// Source: 08_integration/README.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "Integration Category Overview", subtitle: "A map of the LangChain ecosystem")

LangChain · LangGraph · Deep Agents take the shape of a common agent interface beneath which _per-provider implementations_ plug in. Parts II–IV focused on "how to use the agent"; this Part focuses on "_what_ you connect the agent to". We scan the twelve integration categories and lay out the representative packages and selection criteria for each.

#learning-header()
#learning-objectives(
  [Survey the twelve integration categories of the LangChain ecosystem],
  [Understand why Provider Middleware is a separate category],
  [Distinguish vendor-sensitive areas (Chat Models, Vector Stores) from standardized ones (Middleware, Checkpointers)],
  [Map the seven Provider Middleware chapters this Part covers],
)

== 1.1 Baseline version snapshot

The code in this Part assumes the following versions. Check the latest releases in `docs/skills/langchain-dependencies.md`.

- `langchain` 1.2
- `langgraph` 1.1
- `deepagents` 0.5.0

#warning-box[LangChain 1.2 `create_agent` rejects _duplicate instances_ of the same middleware class. If you hit `AssertionError: Please remove duplicate middleware instances.`, split the two instances into separate types via subclassing.]

== 1.2 The twelve integration categories

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Category],
  text(weight: "bold")[Representative packages],
  text(weight: "bold")[Selection criteria],
  [Chat Models],
  [`langchain-openai`, `langchain-anthropic`, `langchain-google-genai`, `langchain-aws`],
  [Model performance · cost · regional requirements],
  [Embeddings],
  [`langchain-openai`, `langchain-cohere`, `langchain-voyageai`],
  [Domain benchmarks · license · multilingual support],
  [Vector Stores],
  [`langchain-chroma`, `langchain-pinecone`, `langchain-pgvector`],
  [Operational scale · metadata filtering · managed option],
  [Document Loaders],
  [`langchain-community.document_loaders`],
  [Source format (PDF, Notion, Slack, etc.)],
  [Retrievers],
  [`langchain.retrievers`, vendor-specific retrievers],
  [Hybrid search · MMR · reranker integration],
  [Text Splitters],
  [`langchain-text-splitters`],
  [Language · structure (code vs prose) · overlap strategy],
  [Tools],
  [`langchain-community.tools`, MCP tools],
  [External API integration · auth methods · call constraints],
  [Checkpointers],
  [`langgraph-checkpoint-postgres`, `-sqlite`],
  [Durability needs · multi-tenancy · backup strategy],
  [Stores],
  [`langgraph-store-postgres`, vendor-managed],
  [Persistent memory scale · lookup method (key / vector)],
  [Sandboxes],
  [`langchain-daytona`, `langchain-modal`, `langchain-runloop`],
  [Isolation level · cold-start · cost],
  [Provider Middleware],
  [`langchain-anthropic`, `langchain-aws`, `langchain-openai`],
  [Provider-specific features (caching · native tools · policy)],
  [Observability],
  [`langsmith`, `langfuse`, OpenTelemetry],
  [SaaS vs self-hosted · PII policy],
)

Provider Middleware wraps features that are activated _on the provider's servers_ (prompt caching, native tools, content policy) into the LangChain middleware format. Official docs often mention them in a single line, so there is a lot of value in organizing them as working code. Chapters 2–8 of this Part each cover one of the seven middleware.

== 1.3 Provider Middleware roadmap

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Chapter],
  text(weight: "bold")[Middleware],
  text(weight: "bold")[Effect],
  [2],
  [`AnthropicPromptCachingMiddleware`],
  [Server-side cache for long system prompts / tool definitions (5m / 1h)],
  [3],
  [`ClaudeBashToolMiddleware`],
  [Claude native bash tool + three execution policies],
  [4],
  [`StateClaudeTextEditorMiddleware` / `FilesystemClaudeTextEditorMiddleware`],
  [Six operations of the native text editor],
  [5],
  [`StateClaudeMemoryMiddleware` / `FilesystemClaudeMemoryMiddleware`],
  [Model self-memory via the `/memories/*` path contract],
  [6],
  [`StateFileSearchMiddleware`],
  [glob / grep over virtual files in state],
  [7],
  [`BedrockPromptCachingMiddleware`],
  [Cache for Claude / Nova through AWS Bedrock],
  [8],
  [`OpenAIModerationMiddleware`],
  [Pre- / post-check via OpenAI Moderation API],
)

== 1.4 Common pattern

Every chapter in this Part shares the same three-step loop.

+ *Environment setup* — put the provider key in `.env` and install the package
+ *Basic usage* — flip the feature on with one line, `create_agent(..., middleware=[Middleware()])`
+ *Validation* — read `usage_metadata`, `tool_calls`, or the Moderation response to confirm the feature actually ran

#tip-box[Provider-specific middleware needs _a matching model_. If you attach Anthropic middleware to an OpenAI model, behavior is governed by `unsupported_model_behavior` — either a warning or an exception. In multi-provider pipelines, watch the order when combining with `ModelFallbackMiddleware`.]

== Key Takeaways

- Integrations are organized into twelve categories, each sharing the "provider plugin + common interface" structure
- Provider Middleware is the category that wraps provider _server-side_ features as LangChain middleware
- Chapters 2–8 cover the seven Provider Middleware with runnable code, one per chapter
- Duplicate-instance constraints, model matching, and multi-provider fallback are the common concerns of Provider Middleware
