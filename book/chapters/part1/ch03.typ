// Auto-generated from 03_langchain_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "LangChain 대화", subtitle: "멀티턴 메모리")

에이전트가 이전 대화를 기억하도록 `InMemorySaver`를 연결합니다.

== 학습 목표
#learning-objectives([`InMemorySaver`로 대화 상태를 저장한다], [`thread_id`로 대화 세션을 구분한다], [에이전트가 이전 문맥을 기억하는 멀티턴 대화를 실행한다])

== 3.1 환경 설정

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

== 3.2 메모리 없는 에이전트의 한계

기본 에이전트는 _상태를 저장하지 않습니다_. 매번 새로운 대화로 취급합니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def add(a: int, b: int) -> int:
    """두 수를 더합니다."""
    return a + b

# 메모리 없는 에이전트
agent_no_mem = create_agent(model=model, tools=[add])

r1 = agent_no_mem.invoke({"messages": [{"role": "user", "content": "3 + 4는 얼마인가요?"}]}, config=lf_config)
print("1차:", r1["messages"][-1].content)

# 이전 결과를 기억하지 못함
r2 = agent_no_mem.invoke({"messages": [{"role": "user", "content": "이전 결과에 10을 더하세요."}]}, config=lf_config)
print("2차:", r2["messages"][-1].content)
`````)
#output-block(`````
1차: 3 + 4는 7입니다.

2차: 이전 결과가 무엇인지 알려주시면, 거기에 10을 더해드릴 수 있습니다. 이전 결과를 입력해 주세요!
`````)

== 3.3 InMemorySaver로 메모리 추가

`checkpointer`를 지정하면 에이전트가 대화 히스토리를 저장합니다.
`thread_id`로 대화 세션을 구분합니다.

_단기 메모리(Short-term Memory)_란 단일 대화 스레드 안에서 이전 상호작용의 정보를 유지하는 기능입니다. 여러 번의 사용자 응답을 처리하는 에이전트라면 꼭 필요합니다.

구현 방법:
- `InMemorySaver()`를 `checkpointer` 파라미터로 전달해 메모리를 켭니다.
- `thread_id`로 서로 다른 대화 세션을 구분합니다. 같은 `thread_id`를 쓰면 이전 내용을 이어서 기억합니다.
- 프로덕션에서는 `PostgresSaver` 같은 DB 기반 체크포인터로 영속성을 확보합니다.

대화가 길어지면 토큰 제한을 초과할 수 있으므로, 메시지 트리밍(trimming), 삭제(deletion), 요약(summarization) 등으로 히스토리를 관리하세요.

#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    model=model,
    tools=[add],
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": "session-1"}}
print("\u2713 메모리 에이전트 생성 완료")
`````)
#output-block(`````
✓ 메모리 에이전트 생성 완료
`````)

#code-block(`````python
# 첫 번째 질문
r1 = agent.invoke(
    {"messages": [{"role": "user", "content": "7 + 8은 얼마인가요?"}]},
    config={**config, **lf_config},
)
print("1차:", r1["messages"][-1].content)

# 이전 대화를 기억하는 두 번째 질문
r2 = agent.invoke(
    {"messages": [{"role": "user", "content": "이제 그 결과에 2를 곱하세요."}]},
    config={**config, **lf_config},
)
print("2차:", r2["messages"][-1].content)
`````)
#output-block(`````
1차: 7 + 8은 15입니다.

2차: 15 × 2 = 30입니다.
`````)

== 3.4 스트리밍으로 실시간 확인

`agent.stream()`으로 에이전트의 각 단계를 실시간으로 관찰합니다.

에이전트 스트리밍은 오래 실행되는 에이전트의 중간 단계를 실시간으로 들여다볼 때 유용합니다. `stream_mode="updates"`를 쓰면 각 노드(모델 호출, 도구 실행 등)의 업데이트를 하나씩 받아볼 수 있어서, 에이전트가 어떤 도구를 호출했는지, 어떤 결과를 받았는지 단계별로 확인할 수 있습니다.

#code-block(`````python
config2 = {"configurable": {"thread_id": "session-2"}}

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "100과 200을 더한 다음 결과에 50을 더하세요."}]},
    config={**config2, **lf_config},
    stream_mode="updates",
):
    for node_name, update in chunk.items():
        if "messages" in update:
            last = update["messages"][-1]
            if hasattr(last, "content") and last.content:
                print(f"[{node_name}] {last.content[:200]}")
`````)
#output-block(`````
[tools] 300

[tools] 350

[model] 100과 200을 더하면 300이고, 여기에 50을 더하면 최종 결과는 350입니다.
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
  [`InMemorySaver`],
  [메모리 내 대화 상태 저장 (체크포인터)],
  [`thread_id`],
  [대화 세션 구분 키],
  [`checkpointer=`],
  [`create_agent()`에 체크포인터 전달],
  [`stream(mode="updates")`],
  [에이전트 실행 단계를 실시간 확인],
)
