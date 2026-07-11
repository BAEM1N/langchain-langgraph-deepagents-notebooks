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
model = ChatOpenAI(model="gpt-5.4")
print("\u2713 모델 준비 완료")
`````)
#output-block(`````
✓ 모델 준비 완료
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
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON \u2014 project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON \u2014 {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)
#output-block(`````
Langfuse tracing ON — https://lf.ddok.ai
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

#code-block(`````python
from langchain.messages import SystemMessage, HumanMessage

messages = [
    SystemMessage(content="당신은 유용한 어시스턴트입니다."),
    HumanMessage(content="Python이란 무엇인가요?"),
]

response = model.invoke(messages, config=lf_config)
print("응답:", response.content[:200])
`````)
#output-block(`````
응답: Python이란 무엇인가요?
Python은 쉽고 읽기 쉬운 문법을 가진 고급 프로그래밍 언어입니다. 1991년 네덜란드의 귀도 반 로섬(Guido van Rossum)이 처음 개발했습니다.

주요 특징:

1. 쉽고 간결한 문법
   - 초보자도 쉽게 배울 수 있고, 코드를 읽고 쓰기 편리합니다.

2. 다양한 용도
   - 웹 개발, 데이터
`````)

== 1.3 시스템 메시지로 행동 제어

`SystemMessage`를 바꾸면 같은 질문에도 전혀 다른 응답을 받습니다.
이것이 _프롬프트 엔지니어링_의 핵심입니다.

#code-block(`````python
# 같은 질문, 다른 시스템 메시지
question = HumanMessage(content="중력에 대해 설명해 주세요.")

# 과학자 페르소나
r1 = model.invoke([SystemMessage(content="당신은 물리학자입니다. 정확하게 답하세요."), question], config=lf_config)
print("[과학자]", r1.content[:150])
print()

# 어린이 교사 페르소나
r2 = model.invoke([SystemMessage(content="5살 아이에게 설명하듯이 쉬운 단어를 사용하세요."), question], config=lf_config)
print("[교사]", r2.content[:150])
`````)
#output-block(`````
[과학자] 중력(gravity)은 질량을 가진 두 물체 사이에 작용하는 인력(끌어당기는 힘)입니다. 우리가 지구에 발을 딛고 있을 수 있는 것도, 사과가 나무에서 떨어지는 것도 모두 중력 때문입니다.

중력의 대표적인 이론은 두 가지가 있습니다.

1. **뉴턴의 만유인력 법칙*


[교사] 좋아! 중력은 모든 것을 아래로 끌어당기는 힘이에요.

우리가 땅 위에 서 있을 수 있는 이유도, 공이 땅에 떨어지는 것도 바로 중력 때문이에요. 중력이 없으면 우리는 땅에 붙어 있지 못하고 하늘로 둥둥 떠올라요!

지구가 우리와 모든 것들을 껴안아 주는 힘이라고 생각
`````)

== 1.4 딕셔너리 형식

메시지 객체 대신 딕셔너리로도 전달할 수 있습니다. LangChain은 메시지 입력을 세 가지 형식으로 지원합니다:

+ _문자열(String)_: 단순 텍스트 프롬프트에 적합 (예: `model.invoke("Hello")`)
+ _메시지 객체(Message objects)_: `SystemMessage`, `HumanMessage` 등 타입이 지정된 인스턴스 리스트
+ _딕셔너리(Dictionary)_: OpenAI Chat Completion API와 동일한 `{"role": ..., "content": ...}` 구조

세 형식 모두 같은 결과를 돌려주니, 상황에 맞는 걸 고르면 됩니다. 딕셔너리 형식은 기존 OpenAI 코드를 LangChain으로 옮길 때 특히 편합니다.

#code-block(`````python
response = model.invoke([
    {"role": "system", "content": "한국어로 답변하세요."},
    {"role": "user", "content": "LangChain이란 무엇인가요?"},
], config=lf_config)
print(response.content[:200])
`````)
#output-block(`````
네, 설명드리겠습니다.

**LangChain**은 파이썬 및 자바스크립트로 작성된 **오픈소스 프레임워크**로, 챗GPT 같은 대형 언어 모델(LLM, Large Language Model)을 실제 애플리케이션에 쉽게 통합하고 활용할 수 있도록 도와줍니다. LangChain을 사용하면, LLM을 단순 질의응답(Q&A) 뿐 아니라, **외부 데이터(문서,
`````)

== 1.5 스트리밍

`model.stream()`을 사용하면 토큰이 생성되는 대로 바로 출력됩니다.
사용자 체감 속도가 눈에 띄게 빨라집니다.

LangChain 모델은 세 가지 호출 방식을 제공합니다:
- _`invoke()`_: 동기 호출로 전체 응답을 한 번에 반환
- _`stream()`_: 토큰 단위로 `AIMessageChunk` 객체를 순차 반환하여 실시간 출력 가능
- _`batch()`_: 여러 요청을 동시에 처리하여 효율적

스트리밍 중에는 각 `AIMessageChunk`가 점진적으로 합쳐져 최종 메시지를 구성하며, 토큰 사용량도 함께 추적됩니다.

#code-block(`````python
print("스트리밍 응답: ", end="")
for chunk in model.stream("우주에 대한 재미있는 사실을 2문장으로 알려주세요.", config=lf_config):
    print(chunk.content, end="", flush=True)
print()  # 줄바꿈
`````)
#output-block(`````
스트리밍 응답:
우
주
에는
 별
보다
 행
성이
 더
 많
다고
 과
학
자
들은
 추
정
합니다
.
 또한
,
 우리가
 보는
 별
빛
은
 수
십
만
 년
... (truncated)
`````)

== 1.6 배치 호출

`model.batch()`로 여러 질문을 한 번에 보낼 수 있습니다. `invoke()`를 반복 호출하는 것보다 여러 요청을 병렬로 처리할 때 효율적입니다.

#code-block(`````python
responses = model.batch(["2+2는 얼마인가요?", "3*5는 얼마인가요?"], config=lf_config)
for r in responses:
    print("-", r.content[:100])
`````)
#output-block(`````
- 2+2는 4입니다.
- 3 곱하기 5는 15입니다.
`````)

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
