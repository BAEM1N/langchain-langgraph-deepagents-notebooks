// Auto-generated from 12_models_and_tools.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(16, "Models and Tools", subtitle: "Design the Deep Agents execution surface")

A Deep Agent is shaped by the model it calls and the tools it is allowed to use. This chapter treats tools as contracts, model configuration as a runtime boundary, and agent construction as something that should be inspectable.

_Learning goals_
- Design tool schemas that are clear enough for an agent to use safely.
- Classify tools by operational risk before wiring them into an agent.
- Keep model and backend configuration centralized and reviewable.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from langchain.tools import tool
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
`````)

== 12.1 Tools are contracts, not just functions

A tool is part of the agent’s public interface. Its name, description, arguments, and return shape should communicate intent without relying on hidden context.


#code-block(`````python
@tool
def summarize_note(text: str, max_bullets: int = 3) -> str:
    """Summarize a note into a short bullet list."""
    sentences = [s.strip() for s in text.split(".") if s.strip()]
    return "\n".join(f"- {s}" for s in sentences[:max_bullets])

print(summarize_note.invoke({"text": "A. B. C.", "max_bullets": 2}))
`````)

== 12.2 Inspect the tool schema

Schema inspection turns a Python function into an auditable contract. If the schema is confusing to a human reviewer, it will probably be confusing to the agent as well.


#code-block(`````python
schema = summarize_note.args_schema.model_json_schema()

print("tool name:", summarize_note.name)
print("description:", summarize_note.description)
print("properties:", sorted(schema["properties"]))
`````)

== 12.3 Classify tool risk

Not every tool deserves the same level of access. Classify tools as safe, approval-gated, sandboxed, or denied before exposing them to autonomous execution.


#code-block(`````python
tool_policy = {
    "summarize_note": "allow",
    "write_file": "approve",
    "execute_shell": "deny-or-sandbox",
}

for name, policy in tool_policy.items():
    print(f"{name:16s} -> {policy}")
`````)

== 12.4 Centralize model configuration

Centralized configuration keeps experiments reproducible. It also makes it obvious which model, tools, and backend are being used for a given run.


#code-block(`````python
MODEL_NAME = os.getenv("COURSE_MODEL", "gpt-5.4")
agent_config = {
    "model": MODEL_NAME,
    "tools": [summarize_note],
    "backend": FilesystemBackend(root_dir=".", virtual_mode=True),
}
agent_config["model"]
`````)

== 12.5 Separate agent construction from invocation

Build the agent in one place and invoke it elsewhere. This separation makes the execution surface easier to test, swap, and review.


#code-block(`````python
agent = create_deep_agent(
    model=agent_config["model"],
    tools=agent_config["tools"],
    backend=agent_config["backend"],
    system_prompt="You are a concise course assistant.",
)

type(agent).__name__
`````)

== 12.6 Design checklist

Use the checklist as a final review before moving from a notebook prototype to an application. It focuses on contracts, permissions, configuration, and observability.


#line(length: 100%, stroke: 0.5pt + luma(200))

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Content],
  [_Covered_],
  [model configuration, tool schema design, and permission-aware Deep Agent setup],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/deepagents/models.md")[`models.md`]
- #link("../../docs/deepagents/tools.md")[`tools.md`]
- #link("../../docs/deepagents/backends.md")[`backends.md`]
