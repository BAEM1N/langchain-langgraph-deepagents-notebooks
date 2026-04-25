// Auto-generated from 03_data_analysis_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Data Analysis Agent", subtitle: "Code Execution and Multi-Turn Analysis")

== Learning Objectives

- Set up a code execution environment with `LocalShellBackend`
- Combine custom tools with built-in tools such as `write_todos` and `execute`
- Perform iterative analysis with streaming and multi-turn conversations
- Apply v1 middleware (`SummarizationMiddleware`, `ModelCallLimitMiddleware`)


== Overview

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Details],
  [_Framework_],
  [Deep Agents],
  [_Core components_],
  [`LocalShellBackend`, `InMemorySaver`],
  [_Built-in tools_],
  [`execute` (code execution), `write_todos` (planning)],
  [_Pattern_],
  [Streaming (`stream(subgraphs=True)`) + multi-turn conversation],
  [_Skill_],
  [`skills/data-analysis/SKILL.md` — analysis checklist + code execution rules],
)


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "Set OPENAI_API_KEY in .env"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

`````)

== Step 1: Compare Backends

Deep Agents supports multiple backends. For data analysis, code execution matters, so we use `LocalShellBackend`.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Backend],
  text(weight: "bold")[File Access],
  text(weight: "bold")[Code Execution],
  text(weight: "bold")[Best Use],
  [`StateBackend`],
  [Stored in state],
  [❌],
  [Scratchpad],
  [`FilesystemBackend`],
  [Local disk],
  [❌],
  [Read/write files],
  [`LocalShellBackend`],
  [Local disk],
  [✅ `execute`],
  [Data analysis, code execution],
  [Sandboxes (Modal, etc.)],
  [Isolated environment],
  [✅],
  [Production],
)

#tip-box[⚠️ `LocalShellBackend` runs commands on the host system. Always use `virtual_mode=True`.]


#code-block(`````python
from deepagents.backends import LocalShellBackend

backend = LocalShellBackend(root_dir=".", virtual_mode=True)

`````)

== Step 2: Create a CSV File for Analysis

If the agent is going to run pandas code with `execute`, there needs to be a CSV file on disk. The agent could also write files itself with the built-in `write_file` tool, but here we prepare the file ahead of time.


#code-block(`````python
import tempfile, os

# Create a CSV file in a temporary directory
tmp_dir = tempfile.mkdtemp()
csv_path = os.path.join(tmp_dir, "sales.csv")

CSV_DATA = """date,product,region,sales,quantity
2024-01-15,Widget A,Seoul,150000,30
2024-01-15,Widget B,Busan,89000,18
2024-02-10,Widget A,Seoul,175000,35
2024-02-10,Widget C,Daegu,62000,12
2024-03-05,Widget B,Seoul,134000,27
2024-03-05,Widget A,Busan,98000,20
2024-03-20,Widget C,Seoul,71000,14
2024-04-01,Widget A,Daegu,112000,22"""

with open(csv_path, "w", encoding="utf-8") as f:
    f.write(CSV_DATA.strip())
print(f"Saved CSV: {csv_path}")

`````)

== Step 3: Define the Analysis Tools

We define two custom tools:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tool],
  text(weight: "bold")[Role],
  [`get_csv_path`],
  [Returns the CSV file path],
  [`run_pandas`],
  [Executes pandas code directly and returns the result],
)

#note-box[`run_pandas` executes pandas code written by the agent with `exec()`. In many notebook environments, this is more stable than relying only on the built-in `execute` tool.]


#code-block(`````python
from langchain.tools import tool
import io, contextlib

@tool
def get_csv_path() -> str:
    """Return the path of the CSV file to analyze."""
    return csv_path

@tool
def run_pandas(code: str) -> str:
    """Execute pandas Python code. Use print() to display results."""
    import pandas as pd, numpy as np
    buf = io.StringIO()
    ns = {"pd": pd, "np": np, "csv_path": csv_path}
    try:
        with contextlib.redirect_stdout(buf):
            exec(code, ns)
        return buf.getvalue() or "Execution finished (no printed output)"
    except Exception as e:
        return f"Error: {e}"

`````)

== Step 4: Create the Agent (with v1 Middleware)

Combine `LocalShellBackend` with the custom tools (`get_csv_path`, `run_pandas`).

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Middleware],
  text(weight: "bold")[Role],
  [`SummarizationMiddleware`],
  [Automatically summarizes older messages when the conversation becomes long],
  [`ModelCallLimitMiddleware`],
  [Prevents infinite loops by limiting the run to 20 model calls],
)


#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import LocalShellBackend
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import (
    SummarizationMiddleware,
    ModelCallLimitMiddleware,
)
from prompts import DATA_ANALYSIS_PROMPT

agent = create_deep_agent(
    model=model,
    tools=[get_csv_path, run_pandas],
    system_prompt=DATA_ANALYSIS_PROMPT,
    backend=LocalShellBackend(root_dir=tmp_dir, virtual_mode=True),
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    middleware=[
        SummarizationMiddleware(model=model, trigger=("messages", 10)),
        ModelCallLimitMiddleware(run_limit=20),
    ],
)

`````)

== Step 5: Analyze with pandas Code Execution

When you ask the agent to analyze the data, it can first use `get_csv_path` to confirm the file path and then use `run_pandas` to write and execute pandas code.

#code-block(`````python
Agent execution flow:
1. get_csv_path() → confirm the CSV file path
2. run_pandas("import pandas as pd; ...") → execute pandas code
3. interpret the result and produce an answer
`````)


== Step 6: Ask a Follow-Up Question in the Same Thread

If you reuse the same `thread_id`, the agent keeps the conversation context and can continue the analysis from the earlier steps.


== Built-In Tools Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Built-in Tool],
  text(weight: "bold")[Backend],
  text(weight: "bold")[Description],
  [`read_file`],
  [All backends],
  [Read a file (including images)],
  [`write_file`],
  [All backends],
  [Write a file],
  [`edit_file`],
  [All backends],
  [Edit a file (find and replace)],
  [`ls`],
  [All backends],
  [List directory contents],
  [`glob`],
  [All backends],
  [Search for files by pattern],
  [`grep`],
  [All backends],
  [Search file contents],
  [`execute`],
  [LocalShell, Sandbox],
  [Run shell commands],
  [`write_todos`],
  [All backends],
  [Create or update a task plan],
)


== Data Analysis Execution Flow

#code-block(`````python
1. [Planning]    write_todos — write the analysis plan
2. [Reading]     read_file — inspect the CSV structure
3. [Execution]   execute — run pandas code
4. [Iteration]   continue analysis through follow-up questions
5. [Delivery]    summarize findings and report results
`````)


== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Key Point],
  [_Backend_],
  [`LocalShellBackend(virtual_mode=True)` — supports code execution],
  [_Built-in tools_],
  [`execute` (code execution) + `write_todos` (planning)],
  [_Streaming_],
  [`stream(subgraphs=True)` — observe the process in real time],
  [_Multi-turn_],
  [`InMemorySaver` + same `thread_id` — preserve conversation context],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- `docs/deepagents/tutorials/data-analysis.md`
- `docs/deepagents/06-backends.md`

_Next Step:_ → #link("./04_ml_agent.ipynb")[04_ml_agent.ipynb]: Build a machine learning agent.

