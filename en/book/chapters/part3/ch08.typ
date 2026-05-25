// Auto-generated from 08_interrupts_and_time_travel.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "Interrupts and Time Travel", subtitle: "Execute interrupt, Acknowledge, Rewind")

== Learning Objectives

Execute with `interrupt()`, interrupt, and resume with `Command(resume=...)`. Time travel back to the previous state.

- Human-in-the-loop pattern can be implemented
- Interrupt can also be used in Functional API
- You can perform time travel using checkpoint history.
- state can be modified externally with `update_state()`

== 8.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4-mini")
print("Model is ready")
`````)

== 8.2 interrupt() — executes interrupt and waits for human input

- `interrupt(value)`: Save the current state to the checkpoint and execute interrupt
- `Command(resume=value)`: Passes the value at interrupt point and resume

This pattern is used to obtain human approval or input additional information before performing sensitive tasks.

== 8.3 Command(resume=...) — interrupt executes resume

Using `Command(resume=value)` causes execution to resume at the point where `interrupt()` is called. The value passed to `resume` becomes the return value of `interrupt()`.

`Command(resume=...)` accepts boolean, text, or dict payloads. The pattern depends on the response shape:

#code-block(`````python
from langgraph.types import Command

# 1) Simple boolean — Approval
graph.invoke(Command(resume=True), config=config, version="v2")

# 2) Text — Review & Edit
graph.invoke(Command(resume="The edited text"), config=config, version="v2")

# 3) Structured dict — Tool interrupt / multi-field response
graph.invoke(
    Command(resume={"action": "approve", "subject": "Updated subject"}),
    config=config,
    version="v2",
)
`````)

=== Common Patterns — five HITL scenarios

The five interrupt patterns you'll see in production:

==== 1) Approval — sensitive action gate

Pause right before a critical action (API call / DB mutation) and route based on the decision.

#code-block(`````python
from typing import Literal
from langgraph.types import Command, interrupt

def approval_node(state) -> Command[Literal["proceed", "cancel"]]:
    decision = interrupt({
        "question": "Approve this action?",
        "details": state["action_details"],
    })
    return Command(goto="proceed" if decision else "cancel")

graph.invoke(Command(resume=True), config=config, version="v2")   # approve
graph.invoke(Command(resume=False), config=config, version="v2")  # reject
`````)

==== 2) Review & Edit — human revises LLM output

#code-block(`````python
def review_node(state):
    edited = interrupt({
        "instruction": "Review and edit this content",
        "content": state["generated_text"],
    })
    return {"generated_text": edited}

graph.invoke(Command(resume="edited body ..."), config=config, version="v2")
`````)

==== 3) Tool Interrupt — approve before the tool runs

Put `interrupt()` inside a `@tool` to require human approval/edits. The resume payload is typically `{"action": "approve", ...}`.

#code-block(`````python
from langchain.tools import tool

@tool
def send_email(to: str, subject: str, body: str):
    response = interrupt({
        "action": "send_email",
        "to": to, "subject": subject, "body": body,
        "message": "Approve sending this email?",
    })
    if response.get("action") == "approve":
        return f"Email sent to {response.get('to', to)}"
    return "Email cancelled by user"
`````)

==== 4) Input Validation — loop until valid

#code-block(`````python
def get_age_node(state):
    prompt = "What is your age?"
    while True:
        answer = interrupt(prompt)
        if isinstance(answer, int) and answer > 0:
            break
        prompt = f"'{answer}' is not valid. Please enter a positive number."
    return {"age": answer}
`````)

==== 5) Multiple Interrupts — match parallel responses

When parallel nodes raise interrupts simultaneously, use a resume map keyed by interrupt id:

#code-block(`````python
result = graph.invoke({"vals": []}, config, version="v2")

resume_map = {
    i.id: f"answer for {i.value}" for i in result.interrupts
}
graph.invoke(Command(resume=resume_map), config, version="v2")
`````)

== 8.4 Interrupt in Functional API

You can also use `interrupt()` in the Functional API (`@entrypoint`, `@task`).

== 8.5 Time Travel — Go back to a previous checkpoint

The checkpoint system in LangGraph stores all executions of state. You can view previous checkpoints with `get_state_history()` and go back to a specific point in time.

== 8.6 update_state() — Time travel + state fix

`update_state()` allows you to directly modify the state of a graph from the outside. This is useful for debugging, testing, or when manual intervention is required.

=== Replay vs Fork — two time-travel modes

- *Replay* — re-run from a previous checkpoint as-is. Nodes after `next` are re-executed (LLM/API calls happen again — results may differ).
- *Fork* — modify state at a previous checkpoint and create a new branch. The original thread is preserved.

#code-block(`````python
# Replay — invoke with the checkpoint config
history = list(graph.get_state_history(config))
before_joke = next(s for s in history if s.next == ("write_joke",))
replay_result = graph.invoke(None, before_joke.config)

# Fork — create a new branch with update_state
fork_config = graph.update_state(
    before_joke.config,
    values={"topic": "chickens"},
)
fork_result = graph.invoke(None, fork_config)
`````)

#tip-box[Pass the _return value_ of `update_state()` (`fork_config`) to `invoke()`, not the original `before.config`. The new checkpoint id lives inside `fork_config`.]

=== `as_node` — declare which node owns the update

`update_state(config, values, as_node="...")` lets you declare which node should be treated as the source of the update. Useful when:

- parallel branches make ownership ambiguous,
- seeding initial state into a fresh thread for a test, or
- skipping a node and resuming from its successor.

#code-block(`````python
fork_config = graph.update_state(
    before_joke.config,
    values={"topic": "chickens"},
    as_node="generate_topic",  # resume from this node's successor
)
graph.invoke(None, fork_config)
`````)

=== Reducer behavior — merge vs overwrite

How `values` is applied depends on whether the channel has a reducer.

- _Channel with reducer_ (e.g. `MessagesState.messages` uses `add_messages`) → values are _merged_; appending messages accumulates.
- _Channel without reducer_ (plain `TypedDict` fields) → values are _overwritten_.

To _replace_ a single message, send `RemoveMessage(id=...)` plus the new one. Plain dict fields can be replaced directly with `values={"field": new_value}`.

== 8.7 Summary

Summarize the key functions learned in this Note book.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Features],
  text(weight: "bold")[API],
  text(weight: "bold")[Description],
  [`interrupt(value)`],
  [Both sides],
  [run interrupt, pass value],
  [`Command(resume=value)`],
  [Both sides],
  [resume at point interrupt],
  [`get_state_history()`],
  [Graph],
  [Checkpoint history inquiry],
  [`update_state()`],
  [Graph],
  [Modify state externally],
)

_interrupts and time travel_ are key features in production AI applications:
- _interrupt_: Get human approval before sensitive operations
- _Time Travel_: You can go back to the previous state and explore different routes
- _update_state_: You can adjust the execution flow by modifying state externally.

=== Next Steps
→ _#link("./09_subgraphs.ipynb")[09_subgraphs.ipynb]_: Learn subgraphs.
