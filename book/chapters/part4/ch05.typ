// Auto-generated from 05_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "서브에이전트와 태스크 위임")

== 학습 목표
#learning-objectives([서브에이전트가 해결하는 문제(컨텍스트 블로트)를 이해한다], [`SubAgent` dict와 `CompiledSubAgent`로 서브에이전트를 정의한다], [빌트인 general-purpose 서브에이전트를 이해하고 오버라이드한다], [컨텍스트 전파와 네임스페이스 키를 활용한다], [멀티 서브에이전트 파이프라인 패턴을 구현한다])

#code-block(`````python
# 환경 설정
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY가 설정되지 않았습니다!"
print("환경 설정 완료")
`````)
#output-block(`````
환경 설정 완료
`````)

#code-block(`````python
# Observability 설정 (선택) - LangSmith 또는 Langfuse
# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    project = os.environ.get("LANGSMITH_PROJECT", "default")
    print(f"LangSmith tracing ON — project: {project}")

# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")
# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)
#output-block(`````
Langfuse tracing ON — https://lf.ddok.ai
`````)

#code-block(`````python
# OpenAI gpt-5.4 모델 설정 (Deep Agents 기본은 anthropic:claude-sonnet-4-6)
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")

print(f"모델 설정 완료: {model.model_name}")
`````)
#output-block(`````
모델 설정 완료: gpt-5.4
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 서브에이전트가 필요한 이유

=== 컨텍스트 블로트(Context Bloat) 문제

에이전트가 도구를 사용할 때마다 _입력/출력이 컨텍스트 윈도우에 쌓입니다_:
- 웹 검색 결과 (수천 토큰)
- 파일 내용 읽기 (수백~수천 줄)
- 데이터베이스 쿼리 결과

중간 결과들이 메인 에이전트의 컨텍스트를 가득 채우면, 정작 중요한 정보를 놓칠 수 있습니다.

=== 서브에이전트의 해결 방식

#image("../../assets/images/subagent_context.png")

메인 에이전트는 _500 토큰짜리 요약만_ 받으므로 컨텍스트가 깔끔하게 유지됩니다.

=== 서브에이전트 사용 기준

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[상황],
  text(weight: "bold")[서브에이전트 사용],
  [다단계 작업으로 중간 결과가 많음],
  [✅ 사용],
  [전문 지식/도구가 필요한 도메인],
  [✅ 사용],
  [다른 모델이 더 적합한 작업],
  [✅ 사용],
  [단순하고 한 번에 끝나는 작업],
  [❌ 불필요],
  [중간 결과가 메인 에이전트에 필요],
  [❌ 불필요],
)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. SubAgent 정의하기 (dict 기반)

`SubAgent`는 딕셔너리 형태로 정의합니다.
`SubAgentMiddleware`가 자동으로 `task()` 도구를 메인 에이전트에 주입해서, 메인이 서브에이전트 이름으로 작업을 위임합니다.
동기 서브에이전트가 존재하면 `SubAgentMiddleware`는 필수 미들웨어로 자동 부착되며 `excluded_middleware` 로 제거할 수 없습니다.

=== 필수 필드
#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필드],
  text(weight: "bold")[타입],
  text(weight: "bold")[설명],
  [`name`],
  [`str`],
  [고유 식별자],
  [`description`],
  [`str`],
  [역할 설명 (메인 에이전트가 호출 판단에 사용)],
  [`system_prompt`],
  [`str`],
  [서브에이전트 지침 (부모로부터 상속하지 않음)],
  [`tools`],
  [`list`],
  [서브에이전트가 쓸 도구 (지정 시 부모 도구를 덮어씀)],
)

=== 선택 필드
#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필드],
  text(weight: "bold")[타입],
  text(weight: "bold")[설명],
  [`model`],
  [`str` \\],
  [`BaseChatModel`],
  [모델 오버라이드 (`"provider:model"` 또는 chat model 객체)],
  [`middleware`],
  [`list`],
  [추가 미들웨어 (상속되지 않음)],
  [`interrupt_on`],
  [`dict[str, bool]`],
  [HITL 설정 (메인 설정을 오버라이드)],
  [`skills`],
  [`list[str]`],
  [격리된 스킬 디렉토리],
  [`response_format`],
  [`ResponseFormat`],
  [구조화 출력 (deepagents ≥ 0.5.3)],
  [`permissions`],
  [`list[FilesystemPermission]`],
  [부모 규칙을 완전히 대체],
)

=== Dispatch + 계획 패턴

메인 에이전트는 `TodoList`(write_todos)로 요청을 순서 있는 작업으로 분해한 뒤 각 항목을 `task()` 호출로 위임합니다. 스트리밍 중에는 `lc_agent_name` 메타데이터로 어느 서브에이전트의 출력인지 식별할 수 있습니다.

#code-block(`````python
from typing import Literal
from tavily import TavilyClient
from deepagents import create_deep_agent

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])


def internet_search(
    query: str,
    max_results: int = 5,
    topic: Literal["general", "news", "finance"] = "general",
    include_raw_content: bool = False,
) -> dict:
    """인터넷에서 정보를 검색합니다.

    Args:
        query: 검색할 질문 또는 키워드
        max_results: 반환할 최대 결과 수
        topic: 검색 주제 카테고리
        include_raw_content: 원본 콘텐츠 포함 여부
    """
    return tavily_client.search(
        query,
        max_results=max_results,
        include_raw_content=include_raw_content,
        topic=topic,
    )


# 리서치 서브에이전트 정의
# `model`을 명시하면 메인과 다른 모델을 쓸 수도 있다 — 예: 가벼운 작업은 gpt-5.4-mini
research_subagent = {
    "name": "researcher",
    "description": "인터넷에서 주제를 심층 조사하고 핵심 정보를 요약합니다. 리서치가 필요한 질문에 사용하세요.",
    "system_prompt": """당신은 전문 리서처입니다.
인터넷 검색을 통해 정확한 정보를 수집하고, 핵심만 추출하여 간결하게 요약합니다.
결과는 항상 한국어로 작성하며, 출처를 함께 표기합니다.
최종 결과는 500단어 이내로 요약하세요.""",
    "tools": [internet_search],
}

print(f"서브에이전트 정의 완료: {research_subagent['name']}")
print(f"설명: {research_subagent['description'][:50]}...")
`````)
#output-block(`````
서브에이전트 정의 완료: researcher
설명: 인터넷에서 주제를 심층 조사하고 핵심 정보를 요약합니다. 리서치가 필요한 질문에 사용하세요...
`````)

#code-block(`````python
# 서브에이전트를 포함하는 메인 에이전트 생성
main_agent = create_deep_agent(
    model=model,
    system_prompt="""당신은 프로젝트 매니저입니다.
사용자의 요청을 분석하고, 필요하면 전문 서브에이전트에게 작업을 위임합니다.
서브에이전트의 결과를 종합하여 최종 답변을 작성합니다.
한국어로 응답하세요.""",
    subagents=[research_subagent],
)

print("메인 에이전트 생성 완료 (서브에이전트: researcher)")
`````)
#output-block(`````
메인 에이전트 생성 완료 (서브에이전트: researcher)
`````)

#code-block(`````python
# 서브에이전트를 활용하는 질문
result = main_agent.invoke(
    {"messages": [{"role": "user", "content": "2024년 AI 에이전트 프레임워크 트렌드를 조사해 주세요."}]},
    config=lf_config,
)

print(result["messages"][-1].content)
`````)
#output-block(`````
Failed to export span batch due to timeout, max retries or shutdown.

Failed to export span batch due to timeout, max retries or shutdown.

2024년 AI 에이전트 프레임워크 트렌드 핵심 정리

■ 대표 프레임워크 및 특징
- LangChain, LangGraph, Crew AI: 오픈소스, 모듈식, 멀티에이전트 지원, Tool 연동 활발
- AutoGen, Semantic Kernel(마이크로소프트): 워크플로우 자동화, 기업·Azure 연계
- PromptFlow, Phidata, Multi-agent Orchestrator(아마존): 시각적 구축, 빠른 배포, 클라우드 지원
- OpenAI Swarm, ChatDev: 실험적 멀티에이전트, 코드 자동화 등 혁신 기능

■ 주요 트렌드 및 변화
- 생성형 AI(LLM)와의 결합이 기본, 실제 실행 기반 솔루션 주목
- 멀티모달 에이전트: 텍스트·음성·이미지 등 다양한 입력 지원, 실무 분야로 빠르게 확산
- RAG(검색결합생성): 외부 정보 연동해 신뢰도·정확도 강화
- 도메인·엔터프라이즈 특화 증가(금융·의료 등), 자체 구축 및 맞춤형 개발 확산
- 멀티에이전트 시스템(MAS) 기반, 역할 분업 및 복잡 업무 자동화 강화

■ 도입 및 커뮤니티 동향
- 글로벌 대기업(Uber, Klarna 등) 직접 구축/운영
- 오픈소스 프레임워크 기반 개발자 커뮤니티 및 협업 확대
- 중소기업/개인 대상 No-code·Low-code 솔루션 부상

■ 발전 방향
- 도메인 특화·미세조정 쉬운 Framework 발전
- 자율/반자율 Agent 지향: 목표 설정~실행까지 자동화
- Human-in-the-loop, 신뢰성·윤리·보안 등 실무·규제 요구 반영
- 비용 및 진입장벽 하락, 다양한 산업에서 활용 가시화

... (truncated)
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. CompiledSubAgent — 커스텀 LangGraph 그래프 연결

미리 컴파일된 LangGraph 그래프를 서브에이전트로 쓸 수 있습니다.
조건 분기, 반복 같은 복잡한 워크플로가 필요한 경우에 유용합니다.

#code-block(`````python
from deepagents import CompiledSubAgent

# 별도의 에이전트를 CompiledSubAgent로 래핑하는 예시
# 실제로는 create_deep_agent()로 만든 그래프도 사용 가능
custom_graph = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="당신은 데이터 분석 전문가입니다. 데이터를 수집하고 통계적으로 분석하여 인사이트를 도출합니다.",
)

# CompiledSubAgent로 래핑
data_analyst_subagent: CompiledSubAgent = {
    "name": "data-analyst",
    "description": "데이터를 수집하고 분석하여 통계적 인사이트를 제공합니다.",
    "runnable": custom_graph,
}

print(f"CompiledSubAgent 정의 완료: {data_analyst_subagent['name']}")
`````)
#output-block(`````
CompiledSubAgent 정의 완료: data-analyst
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. General-Purpose 서브에이전트

Deep Agents는 별도로 정의하지 않아도 _빌트인 general-purpose 서브에이전트_를 자동 제공합니다.

=== 기본 동작
- 메인 에이전트와 _같은 시스템 프롬프트_ 사용
- 메인 에이전트와 _같은 도구_ 접근 (filesystem 도구 포함)
- 메인 에이전트와 _같은 모델_ 사용 (이 노트북에서는 OpenAI `gpt-5.4`, Deep Agents 표준 기본은 `anthropic:claude-sonnet-4-6`)
- 메인 에이전트의 _스킬을 자동 상속_ (커스텀 서브에이전트와 다른 점)

=== 비활성화 또는 오버라이드
- 완전 비활성화: 하네스 프로파일에서 `GeneralPurposeSubagentProfile(enabled=False)`
- 대체: `name="general-purpose"` 로 커스텀 서브에이전트 정의

#code-block(`````python
# general-purpose 서브에이전트 오버라이드 예시
custom_gp_agent = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="당신은 멀티태스크 코디네이터입니다.",
    subagents=[
        research_subagent,
        {
            # 이름을 "general-purpose"로 설정하면 빌트인을 오버라이드
            "name": "general-purpose",
            "description": "범용 에이전트로, 리서치 외의 일반적인 멀티스텝 작업을 처리합니다.",
            "system_prompt": "당신은 범용 어시스턴트입니다. 주어진 작업을 단계별로 처리하세요.",
            "tools": [internet_search],
        },
    ],
)

print("general-purpose 서브에이전트를 오버라이드한 에이전트 생성 완료")
`````)
#output-block(`````
general-purpose 서브에이전트를 오버라이드한 에이전트 생성 완료
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 컨텍스트 전파

런타임 컨텍스트는 자동으로 모든 서브에이전트에 전파됩니다.
`context_schema`로 구조를 정의하고, `config`의 `context` 키로 값을 전달합니다.

#code-block(`````python
from langchain_core.messages import HumanMessage
from langgraph.checkpoint.memory import MemorySaver

# 컨텍스트 스키마를 가진 에이전트
context_agent = create_deep_agent(
    model=model,
    system_prompt="사용자 맞춤 어시스턴트입니다. 한국어로 응답하세요.",
    subagents=[research_subagent],
    context_schema={"user_id": str, "language": str},
    checkpointer=MemorySaver(),
)

# 컨텍스트와 함께 실행
result = context_agent.invoke(
    {"messages": [HumanMessage(content="내 최근 관심사에 맞는 뉴스를 찾아주세요.")]},
    config={**{
        "configurable": {"thread_id": "ctx-test"},
        "context": {
            "user_id": "user-123",
            "language": "ko",
        },
    }, **lf_config},
)

print(result["messages"][-1].content)
`````)
#output-block(`````
최근 관심사에 대해 알려주시면, 그에 맞는 뉴스를 찾아드릴 수 있습니다. 어떤 주제, 분야, 키워드에 관심이 있으신가요? 관심 분야(예: 경제, IT, 스포츠 등)나 구체적인 키워드, 혹은 최근에 흥미롭게 본 기사 스타일을 알려주시면 더 맞춤 추천이 가능합니다.
`````)

=== 네임스페이스 키로 서브에이전트별 컨텍스트 전달

`"서브에이전트이름:키"` 형식을 쓰면, 특정 서브에이전트에만 전달되는 설정을 추가할 수 있습니다.

#code-block(`````python
config = {
    "context": {
        "user_id": "user-123",             # 모든 에이전트에 전파
        "researcher:max_depth": 3,          # researcher에만 전달
        "data-analyst:strict_mode": True,   # data-analyst에만 전달
    }
}
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. 멀티 서브에이전트 파이프라인

여러 서브에이전트를 조합하여 _수집 → 분석 → 작성_ 파이프라인을 구성할 수 있습니다.

#image("../../assets/images/subagent_pipeline.png")

#code-block(`````python
# 멀티 서브에이전트 파이프라인
pipeline_agent = create_deep_agent(
    model=model,
    system_prompt="""당신은 프로젝트 코디네이터입니다.
사용자의 요청을 분석하고, 적절한 서브에이전트에게 순서대로 작업을 위임합니다:
1. 먼저 data-collector로 정보를 수집합니다.
2. 수집된 정보를 data-analyzer에게 전달하여 분석합니다.
3. 분석 결과를 report-writer에게 전달하여 보고서를 작성합니다.
최종 보고서를 사용자에게 전달합니다. 한국어로 응답하세요.""",
    subagents=[
        {
            "name": "data-collector",
            "description": "다양한 소스에서 원시 데이터와 정보를 수집합니다.",
            "system_prompt": """당신은 데이터 수집 전문가입니다.
주어진 주제에 대해 인터넷 검색을 수행하고, 관련 데이터를 최대한 수집합니다.
수집한 데이터를 구조화하여 반환하세요.""",
            "tools": [internet_search],
        },
        {
            "name": "data-analyzer",
            "description": "수집된 데이터를 분석하여 핵심 인사이트를 추출합니다.",
            "system_prompt": """당신은 데이터 분석 전문가입니다.
제공된 데이터에서 패턴, 트렌드, 핵심 인사이트를 추출합니다.
분석 결과를 불릿 포인트로 정리하세요.""",
            "tools": [],
        },
        {
            "name": "report-writer",
            "description": "분석 결과를 바탕으로 전문적인 보고서를 작성합니다.",
            "system_prompt": """당신은 테크니컬 라이터입니다.
분석 결과를 바탕으로 명확하고 읽기 쉬운 보고서를 작성합니다.
보고서는 다음 구조를 따릅니다: 개요 → 핵심 발견 → 결론""",
            "tools": [],
        },
    ],
)

print("멀티 서브에이전트 파이프라인 에이전트 생성 완료")
`````)
#output-block(`````
멀티 서브에이전트 파이프라인 에이전트 생성 완료
`````)

#code-block(`````python
# 파이프라인 실행
result = pipeline_agent.invoke(
    {"messages": [{"role": "user", "content": "2025년 생성형 AI 시장 동향에 대한 간단한 보고서를 작성해 주세요."}]},
    config=lf_config,
)

print(result["messages"][-1].content)
`````)
#output-block(`````
Failed to export span batch due to timeout, max retries or shutdown.

Failed to export span batch due to timeout, max retries or shutdown.

Failed to export span batch due to timeout, max retries or shutdown.

Failed to export span batch due to timeout, max retries or shutdown.

Failed to export span batch due to timeout, max retries or shutdown.

2025년 생성형 AI 시장 동향에 대한 간단 보고서

---

**1. 시장 규모 및 성장 동향**
- 2025년 글로벌 생성형 AI 시장은 약 670억 달러(한화 약 90조 원) 규모로 성장, 연평균 50%가 넘는 고속 성장세 예상
- 국내 시장도 2조 원 이상, 연 60% 가까운 성장률 전망
- 미국, 중국, 한국 등 주요국 Big Tech 기업과 혁신 스타트업 중심의 경쟁 심화

**2. 주요 트렌드**
- 초거대 AI(LLM)와 멀티모달 AI(텍스트·음성·이미지 복합) 기술의 실용화
- 오픈소스 및 맞춤형(경량) 생성형 AI 모델 확산
- 자동화, 창작, 고객상담, R&D, 제조 등 폭넓은 산업에서 도입 확대
- AI 윤리·보안 및 데이터 품질 관리 중요성 부상

**3. 산업별 응용 사례**
| 산업     | 활용 예시                       |
|----------|-------------------------------|
| 금융     | 자동 보고서·신용평가·챗봇      |
| 제조     | R&D 문서생성·설계자동화        |
... (truncated)
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. 베스트 프랙티스

=== 1. 명확한 description 작성
메인 에이전트는 `description`을 보고 어떤 서브에이전트를 호출할지 결정합니다.
서브에이전트의 역할과 사용 시기를 명확하게 기술하세요.

=== 2. 최소 도구 원칙
서브에이전트에는 _필요한 도구만_ 제공하세요. 불필요한 도구는 컨텍스트를 낭비하고 오동작을 유발합니다.

=== 3. 간결한 결과 반환
서브에이전트의 시스템 프롬프트에 _"결과를 간결하게 요약하라"_ 를 포함하세요.

=== 4. 적절한 모델 선택
작업 복잡도에 따라 서브에이전트마다 다른 모델을 사용할 수 있습니다.
- 단순 수집 → 가벼운 모델 (예: `openai:gpt-5.4-mini`, `anthropic:claude-haiku-4-6`)
- 깊은 분석 → 강력한 모델 (예: `openai:gpt-5.4`, `anthropic:claude-sonnet-4-6`)

=== 5. TodoList + dispatch 결합
메인 에이전트가 `write_todos` 로 항목을 만들고, 각 항목을 `task(subagent="...")` 로 위임하면 디스패치 결정이 추적 가능해집니다.

=== 6. 스트리밍 메타데이터
스트리밍 시 `lc_agent_name` 메타데이터로 어느 서브에이전트의 출력인지 식별할 수 있습니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 핵심 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [SubAgent],
  [dict 기반 정의: `name`, `description`, `system_prompt`, `tools`],
  [CompiledSubAgent],
  [커스텀 LangGraph 그래프를 `runnable`로 연결],
  [General-Purpose],
  [빌트인 기본 서브에이전트 (메인과 동일한 설정)],
  [컨텍스트 전파],
  [`context_schema` + `config["context"]`],
  [네임스페이스 키],
  [`"에이전트이름:키"` 형식으로 서브에이전트별 설정],
  [파이프라인 패턴],
  [collector → analyzer → writer],
)
