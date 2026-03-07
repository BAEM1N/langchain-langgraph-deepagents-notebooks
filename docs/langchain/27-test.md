# Agent Testing Documentation

## Overview
The documentation explains that agentic applications require thorough testing because their non-deterministic nature makes it difficult to predict how changes affect overall behavior. Two primary testing approaches are recommended:

**Unit tests** isolate small, deterministic pieces using in-memory fakes for quick assertions. **Integration tests** use real network calls to verify components work together, credentials align, and latency is acceptable. Agentic systems typically emphasize integration testing due to their multi-component chaining requirements.

## Unit Testing Approaches

### Mocking Chat Models
LangChain provides `GenericFakeChatModel` for mocking responses without API calls. This tool accepts an iterator of responses and returns one per invocation, supporting both regular and streaming usage patterns.

### State Persistence Testing
The `InMemorySaver` checkpointer enables simulating multiple conversation turns to test state-dependent behavior by maintaining context across invocations using thread identifiers.

## Integration Testing with AgentEvals

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

The documentation covers async support for evaluators, LangSmith integration for experiment tracking, and HTTP request recording/replaying using `vcrpy` and `pytest-recording` to reduce API costs during CI/CD testing.
