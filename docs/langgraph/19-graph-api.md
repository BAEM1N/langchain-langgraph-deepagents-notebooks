# LangGraph API Overview - Complete Documentation

## Core Concepts

LangGraph models agent workflows as graphs using three fundamental components:

1. **State**: A shared data structure representing the application's current snapshot, typically defined using TypedDict or Pydantic models
2. **Nodes**: Functions encoding agent logic that receive state, perform computation, and return updated state
3. **Edges**: Functions determining which node executes next based on current state

As the documentation states: *"nodes do the work, edges tell what to do next."*

## Graph Execution Model

LangGraph uses message passing inspired by Google's Pregel system. Execution proceeds in discrete "super-steps" where:

- Nodes begin in an inactive state
- A node becomes active when receiving messages on incoming edges
- Active nodes execute their functions and respond with updates
- At each super-step's end, nodes with no incoming messages mark themselves inactive
- Execution terminates when all nodes are inactive and no messages are in transit

## StateGraph

`StateGraph` is the primary graph class, parameterized by a user-defined State object. Graphs must be compiled before use via the `.compile()` method, which performs structural validation and enables runtime configuration like checkpointers and breakpoints.

## State Definition

### Schema Options

State schemas can be defined using:
- **TypedDict** (recommended for most cases)
- **Dataclass** (when default values are needed)
- **Pydantic BaseModel** (for recursive validation, though less performant)

### Multiple Schemas

Graphs support multiple schema layers:
- Input schema: constrains graph inputs
- Internal/overall schema: contains all keys for graph operations
- Output schema: constrains graph outputs
- Private schema: for internal node communication only

Key insight: "A node *can write to any state channel in the graph state.*"

### Reducers

Reducers specify how node updates apply to state. Each state key has an independent reducer function.

**Default behavior**: Updates override existing values

**Custom reducers**: Using `Annotated` with operators like `operator.add` to append instead of overwrite

**Special case**: The `add_messages` function intelligently handles message updates by tracking IDs and deserializing JSON into LangChain Message objects.

### MessagesState

A prebuilt state class with a single `messages` key using `add_messages` as the reducer. Commonly subclassed to add additional fields like documents or metadata.

## Nodes

Nodes are Python functions (sync or async) accepting:
- `state`: The graph's current state
- `config`: A RunnableConfig object with thread_id and tracing info
- `runtime`: A Runtime object with context and additional information

Nodes are automatically converted to `RunnableLambda` objects, adding batch and async support plus native tracing.

### Special Nodes

- **START**: Represents user input entry point
- **END**: Represents terminal nodes

### Node Caching

Nodes support caching based on input hash. Implementation requires:
- Specifying a cache at compilation
- Defining cache policies with optional `key_func` and `ttl` parameters

## Edges

Edges determine control flow and support four types:

### Normal Edges
Direct transitions from one node to another using `add_edge()`.

### Conditional Edges
Routes determined by a function using `add_conditional_edges()`. The routing function receives state and returns target node name(s) or values mapped to node names.

### Entry Points
Define initial nodes via edges from START. Can be static or conditional.

### Multiple Outgoing Edges
If a node has multiple outgoing edges, all destination nodes execute in parallel as part of the next super-step.

## Advanced Control Flow

### Send

The `Send` object allows returning multiple dynamically-created edges with different state variants from a conditional edge--useful for map-reduce patterns where downstream state differs per operation.

### Command

A versatile primitive supporting:
- `update`: Apply state updates
- `goto`: Navigate to specific nodes
- `graph`: Target parent graphs from subgraphs
- `resume`: Provide values after interrupts

Returned from nodes to combine state updates with control flow in a single step. Supports dynamic routing without overriding static edges.

## Graph Migrations

LangGraph handles topology changes gracefully:

- **Finished threads**: Support complete graph restructuring
- **Interrupted threads**: Allow topology changes except node removal/renaming
- **State changes**: Full backwards/forwards compatibility for adding/removing keys

## Runtime Configuration

### Context Schema

Specify a `context_schema` to pass dependencies to nodes that aren't part of graph state (like LLM providers or database connections). Access via `runtime.context` parameter.

### Recursion Limits

The `recursion_limit` controls maximum super-steps per execution (default: 1000). Access current step via `config["metadata"]["langgraph_step"]`.

The `RemainingSteps` managed value tracks steps remaining before hitting the limit, enabling graceful degradation strategies.

### Metadata Access

Available in `config["metadata"]`:
- `langgraph_step`: Current iteration count
- `langgraph_node`: Current node name
- `langgraph_triggers`: What triggered current node
- `langgraph_path`: Execution path
- `langgraph_checkpoint_ns`: Checkpoint namespace

## Observability

LangGraph integrates with LangSmith for tracing, debugging, and evaluation of agent behavior.

## Visualization

Built-in visualization capabilities exist for graphs of any complexity--see how-to guides for implementation details.
