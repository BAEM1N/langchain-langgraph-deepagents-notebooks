# Customer Support State Machine

This tutorial covers building a customer support agent that uses a state machine pattern with dynamic configuration. A single agent handles the entire customer journey, with tools and system prompts changing based on the current support step.

## Architecture

The agent operates as a state machine where each step has its own set of tools and instructions.

```
[Identify Customer] -> [Diagnose Issue] -> [Resolve Issue] -> [Close Ticket]
```

Unlike multi-agent handoff patterns, this approach uses a **single agent** with **dynamic configuration** that changes based on the `current_step` field in the agent state.

## Prerequisites

```bash
pip install langchain langchain-openai
```

```bash
export OPENAI_API_KEY="your-openai-key"
```

## Step 1: Define the State

Extend `AgentState` with a `current_step` field that tracks where the customer is in the support flow.

```python
from langchain.agents import AgentState
from typing import Literal

class SupportState(AgentState):
    current_step: Literal[
        "identify_customer",
        "diagnose_issue",
        "resolve_issue",
        "close_ticket",
    ] = "identify_customer"
```

## Step 2: Define Step-Specific Tools

Each step has its own set of tools. Tools can trigger state transitions by returning `Command` objects.

### Identify Customer Tools

```python
from langchain_core.tools import tool
from langchain_core.commands import Command

@tool
def lookup_customer(email: str) -> Command:
    """Look up a customer by their email address.

    Args:
        email: The customer's email address.
    """
    customer = customer_db.find_by_email(email)
    if customer:
        return Command(
            update={
                "customer": customer,
                "current_step": "diagnose_issue",
            },
            result=f"Found customer: {customer['name']} (ID: {customer['id']}). "
                   f"Account type: {customer['plan']}. Moving to diagnosis.",
        )
    return Command(
        result="Customer not found. Please ask for a different email or account ID.",
    )

@tool
def lookup_customer_by_id(account_id: str) -> Command:
    """Look up a customer by their account ID.

    Args:
        account_id: The customer's account identifier.
    """
    customer = customer_db.find_by_id(account_id)
    if customer:
        return Command(
            update={
                "customer": customer,
                "current_step": "diagnose_issue",
            },
            result=f"Found customer: {customer['name']}. Moving to diagnosis.",
        )
    return Command(result="Account not found. Please verify the ID.")
```

### Diagnose Issue Tools

```python
@tool
def check_service_status(service_name: str) -> str:
    """Check the current status of a service.

    Args:
        service_name: Name of the service to check.
    """
    status = status_api.get_status(service_name)
    return f"Service '{service_name}' status: {status['state']} (uptime: {status['uptime']}%)"

@tool
def check_customer_logs(customer_id: str, hours: int = 24) -> str:
    """Check recent logs for a customer's account.

    Args:
        customer_id: The customer ID to look up.
        hours: Number of hours of logs to retrieve (default: 24).
    """
    logs = logging_service.get_logs(customer_id, hours=hours)
    return format_logs(logs)

@tool
def escalate_to_resolve(diagnosis: str) -> Command:
    """Move to the resolution step after diagnosing the issue.

    Args:
        diagnosis: Summary of the diagnosed issue.
    """
    return Command(
        update={
            "diagnosis": diagnosis,
            "current_step": "resolve_issue",
        },
        result=f"Issue diagnosed: {diagnosis}. Moving to resolution.",
    )
```

### Resolve Issue Tools

```python
@tool
def apply_fix(fix_type: str, customer_id: str, parameters: dict = None) -> Command:
    """Apply a fix to the customer's account.

    Args:
        fix_type: Type of fix to apply (e.g., 'reset_password', 'restart_service', 'apply_credit').
        customer_id: The customer's account ID.
        parameters: Additional parameters for the fix.
    """
    result = fix_service.apply(fix_type, customer_id, parameters or {})
    return Command(
        update={"resolution": result},
        result=f"Fix applied: {result['description']}",
    )

@tool
def escalate_to_human(reason: str) -> Command:
    """Escalate to a human support agent when the issue cannot be resolved automatically.

    Args:
        reason: Reason for escalation.
    """
    ticket = ticketing_service.escalate(reason=reason)
    return Command(
        update={"current_step": "close_ticket", "escalated": True},
        result=f"Escalated to human agent. Ticket: {ticket['id']}",
    )

@tool
def mark_resolved(summary: str) -> Command:
    """Mark the issue as resolved and move to close.

    Args:
        summary: Summary of the resolution.
    """
    return Command(
        update={"current_step": "close_ticket", "resolution_summary": summary},
        result="Issue marked as resolved. Moving to close.",
    )
```

### Close Ticket Tools

```python
@tool
def send_satisfaction_survey(customer_id: str) -> str:
    """Send a satisfaction survey to the customer.

    Args:
        customer_id: The customer's account ID.
    """
    survey_service.send(customer_id)
    return "Satisfaction survey sent."

@tool
def close_ticket(ticket_id: str, notes: str) -> str:
    """Close the support ticket.

    Args:
        ticket_id: The ticket ID to close.
        notes: Closing notes for the ticket.
    """
    ticketing_service.close(ticket_id, notes=notes)
    return f"Ticket {ticket_id} closed."
```

## Step 3: Map Steps to Configuration

Define the tools and system prompt for each step.

```python
STEP_CONFIG = {
    "identify_customer": {
        "tools": [lookup_customer, lookup_customer_by_id],
        "system_prompt": (
            "You are a customer support agent. Your first task is to identify the customer. "
            "Ask for their email address or account ID, then use the lookup tools to find them. "
            "Do not proceed until the customer is identified."
        ),
    },
    "diagnose_issue": {
        "tools": [check_service_status, check_customer_logs, escalate_to_resolve],
        "system_prompt": (
            "You are diagnosing a customer's issue. Ask them to describe the problem, "
            "then use the diagnostic tools to investigate. Check service status and "
            "customer logs. Once you understand the issue, use escalate_to_resolve "
            "to move to the resolution step."
        ),
    },
    "resolve_issue": {
        "tools": [apply_fix, escalate_to_human, mark_resolved],
        "system_prompt": (
            "You are resolving the customer's issue. Based on the diagnosis, apply "
            "the appropriate fix. If you cannot resolve the issue automatically, "
            "escalate to a human agent. Once resolved, use mark_resolved."
        ),
    },
    "close_ticket": {
        "tools": [send_satisfaction_survey, close_ticket],
        "system_prompt": (
            "The issue has been resolved (or escalated). Thank the customer, "
            "send a satisfaction survey, and close the ticket."
        ),
    },
}
```

## Step 4: Create the Middleware

Use `@wrap_model_call` middleware to dynamically swap the system prompt and available tools based on the current step.

```python
from langchain.middleware import wrap_model_call

@wrap_model_call
def step_middleware(state, config, next_fn):
    """Dynamically configure the agent based on the current support step."""
    current_step = state.get("current_step", "identify_customer")
    step_config = STEP_CONFIG[current_step]

    # Override the system prompt
    config["system_prompt"] = step_config["system_prompt"]

    # Override the available tools
    config["tools"] = step_config["tools"]

    # Call the next function in the middleware chain
    return next_fn(state, config)
```

## Step 5: Create the Agent

```python
from langchain.agents import create_agent

# Provide all tools at creation time (middleware will filter per step)
all_tools = [
    lookup_customer, lookup_customer_by_id,
    check_service_status, check_customer_logs, escalate_to_resolve,
    apply_fix, escalate_to_human, mark_resolved,
    send_satisfaction_survey, close_ticket,
]

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=all_tools,
    state_schema=SupportState,
    middleware=[step_middleware],
)
```

## Step 6: Run the Agent

```python
response = agent.invoke(
    {"messages": [{"role": "user", "content": "Hi, I'm having trouble logging into my account. My email is alice@example.com"}]}
)

print(response["messages"][-1].content)
```

## Execution Flow

```
Step: identify_customer
  User: "Hi, I can't log in. My email is alice@example.com"
  Agent -> lookup_customer("alice@example.com")
       <- Found customer: Alice Smith (ID: C-1234). Moving to diagnosis.

Step: diagnose_issue  (automatic transition via Command)
  Agent: "I found your account, Alice. Can you tell me more about the login issue?"
  User: "I keep getting an 'invalid credentials' error"
  Agent -> check_customer_logs("C-1234", hours=24)
       <- "3 failed login attempts in last hour. Last successful login: 2 days ago."
  Agent -> check_service_status("auth-service")
       <- "Service 'auth-service' status: healthy (uptime: 99.9%)"
  Agent -> escalate_to_resolve("Customer locked out after 3 failed login attempts")

Step: resolve_issue  (automatic transition via Command)
  Agent -> apply_fix("reset_password", "C-1234")
       <- "Fix applied: Password reset email sent to alice@example.com"
  Agent -> mark_resolved("Reset password for customer after failed login lockout")

Step: close_ticket  (automatic transition via Command)
  Agent: "I've sent a password reset link to your email. Is there anything else?"
  User: "No, that's all. Thanks!"
  Agent -> send_satisfaction_survey("C-1234")
  Agent -> close_ticket("T-5678", notes="Password reset after login lockout")
  Agent: "You're welcome! I've sent a quick survey. Have a great day!"
```

## Design Considerations

| Aspect | Recommendation |
|--------|----------------|
| State transitions | Use `Command` objects returned from tools to update `current_step` |
| Backward transitions | Allow tools to return to a previous step if needed |
| Invalid transitions | Validate transitions in middleware to prevent skipping steps |
| Step-specific context | Pass accumulated state (customer info, diagnosis) through agent state |
| Error recovery | If a step fails, transition to an error-handling step |
| Logging | Log step transitions for audit and debugging |
