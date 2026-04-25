// Auto-generated from 02_sql_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "SQL Agent", subtitle: "Natural-Language Database Queries")

== Learning Objectives

- Generate SQL tools automatically with `SQLDatabaseToolkit`
- Apply AGENTS.md-based safety rules (READ-ONLY)
- Implement approval before query execution with a HITL interrupt
- Explicitly apply v1 middleware (`HumanInTheLoopMiddleware`, `ModelCallLimitMiddleware`)


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
  [LangChain + Deep Agents],
  [_Core components_],
  [`SQLDatabaseToolkit`, `SQLDatabase`, `InMemorySaver`],
  [_Agent pattern_],
  [AGENTS.md safety rules + skills-based workflow],
  [_HITL_],
  [`interrupt_on` + `Command(resume={...})`],
  [_Database_],
  [Chinook (SQLite)],
  [_Skill_],
  [`skills/sql-agent/SKILL.md` — SQL safety rules + query workflow],
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

== Step 1: Connect to the Database

Chinook is a sample database for a digital music store. It contains tables such as Artist, Album, Track, and Invoice.


#code-block(`````python
from langchain_community.utilities import SQLDatabase

db = SQLDatabase.from_uri("sqlite:///../05_advanced/Chinook.db")
print(f"Tables: {db.get_usable_table_names()}")

`````)

== Step 2: Create the `SQLDatabaseToolkit` Tools

`SQLDatabaseToolkit` automatically generates four tools from the database connection:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tool],
  text(weight: "bold")[Description],
  [`sql_db_list_tables`],
  [List available tables],
  [`sql_db_schema`],
  [Inspect table schema (DDL)],
  [`sql_db_query`],
  [Execute a SQL query],
  [`sql_db_query_checker`],
  [Validate query syntax before execution],
)


#code-block(`````python
from langchain_community.agent_toolkits import SQLDatabaseToolkit

toolkit = SQLDatabaseToolkit(db=db, llm=model)
sql_tools = toolkit.get_tools()
for t in sql_tools:
    print(f"  {t.name}: {t.description[:60]}")

`````)

== Step 3: Load the Prompt (LangSmith / Langfuse / Default)

The prompt loader follows this order:
+ _LangSmith Hub_ — if configured, pull the prompt from the Hub
+ _Langfuse_ — if configured, load it from Langfuse
+ _Default_ — otherwise, use the fallback prompt defined in code

The SQL agent prompt includes READ-ONLY safety rules and the expected query workflow.


#code-block(`````python
from prompts import SQL_AGENT_PROMPT

print(SQL_AGENT_PROMPT)

`````)

== Step 4: The Idea Behind Skills

Skills act as workflow guides for the agent. They document recurring task patterns so the agent works in a more consistent way.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Skill],
  text(weight: "bold")[Purpose],
  [`query-writing`],
  [Inspect tables → inspect schema → write SQL → execute],
  [`schema-exploration`],
  [List tables → inspect DDL → map relationships],
)


== Step 5: Create a Basic SQL Agent

Pass the SQL tools and AGENTS-style safety instructions into `create_deep_agent`. The `system_prompt` injects the SQL safety rules.


#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend

agent = create_deep_agent(
    model=model,
    tools=sql_tools,
    system_prompt=SQL_AGENT_PROMPT,
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
)

`````)

== Step 6: A HITL Agent (`interrupt_on`)

Use the `interrupt_on` parameter of `create_deep_agent` to define approval policies for specific tools. Execution stops before `sql_db_query` runs, and then resumes with `Command(resume=...)`.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Role],
  [`interrupt_on={"sql_db_query": True}`],
  [Pause before `sql_db_query` runs and wait for human approval],
  [`ModelCallLimitMiddleware`],
  [Prevent infinite loops by limiting the run to 15 model calls],
  [`InMemorySaver`],
  [Enables checkpointing so interrupts and resumes work],
)


#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import ModelCallLimitMiddleware

hitl_agent = create_deep_agent(
    model=model,
    tools=sql_tools,
    system_prompt=SQL_AGENT_PROMPT,
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    interrupt_on={"sql_db_query": True},
    middleware=[
        ModelCallLimitMiddleware(run_limit=15),
    ],
)

`````)

== Step 7: Resume After Approval

Use `Command(resume={"decisions": [{"type": "approve"}]})` to continue a paused run. In v1, decisions are passed in a `HITLResponse`-style structure.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Decision Type],
  text(weight: "bold")[Description],
  [`{"type": "approve"}`],
  [Approve the tool call and run it unchanged],
  [`{"type": "edit", "edited_action": {...}}`],
  [Modify the tool call before running it],
  [`{"type": "reject", "message": "..."}`],
  [Reject the tool call and return feedback to the agent],
)


== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Key Point],
  [_Tool generation_],
  [`SQLDatabaseToolkit(db, llm).get_tools()` → automatically creates 4 SQL tools],
  [_Safety rules_],
  [Applies a READ-ONLY policy through the SQL agent instructions],
  [_Skills_],
  [Workflow guides for query writing and schema exploration],
  [_HITL_],
  [`interrupt_on={"sql_db_query": True}` → `Command(resume={...})`],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- `docs/deepagents/examples/03-text-to-sql-agent.md`
- #link("https://python.langchain.com/docs/tutorials/sql_qa/")[LangChain SQL Agent Tutorial]
- `docs/deepagents/06-backends.md`

_Next Step:_ → #link("./03_data_analysis_agent.ipynb")[03_data_analysis_agent.ipynb]: Build a data analysis agent.

