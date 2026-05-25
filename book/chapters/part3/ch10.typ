// Auto-generated from 10_production.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "프로덕션", subtitle: "테스트, 배포, 관측성")

9장까지 에이전트의 설계, 구현, 모듈화를 다루었다면, 이제 실제 사용자에게 서비스하기 위한 _프로덕션 전환_을 다룰 차례입니다. 에이전트를 개발 환경에서 성공적으로 실행하는 것과 프로덕션에서 안정적으로 운영하는 것은 전혀 다른 문제입니다. `langgraph.json` 설정, `LangGraph Platform` 배포, `LangSmith` 기반 트레이싱과 평가는 실환경 운영의 세 기둥입니다. 이 장에서는 앱 구조 설정부터 단위 테스트, 회귀 테스트, 그리고 관측성 확보까지 프로덕션 전환에 필요한 전체 과정을 다룹니다.

#learning-header()
LangGraph 앱을 테스트, 배포, 모니터링하는 방법을 알아봅니다.

- `langgraph.json`으로 프로젝트 구조를 설정할 수 있습니다
- `langgraph dev`로 로컬 개발 서버를 실행하고 LangGraph Studio로 디버깅할 수 있습니다
- 결정론적 테스트와 `GenericFakeChatModel`을 활용한 에이전트 테스트를 작성할 수 있습니다
- Python SDK로 배포된 LangGraph 서버를 호출할 수 있습니다
- LangSmith 트레이싱으로 프로덕션 관측성을 확보할 수 있습니다

== 10.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 10.2 앱 구조 — langgraph.json

LangGraph 앱을 배포하려면 먼저 프로젝트 구조를 `langgraph.json` 설정 파일로 정의해야 합니다. 이 파일은 LangGraph CLI와 Platform이 앱을 인식하고 실행하는 데 필요한 모든 정보를 담고 있습니다.

- `langgraph.json`: 그래프 정의, 의존성, 환경 변수 설정
- `dependencies`: 프로젝트의 Python 패키지 의존성 경로
- `graphs`: 그래프 이름과 해당 Python 모듈 경로 매핑 (형식: `"./module.py:variable"`)
- `env`: 환경 변수 파일 경로
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

앱 구조를 설정했으니, 이제 시각적으로 그래프를 디버깅할 수 있는 LangGraph Studio를 살펴봅시다.

Studio는 `langgraph dev` 실행 시 자동으로 제공되는 웹 기반 디버깅 도구입니다. 그래프의 구조를 시각적으로 확인하고, 실행 과정을 단계별로 추적하며, 인터럽트 지점에서 상태를 직접 수정할 수 있습니다. 개발 과정에서 `print()` 디버깅 대신 Studio를 사용하면 에이전트의 의사결정 과정을 훨씬 직관적으로 파악할 수 있습니다.

_Key Features (7가지):_
+ _Real-time Visualization_ --- 프롬프트, 도구 호출, 결과, 최종 출력 등 모든 단계가 실시간으로 렌더링
+ _Interactive Testing_ --- 다양한 입력으로 실행하고 중간 상태를 UI에서 직접 검사
+ _Hot-reloading_ --- 프롬프트나 도구 시그니처 수정이 서버 재시작 없이 즉시 반영
+ _Trace Inspection_ --- 프롬프트, 도구 인자, 반환값, 토큰 수, 지연 시간 추적
+ _Exception Capture_ --- 예외 발생 시 주변 상태와 함께 캡처되어 디버깅에 활용
+ _Thread Replay_ --- 대화 스레드를 임의 지점부터 다시 실행하여 변경 검증
+ _Optional Tracing_ --- `LANGSMITH_TRACING=false`로 외부 전송 없이 로컬 실행만 유지

#tip-box[LangGraph Studio는 로컬에서 `langgraph dev`를 실행할 때뿐만 아니라, LangSmith에 배포된 원격 에이전트에도 연결할 수 있습니다. 프로덕션 환경에서 발생한 문제를 Studio로 재현하고 디버깅할 수 있어, 운영 중 트러블슈팅에 매우 유용합니다.]

_사용 방법:_
#code-block(`````bash
$ langgraph dev
# 브라우저에서 http://localhost:2024 접속
# 또는 LangSmith Studio에서 원격 접속
`````)

== 10.4 Agent Chat UI

Studio가 개발자를 위한 디버깅 도구라면, Agent Chat UI는 사용자 관점에서 에이전트와 상호작용하는 Next.js 기반 채팅 인터페이스입니다. `create_agent`로 만든 에이전트와 바로 연동되며, `langgraph dev` 서버나 배포된 서버 모두에 연결할 수 있습니다.

_설치 --- npx 사용 (권장):_
#code-block(`````bash
$ npx create-agent-chat-app --project-name my-chat-ui
$ cd my-chat-ui
$ pnpm install
$ pnpm dev
`````)

_Hosted 버전:_ #link("https://agentchat.vercel.app")[agentchat.vercel.app] 에 접속해 에이전트 deployment URL이나 로컬 서버 주소를 입력합니다.

_연결 정보:_
- _Graph ID_ --- `langgraph.json`의 `graphs` 섹션 키
- _Deployment URL_ --- 에이전트 서버 주소 (로컬은 `http://localhost:2024`)
- _LangSmith API key_ --- 선택 (로컬 서버 사용 시 불필요)

_기능:_
- 실시간 스트리밍 채팅 --- 7장에서 다룬 토큰 단위 스트리밍을 UI로 확인
- 도구 호출 / 결과 렌더링 --- 에이전트가 어떤 도구를 호출했는지 실시간 표시
- Time-travel debugging, state forking --- 대화의 특정 시점에서 다른 경로로 분기
- Human-in-the-loop 승인 --- 8장의 인터럽트 패턴을 UI에서 직접 테스트
- Generative UI 지원 --- 멀티 에이전트 응답을 시각적으로 구분

== 10.5 테스트 --- 결정론적 에이전트 테스트

개발 서버와 UI 도구를 갖추었으니, 이제 에이전트의 품질을 보장하는 테스트 전략을 살펴봅시다.

LLM 기반 에이전트는 비결정적 특성 때문에 테스트가 까다롭습니다. 같은 입력을 주어도 매번 다른 응답이 나올 수 있기 때문입니다. LangGraph에서는 두 가지 전략으로 이 문제를 해결합니다. 첫째, LLM 호출이 없는 순수 로직을 분리하여 결정론적으로 테스트합니다. 둘째, `GenericFakeChatModel`로 LLM 응답을 미리 지정하여 전체 에이전트 흐름을 제어된 환경에서 검증합니다.

첫 번째 전략부터 살펴보겠습니다. 노드 함수에서 LLM 호출과 비즈니스 로직을 분리하면, 비즈니스 로직 부분은 일반적인 단위 테스트로 검증할 수 있습니다.

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

== 10.6 LLM 에이전트 테스트 --- GenericFakeChatModel 사용

순수 로직 테스트만으로는 에이전트의 전체 동작을 검증하기 어렵습니다. 도구 호출, 조건부 분기, ReAct 루프 등 LLM의 응답에 따라 달라지는 흐름도 테스트해야 합니다.

순수 로직 테스트를 넘어, 도구 호출을 포함한 전체 에이전트 흐름을 테스트하려면 LLM 응답을 제어해야 합니다. `langchain_core.language_models.GenericFakeChatModel`은 미리 정의된 응답을 순차적으로 반환하는 가짜 모델입니다. 도구 호출을 포함한 `AIMessage`를 응답으로 지정하면, 도구 호출 -> 결과 처리까지의 전체 ReAct 루프를 결정론적으로 테스트할 수 있습니다.

#warning-box[`GenericFakeChatModel`의 `messages` 인자에는 `iter()`를 사용하여 이터레이터를 전달합니다. 응답 리스트보다 호출 횟수가 많으면 `StopIteration` 에러가 발생하므로, 에이전트의 LLM 호출 횟수를 정확히 파악하고 그에 맞는 수의 응답을 준비해야 합니다.]

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

테스트를 통과한 에이전트를 실제 사용자에게 제공하려면 배포가 필요합니다. LangGraph는 세 가지 배포 옵션을 제공하며, 팀의 인프라 역량과 보안 요구사항에 따라 선택할 수 있습니다.

_1. LangSmith Cloud (managed):_

GitHub 저장소를 LangSmith Deployments에서 연결하면 자동 배포됩니다 (약 15분 소요). 배포 흐름은 다음과 같습니다:

+ 애플리케이션 코드를 GitHub 저장소(공개/비공개)에 푸시
+ LangSmith → _Deployments_ → _"+ New Deployment"_ 클릭
+ 비공개 저장소는 GitHub 계정 연결 후 저장소 선택, 제출
+ 배포 완료 후 Studio 버튼으로 그래프 확인, Deployment details에서 API URL 복사

_2. Self-hosted Docker:_

자체 인프라에 Docker 컨테이너로 배포합니다. 데이터가 외부로 나가지 않아야 하는 보안 민감한 환경에 적합합니다.

#code-block(`````bash
$ langgraph build -t my-agent
$ docker run -p 2024:2024 my-agent
`````)

_3. 배포 후 API 호출 (Python SDK):_

배포 URL과 LangSmith API key를 전달해 동일한 SDK로 호출합니다.

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

_REST 호출:_ 배포 서버는 `X-Api-Key` 헤더로 LangSmith API key를 인증합니다.

#code-block(`````bash
curl -s --request POST \
    --url <DEPLOYMENT_URL>/runs/stream \
    --header 'Content-Type: application/json' \
    --header "X-Api-Key: <LANGSMITH API KEY>" \
    --data '{"assistant_id": "agent", "input": {"messages": [{"role": "human", "content": "What is LangGraph?"}]}, "stream_mode": "updates"}'
`````)

#tip-box[어떤 배포 옵션을 선택하든, 배포된 에이전트는 동일한 REST API를 노출합니다. 따라서 Python SDK(`langgraph-sdk`)나 HTTP 클라이언트를 사용하여 동일한 방식으로 에이전트를 호출할 수 있습니다. 개발 단계에서 `langgraph dev`로 테스트한 코드가 프로덕션에서도 동일하게 동작합니다.]

== 10.8 관측성 — LangSmith 트레이싱

배포 후 에이전트가 실제 사용자 요청을 처리할 때, 내부에서 무슨 일이 일어나는지 파악하는 것이 관측성(observability)입니다. LangSmith는 LangChain/LangGraph 생태계의 관측성 플랫폼으로, 환경 변수 두 줄만 설정하면 모든 실행이 자동으로 추적됩니다.

*설정 (`.env`):*
#code-block(`````python
LANGSMITH_API_KEY=lsv2-...
LANGSMITH_TRACING=true
`````)

이 두 줄이 설정되면, LangGraph의 모든 노드 실행, LLM 호출, 도구 호출이 자동으로 LangSmith 대시보드에 기록됩니다. 코드 변경 없이 관측성이 확보되는 것이 핵심입니다.

_자동 추적 항목:_
- 각 노드 실행 시간 --- 병목 구간 식별에 활용
- LLM 입출력, 토큰 사용량 --- 비용 최적화에 활용
- 도구 호출 및 결과 --- 도구 실패 원인 분석
- 상태 변화 --- 각 슈퍼스텝에서의 상태 전이 추적
- 에러 및 재시도 --- 장애 원인 분석 및 알림 설정

#warning-box[프로덕션에서 LangSmith 트레이싱을 활성화하면 모든 LLM 입출력이 기록됩니다. 개인정보가 포함된 데이터를 처리하는 경우, LangSmith의 데이터 보존 정책과 조직의 개인정보 처리 방침을 반드시 확인하세요. 필요시 `hide_inputs`/`hide_outputs` 옵션으로 민감한 데이터를 필터링할 수 있습니다.]

=== Selective tracing --- `tracing_context`

특정 구간만 켜거나 끄려면 `langsmith.tracing_context` 컨텍스트 매니저를 사용합니다. 프로젝트 / 태그 / 메타데이터를 동적으로 지정할 수도 있습니다.

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

=== Data privacy --- `LangChainTracer` + `with_config`

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

배포와 관측성을 다루었으니, LangGraph의 내부 엔진을 잠시 살펴봅시다. 지금까지 사용한 모든 기능 --- 상태 관리, 체크포인트, 인터럽트, 스트리밍 --- 이 하나의 실행 엔진 위에서 동작합니다. 이 섹션은 13장에서 깊이 다룰 내용의 미리보기입니다.

- _Pregel_은 LangGraph의 내부 실행 엔진으로, Google의 Pregel 논문(2010)에서 영감을 받은 메시지 패싱 기반 그래프 처리 프레임워크입니다
- Graph API와 Functional API 모두 Pregel 위에서 실행됨
- 핵심 개념: _슈퍼스텝_(실행 단위), _채널_(노드 간 통신), _체크포인트_(상태 저장)
- _슈퍼스텝_: 동일 레벨의 노드가 병렬 실행되는 단위. 각 슈퍼스텝은 Plan -> Execute -> Update의 3단계를 거칩니다
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

== 10.10 Python SDK로 서버 호출

배포된 LangGraph 서버는 REST API를 노출하며, Python SDK(`langgraph-sdk`)를 통해 프로그래밍 방식으로 호출할 수 있습니다. SDK는 `langgraph dev`로 실행한 로컬 서버와 클라우드에 배포된 서버 모두에 동일한 인터페이스로 연결됩니다.

SDK의 주요 메서드는 다음과 같습니다:
- `client.assistants.search()` --- 등록된 에이전트 목록 조회
- `client.threads.create()` --- 새 대화 스레드 생성
- `client.runs.create()` --- 스레드에서 에이전트 실행
- `client.runs.stream()` --- 스트리밍 방식으로 에이전트 실행
- `client.threads.get_state()` --- 현재 상태 조회
- `client.threads.update_state()` --- 외부에서 상태 수정

#tip-box[Python SDK는 비동기(`async`) 클라이언트도 제공합니다. `from langgraph_sdk import get_client`로 동기 클라이언트를, `from langgraph_sdk.aio import get_client`로 비동기 클라이언트를 생성할 수 있습니다. 웹 서버 등 비동기 환경에서는 비동기 클라이언트를 사용하세요.]

== 10.11 프로덕션 체크리스트

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
  [Pregel 슈퍼스텝 실행 모델 --- 13장에서 심화],
)

#next-step-box[다음 장에서는 `langgraph dev` CLI로 로컬 개발 서버를 실행하고, LangGraph Studio와 Python SDK를 통해 에이전트를 인터랙티브하게 테스트하는 방법을 다룹니다.]

#chapter-end()
