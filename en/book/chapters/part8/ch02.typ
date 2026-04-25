// Source: 08_integration/11_provider_middleware/01_anthropic_prompt_caching.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Anthropic Prompt Caching", subtitle: "Cut input-token costs by 90% with server-side caching")

`AnthropicPromptCachingMiddleware` is a Claude-only prompt cache middleware that caches long system prompts, tool definitions, and initial conversation context on Anthropic's servers for 5 minutes to 1 hour, cutting _input-token cost and latency substantially_. When the same agent is invoked many times with the same system prompt, the input-token price drops by roughly 90% from the second call onward.

#learning-header()
#learning-objectives(
  [Understand the four parameters (`type`, `ttl`, `min_messages_to_cache`, `unsupported_model_behavior`)],
  [Verify cache hits by reading `cache_creation` / `cache_read` under `usage_metadata.input_token_details`],
  [Pick between the 1-hour TTL beta and the 5-minute default],
  [Distinguish `warn` / `ignore` / `raise` behaviors when applied to non-Anthropic models],
)

== 2.1 When to use it

- Agents that send a long system prompt (multi-thousand-token corporate policy, style guide) every turn
- Setups that repeatedly send a large tool-definition list (20+ JSON schemas)
- RAG context reuse: the same document bundle across many queries
- Multi-turn conversations where the prefix context is stable

== 2.2 Environment setup

Required packages: `langchain`, `langchain-anthropic`. `ANTHROPIC_API_KEY` must be present in `.env`.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import AnthropicPromptCachingMiddleware

load_dotenv()
`````)

== 2.3 Basic usage

Passing the middleware to `create_agent`'s `middleware` list makes LangChain attach `cache_control: {"type": "ephemeral"}` markers automatically at the _system prompt · tool definitions · last message_ positions.

#code-block(`````python
long_system_prompt = (
    "You are a senior software engineer... " * 200  # ~2,000 tokens
)

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt=long_system_prompt,
    tools=[],
    middleware=[AnthropicPromptCachingMiddleware()],
)
`````)

== 2.4 Verifying cache hits

Call the same agent twice in a row and read `usage_metadata`. The first call shows a large `cache_creation_input_tokens`; subsequent calls show `cache_read_input_tokens`.

#code-block(`````python
for i in range(2):
    result = agent.invoke(
        {"messages": [{"role": "user", "content": f"Request {i}"}]},
    )
    last = result["messages"][-1]
    print(i, last.usage_metadata.get("input_token_details"))
`````)

#output-block(`````
0 {'cache_creation': 2048, 'cache_read': 0}
1 {'cache_creation': 0, 'cache_read': 2048}
`````)

== 2.5 Full parameters

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
  [Cache duration. `"5m"` or `"1h"`. 1 hour is an Anthropic beta],
  [`min_messages_to_cache`],
  [`0`],
  [Attach `cache_control` only when the message count is at least this value],
  [`unsupported_model_behavior`],
  [`"warn"`],
  [For non-Anthropic models: `"warn"` / `"ignore"` / `"raise"`],
)

=== 1-hour TTL example

#code-block(`````python
AnthropicPromptCachingMiddleware(
    ttl="1h",
    min_messages_to_cache=2,
)
`````)

The 1-hour cache is a fit for scenarios where _the same system prompt is reused over many hours_ — long advisory sessions, daily batch analytics. The 5-minute default targets continuous user input in a real-time chatbot.

== 2.6 Behavior on non-Anthropic models

Because this middleware injects `cache_control` blocks internally, other providers' models either ignore them or error. In pipelines where the model can be swapped, make `unsupported_model_behavior` explicit.

#code-block(`````python
# Log a warning and continue
AnthropicPromptCachingMiddleware(unsupported_model_behavior="warn")

# Silently skip
AnthropicPromptCachingMiddleware(unsupported_model_behavior="ignore")

# Fail immediately (CI / tests)
AnthropicPromptCachingMiddleware(unsupported_model_behavior="raise")
`````)

== 2.7 Differences from Bedrock

When calling Claude via AWS Bedrock, use `BedrockPromptCachingMiddleware` (ch7). The two middleware share parameter names and semantics, but they target _different packages_ and have different TTL constraints (Nova supports only 5m, no tool-definition cache).

== Key Takeaways

- Agents that repeatedly send long system prompts / tool definitions cut input-token cost by 90%
- Verify cache hits by watching `cache_creation_input_tokens` move to `cache_read_input_tokens`
- TTL `"5m"` for real-time conversation, `"1h"` for long-running batches / advisory sessions
- Declare `unsupported_model_behavior="warn"` in multi-provider pipelines to avoid silent failures
