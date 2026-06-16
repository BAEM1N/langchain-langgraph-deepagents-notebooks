// Auto-generated from 07_hitl_and_runtime.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "사람 개입(HITL)과 런타임")

== 학습 목표
도구 실행 전 사람의 승인을 받고, 런타임 컨텍스트를 주입합니다.

이 노트북에서 다루는 내용:
- _Human-in-the-Loop (HITL)_: 에이전트가 위험한 도구를 실행하기 전에 사람의 승인을 받는 패턴
- _ToolRuntime_: 도구 실행 시 런타임 컨텍스트(사용자 정보 등)를 주입하는 방법
- _컨텍스트 엔지니어링_: 동적으로 프롬프트와 도구를 제어하는 기법
- _MCP (Model Context Protocol)_: 도구 서버를 표준 프로토콜로 연결하는 방식

== 7.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

# requires deepagents>=0.5.0 or langgraph>=1.1.5
model = ChatOpenAI(
    model="gpt-5.4",
)

print("모델 준비 완료:", model.model_name)
`````)

== 7.2 Human-in-the-Loop 개념

에이전트가 도구를 호출하기 전에 사람의 승인을 요청합니다.

=== 왜 필요한가?

자율적으로 동작하는 에이전트는 강력하지만, 이메일 전송, 파일 삭제, 결제 처리 같은 _되돌릴 수 없는 작업_에서는 사람의 확인이 필요합니다.

=== 워크플로

#code-block(`````python
에이전트 → 도구 호출 제안 → [중단(interrupt)] → 사람 승인/거부 → 도구 실행 → 결과 반환
`````)

LangChain v1에서는 `HumanInTheLoopMiddleware`와 `InMemorySaver`(체크포인터)를 결합하여 이 패턴을 구현합니다. 체크포인터는 에이전트의 상태를 저장하여 중단 후 재개할 수 있게 합니다.

== 7.3 HumanInTheLoopMiddleware

`HumanInTheLoopMiddleware`는 도구 호출 시 실행을 자동으로 중단하고 사람의 승인을 기다리는 미들웨어입니다. `InMemorySaver` 체크포인터와 함께 사용하여 중단된 상태를 보존합니다.

=== 라이프사이클

내부적으로 `after_model` 훅에서 `HITLRequest` 를 생성합니다.

#code-block(`````python
모델이 tool_call 생성 → after_model 훅 발동 → HITLRequest
{
  "action_requests": [...],     # 어떤 도구를 어떤 인자로 호출하려는지
  "review_configs":  [...]      # 도구별 허용 decision 목록
}
→ interrupt 발생 → result.interrupts 에 노출 → 사람이 Command(resume=...) 로 재개
`````)

=== transient vs persistent 변경

- _transient (요청 단위)_: `request.override(messages=..., tools=...)` — 한 번의 모델 호출에만 적용. 미들웨어가 끝나면 원복됩니다.
- _persistent (상태 저장)_: `ExtendedModelResponse` + `Command(update={...})` — 그래프 상태를 영속적으로 수정. 다음 호출에도 반영됩니다.

권한 가드 같은 일회성 변경은 transient 로, 사용자 프로필이 바뀐 경우는 persistent 로 처리하는 것이 일반적입니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """지정된 수신자에게 이메일을 보냅니다."""
    return f"{to}에게 이메일 전송 완료: {subject}"

@tool
def delete_file(path: str) -> str:
    """지정된 경로의 파일을 삭제합니다."""
    return f"파일 삭제 완료: {path}"

# 도구별로 허용 가능한 decision 목록을 dict 형식으로 지정합니다.
# - approve : 그대로 실행
# - edit    : 인자를 수정해서 실행
# - reject  : 도구 실행 거부 (사유 전달)
# - respond : 도구를 실행하지 않고 사람이 직접 응답
hitl = HumanInTheLoopMiddleware(
    interrupt_on={
        "send_email":  {"allowed_decisions": ["approve", "edit", "reject", "respond"]},
        "delete_file": {"allowed_decisions": ["approve", "reject"]},  # 편집 없이 승인/거부만
    },
)

agent = create_agent(
    model=model,
    tools=[send_email, delete_file],
    system_prompt="당신은 이메일을 보내고 파일을 관리할 수 있는 어시스턴트입니다.",
    middleware=[hitl],
    checkpointer=InMemorySaver(),
)

print("HITL 에이전트 생성 완료")
print("  -> 도구 호출 시 사람의 승인을 위해 중단됩니다 (approve/edit/reject/respond)")
`````)

== 7.4 interrupt와 Command(resume=...) 패턴

HITL 에이전트는 2단계로 동작합니다:

+ _1단계 (invoke)_: 에이전트가 도구 호출을 제안하면 자동으로 _중단(interrupt)_됩니다.
+ _2단계 (Command(resume=...))_: 사람이 결정을 내려 실행을 _재개_합니다.

=== 4가지 decision 형식

`Command(resume={"decisions": [...]})` 의 각 decision 은 dict 입니다:

#code-block(`````python
# 1) 승인 — 도구를 그대로 실행
Command(resume={"decisions": [{"type": "approve"}]})

# 2) 편집 — 도구 인자를 수정해서 실행
Command(resume={"decisions": [{"type": "edit", "args": {"to": "alice@example.com"}}]})

# 3) 거부 — 도구를 실행하지 않고 사유를 모델에 전달
Command(resume={"decisions": [{"type": "reject", "message": "수신자가 잘못되었습니다."}]})

# 4) 응답 — 도구를 실행하지 않고 사람이 직접 답변을 작성 (모델에는 ToolMessage 로 전달)
Command(resume={"decisions": [{"type": "respond", "message": "이미 어제 보냈으니 건너뛰세요."}]})
`````)

decision 리스트의 순서는 `result.interrupts[0].value["action_requests"]` 의 순서와 일치해야 합니다.

== 7.5 ToolRuntime -- 도구에서 런타임 정보에 접근합니다

`ToolRuntime`은 도구가 실행될 때 런타임 컨텍스트(현재 사용자 정보, 세션 데이터 등)에 접근할 수 있게 해주는 메커니즘입니다.

=== 핵심 아이디어
- 도구 함수에 `runtime: ToolRuntime[T]` 파라미터를 추가합니다.
- `T`는 개발자가 정의하는 컨텍스트 데이터 클래스입니다.
- 에이전트 생성 시 `context_schema=T`를 지정하고, 호출 시 `context=T(...)`로 값을 전달합니다.

=== runtime.execution_info — 실행 메타데이터에 접근

`runtime.execution_info` 는 현재 실행에 대한 메타데이터를 담고 있습니다 (LangGraph 1.1.5+ / Deep Agents 0.5.0+).

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필드],
  text(weight: "bold")[설명],
  [`thread_id`],
  [현재 대화 스레드 ID — checkpointer 키와 동일],
  [`run_id`],
  [이번 invoke/stream 한 번의 고유 ID — 로깅/추적용],
  [`attempt`],
  [재시도 횟수 (1부터 시작) — 폴백·재시도 미들웨어에서 유용],
)

도구나 미들웨어 안에서 분기·로깅에 쓰입니다.

=== runtime.server_info — 호스트 서버에서 주입되는 메타데이터

LangGraph Platform / Server 환경에서 실행될 때 `runtime.server_info` 가 채워집니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필드],
  text(weight: "bold")[설명],
  [`assistant_id`],
  [배포된 assistant 의 ID],
  [`graph_id`],
  [그래프 ID],
  [`user`],
  [인증된 사용자 정보(있다면)],
)

로컬에서 실행하면 `None` 또는 빈 객체가 됩니다. 멀티 테넌트 배포에서 권한 분리·로깅에 활용합니다.

== 7.6 컨텍스트 엔지니어링 -- 동적으로 프롬프트와 도구를 제어합니다

컨텍스트 엔지니어링은 에이전트에게 전달되는 _프롬프트_, _도구_, _메시지 히스토리_를 동적으로 조작하는 기법입니다.

=== 주요 활용 사례
- 사용자 역할에 따라 다른 시스템 프롬프트 제공
- 상황에 따라 사용 가능한 도구 필터링
- 긴 대화 히스토리 요약 및 정리

`dynamic_prompt` 미들웨어를 쓰면 매 요청마다 프롬프트를 커스터마이즈할 수 있습니다.

== 7.7 MCP (Model Context Protocol) 연동 개요

_MCP_는 도구 서버를 표준 프로토콜로 연결하는 방식입니다.

=== MCP의 핵심 개념
- _MCP 서버_: 도구(Tool)를 제공하는 서버. HTTP/SSE 또는 stdio로 통신합니다.
- _MCP 클라이언트_: 에이전트가 MCP 서버에 연결하여 도구를 발견하고 호출합니다.
- _표준화_: 어떤 언어/프레임워크로 만든 도구든 MCP 프로토콜을 따르면 연결 가능합니다.

=== LangChain v1에서의 MCP 지원
- `mcp.client.stdio.stdio_client()`와 `ClientSession`으로 로컬 MCP 서버에 연결할 수 있습니다.
- `langchain-mcp-adapters`의 `load_mcp_tools(session)`로 MCP 세션의 도구를 LangChain Tool로 변환할 수 있습니다.

#chapter-summary-header()

이 노트북에서 학습한 핵심 내용:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  text(weight: "bold")[핵심 API],
  [_HITL_],
  [도구 실행 전 사람의 결정 요청],
  [`HumanInTheLoopMiddleware(interrupt_on={"tool": {"allowed_decisions": [...]}})`],
  [_Decisions_],
  [4가지 dict 형식],
  [`approve` / `edit` / `reject` / `respond`],
  [_재개_],
  [dict 기반 resume],
  [`Command(resume={"decisions": [{"type": ..., ...}]})`],
  [_GraphOutput_],
  [v2 결과 객체],
  [`result.value` / `result.interrupts`],
  [_ToolRuntime_],
  [도구에서 런타임 컨텍스트 접근],
  [`ToolRuntime[T]`, `context_schema=T`],
  [_execution_info_],
  [실행 메타데이터],
  [`runtime.execution_info.thread_id / run_id / attempt`],
  [_server_info_],
  [서버 메타데이터],
  [`runtime.server_info.assistant_id / graph_id / user`],
  [_컨텍스트 엔지니어링_],
  [동적 프롬프트/도구 제어],
  [`dynamic_prompt` 미들웨어],
  [_MCP_],
  [표준화된 도구 프로토콜],
  [`ClientSession + load_mcp_tools()`],
)

_핵심 포인트:_
- `version="v2"` 호출은 `GraphOutput` 을 반환 — `result.value["messages"]` / `result.interrupts` 로 접근하세요.
- `interrupt_on` 은 dict 형식 (`{"tool_name": {"allowed_decisions": [...]}}`) — 도구별로 허용 결정을 다르게 설정 가능합니다.
- decision 의 4가지 타입(`approve`/`edit`/`reject`/`respond`)은 모두 `Command(resume={"decisions": [{...}]})` 형식의 dict 입니다.
- `runtime.execution_info` 와 `runtime.server_info` 는 LangGraph 1.1.5+ / Deep Agents 0.5.0+ 에서 사용 가능합니다.
- 미들웨어 변경의 범위: transient(`request.override`) vs persistent(`ExtendedModelResponse` + `Command(update=...)`).
