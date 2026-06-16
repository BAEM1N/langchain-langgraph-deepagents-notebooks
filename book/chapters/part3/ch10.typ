// Auto-generated from 10_production.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "프로덕션", subtitle: "테스트, 배포, 관측성")

== 학습 목표
LangGraph 앱을 테스트, 배포, 모니터링하는 방법을 알아봅니다.

== 10.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 10.2 앱 구조 — langgraph.json

- `langgraph.json`: 그래프 정의, 의존성, 환경 변수 설정
- `langgraph dev`: 로컬 개발 서버 실행

#code-block(`````python
import json

config = {
    "dependencies": ["."],
    "graphs": {
        "agent": "./agent.py:graph"
    },
    "env": ".env"
}
print("langgraph.json 예시:")
print(json.dumps(config, indent=2))
print()
print("명령어:")
print("  $ pip install 'langgraph-cli[inmem]'")
print("  $ langgraph dev  # http://localhost:2024에서 로컬 서버 시작")
`````)
#output-block(`````
langgraph.json 예시:
{
  "dependencies": [
    "."
  ],
  "graphs": {
    "agent": "./agent.py:graph"
  },
  "env": ".env"
}

명령어:
  $ pip install 'langgraph-cli[inmem]'
  $ langgraph dev  # http://localhost:2024에서 로컬 서버 시작
`````)

== 10.3 LangGraph Studio — 시각적 디버깅 도구

Studio는 `langgraph dev` 실행 시 자동으로 제공됩니다.

_Key Features (7가지):_
+ _Real-time Visualization_ — 프롬프트, 도구 호출, 결과, 최종 출력 등 모든 단계가 실시간으로 렌더링
+ _Interactive Testing_ — 다양한 입력으로 실행하고 중간 상태를 UI에서 직접 검사
+ _Hot-reloading_ — 프롬프트나 도구 시그니처 수정이 서버 재시작 없이 즉시 반영
+ _Trace Inspection_ — 프롬프트, 도구 인자, 반환값, 토큰 수, 지연 시간을 추적
+ _Exception Capture_ — 예외 발생 시 주변 상태와 함께 캡처되어 디버깅에 활용
+ _Thread Replay_ — 대화 스레드를 임의 지점부터 다시 실행하여 변경 검증
+ _Optional Tracing_ — `LANGSMITH_TRACING=false`로 외부 전송 없이 로컬 실행만 유지

_사용 방법:_
#code-block(`````bash
$ langgraph dev
# https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024 에서 접속
# Safari 사용자는 langgraph dev --tunnel 사용
`````)

== 10.4 Agent Chat UI

Agent Chat UI는 LangChain 에이전트용 Next.js 채팅 인터페이스입니다.
`create_agent`로 만든 에이전트와 바로 연동됩니다.

_설치 — npx 사용 (권장):_
#code-block(`````bash
$ npx create-agent-chat-app --project-name my-chat-ui
$ cd my-chat-ui
$ pnpm install
$ pnpm dev
`````)

_설치 — Git clone:_
#code-block(`````bash
$ git clone https://github.com/langchain-ai/agent-chat-ui.git
$ cd agent-chat-ui
$ pnpm install
$ pnpm dev
`````)

_Hosted 버전:_
https://agentchat.vercel.app 에 접속해 에이전트 deployment URL이나 로컬 서버 주소를 입력합니다.

_연결 정보:_
- _Graph ID_ — `langgraph.json`의 `graphs` 섹션 키
- _Deployment URL_ — 에이전트 서버 주소(로컬은 `http://localhost:2024`)
- _LangSmith API key_ — 선택(로컬 서버 사용 시 불필요)

_기능:_
- 실시간 스트리밍 채팅
- 도구 호출 / 결과 렌더링
- Time-travel debugging, state forking
- Generative UI 지원
- Human-in-the-loop 인터럽트 감지/처리

== 10.5 테스트 — 결정론적 에이전트 테스트

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

# Graph to test
class TestState(TypedDict):
    input: str
    output: str


def process(state: TestState) -> dict:
    return {"output": state["input"].upper()}


builder = StateGraph(TestState)

builder.add_node("process", process)
builder.add_edge(START, "process")
builder.add_edge("process", END)

graph = builder.compile()


# Unit tests
def test_process():
    result = graph.invoke({"input": "hello"})

    assert result["output"] == "HELLO", f"HELLO 예상, {result['output']} 반환됨"

    print("  OK test_process")


def test_empty_input():
    result = graph.invoke({"input": ""})

    assert result["output"] == "", f"빈 문자열 예상, {result['output']} 반환됨"

    print("  OK test_empty_input")


print("테스트 실행 중:")

test_process()
test_empty_input()

print("모든 테스트 통과!")
`````)
#output-block(`````
테스트 실행 중:
  OK test_process
  OK test_empty_input
모든 테스트 통과!
`````)

== 10.6 LLM 에이전트 테스트 — GenericFakeChatModel 사용

#code-block(`````python
from langchain_core.language_models import GenericFakeChatModel
from langchain.messages import AIMessage, HumanMessage, AnyMessage
from langgraph.graph import StateGraph, START, END, MessagesState

# Deterministic fake model
fake_model = GenericFakeChatModel(
    messages=iter(
        [
            AIMessage(content="The answer is 42."),
        ]
    )
)

def chatbot(state: MessagesState) -> dict:
    return {
        "messages": [fake_model.invoke(state["messages"])]
    }

builder = StateGraph(MessagesState)

builder.add_node("chatbot", chatbot)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

test_graph = builder.compile()

result = test_graph.invoke(
    {
        "messages": [HumanMessage(content="테스트")]
    }
)

assert "42" in result["messages"][-1].content

print("GenericFakeChatModel 테스트 통과!")
print(f"  응답: {result['messages'][-1].content}")
`````)
#output-block(`````
GenericFakeChatModel 테스트 통과!
  응답: The answer is 42.
`````)

== 10.7 배포 옵션

_1. LangSmith Cloud (managed):_

GitHub 저장소를 LangSmith Deployments에서 연결하면 자동 배포됩니다(약 15분 소요).
배포 완료 후 Studio 버튼으로 그래프를 띄우고, Deployment details에서 API URL을 복사합니다.

_2. Self-hosted Docker:_
#code-block(`````bash
$ langgraph build -t my-agent
$ docker run -p 2024:2024 my-agent
`````)

_3. API 호출 (배포 후):_

#code-block(`````python
from langgraph_sdk import get_sync_client

client = get_sync_client(url="your-deployment-url", api_key="your-langsmith-api-key")

for chunk in client.runs.stream(
    None,                                              # thread_id=None → stateless run
    "agent",                                           # langgraph.json의 graph name
    input={"messages": [{"role": "human", "content": "What is LangGraph?"}]},
    stream_mode="updates",
):
    print(f"Receiving new event of type: {chunk.event}...")
    print(chunk.data)
`````)

_REST 호출:_
#code-block(`````bash
curl -s --request POST \
    --url <DEPLOYMENT_URL>/runs/stream \
    --header 'Content-Type: application/json' \
    --header "X-Api-Key: <LANGSMITH API KEY>" \
    --data '{"assistant_id": "agent", "input": {"messages": [{"role": "human", "content": "What is LangGraph?"}]}, "stream_mode": "updates"}'
`````)

== 10.8 관측성 — LangSmith 트레이싱

_환경 변수 (`.env`):_
#code-block(`````python
LANGSMITH_TRACING=true
LANGSMITH_API_KEY=lsv2-...
LANGSMITH_PROJECT=my-agent-project   # 선택, 미설정 시 'default'
`````)

`LANGSMITH_TRACING` / `LANGSMITH_API_KEY` 두 개는 필수, `LANGSMITH_PROJECT`는 선택입니다.

_자동 추적 항목:_
- 각 노드 실행 시간
- LLM 입출력, 토큰 사용량
- 도구 호출 및 결과
- 상태 변화
- 에러 및 재시도

=== Selective tracing — `tracing_context`

특정 구간만 켜거나 끄려면 `langsmith.tracing_context` 컨텍스트 매니저를 사용합니다.
프로젝트 / 태그 / 메타데이터를 동적으로 지정할 수도 있습니다.

#code-block(`````python
import langsmith as ls

# 이 호출만 트레이싱
with ls.tracing_context(enabled=True):
    agent.invoke({"messages": [{"role": "user", "content": "Send a test email"}]})

# 동적 프로젝트 + 태그 + 메타데이터
with ls.tracing_context(
    project_name="email-agent-test",
    enabled=True,
    tags=["production", "email-assistant", "v1.0"],
    metadata={"user_id": "user_123", "session_id": "session_456"},
):
    agent.invoke({"messages": [{"role": "user", "content": "Send a welcome email"}]})
`````)

`invoke()`의 `config` 인자로 태그/메타데이터를 한 번에 주입할 수도 있습니다.

#code-block(`````python
agent.invoke(
    {"messages": [{"role": "user", "content": "Send a welcome email"}]},
    config={
        "tags": ["production", "email-assistant", "v1.0"],
        "metadata": {"user_id": "user_123", "session_id": "session_456"},
    },
)
`````)

=== Data privacy — `LangChainTracer` + `with_config`

민감 정보를 트레이스에 남기지 않으려면 `LangChainTracer`에 anonymizer를 적용한 `Client`를 주입하고, 컴파일된 그래프에 `.with_config({"callbacks": [tracer]})`로 부착합니다.

#code-block(`````python
from langchain_core.tracers.langchain import LangChainTracer
from langgraph.graph import StateGraph, MessagesState
from langsmith import Client
from langsmith.anonymizer import create_anonymizer

anonymizer = create_anonymizer([
    {"pattern": r"\b\d{3}-?\d{2}-?\d{4}\b", "replace": "<ssn>"},
])

tracer_client = Client(anonymizer=anonymizer)
tracer = LangChainTracer(client=tracer_client)

graph = (
    StateGraph(MessagesState)
    # .add_node(...).add_edge(...)
    .compile()
    .with_config({"callbacks": [tracer]})
)
`````)

위 패턴은 SSN처럼 정규식으로 식별 가능한 패턴을 로깅 직전에 마스킹한 뒤 LangSmith로 전송합니다.

== 10.9 Pregel 런타임 개요

- _Pregel_은 LangGraph의 내부 실행 엔진
- Graph API와 Functional API 모두 Pregel 위에서 실행됨
- 핵심 개념: _슈퍼스텝_, _채널_, _체크포인트_
- _슈퍼스텝_: 동일 레벨의 노드가 병렬 실행되는 단위
- 일반적으로 직접 사용할 필요 없음 (Graph/Functional API가 추상화)

_LangGraph 실행 모델:_

#code-block(`````python
[Super-step 1] Node A, Node B (병렬)
     ↓ 상태 업데이트
[Super-step 2] Node C (A, B 결과 기반)
     ↓ 상태 업데이트
[Super-step 3] Node D
     ↓
END
`````)

_각 슈퍼스텝:_
+ 해당 노드들 병렬 실행
+ 상태 업데이트 (리듀서 적용)
+ 체크포인트 저장
+ 다음 슈퍼스텝 결정

== 10.10 프로덕션 체크리스트

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[도구],
  text(weight: "bold")[설명],
  [단위 테스트],
  [pytest],
  [개별 노드 함수 테스트],
  [통합 테스트],
  [GenericFakeChatModel],
  [API 호출 없이 전체 흐름],
  [지속성],
  [PostgresSaver],
  [프로덕션 체크포인터],
  [관측성],
  [LangSmith],
  [트레이싱, 모니터링],
  [배포],
  [langgraph deploy],
  [관리형 배포],
  [UI],
  [Agent Chat UI],
  [사용자 인터페이스],
)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [앱 구조],
  [`langgraph.json`으로 프로젝트 설정],
  [Studio],
  [`langgraph dev`로 시각적 디버깅],
  [테스트],
  [결정론적 테스트 + GenericFakeChatModel],
  [배포],
  [Platform, Docker, Cloud 옵션],
  [관측성],
  [LangSmith 트레이싱],
  [런타임],
  [Pregel 슈퍼스텝 실행 모델 → \#link("13_api_guide_and_pregel.ipynb")[13번 노트북]에서 심화],
)
