// Source: docs/deepagents/16-permissions.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(15, "Permissions", subtitle: "FilesystemPermission · first-match-wins")

Apply declarative allow/deny rules to Deep Agents' built-in filesystem tools (`ls`, `read_file`, `glob`, `grep`, `write_file`, `edit_file`) to enforce _path-based access control_. Use this chapter when you are defending against prompt injection, building a read-only agent, or carving out a workspace-scoped sandbox.

#learning-header()
#learning-objectives(
  [Understand the three components of `FilesystemPermission` (`operations`, `paths`, `mode`)],
  [Know the first-match-wins evaluation rule and the default (allow)],
  [Distinguish the four patterns — read-only, workspace isolation, sensitive-file protection, read-only memory],
  [Recognize how subagent permissions are inherited and how overrides are full replacements],
  [Know the compensating strategies for custom tools, MCP, and sandbox shells that permissions cannot reach],
)

== 15.1 Scope of application

`permissions` are path-based rules that _only apply to the built-in filesystem tools_. The following bypass them:

- Custom tools
- MCP tools
- `execute` shell commands in the sandbox

In other words, you cannot complete a security boundary with permissions alone. In configurations where the sandbox can run arbitrary shell commands, rules must be designed together with _CompositeBackend routing constraints_. Extra validation or auditing for custom tools belongs to _backend policy hooks_.

== 15.2 Evaluation rule: first-match-wins

Rules are evaluated in list order; the _first rule_ whose `operations` and `paths` match the current call decides the outcome. If no rule matches, the default is *allow*. Because of this, place _specific deny/allow rules first_ and keep general fallbacks at the end.

== 15.3 Three rule components

Every `FilesystemPermission` has three fields.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Field],
  text(weight: "bold")[Value],
  text(weight: "bold")[Description],
  [`operations`],
  [`list["read" | "write"]`],
  [`read` = `ls` / `read_file` / `glob` / `grep`, `write` = `write_file` / `edit_file`],
  [`paths`],
  [`list[str]`],
  [Glob patterns with `**` recursion and `{a,b}` selectors],
  [`mode`],
  [`"allow" | "deny"`],
  [Defaults to `"allow"`],
)

== 15.4 Pattern 1: read-only agent

Block every write globally. Useful for investigation, audit, and report-generation agents.

#code-block(`````python
from deepagents import create_deep_agent, FilesystemPermission

agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[
        FilesystemPermission(
            operations=["write"],
            paths=["/**"],
            mode="deny",
        ),
    ],
)
`````)

== 15.5 Pattern 2: workspace isolation

Allow only under `/workspace/`, deny everything else. Because of first-match-wins, the _allow goes first_ and the deny catch-all follows.

#code-block(`````python
agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/workspace/**"],
            mode="allow",
        ),
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/**"],
            mode="deny",
        ),
    ],
)
`````)

== 15.6 Pattern 3: protect specific files

Forbid touching `/workspace/.env` and the examples directory, but allow the rest of `/workspace/` freely.

#code-block(`````python
agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[
        # the most specific deny at the top
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/workspace/.env", "/workspace/examples/**"],
            mode="deny",
        ),
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/workspace/**"],
            mode="allow",
        ),
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/**"],
            mode="deny",
        ),
    ],
)
`````)

== 15.7 Pattern 4: read-only memory / policies

Block only _writes_ on `/memories/` and `/policies/`. Reads stay open. This is the baseline defense that prevents prompt injection from corrupting shared memory and organization policies.

#code-block(`````python
from deepagents import create_deep_agent, FilesystemPermission
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend

agent = create_deep_agent(
    model=model,
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(
                namespace=lambda rt: (rt.server_info.user.identity,),
            ),
            "/policies/": StoreBackend(
                namespace=lambda rt: (rt.context.org_id,),
            ),
        },
    ),
    permissions=[
        FilesystemPermission(
            operations=["write"],
            paths=["/memories/**", "/policies/**"],
            mode="deny",
        ),
    ],
)
`````)

Update memories and policies only from application code; let the agent read.

== 15.8 Subagent inheritance

Default behavior: a parent agent's permissions are _inherited by subagents as-is_. If a subagent spec defines its own `permissions`, that _fully replaces_ the parent rules (not a partial override). When overriding, include the catch-all deny yourself to stay safe.

#code-block(`````python
agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[...parent_rules...],
    subagents=[
        {
            "name": "auditor",
            "description": "Read-only code reviewer",
            "system_prompt": "Review the code for issues.",
            "permissions": [
                # block writes globally
                FilesystemPermission(
                    operations=["write"], paths=["/**"], mode="deny",
                ),
                # allow reads only inside /workspace
                FilesystemPermission(
                    operations=["read"], paths=["/workspace/**"], mode="allow",
                ),
                # deny all other reads
                FilesystemPermission(
                    operations=["read"], paths=["/**"], mode="deny",
                ),
            ],
        },
    ],
)
`````)

This lets an audit-only subagent have a narrower read scope while the main agent keeps broader access.

== 15.9 CompositeBackend constraint: sandbox-default

When the `CompositeBackend` _default is a sandbox_, every permission path must sit _inside a declared route prefix_. This constraint exists because the sandbox can run arbitrary shell commands via the `execute` tool. Path rules cannot stop shell-level file access, so attaching permissions to paths outside the routes creates a _false sense of security_.

#code-block(`````python
from deepagents import create_deep_agent, FilesystemPermission
from deepagents.backends import CompositeBackend

composite = CompositeBackend(
    default=sandbox,
    routes={"/memories/": memories_backend},
)

# valid: inside the /memories/ route
agent = create_deep_agent(
    model=model,
    backend=composite,
    permissions=[
        FilesystemPermission(
            operations=["write"], paths=["/memories/**"], mode="deny",
        ),
    ],
)
`````)

Placing a rule on a path outside any known route raises `NotImplementedError`. For control over the sandbox-internal filesystem, do not reach for permissions — configure the sandbox itself (allowed binaries, network policy, volume-mount scope).

== 15.10 Prompt-injection defense perspective

Shared memory, organization policy, and externally ingested documents are all injection vectors. The defense layers are:

+ *Enforce read-only*: write-deny on `/memories/**` and `/policies/**` (pattern 4)
+ *Workspace isolation*: constrain what the agent can touch to `/workspace/**`
+ *Protect sensitive files*: deny each `.env`-like path individually as in pattern 3
+ *Shrink subagent scope*: configure audit / query subagents as read-only separately
+ *Custom-tool / sandbox boundaries*: permissions cannot reach them — cover with policy hooks + sandbox policy

== 15.11 Permissions vs backend policy hooks

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Purpose],
  text(weight: "bold")[Use this surface],
  [Path-based allow/deny on built-in FS tools],
  [`permissions`],
  [Custom validation (data checks, logging, rate limits)],
  [backend policy hooks],
  [Custom-tool / MCP tool control],
  [Tool wrappers / middleware],
  [Sandbox-internal file / network control],
  [Sandbox configuration (allowed binaries, network policy)],
)

Permissions are _declarative quick rules_; policy hooks are _logic-driven controls_. Use each for what it is good at.

== 15.12 Caveats

- *first-match-wins*: rule order changes the outcome. Put more specific deny/allow at the top
- *no match = allow*: to prevent accidental allows, end with a catch-all deny
- *Missing operations*: a rule with only `"read"` leaves writes to subsequent rules' (default allow)
- *Subagent override is full replacement*: no partial edits. Copy parent rules you want to keep
- *Permissions are not a complete security boundary*: they only make sense alongside sandbox, network, and secret management

== Key Takeaways

- `FilesystemPermission`'s three components (`operations` / `paths` / `mode`) and first-match-wins are the foundations
- Four canonical patterns (read-only / workspace isolation / sensitive-file protection / read-only memory) cover most cases
- Subagent permission overrides are _full replacements_ — be careful to copy in the catch-all deny
- Under CompositeBackend + sandbox-default, permissions outside the route prefixes raise `NotImplementedError`
- Permissions are _declarative quick rules_; custom tools, MCP, and sandbox shells require policy hooks and sandbox policy
