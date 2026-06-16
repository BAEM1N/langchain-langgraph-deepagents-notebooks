// Auto-generated from 05_deep_research_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "딥 리서치 에이전트", subtitle: "`create_deep_agent` + TodoList + 서브에이전트 dispatch")

== 학습 목표
#learning-objectives([`create_deep_agent` 의 표준 구성(harness + 빌트인 도구 + 서브에이전트)으로 리서치 에이전트를 만든다], [빌트인 `write_todos` 로 _TodoList 기반 계획_을 세우고 `task` 도구로 서브에이전트에 dispatch 한다], [`think_tool` 로 전략적 반성(strategic reflection)을 구현한다], [5단계 워크플로(Plan → Delegate → Synthesize → Verify → Report)를 설계한다], [_AsyncSubAgent 5-tool 패턴_(`start_async_task` / `check_async_task` / `update_async_task` / `cancel_async_task` / `list_async_tasks`)을 안내한다], [v1 미들웨어(`SummarizationMiddleware`, `ModelCallLimitMiddleware`, `ModelFallbackMiddleware`)를 적용한다])

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
  [Deep Agents 0.6+],
  [_진입점_],
  [`create_deep_agent(model, tools, subagents, ...)` — harness 가 빌트인 도구·서브에이전트를 자동 부착],
  [_계획 도구_],
  [빌트인 `write_todos` — TodoList 로 다단계 계획 작성/업데이트],
  [_위임 도구_],
  [빌트인 `task` — 동기 서브에이전트 dispatch (Plan → Delegate)],
  [_반성 도구_],
  [커스텀 `think_tool` — 검색 후 전략적 반성],
  [_서브에이전트_],
  [researcher-1, researcher-2, fact-checker (3개)],
  [_워크플로_],
  [Plan → Delegate → Synthesize → Verify → Report],
  [_백엔드_],
  [`FilesystemBackend(root_dir=".", virtual_mode=True)`],
  [_스킬_],
  [`skills/deep-research/SKILL.md` — 리서치 방법론 + 인용 규칙],
  [_비동기 확장_],
  [`AsyncSubAgent` 5-tool 패턴 (`docs/deepagents/12-async-subagents.md`)],
)

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")

`````)

== 1단계: think_tool — 전략적 반성 도구

`think_tool`은 에이전트가 행동하기 전에 "생각"을 기록하는 도구입니다. 의사결정 품질을 높이는 데 씁니다:

- 검색 결과를 분석하고 다음 행동을 계획
- 수집된 정보의 충분성을 평가
- 서브에이전트에게 위임할 작업을 구체화


#code-block(`````python
from langchain.tools import tool

@tool
def think_tool(thought: str) -> str:
    """전략적 반성 — 현재 상황을 분석하고 다음 행동을 계획합니다."""
    return f"Reflection recorded: {thought}"

`````)

== 2단계: web_search 도구 (간소화)

실제 딥 리서치에서는 Tavily API를 사용하지만, 여기서는 학습 목적으로 간소화된 검색 도구를 정의합니다.


#code-block(`````python
@tool
def web_search(query: str) -> str:
    """웹 검색을 수행합니다 (시뮬레이션)."""
    results = {
        "AI agent": "AI 에이전트는 자율적으로 작업을 수행하는 시스템입니다. 2024년 이후 급성장 중입니다.",
        "LangGraph": "LangGraph는 상태 기반 워크플로 프레임워크입니다. Graph API와 Functional API를 지원합니다.",
        "Deep Agents": "Deep Agents는 올인원 에이전트 SDK입니다. 서브에이전트, 백엔드, 스킬을 지원합니다.",
    }
    for key, val in results.items():
        if key.lower() in query.lower():
            return val
    return f"'{query}'에 대한 검색 결과: 관련 정보를 찾을 수 없습니다."

`````)

== 3단계: 5단계 리서치 워크플로 프롬프트

`prompts.load_prompt()` 가 프롬프트를 로드합니다 (LangSmith Hub → Langfuse → 기본값).

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[단계],
  text(weight: "bold")[이름],
  text(weight: "bold")[사용 도구],
  text(weight: "bold")[설명],
  [1],
  [_Plan_],
  [`write_todos`],
  [TodoList 로 리서치 계획 작성],
  [2],
  [_Delegate_],
  [`task`],
  [서브에이전트에 dispatch (비교 분석 시 병렬 최대 3개)],
  [3],
  [_Synthesize_],
  [`think_tool`],
  [수집 정보를 통합·요약],
  [4],
  [_Verify_],
  [`task(fact-checker)`],
  [사실 검증],
  [5],
  [_Report_],
  [(LLM)],
  [최종 보고서 작성],
)

=== TodoList + dispatch 패턴

빌트인 `write_todos` 는 다단계 리서치에서 메인 에이전트의 _계획-기억-진행 상황_을 외부 상태로 분리합니다. 컨텍스트가 압축되어도 todos 가 살아남기 때문에, 긴 리서치 중에 어디까지 했는지 잃지 않습니다.

#code-block(`````python
write_todos([
  {"content": "LangGraph 핵심 개념 조사", "status": "in_progress"},
  {"content": "Deep Agents 핵심 개념 조사", "status": "pending"},
  {"content": "fact-checker 로 사실 검증", "status": "pending"},
  {"content": "최종 보고서 작성", "status": "pending"},
])

task(subagent_type="researcher-1", description="LangGraph 핵심 개념 조사 ...")
task(subagent_type="researcher-2", description="Deep Agents 핵심 개념 조사 ...")
`````)

`task` 는 동기 서브에이전트 dispatch 도구입니다. 메인 에이전트는 서브에이전트 결과를 받아 todos 상태를 갱신하고 다음 단계로 넘어갑니다.

#code-block(`````python
from prompts import RESEARCH_AGENT_PROMPT

print(RESEARCH_AGENT_PROMPT)
`````)
#output-block(`````
Prompt 'rag-agent-label:production' not found during refresh, evicting from cache.

Prompt 'sql-agent-label:production' not found during refresh, evicting from cache.

Prompt 'data-analysis-agent-label:production' not found during refresh, evicting from cache.

Prompt 'ml-agent-label:production' not found during refresh, evicting from cache.

Prompt 'deep-research-agent-label:production' not found during refresh, evicting from cache.

당신은 박사급 딥 리서치 에이전트입니다.

## 워크플로
1. **Plan**: write_todos로 리서치 계획을 세우세요
2. **Delegate**: 서브에이전트에게 조사를 위임하세요 (비교 분석 시 병렬)
3. **Synthesize**: 수집된 정보를 통합하세요
4. **Verify**: fact-checker에게 사실 검증을 요청하세요
5. **Report**: 최종 보고서를 작성하세요

## 규칙
- 검색 후 반드시 think_tool로 반성하세요
- 서브에이전트는 최대 3개까지 병렬 실행
- 인용은 [1], [2] 형식으로, 출처 섹션을 포함하세요
- 단순 주제는 서브에이전트 1개, 비교 분석은 2-3개 사용하세요
`````)

== 4단계: 서브에이전트 3개 정의

딥 리서치 에이전트는 3개의 전문 서브에이전트를 씁니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[서브에이전트],
  text(weight: "bold")[역할],
  text(weight: "bold")[도구],
  [`researcher-1`],
  [주제 조사 담당],
  [web_search, think_tool],
  [`researcher-2`],
  [비교/보완 조사],
  [web_search, think_tool],
  [`fact-checker`],
  [사실 검증 담당],
  [web_search],
)


#code-block(`````python
researcher_1 = {
    "name": "researcher-1",
    "description": "주제에 대한 심층 조사를 수행합니다",
    "system_prompt": "당신은 리서치 전문가입니다. 주제를 깊이 조사하고 핵심 정보를 요약하세요. 검색 후 think_tool로 반성하세요.",
    "tools": [web_search, think_tool],
}

`````)

#code-block(`````python
researcher_2 = {
    "name": "researcher-2",
    "description": "보완적 관점에서 추가 조사를 수행합니다",
    "system_prompt": "당신은 보완 리서처입니다. 다른 관점에서 추가 정보를 수집하세요. 검색 후 think_tool로 반성하세요.",
    "tools": [web_search, think_tool],
}

`````)

#code-block(`````python
fact_checker = {
    "name": "fact-checker",
    "description": "수집된 정보의 사실 여부를 검증합니다",
    "system_prompt": "당신은 팩트체커입니다. 제공된 정보의 정확성을 검증하고, 오류가 있으면 지적하세요.",
    "tools": [web_search],
}

`````)

== 5단계: 딥 리서치 에이전트 생성 (v1 미들웨어)

모든 도구와 서브에이전트를 조합하여 최종 에이전트를 생성합니다. v1 미들웨어로 안정성과 신뢰성을 높입니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[역할],
)

로 체크포인팅을 활성화하여 중단된 리서치를 재개할 수 있습니다.

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import (
    SummarizationMiddleware,
    ModelCallLimitMiddleware,
    ModelFallbackMiddleware,
)

research_agent = create_deep_agent(
    model=model,
    tools=[web_search, think_tool],
    subagents=[researcher_1, researcher_2, fact_checker],
    system_prompt=RESEARCH_AGENT_PROMPT,
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    middleware=[
        SummarizationMiddleware(model=model, trigger=("messages", 15)),
        ModelCallLimitMiddleware(run_limit=30),
        ModelFallbackMiddleware("openai:gpt-5.4-mini"),
    ],
)
`````)

== 6단계: 리서치 실행

에이전트에게 리서치 주제를 부여하면 5단계 워크플로를 자동으로 수행합니다.


== 7단계: 스트리밍 — 네임스페이스 추적

`stream(subgraphs=True)`로 메인 에이전트와 서브에이전트의 실행 과정을 네임스페이스별로 추적합니다. 어떤 서브에이전트가 언제 호출되는지 실시간으로 확인할 수 있습니다.


== 서브에이전트 설계 모범 사례

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[원칙],
  text(weight: "bold")[설명],
  [_명확한 설명_],
  [`description`을 구체적으로 작성 — 메인 에이전트가 위임 대상을 선택하는 기준],
  [_전문 프롬프트_],
  [`system_prompt`에 출력 형식, 제약, 워크플로 포함],
  [_최소 도구_],
  [필요한 도구만 할당 — 불필요한 도구는 혼란 유발],
  [_간결한 결과_],
  [서브에이전트가 요약을 반환하도록 지시 — 원시 데이터 전달 금지],
)


== 확장: AsyncSubAgent 5-tool 패턴

본 노트북의 `task` 는 _동기_ dispatch 입니다. 서브에이전트가 끝날 때까지 메인 에이전트가 블록되며 사용자도 새 지시를 줄 수 없습니다. _장시간 리서치 + 도중 방향 전환 + 병렬 fan-out_ 이 필요하면 Deep Agents 0.5+ 의 `AsyncSubAgent` 로 전환하면 됩니다. `AsyncSubAgentMiddleware` 가 슈퍼바이저에게 다음 5개 도구를 주입합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[역할],
  [`start_async_task`],
  [서브에이전트 백그라운드 기동, task id 즉시 반환 (non-blocking)],
  [`check_async_task`],
  [상태 조회, 완료 시 최종 출력 추출],
  [`update_async_task`],
  [같은 thread 에 새 지시 주입 (mid-flight steering)],
  [`cancel_async_task`],
  [실행 취소, 태스크를 `cancelled` 로 마킹],
  [`list_async_tasks`],
  [추적 중인 모든 태스크의 live status 일괄 조회],
)

#code-block(`````python
from deepagents import AsyncSubAgent, create_deep_agent

async_subagents = [
    AsyncSubAgent(
        name="researcher",
        description="장시간 정보 수집과 종합이 필요한 리서치 작업",
        graph_id="researcher",
    ),
]

agent = create_deep_agent(
    model=model,
    subagents=async_subagents,
    # AsyncSubAgentMiddleware 가 자동 부착됨
)
`````)

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[축],
  text(weight: "bold")[`task` (Sync)],
  text(weight: "bold")[AsyncSubAgent (Async)],
  [실행],
  [슈퍼바이저 블록],
  [즉시 task id 반환, 슈퍼바이저 계속],
  [결과 회수],
  [자동 반환],
  [`check_async_task` 폴링],
  [Mid-task 지시],
  [불가],
  [`update_async_task` 로 가능],
  [취소],
  [불가],
  [`cancel_async_task`],
  [인프라 요구],
  [없음],
  [Agent Protocol 서버 (LangSmith Deployments / `langgraph dev`)],
  [적합 작업],
  [수초~수십초],
  [분~시간 단위, 중간 개입],
)

상세 패턴(ASGI vs HTTP transport, mid-flight steering, `async_tasks` state channel)은 `docs/deepagents/12-async-subagents.md` 를 참고하세요.

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_진입점_],
  [`create_deep_agent(model, tools, subagents, ...)` — harness 가 빌트인 도구·서브에이전트 자동 부착],
  [_TodoList_],
  [빌트인 `write_todos` — 다단계 리서치 계획 외부 상태로 분리],
  [_dispatch_],
  [빌트인 `task` — 동기 서브에이전트 호출 (Plan → Delegate)],
  [_think_tool_],
  [전략적 반성 — 검색 후 분석, 다음 행동 계획],
  [_서브에이전트_],
  [researcher-1, researcher-2, fact-checker 병렬 실행],
  [_워크플로_],
  [Plan → Delegate → Synthesize → Verify → Report],
  [_컨텍스트 관리_],
  [서브에이전트 결과만 메인에 전달 — 중간 과정 격리],
  [_비동기 확장_],
  [`AsyncSubAgent` 5-tool: start / check / update / cancel / list],
)


#references-box[
- `docs/deepagents/examples/02-deep-research.md`
- `docs/deepagents/07-subagents.md` — 동기 서브에이전트
- `docs/deepagents/12-async-subagents.md` — AsyncSubAgent 5-tool 패턴
- `docs/deepagents/06-backends.md`
_이전 단계:_ ← #link("./04_ml_agent.ipynb")[04_ml_agent.ipynb]: 머신러닝 에이전트
]
#chapter-end()
