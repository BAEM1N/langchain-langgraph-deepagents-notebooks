// Auto-generated from 05_deep_agents_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Deep Agents 입문", subtitle: "올인원 에이전트")

Deep Agents SDK의 `create_deep_agent()`로 도구·메모리·백엔드가 내장된 에이전트를 한 줄로 만들어 봅니다.

== 학습 목표
#learning-objectives([`create_deep_agent()`로 에이전트를 생성한다], [`invoke()`로 에이전트를 실행한다], [커스텀 도구를 추가한 에이전트를 만든다])

== 5.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
print("\u2713 모델 준비 완료")
`````)
#output-block(`````
✓ 모델 준비 완료
`````)

== 5.2 에이전트 생성

`create_deep_agent()`는 LangChain 모델을 받아 파일 읽기/쓰기/검색, `execute`, `task` 같은 _빌트인 도구_가 포함된 에이전트를 반환합니다.
반환 타입이 LangGraph의 `CompiledStateGraph`이므로 `invoke()`, `stream()` 등을 그대로 쓸 수 있습니다.

_Deep Agents란?_

Deep Agents는 에이전트 개발을 단순하게 만들기 위해 설계된 프레임워크로, _에이전트 하네스(harness)_ 역할을 합니다. LangChain의 기본 에이전트 컴포넌트 위에 구축되며, 실행 관리에는 LangGraph를 씁니다.

_핵심 기능:_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [_컨텍스트 관리_],
  [파일 시스템 도구(`write_file`, `read_file`)로 토큰 한도를 넘는 중간 산출물을 다룹니다.],
  [_유연한 저장소_],
  [상태 기반, 로컬 디스크, 영구 store, 샌드박스 환경 등 플러거블 백엔드를 지원합니다.],
  [_서브에이전트 위임_],
  [특정 하위 작업을 전문 서브에이전트에 맡겨 컨텍스트를 격리합니다.],
  [_계획 도구_],
  [복잡한 작업에서 `TodoListMiddleware`를 명시적으로 추가하면 `write_todos`로 단계 관리를 할 수 있습니다.],
  [_영구 메모리_],
  [LangGraph store/checkpointer와 Deep Agents memory·skills 계층으로 여러 대화에 걸쳐 정보를 유지합니다.],
)

_에이전트 생성 방법:_

`create_deep_agent()`에 모델, 도구, 시스템 프롬프트를 전달하면 됩니다. 계획을 실습하려면 `middleware=[TodoListMiddleware()]`를 함께 전달합니다. 도구 호출을 지원하는 모델이 필요하며, Anthropic, OpenAI 등 다양한 프로바이더를 쓸 수 있습니다.

#code-block(`````python
from deepagents import create_deep_agent

agent = create_deep_agent(model=model)
print(f"\u2713 에이전트 생성 완료 (타입: {type(agent).__name__})")
`````)
#output-block(`````
✓ 에이전트 생성 완료 (타입: CompiledStateGraph)
`````)

== 5.3 커스텀 도구 추가

Python 함수에 _docstring_과 _타입 힌트_를 작성하면 그대로 도구가 됩니다.

_커스텀 도구의 동작 원리:_

커스텀 도구는 일반 Python 함수로 작성하며, 다음 두 가지가 자동으로 변환됩니다:

- _docstring_ → 도구 설명 (에이전트가 이 도구를 언제 써야 하는지 판단하는 근거)
- _타입 힌트_ → 파라미터 스키마 (에이전트가 올바른 인자를 넘기는 데 사용)

`create_deep_agent()`의 `tools` 파라미터에 함수 리스트를 전달하면, 빌트인 도구(파일 읽기/쓰기, todo 등)와 함께 에이전트 도구 목록에 추가됩니다. `system_prompt` 파라미터로 에이전트의 행동 방식을 지정할 수도 있습니다.

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
