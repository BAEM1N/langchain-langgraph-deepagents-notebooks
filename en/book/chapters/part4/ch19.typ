// Auto-generated from 15_permissions.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(19, "Permissions", subtitle: "Design Deep Agents authorization boundaries first")

Permissions are part of the agent design, not a final hardening pass. This chapter shows how to reason about tool risk, targets, approval messages, and default-deny behavior.

_Learning goals_
- Build a simple permission matrix for agent tools.
- Evaluate allow/approve/deny decisions deterministically.
- Write approval messages that explain the risk clearly.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 15.1 Permission matrix

A permission matrix makes policy visible before code executes. It should connect each tool to the targets it may read, write, modify, or never touch.


#code-block(`````python
permission_matrix = {
    "read_file": "allow",
    "write_file": "approve",
    "edit_file": "approve",
    "execute_shell": "sandbox-only",
    "delete_file": "deny",
}

permission_matrix
`````)

== 15.2 Policy Evaluator

A policy evaluator turns the matrix into a repeatable decision. Even a small deterministic evaluator is better than scattered permission checks.


#code-block(`````python
def decide(tool_name: str) -> str:
    return permission_matrix.get(tool_name, "deny")

for tool in ["read_file", "write_file", "delete_file", "unknown"]:
    print(tool, "=>", decide(tool))
`````)

== 15.3 Approval messages

Approval prompts should be specific enough for a human to make a real decision. They should name the tool, target, action, and reason for escalation.


#code-block(`````python
def approval_message(tool_name: str, target: str) -> str:
    policy = decide(tool_name)
    if policy != "approve":
        return f"{tool_name}: {policy}"
    return f"Approval required: {tool_name} will modify {target}"

approval_message("write_file", "docs/example.md")
`````)

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
  [permission matrices, approval messages, sandbox boundaries, and deny-by-default policies],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/deepagents/permissions.md")[`permissions.md`]
- #link("../../docs/deepagents/tools.md")[`tools.md`]
- #link("../../docs/deepagents/sandboxes.md")[`sandboxes.md`]
