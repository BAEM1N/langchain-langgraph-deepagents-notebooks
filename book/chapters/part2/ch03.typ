// Auto-generated from 03_models_and_messages.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "모델과 메시지 시스템")

LangChain v1에서 다양한 LLM 모델을 설정하고, 메시지 타입을 활용하여 대화를 구성하는 방법을 학습합니다.

== 학습 목표
#learning-objectives([LangChain v1의 모델 초기화 방법(`init_chat_model`, `ChatOpenAI`)을 이해합니다], [`invoke()`, `stream()`, `batch()` 세 가지 호출 패턴을 학습합니다], [`SystemMessage`, `HumanMessage`, `AIMessage`, `ToolMessage` 등 메시지 타입을 이해합니다], [멀티모달 메시지(이미지 입력)를 구성하는 방법을 익힙니다])

== 3.1 환경 설정

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

== 3.2 모델 프로바이더 비교

LangChain v1은 `init_chat_model()`로 다양한 프로바이더의 모델을 통합된 방식으로 초기화할 수 있습니다.

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
  [`"openai:gpt-5.4"`],
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

`init_chat_model()`은 LangChain v1이 제공하는 통합 모델 초기화 함수입니다.
프로바이더별 패키지가 설치되어 있으면, 문자열 하나로 모델을 생성할 수 있습니다.

OpenAI를 쓸 때는 `ChatOpenAI`를 직접 사용하는 편이 더 간편합니다.

== 3.4 invoke(), stream(), batch() 패턴

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

== 3.5 메시지 타입

LangChain v1의 메시지 시스템은 대화의 각 역할을 명확히 구분합니다:

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

== 3.6 멀티모달 메시지 (이미지 입력)

LangChain v1에서는 `HumanMessage`의 `content`에 텍스트와 이미지를 함께 전달할 수 있습니다.
이미지는 URL 또는 base64 인코딩으로 전달하며, 비전(Vision)을 지원하는 모델에서만 동작합니다.

#code-block(`````python
content = [
    {"type": "text", "text": "설명 텍스트"},
    {"type": "image_url", "image_url": {"url": "이미지_URL"}},
]
`````)

== 3.7 토큰 사용량 집계 — `UsageMetadataCallbackHandler`

비용·쿼터를 추적하려면 `UsageMetadataCallbackHandler`를 콜백으로 붙입니다. 모델·에이전트 호출이 끝난 뒤 누적 토큰 수치를 dict로 받을 수 있어, 한 세션의 합산이나 모델별 비교에 바로 씁니다.

#code-block(`````python
from langchain_core.callbacks import UsageMetadataCallbackHandler

cb = UsageMetadataCallbackHandler()

# 단일 모델 호출에 콜백 부착
_ = model.invoke(
    "LangChain v1을 한 줄로 소개해 주세요.",
    config={"callbacks": [cb]},
)

# 동일 핸들러를 여러 호출에 재사용하면 누적 집계됩니다.
_ = model.invoke(
    "한 줄 더 추가해 주세요.",
    config={"callbacks": [cb]},
)

print("누적 usage_metadata:")
print(cb.usage_metadata)
`````)

== 3.8 Runtime Config — `run_name`·`tags`·`metadata`·`max_concurrency`

`config` 파라미터에는 단순 콜백만이 아니라 LangSmith·Langfuse에서 식별에 쓰는 메타데이터를 함께 실어 보낼 수 있습니다. `batch()` 호출에서는 `max_concurrency`로 동시 실행 상한을 정해 토큰 폭주를 막습니다.

#code-block(`````python
runtime_cfg = {
    "run_name": "intro-greeting",
    "tags": ["demo", "ch03"],
    "metadata": {"experiment": "v1_runtime_config"},
    "max_concurrency": 5,
}

# 단일 호출 — run_name/tags/metadata가 트레이스에 노출됩니다.
resp = model.invoke("한국어로 짧게 인사해 주세요.", config=runtime_cfg)
print("응답:", resp.content)

# batch — max_concurrency로 동시 실행 상한을 정합니다.
batched = model.batch(
    [f"숫자 {i}을 한글로 적어 주세요." for i in range(1, 7)],
    config=runtime_cfg,
)
for i, r in enumerate(batched, start=1):
    print(f"{i}: {r.content}")
`````)

== 3.9 연결 회복력 — `max_retries`와 `timeout`

프로덕션에서는 일시적 5xx, 레이트리밋, 네트워크 끊김이 잦습니다. `init_chat_model()`이나 `ChatOpenAI`에 `max_retries`와 `timeout`을 미리 잡아 두면 지수 백오프 재시도가 자동으로 끼어들고, 한 호출이 무한 대기에 빠지는 일도 막을 수 있습니다.

== 3.10 표준 출력 — `LC_OUTPUT_VERSION` / `output_version="v1"`

LangChain v1은 모델 응답을 `content_blocks`(텍스트·이미지·툴콜·추론 블록의 통일된 리스트)로 노출하는 표준 직렬화를 도입했습니다. 사용 방법은 두 가지입니다.

- 환경 변수 `LC_OUTPUT_VERSION=v1`을 띄우면 모든 모델이 자동으로 v1 포맷을 씁니다.
- 또는 모델 생성 시 `output_version="v1"`을 직접 지정합니다.

content_blocks를 쓰면 멀티모달·툴콜·추론 토큰을 일관된 방식으로 다룰 수 있어, 멀티 프로바이더 코드를 깔끔하게 유지할 수 있습니다.

== 3.11 프롬프트 캐싱 — Implicit vs Explicit

긴 시스템 프롬프트나 RAG 컨텍스트를 반복 호출할 때, 프롬프트 캐싱은 비용·지연을 크게 줄여 줍니다. 두 가지 흐름이 있습니다.

- _Implicit caching_ — 프로바이더(예: OpenAI gpt-5.4)가 동일 prefix를 자동 감지·재사용합니다. 호출자는 코드 변경이 거의 없어도 됩니다.
- _Explicit caching_ — Anthropic 계열은 `prompt_cache_key`나 `cache_control` 블록으로 캐싱 단위를 명시합니다. 동일 키 호출이 들어오면 캐시 hit가 보장됩니다.

캐시 히트 여부는 응답의 `usage_metadata.input_token_details.cache_read` 등에 잡힙니다. 위 `UsageMetadataCallbackHandler`로 함께 추적하면 운영 중 효과를 즉시 측정할 수 있습니다.

#chapter-summary-header()

이 노트북에서 학습한 핵심 내용:

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
  [멀티모달 메시지 + `output_version="v1"`],
  [`content_blocks`로 텍스트·이미지 통일 직렬화],
  [`UsageMetadataCallbackHandler`],
  [호출 누적 토큰·캐시 통계 수집],
  [Runtime config],
  [`run_name`·`tags`·`metadata`·`max_concurrency` 등 트레이스 친화 설정],
  [`max_retries`·`timeout`],
  [운영용 연결 회복력],
  [`LC_OUTPUT_VERSION=v1`],
  [환경 변수 한 줄로 표준 출력 적용],
  [Prompt caching],
  [implicit(자동)·explicit(`prompt_cache_key`)로 비용·지연 절감],
)
