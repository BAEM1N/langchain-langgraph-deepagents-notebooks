// Auto-generated from 02_sql_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "SQL 에이전트", subtitle: "자연어 데이터베이스 질의")

== 학습 목표
#learning-objectives([SQLDatabaseToolkit으로 SQL 도구를 자동 생성한다], [AGENTS.md 기반 안전 규칙(READ-ONLY)을 적용한다], [HITL(Human-in-the-Loop) interrupt로 쿼리 실행 전 승인을 구현한다], [v1 미들웨어(HumanInTheLoopMiddleware, ModelCallLimitMiddleware)를 명시적으로 적용한다])

== 개요

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_프레임워크_],
  [LangChain + Deep Agents],
  [_핵심 컴포넌트_],
  [SQLDatabaseToolkit, SQLDatabase, InMemorySaver],
  [_에이전트 패턴_],
  [AGENTS.md 안전 규칙 + Skills 기반 워크플로],
  [_HITL_],
  [`interrupt_on` + `Command(resume="approve")`],
  [_데이터베이스_],
  [Chinook (SQLite)],
  [_스킬_],
  [`skills/sql-agent/SKILL.md` — SQL 안전 규칙 + 쿼리 워크플로],
)

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

`````)

== 1단계: 데이터베이스 연결

Chinook은 디지털 음악 스토어의 샘플 데이터베이스입니다. Artist, Album, Track, Invoice 등의 테이블을 포함합니다.


#code-block(`````python
from langchain_community.utilities import SQLDatabase

db = SQLDatabase.from_uri("sqlite:///../05_advanced/Chinook.db")
print(f"테이블: {db.get_usable_table_names()}")

`````)
#output-block(`````
테이블: ['Album', 'Artist', 'Customer', 'Employee', 'Genre', 'Invoice', 'InvoiceLine', 'MediaType', 'Playlist', 'PlaylistTrack', 'Track']
`````)

== 2단계: SQLDatabaseToolkit 도구 생성

`SQLDatabaseToolkit`은 데이터베이스 연결에서 4개의 도구를 자동 생성합니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[설명],
  [`sql_db_list_tables`],
  [사용 가능한 테이블 목록 조회],
  [`sql_db_schema`],
  [테이블 스키마(DDL) 조회],
  [`sql_db_query`],
  [SQL 쿼리 실행],
  [`sql_db_query_checker`],
  [쿼리 실행 전 문법 검증],
)


#code-block(`````python
from langchain_community.agent_toolkits import SQLDatabaseToolkit

toolkit = SQLDatabaseToolkit(db=db, llm=model)
sql_tools = toolkit.get_tools()
for t in sql_tools:
    print(f"  {t.name}: {t.description[:60]}")

`````)
#output-block(`````
sql_db_query: Input to this tool is a detailed and correct SQL query, outp
  sql_db_schema: Input to this tool is a comma-separated list of tables, outp
  sql_db_list_tables: Input is an empty string, output is a comma-separated list o
  sql_db_query_checker: Use this tool to double check if your query is correct befor
`````)

== 3단계: 프롬프트 로드 (LangSmith / Langfuse / 기본값)

의  함수가 프롬프트를 로드합니다:
+ _LangSmith Hub_ — 가 있으면 Hub에서 pull
+ _Langfuse_ — 가 있으면 Langfuse에서 로드
+ _기본값_ — 둘 다 없으면 코드에 정의된 기본 프롬프트 사용

SQL 에이전트 프롬프트에는 READ-ONLY 안전 규칙과 워크플로가 포함되어 있습니다.

#code-block(`````python
from prompts import SQL_AGENT_PROMPT

print(SQL_AGENT_PROMPT)
`````)
#output-block(`````
Prompt 'rag-agent-label:production' not found during refresh, evicting from cache.

Prompt 'sql-agent-label:production' not found during refresh, evicting from cache.

Prompt 'data-analysis-agent-label:production' not found during refresh, evicting from cache.

Prompt 'ml-agent-label:production' not found during refresh, evicting from cache.

Prompt 'deep-research-agent-label:production' not found during refresh, evicting from cache.

당신은 SQL 에이전트입니다.

## 워크플로
1. sql_db_list_tables로 테이블 목록을 확인하세요
2. sql_db_schema로 관련 테이블의 스키마를 조회하세요
3. SQL 쿼리를 작성하고 sql_db_query_checker로 검증하세요
4. sql_db_query로 실행하고 결과를 해석하세요

## 안전 규칙
- READ-ONLY: SELECT만 허용. INSERT, UPDATE, DELETE, DROP 금지
- 항상 LIMIT 10을 사용하세요
- 쿼리 실행 전 반드시 스키마를 확인하세요
- 복잡한 쿼리는 write_todos로 단계별 계획을 세우세요
`````)

== 4단계: Skills 개념

Skills는 에이전트의 워크플로 가이드입니다. 반복되는 작업 패턴을 문서화하여 에이전트가 일관된 방식으로 작업하도록 합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[스킬],
  text(weight: "bold")[용도],
  [`query-writing`],
  [테이블 확인 → 스키마 조회 → SQL 작성 → 실행],
  [`schema-exploration`],
  [테이블 목록 → DDL 조회 → 관계 매핑],
)


== 5단계: 기본 SQL 에이전트 생성

`create_deep_agent`에 SQL 도구와 AGENTS.md를 전달하여 에이전트를 생성합니다. `system_prompt`로 AGENTS.md 내용을 주입합니다.


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

== 6단계: HITL 에이전트 (interrupt_on)

`create_deep_agent`의 `interrupt_on` 파라미터로 도구별 승인 정책을 설정합니다. `sql_db_query` 호출 전에 실행이 중단되고, `Command(resume=...)`로 재개합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[역할],
  [`interrupt_on={"sql_db_query": True}`],
  [`sql_db_query` 호출 전 실행 중단, 사람 승인 대기],
  [`ModelCallLimitMiddleware`],
  [무한 루프 방지 — 최대 15회 모델 호출 제한],
  [`InMemorySaver`],
  [체크포인팅으로 중단/재개 지원],
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

== 7단계: 승인 후 재개

`Command(resume={"decisions": [{"type": "approve"}]})`로 중단된 실행을 재개합니다. v1에서는 `HITLResponse` 형식으로 결정을 전달합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[결정 유형],
  text(weight: "bold")[설명],
  [`{"type": "approve"}`],
  [도구 호출 승인 — 그대로 실행],
  [`{"type": "edit", "edited_action": {...}}`],
  [도구 호출 수정 후 실행],
  [`{"type": "reject", "message": "..."}`],
  [도구 호출 거부 — 에이전트에 피드백],
)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_도구 생성_],
  [`SQLDatabaseToolkit(db, llm).get_tools()` → 4개 SQL 도구 자동 생성],
  [_안전 규칙_],
  [AGENTS.md로 READ-ONLY 정책 적용],
  [_Skills_],
  [query-writing, schema-exploration 워크플로 가이드],
  [_HITL_],
  [`interrupt_on={"sql_db_query": True}` → `Command(resume="approve")`],
)


#references-box[
- `docs/deepagents/examples/03-text-to-sql-agent.md`
- #link("https://python.langchain.com/docs/tutorials/sql_qa/")[LangChain SQL Agent Tutorial]
- `docs/deepagents/06-backends.md`
_다음 단계:_ → #link("./03_data_analysis_agent.ipynb")[03_data_analysis_agent.ipynb]: 데이터 분석 에이전트를 구축합니다.
]
#chapter-end()
