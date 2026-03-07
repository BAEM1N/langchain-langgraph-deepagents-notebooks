# Complete Documentation: Prebuilt Middleware for LangChain Agents

## Overview

LangChain and Deep Agents offer production-ready middleware for common agent use cases. These tools are provider-agnostic or optimized for specific LLM providers.

## Provider-Agnostic Middleware

### Summarization

**Purpose**: Automatically compress conversation history when approaching token limits while preserving recent messages.

**Use Cases**:
- Long-running conversations exceeding context windows
- Multi-turn dialogues with extensive history
- Applications requiring full conversation context preservation

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import SummarizationMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[your_weather_tool, your_calculator_tool],
    middleware=[
        SummarizationMiddleware(
            model="gpt-4.1-mini",
            trigger=("tokens", 4000),
            keep=("messages", 20),
        ),
    ],
)
```

**Key Parameters**:
- `model`: Chat model for generating summaries
- `trigger`: Conditions for starting summarization (tokens, messages, or fraction)
- `keep`: How much context to preserve after summarization
- `token_counter`: Custom token counting function
- `summary_prompt`: Custom prompt template

---

### Human-in-the-Loop

**Purpose**: Pause execution for human approval, editing, or rejection of tool calls.

**Use Cases**:
- High-stakes operations (database writes, financial transactions)
- Compliance workflows requiring human oversight
- Long-running conversations guided by human feedback

**Requirement**: Needs a checkpointer to maintain state across interruptions.

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    model="gpt-4.1",
    tools=[your_read_email_tool, your_send_email_tool],
    checkpointer=InMemorySaver(),
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "your_send_email_tool": {
                    "allowed_decisions": ["approve", "edit", "reject"],
                },
                "your_read_email_tool": False,
            }
        ),
    ],
)
```

---

### Model Call Limit

**Purpose**: Restrict the number of model calls to prevent infinite loops and excessive costs.

**Use Cases**:
- Preventing runaway agents from excessive API calls
- Enforcing production deployment cost controls
- Testing agent behavior within call budgets

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import ModelCallLimitMiddleware
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    model="gpt-4.1",
    checkpointer=InMemorySaver(),
    tools=[],
    middleware=[
        ModelCallLimitMiddleware(
            thread_limit=10,
            run_limit=5,
            exit_behavior="end",
        ),
    ],
)
```

**Key Parameters**:
- `thread_limit`: Maximum calls across all runs in a thread
- `run_limit`: Maximum calls per single invocation
- `exit_behavior`: "end" (graceful termination) or "error" (raise exception)

---

### Tool Call Limit

**Purpose**: Control tool execution by limiting call counts globally or per-tool.

**Use Cases**:
- Preventing excessive calls to expensive external APIs
- Limiting web searches or database queries
- Enforcing rate limits on specific tool usage
- Protecting against runaway agent loops

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import ToolCallLimitMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, database_tool],
    middleware=[
        # Global limit
        ToolCallLimitMiddleware(thread_limit=20, run_limit=10),
        # Tool-specific limit
        ToolCallLimitMiddleware(
            tool_name="search",
            thread_limit=5,
            run_limit=3,
        ),
    ],
)
```

**Key Parameters**:
- `tool_name`: Specific tool to limit (omit for global limits)
- `thread_limit`: Maximum calls across all runs in a conversation
- `run_limit`: Maximum calls per single invocation
- `exit_behavior`: "continue" (block with error), "error" (raise exception), or "end" (stop immediately)

---

### Model Fallback

**Purpose**: Automatically switch to alternative models when the primary model fails.

**Use Cases**:
- Building resilient agents handling model outages
- Cost optimization by falling back to cheaper alternatives
- Provider redundancy across multiple LLM services

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import ModelFallbackMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[],
    middleware=[
        ModelFallbackMiddleware(
            "gpt-4.1-mini",
            "claude-3-5-sonnet-20241022",
        ),
    ],
)
```

---

### PII Detection

**Purpose**: Detect and handle Personally Identifiable Information using configurable strategies.

**Use Cases**:
- Healthcare and financial applications with compliance requirements
- Customer service agents sanitizing logs
- Applications handling sensitive user data

**Built-in PII Types**: email, credit_card, ip, mac_address, url

**Strategies**: "block" (raise exception), "redact" (replace with [REDACTED_TYPE]), "mask" (partial masking), "hash" (deterministic hashing)

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import PIIMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[],
    middleware=[
        PIIMiddleware("email", strategy="redact", apply_to_input=True),
        PIIMiddleware("credit_card", strategy="mask", apply_to_input=True),
    ],
)
```

**Custom Detectors** (three methods):

**Method 1: Regex string**
```python
PIIMiddleware(
    "api_key",
    detector=r"sk-[a-zA-Z0-9]{32}",
    strategy="block",
)
```

**Method 2: Compiled regex**
```python
import re
PIIMiddleware(
    "phone_number",
    detector=re.compile(r"\+?\d{1,3}[\s.-]?\d{3,4}[\s.-]?\d{4}"),
    strategy="mask",
)
```

**Method 3: Custom function**
```python
def detect_ssn(content: str) -> list[dict[str, str | int]]:
    import re
    matches = []
    pattern = r"\d{3}-\d{2}-\d{4}"
    for match in re.finditer(pattern, content):
        ssn = match.group(0)
        first_three = int(ssn[:3])
        if first_three not in [0, 666] and not (900 <= first_three <= 999):
            matches.append({
                "text": ssn,
                "start": match.start(),
                "end": match.end(),
            })
    return matches

PIIMiddleware(
    "ssn",
    detector=detect_ssn,
    strategy="hash",
)
```

**Configuration Parameters**:
- `pii_type`: Built-in type or custom name
- `strategy`: How to handle detected PII
- `detector`: Custom detection function or regex
- `apply_to_input`: Check user messages
- `apply_to_output`: Check AI messages
- `apply_to_tool_results`: Check tool results

---

### To-Do List

**Purpose**: Equip agents with task planning and tracking capabilities.

**Use Cases**:
- Complex multi-step tasks requiring tool coordination
- Long-running operations needing progress visibility

**Feature**: Automatically provides `write_todos` tool and system prompts for planning.

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import TodoListMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[read_file, write_file, run_tests],
    middleware=[TodoListMiddleware()],
)
```

**Parameters**:
- `system_prompt`: Custom planning instructions
- `tool_description`: Custom description for `write_todos` tool

---

### LLM Tool Selector

**Purpose**: Use an LLM to intelligently select relevant tools before main model execution.

**Use Cases**:
- Agents with many tools (10+) where most aren't relevant per query
- Reducing token usage by filtering irrelevant tools
- Improving model focus and accuracy

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import LLMToolSelectorMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[tool1, tool2, tool3, tool4, tool5, ...],
    middleware=[
        LLMToolSelectorMiddleware(
            model="gpt-4.1-mini",
            max_tools=3,
            always_include=["search"],
        ),
    ],
)
```

**Parameters**:
- `model`: Selection model (defaults to agent's main model)
- `system_prompt`: Custom selection instructions
- `max_tools`: Maximum tools to select
- `always_include`: Tools always included regardless of selection

---

### Tool Retry

**Purpose**: Automatically retry failed tool calls with exponential backoff.

**Use Cases**:
- Handling transient failures in external API calls
- Improving reliability of network-dependent tools
- Building resilient agents for temporary errors

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import ToolRetryMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, database_tool],
    middleware=[
        ToolRetryMiddleware(
            max_retries=3,
            backoff_factor=2.0,
            initial_delay=1.0,
        ),
    ],
)
```

**Key Parameters**:
- `max_retries`: Retry attempts after initial call (default: 2)
- `tools`: Specific tools to apply retry logic (default: all)
- `retry_on`: Exception types to retry on
- `on_failure`: "return_message" (allow LLM to handle) or "raise" (stop execution)
- `backoff_factor`: Exponential backoff multiplier (default: 2.0)
- `initial_delay`: Initial delay in seconds (default: 1.0)
- `max_delay`: Maximum delay cap (default: 60.0)
- `jitter`: Add random variation to avoid thundering herd (default: true)

---

### Model Retry

**Purpose**: Automatically retry failed model calls with exponential backoff.

**Use Cases**:
- Handling transient failures in model API calls
- Improving reliability of network-dependent requests
- Building resilient agents for temporary model errors

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import ModelRetryMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, database_tool],
    middleware=[
        ModelRetryMiddleware(
            max_retries=3,
            backoff_factor=2.0,
            initial_delay=1.0,
        ),
    ],
)
```

**Key Parameters**:
- `max_retries`: Retry attempts after initial call (default: 2)
- `retry_on`: Exception types to retry on
- `on_failure`: "continue" (return error message), "error" (re-raise), or custom callable
- `backoff_factor`: Exponential backoff multiplier (default: 2.0)
- `initial_delay`: Initial delay in seconds (default: 1.0)
- `max_delay`: Maximum delay cap (default: 60.0)
- `jitter`: Add random variation (default: true)

---

### LLM Tool Emulator

**Purpose**: Emulate tool execution using an LLM for testing purposes.

**Use Cases**:
- Testing agent behavior without executing real tools
- Developing agents when external tools unavailable or expensive
- Prototyping workflows before implementing actual tools

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import LLMToolEmulator

agent = create_agent(
    model="gpt-4.1",
    tools=[get_weather, search_database, send_email],
    middleware=[
        LLMToolEmulator(),  # Emulate all tools
    ],
)
```

**Parameters**:
- `tools`: Tools to emulate (None = all tools; empty list = none; specific list = selected tools only)
- `model`: Model for generating responses (defaults to agent's model)

---

### Context Editing

**Purpose**: Manage conversation context by clearing older tool outputs when token limits reached.

**Use Cases**:
- Long conversations with many tool calls exceeding token limits
- Reducing token costs by removing irrelevant older outputs
- Maintaining only recent N tool results in context

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import ContextEditingMiddleware, ClearToolUsesEdit

agent = create_agent(
    model="gpt-4.1",
    tools=[],
    middleware=[
        ContextEditingMiddleware(
            edits=[
                ClearToolUsesEdit(
                    trigger=100000,
                    keep=3,
                ),
            ],
        ),
    ],
)
```

**ContextEditingMiddleware Parameters**:
- `edits`: List of context editing strategies
- `token_count_method`: "approximate" or "model" (default: approximate)

**ClearToolUsesEdit Parameters**:
- `trigger`: Token count threshold (default: 100000)
- `clear_at_least`: Minimum tokens to reclaim
- `keep`: Number of most recent tool results to preserve (default: 3)
- `clear_tool_inputs`: Whether to clear tool call parameters (default: false)
- `exclude_tools`: Tool names to never clear
- `placeholder`: Text replacing cleared outputs (default: "[cleared]")

---

### Shell Tool

**Purpose**: Expose a persistent shell session for agent command execution.

**Use Cases**:
- Agents executing system commands
- Development and deployment automation
- Testing, validation, and file system operations

**Security Note**: Use appropriate execution policies (`HostExecutionPolicy`, `DockerExecutionPolicy`, or `CodexSandboxExecutionPolicy`).

**Limitation**: Persistent shell sessions don't currently work with interrupts (human-in-the-loop).

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import (
    ShellToolMiddleware,
    HostExecutionPolicy,
)

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool],
    middleware=[
        ShellToolMiddleware(
            workspace_root="/workspace",
            execution_policy=HostExecutionPolicy(),
        ),
    ],
)
```

**Parameters**:
- `workspace_root`: Base directory for shell session (temporary if omitted)
- `startup_commands`: Commands executed after session starts
- `shutdown_commands`: Commands executed before shutdown
- `execution_policy`: Policy controlling timeouts and resources
- `redaction_rules`: Rules for sanitizing command output
- `tool_description`: Custom shell tool description
- `shell_command`: Shell executable or arguments (default: /bin/bash)
- `env`: Environment variables for the session

**Execution Policies**:
- `HostExecutionPolicy`: Full host access (default)
- `DockerExecutionPolicy`: Separate Docker container per run
- `CodexSandboxExecutionPolicy`: Codex CLI sandbox with additional restrictions

---

### File Search

**Purpose**: Provide Glob and Grep search tools over filesystem files.

**Use Cases**:
- Code exploration and analysis
- Finding files by name patterns
- Searching code content with regex
- Large codebases requiring file discovery

**Configuration**:
```python
from langchain.agents import create_agent
from langchain.agents.middleware import FilesystemFileSearchMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[],
    middleware=[
        FilesystemFileSearchMiddleware(
            root_path="/workspace",
            use_ripgrep=True,
        ),
    ],
)
```

**Parameters**:
- `root_path`: Root directory to search (required)
- `use_ripgrep`: Use ripgrep for search; falls back to Python regex if unavailable (default: true)
- `max_file_size_mb`: Maximum file size to search (default: 10)

**Tools Provided**:
- **Glob tool**: Fast file pattern matching (e.g., `**/*.py`, `src/**/*.ts`)
- **Grep tool**: Content search with regex and file pattern filtering

---

### Filesystem Middleware (Deep Agents)

**Purpose**: Provide agents with filesystem tools for short-term and long-term memory storage.

**Tools Provided**:
- `ls`: List filesystem files
- `read_file`: Read entire files or specific lines
- `write_file`: Write new files
- `edit_file`: Edit existing files

**Basic Configuration**:
```python
from langchain.agents import create_agent
from deepagents.middleware.filesystem import FilesystemMiddleware

agent = create_agent(
    model="claude-sonnet-4-6",
    middleware=[
        FilesystemMiddleware(
            backend=None,  # Optional: custom backend
            system_prompt="Write to filesystem when...",
            custom_tool_descriptions={
                "ls": "Use ls tool when...",
                "read_file": "Use read_file tool to..."
            }
        ),
    ],
)
```

**Persistent Storage** (using CompositeBackend):
```python
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

agent = create_agent(
    model="claude-sonnet-4-6",
    store=store,
    middleware=[
        FilesystemMiddleware(
            backend=lambda rt: CompositeBackend(
                default=StateBackend(rt),
                routes={"/memories/": StoreBackend(rt)}
            ),
        ),
    ],
)
```

**Architecture**: Files with `/memories/` prefix save to persistent storage; others remain ephemeral.

---

### Subagent Middleware (Deep Agents)

**Purpose**: Allow main agent to spawn subagents for task isolation and context management.

**Use Cases**:
- Isolating context when delegating complex tasks
- Keeping supervisor agent's context window clean
- Assigning specialized tools to specific subagents

**Basic Configuration**:
```python
from langchain.tools import tool
from langchain.agents import create_agent
from deepagents.middleware.subagents import SubAgentMiddleware

@tool
def get_weather(city: str) -> str:
    """Get the weather in a city."""
    return f"The weather in {city} is sunny."

agent = create_agent(
    model="claude-sonnet-4-6",
    middleware=[
        SubAgentMiddleware(
            default_model="claude-sonnet-4-6",
            default_tools=[],
            subagents=[
                {
                    "name": "weather",
                    "description": "This subagent can get weather in cities.",
                    "system_prompt": "Use the get_weather tool to get weather.",
                    "tools": [get_weather],
                    "model": "gpt-4.1",
                    "middleware": [],
                }
            ],
        )
    ],
)
```

**Custom LangGraph Subagents**:
```python
from deepagents import CompiledSubAgent
from langgraph.graph import StateGraph

# Build custom LangGraph
weather_graph = create_weather_graph().compile()

# Wrap in CompiledSubAgent
weather_subagent = CompiledSubAgent(
    name="weather",
    description="This subagent can get weather in cities.",
    runnable=weather_graph
)

agent = create_agent(
    model="claude-sonnet-4-6",
    middleware=[
        SubAgentMiddleware(
            default_model="claude-sonnet-4-6",
            default_tools=[],
            subagents=[weather_subagent],
        )
    ],
)
```

**Built-in Subagent**: All agents automatically have a "general-purpose" subagent with same instructions and tools for context isolation.

---

## Provider-Specific Middleware

**Anthropic Middleware**: Prompt caching, bash tool, text editor, memory, and file search for Claude models.

**OpenAI Middleware**: Content moderation middleware for OpenAI models.

---

## Key Takeaways

- **Provider-agnostic options** cover common scenarios: rate limiting, retries, PII detection, task planning, and context management
- **Execution policies** (host, Docker, sandbox) provide security flexibility for shell operations
- **Deep Agents middleware** enables filesystem operations and subagent delegation for sophisticated context engineering
- **Composition** allows stacking multiple middleware for complex agent behaviors
- **Flexibility** in custom detectors, prompts, and error handling for specific use cases
