// Auto-generated from 03_models_and_messages.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "모델과 메시지 시스템")

에이전트의 성능은 기반 모델의 설정과 메시지 구성 방식에 크게 좌우됩니다. 이 장에서는 LangChain v1이 지원하는 다양한 LLM 프로바이더를 통합된 인터페이스로 관리하는 방법과, 메시지 타입별 특성을 깊이 있게 다룹니다. Part I의 1장에서 다룬 기초를 확장하여, 멀티모달 입력, 토큰 사용량 추적, 프로바이더 간 전환까지 학습합니다.

앞 장에서는 `ChatOpenAI`를 직접 생성하여 에이전트에 전달했습니다. 그런데 프로젝트가 커지면 OpenAI에서 Anthropic으로, 또는 로컬 Ollama 모델로 전환해야 할 때가 옵니다. LangChain v1은 `init_chat_model()` 함수를 통해 _프로바이더 문자열 하나로_ 모델을 초기화할 수 있으며, 런타임 config를 통한 동적 전환까지 지원합니다. 이 장에서는 그 메커니즘과 함께, 대화의 기본 단위인 메시지 객체의 구조를 상세히 파악합니다.

#learning-header()
#learning-objectives([LangChain v1의 모델 초기화 방법(`init_chat_model`, `ChatOpenAI`)을 이해합니다], [`invoke()`, `stream()`, `batch()` 세 가지 호출 패턴을 학습합니다], [`SystemMessage`, `HumanMessage`, `AIMessage`, `ToolMessage` 등 메시지 타입을 이해합니다], [멀티모달 메시지(이미지 입력)를 구성하는 방법을 익힙니다])

== 3.1 환경 설정

이 장 전체에서 사용할 모델 인스턴스를 준비합니다. `ChatOpenAI`의 주요 매개변수는 다음과 같습니다: `model`(모델 이름), `temperature`(창의성 조절, 0~2), `max_tokens`(최대 출력 토큰), `timeout`(요청 타임아웃), `max_retries`(실패 시 자동 재시도 횟수, 기본값 6), `api_key`(API 키). 대부분의 경우 `model`만 지정하면 나머지는 합리적인 기본값이 적용됩니다.

`.env` 파일에서 API 키를 로드하고, OpenAI를 통해 모델을 초기화합니다.

#code-block(`````python
import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv(override=True)

# OpenAI를 통한 모델 초기화
model = ChatOpenAI(
    model="gpt-5.4",
)

print("모델 초기화 완료:", model.model_name)
`````)
#output-block(`````
모델 초기화 완료: gpt-5.4
`````)

== 3.2 모델 프로바이더 비교

LangChain v1은 `init_chat_model()`을 통해 다양한 프로바이더의 모델을 통합된 방식으로 초기화할 수 있습니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[프로바이더],
  text(weight: "bold")[모델 문자열 형식],
  text(weight: "bold")[필요 패키지],
  text(weight: "bold")[환경 변수],
  [OpenAI],
  [`"openai:gpt-5"`],
  [`langchain-openai`],
  [`OPENAI_API_KEY`],
  [Anthropic],
  [`"anthropic:claude-sonnet-4-6"`],
  [`langchain-anthropic`],
  [`ANTHROPIC_API_KEY`],
  [Google],
  [`"google:gemini-2.5-flash-lite"`],
  [`langchain-google-genai`],
  [`GOOGLE_API_KEY`],
  [AWS Bedrock],
  [`"bedrock:anthropic.claude-v3"`],
  [`langchain-aws`],
  [AWS credentials],
  [Azure],
  [`"azure:gpt-4o"`],
  [`langchain-openai`],
  [`AZURE_OPENAI_API_KEY`],
  [Ollama],
  [`"ollama:llama3"`],
  [`langchain-ollama`],
  [(로컬 실행)],
)

#note-box[_참고:_ OpenAI를 사용하는 경우, `ChatOpenAI`에 `base_url`과 `api_key`를 직접 지정하여 OpenAI API 형식의 서비스(vLLM, LMStudio, Ollama 등)에 접근할 수 있습니다.]

== 3.3 init_chat_model() 사용법

프로바이더 비교표를 확인했으니, 이제 실제로 `init_chat_model()`을 사용하여 모델을 생성해 봅니다.

`init_chat_model()`은 LangChain v1에서 제공하는 통합 모델 초기화 함수입니다.
프로바이더별 패키지가 설치되어 있으면, 문자열 하나로 모델을 생성할 수 있습니다.

이 함수의 핵심 장점은 _프로바이더 자동 감지_입니다. `"openai:gpt-5.4"`처럼 `프로바이더:모델명` 형식의 문자열을 전달하면, LangChain이 자동으로 해당 프로바이더의 ChatModel 클래스를 찾아 인스턴스를 생성합니다. 더 나아가, `configurable_fields`를 사용하면 _런타임에_ 프로바이더와 모델을 동적으로 전환할 수도 있어, A/B 테스트나 비용 최적화에 유용합니다.

OpenAI를 사용하는 경우에는 `ChatOpenAI`를 직접 사용하는 것이 더 간편합니다.

#tip-box[`init_chat_model()`은 `create_agent()`의 `model` 매개변수에 직접 전달할 수 있습니다. 또는 `create_agent(model="openai:gpt-5.4", ...)`처럼 문자열을 직접 전달하면 내부적으로 `init_chat_model()`이 호출됩니다.]

== 3.4 invoke(), stream(), batch() 패턴

모델 초기화 방법을 살펴봤으니, 이제 모델을 _호출_하는 세 가지 방법을 알아봅니다. LangChain v1의 모든 모델은 동일한 인터페이스를 따르므로, 프로바이더를 바꿔도 호출 코드는 그대로 유지됩니다.

LangChain v1의 모든 모델은 세 가지 호출 패턴을 지원합니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[메서드],
  text(weight: "bold")[설명],
  text(weight: "bold")[반환 타입],
  [`invoke()`],
  [단일 입력에 대한 단일 응답],
  [`AIMessage`],
  [`stream()`],
  [토큰 단위로 스트리밍 응답],
  [`Iterator[AIMessageChunk]`],
  [`batch()`],
  [여러 입력을 동시에 처리],
  [`List[AIMessage]`],
)

`stream()`이 반환하는 `AIMessageChunk`는 부분 응답을 나타내며, `+` 연산자로 결합할 수 있습니다. 예를 들어, 스트리밍 중 받은 여러 chunk를 `chunk1 + chunk2 + ...`로 합치면 최종 `AIMessage`와 동일한 내용이 됩니다. 각 메서드에는 비동기 버전(`ainvoke()`, `astream()`, `abatch()`)도 있어 asyncio 기반 애플리케이션에서 사용할 수 있습니다.

== 3.5 메시지 타입

호출 패턴을 이해했으니, 이제 호출의 입력과 출력을 구성하는 _메시지 객체_를 자세히 살펴봅니다. LangChain v1의 메시지 시스템은 대화의 각 역할을 명확히 구분합니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[메시지 타입],
  text(weight: "bold")[역할],
  text(weight: "bold")[설명],
  [`SystemMessage`],
  [시스템],
  [모델의 행동 방식을 지시하는 시스템 프롬프트],
  [`HumanMessage`],
  [사용자],
  [사용자가 입력하는 메시지],
  [`AIMessage`],
  [AI],
  [모델이 생성한 응답],
  [`ToolMessage`],
  [도구],
  [도구 실행 결과를 모델에 전달],
)

메시지 리스트를 구성하여 `model.invoke()`에 전달하면, 대화 맥락을 유지한 응답을 받을 수 있습니다.

각 메시지 타입은 고유한 속성을 가집니다. 특히 `AIMessage`는 단순한 `content` 외에도 다음과 같은 유용한 메타데이터를 포함합니다:
- `tool_calls`: 모델이 요청한 도구 호출 목록 (4장에서 상세히 다룸)
- `usage_metadata`: 토큰 사용량 정보 (`input_tokens`, `output_tokens`, `total_tokens`)
- `response_metadata`: 프로바이더별 응답 메타데이터 (모델 버전, finish reason 등)

`ToolMessage`는 도구 실행 결과를 모델에 전달하는 메시지입니다. `content`(결과 텍스트), `tool_call_id`(어떤 도구 호출에 대한 응답인지 식별), `name`(도구 이름)을 필수로 가지며, 선택적으로 `artifact` 필드를 통해 파일이나 이미지 같은 비텍스트 결과물을 첨부할 수 있습니다.

== 3.6 멀티모달 메시지 (이미지 입력)

텍스트 메시지를 넘어, 최신 모델들은 이미지·오디오·비디오·PDF 등 다양한 모달리티를 입력으로 받을 수 있습니다. LangChain v1은 이를 통합된 메시지 형식으로 지원합니다.

LangChain v1에서는 `HumanMessage`의 `content`에 텍스트와 이미지를 함께 전달할 수 있습니다.
이미지는 URL, base64 인코딩, 또는 파일 ID(일부 프로바이더) 중 하나로 전달하며, 비전(Vision)을 지원하는 모델에서만 동작합니다.

#tip-box[멀티모달 지원 범위는 프로바이더마다 다릅니다. OpenAI GPT-5.4는 이미지·PDF·오디오를, Google Gemini 2.5는 이미지·오디오·비디오를 지원합니다. 사용 전 해당 프로바이더의 문서를 확인하세요.]

#code-block(`````python
content = [
    {"type": "text", "text": "설명 텍스트"},
    {"type": "image_url", "image_url": {"url": "이미지_URL"}},
]
`````)

== 3.7 표준 출력 포맷 — `output_version="v1"`

LangChain v1부터 모든 프로바이더가 동일한 _content blocks_ 표준 직렬화를 제공합니다. `init_chat_model("openai:gpt-5.4", output_version="v1")` 처럼 명시하거나, 환경변수 `LC_OUTPUT_VERSION="v1"`을 설정하면 `AIMessage.content_blocks` 속성으로 텍스트·도구 호출·추론(reasoning)·사고 과정·인용을 통일된 스키마로 받을 수 있습니다.

#code-block(`````python
import os
from langchain.chat_models import init_chat_model

os.environ["LC_OUTPUT_VERSION"] = "v1"

model = init_chat_model("openai:gpt-5.4", output_version="v1")
result = model.invoke("LangChain v1을 한 줄로 설명하세요.")

for block in result.content_blocks:
    print(block["type"], "→", block.get("text", block))
`````)

스트리밍에서도 동일합니다. `chunk.content_blocks`로 부분 블록을 받아 UI에 매핑할 수 있습니다.

#code-block(`````python
for chunk in model.stream("멀티모달 입력을 설명해 줘."):
    for block in chunk.content_blocks:
        if block["type"] == "text":
            print(block["text"], end="")
`````)

#tip-box[`output_version="v1"`은 프로바이더 간 응답 차이를 흡수하는 권장 설정입니다. 기존 코드가 `result.content` 문자열에 의존한다면 호환 모드(`v0`)로도 동작하지만, 새 프로젝트는 v1을 사용하세요.]

== 3.8 토큰 사용량 추적 — `UsageMetadataCallbackHandler`

여러 단계에 걸친 에이전트 실행의 누적 토큰 사용량은 콜백 핸들러로 집계합니다. `UsageMetadataCallbackHandler`를 `config={"callbacks": [...]}`로 전달하면 모델 호출마다 `input_tokens` / `output_tokens` / `total_tokens`가 누적됩니다.

#code-block(`````python
from langchain_core.callbacks import UsageMetadataCallbackHandler

cb = UsageMetadataCallbackHandler()
result = agent.invoke(
    {"messages": [{"role": "user", "content": "15 × 27 + 3 은?"}]},
    config={"callbacks": [cb]},
)

print(cb.usage_metadata)
# {'gpt-5.4': {'input_tokens': 312, 'output_tokens': 48, 'total_tokens': 360, ...}}
`````)

== 3.9 Runtime Config — 실행 단위 옵션

`invoke()` / `stream()` 의 `config=` 인자는 단일 호출의 실행 메타데이터를 지정합니다. LangSmith 트레이스 이름, 태그·메타데이터, 도구·서브에이전트 동시 실행 한도 등을 한 번에 설정할 수 있습니다.

#code-block(`````python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "..."}]},
    config={
        "run_name": "monthly-report",
        "tags": ["batch-2025-05", "finance"],
        "metadata": {"user_id": "u-1234", "tenant": "acme"},
        "max_concurrency": 5,
    },
)
`````)

#tip-box[`run_name` / `tags` / `metadata`는 LangSmith UI에서 그대로 필터·검색에 사용됩니다. `max_concurrency`는 한 그래프 실행 내에서 병렬 도구·서브에이전트 호출 수를 제한합니다.]

== 3.10 Connection Resilience — `max_retries` / `timeout`

프로덕션 환경에서는 OpenAI·Anthropic 등 외부 API의 일시적 장애를 견뎌야 합니다. `init_chat_model()` 또는 `ChatOpenAI()`에 `max_retries`와 `timeout`을 지정하면 LangChain이 지수 백오프로 재시도합니다.

#code-block(`````python
from langchain.chat_models import init_chat_model

model = init_chat_model(
    "openai:gpt-5.4",
    max_retries=15,   # 기본값 6 → 장애 대비를 위해 상향
    timeout=120,      # 초 단위, 긴 응답 대비
)
`````)

#tip-box[재시도는 5xx 에러·연결 오류·`429 Too Many Requests`에서 발생합니다. 422 같은 클라이언트 오류는 재시도하지 않습니다. 한도를 너무 크게 잡으면 비용·지연이 증폭되므로, 보통 10\~20 범위에서 운영합니다.]

== 3.11 프롬프트 캐싱 — Implicit vs Explicit

긴 시스템 프롬프트나 RAG 컨텍스트를 반복 사용할 때 프롬프트 캐싱으로 입력 토큰 비용을 크게 줄일 수 있습니다.

- _Implicit caching_: 프로바이더가 동일한 프리픽스를 자동 인식하여 캐싱합니다. OpenAI `gpt-5.4`는 1024 토큰 이상 동일 프리픽스에서 자동 동작합니다.
- _Explicit caching_: Anthropic은 `prompt_cache_key`(또는 `cache_control` 블록)로 캐시 키를 명시합니다. LangChain은 `model_kwargs={"prompt_cache_key": "..."}`로 전달합니다.

#code-block(`````python
from langchain_anthropic import ChatAnthropic

model = ChatAnthropic(
    model="claude-sonnet-4-6",
    model_kwargs={"prompt_cache_key": "system-v3"},
)
`````)

#tip-box[캐시 적중 시 `usage_metadata.input_tokens_details`에 `cache_read`·`cache_creation` 값이 따로 표시됩니다. `UsageMetadataCallbackHandler`로 캐시 적중률을 운영 지표로 추적하세요.]

#chapter-summary-header()

이 노트북에서 학습한 핵심 내용을 정리합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  [`init_chat_model()`],
  [프로바이더 문자열로 모델을 통합 초기화],
  [`ChatOpenAI(base_url=...)`],
  [OpenAI 등 커스텀 엔드포인트 사용],
  [`invoke()`],
  [단일 입력 → 단일 응답],
  [`stream()`],
  [토큰 단위 스트리밍 응답],
  [`batch()`],
  [여러 입력을 동시에 처리],
  [`SystemMessage`],
  [시스템 지시사항 설정],
  [`HumanMessage`],
  [사용자 입력 메시지],
  [`AIMessage`],
  [AI 응답 메시지 (대화 이력용)],
  [`ToolMessage`],
  [도구 실행 결과 전달],
  [멀티모달 메시지],
  [`content`에 텍스트와 이미지를 함께 전달],
)

이 장에서는 모델 초기화와 메시지 시스템의 전체 구조를 파악했습니다. 모델이 _무엇을_ 할 수 있는지 이해했으니, 다음 장에서는 모델이 _어떻게_ 외부 세계와 상호작용하는지 --- `@tool` 데코레이터의 고급 기능, Pydantic 스키마, `ToolRuntime`, 그리고 `with_structured_output()`을 통한 출력 구조화 --- 를 깊이 있게 다룹니다.

