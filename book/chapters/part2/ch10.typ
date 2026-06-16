// Auto-generated from 10_production.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "프로덕션")

== 학습 목표
에이전트를 테스트, 배포, 모니터링하는 방법을 알아봅니다.

이 노트북에서 다루는 내용:
- LangSmith Studio를 사용한 로컬 개발 및 디버깅
- `GenericFakeChatModel`로 결정론적 에이전트 테스트
- 트라젝토리 기반 테스트로 도구 호출 순서 검증
- Agent Chat UI로 웹 기반 대화
- LangGraph Platform 및 자체 서버 배포
- LangSmith를 활용한 관측성(Observability)

== 10.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("환경 준비 완료.")
`````)

== 10.2 LangSmith Studio

로컬에서 에이전트를 개발하고 디버깅합니다.

준비물:
- `langgraph.json` 설정 파일
- `langgraph dev` 명령으로 로컬 서버 실행
- Studio UI(hosted)에서 인터랙티브 테스트

=== Studio 핵심 기능

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [_Hot-reloading_],
  [프롬프트·툴 코드를 저장하면 서버 재시작 없이 즉시 반영],
  [_Full execution trace_],
  [각 노드/툴 호출의 입·출력·메타데이터를 풀 트레이스로 확인],
  [_Thread replay_],
  [과거 스레드를 불러와 임의 시점부터 재실행(time-travel)],
  [_Exception capture_],
  [예외 발생 시 주변 상태(state·메시지·툴 인자)까지 함께 캡처],
)

=== 접속 URL

로컬 dev 서버는 `http://127.0.0.1:2024` 에서 떠 있고, Studio UI 는 hosted 엔드포인트로 접속합니다.

#code-block(`````python
https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
`````)


#code-block(`````python
# langgraph.json 설정 예시
import json

langgraph_config = {
    "dependencies": ["."],
    "graphs": {
        "agent": "./agent.py:agent"
    },
    "env": ".env"
}

print("langgraph.json 설정 예시:")
print(json.dumps(langgraph_config, indent=2))
print("\n실행 방법:")
print("  $ langgraph dev")
print("  → http://localhost:2024 에서 Studio UI 접근")
`````)
#output-block(`````
langgraph.json 설정 예시:
{
  "dependencies": [
    "."
  ],
  "graphs": {
    "agent": "./agent.py:agent"
  },
  "env": ".env"
}

실행 방법:
  $ langgraph dev
  → http://localhost:2024 에서 Studio UI 접근
`````)

== 10.3 에이전트 테스트

LangChain 에이전트는 보통 세 갈래로 테스트합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[분류],
  text(weight: "bold")[목적],
  text(weight: "bold")[도구],
  [_Unit_],
  [단일 노드·툴·프롬프트가 결정론적으로 동작하는지 검증],
  [`GenericFakeChatModel`, `pytest`],
  [_Integration_],
  [실제 모델·외부 시스템과 함께 end-to-end 흐름 검증],
  [LangSmith dataset, 실서비스 모델],
  [_Evals_],
  [에이전트 트라젝토리를 결정론 매칭 또는 LLM-as-judge로 평가],
  [`agentevals`, LangSmith Evaluators],
)

`GenericFakeChatModel`을 쓰면 실제 API 호출 없이 결정론적으로 에이전트를 테스트할 수 있습니다.

- API 비용 없이 테스트 가능
- 항상 동일한 결과 → CI/CD 파이프라인에 적합
- 에이전트 로직(도구 호출, 분기 등)을 독립적으로 검증

#code-block(`````python
from langchain_core.language_models import GenericFakeChatModel
from langchain.messages import AIMessage
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def get_capital(country: str) -> str:
    """국가의 수도를 반환합니다."""
    capitals = {"Korea": "Seoul", "Japan": "Tokyo", "France": "Paris"}
    return capitals.get(country, "알 수 없음")

# 가짜 모델로 결정론적 테스트
fake_model = GenericFakeChatModel(
    messages=iter([
        AIMessage(content="대한민국의 수도는 서울입니다.")
    ])
)

# 테스트 에이전트
test_agent = create_agent(
    model=fake_model,
    tools=[get_capital],
    system_prompt="당신은 지리 전문가입니다.",
)

print("GenericFakeChatModel 테스트:")
print("  → 결정론적 응답으로 에이전트 동작을 테스트합니다")
print("  → CI/CD 파이프라인에서 API 호출 없이 테스트 가능")
`````)
#output-block(`````
GenericFakeChatModel 테스트:
  → 결정론적 응답으로 에이전트 동작을 테스트합니다
  → CI/CD 파이프라인에서 API 호출 없이 테스트 가능
`````)

== 10.4 트라젝토리 평가 — agentevals

`agentevals` 패키지는 에이전트의 메시지 시퀀스(트라젝토리)를 평가합니다. 도구 호출이 의도한 순서로 일어났는지 결정론적으로 매칭하거나, LLM-as-judge 로 자연어 기준에 따라 채점할 수 있습니다.

=== Trajectory match 모드 4종

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[의미],
  [`strict`],
  [동일한 툴이 동일한 순서로 호출되어야 통과],
  [`unordered`],
  [동일한 툴 집합이 호출되면 순서 무관],
  [`subset`],
  [기대 트라젝토리가 실제 트라젝토리에 부분집합으로 포함되면 통과],
  [`superset`],
  [실제 트라젝토리가 기대 트라젝토리를 포함하면 통과],
)

#code-block(`````python
# 트라젝토리 테스트 예시
def test_agent_trajectory():
    """에이전트가 예상된 순서로 도구를 호출하는지 테스트합니다."""
    result = test_agent.invoke(
        {"messages": [{"role": "user", "content": "대한민국의 수도는 어디인가요?"}]}
    )
    
    messages = result["messages"]
    
    # 검증: 메시지가 존재하는지
    assert len(messages) > 0, "에이전트가 응답하지 않았습니다"
    
    # 검증: 마지막 메시지가 AI 응답인지
    last_msg = messages[-1]
    assert hasattr(last_msg, 'content'), "마지막 메시지에 content가 없습니다"
    
    print("✓ 트라젝토리 테스트 통과")
    print(f"  메시지 수: {len(messages)}")
    print(f"  최종 응답: {last_msg.content[:100]}")

try:
    test_agent_trajectory()
except Exception as e:
    print(f"테스트 참고: {e}")
`````)
#output-block(`````
테스트 참고:
`````)

#code-block(`````python
# agentevals — 트라젝토리 결정론 매칭
# 설치: %pip install -U agentevals
from agentevals.trajectory.match import create_trajectory_match_evaluator
from langchain_core.messages import HumanMessage, AIMessage, ToolMessage

# 기대 트라젝토리: get_capital 도구가 한 번 호출되어야 함
expected = [
    HumanMessage(content="대한민국의 수도?"),
    AIMessage(content="", tool_calls=[{"name": "get_capital", "args": {"country": "Korea"}, "id": "1"}]),
    ToolMessage(content="Seoul", tool_call_id="1"),
    AIMessage(content="서울입니다."),
]

# 실제 트라젝토리(에이전트 실행 결과를 그대로 전달)
actual = expected  # 데모 — 실제로는 agent.invoke(...) 결과의 messages

for mode in ("strict", "unordered", "subset", "superset"):
    evaluator = create_trajectory_match_evaluator(trajectory_match_mode=mode)
    result = evaluator(outputs=actual, reference_outputs=expected)
    print(f"  [{mode:9s}] score={result['score']}")

`````)

== 10.5 Agent Chat UI

에이전트와 대화할 수 있는 웹 UI입니다. LangGraph 서버와 연결하여 브라우저에서 직접 에이전트를 테스트할 수 있습니다.

주요 기능:
- 실시간 스트리밍 채팅
- 도구 호출 시각화
- 대화 분기(branching)
- Human-in-the-loop 승인

#code-block(`````python
print("Agent Chat UI 설정:")
print("=" * 50)
print("""
# 1. Agent Chat UI 설치 — 정식 CLI
$ npx create-agent-chat-app --project-name my-chat-ui

# 또는 GitHub 레포를 직접 클론
$ git clone https://github.com/langchain-ai/agent-chat-ui.git
$ cd agent-chat-ui && npm install && npm run dev

# 2. LangGraph 서버 시작
$ langgraph dev
#   → 로컬 dev 서버: http://127.0.0.1:2024

# 3. Agent Chat UI 환경설정
#   - Deployment URL: http://127.0.0.1:2024 (로컬) 또는 LangGraph Platform URL
#   - Graph ID:       langgraph.json 의 graphs 키 (예: "agent")
#   - LangSmith API Key: LangSmith 트레이싱을 같이 보고 싶을 때만
""")
print("주요 기능:")
print("  - 실시간 스트리밍 채팅")
print("  - 도구 호출 시각화")
print("  - 대화 분기(branching)")
print("  - Human-in-the-loop 승인")
`````)

== 10.6 배포

배포는 크게 _LangGraph Platform(관리형)_, _자체 Docker_, 그리고 _레거시 FastAPI 래핑_ 세 트랙이 있습니다. 신규 프로젝트는 Platform 트랙을 권장합니다.

=== Platform 정식 워크플로

+ 에이전트 코드를 _GitHub 레포_로 push
+ LangSmith 콘솔 → _Deployments_ → _+ New Deployment_
+ 레포·브랜치·`langgraph.json` 경로·env 를 지정하고 Deploy
+ Deployment URL + Graph ID 를 클라이언트(Chat UI / SDK)에 연결

=== langgraph-sdk 설치

LangGraph 서버(로컬·Platform 모두)와 통신하려면 `langgraph-sdk` 가 필요합니다.

#code-block(`````python
%pip install -q langgraph-sdk
`````)

#code-block(`````python
print("배포 옵션:")
print("=" * 50)
print("""
# 옵션 1 (권장) — LangGraph Platform
#   1) 에이전트 코드를 GitHub repo 에 push
#   2) https://smith.langchain.com/deployments → "+ New Deployment"
#   3) repo · branch · langgraph.json 경로 · env 를 지정
#   4) Deploy 클릭 → Deployment URL + Graph ID 발급
#   (과거 안내되던 `langgraph deploy` CLI 한 줄 패턴은 더 이상 정식 경로가 아닙니다.)

# 옵션 2 — 자체 Docker
$ langgraph build -t my-agent
$ docker run -p 2024:2024 my-agent

# 옵션 3 (deprecated) — FastAPI/Flask 직접 래핑
#   레거시 통합 용도로만 권장. Platform/SDK 가 제공하는 스레드 관리·체크포인트·
#   스트리밍 프로토콜을 직접 구현해야 하므로 신규 코드에는 사용하지 마세요.
from fastapi import FastAPI

app = FastAPI()

@app.post("/chat")
async def chat(message: str):
    result = agent.invoke({"messages": [{"role": "user", "content": message}]})
    return {"response": result["messages"][-1].content}
""")
`````)

#code-block(`````python
# langgraph-sdk 로 배포된 에이전트 스트리밍 호출 (Python)
# 실제 실행하려면 위에서 langgraph dev 가 떠 있거나 Platform deployment URL 이 있어야 합니다.
example = '''
from langgraph_sdk import get_sync_client

client = get_sync_client(url="http://127.0.0.1:2024")  # 로컬 dev 서버
# Platform 의 경우: get_sync_client(url=DEPLOYMENT_URL, api_key=LANGSMITH_API_KEY)

for chunk in client.runs.stream(
    None,                       # thread_id — None 이면 새 스레드 생성
    "agent",                    # Graph ID = langgraph.json 의 graphs 키
    input={"messages": [{"role": "user", "content": "안녕하세요"}]},
    stream_mode="updates",
):
    print(chunk)
'''
print(example)
`````)

#code-block(`````python
# REST 로 직접 호출 — assistant_id + input + stream_mode 페이로드 형태
rest_example = '''
curl -X POST http://127.0.0.1:2024/runs/stream \\
  -H "Content-Type: application/json" \\
  --data '{
    "assistant_id": "agent",
    "input": {"messages": [{"role": "user", "content": "안녕하세요"}]},
    "stream_mode": "updates"
  }'

# Platform deployment 에서는 LangSmith API key 를 함께 보냅니다.
#   -H "X-Api-Key: $LANGSMITH_API_KEY"
'''
print(rest_example)
`````)

== 10.7 관측성

LangSmith로 에이전트 동작을 추적합니다. 트레이싱을 활성화하면 에이전트의 모든 실행 단계를 기록하고 분석할 수 있습니다.

LangSmith에서 확인할 수 있는 정보:
- 각 에이전트 호출의 전체 실행 흐름
- 모델 입/출력, 도구 호출, 토큰 사용량
- 지연 시간, 에러, 비용 추적

#code-block(`````python
# tracing_context — 코드 블록 단위로 트레이싱을 강제 ON/OFF
import langsmith as ls

example = '''
import langsmith as ls

# 환경변수가 꺼져 있어도 이 블록 안에서는 트레이싱이 켜집니다.
with ls.tracing_context(enabled=True):
    agent.invoke({"messages": [{"role": "user", "content": "안녕하세요"}]})

# 반대로 민감 구간만 꺼두기
with ls.tracing_context(enabled=False):
    agent.invoke({"messages": [{"role": "user", "content": "PII 포함"}]})
'''
print(example)
`````)

#code-block(`````python
# 트레이스에 태그·메타데이터 주입 — 대시보드에서 필터·검색 키로 사용
example = '''
agent.invoke(
    {"messages": [{"role": "user", "content": "안녕하세요"}]},
    config={
        "tags": ["production", "v1.0"],
        "metadata": {"user_id": "123", "session_id": "456"},
    },
)
'''
print(example)
`````)

== 10.8 프로덕션 체크리스트

에이전트를 프로덕션에 배포하기 전에 아래 항목을 확인하세요.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[도구],
  text(weight: "bold")[상태],
  [단위 테스트],
  [`GenericFakeChatModel`, `pytest`],
  [],
  [트라젝토리 테스트],
  [커스텀 검증 함수],
  [],
  [관측성 설정],
  [LangSmith 트레이싱],
  [],
  [에러 처리],
  [`try/except`, 재시도 로직],
  [],
  [보안],
  [API 키 관리, 입력 검증, 가드레일],
  [],
  [배포 환경],
  [Docker, LangGraph Platform],
  [],
  [모니터링],
  [LangSmith 대시보드, 알림 설정],
  [],
  [문서화],
  [API 문서, 에이전트 동작 설명],
  [],
)

#chapter-summary-header()

이 노트북에서 배운 내용:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [_LangSmith Studio_],
  [`langgraph dev`로 로컬에서 에이전트를 시각적으로 디버깅합니다],
  [_에이전트 테스트_],
  [`GenericFakeChatModel`로 API 호출 없이 결정론적 테스트를 수행합니다],
  [_트라젝토리 테스트_],
  [도구 호출 순서와 최종 응답을 검증합니다],
  [_Agent Chat UI_],
  [웹 브라우저에서 에이전트와 대화하고 도구 호출을 시각화합니다],
  [_배포_],
  [LangGraph Platform, Docker, FastAPI 등으로 배포합니다],
  [_관측성_],
  [LangSmith로 실행 흐름, 토큰 사용량, 비용을 추적합니다],
)

LangChain v1 에이전트 과정을 마칩니다. 기본 개념부터 프로덕션 배포까지, 에이전트 개발의 전체 라이프사이클을 다루었습니다.
