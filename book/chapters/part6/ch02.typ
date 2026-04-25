// Source: 08_langsmith/02_tracing_agents.ipynb
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

Run 하나에는 `parent_run_id`, `trace_id`, `start_time`, `end_time`, `inputs`, `outputs`, `total_tokens`, `total_cost` 등이 붙습니다. _Trace는 같은 `trace_id`를 공유하는 run들의 트리_일 뿐입니다.

#figure(image("../../../assets/images/langsmith/02_tracing_agents/00_runs_populated_full.png", width: 95%), caption: [프로젝트 Runs 리스트 — Name/Input/Output/Error/Latency/Dataset/Tokens/Cost/Tags/Metadata 등 17개 컬럼])

#figure(image("../../../assets/images/langsmith/02_tracing_agents/01_subgraph_tree_namespace.png", width: 95%), caption: [LangGraph subgraph trace tree — `PatchToolCallsMiddleware → model → ChatOpenAI → TodoListMiddleware` 체인이 네임스페이스로 구성됨])

== 2.2 LangGraph StateGraph 트레이스 트리

LangGraph 그래프는 _그래프가 루트 run_, 각 노드가 자식 run, 서브그래프는 네임스페이스가 붙은 손자 run으로 보입니다. 서브그래프의 노드 이름은 UI에서 `parent_node:child_node` 형식으로 표시됩니다.

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

여러 번의 invoke를 _하나의 대화_로 묶으려면 `metadata`에 세션 식별자를 넣습니다. LangSmith는 `thread_id`, `session_id`, `conversation_id` 중 하나라도 있으면 자동으로 Threads 뷰에 엮습니다.

#code-block(`````python
agent.invoke(
    {"messages": [{"role": "user", "content": "..."}]},
    config={"metadata": {"thread_id": "t_demo_0001", "user_id": "u_alice"}},
)
`````)

#figure(image("../../../assets/images/langsmith/02_tracing_agents/04_thread_view.png", width: 95%), caption: [Threads 탭 — 동일 `thread_id` 공유 run들이 대화 세션으로 묶임. First Input / Last Output / turns / tokens / cost / P50·P99 Latency 자동 집계])

== 2.5 런에 피드백 부착 — `client.create_feedback`

평가 점수·사용자 thumbs-up/down·내부 QA 리뷰 결과는 *Feedback*으로 run에 붙입니다.

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

UI 필터와 똑같은 표현식을 `client.list_runs(filter=...)`로 코드에서 쓸 수 있습니다. 회귀 테스트·야간 배치·대시보드 피딩에 유용합니다.

#code-block(`````python
runs = client.list_runs(
    project_name="langsmith-tracing-agents",
    filter='and(has(tags, "env:prod"), eq(run_type, "chain"))',
    limit=50,
)
`````)

#figure(image("../../../assets/images/langsmith/02_tracing_agents/06_add_filter_menu.png", width: 95%), caption: [Add filter 메뉴: Tag·Metadata가 별도 필드로 존재 — `tags contains env:dev` 같은 조건 쿼리 가능])

== 2.7 400일 보존 한계 → 데이터셋으로 영구화

SaaS LangSmith는 _ingestion 시점부터 400일_ 후 trace가 삭제됩니다. 평가 회귀에 쓰고 싶은 중요한 실행은 _Dataset으로 영구화_해야 합니다. 3장에서 자세히 다루지만, 여기선 패턴만 봅니다.

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
- 400일 보존 한계를 넘기려면 Dataset으로 이관
