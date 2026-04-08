// Auto-generated from 13_guardrails.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(13, "Guardrails")


== Learning Objectives

Learn how to configure guardrails that validate and filter agent input and output.

This notebook covers:
- Understanding the concept of guardrails and why they are needed
- Comparing deterministic guardrails and model-based guardrails
- Configuring PII detection middleware
- Building human-in-the-loop guardrails
- Writing custom `before_agent` and `after_agent` guardrails


== 13.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-4.1",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("Environment ready.")
`````)

== 13.2 Guardrail Concepts

_Guardrails_ are safety mechanisms that validate and filter content during agent execution.

=== Why do we need guardrails?

- Prevent leakage of personally identifiable information (PII)
- Block prompt-injection attacks
- Prevent harmful or inappropriate content
- Enforce business rules and compliance requirements
- Validate output quality and correctness

=== Two approaches

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Approach],
  text(weight: "bold")[Mechanism],
  text(weight: "bold")[Strengths],
  text(weight: "bold")[Weaknesses],
  [_Deterministic_],
  [Regex, keyword matching, explicit rules],
  [Fast, predictable, cost-efficient],
  [May miss subtle violations],
  [_Model-based_],
  [Use an LLM or classifier to analyze meaning],
  [Can catch subtle issues],
  [Slower and more expensive],
)

=== When guardrails are applied

#code-block(`````python
User input → [input guardrail] → agent execution → [output guardrail] → response
                  ↑                                    ↑
            before_agent                          after_agent
`````)


== 13.3 PII Detection Middleware

`PIIMiddleware` automatically detects and handles personal data such as email addresses, credit-card numbers, and IP addresses.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Strategy],
  text(weight: "bold")[Result],
  [`redact`],
  [Replace with `[REDACTED_EMAIL]`],
  [`mask`],
  [Partial masking (for example, only the last 4 digits shown)],
  [`hash`],
  [Replace with a deterministic hash],
  [`block`],
  [Raise an exception when detected],
)


#code-block(`````python
# Example PII-detection middleware setup
print("PII-detection middleware setup:")
print("=" * 50)
print("""
from langchain.agents import create_agent
from langchain.agents.middleware import PIIMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[customer_service_tool, email_tool],
    middleware=[
        # Replace email addresses with [REDACTED_EMAIL]
        PIIMiddleware("email",
            strategy="redact",
            apply_to_input=True),

        # Partially mask credit-card numbers (****-****-****-1234)
        PIIMiddleware("credit_card",
            strategy="mask",
            apply_to_input=True),

        # Block detected API keys (custom regex)
        PIIMiddleware("api_key",
            detector=r"sk-[a-zA-Z0-9]{32}",
            strategy="block",
            apply_to_input=True),
    ],
)
""")
print("Built-in PII types: email, credit_card, ip, mac_address, url")
print("Custom detection: pass a regex or function to the detector parameter")
`````)

== 13.4 Human-in-the-Loop Guardrails

`HumanInTheLoopMiddleware` requires _human approval_ before risky actions are executed. This is essential for high-risk operations such as financial transactions, data deletion, or external communication.


#code-block(`````python
# Human-in-the-Loop guardrail example
print("Human-in-the-Loop guardrail:")
print("=" * 50)
print("""
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool, delete_db_tool],
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "send_email": True,       # approval required
                "delete_db": True,         # approval required
                "search": False,           # automatic
            }
        ),
    ],
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": "review-123"}}

# Step 1: run the agent -> pause at send_email
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Send an email to the team"}]},
    config=config,
)
# -> paused: waiting for approval before send_email executes

# 2Step: resume after approval
result = agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config,
)
""")
print("Key point: a checkpointer is required for pause/resume flows.")
print("On rejection, use {\"type\": \"reject\"} to block the tool call.")
`````)

== 13.5 Custom Input Guardrails — `before_agent`

The `before_agent` hook validates requests _before the agent starts running_. It is useful for session-level authentication, rate limiting, and content filtering.


#code-block(`````python
# Custom input guardrail — ContentFilterMiddleware class
print("Custom input guardrail (class-based):")
print("=" * 50)
print("""
from langchain.agents.middleware import (
    AgentMiddleware, AgentState, hook_config
)
from langgraph.runtime import Runtime
from typing import Any

class ContentFilterMiddleware(AgentMiddleware):
    \"\"\"Deterministic guardrail: blocks requests that contain banned keywords.\"\"\"

    def __init__(self, banned_keywords: list[str]):
        super().__init__()
        self.banned_keywords = [kw.lower() for kw in banned_keywords]

    @hook_config(can_jump_to=["end"])
    def before_agent(
        self, state: AgentState, runtime: Runtime
    ) -> dict[str, Any] | None:
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
                        "content": "The request contains inappropriate content."
                    }],
                    "jump_to": "end"
                }
        return None
""")
print("Key point: jump_to='end' skips agent execution and returns immediately.")
print("If the middleware returns None, execution continues to the next step.")
`````)

== 13.6 Custom Output Guardrails — `after_agent`

The `after_agent` hook validates the final output _after agent execution is complete_. It is useful for model-based safety checks and quality validation.


#code-block(`````python
# Custom output guardrail — SafetyGuardrailMiddleware class
print("Custom output guardrail (class-based):")
print("=" * 50)
print("""
from langchain.agents.middleware import (
    AgentMiddleware, AgentState, hook_config
)
from langgraph.runtime import Runtime
from langchain.messages import AIMessage
from langchain.chat_models import init_chat_model
from typing import Any

class SafetyGuardrailMiddleware(AgentMiddleware):
    \"\"\"Model-based guardrail: uses an LLM to evaluate response safety.\"\"\"

    def __init__(self):
        super().__init__()
        self.safety_model = init_chat_model("gpt-4.1-mini")

    @hook_config(can_jump_to=["end"])
    def after_agent(
        self, state: AgentState, runtime: Runtime
    ) -> dict[str, Any] | None:
        if not state["messages"]:
            return None

        last_message = state["messages"][-1]
        if not isinstance(last_message, AIMessage):
            return None

        safety_prompt = f\"\"\"Evaluate if this response is safe.
        Respond with only 'SAFE' or 'UNSAFE'.

        Response: {last_message.content}\"\"\"

        result = self.safety_model.invoke(
            [{"role": "user", "content": safety_prompt}]
        )

        if "UNSAFE" in result.content:
            last_message.content = (
                "This response was flagged as unsafe. Please ask again."
            )
        return None
""")
print("Key point: evaluate safety with a smaller helper model (gpt-4.1-mini).")
print("If the result is UNSAFE, replace the response with a safe fallback message.")
`````)

== 13.7 Decorator-Based Guardrails

Instead of defining a class, you can build a concise guardrail with _decorators_.


#code-block(`````python
# Decorator-based guardrails
print("Decorator-based guardrails:")
print("=" * 50)
print("""
from langchain.agents.middleware import (
    before_agent, after_agent, AgentState, hook_config
)
from langgraph.runtime import Runtime
from typing import Any

banned_keywords = ["hack", "exploit", "malware"]

# Input guardrail — decorator
@before_agent(can_jump_to=["end"])
def content_filter(
    state: AgentState, runtime: Runtime
) -> dict[str, Any] | None:
    \"\"\"Blocks banned keywords.\"\"\"
    if not state["messages"]:
        return None
    content = state["messages"][0].content.lower()
    for kw in banned_keywords:
        if kw in content:
            return {
                "messages": [{"role": "assistant",
                    "content": "This request is not allowed."}],
                "jump_to": "end"
            }
    return None

# Output guardrail — decorator
@after_agent(can_jump_to=["end"])
def safety_check(
    state: AgentState, runtime: Runtime
) -> dict[str, Any] | None:
    \"\"\"Checks whether the response contains sensitive content.\"\"\"
    last = state["messages"][-1]
    if hasattr(last, 'content') and 'password' in last.content:
        last.content = "The response contained sensitive information."
    return None

# Apply to the agent
agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool],
    middleware=[content_filter, safety_check],
)
""")
print("Decorator-based guardrails work well for simple policies.")
print("Use the class-based approach for more complex logic such as state handling or initialization.")
`````)

== 13.8 Combining Multiple Guardrails

By adding several guardrails in order to the `middleware` list, you can build a _layered defense_ strategy.


#code-block(`````python
# Combine multiple guardrails
print("Combining multiple guardrails (defense in depth):")
print("=" * 50)
print("""
from langchain.agents import create_agent
from langchain.agents.middleware import (
    PIIMiddleware, HumanInTheLoopMiddleware
)

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool],
    middleware=[
        # Layer 1: deterministic input filter
        ContentFilterMiddleware(
            banned_keywords=["hack", "exploit"]
        ),

        # Layer 2: PII protection (input + output)
        PIIMiddleware("email",
            strategy="redact", apply_to_input=True),
        PIIMiddleware("email",
            strategy="redact", apply_to_output=True),

        # Layer 3: human approval for sensitive tools
        HumanInTheLoopMiddleware(
            interrupt_on={"send_email": True}
        ),

        # Layer 4: model-based safety check
        SafetyGuardrailMiddleware(),
    ],
)
""")
print("Execution order:")
print("  input -> [ContentFilter] -> [PII input] -> agent execution")
print("       -> [HITL approval] -> [PII output] -> [Safety] -> response")
print()
print("Tip: place fast deterministic guardrails first and slower model-based checks later.")
`````)

== 13.9 Production Guardrail Patterns

=== Best practices

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Pattern],
  text(weight: "bold")[Description],
  text(weight: "bold")[Implementation],
  [_Layered defense_],
  [Combine multiple guardrails to remove a single point of failure],
  [`middleware=[layer1, layer2, ...]`],
  [_Fail fast_],
  [Run deterministic checks first to reduce cost],
  [Deterministic → model-based order],
  [_Input/output separation_],
  [Use different guardrails for input and output],
  [`before_agent` + `after_agent`],
  [_Graceful rejection_],
  [Return a friendly message when blocking a request],
  [`jump_to="end"` + guidance message],
  [_Logging and monitoring_],
  [Record guardrail trigger events],
  [LangSmith tracing integration],
  [_Fallback strategy_],
  [Handle failure inside the guardrail system itself],
  [`try/except` + default policy],
  [_Testing_],
  [Validate guardrail behavior with unit tests],
  [`GenericFakeChatModel`],
)

=== Domain-specific examples

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Domain],
  text(weight: "bold")[Main guardrails],
  [_Healthcare_],
  [PII (patient data), medical-advice disclaimer, emergency detection],
  [_Finance_],
  [PII (account data), investment disclaimer, HITL for transaction approval],
  [_Customer service_],
  [Sentiment analysis, escalation detection, PII masking],
  [_Education_],
  [Age-appropriateness checks, academic integrity, content filtering],
)


== 13.10 Summary

This notebook covered:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Idea],
  [_Guardrail concepts_],
  [Guardrails validate and filter content during agent execution],
  [_PII detection_],
  [`PIIMiddleware` automatically detects and handles email, credit-card numbers, and related data],
  [_HITL_],
  [`HumanInTheLoopMiddleware` requires human approval before risky tool calls],
  [_Custom input_],
  [`before_agent` validates requests before execution],
  [_Custom output_],
  [`after_agent` validates responses after execution],
  [_Decorators_],
  [`\@before_agent` and `\@after_agent` define concise guardrails],
  [_Layered defense_],
  [Multiple guardrails can be stacked in the `middleware` list],
)

=== Next Steps
→ Continue to the _#link("../03_langgraph/01_introduction.ipynb")[LangGraph intermediate track]_


#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/langchain/13-guardrails.md")[Guardrails]

