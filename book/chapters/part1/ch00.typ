// Auto-generated from 00_setup.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(0, "환경 설정", subtitle: "시작하기 전에")

이 시리즈는 _LangChain → LangGraph → Deep Agents_ 순서로
AI 에이전트의 핵심만 빠르게 체험하는 입문 과정입니다.

== 학습 목표
#learning-objectives([`.env` 파일로 API 키를 안전하게 관리하는 방법을 익힌다], [`ChatOpenAI`로 LLM 모델을 초기화한다], [모델에 간단한 질문을 보내 정상 동작을 확인한다])

== 0.1 API 키 설정

프로젝트 루트의 `.env.example`을 `.env`로 복사하고, 아래 키를 입력하세요:

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

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
print("\u2713 API 키 로드 완료")
`````)
#output-block(`````
✓ API 키 로드 완료
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

== 0.2 모델 초기화

`ChatOpenAI`는 OpenAI 호환 LLM을 감싸는 LangChain 클래스입니다.
이후 노트북에서 이 `model` 객체를 계속 씁니다.

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")
print("\u2713 모델 설정 완료:", model.model_name)
`````)
#output-block(`````
✓ 모델 설정 완료: gpt-4.1
`````)

== 0.3 동작 확인

모델에 간단한 메시지를 보내 정상적으로 응답하는지 확인합니다.

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
  [`ChatOpenAI(model="gpt-4.1")`],
  [테스트],
  [`model.invoke("...")` → 응답 확인],
)
