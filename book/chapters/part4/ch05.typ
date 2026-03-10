// Auto-generated from 05_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "서브에이전트와 태스크 위임")

에이전트가 도구를 반복 호출하면 중간 결과가 컨텍스트 윈도우를 빠르게 채우는 _컨텍스트 블로트_ 문제가 발생한다. 서브에이전트는 이 문제를 근본적으로 해결하는 구조로, 전문 작업을 격리된 컨텍스트에서 수행한 뒤 압축된 결과만 메인 에이전트에 반환한다. 이 장에서는 `SubAgent` dict 정의, `CompiledSubAgent` 연결, 빌트인 `general-purpose` 서브에이전트 오버라이드, 그리고 멀티 서브에이전트 파이프라인 패턴을 실습한다.

4장에서 백엔드가 에이전트의 데이터 저장을 추상화하는 것을 보았다. 이 장에서 다루는 서브에이전트는 에이전트의 _작업 실행_을 추상화한다. 메인 에이전트가 모든 작업을 직접 수행하는 대신, 전문 서브에이전트에게 위임하여 컨텍스트를 깔끔하게 유지하는 것이 핵심이다. Deep Agents에서 서브에이전트를 정의하는 방법은 두 가지다: `subagents` 파라미터로 명시적으로 정의하거나, 에이전트가 런타임에 `create_subagent` 도구를 호출하여 동적으로 생성할 수 있다.

명시적 정의(`subagents` 파라미터)는 빌드 타임에 어떤 서브에이전트가 존재하는지 확정할 수 있어 테스트와 디버깅이 용이하다. 반면 동적 생성(`create_subagent` 도구)은 실행 중 사용자의 요구에 맞춰 새로운 전문 에이전트를 즉석에서 만들 수 있어 유연성이 높다. 각 서브에이전트는 _독립된 컨텍스트 윈도우_를 갖고, 메인 에이전트는 `task` 도구를 통해 서브에이전트에 작업을 위임한다. 서브에이전트가 작업을 완료하면 결과만 메인 에이전트에 돌려주므로, 중간 과정에서 발생한 수천 토큰의 정보가 메인 컨텍스트에 쌓이지 않는다.

#learning-header()
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
# OpenAI gpt-4.1 모델 설정
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

print(f"모델 설정 완료: {model.model_name}")
`````)
#output-block(`````
모델 설정 완료: gpt-4.1
`````)

환경 설정이 완료되었으므로, 서브에이전트의 필요성과 동작 원리를 단계별로 살펴보자. 먼저 서브에이전트가 등장하게 된 근본 원인인 _컨텍스트 블로트_ 문제부터 이해한다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 서브에이전트가 필요한 이유

=== 컨텍스트 블로트(Context Bloat) 문제

LLM 기반 에이전트는 대화 이력과 도구 호출 결과를 _하나의 컨텍스트 윈도우_ 안에서 관리한다. 도구를 반복 호출할수록 이 윈도우가 빠르게 채워지며, 이를 _컨텍스트 블로트_라 부른다. 컨텍스트가 포화되면 LLM은 앞부분의 중요한 지시를 "잊거나" 환각(hallucination) 확률이 높아진다.

에이전트가 도구를 사용할 때마다 _입력/출력이 컨텍스트 윈도우에 쌓입니다_:
- 웹 검색 결과 (수천 토큰)
- 파일 내용 읽기 (수백~수천 줄)
- 데이터베이스 쿼리 결과

이 중간 결과들이 메인 에이전트의 컨텍스트를 가득 채우면, 정작 중요한 정보를 놓칠 수 있습니다. 예를 들어 웹 검색 3회 + 파일 읽기 2회만 해도 쉽게 10,000 토큰 이상이 소비되어, 시스템 프롬프트나 초기 지시를 밀어내는 현상이 발생합니다.

=== 서브에이전트의 해결 방식

#align(center)[#image("../../assets/diagrams/png/subagent_context.png", width: 68%, height: 122mm, fit: "contain")]

메인 에이전트는 _500 토큰짜리 요약만_ 받으므로 컨텍스트가 깔끔하게 유지됩니다. 서브에이전트 내부에서 수천 토큰의 검색 결과, 파일 내용, 분석 결과가 오갔더라도, 메인 에이전트의 컨텍스트에는 압축된 최종 결과만 추가됩니다. 이것이 서브에이전트의 핵심 가치인 _컨텍스트 격리_입니다.

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

서브에이전트의 필요성을 이해했으므로, 이제 실제로 서브에이전트를 정의하는 방법을 알아보자. 가장 간단한 방법은 Python 딕셔너리(`dict`)로 선언하는 것이다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. SubAgent 정의하기 (dict 기반)

`SubAgent`는 딕셔너리 형태로 정의합니다. `create_deep_agent()`의 `subagents` 파라미터에 이 딕셔너리 리스트를 전달하면, 프레임워크가 내부적으로 각 서브에이전트를 독립 LangGraph 노드로 컴파일합니다. 메인 에이전트는 `task` 빌트인 도구를 통해 서브에이전트를 호출하며, 이때 `description` 필드를 참고하여 어떤 서브에이전트를 선택할지 결정합니다.

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
  [서브에이전트 지침],
  [`tools`],
  [`list`],
  [사용할 도구 목록],
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
  [`str`],
  [모델 오버라이드 (`"provider:model"`)],
  [`middleware`],
  [`list`],
  [추가 미들웨어],
  [`interrupt_on`],
  [`dict`],
  [Human-in-the-Loop 설정],
  [`skills`],
  [`list[str]`],
  [스킬 소스 경로],
)

#tip-box[`description`은 메인 에이전트가 서브에이전트를 _선택하는 유일한 기준_입니다. "리서치 에이전트"처럼 모호하게 쓰지 말고, _"인터넷 검색을 통해 최신 정보를 수집하고 핵심을 요약합니다. 사실 확인이나 트렌드 조사가 필요할 때 사용하세요"_처럼 구체적인 역할과 사용 시기를 명시하세요.]

다음 코드에서는 Tavily 웹 검색 도구를 갖춘 리서치 서브에이전트를 정의하고, 메인 에이전트에 연결하는 전체 흐름을 보여준다.

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

위에서 정의한 `research_subagent`는 아직 독립적인 딕셔너리일 뿐이다. 이것을 실제로 동작하게 하려면 `create_deep_agent()`의 `subagents` 파라미터에 전달해야 한다. 메인 에이전트가 생성되면 프레임워크가 자동으로 `task` 도구를 등록하고, 메인 에이전트는 이 도구를 통해 서브에이전트에 작업을 위임할 수 있다.

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

#warning-box[`subagents` 파라미터 외에도, 에이전트가 런타임에 `create_subagent` 도구를 호출하여 _동적으로_ 서브에이전트를 생성할 수 있다. 이 방식은 유연하지만, 어떤 서브에이전트가 만들어질지 사전에 예측할 수 없으므로 디버깅과 테스트가 어렵다. 프로덕션 환경에서는 명시적 `subagents` 정의를 우선 사용하고, 동적 생성은 탐색적(exploratory) 작업에 한정하는 것을 권장한다.]

dict 기반 `SubAgent`는 선언이 간편하지만, 조건 분기나 반복 같은 복잡한 로직에는 한계가 있다. 이럴 때는 `CompiledSubAgent`를 사용하여 이미 컴파일된 LangGraph 그래프를 서브에이전트로 연결할 수 있다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. CompiledSubAgent -- 커스텀 LangGraph 그래프 연결

`SubAgent` dict는 단순한 설정으로 서브에이전트를 정의하기에 편리하지만, 조건 분기, 반복, 멀티 노드 워크플로 같은 복잡한 로직이 필요한 경우에는 한계가 있습니다. `CompiledSubAgent`를 사용하면 미리 컴파일된 LangGraph 그래프(또는 다른 `create_deep_agent()` 결과)를 서브에이전트로 연결할 수 있습니다. 핵심 차이는 `tools` 대신 `runnable` 필드에 컴파일된 그래프 객체를 전달한다는 점이다.

이 패턴은 다음과 같은 상황에서 유용하다:
- 서브에이전트 내부에 _조건부 분기_(예: 데이터 유효성 검사 후 재시도)가 필요한 경우
- _여러 노드가 순차적으로 연결_된 파이프라인을 서브에이전트 하나로 캡슐화하고 싶은 경우
- 이미 구축된 LangGraph 워크플로를 _재사용_하고 싶은 경우

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

`CompiledSubAgent`에서는 `system_prompt`와 `tools`를 별도로 지정하지 않는다. 이 정보들은 이미 `runnable` 그래프 내부에 포함되어 있기 때문이다. 필요한 것은 `name`, `description`, 그리고 `runnable` 세 가지뿐이다.

다음으로, 명시적으로 서브에이전트를 정의하지 않아도 항상 사용 가능한 _빌트인 general-purpose 서브에이전트_에 대해 알아보자.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. General-Purpose 서브에이전트

Deep Agents는 별도로 정의하지 않아도 _빌트인 general-purpose 서브에이전트_를 자동 제공합니다.

=== 기본 동작
- 메인 에이전트와 _같은 시스템 프롬프트_ 사용
- 메인 에이전트와 _같은 도구_ 접근 가능
- 메인 에이전트와 _같은 모델_ 사용 (이 노트북에서는 OpenAI `gpt-4.1`)
- 메인 에이전트의 _스킬_ 상속

=== 오버라이드
`name="general-purpose"`로 서브에이전트를 정의하면 기본 동작을 덮어씁니다.

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

위 예시에서 `name`을 `"general-purpose"`로 설정하면 빌트인을 완전히 대체한다. 오버라이드하지 않으면 메인 에이전트의 설정(시스템 프롬프트, 도구, 모델)을 그대로 복사한 기본 서브에이전트가 자동으로 사용된다. 커스텀 서브에이전트만으로 커버되지 않는 "기타 멀티스텝 작업"을 general-purpose가 처리하므로, 오버라이드 시에는 범용적인 도구 세트를 할당하는 것이 좋다.

서브에이전트가 메인 에이전트와 격리된 컨텍스트를 갖는다고 했지만, _모든_ 정보가 차단되는 것은 아니다. 다음 섹션에서는 런타임 컨텍스트를 서브에이전트에 선택적으로 전달하는 메커니즘을 살펴본다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 컨텍스트 전파

서브에이전트가 메인 에이전트와 격리된 컨텍스트를 가진다 해도, 일부 정보(사용자 ID, 세션 설정 등)는 모든 에이전트가 공유해야 합니다. Deep Agents는 런타임 컨텍스트를 자동으로 모든 서브에이전트에 전파합니다. `context_schema`로 구조를 정의하고, `config`의 `context` 키로 값을 전달합니다.

=== 네임스페이스 키로 서브에이전트별 컨텍스트 전달

`"서브에이전트이름:키"` 형식을 사용하면, 특정 서브에이전트에만 전달되는 설정을 추가할 수 있습니다.

#code-block(`````python
config = {
    "context": {
        "user_id": "user-123",             # 모든 에이전트에 전파
        "researcher:max_depth": 3,          # researcher에만 전달
        "data-analyst:strict_mode": True,   # data-analyst에만 전달
    }
}
`````)

위 코드에서 `"user_id"`는 콜론(`:`)이 없으므로 _모든_ 에이전트(메인 + 모든 서브에이전트)에 전파된다. 반면 `"researcher:max_depth"`는 `researcher` 서브에이전트에만, `"data-analyst:strict_mode"`는 `data-analyst` 서브에이전트에만 전달된다. 이 네임스페이스 키 규칙을 활용하면, 보안에 민감한 설정(API 키, 접근 권한 등)을 특정 서브에이전트에만 제한적으로 전달할 수 있다.

#tip-box[`context_schema`를 사전에 정의해 두면, 잘못된 키 이름이나 타입의 컨텍스트가 전달될 때 _빌드 타임에 오류_를 잡을 수 있다. 스키마 없이도 동작하지만, 프로덕션 환경에서는 스키마 정의를 강력히 권장한다.]

지금까지 개별 서브에이전트의 정의와 컨텍스트 전파를 다루었다. 다음은 여러 서브에이전트를 _순차적으로 연결_하여 복잡한 작업 흐름을 구성하는 파이프라인 패턴을 살펴본다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. 멀티 서브에이전트 파이프라인

서브에이전트의 진정한 힘은 여러 개를 조합할 때 발휘됩니다. 메인 에이전트가 _코디네이터_ 역할을 하면서 전문 서브에이전트들을 순서대로 호출하는 _파이프라인 패턴_을 구성할 수 있습니다. 예를 들어 _수집 -> 분석 -> 작성_ 파이프라인에서 각 단계를 전문 서브에이전트가 담당합니다.

#tip-box[파이프라인 패턴에서 메인 에이전트의 시스템 프롬프트에 호출 순서를 명시하면, 에이전트가 더 일관되게 파이프라인을 따릅니다. 단, LLM은 지시를 항상 완벽히 따르지 않으므로 결과를 검증하는 로직도 고려하세요.]

#align(center)[#image("../../assets/diagrams/png/subagent_pipeline.png", width: 60%, height: 132mm, fit: "contain")]

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

위 파이프라인에서 각 서브에이전트는 _독립된 컨텍스트_에서 작업하므로, data-collector가 수집한 방대한 원시 데이터가 report-writer의 컨텍스트를 오염시키지 않는다. 메인 에이전트(코디네이터)는 각 단계의 _압축된 결과만_ 받아 다음 서브에이전트에 전달하는 중개자 역할을 한다. 이 구조 덕분에 개별 서브에이전트는 자신의 전문 영역에만 집중할 수 있고, 전체 파이프라인의 토큰 효율도 크게 향상된다.

#warning-box[파이프라인의 서브에이전트 수가 많아지면 메인 에이전트가 호출 순서를 혼동할 수 있다. 서브에이전트는 3~5개 이내로 유지하고, 시스템 프롬프트에 명확한 호출 순서를 기술하라. 더 복잡한 워크플로가 필요하면 `CompiledSubAgent`로 LangGraph 그래프를 직접 설계하는 것이 낫다.]

파이프라인 패턴까지 익혔다면, 마지막으로 서브에이전트를 효과적으로 설계하기 위한 실무 가이드라인을 정리한다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. 베스트 프랙티스

=== 1. 명확한 description 작성
메인 에이전트는 `description`을 보고 어떤 서브에이전트를 호출할지 결정합니다.
-\> 서브에이전트의 역할과 사용 시기를 명확하게 기술하세요.

=== 2. 최소 도구 원칙
서브에이전트에는 _필요한 도구만_ 제공하세요.
불필요한 도구는 컨텍스트를 낭비하고 오동작의 원인이 됩니다.

=== 3. 간결한 결과 반환
서브에이전트의 시스템 프롬프트에 _"결과를 간결하게 요약하라"_는 지침을 포함하세요.
그래야 메인 에이전트가 효율적으로 결과를 처리할 수 있습니다.

=== 4. 적절한 모델 선택
작업 복잡도에 따라 서브에이전트마다 다른 모델을 사용할 수 있습니다.
이 노트북에서는 OpenAI `gpt-4.1` 모델을 사용합니다.
다양한 프로바이더의 모델을 유연하게 선택할 수 있습니다:
- 단순 수집 -\> 가벼운 모델 (예: `gpt-4.1-mini`)
- 깊은 분석 -\> 강력한 모델 (예: `gpt-4.1`, `anthropic:claude-sonnet-4`)

=== 5. 서브에이전트 간 의존성 최소화
서브에이전트 A의 결과가 서브에이전트 B에 필요한 경우, 반드시 _메인 에이전트를 경유_하여 전달한다. 서브에이전트끼리 직접 통신하는 구조는 디버깅이 어렵고, 실패 시 복구가 곤란하다.

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
  [collector -> analyzer -> writer],
)

서브에이전트를 통해 컨텍스트 블로트 문제를 해결하고, 전문 작업을 효율적으로 위임하는 방법을 배웠습니다. 그러나 서브에이전트 간에 지식을 영속적으로 공유하려면 장기 메모리가 필요합니다. 다음 장에서는 `AGENTS.md`, `SKILL.md`, `StoreBackend`를 활용한 장기 메모리 시스템을 다룹니다.

