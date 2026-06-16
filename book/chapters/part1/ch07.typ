// Auto-generated from 07_mini_project.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "미니 프로젝트", subtitle: "검색 + 요약 에이전트")

입문 과정에서 배운 내용을 조합하여, Tavily 웹 검색 도구를 갖춘 리서치 에이전트를 만듭니다.

== 학습 목표
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
model = ChatOpenAI(model="gpt-4.1")
print("\u2713 환경 준비 완료")
`````)
#output-block(`````
✓ 환경 준비 완료
`````)

== 7.2 검색 도구 정의

Tavily 클라이언트를 감싸는 검색 함수를 만듭니다.
_docstring_과 _타입 힌트_가 에이전트에 도구 스키마를 알려줍니다.

_도구 함수 작성 규칙:_

`create_deep_agent()`의 `tools` 파라미터에 전달할 검색 함수를 정의합니다. Deep Agents는 함수의 docstring을 도구 설명으로, 타입 힌트를 파라미터 스키마로 자동 변환합니다. 따라서:

- _docstring_: 에이전트가 "이 도구를 언제 써야 하는지" 판단하는 근거가 됩니다. 명확하고 구체적으로 적으세요.
- _타입 힌트_: 에이전트가 올바른 타입의 인자를 전달하도록 합니다. `Literal` 타입을 쓰면 허용 값을 제한할 수 있습니다.
- _Args 섹션_: 각 파라미터의 용도를 설명하면 에이전트가 더 정확하게 인자를 고릅니다.

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

== 7.3 Deep Agents 리서치 에이전트

`create_deep_agent()`에 검색 도구와 시스템 프롬프트를 전달합니다.

_에이전트의 자동 워크플로:_

에이전트는 사용자 요청을 받으면 다음 과정을 자동으로 수행합니다:

+ _계획 수립_: 빌트인 `write_todos` 도구로 작업을 단계별로 나눕니다.
+ _리서치 수행_: 전달된 검색 도구(`internet_search`)로 웹에서 정보를 모읍니다.
+ _컨텍스트 관리_: 필요하면 파일 시스템 도구(`write_file`, `read_file`)로 중간 결과를 저장해 토큰 한도를 관리합니다.
+ _결과 종합_: 수집한 정보를 분석하고 일관된 보고서로 정리합니다.

복잡한 작업에서는 전문 서브에이전트를 만들어 특정 하위 작업의 컨텍스트를 격리할 수도 있습니다.

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

== 7.4 스트리밍으로 과정 관찰

`stream(mode="updates")`로 에이전트가 어떤 단계를 거치는지 실시간으로 확인합니다.

_LangGraph 스트리밍 시스템:_

LangGraph는 완전한 응답이 준비되기 전에 진행 상황을 점진적으로 보여줘 애플리케이션의 반응성을 높이는 스트리밍 시스템을 제공합니다.

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

`stream()` (동기) 또는 `astream()` (비동기) 메서드로 스트리밍에 접근하며, 여러 모드를 리스트로 넘겨 동시에 쓸 수도 있습니다. 아래 예제에서는 `updates` 모드로 에이전트의 각 단계(도구 호출, 최종 응답)를 실시간으로 출력합니다.

== 7.5 LangChain 에이전트로 비교

같은 검색 도구를 LangChain `create_agent()`로도 사용해 봅니다.

_LangChain 에이전트와의 차이점:_

LangChain의 `create_agent()`는 모델과 도구를 받아 간단한 ReAct 에이전트를 만듭니다. Deep Agents와 비교하면:

- _LangChain_: 도구 호출 에이전트의 기본 형태. 빠른 프로토타이핑에 맞지만, 태스크 플래닝이나 파일 시스템 관리 같은 기능은 직접 구현해야 합니다.
- _Deep Agents_: 플래닝(`write_todos`), 파일 관리, 서브에이전트 위임이 기본 내장되어 있어, 복잡한 멀티스텝 작업에 더 잘 맞습니다.

`@tool` 데코레이터를 쓰면 LangChain 도구 인터페이스에 맞게 함수를 변환할 수 있습니다. 시스템 프롬프트와 도구 리스트를 `create_agent()`에 전달하는 패턴은 Deep Agents와 같습니다.

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
