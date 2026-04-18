// Auto-generated from 01_middleware.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "Deepening the middleware system", subtitle: "v1’s biggest new features")

== Learning Objectives

- Understand the role and execution flow of middleware hooks in the agent loop.
- Learn how to set up and use 7 types of built-in middleware
- You can write decorator/class-based custom middleware.
- Execution order can be accurately predicted when combining multiple middleware

== 1.1 Environment Setup

Middleware is a core feature of v1 that implements monitoring, transformation, reliability, and governance by inserting hooks into each step of agent execution. It is used by passing the middleware instance list to the `middleware` parameter of the `create_agent` function.

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-4.1")
`````)

== 1.2 Middleware Architecture Overview

The agent loop is a repeating cycle of _model call → tool selection → tool execution → termination decision_. Middleware enables fine-grained control by inserting hooks into each step of this cycle.

=== Hook type

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Hook Type],
  text(weight: "bold")[When to run],
  text(weight: "bold")[Representative uses],
  [`before_model`],
  [Just before the model call],
  [Prompt Modification, Logging, Status Updates],
  [`after_model`],
  [Immediately after the model responds],
  [Response validation, guardrails, result transformation],
  [`before_agent`],
  [When the agent starts running],
  [initialization, preprocessing],
  [`after_agent`],
  [At the end of agent execution],
  [Cleanup, post-processing],
  [`wrap_model_call`],
  [Wrapping model call],
  [Retries, caching, fallback],
  [`wrap_tool_call`],
  [tool calling Wrap],
  [tool Retries, audit logs, error handling],
)

=== Two hook styles

- _Node-style hook_ (`before_*`, `after_*`): Executes sequentially and is suitable for logging/verification/status updates.
- _Wrap-style hook_ (`wrap_*`): Allows you to control whether the handler (`next_fn`) is called. It can be called 0 times (blocking), 1 time (passing), or multiple times (retry), making it suitable for retry, caching, and conversion logic.

Middleware provides clean separation of cross-cutting concerns such as monitoring, transformation, reliability, and governance without changing the agent's core logic.

#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.middleware import (
    SummarizationMiddleware,
    HumanInTheLoopMiddleware,
)

agent = create_agent(
    model="gpt-4.1", tools=[],
    middleware=[
        SummarizationMiddleware(model="gpt-4.1-mini", trigger=("messages", 50)),
        HumanInTheLoopMiddleware(interrupt_on={}),
    ],
)
`````)

== 1.3 SummarizationMiddleware

When a conversation becomes long enough to exceed the context window, it automatically compresses the previous conversation by Summary. It is essential for long-running conversations, multi-turn conversations, and applications that require preservation of the entire conversation context.

=== Main parameters

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[parameters],
  text(weight: "bold")[Description],
  text(weight: "bold")[Example],
  [`model`],
  [Summary Lightweight model to use for creation (reduces costs)],
  [`"gpt-4.1-mini"`],
  [`trigger`],
  [Summary Trigger condition],
  [`("tokens", 4000)`, `("messages", 50)`, `("fraction", 0.8)`],
  [`keep`],
  [Latest context to keep after Summary],
  [`("messages", 20)`],
  [`token_counter`],
  [Custom token counting function],
  [optional],
  [`summary_prompt`],
  [Custom Summary Prompt Template],
  [optional],
)

`trigger` can be set based on one of the following: number of tokens, number of messages, or window ratio. When the condition is reached, all but the most recent messages specified in `keep` are replaced with Summary statements.

#code-block(`````python
from langchain.agents.middleware import SummarizationMiddleware

summarizer = SummarizationMiddleware(
    model="gpt-4.1-mini",
    trigger=("tokens", 4000),
    keep=("messages", 20),
)
`````)

== 1.4 HumanInTheLoopMiddleware

Stop agent execution before high-risk tool calling and wait for human approval. Use when human supervision is required for high-risk tasks or compliance workflows, such as database writes, financial transactions, and email sending.

*`checkpointer` required* — a checkpointer is absolutely required to restore state after an interruption.

=== Decision type

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[decision],
  text(weight: "bold")[Description],
  text(weight: "bold")[How to use],
  [`approve`],
  [tool calling Approval and Execution],
  [`Command(resume="approve")`],
  [`edit`],
  [tool Execute after modifying arguments],
  [`Command(resume={"type": "edit", "args": {...}})`],
  [`reject`],
  [tool calling Reject],
  [`Command(resume={"type": "reject", "reason": "..."})`],
)

Set the approval policy for each tool in the `interrupt_on` dictionary. If set to `False`, the corresponding tool will run without interruption.

#code-block(`````python
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

hitl = HumanInTheLoopMiddleware(
    interrupt_on={
        "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},
        "read_email": False,
    }
)
`````)

#code-block(`````python
agent = create_agent(
    model="gpt-4.1", tools=[],
    checkpointer=InMemorySaver(),
    middleware=[hitl],
)
`````)

== 1.5 ModelCallLimitMiddleware & ToolCallLimitMiddleware

Call limiting middleware to prevent infinite loops or excessive API costs.

=== ModelCallLimitMiddleware

Limits the number of times the agent calls the model. Used to prevent agent flooding, control production costs, and manage call budgets during testing.

=== ToolCallLimitMiddleware

Limits tool calling counts globally or per specific tool. It is useful for limiting expensive external API calls, controlling search/DB query frequency, and enforcing rate limits for specific tool.

=== Common parameters

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[parameters],
  text(weight: "bold")[Description],
  [`thread_limit`],
  [Maximum number of calls across all threads (all invokes)],
  [`run_limit`],
  [Maximum number of calls in a single invoke execution],
  [`exit_behavior`],
  [`"end"` (normal termination), `"error"` (raise exception), `"continue"` (continue with error message — ToolCallLimit only)],
)

ToolCallLimitMiddleware can additionally take a `tool_name` parameter to apply limits to specific tool only.

#code-block(`````python
from langchain.agents.middleware import ModelCallLimitMiddleware

model_limit = ModelCallLimitMiddleware(
    thread_limit=10,
    run_limit=5,
    exit_behavior="end",
)
`````)

#code-block(`````python
from langchain.agents.middleware import ToolCallLimitMiddleware

# global limit
global_tool_limit = ToolCallLimitMiddleware(thread_limit=20, run_limit=10)

# Certain tool restrictions
search_limit = ToolCallLimitMiddleware(
    tool_name="search",
    thread_limit=5, run_limit=3,
    exit_behavior="continue",
)
`````)

== 1.6 ModelFallbackMiddleware

Automatically switches to an alternate model chain when the primary model fails. It is useful for responding to production failures, optimizing costs (fallback from expensive models to cheap models), and ensuring multi-provider redundancy (OpenAI + Anthropic, etc.).

If you pass a fallback model to the constructor in order, it will try the fallback models in the specified order when the main model call fails. If all fallbacks fail, a final error is raised.

#code-block(`````python
from langchain.agents.middleware import ModelFallbackMiddleware

# gpt-4.1 failed -> gpt-4.1-mini -> claude
fallback = ModelFallbackMiddleware(
    "gpt-4.1-mini",
    "claude-3-5-sonnet-20241022",
)
`````)

== 1.7 PIIMiddleware

Personally identifiable information (PII) is automatically detected and processed according to established strategies. It is essential for healthcare/financial compliance, cleaning logs for customer service agents, handling sensitive user data, and more.

=== Built-in PII type
`email`, `credit_card`, `ip`, `mac_address`, `url`

=== Processing Strategy

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[strategy],
  text(weight: "bold")[Action],
  text(weight: "bold")[Example (email)],
  [`block`],
  [Exception raised — execution halts when PII is found],
  [Error Occurred],
  [`redact`],
  [Replace with `[REDACTED_TYPE]`],
  [`[REDACTED_EMAIL]`],
  [`mask`],
  [Partial masking],
  [`u***\@example.com`],
  [`hash`],
  [deterministic hashing],
  [`a1b2c3d4...`],
)

=== Scope of application
- `apply_to_input`: Check user input message
- `apply_to_output`: Check AI response message
- `apply_to_tool_results`: Check tool execution results

=== Custom Detector
In addition to the built-in PII types, you can create custom detectors in three ways:
+ _Regular Expression String_: Simple pattern matching
+ *Compiled regular expressions (`re.compile`):* complex regular expressions
+ _Function_: Advanced detection that requires validation logic (returns: `list[dict]` — contains `text`, `start`, `end` keys)

#code-block(`````python
from langchain.agents.middleware import PIIMiddleware

email_pii = PIIMiddleware("email", strategy="redact", apply_to_input=True)
card_pii = PIIMiddleware("credit_card", strategy="mask", apply_to_input=True)
`````)

#code-block(`````python
# Custom Detector: Regular Expression String
api_key_pii = PIIMiddleware(
    "api_key",
    detector=r"sk-[a-zA-Z0-9]{32}",
    strategy="block",
)
`````)

#code-block(`````python
import re

# Custom Detector: Compiled Regular Expressions
phone_pii = PIIMiddleware(
    "phone_number",
    detector=re.compile(r"\+?\d{1,3}[\s.-]?\d{3,4}[\s.-]?\d{4}"),
    strategy="mask",
)
`````)

#code-block(`````python
# Custom detector: function (SSN example)
def detect_ssn(content: str) -> list[dict]:
    matches = []
    for m in re.finditer(r"\d{3}-\d{2}-\d{4}", content):
        first = int(m.group(0)[:3])
        if first not in [0, 666] and not (900 <= first <= 999):
            matches.append({"text": m.group(0), "start": m.start(), "end": m.end()})
    return matches

ssn_pii = PIIMiddleware("ssn", detector=detect_ssn, strategy="hash")
`````)

== 1.8 LLMToolSelectorMiddleware

When there are more than 10 tools, Lightweight LLM analyzes the user query and selects only the relevant tools. This reduces token waste due to unnecessary tool descriptions and allows the model to focus on relevant tool, increasing accuracy.

=== Main parameters

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[parameters],
  text(weight: "bold")[Description],
  text(weight: "bold")[default],
  [`model`],
  [tool Model for selection],
  [Agent's main model],
  [`system_prompt`],
  [Custom Selection Guidelines],
  [Built-in prompt],
  [`max_tools`],
  [Maximum number of selections tool],
  [All],
  [`always_include`],
  [List of tool names to always include],
  [`[]`],
)

Using a lightweight model like `gpt-4.1-mini` as the model of choice allows for effective tool filtering while reducing cost.

#code-block(`````python
from langchain.agents.middleware import LLMToolSelectorMiddleware

tool_selector = LLMToolSelectorMiddleware(
    model="gpt-4.1-mini",
    max_tools=3,
    always_include=["search"],
)
`````)

== 1.9 Writing custom middleware

There are two implementation methods:

=== 1. Decorator method
Single hook, suitable for simple logic. Use the `@before_model`, `@after_model`, `@wrap_model_call`, and `@wrap_tool_call` decorators.

=== 2. Class method (`AgentMiddleware`)
If you need to combine multiple hooks or configure them, inherit `AgentMiddleware`. You can provide sync/async implementations simultaneously.

=== Custom Status
Middleware can extend agent state using the `NotRequired` type hint. This allows tracking values ​​between executions, sharing data between hooks, and implementing cross-cutting concerns such as rate limiting or audit logging.

=== Agent Jump
You can control agent flow by returning a dictionary from `after_model`, etc.:
- `{"jump_to": "end"}` — Terminate agent immediately
- Go to `{"jump_to": "tools"}` — tool execution phase
- `{"jump_to": "model"}` — Go to model call step

#code-block(`````python
from langchain.agents.middleware import before_model

@before_model
def log_before(state, runtime):
    """Record the number of messages before calling the model."""
    print(f"[LOG] {len(state.get('messages', []))} messages")
`````)

#code-block(`````python
from langchain.agents.middleware import after_model

@after_model
def validate_output(state, runtime):
    """Guard: Blocks prohibited content."""
    last = state["messages"][-1].content
    if "FORBIDDEN" in last:
        return {"jump_to": "end"}
`````)

#code-block(`````python
from langchain.agents.middleware import wrap_model_call

@wrap_model_call
def retry_on_error(request, handler):
    """In case of failure, the model call is retried up to 2 times."""
    for attempt in range(3):
        try:
            return handler(request)
        except Exception as e:
            if attempt == 2: raise
`````)

#code-block(`````python
from langchain.agents.middleware import AgentMiddleware

class AuditMiddleware(AgentMiddleware):
    def __init__(self, log_file="audit.log"):
        self.log_file = log_file
    def before_model(self, state, config):
        print(f"[AUDIT] before -> {self.log_file}")
    def after_model(self, state, config):
        print(f"[AUDIT] after -> {self.log_file}")
`````)

== 1.10 Middleware execution order

When registering multiple middleware, you can prevent unexpected behavior by accurately understanding the execution order.

`middleware=[A, B, C]` Upon registration:

#image("../../../../book/assets/diagrams/png/middleware_execution_order.png")

=== Practical tips
- _PII detection must be registered before logging_ so that PII is not included in the log.
- Place _fallback middleware_ after retry middleware, so that fallback works after a retry failure.
- If `next_fn` is not called from the `wrap` hook, all subsequent middleware and actual calls will be skipped.

#code-block(`````python
@before_model
def mw_a(state, runtime): print("before A")

@before_model
def mw_b(state, runtime): print("before B")

@before_model
def mw_c(state, runtime): print("before C")

# Run: A -> B -> C (if after_model, C -> B -> A)
`````)

== 1.11 Middleware Combination (Stacking)

In a production environment, multiple middlewares are used together to implement comprehensive agent governance. Since middleware is executed in registration order, it is recommended to place it in the following order: Security (PII) → Reliability (fallback) → Cost control (call limiting) → Context management (Summary) → Optimization (tool selection) → Supervision (HITL).

This combination allows each middleware to maintain single-responsibility principles, while collectively forming a powerful production agent pipeline.

#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.middleware import (
    PIIMiddleware, ModelFallbackMiddleware,
    ModelCallLimitMiddleware, SummarizationMiddleware,
    HumanInTheLoopMiddleware, LLMToolSelectorMiddleware,
)
from langgraph.checkpoint.memory import InMemorySaver
`````)

#code-block(`````python
middleware_stack = [
    PIIMiddleware("email", strategy="redact", apply_to_input=True),
    ModelFallbackMiddleware("gpt-4.1-mini", "claude-3-5-sonnet-20241022"),
    ModelCallLimitMiddleware(thread_limit=50, run_limit=10),
    SummarizationMiddleware(model="gpt-4.1-mini", trigger=("tokens", 4000)),
]

production_agent = create_agent(
    model="gpt-4.1", tools=[], checkpointer=InMemorySaver(), middleware=middleware_stack,
)
`````)

== 1.12 Provider-specific Middleware

While the seven built-in middleware above cover _provider-agnostic_ patterns, provider-specific middleware wires _vendor-only features_ into the agent. Capabilities that must be toggled on a provider's server — Anthropic prompt cache, Bedrock TTL cache, OpenAI Moderation API — are exposed as dedicated middleware.

=== Anthropic Prompt Caching

`langchain_anthropic.middleware.AnthropicPromptCachingMiddleware` attaches `cache_control` markers automatically at the _system prompt · tool definitions · last message_ positions when calling Claude models. Agents that repeatedly send long system prompts or RAG context can cut input-token cost by up to 90%.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Default],
  text(weight: "bold")[Description],
  [`type`],
  [`"ephemeral"`],
  [The only type Anthropic currently supports],
  [`ttl`],
  [`"5m"`],
  [`"5m"` or `"1h"` (1h is an Anthropic beta)],
  [`min_messages_to_cache`],
  [`0`],
  [Attach `cache_control` only when message count is at least this value],
  [`unsupported_model_behavior`],
  [`"warn"`],
  [When applied to non-Anthropic models: `"warn"` / `"ignore"` / `"raise"`],
)

#code-block(`````python
from langchain.agents import create_agent
from langchain_anthropic.middleware import AnthropicPromptCachingMiddleware

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    tools=[],
    middleware=[
        AnthropicPromptCachingMiddleware(
            ttl="1h",
            min_messages_to_cache=2,
            unsupported_model_behavior="warn",
        ),
    ],
)
`````)

On successive calls, check `usage_metadata.input_token_details` for `cache_creation_input_tokens` (first call) and `cache_read_input_tokens` (subsequent calls) to confirm cache hits.

=== Claude native tool middleware

Claude models are trained on native tool schemas (`bash_20250124`, `text_editor_20250728`, `memory_20250818`) that the Anthropic server interprets directly. Compared to building the same behavior with a generic `@tool` decorator, _tool-schema token usage approaches zero_ and error rates are lower. LangChain ships middleware that wraps these native tools in two variants — state-backed and filesystem-backed.

- `ClaudeBashToolMiddleware` — native bash execution tool. Takes `workspace_root`, `startup_commands`, `execution_policy` (`HostExecutionPolicy` / `DockerExecutionPolicy` / `CodexSandboxExecutionPolicy`), and `redaction_rules`. The Docker policy is the recommended default.
- `StateClaudeTextEditorMiddleware` / `FilesystemClaudeTextEditorMiddleware` — native text editor supporting `view` / `create` / `str_replace` / `insert` / `delete` / `rename`. The state variant writes into the `text_editor_files` state key; the filesystem variant writes into an actual `root_path` directory.
- `StateClaudeMemoryMiddleware` / `FilesystemClaudeMemoryMiddleware` — native memory tool that follows the `/memories/*` path contract. The state variant, combined with a checkpointer, is restored on `thread_id` resume; the filesystem variant persists to disk across process restarts.
- `StateFileSearchMiddleware` — native tool that runs `glob` / `grep` across the virtual files accumulated by the text editor or memory middleware. `state_key="text_editor_files"` is the default; switch to `"memory_files"` to search memory-side files.

#code-block(`````python
from langchain_anthropic.middleware import (
    ClaudeBashToolMiddleware,
    StateClaudeTextEditorMiddleware,
    StateClaudeMemoryMiddleware,
    StateFileSearchMiddleware,
)
from langchain.agents.middleware import DockerExecutionPolicy

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        ClaudeBashToolMiddleware(execution_policy=DockerExecutionPolicy()),
        StateClaudeTextEditorMiddleware(allowed_path_prefixes=["/src"]),
        StateClaudeMemoryMiddleware(),
        StateFileSearchMiddleware(state_key="text_editor_files"),
    ],
)
`````)

#warning-box[LangChain 1.2 `create_agent` rejects duplicate instances of the same middleware class. To search both text-editor files and memory files with `StateFileSearchMiddleware` at once, split them into separate subclasses.]

=== Bedrock Prompt Caching

In enterprise setups that call Claude/Nova through AWS Bedrock, use `langchain_aws.middleware.BedrockPromptCachingMiddleware`. Parameter names and semantics are almost identical to `AnthropicPromptCachingMiddleware`, but the target package and model-specific constraints differ.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[ChatBedrockConverse + Anthropic],
  text(weight: "bold")[ChatBedrockConverse + Nova],
  [System-prompt cache],
  [O],
  [O],
  [Tool-definition cache],
  [O],
  [X],
  [Message cache],
  [O],
  [O (excluding tool-result messages)],
  [TTL `"1h"`],
  [O],
  [X (5m only)],
)

The `type` parameter only takes effect on `ChatBedrock` (the legacy invoke-model wrapper); on `ChatBedrockConverse` it is pinned to `"default"`. For a checkpoint to actually hit, the cached block must be roughly _1,024 tokens or more_. For Nova models, pin `ttl="5m"` and set `unsupported_model_behavior="warn"` so an accidental `"1h"` is not silently ignored.

#code-block(`````python
from langchain_aws.middleware import BedrockPromptCachingMiddleware

agent = create_agent(
    model="bedrock_converse:anthropic.claude-sonnet-4-20250514-v2:0",
    tools=[],
    middleware=[
        BedrockPromptCachingMiddleware(
            ttl="1h",
            min_messages_to_cache=2,
            unsupported_model_behavior="warn",
        ),
    ],
)
`````)

=== OpenAI Content Moderation (in depth)

Here is the full parameter set for `OpenAIModerationMiddleware`, which we introduced briefly earlier. `check_tool_results` adds a scan over tool outputs before they enter the model; it is cost-effective only in pipelines that mix in _third-party authored content_ such as web search or email.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Default],
  text(weight: "bold")[Description],
  [`model`],
  [`"omni-moderation-latest"`],
  [Moderation model. Pinning to `"omni-moderation-2024-09-26"` etc. is supported],
  [`check_input`],
  [`True`],
  [Scan user messages before they reach the model],
  [`check_output`],
  [`True`],
  [Scan model-generated responses before returning],
  [`check_tool_results`],
  [`False`],
  [Scan tool outputs before they enter the model],
  [`exit_behavior`],
  [`"end"`],
  [`"end"` (end the graph) / `"error"` (raise) / `"replace"` (swap message only)],
  [`violation_message`],
  [default template],
  [Supports the `{categories}` · `{category_scores}` · `{original_content}` variables],
  [`client` / `async_client`],
  [`None`],
  [Inject a pre-configured OpenAI client (optional)],
)

#code-block(`````python
from langchain_openai.middleware import OpenAIModerationMiddleware

agent = create_agent(
    model="openai:gpt-4.1",
    tools=[search_tool],
    middleware=[
        OpenAIModerationMiddleware(
            model="omni-moderation-latest",
            check_input=True,
            check_output=True,
            check_tool_results=False,
            exit_behavior="replace",
            violation_message=(
                "A safety-policy violation was detected "
                "(categories: {categories}). The original content is not recorded."
            ),
        ),
    ],
)
`````)

#tip-box[In production it is common to always keep `check_input` on and run `check_output` under a sampling strategy (for example, 10% random sampling). The Moderation API itself adds call cost and latency.]

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Key Takeaways],
  [_Architecture_],
  [Four hooks: `before_model`, `after_model`, `wrap_model_call`, `wrap_tool_call`],
  [_7 built-in types_],
  [Summarization, HITL, ModelCallLimit, ToolCallLimit, ModelFallback, PII, LLMToolSelector],
  [_Custom_],
  [Decorator (`\@before_model`, etc.) / `AgentMiddleware` class],
  [_Execution order_],
  [`before`: forward, `after`: reverse, `wrap`: nested],
  [_Production_],
  [PII → Fallback → Limit → Summarization → ToolSelector → HITL],
  [_Provider-specific_],
  [Anthropic (caching · bash · editor · memory · search), Bedrock (caching), OpenAI (Moderation)],
)

Middleware is a powerful tool for controlling a single agent's behavior. But solving complex domain problems requires multi-agent architectures where several agents collaborate. The next chapter covers multi-agent systems that coordinate subagents with the supervisor pattern.

=== Next Steps
→ _#link("./02_multi_agent_subagents.ipynb")[02_multi_agent_subagents.ipynb]_: Multi-Agent: Learn the Subagents pattern.
