// Auto-generated from 05_deep_research_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "딥 리서치 에이전트", subtitle: "병렬 서브에이전트와 5단계 워크플로")

Part 6의 마지막 장이자 캡스톤 프로젝트입니다. 앞선 네 장에서 RAG, SQL, 데이터 분석, 머신러닝 에이전트를 각각 구축하며 학습한 패턴들 -- 도구 정의, 백엔드 설정, 미들웨어 적용, 멀티턴 대화, 스트리밍 -- 을 모두 종합하여 가장 복잡한 형태의 에이전트를 만들어 봅니다.

딥 리서치 에이전트는 복잡한 조사 과제를 Plan, Delegate, Synthesize, Verify, Report의 5단계로 분해하여 수행하는 고급 멀티에이전트 시스템입니다. 병렬 서브에이전트 3개(researcher-1, researcher-2, fact-checker)가 동시에 정보를 수집하고 교차 검증하며, `think_tool`을 통한 전략적 반성으로 분석 품질을 높입니다. Part 5 ch02에서 학습한 서브에이전트 패턴과 ch01의 미들웨어 시스템이 실전에서 어떻게 결합되는지 확인할 수 있습니다.

#learning-header()
#learning-objectives([병렬 서브에이전트 3개(researcher-1, researcher-2, fact-checker)를 구성한다], [`think_tool`로 전략적 반성(strategic reflection)을 구현한다], [5단계 워크플로(Plan → Delegate → Synthesize → Verify → Report)를 설계한다], [v1 미들웨어(SummarizationMiddleware, ModelCallLimitMiddleware, ModelFallbackMiddleware)를 적용한다])

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
  [Deep Agents],
  [_핵심 컴포넌트_],
  [병렬 서브에이전트 3개, think_tool],
  [_워크플로_],
  [5단계: Plan → Delegate → Synthesize → Verify → Report],
  [_백엔드_],
  [`FilesystemBackend(root_dir=".", virtual_mode=True)`],
  [_빌트인 도구_],
  [`write_todos` (계획), `task` (서브에이전트 호출)],
  [_스킬_],
  [`skills/deep-research/SKILL.md` — 리서치 방법론 + 인용 규칙],
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

딥 리서치 에이전트를 구축하기 위해 먼저 개별 구성 요소를 정의하고, 이를 순서대로 조립해 나갑니다. 첫 번째는 에이전트의 의사결정 품질을 높이는 반성 도구입니다.

== 1단계: think_tool -- 전략적 반성 도구

딥 리서치 에이전트의 첫 번째 구성 요소는 _반성 도구_입니다.

#tip-box[`think_tool`은 Anthropic이 공개한 "tool use를 통한 확장된 사고(extended thinking)" 패턴에서 영감을 받았습니다. 에이전트가 도구 호출 결과를 받은 직후 `think_tool`을 호출하면, 결과를 분석하고 다음 행동을 계획하는 _명시적 사고 단계_가 강제됩니다. 이 패턴은 특히 복잡한 리서치에서 에이전트가 성급하게 결론을 내리는 것을 방지하여 답변 품질을 크게 향상시킵니다.] `think_tool`은 에이전트가 행동하기 전에 "생각"을 기록하는 도구입니다. 일반 에이전트는 검색 결과를 받자마자 바로 다음 행동으로 넘어가지만, `think_tool`이 있으면 결과를 분석하고 다음 행동을 계획하는 중간 단계를 강제합니다. 이 패턴은 에이전트의 의사결정 품질을 높입니다:

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

반성 도구가 준비되었으니, 정보 수집 도구를 정의합니다. 실제 딥 리서치에서는 Tavily API를 사용하지만, 여기서는 학습 목적으로 간소화된 검색 도구를 정의합니다. 프로덕션에서는 이 시뮬레이션을 실제 웹 검색 API로 교체하면 됩니다.

#tip-box[Tavily, Brave Search, SerpAPI 등의 검색 API를 사용하면 실제 웹 검색 결과를 받을 수 있습니다. `@tool` 데코레이터의 인터페이스만 유지하면 에이전트 코드를 수정할 필요가 없습니다.]


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

도구가 준비되었으니, 에이전트의 행동을 구조화하는 프롬프트를 정의합니다. 딥 리서치의 핵심은 자유롭게 검색하는 것이 아니라, 체계적인 5단계 워크플로를 따르는 것입니다. 프롬프트 로더가 프롬프트를 로드합니다 (LangSmith Hub -> Langfuse -> 기본값).

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[단계],
  text(weight: "bold")[이름],
  text(weight: "bold")[설명],
  [1],
  [_Plan_],
  [로 리서치 계획 작성],
  [2],
  [_Delegate_],
  [서브에이전트에게 병렬 조사 위임 (최대 3개 동시)],
  [3],
  [_Synthesize_],
  [수집된 정보를 통합],
  [4],
  [_Verify_],
  [fact-checker가 사실 검증],
  [5],
  [_Report_],
  [최종 보고서 작성],
)

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

프롬프트가 워크플로를 정의했으니, 이제 Delegate 단계의 핵심인 서브에이전트를 정의합니다. 각 서브에이전트는 독립된 컨텍스트와 전문 역할을 가지며, 메인 에이전트의 `task` 빌트인 도구를 통해 호출됩니다.

== 4단계: 서브에이전트 3개 정의

5단계 워크플로에서 Delegate 단계의 핵심은 병렬 서브에이전트입니다. Part 5 ch02에서 학습한 것처럼, 서브에이전트는 각각 독립된 컨텍스트를 가지며 메인 에이전트의 `task` 빌트인 도구로 호출됩니다. 딥 리서치 에이전트는 3개의 전문 서브에이전트를 사용합니다:

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

도구, 서브에이전트, 프롬프트가 모두 준비되었으니, `create_deep_agent`로 최종 에이전트를 조립합니다. 이 단계에서 v1 미들웨어가 특히 중요합니다 -- 딥 리서치는 서브에이전트가 각각 독립적으로 LLM을 호출하므로 토큰 소비가 급격히 증가하고, 대화 길이도 매우 길어질 수 있기 때문입니다. 딥 리서치는 대화가 매우 길어질 수 있으므로 `SummarizationMiddleware`가 특히 중요합니다. `ModelFallbackMiddleware`는 주 모델(gpt-4.1)이 Rate Limit에 걸릴 때 자동으로 대체 모델(gpt-4.1-mini)로 전환하여 리서치가 중단되지 않도록 합니다. 모든 도구와 서브에이전트를 조합하여 최종 에이전트를 생성합니다. v1 미들웨어로 안정성과 신뢰성을 강화합니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[역할],
)

`InMemorySaver`로 체크포인팅을 활성화하여 중단된 리서치를 재개할 수 있습니다.

#warning-box[딥 리서치는 서브에이전트가 각각 여러 번 모델을 호출하므로 토큰 소비가 급격히 증가합니다. `ModelCallLimitMiddleware(run_limit=30)`으로 전체 호출 횟수를 제한하고, `SummarizationMiddleware`로 컨텍스트 윈도우 초과를 방지하세요.]

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
        ModelFallbackMiddleware("gpt-4.1-mini"),
    ],
)
`````)

== 6단계: 리서치 실행

에이전트가 완성되었습니다. 에이전트에게 리서치 주제를 부여하면 5단계 워크플로를 자동으로 수행합니다. 주제의 복잡도에 따라 에이전트의 행동이 달라지는 것을 관찰하세요 -- 단순 주제는 researcher-1만 활용하고, "A와 B를 비교 분석해"와 같은 비교 질문에는 두 researcher를 병렬로 동원합니다.

#warning-box[딥 리서치 에이전트는 서브에이전트 3개가 각각 여러 번 검색과 반성을 수행하므로, _단일 실행에 수십 번의 LLM 호출_이 발생할 수 있습니다. 비용 관리를 위해 (1) `ModelCallLimitMiddleware`로 전체 호출 횟수를 제한하고, (2) 서브에이전트의 시스템 프롬프트에 "최대 3회 검색 후 요약"이라는 제한을 명시하며, (3) `ModelFallbackMiddleware`로 Rate Limit 시 저비용 모델로 자동 전환하는 전략을 병행하세요.] 에이전트는 먼저 `write_todos`로 계획을 세운 뒤, 주제의 복잡도에 따라 서브에이전트 1~3개를 동시에 호출합니다. 단순 주제는 researcher-1만, 비교 분석은 researcher-1과 researcher-2를, 사실 검증이 필요하면 fact-checker까지 병렬로 동원합니다.


리서치 실행의 전체 과정을 실시간으로 관찰하려면 스트리밍이 필수적입니다. 특히 멀티에이전트 시스템에서는 어떤 서브에이전트가 현재 작업 중인지, 각각 어떤 검색을 수행하고 있는지 추적하는 것이 디버깅과 품질 관리에 핵심입니다.

== 7단계: 스트리밍 -- 네임스페이스 추적

리서치가 진행되는 동안 `stream(subgraphs=True)`로 메인 에이전트와 서브에이전트의 실행 과정을 네임스페이스별로 추적합니다. 네임스페이스 시스템은 중첩된 에이전트 구조에서 이벤트의 _출처_를 정확히 식별하는 메커니즘입니다. 예를 들어, `("main", "researcher-1")`은 메인 에이전트가 호출한 researcher-1 서브에이전트에서 발생한 이벤트를 의미합니다. 어떤 서브에이전트가 언제 호출되는지 실시간으로 확인할 수 있습니다. 네임스페이스는 `("main",)`, `("main", "researcher-1")` 형태로 표시되어, 현재 어떤 에이전트가 작업 중인지 명확히 구분됩니다.


스트리밍으로 에이전트의 실행 과정을 관찰하면서 서브에이전트 설계의 중요성을 체감했을 것입니다. 잘 설계된 서브에이전트는 정확한 결과를 빠르게 반환하지만, 설계가 부실하면 불필요한 도구 호출이 반복되거나 관련 없는 정보를 수집합니다. 다음은 실전에서 얻은 모범 사례입니다.

== 서브에이전트 설계 모범 사례

딥 리서치 에이전트를 구축하며 얻은 교훈을 정리합니다.

#tip-box[서브에이전트의 `description`은 메인 에이전트가 위임 대상을 선택하는 _유일한 기준_입니다. "주제에 대한 심층 조사를 수행합니다"보다 "기술 문서와 공식 소스를 기반으로 특정 기술/프레임워크의 아키텍처, 장단점, 사용 사례를 심층 분석합니다"처럼 구체적으로 작성하면 메인 에이전트의 위임 정확도가 크게 향상됩니다.] 서브에이전트 기반 시스템에서 가장 흔한 실수는 서브에이전트에게 너무 많은 도구를 할당하거나, 설명(description)이 모호하여 메인 에이전트가 적절한 서브에이전트를 선택하지 못하는 것입니다.

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


#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_think_tool_],
  [전략적 반성 — 검색 후 분석, 다음 행동 계획],
  [_서브에이전트_],
  [researcher-1, researcher-2, fact-checker 병렬 실행],
  [_워크플로_],
  [Plan → Delegate → Synthesize → Verify → Report],
  [_컨텍스트 관리_],
  [서브에이전트 결과만 메인에 전달 — 중간 과정 격리],
)


이 장을 마지막으로 Part 6의 실전 프로젝트가 모두 완성되었습니다. RAG 에이전트의 벡터 검색, SQL 에이전트의 데이터베이스 질의, 데이터 분석 에이전트의 코드 실행, ML 에이전트의 모델 학습, 그리고 딥 리서치 에이전트의 병렬 조사까지 -- 에이전트의 활용 범위가 단일 도구 호출에서 복잡한 멀티에이전트 협업으로 점진적으로 확장되는 과정을 경험했습니다. 이 패턴들을 조합하여 자신만의 에이전트를 설계해 보세요.

#references-box[
- `docs/deepagents/examples/02-deep-research.md`
- `docs/deepagents/07-subagents.md`
- `docs/deepagents/06-backends.md`
_이전 단계:_ ← #link("./04_ml_agent.ipynb")[04_ml_agent.ipynb]: 머신러닝 에이전트
]
#chapter-end()
