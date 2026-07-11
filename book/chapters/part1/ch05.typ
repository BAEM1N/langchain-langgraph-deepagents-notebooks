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

== 5.2 에이전트 생성

`create_deep_agent()`는 LangChain 모델을 받아, 파일 읽기/쓰기/검색 등의 _빌트인 도구_가 자동으로 포함된 에이전트를 반환합니다.
반환 타입이 LangGraph의 `CompiledStateGraph`이므로 `invoke()`, `stream()` 등을 그대로 쓸 수 있습니다.

_Deep Agents란?_

Deep Agents는 에이전트 개발을 단순하게 만들기 위해 설계된 프레임워크로, _에이전트 하네스(harness)_ 역할을 합니다. LangChain의 기본 에이전트 컴포넌트 위에 구축되며, 실행 관리에는 LangGraph를 씁니다.

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
  [`write_todos` 도구로 복잡한 문제를 관리 가능한 단계로 자동 분해],
  [_컨텍스트 관리_],
  [파일 시스템 도구(`write_file`, `read_file`)로 토큰 한도를 넘지 않고 대량 데이터 처리],
  [_유연한 저장소_],
  [인메모리, 로컬 디스크, 영구 저장소, 샌드박스 환경 등 플러거블 백엔드 지원],
  [_서브에이전트 위임_],
  [특정 하위 작업을 위한 전문 서브에이전트를 만들어 컨텍스트 격리],
  [_영구 메모리_],
  [LangGraph 메모리 인프라로 여러 대화에 걸쳐 정보를 유지],
)

_에이전트 생성 방법:_

`create_deep_agent()`에 모델, 도구, 시스템 프롬프트를 전달하면 됩니다. 도구 호출을 지원하는 모델이 필요하며, Anthropic, OpenAI 등 다양한 프로바이더를 쓸 수 있습니다.

#code-block(`````python
from deepagents import create_deep_agent

agent = create_deep_agent(model=model)
print(f"\u2713 에이전트 생성 완료 (타입: {type(agent).__name__})")
`````)
#output-block(`````
✓ 에이전트 생성 완료 (타입: CompiledStateGraph)
`````)

#code-block(`````python
result = agent.invoke(
    {
        "messages": [
            {
                "role": "user",
                "content": "안녕하세요! 어떤 도구를 사용할 수 있나요? 목록만 간단히 알려주세요."
            }
        ]
    },
    config=lf_config,
)

print(result["messages"][-1].content)
`````)
#output-block(`````
사용 가능한 도구 목록입니다:

1. 파일시스템 도구: ls, read_file, write_file, edit_file, glob, grep
2. 할 일 관리: write_todos
3. 태스크(서브에이전트) 실행: task
4. 병렬 도구 실행: multi_tool_use.parallel

필요한 도구의 기능 등, 더 자세한 설명이 필요하시면 말씀해 주세요!
`````)

== 5.3 커스텀 도구 추가

Python 함수에 _docstring_과 _타입 힌트_를 작성하면 그대로 도구가 됩니다.

_커스텀 도구의 동작 원리:_

커스텀 도구는 일반 Python 함수로 작성하며, 다음 두 가지가 자동으로 변환됩니다:

- _docstring_ → 도구 설명 (에이전트가 이 도구를 언제 써야 하는지 판단하는 근거)
- _타입 힌트_ → 파라미터 스키마 (에이전트가 올바른 인자를 넘기는 데 사용)

`create_deep_agent()`의 `tools` 파라미터에 함수 리스트를 전달하면, 빌트인 도구(파일 읽기/쓰기, todo 등)와 함께 에이전트 도구 목록에 추가됩니다. `system_prompt` 파라미터로 에이전트의 행동 방식을 지정할 수도 있습니다.

#code-block(`````python
def greet(name: str) -> str:
    """이름으로 인사합니다."""
    return f"안녕하세요, {name}님! Deep Agents에 오신 것을 환영합니다."

custom_agent = create_deep_agent(
    model=model,
    tools=[greet],
    system_prompt="당신은 친절한 어시스턴트입니다. 누군가 자기소개를 하면 greet 도구를 사용하세요.",
)

result = custom_agent.invoke(
    {"messages": [{"role": "user", "content": "제 이름은 앨리스입니다."}]},
    config=lf_config,
)
print(result["messages"][-1].content)
`````)
#output-block(`````
안녕하세요, 앨리스님! Deep Agents에 오신 것을 환영합니다. 무엇을 도와드릴까요?
`````)

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
