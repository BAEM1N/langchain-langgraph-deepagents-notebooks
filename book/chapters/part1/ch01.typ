// Auto-generated from 01_llm_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LLM 기초", subtitle: "메시지, 프롬프트, 스트리밍")

에이전트를 만들기 전에, LLM과 대화하는 기본 방법을 익힙니다.

== 학습 목표
#learning-objectives([메시지의 역할(`system`, `human`, `ai`)을 이해한다], [시스템 메시지로 모델의 행동을 제어한다], [`model.stream()`으로 실시간 응답을 받는다])

== 1.1 환경 설정

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

== 1.2 메시지의 세 가지 역할

LLM은 _메시지 리스트_를 입력으로 받습니다. 각 메시지에는 역할(role), 콘텐츠(content), 메타데이터(metadata)라는 세 가지 핵심 요소가 있습니다.

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

도구 실행 결과를 모델에 전달하는 `ToolMessage`도 있습니다. `ToolMessage`는 도구 결과 내용, 도구 호출 ID, 도구 이름을 필수로 포함합니다.

== 1.3 시스템 메시지로 행동 제어

`SystemMessage`를 바꾸면 같은 질문에도 전혀 다른 응답을 받습니다.
이것이 _프롬프트 엔지니어링_의 핵심입니다.

== 1.4 딕셔너리 형식

메시지 객체 대신 딕셔너리로도 전달할 수 있습니다. LangChain은 메시지 입력을 세 가지 형식으로 지원합니다:

+ _문자열(String)_: 단순 텍스트 프롬프트에 적합 (예: `model.invoke("Hello")`)
+ _메시지 객체(Message objects)_: `SystemMessage`, `HumanMessage` 등 타입이 지정된 인스턴스 리스트
+ _딕셔너리(Dictionary)_: OpenAI Chat Completion API와 동일한 `{"role": ..., "content": ...}` 구조

세 형식 모두 같은 결과를 돌려주니, 상황에 맞는 걸 고르면 됩니다. 딕셔너리 형식은 기존 OpenAI 코드를 LangChain으로 옮길 때 특히 편합니다.

== 1.5 스트리밍

`model.stream()`을 사용하면 토큰이 생성되는 대로 바로 출력됩니다.
사용자 체감 속도가 눈에 띄게 빨라집니다.

LangChain 모델은 세 가지 호출 방식을 제공합니다:
- _`invoke()`_: 동기 호출로 전체 응답을 한 번에 반환
- _`stream()`_: 토큰 단위로 `AIMessageChunk` 객체를 순차 반환하여 실시간 출력 가능
- _`batch()`_: 여러 요청을 동시에 처리하여 효율적

스트리밍 중에는 각 `AIMessageChunk`가 점진적으로 합쳐져 최종 메시지를 구성하며, 토큰 사용량도 함께 추적됩니다.

== 1.6 배치 호출

`model.batch()`로 여러 질문을 한 번에 보낼 수 있습니다. `invoke()`를 반복 호출하는 것보다 여러 요청을 병렬로 처리할 때 효율적입니다.

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
