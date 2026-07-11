// Auto-generated from 07_data_analysis.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Data Analysis Agent", subtitle: "Deep Agents + Sandbox")

Build an autonomous agent that takes CSV data as input, performs exploratory data analysis (EDA), generates visualization results, and shares them through Slack.

Utilizes the Deep Agents SDK's `create_deep_agent`, backend system, and built-in tool and checkpointer.

== Learning Objectives

After completing this notebook, you will be able to:

+ _Backend Selection_ — Understand the difference between `LocalShellBackend` (development) and `DaytonaSandbox`/`Modal`/`Runloop` (operations) and be able to choose
+ _Custom tool Definition_ — External services tool, such as Slack integration, can be created with the `@tool` decorator.
+ _Agent Creation_ — With `create_deep_agent()`, you can configure an agent that combines model, tool, backend, and checkpointer.
+ _Streaming Observation_ — You can monitor the agent’s analysis process in real-time.
+ _Use built-in tool_ — Understand the role of `write_todos`, `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep` tool
+ _checkpointer_ — You can maintain the conversation with `InMemorySaver` and then perform analysis.

== 7.1 Environment Setup

Install Deep Agents SDK, Tavily (web search), and Slack SDK. Use `pip` or `uv` depending on the execution environment.

#code-block(`````python
from dotenv import load_dotenv

load_dotenv()
`````)

#code-block(`````python
# Observability settings (optional) - LangSmith or Langfuse
# Set the key in .env, or uncomment it below and enter it yourself.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: Automatically enabled when LANGSMITH_TRACING=true (no code modification required)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: Pass config={"callbacks": [langfuse_handler]} when calling invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")
# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 7.2 Data Analysis Agent Overview

Deep Agents' data analysis agents _autonomously_ run the following pipelines:

#code-block(`````python
CSV input -> planning (`write_todos`) -> file reading (`read_file`) -> code generation and execution -> iterative analysis -> result delivery (Slack)
`````)

=== Detailed Execution Flow

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Step],
  text(weight: "bold")[Description],
  text(weight: "bold")[Tools used],
  [_Planning_],
  [Builds a structured task plan with `write_todos` and updates TODOs as the analysis progresses],
  [`write_todos`],
  [_File Reading_],
  [Inspects CSV structure, column names, data types, and row counts. Image files can also be read multimodally.],
  [`read_file`],
  [_Code Execution_],
  [Writes and runs Python code (pandas, matplotlib, etc.) in an isolated backend],
  [Backend `execute`],
  [_Iterative Analysis_],
  [Performs follow-up analysis based on initial results and uses web search for domain context],
  [Tavily, `edit_file`],
  [_Result Delivery_],
  [Formats the analysis result and sends it to Slack],
  [`slack_send_message`],
)

=== Key Traits of an Autonomous Agent

A Deep Agents data-analysis agent goes beyond simple tool use and can _plan autonomously_:

+ _Planning_: uses `write_todos` to break the analysis into steps and track progress
+ _Adaptive execution_: if an error occurs during analysis, it can revise the code (`edit_file`) and run it again.
+ _subagent Delegation_: Complex tasks are processed in parallel by creating specialized subagent
+ _Context Management_: Store intermediate results in file system tool and refer back to them when needed

== 7.3 Backend selection

Deep Agents provide a filesystem and code execution environment through a _pluggable backend architecture_. All backends implement the same `BackendProtocol`, so you can replace just the backend without changing any code.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[backend],
  text(weight: "bold")[Use],
  text(weight: "bold")[Security level],
  text(weight: "bold")[Setting Difficulty],
  [`LocalShellBackend`],
  [Local development/testing],
  [Low (host system full access)],
  [No setup required],
  [`Daytona`],
  [Cloud sandbox environment],
  [High (isolated container)],
  [API key required],
  [`Modal`],
  [Serverless GPU/CPU computation],
  [High],
  [Modal account required],
  [`Runloop`],
  [Running a managed cloud],
  [High],
  [API key required],
)

=== Details by backend type

- _`StateBackend`_ (default): Store files in LangGraph agent state. It is suitable for use as a scratch pad, and large printouts are automatically removed.
- _`FilesystemBackend`_: Use `root_dir` and `virtual_mode=True` to constrain filesystem-tool paths.
- _`LocalShellBackend`_: The `execute` tool runs with host privileges. `virtual_mode=True` normalizes file paths but provides no shell isolation.
- _`CompositeBackend`_: Route different backends per route. Example: `StateBackend` for temporary files, `StoreBackend` for `/memories/`.

=== Sandbox Security Principles

Sandboxes provide an isolated environment where agents can run code safely. Core security principles:

- _Never put secrets in the sandbox_ -- Context injection attacks can allow agents to read environment variables or credentials from mounted files and thus leak them.
- Keep your credentials outside the sandbox in tool
- Use Human-in-the-Loop approval for sensitive tasks
- Block unnecessary network access

#tip-box[_Caution_: The local configuration below reduces exposure with a temporary root, minimal environment, and HITL. It is not a security sandbox; use an isolated sandbox backend in production.]

#code-block(`````python
from deepagents.backends import LocalShellBackend
from pathlib import Path
import sys

work_dir = Path(".agent-work").resolve()
work_dir.mkdir(exist_ok=True)
dev_backend = LocalShellBackend(
    root_dir=work_dir, virtual_mode=True,
    env={"PATH": f"{Path(sys.executable).parent}:/usr/bin:/bin"},
    inherit_env=False,
)

# For Operations — Cloud Sandbox (Choose 1)
# prod_backend = ... # Use cloud sandbox backend in production
`````)

== 7.4 Upload sample data

Create a CSV file in the backend's working directory for the agent to analyze. `create_deep_agent`'s backend has `write_file` tool built in, so the agent can write files directly, but here the data is prepared in advance.

#code-block(`````python
import os

workspace = "/tmp/analysis"
os.makedirs(workspace, exist_ok=True)

csv_content = (
    "region,quarter,revenue,units_sold\n"
    "Seoul,Q1,120000,340\nSeoul,Q2,135000,380\n"
    "Seoul,Q3,128000,355\nSeoul,Q4,150000,420\n"
    "Busan,Q1,85000,240\nBusan,Q2,92000,260\n"
    "Busan,Q3,88000,250\nBusan,Q4,105000,300"
)
`````)

#code-block(`````python
with open(f"{workspace}/sales_2025.csv", "w") as f:
    f.write(csv_content)
print(f"CSV saved: {workspace}/sales_2025.csv")
`````)

== 7.5 Custom tool -- Slack integration

Use the `@tool` decorator to define a custom tool that the agent can call. _docstring_ in tool tells the agent how to use it.

Below is tool, which transmits analysis results to a Slack channel.

#code-block(`````python
from langchain_core.tools import tool
try:
    from slack_sdk import WebClient
except ImportError:
    WebClient = None
    print("slack_sdk not installed -- Slack tool works as a stub")

slack_client = WebClient(token=os.environ.get("SLACK_BOT_TOKEN", "xoxb-placeholder")) if WebClient else None

@tool
def slack_send_message(message: str) -> str:
    """Send analysis results to Slack channel."""
    resp = slack_client.chat_postMessage(
        channel=os.environ.get("SLACK_CHANNEL_ID", "general"), text=message)
    return f"Sent successfully. Timestamp: {resp['ts']}"
`````)

=== Web Search tool (Tavily)

Prepares Tavily tool so that agents can perform web searches when domain context is needed during analysis.

#code-block(`````python
from tavily import TavilyClient

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

def tavily_search(query: str) -> str:
    """Search the web for information related to your analysis."""
    results = tavily_client.search(query, max_results=5)
    return "\n".join(
        [r["content"] for r in results["results"]]
    )
`````)

== 7.6 Creating an agent

`create_deep_agent()` creates an agent by combining the model, tool, backend, checkpointer, and system prompts.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[parameters],
  text(weight: "bold")[Type],
  text(weight: "bold")[Description],
  [`model`],
  [`str`],
  [model identifier (default: `claude-sonnet-4-6`)],
  [`tools`],
  [`list`],
  [List of tool functions to be used by the agent],
  [`backend`],
  [`Backend`],
  [Code execution and filesystem backend],
  [`checkpointer`],
  [`Checkpointer`],
  [State Perpetuation Mechanism],
  [`system_prompt`],
  [`str`],
  [Agent Behavior Guidelines],
)

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import LocalShellBackend
from langgraph.checkpoint.memory import InMemorySaver

backend = dev_backend  # development host shell, not a sandbox
checkpointer = InMemorySaver()
`````)

#code-block(`````python
agent = create_deep_agent(
    model="gpt-5.4",
    tools=[tavily_search, slack_send_message],
    backend=backend,
    checkpointer=checkpointer,
    interrupt_on={"execute": True},
    system_prompt="You are a data analyst.",
)
`````)

== 7.7 Execution — Analysis Request

When an analysis request is sent to `agent.invoke()`, the agent autonomously performs the following pipeline: planning → reading files → executing code → delivering results.

#code-block(`````python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Analyze sales data in /tmp/analysis/sales_2025.csv. Find top-performing regions, identify quarterly trends, create visualizations, and send Summary to Slack."}]},
    config={**lf_config, "configurable": {"thread_id": "data-analysis-1"}},
)
print(result)

`````)

== 7.8 Observe the analysis process through streaming

`agent.stream()` allows you to observe the agent's execution _in real-time_. Deep Agents provides powerful monitoring that can trace the execution of subagent based on LangGraph's streaming infrastructure.

=== Stream mode

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[mode],
  text(weight: "bold")[Description],
  text(weight: "bold")[Use cases],
  [_Updates_],
  [Receive events upon completion of each step (node)],
  [Progress Dashboard, Log],
  [_Messages_],
  [Individual token streaming, including source agent metadata],
  [Real-time chat UI],
  [_Custom_],
  [Issue custom progress event with `get_stream_writer()`],
  [Analysis progress display, custom notifications],
)

=== Namespace system

Streaming events contain a namespace that identifies their source:

- `()` (empty tuple) = main agent
- `("tools:abc123",)` = subagent created with tool calling
- `("tools:abc123", "model_request:def456")` = model request node inside subagent

By setting `subgraphs=True`, you can trace the execution of subagent as well, and you can also use multiple stream modes simultaneously:

#code-block(`````python
for namespace, chunk in agent.stream(
    {"messages": [...]},
    stream_mode=["updates", "messages", "custom"],
    subgraphs=True,
):
    mode, data = chunk
    # Handle each mode differently
`````)

=== Tracking the Subagent Lifecycle

A subagent goes through three stages:
+ _Pending_ — detected when the main agent includes a delegated task in its `model_request`
+ _Running_ — starts when events appear under the `tools:UUID` namespace
+ _Complete_ — finishes when the main agent's `tools` node returns its result.

#code-block(`````python
for namespace, chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Please Summary sales by region."}]},
    stream_mode="updates",
    subgraphs=True,
    config={**lf_config, "configurable": {"thread_id": "data-analysis-1"}},
):
    source = f"[subagent: {namespace}]" if namespace else "[main]"
    print(source, chunk)

`````)

== 7.9 Utilizing built-in tool

Deep Agents automatically provides the following built-ins to agents through the backend: The agent autonomously selects and uses these tool during the analysis process.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[tool],
  text(weight: "bold")[Description],
  text(weight: "bold")[Example usage],
  [`write_todos`],
  [Create and track structured work plans],
  [Creation of TODO list for each stage of analysis],
  [`ls`],
  [List directory contents (`BackendProtocol.ls`)],
  [Check CSV file existence],
  [`read_file`],
  [Read file (image multimodal support)],
  [Understand CSV structure, check chart image],
  [`write_file`],
  [Creating a new file (create-only)],
  [Analysis script, save result file],
  [`edit_file`],
  [Modifying existing files (find-and-replace)],
  [Code fix, update config file],
  [`glob`],
  [glob pattern based file navigation],
  [`*.csv` Searching data files by pattern],
  [`grep`],
  [Pattern matching search],
  [Search for specific column name or value],
)

=== Multimodal support in `read_file`

`read_file` supports image files as multimodal content in all backends. After the agent creates a chart with matplotlib, you can _visually interpret_ the contents of the chart by reading the image with `read_file`. Through this, it autonomously determines “whether the chart was created correctly” and “what additional visualization is needed.”

=== Custom backend implementation

You can implement `BackendProtocol` yourself depending on your needs. Required methods:
- `ls()` -- Return directory contents in `LsResult`
- `read()` -- Read file with line numbers
- `grep()` -- Return structured matches in `GrepResult`
- `glob()` -- Return glob matches in `GlobResult`
- `write()` -- Create file (create-only)
- `edit()` -- find-and-replace that guarantees uniqueness

#code-block(`````python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "List all CSV files in /tmp/analysis/ using glob, and read the first file to describe its structure."}]},
    config={**lf_config, "configurable": {"thread_id": "data-analysis-1"}},
)
print(result)

`````)

== 7.10 Maintain conversation with checkpointer

checkpointer saves agent state to enable _abort and resume_. A conversation session is identified through `thread_id`, and subsequent requests with the same `thread_id` will maintain the previous conversation context.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[checkpointer],
  text(weight: "bold")[Use],
  text(weight: "bold")[permanence],
  [`InMemorySaver`],
  [Development/Test],
  [Destroyed when process ends],
  [`SQLiteSaver`],
  [local persistence],
  [Save to Disk (`./agent_checkpoints.db`)],
  [`PostgresSaver`],
  [Production],
  [Store in database, support multiple instances],
)

=== Role of checkpointer

checkpointer goes beyond simply saving conversation history and allows you to:

- _Interruption Recovery_: Resume from the last completed step in case of network error or timeout
- _`interrupt()` Support_: Save the graph state in Human-in-the-Loop and resume at the correct location after the human responds.
- _Multi-turn analysis_: Process multiple analysis requests consecutively in the same session while referencing previous results

=== Sandbox Lifetime Management

An explicit shutdown is required when using a sandbox. Failure to terminate will result in unnecessary costs. In your chat application, use a unique sandbox for each conversation thread and configure automatic cleanup with Time-to-Live (TTL) settings.

#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()
config = {"configurable": {"thread_id": "analysis-session-1"}}

agent_with_memory = create_deep_agent(
    model="gpt-5.4",
    tools=[tavily_search, slack_send_message],
    backend=dev_backend,
    checkpointer=checkpointer,
    interrupt_on={"execute": True},
)
`````)

#code-block(`````python
r1 = agent_with_memory.invoke(
    {"messages": [{"role": "user", "content": "Please read /tmp/analysis/sales_2025.csv and Summary."}]},
    config={**config, **lf_config},
)
print("Turn:", r1)
`````)

#code-block(`````python
r2 = agent_with_memory.invoke(
    {"messages": [{"role": "user", "content": "Please compare the Q4 performance of Seoul and Busan."}]},
    config={**config, **lf_config},
)
print("Turn:", r2)
`````)

== Summary

To summarize what we covered in this notebook:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Takeaways],
  [_Backend_],
  [`LocalShell` (development) uses host shell access, production uses `Daytona`/`Modal`/`Runloop` sandbox],
  [_Custom tool_],
  [`\@tool` Defined by decorator + docstring, agent calls autonomously],
  [_Create Agent_],
  [`create_deep_agent(model, tools, backend, checkpointer, system_prompt)`],
  [_Streaming_],
  [Real-time observation with `agent.stream(stream_mode="updates", subgraphs=True)`],
  [_Built-in tool_],
  [`write_todos`, `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`],
  [_checkpointer_],
  [`InMemorySaver` (Development) → `SQLiteSaver` → `PostgresSaver` (Production)],
)

=== Next Steps
→ _#link("./08_voice_agent.ipynb")[08_voice_agent.ipynb]_: Creates a voice agent.
