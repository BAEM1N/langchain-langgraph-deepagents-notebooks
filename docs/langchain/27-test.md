# Agent Testing Documentation

## Overview
The documentation explains that agentic applications require thorough testing because their non-deterministic nature makes it difficult to predict how changes affect overall behavior. Testing is organized into three categories:

**Unit tests** exercise small, deterministic pieces of your agent in isolation using in-memory fakes for quick assertions. **Integration tests** use real network calls to confirm that components work together, credentials align, and latency is acceptable. **Evals** use evaluators to assess your agent's execution trajectory, either via deterministic matching or an LLM judge — promoting evaluation to a first-class axis alongside unit and integration coverage.

Use **LangSmith** to run evaluations at scale, track results over time, and compare experiments.

## Unit Testing Approaches

### Mocking Chat Models
LangChain provides `GenericFakeChatModel` for mocking responses without API calls. This tool accepts an iterator of responses and returns one per invocation, supporting both regular and streaming usage patterns.

### State Persistence Testing
The `InMemorySaver` checkpointer enables simulating multiple conversation turns to test state-dependent behavior by maintaining context across invocations using thread identifiers.

## Evals

Evals evaluate agent trajectories with deterministic matching or LLM-as-judge evaluators. See sub-guide for full details on `agentevals`, trajectory match modes, and LangSmith integration.

The `agentevals` package offers evaluators designed specifically for agent trajectory testing. Two main evaluation strategies exist:

**Trajectory match** involves hard-coding expected sequences and performing step-by-step comparisons—ideal for well-defined workflows but requiring specific tool-call expectations.

**LLM-as-judge** uses an LLM to qualitatively assess execution trajectories against rubrics, offering flexibility for nuanced evaluation but requiring additional LLM calls.

### Trajectory Match Modes

Four matching modes accommodate different requirements:

- `strict`: Exact message and tool-call ordering
- `unordered`: Same tools in any sequence
- `subset`: Agent calls only reference tools
- `superset`: Agent calls at least reference tools

## Testing Tools & Integration

The documentation covers async support for evaluators, LangSmith integration for running evaluations at scale, tracking results, and comparing experiments over time, plus HTTP request recording/replaying using `vcrpy` and `pytest-recording` to reduce API costs during CI/CD testing.

> Detailed coverage of `GenericFakeChatModel`, `InMemorySaver`, `agentevals`, and the four trajectory match modes (`strict` / `unordered` / `subset` / `superset`) is preserved above and in the LangSmith sub-guides.
