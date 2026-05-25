// Source: 06_langsmith/02_tracing_agents.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "에이전트 트레이스 구조", subtitle: "Subgraph · SubAgent · Thread · Feedback")

1장에서 `create_agent` 한 번의 실행을 UI에서 봤다면, 이 장은 _LangGraph StateGraph · Deep Agents 서브에이전트 · 비동기 태스크_처럼 중첩 구조가 있는 에이전트가 어떻게 트레이스로 그려지는지를 다룹니다. Run/Trace/Project/Thread 4층 개념, 서브그래프 네임스페이스, 동기 vs 비동기 서브에이전트의 트레이스 차이, feedback API, 400일 보존 한계까지 운영 관점 이슈를 정리합니다.

#learning-header()
#learning-objectives(
  [Run · Trace · Project · Thread의 관계를 이해한다 (run = span, trace = span tree)],
  [LangGraph 서브그래프가 부모 트레이스 안에서 네임스페이스 자식으로 표시되는 방식을 확인한다],
  [Deep Agents 동기 서브에이전트와 비동기 서브에이전트(`async_tasks` 채널) 트레이스 차이를 구분한다],
  [`thread_id` / `session_id`로 여러 실행을 세션 뷰에 묶는다],
  [`client.create_feedback(run_id, key, score)`로 런에 평가 점수를 부착한다],
  [`client.list_runs(filter=...)`로 태그·메타데이터 기반 프로그램 필터링을 한다],
  [400일 보존 한계를 넘기기 위해 주요 트레이스를 _데이터셋으로 영구화_한다],
)

== 2.1 Run · Trace · Project · Thread 개념

LangSmith의 데이터 계층은 네 레벨로 쌓입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[레벨],
  text(weight: "bold")[정의],
  text(weight: "bold")[예],
  [*Project*],
  [같은 애플리케이션의 트레이스를 모아두는 컨테이너],
  [`langsmith-tracing-agents`],
  [*Trace*],
  [하나의 사용자 요청을 처리하는 동안 만들어진 run 트리 (최대 25,000 run / trace)],
  [에이전트 한 번 invoke],
  [*Run*],
  [단일 span — LLM 호출, tool 호출, chain 노드 등],
  [`ChatOpenAI`, `get_weather`],
  [*Thread*],
  [`thread_id`/`session_id`/`conversation_id`로 묶인 여러 trace — 멀티턴 대화 뷰],
  [한 사용자의 세션],
)

Run 하나에는 `parent_run_id`, `trace_id`, `start_time`, `end_time`, `inputs`, `outputs`, `total_tokens`, `total_cost` 등이 붙습니다. _Trace는 같은 `trace_id`를 공유하는 run들의 트리_입니다.

#figure(image("../../../assets/images/langsmith/02_tracing_agents/00_runs_populated_full.png", width: 95%), caption: [프로젝트 Runs 리스트 — Name/Input/Output/Error/Latency/Dataset/Tokens/Cost/Tags/Metadata 등 17개 컬럼])

#figure(image("../../../assets/images/langsmith/02_tracing_agents/01_subgraph_tree_namespace.png", width: 95%), caption: [LangGraph subgraph trace tree — `PatchToolCallsMiddleware → model → ChatOpenAI → TodoListMiddleware` 체인이 네임스페이스로 구성됨])

== 2.2 LangGraph StateGraph 트레이스 트리

LangGraph 그래프는 _그래프가 루트 run_, 각 노드가 자식 run, 서브그래프는 네임스페이스가 붙은 손자 run으로 나타납니다. 서브그래프 노드 이름은 UI에서 `parent_node:child_node` 형식으로 표시됩니다.

#code-block(`````python
from langgraph.graph import StateGraph
from langsmith import tracing_context

with tracing_context(name="writer-pipeline", tags=["env:dev"]):
    result = pipeline.invoke({"topic": "agent streaming"})
`````)

UI에서 `writer-pipeline` 트레이스를 열면 루트 아래 `research`, `writer` 노드가 자식이고, `writer` 안에 `writer:outline`, `writer:draft` 손자 run이 네임스페이스와 함께 표시됩니다. _서브그래프 경로가 run 이름에 그대로 박히므로_ `name contains writer:` 같은 필터를 쓸 수 있습니다.

== 2.3 Deep Agents 서브에이전트 트레이스 (동기 · 비동기)

Deep Agents의 서브에이전트는 부모 run 아래 독립된 자식 트리로 나타납니다.

- *동기* (`SubAgent` dict): 부모가 블로킹되므로 단일 trace. `task` 툴 호출 run 아래에 서브에이전트의 LLM/tool 호출이 중첩됩니다.
- *비동기* (`AsyncSubAgent`): 별개의 Agent Protocol 서버에서 실행되므로 부모와 _다른 trace_로 기록됩니다. 부모 상태의 `async_tasks` 채널에 `task_id`만 남고, 부모 trace에는 `start_async_task` / `check_async_task` 같은 관리 tool 호출만 보입니다.

#figure(image("../../../assets/images/langsmith/02_tracing_agents/02_subagent_sync_trace.png", width: 95%), caption: [Deep Agents 동기 서브에이전트 + user_thumbs 1.00 feedback — `tools → task → researcher` 체인과 Feedback 탭])

#figure(image("../../../assets/images/langsmith/02_tracing_agents/05_thread_detail_conversation.png", width: 95%), caption: [Thread Turn View — 각 turn의 Input/Output을 대화 버블로 표시, `task call` description과 `subagent_type: researcher` YAML 노출])

#code-block(`````python
from deepagents import AsyncSubAgent

researcher = AsyncSubAgent(name="researcher", description="장시간 리서치", graph_id="researcher")
# 부모 trace: start_async_task 툴 호출만
# 자식 trace: researcher 그래프가 별개 trace (동일 thread_id로 묶임)
# 상태 보존: async_tasks 채널은 compaction 을 거쳐도 살아남음
`````)

== 2.4 세션 뷰 — `thread_id` · `session_id` · `conversation_id`

여러 번의 invoke를 _하나의 대화_로 묶으려면 `metadata`에 세션 식별자를 넣습니다. `thread_id`, `session_id`, `conversation_id` 중 하나라도 있으면 LangSmith가 자동으로 Threads 뷰에 묶습니다.

#code-block(`````python
agent.invoke(
    {"messages": [{"role": "user", "content": "..."}]},
    config={"metadata": {"thread_id": "t_demo_0001", "user_id": "u_alice"}},
)
`````)

#figure(image("../../../assets/images/langsmith/02_tracing_agents/04_thread_view.png", width: 95%), caption: [Threads 탭 — 동일 `thread_id` 공유 run들이 대화 세션으로 묶임. First Input / Last Output / turns / tokens / cost / P50·P99 Latency 자동 집계])

== 2.5 런에 피드백 부착 — `client.create_feedback`

평가 점수, 사용자 thumbs-up/down, 내부 QA 리뷰 결과는 *Feedback*으로 run에 붙입니다.

- `key`: 피드백 이름 (예: `"correctness"`, `"user_thumbs"`)
- `score`: 0~1 사이 실수 또는 임의 숫자
- `value`, `comment`: 선택

#code-block(`````python
from langsmith import Client

client = Client()
client.create_feedback(
    run_id=latest_run.id,
    key="user_thumbs",
    score=1.0,
    comment="정답을 정확히 뽑아냄",
)
`````)

== 2.6 태그·메타데이터 기반 필터 쿼리

UI 필터와 똑같은 표현식을 `client.list_runs(filter=...)`로 코드에서 씁니다. 회귀 테스트, 야간 배치, 대시보드 피딩에 두루 씁니다.

#code-block(`````python
runs = client.list_runs(
    project_name="langsmith-tracing-agents",
    filter='and(has(tags, "env:prod"), eq(run_type, "chain"))',
    limit=50,
)
`````)

#figure(image("../../../assets/images/langsmith/02_tracing_agents/06_add_filter_menu.png", width: 95%), caption: [Add filter 메뉴: Tag·Metadata가 별도 필드로 존재 — `tags contains env:dev` 같은 조건 쿼리 가능])

== 2.7 `@traceable` 데코레이터 — run_type별 종류

`@traceable`은 LangChain 외부 함수를 트레이스 트리에 편입하는 데 쓰며, `run_type`으로 UI 아이콘과 필터 카테고리가 정해집니다. 자주 쓰는 값은 다음과 같습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[run_type],
  text(weight: "bold")[용도],
  text(weight: "bold")[UI 표시],
  [`chain`],
  [기본값 — 임의의 함수 / 파이프라인 스텝],
  [체인 아이콘, `chain` 필터],
  [`llm`],
  [수동 LLM 호출 (provider SDK 직접 사용 등)],
  [LLM 아이콘, 토큰/비용 자동 합산],
  [`tool`],
  [외부 시스템 호출 (검색·DB·API)],
  [도구 아이콘, `tool` 필터],
  [`retriever`],
  [벡터스토어·검색 단계],
  [retriever 아이콘, document 카운트 표시],
  [`embedding`],
  [임베딩 계산 단계],
  [embedding 아이콘],
  [`parser`],
  [출력 파싱·후처리],
  [parser 아이콘],
)

#code-block(`````python
from langsmith import traceable

@traceable(run_type="retriever", name="vector-search")
def search(query: str) -> list[dict]:
    return vectorstore.similarity_search_with_score(query, k=4)

@traceable(run_type="tool", name="lookup-order")
def lookup_order(order_id: str) -> dict:
    return db.fetch_order(order_id)
`````)

== 2.8 PII 마스킹 — `LangChainTracer` + `Client(anonymizer=...)`

LangSmith로 보내기 _직전_에 input/output을 정규식으로 마스킹하려면 `create_anonymizer`로 패턴 목록을 만든 뒤 `Client(anonymizer=...)`에 주입합니다. 이 클라이언트로 만든 `LangChainTracer`를 `config={"callbacks": [...]}`로 꽂으면 해당 실행만 PII가 가려진 채 기록됩니다.

#code-block(`````python
from langsmith import Client
from langsmith.anonymizer import create_anonymizer
from langchain.callbacks.tracers import LangChainTracer

anonymizer = create_anonymizer([
    {"pattern": r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+", "replace": "<email>"},
    {"pattern": r"\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b",            "replace": "<card>"},
    {"pattern": r"010[ -]?\d{4}[ -]?\d{4}",                              "replace": "<phone>"},
])
masked_client = Client(anonymizer=anonymizer)
tracer = LangChainTracer(client=masked_client, project_name="prod-masked")

agent.invoke(
    {"messages": [{"role": "user", "content": "내 이메일 a@b.com, 010-1234-5678"}]},
    config={"callbacks": [tracer]},
)
`````)

전체 input/output을 통째로 차단하려면 `Client(hide_inputs=lambda _: {}, hide_outputs=lambda _: {})` 또는 `LANGSMITH_HIDE_INPUTS=true` 환경 변수를 씁니다. 5장에서 `PIIMiddleware`와 함께 이중 방어 패턴으로 다시 다룹니다.

== 2.9 Selective tracing — 일부 실행만 기록

전역 트레이싱을 켜둔 상태에서 _특정 호출만 제외_하거나, _특정 호출만 따로 다른 프로젝트로 보내는_ 패턴이 자주 필요합니다.

#code-block(`````python
import langsmith as ls

# 1) 환경변수가 켜져 있어도 이 블록만 비활성화
with ls.tracing_context(enabled=False):
    agent.invoke({"messages": [{"role": "user", "content": "민감 데이터..."}]})

# 2) 디버깅용 호출만 별도 프로젝트로 라우팅
with ls.tracing_context(project_name="langsmith-debug", tags=["mode:debug"]):
    agent.invoke({"messages": [{"role": "user", "content": "테스트 케이스"}]})
`````)

`tracing_context`는 thread-local로 적용되므로 비동기 환경에서도 안전합니다. 환경 변수와 컨텍스트 매니저, `config={"callbacks": [...]}` 세 경로의 우선순위는 _가까운 스코프 우선_입니다.

== 2.10 400일 보존 한계 → 데이터셋으로 영구화

SaaS LangSmith는 _ingestion 시점부터 400일_ 후 trace가 삭제됩니다. 평가 회귀에 쓸 실행은 _Dataset으로 영구화_해야 합니다. 3장에서 자세히 다루고, 여기선 패턴만 확인합니다.

#code-block(`````python
# langsmith 0.7+에서는 add_runs_to_dataset이 제거되었으므로
# create_examples로 run의 inputs/outputs를 직접 example로 변환한다.
golden_runs = [r for r in runs if r.feedback.get("user_thumbs") == 1]
ds = client.create_dataset("agent-golden-traces",
                           description="사람이 승인한 황금 trace")
client.create_examples(
    dataset_id=ds.id,
    examples=[
        {"inputs": r.inputs,
         "outputs": r.outputs,
         "metadata": {"source_run_id": str(r.id)}}
        for r in golden_runs if r.outputs
    ],
)
`````)

== 핵심 정리

- Project → Trace → Run + Thread(세션 묶음) 4층 개념이 모든 UI 뷰의 기초
- LangGraph 서브그래프는 네임스페이스가 run 이름에 박히므로 필터 가능
- Deep Agents 동기 서브에이전트는 단일 trace, 비동기는 별개 trace — `async_tasks` 채널로 추적
- `thread_id`/`session_id` 메타데이터가 Threads 뷰 묶음을 트리거
- Feedback API + `list_runs(filter=...)`로 평가 루프의 프로그램적 연결
- `@traceable`의 `run_type`(`chain`/`llm`/`tool`/`retriever`/`embedding`/`parser`)이 UI 아이콘과 필터 카테고리를 결정
- PII는 `create_anonymizer` + `Client(anonymizer=...)` + `LangChainTracer` 조합으로 트레이스 전송 직전 마스킹
- Selective tracing은 `ls.tracing_context(enabled=...)`로 블록 단위 on/off — thread-local
- 400일 보존 한계를 넘기려면 Dataset으로 이관
