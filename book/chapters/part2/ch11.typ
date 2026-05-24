// Auto-generated from 11_mcp.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "MCP (Model Context Protocol)")

에이전트가 사용할 수 있는 도구를 일일이 코드로 작성하는 대신, 표준화된 프로토콜을 통해 외부 도구 서버에 연결할 수 있다면 어떨까요? MCP(Model Context Protocol)는 바로 이 목적을 위해 만들어진 개방형 표준입니다. 이 장에서는 MCP의 아키텍처를 이해하고, `langchain-mcp-adapters`를 사용하여 LangChain 에이전트에 MCP 서버의 도구를 통합하는 방법을 학습합니다.

MCP의 핵심 가치는 _도구 제공자와 도구 소비자의 분리_입니다. 데이터베이스 관리자가 MCP 서버를 한 번 구현하면, Claude, ChatGPT, LangChain 에이전트 등 MCP를 지원하는 모든 호스트 애플리케이션이 별도의 통합 코드 없이 해당 도구를 사용할 수 있습니다. 이는 USB가 다양한 장치를 표준화된 인터페이스로 연결하는 것과 유사합니다.

#learning-header()
MCP를 통해 외부 도구와 컨텍스트를 에이전트에 연결하는 방법을 알아봅니다.

이 노트북에서 다루는 내용:
- MCP의 개념과 아키텍처(서버/클라이언트/호스트)를 이해한다
- `langchain-mcp-adapters` 패키지로 MCP 서버에 연결한다
- `create_agent(model=..., tools=await client.get_tools())` 패턴으로 에이전트와 MCP 도구를 통합한다
- Stdio와 SSE 전송 방식의 차이를 안다
- 다중 MCP 서버를 연결하는 방법을 익힌다

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
#output-block(`````
환경 준비 완료.
`````)

== 11.2 MCP 개념

_MCP(Model Context Protocol)_는 외부 도구와 컨텍스트를 _표준화된 방식_으로 LLM에 제공하기 위한 오픈 프로토콜입니다.

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
  [`MultiServerMCPClient`],
  [_호스트_],
  [클라이언트를 관리하고 LLM과 연결],
  [LangChain 에이전트, IDE],
)

=== 핵심 리소스 타입

- _Tools_: 에이전트가 호출할 수 있는 실행 가능한 함수
- _Resources_: 파일, DB 레코드 등의 데이터 (LangChain Blob 객체로 변환)
- _Prompts_: 재사용 가능한 프롬프트 템플릿

=== 왜 MCP인가?

MCP 이전에는 각 도구마다 개별적으로 연결 코드를 작성해야 했습니다. MCP는 이를 _하나의 표준 프로토콜_로 통합하여:
- 도구 제공자는 한 번만 MCP 서버를 구현하면 됩니다
- LLM 호스트는 MCP 클라이언트 하나로 모든 도구에 접근할 수 있습니다
- 생태계 전체에서 도구를 재사용할 수 있습니다

MCP의 3계층 아키텍처를 좀 더 자세히 살펴보면: _호스트(Host)_는 사용자의 LangChain 에이전트 애플리케이션입니다. 호스트 안에서 _클라이언트(Client)_가 MCP 프로토콜을 사용하여 외부 _서버(Server)_와 통신합니다. 클라이언트는 서버에 "어떤 도구를 제공하는가?"라고 물어 도구 목록을 동적으로 발견(discover)하고, LLM이 도구 호출을 결정하면 해당 서버에 실행 요청을 보냅니다.

이제 LangChain에서 이 프로토콜을 어떻게 사용하는지 살펴보겠습니다.

== 11.3 langchain-mcp-adapters 설치

LangChain에서 MCP를 사용하려면 `langchain-mcp-adapters` 패키지가 필요합니다.

#code-block(`````python
# MCP 어댑터 설치 명령어
print("MCP 어댑터 설치:")
print("  pip install langchain-mcp-adapters")
print()
print("주요 컴포넌트:")
print("  - MultiServerMCPClient: 여러 MCP 서버를 관리하는 클라이언트")
print("  - client.get_tools(): MCP 서버에서 도구를 LangChain Tool로 변환")
print("  - client.get_resources(): MCP 서버에서 리소스를 LangChain Blob으로 변환")
`````)
#output-block(`````
MCP 어댑터 설치:
  pip install langchain-mcp-adapters

주요 컴포넌트:
  - MultiServerMCPClient: 여러 MCP 서버를 관리하는 클라이언트
  - client.get_tools(): MCP 서버에서 도구를 LangChain Tool로 변환
  - client.get_resources(): MCP 서버에서 리소스를 LangChain Blob으로 변환
`````)

MCP 어댑터를 설치했으면, 실제로 MCP 서버와 통신하는 두 가지 전송 방식을 알아보겠습니다. 전송 방식의 선택은 MCP 서버의 위치(로컬 vs 원격)에 따라 달라집니다.

== 11.4 Stdio 전송

_Stdio(Standard I/O)_ 전송은 로컬 서브프로세스를 통해 MCP 서버와 통신합니다. 클라이언트가 MCP 서버를 자식 프로세스로 직접 실행하고, `stdin`/`stdout`을 통해 JSON-RPC 메시지를 교환합니다. 별도의 네트워크 설정이 불필요하고 프로세스 생명주기가 클라이언트에 의해 자동 관리되므로, 개발 및 테스트 환경에 적합합니다.

#code-block(`````python
# Stdio 전송 설정 예시 (실제 실행하지 않음)
stdio_config = {
    "math_server": {
        "transport": "stdio",
        "command": "python",
        "args": ["math_server.py"],
    }
}

print("Stdio 전송 설정:")
import json
print(json.dumps(stdio_config, indent=2))
print()
print("사용 패턴:")
print("  async with MultiServerMCPClient(stdio_config) as client:")
print("      tools = client.get_tools()")
print()
print("특징:")
print("  - 로컬 서브프로세스로 통신 (stdin/stdout)")
print("  - 개발/테스트 환경에 적합")
print("  - 별도 서버 실행 불필요 — 자동으로 프로세스 시작")
`````)
#output-block(`````
Stdio 전송 설정:
{
  "math_server": {
    "transport": "stdio",
    "command": "python",
    "args": [
      "math_server.py"
    ]
  }
}

사용 패턴:
  async with MultiServerMCPClient(stdio_config) as client:
      tools = client.get_tools()

특징:
  - 로컬 서브프로세스로 통신 (stdin/stdout)
  - 개발/테스트 환경에 적합
  - 별도 서버 실행 불필요 — 자동으로 프로세스 시작
`````)

Stdio가 로컬 개발에 적합하다면, 프로덕션 환경에서는 원격 서버와 통신할 수 있는 HTTP 기반 전송이 필요합니다.

== 11.5 SSE/HTTP 전송

_HTTP(streamable-http)_ 전송은 웹 기반 통신으로, 원격 MCP 서버에 연결할 때 사용합니다. 인증 헤더와 커스텀 설정을 지원합니다. `streamable_http`는 최신 MCP 사양에서 권장하는 전송 방식이며, 기존의 SSE(Server-Sent Events) 전송은 레거시로 분류되었으나 여전히 지원됩니다.

#tip-box[`streamable_http`와 `sse`의 차이: `streamable_http`는 단일 HTTP 엔드포인트에서 요청/응답과 서버 푸시를 모두 처리하며, `sse`는 이벤트 스트리밍과 요청을 별도 채널로 분리합니다. 새로운 프로젝트에서는 `streamable_http`를 사용하세요.]

#code-block(`````python
# HTTP/streamable-http 전송 설정 예시 (실제 실행하지 않음)
http_config = {
    "weather_server": {
        "transport": "streamable_http",
        "url": "https://weather-mcp.example.com/mcp",
        "headers": {
            "Authorization": "Bearer YOUR_API_KEY"
        },
    }
}

print("HTTP 전송 설정:")
import json
print(json.dumps(http_config, indent=2))
print()
print("사용 패턴:")
print("  async with MultiServerMCPClient(http_config) as client:")
print("      tools = client.get_tools()")
print()
print("전송 방식 비교:")
print("  | 전송 방식        | 사용 사례         | 인증 지원 |")
print("  |-----------------|------------------|----------|")
print("  | stdio           | 로컬 개발/테스트   | N/A      |")
print("  | streamable_http | 원격 서버 연결     | 헤더 지원  |")
print("  | sse             | 레거시 SSE 서버   | 헤더 지원  |")
`````)
#output-block(`````
HTTP 전송 설정:
{
  "weather_server": {
    "transport": "streamable_http",
    "url": "https://weather-mcp.example.com/mcp",
    "headers": {
      "Authorization": "Bearer YOUR_API_KEY"
    }
  }
}

사용 패턴:
  async with MultiServerMCPClient(http_config) as client:
      tools = client.get_tools()

전송 방식 비교:
  | 전송 방식        | 사용 사례         | 인증 지원 |
  |-----------------|------------------|----------|
  | stdio           | 로컬 개발/테스트   | N/A      |
  | streamable_http | 원격 서버 연결     | 헤더 지원  |
  | sse             | 레거시 SSE 서버   | 헤더 지원  |
`````)

전송 방식을 이해했으니, 이제 MCP 서버에서 가져온 도구를 실제로 에이전트에 연결하는 과정을 살펴보겠습니다.

== 11.6 MCP 도구 로드 및 에이전트 통합

MCP 서버에서 가져온 도구를 LangChain 에이전트에 바인딩하는 패턴입니다. 핵심은 `client.get_tools()` 메서드입니다. 이 메서드는 MCP 서버가 노출하는 도구 목록을 자동으로 발견하고, 각 도구의 이름, 설명, 파라미터 스키마를 LangChain의 `Tool` 객체로 변환합니다. 변환된 도구는 `create_agent(tools=mcp_tools)`에 그대로 전달할 수 있습니다.

=== 주요 함수 시그니처

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[함수],
  text(weight: "bold")[설명],
  [`client.get_tools()`],
  [모든 등록 서버의 도구를 LangChain `Tool` 리스트로 반환],
  [`client.get_resources(server_name)`],
  [특정 서버의 리소스를 LangChain `Blob` 리스트로 반환],
  [`client.get_prompt(server_name, prompt_name, arguments={...})`],
  [서버에 등록된 프롬프트 템플릿을 가져옴],
  [`load_mcp_tools(session)`],
  [열린 세션에서 도구 목록을 LangChain `Tool`로 변환 (stateful 패턴)],
  [`load_mcp_resources(session, uris=[...])`],
  [열린 세션에서 지정한 URI의 리소스를 로드],
)

#code-block(`````python
# MCP 도구를 에이전트에 통합하는 패턴 (개념 코드)
print("MCP 도구 → 에이전트 통합 패턴:")
print("=" * 50)
print("""
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain.agents import create_agent

mcp_config = {
    "math": {
        "transport": "stdio",
        "command": "python",
        "args": ["math_server.py"],
    }
}

async with MultiServerMCPClient(mcp_config) as client:
    # 1. MCP 서버에서 도구 가져오기
    mcp_tools = await client.get_tools()

    # 2. 에이전트에 도구 전달
    agent = create_agent(
        model="gpt-5.4",
        tools=mcp_tools,
    )

    # 3. 에이전트 실행
    result = agent.invoke(
        {"messages": [{"role": "user", "content": "2 + 3은?"}]}
    )
""")
print("핵심: client.get_tools()가 MCP 도구를 LangChain Tool로 자동 변환합니다.")
`````)
#output-block(`````
MCP 도구 → 에이전트 통합 패턴:
==================================================

from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain.agents import create_agent

mcp_config = {
    "math": {
        "transport": "stdio",
        "command": "python",
        "args": ["math_server.py"],
    }
}

async with MultiServerMCPClient(mcp_config) as client:
    # 1. MCP 서버에서 도구 가져오기
    mcp_tools = await client.get_tools()

    # 2. 에이전트에 도구 전달
    agent = create_agent(
        model="gpt-5.4",
        tools=mcp_tools,
    )

    # 3. 에이전트 실행
    result = agent.invoke(
        {"messages": [{"role": "user", "content": "2 + 3은?"}]}
    )

핵심: client.get_tools()가 MCP 도구를 LangChain Tool로 자동 변환합니다.
`````)

단일 서버 연결을 마스터했다면, 실전에서는 여러 MCP 서버를 동시에 연결하는 경우가 더 많습니다. 수학 연산 서버, 날씨 API 서버, 데이터베이스 서버 등을 하나의 에이전트에서 모두 사용하는 시나리오를 살펴보겠습니다.

== 11.7 다중 MCP 서버 연결

`MultiServerMCPClient`는 이름 그대로 여러 MCP 서버를 동시에 관리할 수 있습니다. 설정 딕셔너리에 여러 서버를 나열하면, 클라이언트가 모든 서버에 동시에 연결하고 각 서버의 도구를 하나의 통합 리스트로 반환합니다.

#warning-box[여러 MCP 서버의 도구가 같은 이름을 가질 수 있습니다. 예를 들어 두 서버 모두 `search`라는 도구를 제공하면 충돌이 발생합니다. `MultiServerMCPClient`는 기본적으로 서버 이름을 접두사로 붙여 이를 방지하지만, 명시적으로 도구 이름을 확인하는 것이 안전합니다.]

#code-block(`````python
# 다중 MCP 서버 설정 예시
multi_server_config = {
    "math_server": {
        "transport": "stdio",
        "command": "python",
        "args": ["math_server.py"],
    },
    "weather_server": {
        "transport": "streamable_http",
        "url": "https://weather-mcp.example.com/mcp",
    },
    "database_server": {
        "transport": "stdio",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-postgres"],
        "env": {"DATABASE_URL": "postgresql://..."},
    },
}

print("다중 MCP 서버 설정:")
import json
print(json.dumps(multi_server_config, indent=2, ensure_ascii=False))
print()
print("사용 패턴:")
print("  async with MultiServerMCPClient(multi_server_config) as client:")
print("      tools = client.get_tools()  # 모든 서버의 도구를 한 번에 로드")
print("      # tools 리스트에 math, weather, database 도구가 모두 포함")
print()
print("참고: 기본적으로 stateless — 각 도구 호출마다 새 세션 생성 후 정리")
`````)
#output-block(`````
다중 MCP 서버 설정:
{
  "math_server": {
    "transport": "stdio",
    "command": "python",
    "args": [
      "math_server.py"
    ]
  },
  "weather_server": {
    "transport": "streamable_http",
    "url": "https://weather-mcp.example.com/mcp"
  },
  "database_server": {
    "transport": "stdio",
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-postgres"
    ],
    "env": {
      "DATABASE_URL": "postgresql://..."
    }
  }
}

사용 패턴:
  async with MultiServerMCPClient(multi_server_config) as client:
      tools = client.get_tools()  # 모든 서버의 도구를 한 번에 로드
      # tools 리스트에 math, weather, database 도구가 모두 포함
... (truncated)
`````)

=== Stateful sessions

기본 `client.get_tools()`는 각 도구 호출마다 새 세션을 열고 닫는 _stateless_ 모드입니다. 같은 세션 안에서 여러 호출을 묶고 싶다면 `client.session(server_name)`으로 명시적 세션을 엽니다.

#code-block(`````python
async with client.session("math_server") as session:
    tools = await load_mcp_tools(session)
    # 같은 세션을 공유한 채 여러 도구 호출
    result1 = await tools[0].ainvoke({"a": 1, "b": 2})
    result2 = await tools[1].ainvoke({"a": 3, "b": 4})
`````)

== 11.8 MCP 인증

원격 MCP 서버에 접속할 때는 두 가지 인증 트랙을 사용합니다.

=== 트랙 A — 정적 헤더

가장 단순한 방식으로, 헤더에 토큰을 직접 넣습니다. CI/CD 등 사전 발급된 키를 사용할 때 적합합니다.

#code-block(`````python
http_config = {
    "weather_server": {
        "transport": "streamable_http",
        "url": "https://weather-mcp.example.com/mcp",
        "headers": {"Authorization": "Bearer YOUR_API_KEY"},
    }
}
`````)

=== 트랙 B — `httpx.Auth` 인터페이스

토큰 갱신·서명 등 동적 인증이 필요하면 `httpx.Auth` 구현체를 전달합니다.

#code-block(`````python
import httpx

class BearerAuth(httpx.Auth):
    def __init__(self, token: str):
        self.token = token

    def auth_flow(self, request):
        request.headers["Authorization"] = f"Bearer {self.token}"
        yield request

http_config = {
    "weather_server": {
        "transport": "streamable_http",
        "url": "https://weather-mcp.example.com/mcp",
        "auth": BearerAuth(token="..."),
    }
}
`````)

=== 트랙 C — MCP SDK OAuth2

MCP Python SDK가 제공하는 `mcp.client.auth.oauth2` 모듈을 사용하면 표준 OAuth2 흐름(authorization code, refresh token)을 그대로 따를 수 있습니다.

#code-block(`````python
from mcp.client.auth.oauth2 import OAuth2ClientCredentials

auth = OAuth2ClientCredentials(
    token_url="https://auth.example.com/token",
    client_id="my-client",
    client_secret="...",
    scope="mcp.tools",
)

http_config = {
    "secure_server": {
        "transport": "streamable_http",
        "url": "https://secure-mcp.example.com/mcp",
        "auth": auth,
    }
}
`````)

== 11.9 Elicitation — 서버가 사용자 입력을 요청

Elicitation은 MCP 서버가 도구 실행 중에 _추가 입력_을 클라이언트(호스트)에 요청하는 메커니즘입니다. 호스트가 사용자에게 보여 줄 폼을 띄우고, 응답을 `ElicitResult`로 돌려줍니다.

#code-block(`````python
from mcp import ElicitResult, Callbacks

async def on_elicitation(request):
    # 호스트 측에서 사용자에게 폼을 보여주고 응답 수집
    user_input = await show_form(request.schema)
    return ElicitResult(
        action="accept",   # "accept" | "decline" | "cancel"
        content={"city": user_input["city"], "unit": "celsius"},
    )

callbacks = Callbacks(on_elicitation=on_elicitation)

async with MultiServerMCPClient(config, callbacks=callbacks) as client:
    tools = await client.get_tools()
`````)

#tip-box[`action="accept"`는 사용자가 값을 제공한 경우, `"decline"`은 사용자가 거절한 경우, `"cancel"`은 도구 실행 자체를 중단하라는 신호로 사용합니다.]

== 11.10 도구 인터셉터

_Tool Interceptor_는 MCP 도구 호출을 가로채는 미들웨어입니다. 런타임 컨텍스트에 접근하거나, 요청/응답을 수정하거나, 재시도 로직을 구현할 수 있습니다.

=== 인터셉터 사용 사례

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[사용 사례],
  text(weight: "bold")[설명],
  [인증 주입],
  [런타임에 사용자별 토큰 전달],
  [요청 수정],
  [도구 호출 파라미터 변환],
  [응답 필터링],
  [민감한 정보 제거],
  [재시도 로직],
  [실패 시 자동 재시도],
  [로깅],
  [도구 호출 추적],
)

#code-block(`````python
# 도구 인터셉터 예시 (개념 코드)
print("도구 인터셉터 패턴:")
print("=" * 50)
print("""
from langchain_mcp_adapters.client import MultiServerMCPClient

# 인터셉터 함수 정의
async def auth_interceptor(request, context):
    \"\"\"런타임 컨텍스트에서 사용자 토큰을 주입합니다.\"\"\" 
    user_token = context.get("user_token", "")
    request.params["auth_token"] = user_token
    return request

async def logging_interceptor(request, context):
    \"\"\"도구 호출을 로깅합니다.\"\"\"
    print(f"Tool call: {request.tool_name}")
    return request

# 인터셉터를 클라이언트에 전달
async with MultiServerMCPClient(
    config,
    interceptors=[auth_interceptor, logging_interceptor],
) as client:
    tools = client.get_tools()
""")
print("인터셉터는 도구 호출 전에 순서대로 실행됩니다.")
`````)

=== 인터셉터에서 `Command` 반환

인터셉터는 단순히 요청을 가공하는 것을 넘어, LangGraph의 `Command` 객체를 반환하여 _상태 업데이트_와 _다음 노드 지정_까지 수행할 수 있습니다.

#code-block(`````python
from langgraph.types import Command

async def logging_interceptor(request, context):
    """도구 호출을 로깅하면서 상태에 트레이스를 누적."""
    print(f"[interceptor] tool={request.tool_name}")
    return Command(
        update={"tool_calls_log": [request.tool_name]},
        goto="tools",
    )
`````)

이 패턴은 인터셉터에서 가드레일을 적용하다 위험 호출이 감지되면 `goto="human_review"`로 보내는 식의 분기 로직을 구현할 때 유용합니다.

#output-block(`````
도구 인터셉터 패턴:
==================================================

from langchain_mcp_adapters.client import MultiServerMCPClient

# 인터셉터 함수 정의
async def auth_interceptor(request, context):
    """런타임 컨텍스트에서 사용자 토큰을 주입합니다.""" 
    user_token = context.get("user_token", "")
    request.params["auth_token"] = user_token
    return request

async def logging_interceptor(request, context):
    """도구 호출을 로깅합니다."""
    print(f"Tool call: {request.tool_name}")
    return request

# 인터셉터를 클라이언트에 전달
async with MultiServerMCPClient(
    config,
    interceptors=[auth_interceptor, logging_interceptor],
) as client:
    tools = client.get_tools()

인터셉터는 도구 호출 전에 순서대로 실행됩니다.
`````)

지금까지 기존 MCP 서버에 연결하는 방법을 배웠습니다. 하지만 조직 내부의 API나 비즈니스 로직을 MCP 도구로 노출하려면 직접 MCP 서버를 작성해야 합니다.

== 11.11 커스텀 MCP 서버 작성

_FastMCP_ 라이브러리를 사용하면 데코레이터로 간편하게 MCP 서버를 구축할 수 있습니다. `@mcp.tool()` 데코레이터를 함수에 붙이면 해당 함수가 MCP 도구로 자동 등록되며, 함수의 타입 힌트와 독스트링이 도구의 파라미터 스키마와 설명으로 변환됩니다.

#code-block(`````python
# 커스텀 MCP 서버 예시 (FastMCP)
print("커스텀 MCP 서버 작성 (FastMCP):")
print("=" * 50)
print("""
# my_server.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-tools")

@mcp.tool()
def add(a: int, b: int) -> int:
    \"\"\"두 수를 더합니다.\"\"\"
    return a + b

@mcp.tool()
def multiply(a: int, b: int) -> int:
    \"\"\"두 수를 곱합니다.\"\"\"
    return a * b

@mcp.resource("config://app")
def get_config() -> str:
    \"\"\"앱 설정을 반환합니다.\"\"\"
    return '{"version": "1.0", "debug": false}'

if __name__ == "__main__":
    mcp.run(transport="stdio")
""")
print("실행 방법:")
print("  1. Stdio: python my_server.py")
print("  2. HTTP:  mcp.run(transport='streamable-http', port=8080)")
print()
print("LangChain 연결:")
print('  config = {"my_tools": {"transport": "stdio", "command": "python", "args": ["my_server.py"]}}')
`````)
#output-block(`````
커스텀 MCP 서버 작성 (FastMCP):
==================================================

# my_server.py
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-tools")

@mcp.tool()
def add(a: int, b: int) -> int:
    """두 수를 더합니다."""
    return a + b

@mcp.tool()
def multiply(a: int, b: int) -> int:
    """두 수를 곱합니다."""
    return a * b

@mcp.resource("config://app")
def get_config() -> str:
    """앱 설정을 반환합니다."""
    return '{"version": "1.0", "debug": false}'

if __name__ == "__main__":
    mcp.run(transport="stdio")

실행 방법:
  1. Stdio: python my_server.py
  2. HTTP:  mcp.run(transport='streamable-http', port=8080)

... (truncated)
`````)

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
  [_SSE/HTTP 전송_],
  [웹 기반 통신으로, 원격 서버 연결 및 인증을 지원합니다],
  [_에이전트 통합_],
  [`client.get_tools()` → `create_agent(tools=mcp_tools)`로 연결합니다],
  [_다중 서버_],
  [`MultiServerMCPClient`에 여러 서버를 설정하여 동시 관리합니다],
  [_인터셉터_],
  [도구 호출을 가로채 인증, 로깅, 수정 등의 미들웨어를 적용합니다],
  [_커스텀 서버_],
  [`FastMCP`의 데코레이터로 간편하게 MCP 서버를 구축합니다],
)

MCP를 통해 에이전트의 도구 생태계를 외부로 확장하는 방법을 배웠습니다. 다음 장에서는 에이전트의 응답을 사용자에게 실시간으로 전달하는 _스트리밍_ 기법을 학습합니다. 백엔드의 `astream_events()`부터 프론트엔드의 React `useStream` 훅까지, 전체 스트리밍 파이프라인을 다룹니다.

#references-box[
- #link("../docs/langchain/16-mcp.md")[MCP (Model Context Protocol)]
]
#chapter-end()
