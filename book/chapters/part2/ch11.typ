// Auto-generated from 11_mcp.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "MCP (Model Context Protocol)")

== 학습 목표
MCP(Model Context Protocol)로 외부 도구와 컨텍스트를 에이전트에 연결하는 방법을 알아봅니다.

이 노트북에서 다루는 내용:
- MCP의 개념과 아키텍처(서버/클라이언트/호스트)를 이해한다
- `langchain.mcp.MCPAdapter` 베타 API로 MCP 서버에 연결한다
- `MCPConfig`와 `await adapter.list_tools()` 패턴으로 MCP 도구를 에이전트에 주입한다
- Stdio와 streamable-http 전송 방식의 차이를 안다
- 다중 MCP 서버를 연결하고 인증·Elicitation·미들웨어로 확장한다

== 11.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

print("환경 준비 완료.")
`````)

== 11.2 MCP 개념

_MCP(Model Context Protocol)_는 외부 도구와 컨텍스트를 _표준화된 방식_으로 LLM에 제공하기 위한 오픈 프로토콜입니다. LangChain 1.4에서는 `langchain.mcp.MCPAdapter`가 베타 표면으로 제공되며, FastMCP 클라이언트 수명주기 위에서 도구를 LangChain Tool로 변환합니다.

=== 아키텍처 구성 요소

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구성 요소],
  text(weight: "bold")[역할],
  text(weight: "bold")[예시],
  [_MCP 서버_],
  [도구, 리소스, 프롬프트를 노출],
  [파일 시스템 서버, DB 서버, API 래퍼],
  [_MCP 클라이언트_],
  [서버에 연결하여 도구를 가져옴],
  [`MCPAdapter` / FastMCP `Client`],
  [_호스트_],
  [클라이언트를 관리하고 LLM과 연결],
  [LangChain 에이전트, IDE],
)

`MCPAdapter`는 현재 LangChain Tool 변환에 초점을 둡니다. 프롬프트와 리소스 래퍼는 아직 일대일 대응 API가 없으므로 FastMCP 클라이언트로 직접 읽는 영역입니다.

== 11.3 `langchain[mcp]` 설치와 베타 MCPAdapter

LangChain 1.4 기준 MCP 도구 연동은 `langchain.mcp.MCPAdapter` 베타 표면을 사용합니다. 실행 환경에는 `langchain[mcp]` extra와 MCP 서버 구현에 필요한 `mcp`/`fastmcp` 계열 패키지가 필요합니다.

이전 별도 adapter 패키지는 마이그레이션 비교 대상으로만 다루고, 새 실습 코드는 `MCPAdapter`와 표준 `MCPConfig`를 기준으로 작성합니다.

#code-block(`````python
# MCP 베타 어댑터 설치 명령어
print("MCP 베타 어댑터 설치:")
print("  uv add langchain[mcp] mcp")
print()
print("주요 진입점:")
print("  - from langchain.mcp import MCPAdapter")
print("  - async with MCPAdapter(target) as adapter:")
print("        tools = await adapter.list_tools()")
print("  - target: URL, Path, FastMCP Client, ClientGroup, MCPConfig")
print("  - MCPConfig: {'mcpServers': {'name': {'command': ..., 'args': [...]}}}")
print("참고: list_tools()는 adapter context 안에서 수행하고, 반환된 도구는 client context를 보존합니다.")
`````)

== 11.4 Stdio 전송

_Stdio(Standard I/O)_ 전송은 로컬 서브프로세스로 MCP 서버와 통신합니다. 개발 및 테스트 환경에 적합합니다.

#code-block(`````python
from pathlib import Path
import json, tempfile, sys
server_path = Path(tempfile.gettempdir()) / "lc_mcp_math_server.py"
server_code = """from fastmcp import FastMCP
mcp = FastMCP("math")
@mcp.tool()
def add(a: int, b: int) -> int:
    return a + b
if __name__ == "__main__":
    mcp.run(transport="stdio")
"""
server_path.write_text(server_code)
stdio_config = {"mcpServers": {"math": {"command": sys.executable, "args": [str(server_path)]}}}
print("Stdio MCPConfig:")
print(json.dumps(stdio_config, indent=2, ensure_ascii=False))
print(f"\n서버 파일: {server_path}")
`````)

MCP 서버와 어댑터 연결이 되는지 모델 호출 없이 먼저 확인합니다. 이 셀은 도구 discovery와 직접 tool invocation만 수행하므로 오프라인 검증에 적합합니다.

#code-block(`````python
from langchain.mcp import MCPAdapter

async with MCPAdapter(stdio_config) as adapter:
    tools = await adapter.list_tools()
    add_tool = next(t for t in tools if t.name.endswith("add"))
    result = await add_tool.ainvoke({"a": 2, "b": 3})
print([t.name for t in tools], result[0]["text"])
`````)

== 11.5 SSE/HTTP 전송

_HTTP(streamable-http)_ 전송은 웹 기반 통신으로, 원격 MCP 서버에 연결할 때 사용합니다. 인증 헤더와 커스텀 설정을 지원합니다.

#code-block(`````python
# HTTP/streamable-http 전송 설정 예시
http_config = {
    "mcpServers": {
        "weather": {"url": "https://weather-mcp.example.com/mcp"}
    }
}
import json
print("HTTP MCPConfig:")
print(json.dumps(http_config, indent=2, ensure_ascii=False))
print("\n사용 패턴: async with MCPAdapter(http_config) -> await adapter.list_tools()")
`````)

=== 인증 — FastMCP Client가 인증을 소유

원격 MCP 서버 인증은 서버별 설정 딕셔너리에 임의 `auth` 객체를 넣는 방식이 아니라 _FastMCP `Client`를 먼저 구성_하고 그 클라이언트를 `MCPAdapter`에 넘기는 방식으로 설명합니다. 이렇게 하면 토큰·OAuth·전송 수명주기가 한곳에 묶입니다. 커스텀 HTTP 인증이 필요하면 FastMCP가 쓰는 `httpx2.Auth` 호환 객체를 사용하고, 일반 `httpx.Auth` 객체를 섞지 않습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[방식],
  text(weight: "bold")[예시],
  text(weight: "bold")[비고],
  [정적 토큰],
  [`Client(url, auth=token)`],
  [실습에서는 환경변수에서 토큰 문자열을 읽습니다],
  [OAuth],
  [`Client(url, auth="oauth")`],
  [FastMCP가 OAuth 흐름을 시작합니다. 운영 환경은 영구 토큰 저장소를 별도로 구성합니다],
  [여러 서버],
  [`ClientGroup({"name": Client(...)})`],
  [서버별 인증을 유지한 채 하나의 adapter target으로 넘깁니다],
)

도구 discovery는 `async with MCPAdapter(client_or_group)` 블록에서 수행합니다. 반환된 LangChain 도구는 client context를 보존하므로 블록 밖 agent에도 전달할 수 있습니다.

#code-block(`````python
# FastMCP Client / ClientGroup 기반 인증 구성 예시(객체 생성만 수행)
from fastmcp import Client, ClientGroup

weather_token = "${WEATHER_MCP_TOKEN}"
weather_client = Client("https://weather-mcp.example.com/mcp", auth=weather_token)
calendar_client = Client("https://calendar.example.com/mcp", auth="oauth")
auth_group = ClientGroup({"weather": weather_client, "calendar": calendar_client})
print(type(auth_group).__name__, list(auth_group.clients))
`````)

== 11.6 MCP 도구 로드 및 에이전트 통합

MCP 서버에서 가져온 도구를 LangChain 에이전트에 바인딩하는 패턴입니다.

== 11.7 다중 MCP 서버 연결

여러 서버는 표준 `MCPConfig`의 `mcpServers` 아래에 둡니다. `transport` 키를 직접 넣기보다 `command`/`args` 또는 `url`로 전송 방식을 추론하게 두는 것이 새 표면의 기본 흐름입니다.

#code-block(`````python
# 다중 MCP 서버 설정 예시
import json, sys
multi_server_config = {"mcpServers": {
    "math": {"command": sys.executable, "args": [str(server_path)]},
    "weather": {"url": "https://weather-mcp.example.com/mcp"},
    "database": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-postgres"], "env": {"DATABASE_URL": "postgresql://..."}},
}}
print("다중 MCPConfig:")
print(json.dumps(multi_server_config, indent=2, ensure_ascii=False))
print("도구 이름은 다중 서버에서 server_tool 형식으로 prefix 됩니다.")
`````)

== 11.7b Elicitation — 서버가 사용자 입력을 요청

MCP 서버는 도구 실행 중 사용자에게 추가 입력을 요청할 수 있습니다. `MCPAdapter`를 LangChain agent와 함께 쓰면 현대 MCP 서버가 반환하는 `InputRequiredResult`가 LangGraph interrupt로 노출됩니다. 기존 server-initiated `ctx.elicit(...)` 푸시 방식은 현재 FastMCP/MCP 조합에서 이 interrupt 루프로 답할 수 없으므로, 교육 예제에서는 `InputRequiredResult` 호환 서버를 전제로 둡니다.

`version="v2"` 응답에서는 interrupt payload의 `requests[0].key`를 읽고, 같은 key 아래에 `accept`/`decline`/`cancel` 응답을 넣어 재개합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[`action`],
  text(weight: "bold")[의미],
  [`accept`],
  [사용자가 동의하고 `content`에 값을 제공합니다],
  [`decline`],
  [사용자가 거부했으므로 서버가 대체 흐름을 선택합니다],
  [`cancel`],
  [사용자가 취소했으므로 도구 실행을 중단합니다],
)

#code-block(`````python
# Elicitation — interrupt payload의 requests[0].key로 재개한다
elicit_example = '''
from langgraph.types import Command
first = await agent.ainvoke(input_state, config=config, version="v2")
payload = first.interrupts[0].value; key = payload.requests[0].key
resume = {"responses": {key: {"action": "accept", "content": {"value": "사용자 입력"}}}}
final = await agent.ainvoke(Command(resume=resume), config=config, version="v2")
'''
print(elicit_example)
`````)

== 11.8 도구 호출 미들웨어

MCP 도구도 LangChain Tool로 변환된 뒤에는 일반 도구와 같은 middleware 표면을 사용합니다. 인증은 FastMCP `Client`에 두고, 호출 로깅·정책·응답 필터링은 `@wrap_tool_call` 같은 LangChain middleware에서 처리합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[사용 사례],
  text(weight: "bold")[설명],
  [호출 로깅],
  [MCP 메타데이터가 있는 도구 호출을 기록],
  [요청 정책],
  [위험한 도구 이름이나 인자를 검사],
  [응답 필터링],
  [민감한 정보를 ToolMessage에서 제거],
  [재시도 연결],
  [도구 호출 예외를 보고 LangChain 쪽 재시도 정책 적용],
)

#code-block(`````python
# 도구 호출 정책은 LangChain middleware에서 처리한다
middleware_note = '''
from langchain.agents.middleware import wrap_tool_call
@wrap_tool_call
def guard_mcp_tool(request, handler):
    if (request.tool.metadata or {}).get("mcp"):
        print(f"MCP policy check: {request.tool_call['name']}")
    return handler(request)
'''
print(middleware_note)
`````)

== 11.9b 도구 수명주기 — discovery와 호출 범위

이전 adapter 패키지의 세션 바인딩 헬퍼는 새 `langchain.mcp`의 직접 대응 API가 아닙니다. `list_tools()`는 `async with MCPAdapter(...)` 블록 안에서 호출하고, 반환된 도구는 client context를 보존해 블록 밖에서도 다시 연결해 호출할 수 있습니다. 실습에서는 한 번의 discovery와 agent 호출을 같은 함수 안에 두면 흐름을 읽기 쉽고, 같은 서버 세션 상태나 동시 호출 정책이 중요한 경우에는 scope를 명시적으로 관리합니다.

#code-block(`````python
# Adapter context에서 도구를 발견한 뒤 agent에 전달
stateful_example = '''
from langchain.mcp import MCPAdapter
async def run_with_adapter_lifetime():
    async with MCPAdapter(stdio_config) as adapter:
        tools = await adapter.list_tools()
        agent = create_agent(model=model, tools=tools)
        return await agent.ainvoke({"messages": [{"role": "user", "content": "2와 3을 더하고 결과를 5와 곱해주세요."}]})
'''
print(stateful_example)
`````)

== 11.10 커스텀 MCP 서버 작성

_FastMCP_ 라이브러리를 쓰면 데코레이터로 간편하게 MCP 서버를 구축할 수 있습니다.

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
  [_MCP 개념_],
  [외부 도구와 컨텍스트를 표준화된 방식으로 LLM에 제공하는 오픈 프로토콜입니다],
  [_Stdio 전송_],
  [로컬 서브프로세스를 통한 통신으로, 개발/테스트에 적합합니다],
  [_Streamable HTTP_],
  [웹 기반 통신으로, 원격 서버 연결 및 인증을 지원합니다],
  [_에이전트 통합_],
  [`async with MCPAdapter(...)` 안에서 `await adapter.list_tools()` 후 `create_agent(tools=...)`로 연결합니다],
  [_다중 서버_],
  [`MCPConfig.mcpServers` 또는 FastMCP `ClientGroup`으로 여러 서버를 묶습니다],
  [_인증_],
  [bearer/OAuth 인증은 `MCPAdapter`에 넘기기 전 FastMCP `Client`에 구성합니다],
  [_Elicitation_],
  [서버의 추가 입력 요청은 `payload.requests[0].key` 기반 interrupt/resume 흐름으로 처리합니다],
  [_미들웨어_],
  [도구 호출 로깅·정책은 `\@wrap_tool_call` 같은 LangChain middleware로 적용합니다],
  [_수명주기_],
  [`list_tools()`는 adapter context 안에서 호출하고, 반환된 도구는 client context를 보존합니다],
)


#references-box[
- #link("../docs/langchain/16-mcp.md")[MCP (Model Context Protocol)]
]
#chapter-end()
