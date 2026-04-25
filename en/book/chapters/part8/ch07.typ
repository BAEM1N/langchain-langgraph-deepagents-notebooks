// Source: 08_integration/11_provider_middleware/06_bedrock_prompt_caching.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Bedrock Prompt Caching", subtitle: "Claude / Nova caching through AWS")

When calling Claude / Nova through AWS Bedrock, `BedrockPromptCachingMiddleware` plants cache checkpoints automatically at the _system prompt · tool definitions · last message_ positions to reduce input-token cost. Parameter names and semantics are _almost identical_ to `AnthropicPromptCachingMiddleware` (ch2), but the target package and per-model constraints differ.

#learning-header()
#learning-objectives(
  [Understand the four parameters of `BedrockPromptCachingMiddleware`],
  [Verify hits via `cache_creation` / `cache_read` in `usage_metadata.input_token_details`],
  [Know how `type` is handled differently between `ChatBedrock` and `ChatBedrockConverse`],
  [Distinguish Nova constraints (5m TTL only, no tool-definition cache)],
)

== 7.1 When to use it

- Enterprise setups that must keep LLM calls inside AWS account / VPC boundaries (via Bedrock)
- Using Claude through _Bedrock billing_ rather than the direct Anthropic API
- Repeated use of long system prompts with Amazon Nova

== 7.2 Environment setup

Required packages: `langchain`, `langchain-aws`. AWS credentials (`AWS_ACCESS_KEY_ID` etc.) and a region must be configured via `.env` or environment. In the Bedrock console you also need to grant _model access_ before the call works.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_aws.middleware import BedrockPromptCachingMiddleware

load_dotenv()
`````)

== 7.3 ChatBedrockConverse + Claude (recommended)

The Converse API is Bedrock's _unified interface_ and can call many models through the same endpoint. Adding `BedrockPromptCachingMiddleware` automatically inserts cache checkpoints at the system / tool / last-message positions.

#warning-box[For a checkpoint to actually hit, the cached block must be _roughly 1,024 tokens or more_. On short system prompts, `cache_creation` may not register.]

#code-block(`````python
long_prompt = (
    "You are an enterprise policy assistant. Always cite section numbers. "
    * 200  # ~2,000 tokens
)

agent = create_agent(
    model="bedrock_converse:anthropic.claude-sonnet-4-20250514-v2:0",
    system_prompt=long_prompt,
    tools=[],
    middleware=[BedrockPromptCachingMiddleware(ttl="1h")],
)
`````)

== 7.4 Verifying cache hits

Call twice in a row and read `usage_metadata.input_token_details` to confirm cache creation / hits.

#code-block(`````python
for i in range(2):
    result = agent.invoke(
        {"messages": [{"role": "user", "content": f"Request {i}"}]},
    )
    last = result["messages"][-1]
    print(i, last.usage_metadata.get("input_token_details"))
`````)

`cache_creation` is large on the first call; `cache_read` fills in on subsequent calls.

== 7.5 Full parameters

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
  [Only takes effect on `ChatBedrock`; `ChatBedrockConverse` ignores it and uses `"default"`],
  [`ttl`],
  [`"5m"`],
  [`"5m"` or `"1h"`. _Nova-class models support `"5m"` only_],
  [`min_messages_to_cache`],
  [`0`],
  [Attach a cache checkpoint only when the message count is at least this value],
  [`unsupported_model_behavior`],
  [`"warn"`],
  [For cache-unsupported models: `"ignore"` / `"warn"` / `"raise"`],
)

== 7.6 ChatBedrock (Invoke model) example

`ChatBedrock` is the legacy invoke-model wrapper. `BedrockPromptCachingMiddleware` supports it too, and the `type="ephemeral"` parameter _does_ take effect here. On the ChatBedrock side, for Anthropic models, both tool-definition caching and the extended TTL (1h) are supported.

#code-block(`````python
from langchain_aws import ChatBedrock

model = ChatBedrock(model_id="anthropic.claude-sonnet-4-20250514-v2:0")

agent = create_agent(
    model=model,
    system_prompt=long_prompt,
    tools=[],
    middleware=[
        BedrockPromptCachingMiddleware(type="ephemeral", ttl="1h"),
    ],
)
`````)

== 7.7 Amazon Nova constraints

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

When targeting Nova, pin `ttl="5m"` and set `unsupported_model_behavior="warn"` so an accidental `"1h"` is not silently ignored.

== Key Takeaways

- When using Claude / Nova inside AWS boundaries, the Bedrock middleware reduces input-token cost
- Be aware of the `type` parameter difference between `ChatBedrock` and `ChatBedrockConverse`
- Nova supports 5m TTL only with no tool-definition cache — pin `ttl="5m"`
- Cache blocks must be roughly 1,024 tokens or more to actually hit
