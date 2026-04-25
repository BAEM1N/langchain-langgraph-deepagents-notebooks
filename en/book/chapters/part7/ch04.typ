// Auto-generated from 04_ml_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Machine Learning Agent", subtitle: "A Flexible CSV-Based ML Workflow")

== Learning Objectives

- Set a data directory with `FilesystemBackend` and let the agent explore files freely
- Extend the `run_pandas` pattern from NB03 to create a `run_ml_code` tool with scikit-learn
- Let the agent explore data with built-in tools (`ls`, `read_file`, `glob`) and analyze it with `run_ml_code`
- Run EDA → preprocessing → model selection → training → evaluation through multi-turn conversation


== Overview

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[NB03 (Data Analysis)],
  text(weight: "bold")[NB04 (Machine Learning)],
  [_Backend_],
  [`LocalShellBackend`],
  [`FilesystemBackend`],
  [_Data_],
  [Sales CSV (8 rows)],
  [User-provided CSV (demo: breast cancer, 569 rows)],
  [_Custom tools_],
  [`get_csv_path` + `run_pandas`],
  [`run_ml_code` (adds sklearn)],
  [_Built-in tools_],
  [—],
  [`ls`, `read_file`, `glob` (file exploration)],
  [_Goal_],
  [Aggregation, statistics, trend analysis],
  [EDA → preprocessing → model training → comparison],
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

== NB03 vs. NB04: Extending the Backend and Tooling

In NB03, you used `LocalShellBackend` + `run_pandas` to execute pandas code.
In NB04, you extend that setup in two ways:

+ _Backend_: `FilesystemBackend(root_dir=DATA_DIR)` — the agent can freely explore the data directory with built-in tools such as `ls`, `read_file`, and `glob`
+ _Tool_: `run_ml_code` — adds `sklearn` to the execution namespace so the agent can run ML pipelines

#code-block(`````python
# NB03: LocalShellBackend + run_pandas
backend = LocalShellBackend(root_dir=tmp_dir, virtual_mode=True)
ns = {"pd": pd, "np": np, "csv_path": csv_path}

# NB04: FilesystemBackend + run_ml_code
backend = FilesystemBackend(root_dir=DATA_DIR, virtual_mode=True)
ns = {"pd": pd, "np": np, "sklearn": sklearn, "DATA_DIR": DATA_DIR}
`````)

#tip-box[Because `FilesystemBackend` does not expose `execute`, it is safer than `LocalShellBackend`.]


== Step 1: Set the Data Directory

If you change `DATA_DIR`, you can point the agent to _your own CSV data_.
The agent will inspect the directory with built-in tools such as `ls`, `glob`, and `read_file` to understand which files exist.

#code-block(`````python
# Example: point to your own data directory
DATA_DIR = "/path/to/your/data"
`````)


#code-block(`````python
import tempfile
import pandas as pd
from sklearn.datasets import load_breast_cancer

# ── Data directory setup ──────────────────────────────
# Change this to a directory that contains your own CSV files.
# For this demo, we save the breast_cancer dataset as a CSV.
DATA_DIR = tempfile.mkdtemp()

# Demo data creation (remove this block if you already have your own CSV)
data = load_breast_cancer()
df = pd.DataFrame(data.data, columns=data.feature_names)
df["target"] = data.target
df.to_csv(os.path.join(DATA_DIR, "breast_cancer.csv"), index=False)

print(f"DATA_DIR: {DATA_DIR}")
print(f"Files: {os.listdir(DATA_DIR)}")

`````)

== Step 2: Create the `FilesystemBackend`

`FilesystemBackend` provides built-in file tools below the `root_dir`:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Built-in Tool],
  text(weight: "bold")[Role],
  [`ls`],
  [List directory contents],
  [`read_file`],
  [Read file contents],
  [`glob`],
  [Find files by pattern],
  [`write_file`],
  [Write files (for saving results)],
)

#tip-box[`virtual_mode=True` prevents path escape patterns such as `..` or `~`.]


#code-block(`````python
from deepagents.backends import FilesystemBackend

backend = FilesystemBackend(root_dir=DATA_DIR, virtual_mode=True)

`````)

== Step 3: Define `run_ml_code`

Extend the `run_pandas` pattern from NB03 by adding `sklearn` to the execution namespace.
Pass `DATA_DIR` into the namespace so the agent can load any CSV file inside the directory.

#tip-box[Use built-in `ls` / `read_file` for file exploration and `run_ml_code` for code execution — keep the responsibilities separate.]


#code-block(`````python
from langchain.tools import tool
import io, contextlib

@tool
def run_ml_code(code: str) -> str:
    """Execute sklearn/pandas Python code. Use print() to display results.
    Available modules: pd, np, sklearn, os. Access the data directory via DATA_DIR."""
    import pandas as pd, numpy as np, sklearn
    buf = io.StringIO()
    ns = {"pd": pd, "np": np, "sklearn": sklearn, "os": os, "DATA_DIR": DATA_DIR}
    try:
        with contextlib.redirect_stdout(buf):
            exec(code, ns)
        return buf.getvalue() or "Execution finished (no printed output)"
    except Exception as e:
        return f"Error: {e}"

`````)

== Step 4: Create the Agent

The agent workflow is:
+ Explore CSV files inside `DATA_DIR` with built-in `ls` / `glob`
+ Preview data with built-in `read_file`
+ Run EDA → preprocessing → model training/comparison with `run_ml_code`

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Middleware],
  text(weight: "bold")[Role],
  [`ToolRetryMiddleware`],
  [Automatically retries failed tool calls (up to 2 times)],
  [`ModelCallLimitMiddleware`],
  [Prevents infinite loops by limiting the run to 20 model calls],
)


#code-block(`````python
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import (
    ToolRetryMiddleware,
    ModelCallLimitMiddleware,
)
from prompts import ML_AGENT_PROMPT

ml_agent = create_deep_agent(
    model=model,
    tools=[run_ml_code],
    system_prompt=ML_AGENT_PROMPT,
    backend=backend,
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    middleware=[
        ToolRetryMiddleware(max_retries=2),
        ModelCallLimitMiddleware(run_limit=20),
    ],
)

`````)

== Step 5: File Exploration + EDA

Ask the agent to explore the data directory and analyze the dataset.
The agent can inspect the file list with built-in `ls` and then perform EDA with `run_ml_code`.


== Step 6: Train and Compare Models

Ask the agent to train at least three suitable models and compare them with cross-validation.
The agent chooses the algorithms by itself.


== Step 7: Multi-Turn Follow-Up — Feature Importance

Reuse the same `thread_id` so the follow-up analysis keeps the earlier conversation context.


== Step 8: Streaming — Additional Analysis

Observe the execution process in real time with `stream(subgraphs=True)`.


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
  [`FilesystemBackend(root_dir=DATA_DIR)` — point the agent at your data directory],
  [_Built-in tools_],
  [`ls`, `read_file`, `glob` — explore files],
  [_Custom tool_],
  [`run_ml_code` (pandas + numpy + sklearn) — execute ML code],
  [_Workflow_],
  [File exploration → EDA → preprocessing → model selection → cross-validation comparison],
  [_Multi-turn_],
  [`InMemorySaver` + same `thread_id` — preserve analysis context],
)

=== Using Your Own Data

#code-block(`````python
# Just change DATA_DIR in Step 1
DATA_DIR = "/path/to/your/data"  # directory containing CSV files
`````)

The agent will explore files with `ls` and analyze them freely with `run_ml_code`.

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- `docs/deepagents/06-backends.md`
- `docs/deepagents/tutorials/data-analysis.md`
- #link("https://scikit-learn.org/stable/")[scikit-learn documentation]

_Next Step:_ → #link("./05_deep_research_agent.ipynb")[05_deep_research_agent.ipynb]: Build a deep research agent.

