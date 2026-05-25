// Auto-generated from 01_llm_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LLM 기초", subtitle: "메시지, 프롬프트, 스트리밍")

현대의 LLM은 근본적으로 _채팅 완성(chat completion)_ 모델입니다. 단순히 텍스트를 이어 쓰는 과거의 텍스트 완성 모델과 달리, 메시지 시퀀스를 입력으로 받아 다음 메시지를 예측합니다. 이 메시지 기반 인터페이스를 통해 대화 맥락, 페르소나, 멀티턴 상호작용을 정밀하게 제어할 수 있습니다. 에이전트, 도구, 워크플로 — 이 책에서 다루는 모든 것은 이 메시지 시스템 위에 구축됩니다.

에이전트를 만들기 전에, 먼저 LLM과 대화하는 기본 방법을 익힙니다.

#learning-header()
#learning-objectives([메시지의 역할(`system`, `human`, `ai`)을 이해한다], [시스템 메시지로 모델의 행동을 제어한다], [`model.stream()`으로 실시간 응답을 받는다])

== 1.1 환경 설정

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

== 1.2 메시지의 세 가지 역할

LLM은 _메시지 리스트_를 입력으로 받습니다. 각 메시지에는 역할이 있으며, 역할(role), 콘텐츠(content), 메타데이터(metadata) 세 가지 핵심 요소로 구성됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[역할],
  text(weight: "bold")[클래스],
  text(weight: "bold")[설명],
  [`system`],
  [`SystemMessage`],
  [모델의 행동 지침을 설정합니다. 페르소나, 응답 톤, 규칙 등을 정의하여 모델의 초기 동작을 결정합니다.],
  [`human`],
  [`HumanMessage`],
  [사용자의 입력을 나타냅니다. 텍스트뿐만 아니라 이미지, 오디오, 파일 등 멀티모달 콘텐츠를 지원합니다.],
  [`ai`],
  [`AIMessage`],
  [모델의 응답입니다. 텍스트 응답 외에도 `tool_calls`(도구 호출), `usage_metadata`(토큰 사용량) 등의 속성을 포함합니다.],
)

`AIMessage`는 단순한 텍스트 응답 이상의 정보를 담고 있습니다. `.content`로 응답 텍스트를 얻는 것 외에도, `.tool_calls`에는 에이전트가 사용하려는 도구 호출 요청(이름, 인자, 고유 ID)이 담겨 있고, `.usage_metadata`에는 토큰 소비량(`input_tokens`, `output_tokens`, `total_tokens`)이, `.response_metadata`에는 모델 버전이나 종료 사유 같은 프로바이더별 정보가 포함됩니다. 스트리밍 중에는 `AIMessageChunk` 객체가 생성되며, 이들은 `+` 연산자로 점진적으로 결합되어 최종 `AIMessage`를 구성합니다.

이 외에도 도구 실행 결과를 모델에 전달하는 `ToolMessage`가 있습니다. 도구 호출의 전체 흐름은 다음과 같습니다: (1) 모델이 `tool_calls`가 포함된 `AIMessage`를 반환하고, (2) 코드가 해당 도구를 실행한 뒤, (3) 결과를 매칭되는 `tool_call_id`와 함께 `ToolMessage`로 감싸서 (4) 대화에 추가합니다. `ToolMessage`에는 선택적으로 `artifact` 필드를 사용할 수 있는데, 모델에게는 보여줄 필요 없지만 후속 코드에서 활용할 보조 데이터(예: 문서 ID)를 저장할 때 유용합니다.

이 메시지 시스템을 구성하는 핵심 요소부터 살펴봅시다.

== 1.3 시스템 메시지로 행동 제어

`SystemMessage`를 바꾸면 같은 질문에도 전혀 다른 응답을 받습니다.
이것이 _프롬프트 엔지니어링_의 핵심입니다.

메시지 역할 중 가장 강력한 것은 `SystemMessage`입니다. 같은 질문이라도 시스템 메시지에 따라 완전히 다른 답변을 받을 수 있습니다.

== 1.4 딕셔너리 형식

메시지 객체 대신 딕셔너리로도 전달할 수 있습니다. LangChain은 메시지 입력을 세 가지 형식으로 지원합니다:

+ _문자열(String)_: 단순 텍스트 프롬프트에 적합 (예: `model.invoke("Hello")`)
+ _메시지 객체(Message objects)_: `SystemMessage`, `HumanMessage` 등 타입이 지정된 인스턴스 리스트
+ _딕셔너리(Dictionary)_: OpenAI Chat Completion API와 동일한 `{"role": ..., "content": ...}` 구조

세 가지 형식 모두 동일한 결과를 반환하므로, 상황에 맞는 형식을 선택하면 됩니다. 딕셔너리 형식은 기존 OpenAI 코드를 LangChain으로 마이그레이션할 때 특히 유용합니다.

딕셔너리 형식의 `content` 필드는 텍스트뿐 아니라 멀티모달 콘텐츠도 담을 수 있습니다. `HumanMessage`는 텍스트 외에 이미지(URL, base64, 프로바이더 파일 ID), 오디오, 비디오, 문서(PDF) 등 다양한 형식을 지원합니다. LangChain은 이러한 멀티모달 입력을 프로바이더 간에 표준화하므로, OpenAI, Anthropic, Google 중 어떤 프로바이더를 사용하더라도 동일한 코드가 동작합니다.

== 1.5 스트리밍

`model.stream()`을 사용하면 토큰이 생성되는 대로 실시간으로 출력됩니다.
사용자 체감 속도가 크게 향상됩니다.

LangChain 모델은 세 가지 호출 방식을 제공합니다:
- *`invoke()`*: 동기 호출로 전체 응답을 한 번에 반환
- *`stream()`*: 토큰 단위로 `AIMessageChunk` 객체를 순차 반환하여 실시간 출력 가능
- *`batch()`*: 여러 요청을 동시에 처리하여 효율성 향상

스트리밍 중에는 각 `AIMessageChunk`가 점진적으로 결합되어 최종 메시지를 구성하며, 토큰 사용량도 점진적으로 추적할 수 있습니다. `stream()`은 동기 메서드이며, 비동기 코드에서는 `astream()`을 사용합니다.

스트리밍이 단일 요청의 응답성을 높인다면, `batch()`는 여러 요청의 처리량을 높입니다.

== 1.6 배치 호출

`model.batch()`로 여러 질문을 한 번에 보낼 수 있습니다. `batch()`는 요청을 순차적으로 처리하는 것이 아니라 _병렬_로 처리하므로, `invoke()`를 루프로 반복 호출하는 것보다 훨씬 빠릅니다. 여러 문서를 분류하거나 다수의 텍스트를 동시에 번역하는 등의 대량 처리 작업에 유용합니다.

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  [`SystemMessage`],
  [모델의 페르소나·규칙 설정],
  [`HumanMessage`],
  [사용자 입력],
  [`model.invoke()`],
  [동기 호출 (전체 응답)],
  [`model.stream()`],
  [토큰 단위 실시간 출력],
  [`model.batch()`],
  [여러 요청 동시 처리],
)

이 장에서 다룬 메시지 시스템과 호출 방식은 다음 장에서 배울 도구(Tool) 호출과 에이전트의 기반이 됩니다.

