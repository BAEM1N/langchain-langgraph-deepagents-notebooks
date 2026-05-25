// Auto-generated from 07_mini_project.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "미니 프로젝트", subtitle: "검색 + 요약 에이전트")

이 장은 앞선 여섯 개 장의 모든 내용을 하나의 실전 프로젝트로 종합합니다. 0장의 모델 초기화, 1장의 메시지 시스템, 2장의 도구 정의 패턴, 3장의 스트리밍 관찰, 5장의 Deep Agents 프레임워크를 활용하여, 웹에서 정보를 검색하고 구조화된 요약을 생성하는 리서치 에이전트를 만듭니다.

#learning-header()
#learning-objectives([Tavily 검색 도구를 직접 정의한다], [Deep Agents로 리서치 에이전트를 만든다], [스트리밍으로 에이전트 실행 과정을 실시간 관찰한다], [LangChain 에이전트로도 같은 작업을 수행하여 비교한다])

== 7.1 환경 설정

이 노트북에는 `TAVILY_API_KEY`가 필요합니다. https://tavily.com 에서 무료로 발급받을 수 있습니다.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY 필요!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY 필요!"

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
print("\u2713 환경 준비 완료")
`````)
#output-block(`````
✓ 환경 준비 완료
`````)

== 7.2 검색 도구 정의

Tavily 클라이언트를 래핑하는 검색 함수를 만듭니다.
_docstring_과 _타입 힌트_가 에이전트에 도구 스키마를 알려줍니다.

_도구 함수 작성 규칙:_

`create_deep_agent()`의 `tools` 파라미터에 전달할 검색 함수를 정의합니다. Deep Agents는 함수의 docstring을 도구 설명으로, 타입 힌트를 파라미터 스키마로 자동 변환합니다. 따라서:

- _docstring_: 에이전트가 "이 도구를 언제 사용해야 하는지" 판단하는 근거가 됩니다. 명확하고 구체적으로 작성하세요.
- _타입 힌트_: 에이전트가 올바른 타입의 인자를 전달하도록 합니다. `Literal` 타입을 사용하면 허용 값을 제한할 수 있습니다.
- _Args 섹션_: 각 파라미터의 용도를 설명하면 에이전트가 더 정확하게 인자를 선택합니다. 없으면 에이전트가 `topic`의 의미를 잘못 추측할 수 있습니다.

이 패턴 — 제약된 타입, 합리적 기본값, 상세한 docstring — 은 도구 설계의 모범 사례입니다. `Literal["general", "news"]` 타입 힌트는 에이전트가 유효한 값만 전달하도록 강제하고, `max_results: int = 3` 기본값은 에이전트가 특별히 더 많은 결과가 필요하지 않으면 이 매개변수를 지정할 필요가 없음을 의미합니다.

#code-block(`````python
from typing import Literal
from tavily import TavilyClient

tavily = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

def internet_search(
    query: str,
    max_results: int = 3,
    topic: Literal["general", "news"] = "general",
) -> dict:
    """인터넷에서 정보를 검색합니다.

    Args:
        query: 검색 쿼리
        max_results: 최대 결과 수
        topic: 검색 주제 카테고리
    """
    return tavily.search(query, max_results=max_results, topic=topic)

print("\u2713 검색 도구 준비 완료")
`````)
#output-block(`````
✓ 검색 도구 준비 완료
`````)

검색 도구가 준비되었습니다. 이제 이 도구를 사용할 Deep Agents 에이전트를 만듭니다.

== 7.3 Deep Agents 리서치 에이전트

`create_deep_agent()`에 검색 도구와 시스템 프롬프트를 전달합니다. 시스템 프롬프트는 에이전트의 행동을 결정적으로 좌우합니다. "한국어로 요약하세요"도 좋지만, "3개의 핵심 포인트로 정리하세요"처럼 출력 형식을 구체적으로 지정하면 더 일관된 결과를 얻습니다. "검색 결과가 불충분하면 추가 검색을 수행하세요"와 같은 행동 지침을 추가하면 에이전트가 반복 검색을 통해 더 철저한 리서치를 수행합니다.

_에이전트의 자동 워크플로:_

에이전트는 사용자의 요청을 받으면 다음과 같은 과정을 자동으로 수행합니다:

+ _계획 수립_: 빌트인 `write_todos` 도구로 작업을 단계별로 분해합니다.
+ _리서치 수행_: 전달된 검색 도구(`internet_search`)를 사용하여 웹에서 정보를 수집합니다.
+ _컨텍스트 관리_: 필요 시 파일 시스템 도구(`write_file`, `read_file`)로 중간 결과를 저장하여 토큰 한도를 관리합니다.
+ _결과 종합_: 수집한 정보를 분석하고 일관된 보고서로 종합합니다.

복잡한 작업의 경우, 에이전트는 전문 서브에이전트를 생성하여 특정 하위 작업의 컨텍스트를 격리할 수도 있습니다.

#code-block(`````python
from deepagents import create_deep_agent

research_agent = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="당신은 전문 리서처입니다. 웹을 검색한 후 결과를 한국어로 요약하세요.",
)
print("\u2713 리서치 에이전트 생성 완료")
`````)
#output-block(`````
✓ 리서치 에이전트 생성 완료
`````)

에이전트를 실행하면서 내부에서 어떤 일이 벌어지는지 스트리밍으로 관찰해 봅시다.

== 7.4 스트리밍으로 과정 관찰

`stream(mode="updates")`로 에이전트가 어떤 단계를 거치는지 실시간으로 확인합니다. 스트리밍 출력에서는 다음과 같은 과정을 관찰할 수 있습니다: 먼저 에이전트의 "사고" 단계 — 바로 검색할지, 계획을 세울지 판단합니다. 이어서 도구 호출이 나타나며, 에이전트가 선택한 쿼리로 `internet_search`가 실행됩니다. 검색 결과가 돌아오면, 에이전트는 정제된 쿼리로 추가 검색을 수행할 수도 있습니다. 마지막으로 모든 결과를 종합하여 응답을 생성합니다. 각 단계는 노드 이름(예: "agent", "tools")과 함께 별개의 `updates` 이벤트로 나타납니다.

_LangGraph 스트리밍 시스템:_

LangGraph는 완전한 응답이 준비되기 전에 진행 상황을 점진적으로 표시하여 애플리케이션의 반응성을 높이는 포괄적인 스트리밍 시스템을 제공합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[스트림 모드],
  text(weight: "bold")[용도],
  [`values`],
  [각 그래프 단계 후 _전체 상태_를 스트리밍],
  [`updates`],
  [각 단계 후 _상태 변경분만_ 스트리밍],
  [`messages`],
  [LLM 토큰을 메타데이터와 함께 스트리밍],
  [`custom`],
  [노드에서 사용자 정의 데이터를 스트리밍],
  [`debug`],
  [포괄적인 실행 정보를 스트리밍],
)

`stream()` (동기) 또는 `astream()` (비동기) 메서드로 스트리밍에 접근하며, 여러 모드를 리스트로 전달하여 동시에 사용할 수도 있습니다. 아래 예제에서는 `updates` 모드를 사용하여 에이전트의 각 단계(도구 호출, 최종 응답)를 실시간으로 출력합니다.

같은 작업을 LangChain의 `create_agent()`로도 수행하여, 두 접근 방식의 차이를 직접 비교합니다.

== 7.5 LangChain 에이전트로 비교

같은 검색 도구를 LangChain `create_agent()`로도 사용해 봅니다. `@tool` 데코레이터를 사용하면 LangChain의 도구 인터페이스에 맞게 함수를 변환할 수 있습니다.

실행 결과를 비교하면 실질적인 차이를 관찰할 수 있습니다. LangChain 에이전트는 검색 도구를 호출하고 바로 요약합니다 — 계획을 세우거나 파일을 관리하지 않습니다. 반면 Deep Agents 에이전트는 투두 리스트를 생성하고, 여러 번 검색하고, 중간 노트를 파일에 기록하여 더 철저한 결과를 생성할 수 있습니다.

트레이드오프는 명확합니다: Deep Agents는 더 철저하지만 더 많은 토큰을 소비합니다(비용이 높아집니다). LangChain은 단순한 쿼리에 더 빠르고 저렴합니다. 이 특정 작업(단일 주제 리서치)에서는 차이가 작을 수 있지만, 복잡한 멀티 토픽 리서치에서는 Deep Agents의 계획 능력이 큰 차이를 만듭니다.

#chapter-summary-header()

이 미니 프로젝트에서 사용한 기술:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기술],
  text(weight: "bold")[출처],
  [`ChatOpenAI` + `load_dotenv`],
  [00_setup],
  [메시지 역할, 스트리밍],
  [01_llm_basics],
  [`\@tool`, `create_agent()`],
  [02_langchain_basics],
  [`InMemorySaver`, `thread_id`],
  [03_langchain_memory],
  [`StateGraph`, `compile()`],
  [04_langgraph_basics],
  [`create_deep_agent()`],
  [05_deep_agents_basics],
)

=== 도전 과제

이 프로젝트를 확장해 보세요:

+ 계산기나 날짜 유틸리티 같은 두 번째 도구를 추가하고, 두 도구가 모두 필요한 리서치를 요청해 보세요.
+ `InMemorySaver`를 추가하여 에이전트가 이전 리서치 세션을 기억하도록 만들어 보세요.
+ 시스템 프롬프트를 수정하여 마크다운 형식(섹션, 불릿 포인트, 출처 링크 포함)의 보고서를 생성하도록 해 보세요.

축하합니다! 입문 과정을 완료했습니다. 이제 6장에서 안내한 중급 과정으로 넘어가, 각 프레임워크의 고급 기능을 깊이 있게 학습할 수 있습니다.

