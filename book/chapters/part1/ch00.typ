// Auto-generated from 00_setup.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(0, "환경 설정", subtitle: "시작하기 전에")

이 책은 AI 에이전트 개발을 세 가지 프레임워크를 통해 단계적으로 학습하는 과정입니다. *LangChain*은 100개 이상의 LLM 프로바이더와 도구를 연결하는 인터페이스 레이어를 제공하고, *LangGraph*는 상태 기반 워크플로 오케스트레이션을 추가하며, *Deep Agents*는 이 모든 것을 사전 구축된 에이전트 하네스로 감싸줍니다. 세 프레임워크는 동일한 모델 인터페이스를 공유하므로, 이 장에서 설정하는 환경은 책 전체에 걸쳐 그대로 사용됩니다.

이 모든 것을 시작하려면 먼저 개발 환경을 구성해야 합니다.

#learning-header()
#learning-objectives([`.env` 파일로 API 키를 안전하게 관리하는 방법을 익힌다], [`ChatOpenAI`로 LLM 모델을 초기화한다], [모델에 간단한 질문을 보내 정상 동작을 확인한다])

== 0.1 API 키 설정

LLM API를 호출하려면 프로바이더별 API 키가 필요합니다. 프로젝트 루트의 `.env.example`을 `.env`로 복사하고, 발급받은 키를 입력하세요.

#code-block(`````python
OPENAI_API_KEY=sk-...
TAVILY_API_KEY=tvly-...   # 선택
`````)

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[키],
  text(weight: "bold")[용도],
  text(weight: "bold")[발급처],
  [`OPENAI_API_KEY`],
  [LLM 호출 (필수)],
  [https://platform.openai.com/api-keys],
  [`TAVILY_API_KEY`],
  [웹 검색 도구 (선택)],
  [https://tavily.com],
)

#warning-box[`.env` 파일은 절대 버전 관리 시스템에 커밋하지 마세요. 프로젝트의 `.gitignore`에 `.env`가 포함되어 있는지 반드시 확인하세요. 프로덕션 환경에서는 `.env` 파일 대신 AWS Secrets Manager, GCP Secret Manager 같은 전용 시크릿 매니저를 사용하는 것이 권장됩니다.]

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
print("\u2713 API 키 로드 완료")
`````)

`load_dotenv(override=True)`에서 `override=True` 매개변수는 `.env` 파일의 값이 시스템 환경 변수보다 우선하도록 합니다. 프로젝트마다 다른 API 키나 설정을 사용해야 할 때 유용합니다.
#output-block(`````
✓ API 키 로드 완료
`````)

=== Observability (관측 가능성) 설정

에이전트는 LLM 호출, 도구 실행, 상태 전이 등 여러 단계를 거쳐 작업을 수행합니다. 이 과정에서 어떤 단계에서 오류가 발생했는지, 각 단계에 토큰이 얼마나 소비되었는지 파악하려면 _트레이싱(tracing)_ 이 필수적입니다. LangSmith는 `LANGSMITH_TRACING=true` 환경 변수 하나만 설정하면 코드 수정 없이 자동으로 활성화되며, Langfuse는 오픈소스 대안으로 콜백 핸들러를 통해 동작합니다.

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

API 키가 준비되었으니, 이제 이 키를 사용할 LLM 모델을 초기화합니다.

== 0.2 모델 초기화

LangChain에서 모델을 초기화하는 방법은 두 가지입니다. 첫 번째는 프로바이더별 클래스를 직접 사용하는 방식으로, `ChatOpenAI`가 대표적입니다. `temperature`, `max_tokens`, `timeout`, `max_retries`(기본값: 6) 등 프로바이더 고유 매개변수에 직접 접근할 수 있어 세밀한 제어가 가능합니다.

두 번째는 `init_chat_model()` 팩토리 함수로, 모델 이름에서 프로바이더를 자동 감지합니다. 런타임에 프로바이더를 전환해야 하는 경우에 유용하지만, 이 책에서는 명시성을 위해 `ChatOpenAI`를 사용합니다.

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")
print("\u2713 모델 설정 완료:", model.model_name)
`````)
#output-block(`````
✓ 모델 설정 완료: gpt-5.4
`````)

#tip-box[프로바이더를 동적으로 전환하고 싶다면 `from langchain.chat_models import init_chat_model`을 사용하세요. `init_chat_model("gpt-5.4")`은 모델 이름에서 OpenAI를 자동 감지하고, `init_chat_model("claude-sonnet-4-6")`은 Anthropic을 자동 감지합니다.]

모델 객체가 준비되었습니다. 실제로 동작하는지 간단한 호출로 확인해 봅시다.

== 0.3 동작 확인

`model.invoke()`는 단순한 문자열이 아니라 `AIMessage` 객체를 반환합니다. `.content` 속성으로 응답 텍스트를 얻을 수 있고, `.usage_metadata`에는 토큰 사용량(`input_tokens`, `output_tokens`, `total_tokens`)이, `.response_metadata`에는 모델 버전이나 종료 사유 같은 프로바이더별 메타데이터가 담겨 있습니다. 이 메시지 체계는 다음 장에서 자세히 다룹니다.

#code-block(`````python
response = model.invoke("안녕하세요! 한 문장으로 답해주세요.", config=lf_config)
print("\u2713 모델 응답:", response.content)
`````)
#output-block(`````
✓ 모델 응답: 안녕하세요! 무엇을 도와드릴까요?
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [환경 변수],
  [`load_dotenv()`로 `.env` 파일 로드],
  [모델],
  [`ChatOpenAI(model="gpt-5.4")`],
  [테스트],
  [`model.invoke("...")` → `AIMessage` 객체 반환 확인],
)

환경이 정상적으로 구성되었습니다. 다음 장에서는 이 `model` 객체를 사용하여 LLM의 메시지 시스템과 호출 방식을 자세히 살펴봅니다.

