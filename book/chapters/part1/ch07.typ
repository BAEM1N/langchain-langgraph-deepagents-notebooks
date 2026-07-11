// Auto-generated from 07_mini_project.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "미니 프로젝트", subtitle: "검색 + 요약 에이전트")

입문 과정에서 배운 내용을 조합하여, Tavily 웹 검색 도구를 갖춘 리서치 에이전트를 만듭니다.

== 학습 목표
#learning-objectives([Tavily 검색 도구를 직접 정의한다], [Deep Agents로 리서치 에이전트를 만든다], [스트리밍으로 에이전트 실행 과정을 실시간 관찰한다], [LangChain 에이전트로도 같은 작업을 수행하여 비교한다])

== 7.1 환경 설정

이 노트북에는 `TAVILY_API_KEY`가 필요합니다. https://tavily.com 에서 무료로 발급받을 수 있습니다.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY 필요!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY 필요!"

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
print("\u2713 환경 준비 완료")
`````)
#output-block(`````
✓ 환경 준비 완료
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

== 7.2 검색 도구 정의

Tavily 클라이언트를 감싸는 검색 함수를 만듭니다.
_docstring_과 _타입 힌트_가 에이전트에 도구 스키마를 알려줍니다.

_도구 함수 작성 규칙:_

`create_deep_agent()`의 `tools` 파라미터에 전달할 검색 함수를 정의합니다. Deep Agents는 함수의 docstring을 도구 설명으로, 타입 힌트를 파라미터 스키마로 자동 변환합니다. 따라서:

- _docstring_: 에이전트가 "이 도구를 언제 써야 하는지" 판단하는 근거가 됩니다. 명확하고 구체적으로 적으세요.
- _타입 힌트_: 에이전트가 올바른 타입의 인자를 전달하도록 합니다. `Literal` 타입을 쓰면 허용 값을 제한할 수 있습니다.
- _Args 섹션_: 각 파라미터의 용도를 설명하면 에이전트가 더 정확하게 인자를 고릅니다.

#code-block(`````python
from typing import Literal
from tavily import TavilyClient

tavily = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

def internet_search(
    query: str,
    max_results: int = 3,
    topic: Literal["general", "news"] = "general",
) -> dict:
    """인터넷에서 정보를 검색합니다.

    Args:
        query: 검색 쿼리
        max_results: 최대 결과 수
        topic: 검색 주제 카테고리
    """
    return tavily.search(query, max_results=max_results, topic=topic)

print("\u2713 검색 도구 준비 완료")
`````)
#output-block(`````
✓ 검색 도구 준비 완료
`````)

== 7.3 Deep Agents 리서치 에이전트

`create_deep_agent()`에 검색 도구와 시스템 프롬프트를 전달합니다.

_에이전트의 자동 워크플로:_

에이전트는 사용자 요청을 받으면 다음 과정을 자동으로 수행합니다:

+ _계획 수립_: 빌트인 `write_todos` 도구로 작업을 단계별로 나눕니다.
+ _리서치 수행_: 전달된 검색 도구(`internet_search`)로 웹에서 정보를 모읍니다.
+ _컨텍스트 관리_: 필요하면 파일 시스템 도구(`write_file`, `read_file`)로 중간 결과를 저장해 토큰 한도를 관리합니다.
+ _결과 종합_: 수집한 정보를 분석하고 일관된 보고서로 정리합니다.

복잡한 작업에서는 전문 서브에이전트를 만들어 특정 하위 작업의 컨텍스트를 격리할 수도 있습니다.

#code-block(`````python
from deepagents import create_deep_agent

research_agent = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="당신은 전문 리서처입니다. 웹을 검색한 후 결과를 한국어로 요약하세요.",
)
print("\u2713 리서치 에이전트 생성 완료")
`````)
#output-block(`````
✓ 리서치 에이전트 생성 완료
`````)

#code-block(`````python
result = research_agent.invoke(
    {
        "messages": [
            {
                "role": "user",
                "content": "LangGraph가 무엇인지 검색해서 3줄로 요약해 주세요."
            }
        ]
    },
    config=lf_config,
)

print(result["messages"][-1].content)
`````)
#output-block(`````
LangGraph는 LangChain 생태계의 라이브러리로, 노드와 엣지 기반의 그래프 구조를 통해 복잡한 워크플로우 및 데이터 흐름을 쉽게 설계·관리할 수 있습니다.
상태 관리 기능이 강력해서 각 노드의 상태를 효과적으로 추적·제어할 수 있으며, 멀티 에이전트 시스템과 순환 그래프도 지원합니다.
이를 통해 다양한 LLM 기반 애플리케이션의 복잡한 작업 흐름과 에이전트 간 상호작용을 효율적으로 구축할 수 있습니다.
`````)

== 7.4 스트리밍으로 과정 관찰

`stream(mode="updates")`로 에이전트가 어떤 단계를 거치는지 실시간으로 확인합니다.

_LangGraph 스트리밍 시스템:_

LangGraph는 완전한 응답이 준비되기 전에 진행 상황을 점진적으로 보여줘 애플리케이션의 반응성을 높이는 스트리밍 시스템을 제공합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[스트림 모드],
  text(weight: "bold")[용도],
  [`values`],
  [각 그래프 단계 후 _전체 상태_를 스트리밍],
  [`updates`],
  [각 단계 후 _상태 변경분만_ 스트리밍],
  [`messages`],
  [LLM 토큰을 메타데이터와 함께 스트리밍],
  [`custom`],
  [노드에서 사용자 정의 데이터를 스트리밍],
  [`debug`],
  [포괄적인 실행 정보를 스트리밍],
)

`stream()` (동기) 또는 `astream()` (비동기) 메서드로 스트리밍에 접근하며, 여러 모드를 리스트로 넘겨 동시에 쓸 수도 있습니다. 아래 예제에서는 `updates` 모드로 에이전트의 각 단계(도구 호출, 최종 응답)를 실시간으로 출력합니다.

#code-block(`````python
for chunk in research_agent.stream(
    {
        "messages": [
            {
                "role": "user",
                "content": "LangChain v1의 주요 변경사항을 검색해서 요약해 주세요."
            }
        ]
    },
    stream_mode="updates",
    config=lf_config,
):
    for node_name, node_data in chunk.items():
        if not node_data:
            continue

        msgs = node_data.get("messages", [])

        if hasattr(msgs, "value"):
            msgs = msgs.value

        if not msgs:
            continue

        last = msgs[-1]

        if hasattr(last, "tool_calls") and last.tool_calls:
            for tc in last.tool_calls:
                print(
                    f"[도구 호출] {tc['name']}({tc['args'].get('query', '')[:50]})"
                )

        elif hasattr(last, "content") and last.content and not hasattr(last, "tool_call_id"):
            content = last.content if isinstance(last.content, str) else str(last.content)

            if content.strip():
                print(f"\n[최종 응답]\n{content}")
`````)
#output-block(`````
[최종 응답]
LangChain v1의 주요 변경사항을 검색해서 요약해 주세요.

[도구 호출] internet_search(LangChain v1 주요 변경사항)


[최종 응답]
LangChain v1의 주요 변경사항 요약:

1. create_agent의 표준화 및 강화
   - agent 생성이 더 간단해지고, 미들웨어 기반 구조로 커스터마이즈와 신뢰성 강화됨
   - 기존 langgraph의 ‘create_react_agent’보다 심플하지만 매우 확장성 있게 구현 가능

2. 미들웨어 시스템 도입
   - 중요한 미들웨어(PII정보 마스킹, 대화 이력 요약, Human-in-the-loop 등)로 agent 실행 중 각 단계를 제어 가능
   - 커스텀 미들웨어 제작 및 연결 포인트 다양화
   - OpenAI 콘텐츠 필터 등 moderation 미들웨어 추가 제공

3. 구조화된 출력 개선
   - 다양한 LLM, 프로바이더에서 일관성 있게 작동하도록 메시지 구조 표준화(content_blocks 등)

4. Model profile 기반 context-aware 처리
   - 모델 프로필 시스템 도입: 각 LLM의 동작 특성을 반영해 agent 동작 및 요약 정책을 더 세밀하게 조절

5. 에이전트 런타임(Context) 및 관리 강화
   - 정적/동적 Context와 장기 메모리 등 Runtime 객체 구분 및 활용성 강화
   - 더 안정적이고 장기적인 세션, 신뢰할 수 있는 agent 동작 지원

6. 기타 주요 업데이트
   - langchain-core, partner 패키지 구조 개편
... (truncated)
`````)

== 7.5 LangChain 에이전트로 비교

같은 검색 도구를 LangChain `create_agent()`로도 사용해 봅니다.

_LangChain 에이전트와의 차이점:_

LangChain의 `create_agent()`는 모델과 도구를 받아 간단한 ReAct 에이전트를 만듭니다. Deep Agents와 비교하면:

- _LangChain_: 도구 호출 에이전트의 기본 형태. 빠른 프로토타이핑에 맞지만, 태스크 플래닝이나 파일 시스템 관리 같은 기능은 직접 구현해야 합니다.
- _Deep Agents_: 플래닝(`write_todos`), 파일 관리, 서브에이전트 위임이 기본 내장되어 있어, 복잡한 멀티스텝 작업에 더 잘 맞습니다.

`@tool` 데코레이터를 쓰면 LangChain 도구 인터페이스에 맞게 함수를 변환할 수 있습니다. 시스템 프롬프트와 도구 리스트를 `create_agent()`에 전달하는 패턴은 Deep Agents와 같습니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def search_web(query: str) -> dict:
    """웹에서 정보를 검색합니다."""
    return tavily.search(query, max_results=3)

lc_agent = create_agent(
    model=model,
    tools=[search_web],
    system_prompt="당신은 리서치 어시스턴트입니다. 한국어로 답변하세요.",
)

result = lc_agent.invoke(
    {"messages": [{"role": "user", "content": "LangChain v1의 주요 특징을 검색해서 알려주세요."}]},
    config=lf_config,
)
print(result["messages"][-1].content)
`````)
#output-block(`````
LangChain v1의 주요 특징은 다음과 같습니다:

1. 다양한 LLM(대형 언어 모델) 표준화 지원: OpenAI, Google, Anthropic 등 여러 LLM 제공자를 표준화된 인터페이스로 쉽게 사용할 수 있습니다.
2. 에이전트 생성의 표준화: create_agent 함수를 통해 쉽고 유연하게 에이전트를 만들 수 있으며, LangGraph 기반의 신뢰성 높은 장기 실행을 지원합니다.
3. 미들웨어(Middleware) 도입: 에이전트 실행의 각 단계마다 다양한 미들웨어(예: 개인정보 자동 마스킹, 대화 기록 요약, 인증 절차 등)를 자유롭게 삽입해 확장성과 커스터마이징이 매우 뛰어납니다.
4. 메시지 구조 표준화(content_blocks): 다양한 LLM 제공자 간 일관된 메시지 컨텐츠 표현이 가능하도록 표준 메시지 구조를 도입했습니다.
5. 간결한 패키지 구조: 사용성과 유지보수를 높이기 위해 패키지 구성을 정비하고, classic 모듈(@langchain/classic)로 핵심 기능을 집중시켰습니다.
6. 고도화된 에이전트 관리: 에이전트가 도구를 호출하고 결과를 바탕으로 반복적으로 의사결정 및 실행을 하며, 각 단계에 후킹 포인트(hook)가 있어 자유롭게 맞춤형 동작을 구현할 수 있습니다.

이 밖에도 안정성, 구조화된 출력 관리 등 다양한 부분에서 개선이 이루어졌습니다.
`````)

#chapter-summary-header()

이 미니 프로젝트에서 사용한 기술:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기술],
  text(weight: "bold")[출처],
  [`ChatOpenAI` + `load_dotenv`],
  [00_setup],
  [메시지 역할, 스트리밍],
  [01_llm_basics],
  [`\@tool`, `create_agent()`],
  [02_langchain_basics],
  [`InMemorySaver`, `thread_id`],
  [03_langchain_memory],
  [`StateGraph`, `compile()`],
  [04_langgraph_basics],
  [`create_deep_agent()`],
  [05_deep_agents_basics],
)
