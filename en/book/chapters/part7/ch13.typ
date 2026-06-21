// Auto-generated from 13_skills_sql_assistant.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(13, "Skills SQL Assistant", subtitle: "Load SQL guidance on demand")

Skills let an agent load specialized instructions only when they are relevant. This example applies that idea to a SQL assistant with read-only safety rules.

_Learning goals_
- Express SQL safety guidance as an on-demand skill policy.
- Check queries before execution.
- Separate safe execution from answer synthesis.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
import sqlite3

conn = sqlite3.connect(":memory:")
conn.execute("CREATE TABLE tracks (id INTEGER, name TEXT, genre TEXT)")
conn.executemany("INSERT INTO tracks VALUES (?, ?, ?)", [(1,"A","Jazz"),(2,"B","Rock")])
conn.commit()
`````)

== 13.1 SQL skill policy

The skill policy describes what the assistant may and may not do. For SQL, that usually means read-only access, bounded queries, and explicit refusal for mutation commands.


#code-block(`````python
sql_policy = [
    "SELECT only by default",
    "LIMIT required for exploration",
    "No INSERT/UPDATE/DELETE without approval",
]

sql_policy
`````)

== 13.2 Query safety check

Run a safety check before any database call. This teaching example enforces read-only `SELECT` statements, blocks common mutation commands, and requires `LIMIT` so exploratory queries stay bounded. In production, pair this kind of check with database permissions, query timeouts, row caps, and parser-based validation.


#code-block(`````python
def is_safe_query(sql: str) -> bool:
    lowered = sql.lower().strip()
    forbidden = ["insert", "update", "delete", "drop", "alter"]
    has_limit = " limit " in f" {lowered} "
    return lowered.startswith("select") and has_limit and not any(word in lowered for word in forbidden)

print(is_safe_query("SELECT * FROM tracks LIMIT 5"))
print(is_safe_query("SELECT * FROM tracks"))

`````)

== 13.3 Read-only execution

Read-only execution keeps the example safe while still demonstrating the end-to-end flow. The database returns evidence that the final answer can cite.


#code-block(`````python
query = "SELECT genre, COUNT(*) AS n FROM tracks GROUP BY genre LIMIT 10"
assert is_safe_query(query)

rows = conn.execute(query).fetchall()
rows
`````)

== 13.4 Answer synthesis

Synthesis turns query results into a user-facing explanation. Keep the answer tied to the returned rows rather than inventing unsupported details.


#code-block(`````python
answer = {
    "query": query,
    "rows": rows,
    "policy_checked": True,
}

answer
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Content],
  [_Covered_],
  [SKILL.md progressive disclosure, SQL safety policy, static query checks, and read-only execution],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/deepagents/skills.md")[`skills.md`]
- #link("../../docs/langchain/sql-agent.md")[`sql-agent.md`]
- #link("../../docs/langgraph/sql-agent.md")[`sql-agent.md`]
