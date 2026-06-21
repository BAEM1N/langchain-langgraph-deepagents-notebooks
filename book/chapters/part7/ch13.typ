// Auto-generated from 13_skills_sql_assistant.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(13, "Skills SQL Assistant", subtitle: "필요할 때만 SQL 지침 로드하기")

== 학습 목표
#learning-objectives([SKILL.md progressive disclosure를 SQL assistant에 적용합니다.], [SQL 안전 규칙을 query 실행 전 checklist로 검증합니다.], [실제 DB mutation 없이 read-only SQL 흐름을 연습합니다.])

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

SQL assistant는 query 작성 전에 안전 규칙을 먼저 로드해야 합니다.

#code-block(`````python
sql_policy = [
    "SELECT only by default",
    "LIMIT required for exploration",
    "No INSERT/UPDATE/DELETE without approval",
]

sql_policy
`````)

== 13.2 query safety check

데이터베이스 호출 전에 안전 검사를 먼저 실행합니다. 이 교육용 예시는 읽기 전용 `SELECT`만 허용하고, 주요 mutation 명령을 차단하며, 탐색 쿼리가 무제한으로 실행되지 않도록 `LIMIT`을 필수로 요구합니다. 실제 운영 환경에서는 DB 권한, query timeout, row cap, parser 기반 validation을 함께 사용해야 합니다.


#code-block(`````python
def is_safe_query(sql: str) -> bool:
    lowered = sql.lower().strip()
    forbidden = ["insert", "update", "delete", "drop", "alter"]
    has_limit = " limit " in f" {lowered} "
    return lowered.startswith("select") and has_limit and not any(word in lowered for word in forbidden)

print(is_safe_query("SELECT * FROM tracks LIMIT 5"))
print(is_safe_query("SELECT * FROM tracks"))

`````)

== 13.3 read-only 실행

안전 검사를 통과한 SELECT만 실행합니다.

#code-block(`````python
query = "SELECT genre, COUNT(*) AS n FROM tracks GROUP BY genre LIMIT 10"
assert is_safe_query(query)

rows = conn.execute(query).fetchall()
rows
`````)

== 13.4 answer synthesis

SQL 결과와 정책 확인을 함께 보고합니다.

#code-block(`````python
answer = {
    "query": query,
    "rows": rows,
    "policy_checked": True,
}

answer
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))

== 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_다룬 기술_],
  [SQL skill policy, static query check, read-only execution],
  [_핵심 개념_],
  [SQL assistant는 답변보다 먼저 안전한 query-writing workflow를 강제해야 합니다.],
)

#references-box[
- `docs/langchain/multi-agent/skills-sql-assistant.md`
- `docs/langchain/sql-agent.md`
- `07_examples/skills/sql-agent/SKILL.md`
]
#chapter-end()
