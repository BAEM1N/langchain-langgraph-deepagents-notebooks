// Auto-generated from 06_sql_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "SQL 에이전트 심화", subtitle: "- LangChain & LangGraph")

자연어를 SQL 쿼리로 변환하는 에이전트를 두 가지 방법으로 구축합니다: LangChain `create_agent` + `SQLDatabaseToolkit` (간단 버전)과 LangGraph `StateGraph` (커스텀 버전). Human-in-the-Loop, `interrupt()`, `Command(resume=...)` 패턴을 다룹니다.

== 학습 목표
#learning-objectives([SQL 에이전트의 8단계 워크플로우를 이해한다], [`SQLDatabase`와 `SQLDatabaseToolkit`의 4개 도구를 활용한다], [LangChain `create_agent`로 ReAct 기반 SQL Agent를 구현한다], [`HumanInTheLoopMiddleware`로 쿼리 실행 전 승인을 추가한다], [LangGraph `StateGraph`로 커스텀 SQL Agent를 구축한다], [`bind_tools`와 `tool_choice`로 강제 도구 호출을 설정한다], [`interrupt()`와 `Command(resume=...)`로 쿼리 리뷰를 구현한다])

== 6.1 환경 설정 (SQLite + Chinook DB)

#code-block(`````python
# %pip install langchain langchain-openai langchain-community langgraph sqlalchemy python-dotenv

from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
from langchain_community.utilities import SQLDatabase

llm = ChatOpenAI(model="gpt-5.4")
db = SQLDatabase.from_uri("sqlite:///Chinook.db")
print(f"Dialect: {db.dialect}")
`````)
#output-block(`````
Dialect: sqlite
`````)

== 6.2 SQL 에이전트 개요

SQL 에이전트는 자연어 질문을 SQL 쿼리로 변환하는 _8단계_ 프로세스를 따릅니다:

#code-block(`````python
1. 질문 수신 -> 2. 테이블 목록 -> 3. 관련 테이블 스키마
-> 4. SQL 쿼리 생성 -> 5. 쿼리 검증 -> 6. (선택) 사람 리뷰
-> 7. 쿼리 실행 -> 8. 결과 해석
`````)

=== 왜 에이전트가 필요한가?

단순 text-to-SQL과 달리 에이전트 방식은 _스키마 탐색 → 쿼리 생성 → 검증 → 실행_의 반복 루프를 수행합니다. 잘못된 쿼리가 나오면 에이전트가 오류를 분석하고 쿼리를 재작성할 수 있어 정확도가 크게 높아집니다. 에이전트는 필요한 테이블의 스키마만 선택적으로 로드하므로 _컨텍스트 윈도우를 효율적으로_ 사용합니다.

=== 에이전트 실행 트레이스 예시

#code-block(`````python
User: "지난달 매출 상위 5개 제품은?"

Agent -> sql_db_list_tables()
      <- "customers, orders, order_items, products, categories"

Agent -> sql_db_schema("orders, order_items, products")
      <- CREATE TABLE orders (id INT, order_date DATE, ...)
         CREATE TABLE order_items (order_id INT, product_id INT, quantity INT, price DECIMAL, ...)

Agent -> sql_db_query_checker("SELECT p.name, SUM(oi.quantity * oi.price) ...")
      <- "The query looks correct."

Agent -> sql_db_query(validated_query)
      <- [("Widget Pro", 45230.00), ("Gadget X", 38100.00), ...]
`````)

=== 안전 수칙

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[우려사항],
  text(weight: "bold")[대응],
  [SQL Injection],
  [파라미터화된 쿼리 사용, Toolkit이 자동 처리],
  [DML 실행],
  [시스템 프롬프트에서 INSERT/UPDATE/DELETE 금지, DB 레벨 읽기 전용 권한 설정],
  [비용 높은 쿼리],
  [LIMIT 강제, Human-in-the-Loop으로 실행 전 승인],
  [민감 데이터],
  [`include_tables`/`exclude_tables`로 접근 가능 테이블 제한, 컬럼 레벨 권한 설정],
  [데이터 노출],
  [데이터베이스 뷰(view) 또는 제한된 사용자 권한 활용],
)

=== 접근 가능 테이블 제한

프로덕션에서는 에이전트가 접근할 수 있는 테이블을 명시적으로 제한하는 것이 좋습니다:

#code-block(`````python
db = SQLDatabase.from_uri(
    "sqlite:///company.db",
    include_tables=["products", "orders", "order_items"],  # 허용 목록
    # exclude_tables=["users", "credentials"],             # 또는 차단 목록
)
`````)

== 6.3 SQLDatabaseToolkit

4개의 도구를 자동 생성합니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[기능],
  [`sql_db_list_tables`],
  [데이터베이스의 모든 테이블 이름 반환],
  [`sql_db_schema`],
  [CREATE TABLE 문 + 샘플 행 반환],
  [`sql_db_query`],
  [SQL 쿼리를 실행하고 결과 반환],
  [`sql_db_query_checker`],
  [LLM이 쿼리의 오류를 사전 검사],
)

#code-block(`````python
from langchain_community.agent_toolkits import SQLDatabaseToolkit

toolkit = SQLDatabaseToolkit(db=db, llm=llm)
tools = toolkit.get_tools()

for t in tools:
    print(f"  {t.name}: {t.description[:60]}...")
print(f"총 도구 수: {len(tools)}")
`````)
#output-block(`````
sql_db_query: Input to this tool is a detailed and correct SQL query, outp...
  sql_db_schema: Input to this tool is a comma-separated list of tables, outp...
  sql_db_list_tables: Input is an empty string, output is a comma-separated list o...
  sql_db_query_checker: Use this tool to double check if your query is correct befor...
총 도구 수: 4
`````)

== 6.4 LangChain SQL Agent -- `create_agent` + ReAct

`create_agent`는 LangChain의 고수준 API로, 모델과 도구를 받아 _ReAct(Reasoning + Acting) 루프_를 자동으로 구성합니다. 에이전트는 시스템 프롬프트에 정의된 워크플로우를 따라 도구를 순서대로 호출합니다.

=== ReAct 루프 동작 원리

+ LLM이 사용자 질문과 대화 이력을 분석하여 _다음에 호출할 도구_를 결정합니다
+ 도구가 실행되고 결과가 대화 이력에 추가됩니다
+ LLM이 결과를 확인하고, 추가 도구 호출이 필요하면 1단계로 돌아갑니다
+ 최종 답변이 준비되면 텍스트 응답을 반환합니다

=== 시스템 프롬프트의 역할

시스템 프롬프트는 에이전트의 행동 지침을 정의합니다. SQL 에이전트에서는 특히 다음을 명시해야 합니다:
- _도구 호출 순서_: `list_tables` → `schema` → `query_checker` → `query` 순서 강제
- _안전 규칙_: `LIMIT` 사용, DML 금지, 필요한 컬럼만 조회
- _오류 처리_: 쿼리 오류 발생 시 재작성 지시
- _SQL 방언_: 현재 DB의 dialect(SQLite, PostgreSQL 등) 명시

#code-block(`````python
system_prompt = (
    "당신은 SQL 에이전트입니다. 단계:\n"
    "1. sql_db_list_tables\n2. sql_db_schema\n"
    "3. 쿼리 작성 + sql_db_query_checker\n"
    "4. sql_db_query\n5. 결과를 해석하세요.\n"
    f"규칙: LIMIT 10 사용. DML 금지. Dialect: {db.dialect}"
)
`````)

#code-block(`````python
from langchain.agents import create_agent

sql_agent = create_agent(
    model=llm, tools=tools, system_prompt=system_prompt,
)
print("LangChain SQL 에이전트 생성됨.")
`````)
#output-block(`````
LangChain SQL 에이전트 생성됨.
`````)

== 6.5 실행 테스트

== 6.6 HITL — `HumanInTheLoopMiddleware`

프로덕션에서는 SQL 쿼리 실행 전 _사람 승인_이 필요합니다. 에이전트가 만든 쿼리가 비용을 유발하거나, 예상 외 테이블에 접근하거나, 의도와 다른 결과를 반환할 수 있기 때문입니다.

`HumanInTheLoopMiddleware` 는 지정한 도구(`sql_db_query`) 호출을 가로채 그래프를 일시 중단합니다. 사람이 결정을 내리면 `Command(resume={"decisions": [...]})` 로 그래프를 재개합니다 (v2 invocation 필수).

=== 4가지 decision 타입

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[타입],
  text(weight: "bold")[`Command(resume=...)` 값],
  text(weight: "bold")[동작],
  [_approve_],
  [`{"decisions": [{"type": "approve"}]}`],
  [원본 인자 그대로 실행],
  [_edit_],
  [`{"decisions": [{"type": "edit", "edited_action": {"name": "sql_db_query", "args": {"query": "..."}}}]}`],
  [수정된 인자로 실행],
  [_reject_],
  [`{"decisions": [{"type": "reject", "message": "..."}]}`],
  [실행 거부, 대화에 메시지 추가],
  [_respond_],
  [`{"decisions": [{"type": "respond", "message": "..."}]}`],
  [도구 호출 건너뛰고, 사람의 응답이 도구 결과를 대체],
)

=== HITL이 필요한 이유

- _비용 제어_: `LIMIT` 없는 풀 스캔 차단
- _데이터 보호_: 민감 컬럼 접근 사전 차단
- _정확성 검증_: 에이전트가 질문 의도를 잘못 해석한 경우 수정
- _감사 추적_: 실행된 모든 쿼리에 대한 승인 기록 — DELETE / UPDATE 등 파괴적 쿼리는 반드시 HITL 필수

=== v2 invocation 필수

`Command(resume={"decisions": [...]})` 패턴은 `invoke(..., version="v2")` / `stream(..., version="v2")` 호출에서만 동작합니다. v2 결과는 `.interrupts`, `.value` 속성을 가진 `GraphOutput` 객체입니다.


#code-block(`````python
from langchain.agents.middleware import HumanInTheLoopMiddleware

# DELETE / UPDATE 가 위험한 환경: sql_db_query 를 전부 가로채거나,
# 특정 도구만 allowed_decisions 로 제한할 수 있습니다.
hitl = HumanInTheLoopMiddleware(
    interrupt_on={
        "sql_db_query": {"allowed_decisions": ["approve", "edit", "reject"]},
    },
    description_prefix="SQL 쿼리 실행 승인 필요",
)
sql_agent_hitl = create_agent(
    model=llm, tools=tools,
    system_prompt=system_prompt, middleware=[hitl],
)
print("HITL이 적용된 SQL 에이전트 생성됨.")

`````)
#output-block(`````
HITL이 적용된 SQL 에이전트 생성됨.
`````)

#code-block(`````python
from langgraph.types import Command

config = {"configurable": {"thread_id": "sql-review-1"}}

# v2 invocation 필요 (version="v2")
# 1) 첫 실행 — interrupt 발생 시점까지 진행
# result = sql_agent_hitl.invoke(
#     {"messages": [{"role": "user", "content": "고객이 가장 많은 나라는?"}]},
#     config=config, version="v2",
# )
# print(result.interrupts)  # HITLRequest 확인

# Option 1: Approve
# result = sql_agent_hitl.invoke(
#     Command(resume={"decisions": [{"type": "approve"}]}),
#     config=config, version="v2",
# )

# Option 2: Edit
# result = sql_agent_hitl.invoke(
#     Command(resume={"decisions": [
#         {"type": "edit",
#          "edited_action": {
#              "name": "sql_db_query",
#              "args": {"query": "SELECT Country, COUNT(*) FROM Customer GROUP BY Country LIMIT 10"},
#          }}
#     ]}),
#     config=config, version="v2",
# )

# Option 3: Reject (DELETE/UPDATE 차단 시 사용)
# result = sql_agent_hitl.invoke(
#     Command(resume={"decisions": [
#         {"type": "reject", "message": "DELETE 가 의심됩니다. SELECT 로 다시 작성하세요."}
#     ]}),
#     config=config, version="v2",
# )
print("HITL 재개 옵션: approve / edit / reject / respond (v2 invocation 필수)")

`````)
#output-block(`````
HITL 재개 옵션: approve / edit / reject
`````)

== 6.7 LangGraph 커스텀 SQL Agent -- StateGraph

LangChain `create_agent`는 빠르게 프로토타입을 만들 수 있지만, _노드 단위의 세밀한 제어_가 필요하면 LangGraph `StateGraph`를 사용합니다. 각 단계를 독립적인 노드로 정의하면 다음을 실현할 수 있습니다:

- _조건부 분기_: 쿼리 검증 실패 시 재생성 노드로 라우팅
- _강제 도구 호출_: `bind_tools(tool_choice=...)`로 특정 노드에서 반드시 특정 도구 호출
- _세밀한 중단점_: `interrupt()`로 원하는 노드에서 정확히 실행 중단
- _커스텀 상태_: 쿼리 이력, 재시도 횟수 등을 상태에 추가

=== 그래프 구조

#code-block(`````python
START -> list_tables -> get_schema -> generate_query
      -> check_query -> execute_query -> END
`````)

각 노드는 공유 `State` 객체를 받아 메시지를 추가하며, 에이전트가 워크플로우를 진행하는 동안 대화 이력이 누적됩니다. `tools_condition`을 사용하면 `check_query` 결과에 따라 쿼리를 재생성하거나 실행으로 진행하는 조건부 분기를 구현할 수 있습니다.

=== LangChain `create_agent` 대비 장점

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[측면],
  text(weight: "bold")[`create_agent`],
  text(weight: "bold")[`StateGraph`],
  [도구 호출 순서],
  [LLM 자율 결정],
  [그래프 엣지로 강제],
  [오류 시 재시도],
  [시스템 프롬프트에 의존],
  [조건부 엣지로 명시적 구현],
  [사람 리뷰],
  [미들웨어 기반],
  [`interrupt()` 기반, 위치 자유],
  [디버깅],
  [블랙박스],
  [노드별 상태 확인 가능],
)

#code-block(`````python
from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph.message import add_messages

class SQLState(TypedDict):
    messages: Annotated[list, add_messages]

print(f"SQLState 키: {list(SQLState.__annotations__)}")
`````)
#output-block(`````
SQLState 키: ['messages']
`````)

== 6.8 전용 노드 -- `list_tables`, `get_schema`, `generate_query`, `check_query`

각 노드는 SQL 에이전트 워크플로우의 한 단계를 담당합니다.

== 6.9 `bind_tools` with `tool_choice` -- 강제 도구 호출

`tool_choice` 파라미터로 특정 도구를 _강제_ 호출하도록 설정합니다.

== 6.10 `interrupt()`로 쿼리 리뷰

LangGraph의 `interrupt()` 함수는 그래프 실행을 _일시 중단_하고 외부 입력(사람의 리뷰)을 기다립니다. `HumanInTheLoopMiddleware`와 달리 `interrupt()`는 _노드 내부 코드의 정확한 위치_에서 중단할 수 있어 더 유연합니다.

=== 동작 원리

+ 노드 함수 내에서 `interrupt(payload)`를 호출하면 그래프 실행이 즉시 중단됩니다
+ `payload`는 클라이언트에게 전달되어 리뷰 UI에 표시됩니다 (예: 생성된 SQL 쿼리)
+ 클라이언트가 `Command(resume=value)`로 그래프를 재개하면, `interrupt()`가 `value`를 반환합니다
+ 노드 함수는 반환된 값에 따라 쿼리를 실행, 수정, 또는 거부합니다

=== `interrupt()` vs `HumanInTheLoopMiddleware`

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[`interrupt()`],
  text(weight: "bold")[`HumanInTheLoopMiddleware`],
  [적용 범위],
  [노드 내 코드 레벨],
  [도구 호출 레벨],
  [유연성],
  [임의 로직 구현 가능],
  [도구 호출 가로채기만 가능],
  [상태 접근],
  [전체 State 접근 가능],
  [도구 인자만 접근 가능],
  [체크포인터],
  [필수 (상태 저장 필요)],
  [선택적],
)

== 6.11 `Command(resume=...)` 패턴

`interrupt()`로 중단된 그래프를 재개하려면 `Command(resume=...)`를 사용합니다.

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver

builder = StateGraph(SQLState)
builder.add_node("list_tables", list_tables_node)
builder.add_node("get_schema", get_schema_node)
builder.add_node("generate_query", generate_query_node)
builder.add_node("check_query", check_query_node)
builder.add_node("execute_query", execute_query_node)
`````)
#output-block(`````
<langgraph.graph.state.StateGraph at 0x1f6f9914b00>
`````)

#code-block(`````python
builder.add_edge(START, "list_tables")
builder.add_edge("list_tables", "get_schema")
builder.add_edge("get_schema", "generate_query")
builder.add_edge("generate_query", "check_query")
builder.add_edge("check_query", "execute_query")
builder.add_edge("execute_query", END)

checkpointer = InMemorySaver()
sql_graph = builder.compile(checkpointer=checkpointer)
print("LangGraph SQL 에이전트 컴파일됨.")
`````)
#output-block(`````
LangGraph SQL 에이전트 컴파일됨.
`````)

#chapter-summary-header()

=== 두 가지 SQL Agent 비교

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[LangChain `create_agent`],
  text(weight: "bold")[LangGraph `StateGraph`],
  [구현 복잡도],
  [낮음 (5줄)],
  [높음 (전용 노드)],
  [제어 수준],
  [ReAct 자동],
  [노드 단위 커스텀],
  [HITL],
  [`HumanInTheLoopMiddleware`],
  [`interrupt()` + `Command(resume=...)`],
  [강제 도구 호출],
  [미지원],
  [`bind_tools(tool_choice=...)`],
  [적합한 경우],
  [빠른 프로토타입],
  [프로덕션, 세밀한 제어],
)

=== HITL 패턴

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[액션],
  text(weight: "bold")[`Command(resume=...)`],
  [Accept],
  [`{"action": "accept"}`],
  [Edit],
  [`{"action": "edit", "edited_query": "..."}`],
  [Reject],
  [`{"action": "reject", "reason": "..."}`],
)

=== SQLDatabaseToolkit 4개 도구

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[단계],
  text(weight: "bold")[용도],
  [`sql_db_list_tables`],
  [2],
  [테이블 목록 확인],
  [`sql_db_schema`],
  [3],
  [DDL + 샘플 데이터 조회],
  [`sql_db_query_checker`],
  [5],
  [쿼리 사전 검증],
  [`sql_db_query`],
  [7],
  [쿼리 실행],
)
