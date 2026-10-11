// Source: 08_integration/README.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "Integration Category Overview", subtitle: "A map of the LangChain ecosystem")

LangChain · LangGraph · Deep Agents take the shape of a common agent interface beneath which _per-provider implementations_ plug in. Parts II–IV focused on "how to use the agent"; this Part focuses on "_what_ you connect the agent to". We scan the thirteen integration categories and lay out the representative packages and selection criteria for each.

#learning-header()
#learning-objectives(
  [Survey the thirteen integration categories of the LangChain ecosystem],
  [Understand why Provider Middleware is a separate category],
  [Distinguish vendor-sensitive areas (Chat Models, Vector Stores) from standardized ones (Middleware, Checkpointers)],
  [Map the seven Provider Middleware chapters this Part covers],
)

== 1.1 Baseline version snapshot

The code in this Part assumes the following versions. Check the latest releases in `docs/skills/langchain-dependencies.md`.

- `langchain` 1.3+ (event streaming v3)
- `langgraph` 1.2+ (per-node timeout · `DeltaChannel` · graceful shutdown)
- `deepagents` 0.6.1+ (`CodeInterpreterMiddleware`, async subagents, interpreter snapshots)

#warning-box[LangChain 1.2 `create_agent` rejects _duplicate instances_ of the same middleware class. If you hit `AssertionError: Please remove duplicate middleware instances.`, split the two instances into separate types via subclassing.]

== 1.2 The thirteen integration categories

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
  [Providers (Hosted Runtime)],
  [LangGraph Platform, Anthropic Skills, OpenAI Agents],
  [Managed runtime vs self-hosted · SDK compatibility],
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


== 1.4 New integration surfaces: UI · Code · resilience

As of 2026, integration scope does not stop at provider middleware. These surfaces do not change the thirteen-category count in this Part; treat them as _connection styles_ layered on top of the existing categories.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Surface],
  text(weight: "bold")[Core idea],
  text(weight: "bold")[Where it connects in this book],
  [Generative UI / AG-UI],
  [controlled · declarative · open-ended UI generation and the frontend/server event boundary],
  [Parts 2/3 agent state and streaming; Part 8 provider/runtime integration],
  [Deep Agents Code],
  [`/oss/deepagents/code` configuration · approval · extensions · plugins · MCP tools],
  [Part 4 permissions/skills/subagents/backends, specialized for coding-agent runtime],
  [RAG · fault tolerance · multimodal],
  [retrieval, checkpointer/retry/resume, and multimodal `read_file` combined with the Deep Agents filesystem],
  [Parts 4/5/7 core agent, advanced patterns, and examples],
)

Generative UI splits by how much control the model has over the UI: controlled, declarative, and open-ended. AG-UI connects that flow through an event protocol between a frontend and an agent server. This chapter therefore marks it as a frontend integration track after state, streaming, and hosted runtime concepts, without inventing a new notebook or setup path.

Deep Agents Code covers production surfaces for coding agents: `configuration`, `approval`, `extensions`, `plugins`, and `MCP tools`. Those are the same conceptual families as permissions, skills, subagents, and backends from Part 4, narrowed to a coding-agent runtime. No new credential or environment variable is assumed here.

RAG, fault tolerance, and multimodal are combinations of existing axes, not new categories. RAG combines Retriever/Vector Store components with Deep Agents file context. Fault tolerance connects LangGraph checkpointers, retries, and resumability to production operations. Multimodal is the question of passing image/PDF/audio/video files through `read_file` within each provider's limits.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Official reference],
  text(weight: "bold")[What to check],
  [#link("https://docs.langchain.com/oss/python/langchain/frontend/generative-ui")[LangChain Generative UI]],
  [controlled/declarative/open-ended UI patterns],
  [#link("https://docs.langchain.com/oss/python/deepagents/ag-ui")[Deep Agents AG-UI]],
  [frontend/server integration event boundary],
  [#link("https://docs.langchain.com/oss/deepagents/code/configuration")[Deep Agents Code configuration]],
  [coding-agent runtime configuration],
  [#link("https://docs.langchain.com/oss/deepagents/code/approval-modes")[Code approval modes]],
  [pre-execution approval policy and permission boundaries],
  [#link("https://docs.langchain.com/oss/deepagents/code/extensions")[Code extensions]],
  [runtime feature extension and skill/memory wiring],
  [#link("https://docs.langchain.com/oss/deepagents/code/plugins")[Code plugins]],
  [external tool bundles and deployment units],
  [#link("https://docs.langchain.com/oss/python/deepagents/fault-tolerance")[Deep Agents fault tolerance]],
  [retry, resume, checkpointer, and operational resilience],
  [#link("https://docs.langchain.com/oss/python/deepagents/multimodal")[Deep Agents multimodal]],
  [file backends and multimodal input handling],
  [#link("https://docs.langchain.com/oss/python/deepagents/rag")[Deep Agents RAG]],
  [retrieval, file context, and subagent composition],
)

== 1.5 Common pattern

Every chapter in this Part shares the same three-step loop.

+ *Environment setup* — put the provider key in `.env` and install the package
+ *Basic usage* — flip the feature on with one line, `create_agent(..., middleware=[Middleware()])`
+ *Validation* — read `usage_metadata`, `tool_calls`, or the Moderation response to confirm the feature actually ran

#tip-box[Provider-specific middleware needs _a matching model_. If you attach Anthropic middleware to an OpenAI model, behavior is governed by `unsupported_model_behavior` — either a warning or an exception. In multi-provider pipelines, watch the order when combining with `ModelFallbackMiddleware`.]

== 1.6 Observability env-var standardization

From LangChain 1.1, tracing-related environment variables were standardized from `LANGCHAIN_*` to `LANGSMITH_*`. The old names continue to work for a while for compatibility, but _new code uses the new names exclusively_.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Variable],
  text(weight: "bold")[Role],
  text(weight: "bold")[Notes],
  [`LANGSMITH_TRACING`],
  [Enable tracing (`true` / `false`)],
  [Auto-instruments every `create_agent` run],
  [`LANGSMITH_API_KEY`],
  [LangSmith account key],
  [`ls__` prefix],
  [`LANGSMITH_PROJECT`],
  [Project name for trace grouping],
  [Per-call overridable via `tracing_context`],
  [`LANGSMITH_ENDPOINT`],
  [Endpoint for self-hosted LangSmith],
  [Optional — unneeded for SaaS],
)

== Key Takeaways

- Integrations are organized into thirteen categories, each sharing the "provider plugin + common interface" structure
- Provider Middleware is the category that wraps provider _server-side_ features as LangChain middleware
- Chapters 2–8 cover the seven Provider Middleware with runnable code, one per chapter
- Generative UI/AG-UI, Deep Agents Code, and RAG/fault tolerance/multimodal are not new notebook categories here; read them as extensions of state, streaming, backend, retrieval, and operations concepts
- Duplicate-instance constraints, model matching, and multi-provider fallback are the common concerns of Provider Middleware
