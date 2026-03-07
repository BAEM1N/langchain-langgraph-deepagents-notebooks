# Guardrails Documentation

## Overview

Guardrails are safety mechanisms that validate and filter content throughout agent execution. They detect sensitive information, enforce content policies, validate outputs, and prevent unsafe behaviors.

**Common use cases:**
- Preventing PII leakage
- Detecting and blocking prompt injection attacks
- Blocking inappropriate or harmful content
- Enforcing business rules and compliance requirements
- Validating output quality and accuracy

Guardrails work through middleware that intercepts execution at strategic points—before agent start, after completion, or around model and tool calls.

## Two Implementation Approaches

**Deterministic guardrails:** Rule-based logic using regex patterns, keyword matching, or explicit checks. Fast, predictable, and cost-effective, but may miss nuanced violations.

**Model-based guardrails:** Use LLMs or classifiers for semantic understanding. Catch subtle issues but are slower and more expensive.

## Built-in Guardrails

### PII Detection

LangChain provides middleware for detecting Personally Identifiable Information including emails, credit cards, IP addresses, and more. Useful for healthcare, financial applications, and customer service agents requiring compliance.

**Handling strategies:**

| Strategy | Result |
|----------|--------|
| `redact` | Replace with `[REDACTED_{TYPE}]` |
| `mask` | Partially obscure (e.g., last 4 digits) |
| `hash` | Replace with deterministic hash |
| `block` | Raise exception when detected |

**Example implementation:**

```python
from langchain.agents import create_agent
from langchain.agents.middleware import PIIMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[customer_service_tool, email_tool],
    middleware=[
        PIIMiddleware("email", strategy="redact", apply_to_input=True),
        PIIMiddleware("credit_card", strategy="mask", apply_to_input=True),
        PIIMiddleware("api_key", detector=r"sk-[a-zA-Z0-9]{32}",
                     strategy="block", apply_to_input=True),
    ],
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "My email is john.doe@example.com"}]
})
```

**Built-in PII types:** email, credit_card, ip, mac_address, url

**Configuration parameters:**
- `pii_type`: Type of PII to detect (required)
- `strategy`: How to handle detected PII (default: "redact")
- `detector`: Custom regex pattern or function
- `apply_to_input`: Check user messages before model call (default: True)
- `apply_to_output`: Check AI messages after model call (default: False)
- `apply_to_tool_results`: Check tool results after execution (default: False)

### Human-in-the-Loop

Requires human approval before executing sensitive operations. Essential for high-stakes decisions like financial transactions, production data modifications, and external communications.

**Example implementation:**

```python
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool, delete_database_tool],
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "send_email": True,
                "delete_database": True,
                "search": False,
            }
        ),
    ],
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": "some_id"}}

result = agent.invoke(
    {"messages": [{"role": "user", "content": "Send an email to the team"}]},
    config=config
)

result = agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config
)
```

## Custom Guardrails

### Before Agent Guardrails

Validate requests at invocation start for session-level checks like authentication and rate limiting.

**Class syntax example:**

```python
from langchain.agents.middleware import AgentMiddleware, AgentState, hook_config
from langgraph.runtime import Runtime
from typing import Any

class ContentFilterMiddleware(AgentMiddleware):
    """Deterministic guardrail: Block requests with banned keywords."""

    def __init__(self, banned_keywords: list[str]):
        super().__init__()
        self.banned_keywords = [kw.lower() for kw in banned_keywords]

    @hook_config(can_jump_to=["end"])
    def before_agent(self, state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
        if not state["messages"]:
            return None

        first_message = state["messages"][0]
        if first_message.type != "human":
            return None

        content = first_message.content.lower()

        for keyword in self.banned_keywords:
            if keyword in content:
                return {
                    "messages": [{
                        "role": "assistant",
                        "content": "I cannot process requests with inappropriate content. Please rephrase."
                    }],
                    "jump_to": "end"
                }

        return None

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, calculator_tool],
    middleware=[ContentFilterMiddleware(banned_keywords=["hack", "exploit", "malware"])],
)
```

**Decorator syntax example:**

```python
from langchain.agents.middleware import before_agent, AgentState, hook_config
from langgraph.runtime import Runtime
from typing import Any

banned_keywords = ["hack", "exploit", "malware"]

@before_agent(can_jump_to=["end"])
def content_filter(state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
    """Deterministic guardrail: Block requests with banned keywords."""
    if not state["messages"]:
        return None

    first_message = state["messages"][0]
    if first_message.type != "human":
        return None

    content = first_message.content.lower()

    for keyword in banned_keywords:
        if keyword in content:
            return {
                "messages": [{
                    "role": "assistant",
                    "content": "I cannot process requests with inappropriate content. Please rephrase."
                }],
                "jump_to": "end"
            }

    return None

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, calculator_tool],
    middleware=[content_filter],
)
```

### After Agent Guardrails

Validate final outputs before returning to users. Useful for model-based safety checks and quality validation.

**Class syntax example:**

```python
from langchain.agents.middleware import AgentMiddleware, AgentState, hook_config
from langgraph.runtime import Runtime
from langchain.messages import AIMessage
from langchain.chat_models import init_chat_model
from typing import Any

class SafetyGuardrailMiddleware(AgentMiddleware):
    """Model-based guardrail: Use LLM to evaluate response safety."""

    def __init__(self):
        super().__init__()
        self.safety_model = init_chat_model("gpt-4.1-mini")

    @hook_config(can_jump_to=["end"])
    def after_agent(self, state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
        if not state["messages"]:
            return None

        last_message = state["messages"][-1]
        if not isinstance(last_message, AIMessage):
            return None

        safety_prompt = f"""Evaluate if this response is safe and appropriate.
        Respond with only 'SAFE' or 'UNSAFE'.

        Response: {last_message.content}"""

        result = self.safety_model.invoke([{"role": "user", "content": safety_prompt}])

        if "UNSAFE" in result.content:
            last_message.content = "I cannot provide that response. Please rephrase your request."

        return None

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, calculator_tool],
    middleware=[SafetyGuardrailMiddleware()],
)
```

**Decorator syntax example:**

```python
from langchain.agents.middleware import after_agent, AgentState, hook_config
from langgraph.runtime import Runtime
from langchain.messages import AIMessage
from langchain.chat_models import init_chat_model
from typing import Any

safety_model = init_chat_model("gpt-4.1-mini")

@after_agent(can_jump_to=["end"])
def safety_guardrail(state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
    """Model-based guardrail: Use LLM to evaluate response safety."""
    if not state["messages"]:
        return None

    last_message = state["messages"][-1]
    if not isinstance(last_message, AIMessage):
        return None

    safety_prompt = f"""Evaluate if this response is safe and appropriate.
    Respond with only 'SAFE' or 'UNSAFE'.

    Response: {last_message.content}"""

    result = safety_model.invoke([{"role": "user", "content": safety_prompt}])

    if "UNSAFE" in result.content:
        last_message.content = "I cannot provide that response. Please rephrase your request."

    return None

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, calculator_tool],
    middleware=[safety_guardrail],
)
```

### Combining Multiple Guardrails

Stack multiple guardrails by adding them to the middleware array for layered protection:

```python
from langchain.agents import create_agent
from langchain.agents.middleware import PIIMiddleware, HumanInTheLoopMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool],
    middleware=[
        # Layer 1: Deterministic input filter
        ContentFilterMiddleware(banned_keywords=["hack", "exploit"]),

        # Layer 2: PII protection
        PIIMiddleware("email", strategy="redact", apply_to_input=True),
        PIIMiddleware("email", strategy="redact", apply_to_output=True),

        # Layer 3: Human approval for sensitive tools
        HumanInTheLoopMiddleware(interrupt_on={"send_email": True}),

        # Layer 4: Model-based safety check
        SafetyGuardrailMiddleware(),
    ],
)
```

## Additional Resources

- Middleware documentation - Complete guide to custom middleware
- Middleware API reference - API details
- Human-in-the-loop documentation - Add human review for sensitive operations
- Testing agents documentation - Strategies for testing safety mechanisms
