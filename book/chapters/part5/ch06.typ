// Auto-generated from 06_sql_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "SQL 에이전트 심화", subtitle: "- LangChain & LangGraph")

이전 장의 Agentic RAG가 비정형 문서를 다뤘다면, SQL 에이전트는 정형 데이터베이스에 자연어로 질의하는 패턴입니다. 자연어를 SQL 쿼리로 변환하는 에이전트를 두 가지 방법으로 구축합니다: LangChain `create_agent` + `SQLDatabaseToolkit` (간단 버전)과 LangGraph `StateGraph` (커스텀 버전). Human-in-the-Loop, `interrupt()`, `Command(resume=...)` 패턴을 다룹니다.

#learning-header()
#learning-objectives([SQL 에이전트의 8단계 워크플로우를 이해한다], [`SQLDatabase`와 `SQLDatabaseToolkit`의 4개 도구를 활용한다], [LangChain `create_agent`로 ReAct 기반 SQL Agent를 구현한다], [`HumanInTheLoopMiddleware`로 쿼리 실행 전 승인을 추가한다], [LangGraph `StateGraph`로 커스텀 SQL Agent를 구축한다], [`bind_tools`와 `tool_choice`로 강제 도구 호출을 설정한다], [`interrupt()`와 `Command(resume=...)`로 쿼리 리뷰를 구현한다])

== 6.1 환경 설정 (SQLite + Chinook DB)

SQL 에이전트를 구축하기 위해 LLM과 데이터베이스를 연결합니다. Chinook DB는 디지털 음악 스토어의 샘플 데이터베이스로, Artist, Album, Track, Invoice 등 11개 테이블을 포함합니다. `SQLDatabase` 래퍼는 SQLAlchemy를 기반으로 데이터베이스 메타데이터(테이블 목록, 스키마, 샘플 데이터)에 프로그래밍 방식으로 접근하는 인터페이스를 제공합니다.

#code-block(`````python
# %pip install langchain langchain-openai langchain-community langgraph sqlalchemy python-dotenv

from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
from langchain_community.utilities import SQLDatabase

llm = ChatOpenAI(model="gpt-4.1")
db = SQLDatabase.from_uri("sqlite:///Chinook.db")
print(f"Dialect: {db.dialect}")
`````)
#output-block(`````
Dialect: sqlite
`````)

== 6.2 SQL 에이전트 개요

SQL 에이전트는 자연어 질문을 SQL 쿼리로 변환하는 _8단계_ 프로세스를 따릅니다:

#align(center)[#image("../../assets/diagrams/png/sql_query_review_flow.png", width: 92%, height: 82mm, fit: "contain")]

실무에서는 이 흐름을 두 갈래로 기억하면 됩니다. _정상 경로_ 는 생성 → 검증 → 승인 → 실행으로 이어지고, _보호 경로_ 는 검증 실패나 사람 거절 시 즉시 다시 작성하거나 사용자에게 추가 정보를 요구합니다.

=== 왜 에이전트가 필요한가?

단순 text-to-SQL과 달리 에이전트 방식은 _스키마 탐색 → 쿼리 생성 → 검증 → 실행_의 반복 루프를 수행합니다. 잘못된 쿼리가 생성되면 에이전트가 오류를 분석하고 쿼리를 재작성할 수 있어 정확도가 크게 향상됩니다. 또한 에이전트는 필요한 테이블의 스키마만 선택적으로 로드하므로 _컨텍스트 윈도우를 효율적으로_ 사용합니다.

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

#warning-box[SQL 에이전트는 데이터베이스에 직접 쿼리를 실행하므로, 반드시 _읽기 전용 계정_을 사용하고 `include_tables`로 접근 범위를 제한해야 합니다. DML(INSERT/UPDATE/DELETE) 실행을 시스템 프롬프트로만 방지하는 것은 불충분합니다 — DB 레벨 권한 설정이 근본적인 안전장치입니다.]

=== 접근 가능 테이블 제한

프로덕션에서는 에이전트가 접근할 수 있는 테이블을 명시적으로 제한하는 것이 좋습니다:

#code-block(`````python
db = SQLDatabase.from_uri(
    "sqlite:///company.db",
    include_tables=["products", "orders", "order_items"],  # 허용 목록
    # exclude_tables=["users", "credentials"],             # 또는 차단 목록
)
`````)

SQL 에이전트의 전체 구조와 안전 수칙을 이해했으니, 이제 실제 구현의 핵심인 도구(tool) 레이어를 살펴봅니다. `SQLDatabaseToolkit`은 데이터베이스 연결 하나로 SQL 에이전트에 필요한 모든 도구를 자동으로 생성해 주는 유틸리티입니다.

== 6.3 SQLDatabaseToolkit

`SQLDatabaseToolkit`은 `SQLDatabase` 인스턴스와 LLM을 받아 4개의 도구를 자동 생성합니다. 이 도구들은 SQL 에이전트 워크플로의 각 단계에 1:1로 매핑됩니다:

#tip-box[`sql_db_query_checker`는 내부적으로 LLM을 사용하여 쿼리를 검사합니다. 따라서 `SQLDatabaseToolkit(db=db, llm=llm)`에서 LLM을 전달하는 것이 필수입니다. 쿼리 검증에 사용되는 LLM은 에이전트의 메인 LLM과 동일하거나, 비용 절감을 위해 더 가벼운 모델을 지정할 수 있습니다.]

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

에이전트가 생성되었으니, 실제 자연어 질문을 던져 SQL 에이전트의 동작을 확인합니다. 에이전트가 도구를 호출하는 순서와 생성하는 SQL 쿼리를 주의 깊게 관찰하세요. 시스템 프롬프트에 지시한 워크플로(list_tables -> schema -> query_checker -> query)를 따르는지 확인하는 것이 핵심입니다.

LangChain `create_agent` 기반의 SQL 에이전트는 간단하게 프로토타입을 만들 수 있지만, 프로덕션 환경에서는 SQL 쿼리 실행 전 반드시 사람의 검토가 필요합니다. 다음 절에서 이를 구현합니다.

== 6.6 HITL -- `HumanInTheLoopMiddleware`

프로덕션 환경에서는 SQL 쿼리 실행 전 _사람의 승인이 필수_입니다. 에이전트가 생성한 쿼리가 비용이 높거나, 예상치 못한 테이블에 접근하거나, 의도와 다른 결과를 반환할 수 있기 때문입니다.

`HumanInTheLoopMiddleware`는 지정된 도구(`sql_db_query`) 호출을 가로채서 실행을 일시 중단하고, 사람이 리뷰할 수 있도록 합니다.

=== 리뷰 옵션 3가지

에이전트가 `sql_db_query`를 호출하려 할 때, 실행이 일시 중단되고 사람은 다음 중 하나를 선택합니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[옵션],
  text(weight: "bold")[`Command(resume=...)` 값],
  text(weight: "bold")[설명],
  [_승인_],
  [`"approve"`],
  [생성된 쿼리를 그대로 실행],
  [_수정_],
  [`{"type": "edit", "args": {"query": "..."}}`],
  [쿼리를 수정한 후 실행],
  [_거부_],
  [`{"type": "reject", "reason": "..."}`],
  [쿼리를 실행하지 않고 사유를 전달],
)

=== 왜 HITL이 중요한가?

리뷰 단계는 단순 승인 버튼이 아니라 _분기점_ 입니다.

- _승인 경로_ — 생성된 쿼리를 그대로 실행하여 빠른 응답 제공
- _수정 경로_ — WHERE 조건, LIMIT, 집계 방식만 사람 손으로 보정
- _거절 경로_ — 쿼리를 실행하지 않고 질문을 더 좁히거나 정책 위반 사유를 설명

- _비용 제어_: `LIMIT` 없는 대규모 테이블 풀 스캔 방지
- _데이터 보호_: 민감한 컬럼 접근 사전 차단
- _정확성 검증_: 에이전트가 질문 의도를 잘못 해석한 경우 수정 가능
- _감사 추적(Audit Trail)_: 모든 실행된 쿼리에 대한 승인 기록 유지

#code-block(`````python
from langchain.agents.middleware import HumanInTheLoopMiddleware

hitl = HumanInTheLoopMiddleware(
    interrupt_on={"sql_db_query": True},
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

`create_agent` 기반 SQL 에이전트는 빠르게 프로토타입을 만들 수 있지만, 도구 호출 순서가 LLM의 자율 판단에 의존합니다. 프로덕션에서는 스키마 조회 → 쿼리 생성 → 검증 → 실행의 순서를 _강제_하고, 쿼리 리뷰를 위한 정확한 중단점을 설정해야 합니다. LangGraph `StateGraph`가 이를 가능하게 합니다.

== 6.7 LangGraph 커스텀 SQL Agent -- StateGraph

LangChain `create_agent`는 빠르게 프로토타입을 만들 수 있지만, _노드 단위의 세밀한 제어_가 필요하면 LangGraph `StateGraph`를 사용합니다. 각 단계를 독립적인 노드로 정의하여 다음을 실현할 수 있습니다:

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

`tool_choice` 파라미터로 특정 도구를 _강제_ 호출하도록 설정합니다. 이는 `create_agent`의 ReAct 루프에서 LLM이 자율적으로 도구를 선택하는 것과 대비됩니다. `StateGraph`에서는 특정 노드에서 _반드시_ 특정 도구를 호출하도록 강제할 수 있어, 워크플로의 일관성이 보장됩니다. 예를 들어, `list_tables` 노드에서는 반드시 `sql_db_list_tables` 도구를 호출하고, `get_schema` 노드에서는 반드시 `sql_db_schema`를 호출하도록 설정할 수 있습니다.

#tip-box[`bind_tools(tools, tool_choice="sql_db_list_tables")`는 LLM에게 해당 도구를 _반드시_ 호출하도록 강제합니다. 이는 OpenAI API의 `tool_choice` 파라미터를 활용하며, LLM이 도구 호출 없이 텍스트 응답만 생성하는 것을 방지합니다. 특정 노드에서 확실한 도구 호출이 필요할 때 사용하세요.]

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

`interrupt()`로 중단된 그래프를 재개하려면 `Command(resume=...)`를 사용합니다. 이 패턴은 에이전트 실행의 _비동기적 중단과 재개_를 가능하게 합니다. 웹 애플리케이션에서는 사용자가 쿼리를 리뷰하는 동안 에이전트 상태가 체크포인터에 저장되며, 사용자의 결정(승인/수정/거부)이 `Command(resume=...)`를 통해 전달되면 정확히 중단된 지점에서 실행이 재개됩니다.

#warning-box[`interrupt()` 사용 시 반드시 체크포인터(`InMemorySaver`, `SqliteSaver` 등)를 설정해야 합니다. 체크포인터 없이 `interrupt()`를 호출하면 그래프 상태가 소실되어 재개가 불가능합니다. 또한 `thread_id`를 통해 세션을 식별하므로, 같은 `thread_id`로 `Command(resume=...)`를 전달해야 올바른 세션이 재개됩니다.]

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

SQL 에이전트는 정형 데이터에 자연어 인터페이스를 제공합니다. 다음 장에서는 코드 실행 샌드박스를 활용하여 비정형 데이터(CSV, 이미지 등)를 프로그래밍 방식으로 분석하는 데이터 분석 에이전트를 구축합니다.


