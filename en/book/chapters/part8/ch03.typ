// Source: 08_integration/11_provider_middleware/02_claude_bash_tool.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Claude Bash Tool", subtitle: "Native bash_20250124 + execution policies")

`ClaudeBashToolMiddleware` injects the Anthropic native `bash_20250124` tool into Claude models. Unlike a generic `ShellToolMiddleware`, _Anthropic's servers manage the bash call schema directly_, so the prompt stays short and tool-schema tokens approach zero. This chapter compares the three execution policies (Host / Docker / CodexSandbox) and covers `redaction_rules` for masking secrets.

#learning-header()
#learning-objectives(
  [Understand the four main parameters of `ClaudeBashToolMiddleware`],
  [Distinguish the isolation levels of `HostExecutionPolicy` / `DockerExecutionPolicy` / `CodexSandboxExecutionPolicy`],
  [Mask tokens and keys in output via `RedactionRule`],
  [Know how Claude native bash differs from a generic shell tool],
)

== 3.1 When to use it

- Letting Claude run real shell commands for code execution, file inspection, builds
- Deep-Agents-style long-running workspaces where you need to preserve session state (cwd, env vars)
- Running arbitrary code safely in an isolated Docker container
- Shell output may contain API keys / credentials, so redaction is required

== 3.2 Environment setup

Required packages: `langchain`, `langchain-anthropic`. The Docker policy example requires a local Docker daemon running.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import ClaudeBashToolMiddleware

load_dotenv()
`````)

== 3.3 Host execution policy (simplest)

`HostExecutionPolicy` runs commands in the local process. Fast with no setup, but _no isolation_ — it has full access to network, filesystem, and environment variables, so reserve it for trusted scripts or local development.

#code-block(`````python
from langchain.agents.middleware import HostExecutionPolicy

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        ClaudeBashToolMiddleware(
            workspace_root="/tmp/work",
            startup_commands=["export PATH=$HOME/.local/bin:$PATH"],
            execution_policy=HostExecutionPolicy(),
        ),
    ],
)
`````)

- `workspace_root`: default directory for the shell session
- `startup_commands`: commands run automatically at session start (PATH configuration, venv activation, etc.)

== 3.4 Docker execution policy (recommended, isolated)

`DockerExecutionPolicy` runs commands _inside a container_, fully isolated from the host filesystem and network. Make it the effective default when executing model-generated code.

#code-block(`````python
from langchain.agents.middleware import DockerExecutionPolicy

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        ClaudeBashToolMiddleware(
            execution_policy=DockerExecutionPolicy(image="python:3.11"),
            startup_commands=["pip install requests numpy"],
        ),
    ],
)
`````)

The container is created on the first bash call and cleaned up at session end. For package requirements, add `pip install ...` to `startup_commands`.

== 3.5 Codex sandbox policy

`CodexSandboxExecutionPolicy` runs commands on Anthropic's managed sandbox runner. It is the alternative when you want isolation without local Docker. The network whitelist and resource limits come with strong defaults.

== 3.6 Output redaction (`redaction_rules`)

Shell output can leak sensitive values — API keys, tokens, emails. Pass a list of `RedactionRule` objects to mask tool responses _before they enter the agent context_. LangChain 1.2 unified the `RedactionRule` signature with `PIIMiddleware` — use `(pii_type, strategy, detector)` instead of the removed `pattern=` / `replacement=` kwargs.

#code-block(`````python
from langchain.agents.middleware import RedactionRule

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        ClaudeBashToolMiddleware(
            execution_policy=DockerExecutionPolicy(),
            redaction_rules=[
                RedactionRule(
                    pii_type="openai_api_key",
                    strategy="redact",
                    detector=r"sk-[a-zA-Z0-9]{32,}",
                ),
                RedactionRule(
                    pii_type="github_token",
                    strategy="redact",
                    detector=r"ghp_[a-zA-Z0-9]{36}",
                ),
            ],
        ),
    ],
)
`````)

== 3.7 Native vs generic comparison

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[`ClaudeBashToolMiddleware`],
  text(weight: "bold")[Generic `ShellToolMiddleware`],
  [Tool type],
  [Anthropic native `bash_20250124`],
  [Ordinary `@tool` function],
  [Supported models],
  [Claude only],
  [All models],
  [Tool-schema tokens],
  [Server-side → near zero],
  [Sent every turn],
  [Session state],
  [cwd, env preserved and accumulated],
  [Depends on implementation],
  [Execution-policy API],
  [Shared (`HostExecutionPolicy`, etc.)],
  [Shared],
)

*Selection criteria*: If you are Claude-only, the native version is cheaper and cleaner. For multi-provider pipelines, unify on the generic `ShellToolMiddleware`.

== Key Takeaways

- Claude native bash brings tool-schema tokens close to zero
- Pick execution policy in three tiers: Host (no isolation) → Docker (recommended) → CodexSandbox (Anthropic-managed)
- `redaction_rules` masks sensitive values in tool responses before they enter agent context
- In multi-provider pipelines, unifying on the generic `ShellToolMiddleware` is the safer default
