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

#code-block(`````python
# Observability 설정 (선택) - LangSmith 또는 Langfuse
# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    project = os.environ.get("LANGSMITH_PROJECT", "default")
    print(f"LangSmith tracing ON \u2014 project: {project}")

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

@tool
def ask_user(question: str) -> str:
    """계속 진행하는 데 필요한 정보를 사용자에게 묻습니다."""
    return "응답 없음"

hitl = HumanInTheLoopMiddleware(
    interrupt_on={
        "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},
        "delete_file": {"allowed_decisions": ["approve", "reject"]},
        "ask_user": {"allowed_decisions": ["respond"]},
    },
)

agent = create_agent(
    model=model,
    tools=[send_email, delete_file, ask_user],
    system_prompt="이메일과 파일 작업은 승인받고, 정보가 부족하면 ask_user를 호출하세요.",
    middleware=[hitl],
    checkpointer=InMemorySaver(),
)

print("HITL 에이전트 생성 완료")
print("  -> 부작용 거부는 reject, 사용자 답변 대행은 respond를 사용합니다.")
`````)

== 7.4 interrupt와 Command(resume=...) 패턴

HITL 에이전트는 도구 호출에서 중단되고, 같은 `thread_id`의 `Command(resume={"decisions": [...]})`로 재개합니다.

=== 결정의 의미

#code-block(`````python
# 승인 — 원래 인자로 실행
Command(resume={"decisions": [{"type": "approve"}]})

# 편집 — 수정한 인자로 실행
Command(resume={"decisions": [{"type": "edit", "args": {"to": "alice@example.com"}}]})

# 거부 — 이메일·파일·SQL 같은 부작용 실행을 막음
Command(resume={"decisions": [{"type": "reject", "message": "수신자가 잘못되었습니다."}]})

# 응답 — ask_user 질문에 사람이 도구 역할로 답함
Command(resume={"decisions": [{"type": "respond", "message": "파란색입니다."}]})
`````)

`respond` 메시지는 성공한 ToolMessage로 처리됩니다. 부작용을 거부할 때 사용하면 안 됩니다. decision 순서는 `action_requests` 순서와 같아야 합니다.

#code-block(`````python
from langgraph.types import Command

config = {"configurable": {"thread_id": "hitl-demo"}}
result = agent.invoke(
    {"messages": [{"role": "user", "content": "bob@example.com에게 제목 '인사', 본문 '안녕하세요 Bob!' 이메일을 보내주세요"}]},
    config={**config, **lf_config},
    version="v2",
)
print("interrupts:", result.interrupts)
print("마지막 메시지:", result.value["messages"][-1])

try:
    result = agent.invoke(
        Command(resume={"decisions": [{"type": "approve"}]}),
        config={**config, **lf_config},
        version="v2",
    )
    print("승인 후 결과:", result.value["messages"][-1].content)
except Exception as e:
    print(f"HITL 데모는 인터랙티브 환경에서 실행하세요. ({e})")

# 부작용 거부: {"type": "reject", "message": "수신자가 잘못되었습니다."}
# ask_user 답변: {"type": "respond", "message": "파란색입니다."}
`````)

== 7.5 ToolRuntime -- 도구에서 런타임 정보에 접근합니다

`ToolRuntime`은 도구가 실행될 때 런타임 컨텍스트(현재 사용자 정보, 세션 데이터 등)에 접근할 수 있게 해주는 메커니즘입니다.

=== 핵심 아이디어
- 도구 함수에 `runtime: ToolRuntime[T]` 파라미터를 추가합니다.
- `T`는 개발자가 정의하는 컨텍스트 데이터 클래스입니다.
- 에이전트 생성 시 `context_schema=T`를 지정하고, 호출 시 `context=T(...)`로 값을 전달합니다.

#code-block(`````python
from langchain.tools import ToolRuntime
from dataclasses import dataclass

@dataclass
class UserContext:
    """사용자 정보가 포함된 런타임 컨텍스트."""
    user_id: str
    role: str

@tool
def get_user_profile(runtime: ToolRuntime[UserContext]) -> str:
    """현재 사용자의 프로필 정보를 가져옵니다."""
    ctx = runtime.context
    return f"사용자 ID: {ctx.user_id}, 역할: {ctx.role}"

@tool
def check_permissions(action: str, runtime: ToolRuntime[UserContext]) -> str:
    """현재 사용자가 작업에 대한 권한이 있는지 확인합니다."""
    ctx = runtime.context
    if ctx.role == "admin":
        return f"사용자 {ctx.user_id}은(는) '{action}' 권한이 있습니다"
    return f"사용자 {ctx.user_id}은(는) '{action}' 권한이 없습니다"

agent_ctx = create_agent(
    model=model,
    tools=[get_user_profile, check_permissions],
    system_prompt="사용자 프로필과 권한을 확인할 수 있습니다.",
    context_schema=UserContext,
)

result = agent_ctx.invoke(
    {"messages": [{"role": "user", "content": "제가 누구이고 파일을 삭제할 수 있나요?"}]},
    context=UserContext(user_id="user-42", role="admin"),
    config=lf_config,
    version="v2",
)
print("결과:", result.value["messages"][-1].content)
`````)

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

#code-block(`````python
# runtime.execution_info — thread_id / run_id / attempt 활용
@tool
def whoami_exec(runtime: ToolRuntime[UserContext]) -> str:
    """현재 실행의 thread/run/attempt 정보를 반환합니다."""
    info = runtime.execution_info
    return (
        f"thread_id={info.thread_id} | "
        f"run_id={info.run_id} | "
        f"attempt={info.attempt}"
    )

agent_exec = create_agent(
    model=model,
    tools=[whoami_exec],
    system_prompt="실행 정보를 조회할 수 있습니다.",
    context_schema=UserContext,
    checkpointer=InMemorySaver(),
)

result = agent_exec.invoke(
    {"messages": [{"role": "user", "content": "현재 실행 메타데이터를 알려주세요."}]},
    context=UserContext(user_id="user-42", role="admin"),
    config={"configurable": {"thread_id": "exec-info-demo"}, **lf_config},
    version="v2",
)
print(result.value["messages"][-1].content)
`````)

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

#code-block(`````python
# runtime.server_info — 배포 환경 메타데이터 (로컬에서는 빈/None 일 수 있음)
@tool
def whoami_server(runtime: ToolRuntime[UserContext]) -> str:
    """호스트 서버 정보를 반환합니다 (LangGraph Platform 환경)."""
    info = runtime.server_info
    if info is None:
        return "로컬 실행 — server_info 가 비어 있습니다."
    return (
        f"assistant_id={getattr(info, 'assistant_id', None)} | "
        f"graph_id={getattr(info, 'graph_id', None)} | "
        f"user={getattr(info, 'user', None)}"
    )

agent_server = create_agent(
    model=model,
    tools=[whoami_server],
    system_prompt="배포 서버 정보를 조회할 수 있습니다.",
    context_schema=UserContext,
    checkpointer=InMemorySaver(),
)

result = agent_server.invoke(
    {"messages": [{"role": "user", "content": "어느 서버에서 실행 중인가요?"}]},
    context=UserContext(user_id="user-42", role="admin"),
    config={"configurable": {"thread_id": "server-info-demo"}, **lf_config},
    version="v2",
)
print(result.value["messages"][-1].content)
`````)

== 7.6 컨텍스트 엔지니어링 -- 동적으로 프롬프트와 도구를 제어합니다

컨텍스트 엔지니어링은 에이전트에게 전달되는 _프롬프트_, _도구_, _메시지 히스토리_를 동적으로 조작하는 기법입니다.

=== 주요 활용 사례
- 사용자 역할에 따라 다른 시스템 프롬프트 제공
- 상황에 따라 사용 가능한 도구 필터링
- 긴 대화 히스토리 요약 및 정리

`dynamic_prompt` 미들웨어를 쓰면 매 요청마다 프롬프트를 커스터마이즈할 수 있습니다.

#code-block(`````python
from langchain.agents.middleware import dynamic_prompt

@tool
def basic_search(query: str) -> str:
    """기본 웹 검색을 수행합니다."""
    return f"'{query}'에 대한 기본 검색 결과"

@tool
def advanced_analytics(query: str) -> str:
    """고급 데이터 분석을 수행합니다."""
    return f"'{query}'에 대한 분석 보고서"

# 사용자 역할에 따라 다른 프롬프트와 도구 제공
@dynamic_prompt
def role_based_prompt(request):
    """컨텍스트에 기반하여 프롬프트를 커스터마이즈합니다."""
    return "당신은 전문 어시스턴트입니다. 사용자의 질문에 효율적으로 답변하세요."

agent_ctx_eng = create_agent(
    model=model,
    tools=[basic_search, advanced_analytics],
    middleware=[role_based_prompt],
)

result = agent_ctx_eng.invoke(
    {"messages": [{"role": "user", "content": "머신러닝 트렌드를 검색해 주세요"}]},
    config=lf_config,
    version="v2",
)
print("컨텍스트 엔지니어링 결과:", result.value["messages"][-1].content[:200])
`````)

== 7.7 MCP (Model Context Protocol) 연동 개요

_MCP_는 도구 서버를 표준 프로토콜로 연결하는 방식입니다.

=== MCP의 핵심 개념
- _MCP 서버_: 도구(Tool)를 제공하는 서버. HTTP/SSE 또는 stdio로 통신합니다.
- _MCP 클라이언트_: 에이전트가 MCP 서버에 연결하여 도구를 발견하고 호출합니다.
- _표준화_: 어떤 언어/프레임워크로 만든 도구든 MCP 프로토콜을 따르면 연결 가능합니다.

=== LangChain v1에서의 MCP 지원
- `mcp.client.stdio.stdio_client()`와 `ClientSession`으로 로컬 MCP 서버에 연결할 수 있습니다.
- `langchain-mcp-adapters`의 `load_mcp_tools(session)`로 MCP 세션의 도구를 LangChain Tool로 변환할 수 있습니다.

#code-block(`````python
from pathlib import Path; import asyncio, tempfile, sys
from mcp import ClientSession, StdioServerParameters; from mcp.client.stdio import stdio_client; from langchain_mcp_adapters.tools import load_mcp_tools
server_path = Path(tempfile.gettempdir()) / "lc_mcp_echo_server.py"
server_path.write_text('from mcp.server.fastmcp import FastMCP\nmcp = FastMCP("echo")\n@mcp.tool()\ndef echo(text: str) -> str:\n    return f"Echo: {text}"\nif __name__ == "__main__":\n    mcp.run(transport="stdio")')
async def run_mcp_agent():
    params = StdioServerParameters(command=sys.executable, args=[str(server_path)])
    async with stdio_client(params) as (read, write), ClientSession(read, write) as session: await session.initialize(); tools = await load_mcp_tools(session); agent = create_agent(model=model, tools=tools, system_prompt="MCP 도구를 사용할 수 있습니다."); return await agent.ainvoke({"messages": [{"role": "user", "content": "echo 도구로 '안녕하세요'를 반복해 주세요."}]}, config=lf_config, version="v2")
result = asyncio.run(run_mcp_agent()); print(result.value["messages"][-1].content)
`````)

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
