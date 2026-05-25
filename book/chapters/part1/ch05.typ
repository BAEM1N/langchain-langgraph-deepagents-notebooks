// Auto-generated from 05_deep_agents_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Deep Agents 입문", subtitle: "올인원 에이전트")

Deep Agents SDK의 `create_deep_agent()`로 도구·메모리·백엔드가 내장된 에이전트를 한 줄로 만들어 봅니다.

#learning-header()
#learning-objectives([`create_deep_agent()`로 에이전트를 생성한다], [`invoke()`로 에이전트를 실행한다], [커스텀 도구를 추가한 에이전트를 만든다])

== 5.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
print("\u2713 모델 준비 완료")
`````)
#output-block(`````
✓ 모델 준비 완료
`````)

== 5.2 에이전트 생성

`create_deep_agent()`는 LangChain 모델을 받아, 파일 읽기/쓰기/검색 등의 _빌트인 도구_가 자동으로 포함된 에이전트를 반환합니다.
반환 타입은 LangGraph의 `CompiledStateGraph`이므로 `invoke()`, `stream()` 등을 그대로 사용할 수 있습니다.

_Deep Agents란?_

Deep Agents는 에이전트 개발을 간소화하기 위해 설계된 프레임워크로, 일종의 _"에이전트 하네스(harness)"_ 역할을 합니다. 내부적으로 LangChain과 LangGraph _위에_ 구축됩니다. `create_deep_agent()`를 호출하면 내부적으로 LangGraph의 `StateGraph`에 계획, 도구 실행, 컨텍스트 관리를 위한 사전 구성된 노드가 생성됩니다. 반환되는 `CompiledStateGraph`는 4장에서 `builder.compile()`로 얻는 것과 동일한 타입이므로, 스트리밍, 체크포인팅 등 모든 LangGraph 기능이 자동으로 작동합니다. 따라서 4장에서 LangGraph 기초를 이해한 것이 Deep Agents의 내부 동작을 파악하는 데 도움이 됩니다.

_핵심 내장 기능:_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [_태스크 플래닝_],
  [`write_todos` / `read_todos` 도구로 구조화된 태스크 리스트를 생성하고, 진행하면서 항목을 체크합니다],
  [_컨텍스트 관리_],
  [`write_file` / `read_file` 도구로 중간 결과를 가상 파일시스템에 저장합니다. 대화에 모든 것을 유지하는 대신 데이터를 파일로 오프로드하여 토큰 오버플로를 방지합니다],
  [_유연한 저장소_],
  [기본적으로 인메모리 파일시스템을 사용하지만, 로컬 디스크나 영구 저장소로 교체할 수 있는 플러거블 백엔드를 지원합니다],
  [_서브에이전트 위임_],
  [`create_subagent` 도구로 독자적인 컨텍스트 윈도우, 도구, 시스템 프롬프트를 가진 전문 서브에이전트를 생성합니다. 서브에이전트는 작업을 완료하고 결과를 부모에게 반환합니다],
  [_영구 메모리_],
  [LangGraph의 메모리 인프라를 활용하여 여러 대화에 걸쳐 정보 유지],
)

_에이전트 생성 방법:_

`create_deep_agent()`에 모델, 도구, 시스템 프롬프트를 전달하여 에이전트를 생성합니다. 도구 호출을 지원하는 모델이 필요하며, Anthropic, OpenAI 등 다양한 모델 프로바이더를 사용할 수 있습니다.

#code-block(`````python
from deepagents import create_deep_agent

agent = create_deep_agent(model=model)
print(f"\u2713 에이전트 생성 완료 (타입: {type(agent).__name__})")
`````)
#output-block(`````
✓ 에이전트 생성 완료 (타입: CompiledStateGraph)
`````)

빌트인 도구만으로 충분하지 않을 때, 커스텀 도구를 추가하여 에이전트의 능력을 확장할 수 있습니다.

== 5.3 커스텀 도구 추가

Python 함수에 _docstring_과 _타입 힌트_를 작성하면 그대로 도구가 됩니다.

커스텀 도구는 일반 Python 함수로 작성하며, 다음 두 가지가 자동으로 변환됩니다:

- _docstring_ → 도구 설명 (에이전트가 도구의 용도를 이해하는 데 사용)
- _타입 힌트_ → 파라미터 스키마 (에이전트가 올바른 인자를 전달하는 데 사용)

`create_deep_agent()`의 `tools` 파라미터에 함수 리스트를 전달하면, 빌트인 도구를 _대체_하는 것이 아니라 _추가_됩니다. 에이전트는 같은 실행에서 커스텀 도구와 빌트인 파일/계획 도구를 함께 사용할 수 있습니다. `system_prompt` 파라미터는 에이전트가 모든 도구를 어떻게 활용할지 안내합니다 — 항상 계획을 먼저 세우도록 하거나, 특정 도구를 선호하도록 지시할 수 있습니다.

#tip-box[단순한 Q&A 에이전트에 도구 하나둘만 필요하다면 2장의 `create_agent()`가 더 단순하고 오버헤드가 적습니다. 여러 단계, 대량 데이터 처리, 자동 계획이 필요한 작업에는 Deep Agents가 설정 시간을 크게 절약합니다.]

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[핵심 API],
  text(weight: "bold")[역할],
  [`create_deep_agent(model)`],
  [빌트인 도구가 포함된 에이전트 생성],
  [`create_deep_agent(model, tools, system_prompt)`],
  [커스텀 도구 + 시스템 프롬프트],
  [`agent.invoke()`],
  [에이전트 실행],
)

지금까지 LangChain, LangGraph, Deep Agents를 각각 살펴봤습니다. 다음 장에서는 세 프레임워크를 나란히 비교하여 어떤 상황에서 어떤 것을 선택해야 하는지 정리합니다.

