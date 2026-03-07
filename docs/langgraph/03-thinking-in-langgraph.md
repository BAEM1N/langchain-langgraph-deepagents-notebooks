# Thinking in LangGraph - Complete Documentation

## Overview

This guide teaches developers how to architect AI agents using LangGraph by breaking workflows into discrete steps called **nodes** that communicate through shared **state**.

## The Five-Step Process

### Step 1: Map Workflow as Discrete Steps

Begin by identifying distinct process steps, each becoming a node (single-purpose function). The documentation uses a customer support email agent example with these nodes:

- **Read Email**: Extract and parse content
- **Classify Intent**: Categorize urgency and topic via LLM
- **Doc Search**: Query knowledge base
- **Bug Track**: Create tracking tickets
- **Draft Reply**: Generate responses
- **Human Review**: Escalate for approval
- **Send Reply**: Dispatch responses

Key principle: "Some nodes make decisions about where to go next (`Classify Intent`, `Draft Reply`, `Human Review`), while others always proceed to the same next step."

### Step 2: Identify Operation Types

Four categories guide node implementation:

**LLM Steps** - Use for understanding, analysis, text generation, or reasoning decisions (examples: classify intent, draft replies)

**Data Steps** - Retrieve external information with retry strategies and optional caching (examples: document search, customer history lookup)

**Action Steps** - Perform external operations with retry policies and execution timing (examples: send emails, create tickets)

**User Input Steps** - Pause for human intervention with decision context and expected input formats

### Step 3: Design State Structure

State represents shared memory accessible to all nodes. The documentation emphasizes: "Your state should store raw data, not formatted text. Format prompts inside nodes when you need them."

Key principle: Include data that persists across steps; derive other data on-demand rather than storing it.

Example state structure for the email agent includes:
- Raw email data (content, sender, ID)
- Classification results
- Search/API results
- Generated content (draft responses)
- Execution metadata

### Step 4: Build Node Functions

Nodes are Python functions accepting current state and returning state updates. Error handling varies by type:

| Error Type | Handler | Strategy |
|-----------|---------|----------|
| Transient (network, rate limits) | System | Retry policy |
| LLM-recoverable (tool failures) | LLM | Store error, loop back |
| User-fixable (missing info) | Human | Pause with interrupt() |
| Unexpected | Developer | Bubble up |

Code example structure: nodes use `Command` objects for routing decisions with type hints like `Command[Literal["node1", "node2"]]`.

### Step 5: Wire Together

Connect nodes using minimal essential edges. Routing happens within nodes through `Command` objects. Enable human-in-the-loop by compiling with a checkpointer:

```python
from langgraph.checkpoint.memory import MemorySaver
memory = MemorySaver()
app = workflow.compile(checkpointer=memory)
```

The `interrupt()` function pauses execution indefinitely, saves state, and resumes exactly where execution stopped when input is provided.

## Core Insights

1. **Decomposition enables streaming, durable execution with pause/resume, and clear debugging** through state inspection between steps

2. **State holds raw data** allowing different nodes to format information differently for their specific needs

3. **Nodes are pure functions** taking state and returning updates with explicit routing declarations

4. **Error handling is flow-integrated**, with different strategies for different failure modes

5. **Human input is first-class** - `interrupt()` must come first in node code before additional operations

6. **Control flow emerges naturally** from node routing logic, keeping workflows explicit and traceable

## Advanced Considerations

**Node Granularity Trade-offs**: Smaller nodes create more frequent checkpoints, reducing re-execution on failures, but larger nodes simplify flow. Choose based on resilience needs, external service isolation, and debugging requirements.

**Durability Modes**: LangGraph writes checkpoints asynchronously by default with minimal performance impact, or supports `"exit"` (completion-only) and `"sync"` (blocking) modes.

## Next Steps

The documentation recommends exploring:
- Human-in-the-loop patterns
- Subgraphs for complex operations
- Streaming for real-time progress
- Observability with LangSmith
- Tool integration
- Retry logic with exponential backoff
