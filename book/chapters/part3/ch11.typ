// Auto-generated from 11_local_server.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "로컬 서버")

== 학습 목표
#learning-objectives([`langgraph dev` CLI로 개발 서버를 실행하는 방법을 안다], [LangGraph Studio와 연동하여 시각적으로 디버깅한다], [`langgraph.json` 설정 파일을 작성한다], [Python SDK로 로컬 서버를 호출한다], [배포 준비 과정을 이해한다])

== 11.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 11.2 LangGraph CLI 설치

LangGraph 로컬 서버를 실행하려면 CLI를 먼저 설치해야 합니다.
`langgraph-cli[inmem]` 패키지에는 인메모리 모드가 포함되어 개발·테스트에 적합합니다.

#code-block(`````python
# LangGraph CLI 설치 명령어
print("=== pip으로 설치 (Python >= 3.11) ===")
print('  $ pip install -U "langgraph-cli[inmem]"')
print()
print("=== uv로 설치 ===")
print('  $ uv add "langgraph-cli[inmem]"')
print()
print("설치 후 확인:")
print("  $ langgraph --version")
`````)
#output-block(`````
=== pip으로 설치 (Python >= 3.11) ===
  $ pip install -U "langgraph-cli[inmem]"

=== uv로 설치 ===
  $ uv add "langgraph-cli[inmem]"

설치 후 확인:
  $ langgraph --version
`````)

== 11.3 프로젝트 생성

`langgraph new` 명령으로 프로젝트 템플릿을 생성할 수 있습니다.
템플릿을 지정하지 않으면 인터랙티브 메뉴가 표시됩니다.

#code-block(`````python
# 프로젝트 생성 명령어
print("=== 템플릿으로 새 프로젝트 생성 ===")
print("  $ langgraph new my-agent --template new-langgraph-project-python")
print()
print("=== 인터랙티브 메뉴로 생성 ===")
print("  $ langgraph new my-agent")
print()
print("=== 생성 후 의존성 설치 ===")
print("  # pip 사용")
print("  $ cd my-agent && pip install -e .")
print()
print("  # uv 사용")
print("  $ cd my-agent && uv sync")
print()
print("=== 생성되는 파일 구조 ===")
print("  my-agent/")
print("  ├── langgraph.json   # 그래프 설정")
print("  ├── .env.example     # 환경 변수 템플릿")
print("  ├── pyproject.toml   # 의존성 정의")
print("  └── src/")
print("      └── agent.py     # 에이전트 코드")
`````)
#output-block(`````
=== 템플릿으로 새 프로젝트 생성 ===
  $ langgraph new my-agent --template new-langgraph-project-python

=== 인터랙티브 메뉴로 생성 ===
  $ langgraph new my-agent

=== 생성 후 의존성 설치 ===
  # pip 사용
  $ cd my-agent && pip install -e .

  # uv 사용
  $ cd my-agent && uv sync

=== 생성되는 파일 구조 ===
  my-agent/
  ├── langgraph.json   # 그래프 설정
  ├── .env.example     # 환경 변수 템플릿
  ├── pyproject.toml   # 의존성 정의
  └── src/
      └── agent.py     # 에이전트 코드
`````)

== 11.4 langgraph.json 설정

`langgraph.json`은 LangGraph 프로젝트의 핵심 설정 파일입니다.
그래프 정의 위치, 의존성, 환경 변수 파일 등을 지정합니다.

#code-block(`````python
import json

# langgraph.json 설정 예시
config = {
    "dependencies": ["."],
    "graphs": {
        "agent": "./src/agent.py:graph"
    },
    "env": ".env"
}

print("langgraph.json 예시:")
print(json.dumps(config, indent=2))
print()
print("주요 필드:")
print('  dependencies: 설치할 패키지 경로 목록')
print('  graphs:       그래프 이름 → 모듈:변수 매핑')
print('  env:          환경 변수 파일 경로')
`````)
#output-block(`````
langgraph.json 예시:
{
  "dependencies": [
    "."
  ],
  "graphs": {
    "agent": "./src/agent.py:graph"
  },
  "env": ".env"
}

주요 필드:
  dependencies: 설치할 패키지 경로 목록
  graphs:       그래프 이름 → 모듈:변수 매핑
  env:          환경 변수 파일 경로
`````)

== 11.5 개발 서버 실행

`langgraph dev` 명령으로 로컬 개발 서버를 실행합니다.

#code-block(`````bash
$ langgraph dev
`````)

_예상 출력:_
#code-block(`````python
Ready!
- API: http://127.0.0.1:2024
- Docs: http://127.0.0.1:2024/docs
- Studio: https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
`````)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[URL],
  text(weight: "bold")[용도],
  [`http://127.0.0.1:2024`],
  [API 엔드포인트],
  [`http://127.0.0.1:2024/docs`],
  [API 문서 (Swagger)],
  [`https://smith.langchain.com/studio/...`],
  [LangGraph Studio 인터페이스],
)

#tip-box[_Safari 사용자:_ `langgraph dev --tunnel` 플래그를 사용하여 localhost 서버에 대한 보안 연결을 설정하세요.]

== 11.6 LangGraph Studio 연동

LangGraph Studio는 `langgraph dev` 실행 시 자동으로 제공되는 시각적 디버깅 도구입니다.

_주요 기능:_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [그래프 시각화],
  [노드와 엣지 구조를 한눈에 파악],
  [실시간 추적],
  [각 노드의 실행 과정을 실시간으로 관찰],
  [상태 검사],
  [각 단계의 상태(state) 값을 확인·수정],
  [인터랙티브 테스트],
  [입력을 바꿔가며 그래프 실행 테스트],
)

Studio는 브라우저 기반이므로 별도 설치가 필요 없습니다.
커스텀 서버 주소를 사용하는 경우, Studio URL의 `baseUrl` 파라미터를 변경하면 됩니다.

== 11.7 Python SDK — 비동기 클라이언트

비동기 클라이언트는 `langgraph_sdk.get_client()`로 생성합니다.
`asyncio` 기반으로 동작하며, 스트리밍 응답을 효율적으로 처리합니다.

#code-block(`````python
# 비동기 클라이언트 사용 패턴 (서버 실행 중일 때 사용)
print("""from langgraph_sdk import get_client
import asyncio

client = get_client(url="http://localhost:2024")

async def main():
    async for chunk in client.runs.stream(
        None,
        "agent",
        input={
            "messages": [{
                "role": "human",
                "content": "What is LangGraph?",
            }],
        },
    ):
        print(f"Event type: {chunk.event}...")
        print(chunk.data)

asyncio.run(main())
""")
print("# 위 코드는 langgraph dev 서버가 실행 중일 때 사용합니다.")
`````)
#output-block(`````
from langgraph_sdk import get_client
import asyncio

client = get_client(url="http://localhost:2024")

async def main():
    async for chunk in client.runs.stream(
        None,
        "agent",
        input={
            "messages": [{
                "role": "human",
                "content": "What is LangGraph?",
            }],
        },
    ):
        print(f"Event type: {chunk.event}...")
        print(chunk.data)

asyncio.run(main())

# 위 코드는 langgraph dev 서버가 실행 중일 때 사용합니다.
`````)

== 11.8 Python SDK — 동기 클라이언트

동기 클라이언트는 `langgraph_sdk.get_sync_client()`로 생성합니다.
비동기가 필요 없는 간단한 스크립트나 테스트에 적합합니다.

#code-block(`````python
# 동기 클라이언트 사용 패턴 (서버 실행 중일 때 사용)
print("""from langgraph_sdk import get_sync_client

client = get_sync_client(url="http://localhost:2024")

for chunk in client.runs.stream(
    None,
    "agent",
    input={
        "messages": [{
            "role": "human",
            "content": "What is LangGraph?",
        }],
    },
    stream_mode="messages-tuple",
):
    print(f"Event: {chunk.event}...")
    print(chunk.data)
""")
print("# 위 코드는 langgraph dev 서버가 실행 중일 때 사용합니다.")
`````)
#output-block(`````
from langgraph_sdk import get_sync_client

client = get_sync_client(url="http://localhost:2024")

for chunk in client.runs.stream(
    None,
    "agent",
    input={
        "messages": [{
            "role": "human",
            "content": "What is LangGraph?",
        }],
    },
    stream_mode="messages-tuple",
):
    print(f"Event: {chunk.event}...")
    print(chunk.data)

# 위 코드는 langgraph dev 서버가 실행 중일 때 사용합니다.
`````)

== 11.9 REST API 호출

LangGraph 로컬 서버는 REST API를 제공합니다.
`curl`이나 HTTP 클라이언트로 직접 호출할 수 있습니다.

#code-block(`````bash
curl -s --request POST \
    --url "http://localhost:2024/runs/stream" \
    --header 'Content-Type: application/json' \
    --data '{
        "assistant_id": "agent",
        "input": {
            "messages": [{
                "role": "human",
                "content": "What is LangGraph?"
            }]
        },
        "stream_mode": "messages-tuple"
    }'
`````)

API 문서는 `http://localhost:2024/docs`에서 확인할 수 있습니다.

== 11.10 배포 준비 체크리스트

로컬 개발이 완료되면 프로덕션 배포를 준비합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  text(weight: "bold")[확인],
  [`langgraph.json`],
  [그래프 경로·의존성·환경 변수 설정 완료],
  [☐],
  [`.env` 파일],
  [API 키 등 환경 변수 설정],
  [☐],
  [의존성 정리],
  [`pyproject.toml` 또는 `requirements.txt` 정리],
  [☐],
  [로컬 테스트],
  [`langgraph dev`로 로컬에서 정상 동작 확인],
  [☐],
  [Studio 확인],
  [LangGraph Studio에서 그래프 구조 확인],
  [☐],
  [SDK 테스트],
  [Python SDK 또는 REST API로 호출 테스트],
  [☐],
  [영속 저장소],
  [프로덕션용 체크포인터(예: PostgresSaver) 설정],
  [☐],
  [관측성],
  [LangSmith 또는 Langfuse 트레이싱 설정],
  [☐],
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
  [CLI 설치],
  [`pip install "langgraph-cli[inmem]"` 또는 `uv add`],
  [프로젝트 생성],
  [`langgraph new`로 템플릿 기반 프로젝트 생성],
  [langgraph.json],
  [그래프 경로, 의존성, 환경 변수를 정의하는 설정 파일],
  [Studio],
  [`langgraph dev` 실행 시 자동 제공되는 시각적 디버깅 도구],
  [SDK 비동기],
  [`get_client()`로 비동기 스트리밍 호출],
  [SDK 동기],
  [`get_sync_client()`로 동기 스트리밍 호출],
  [REST API],
  [`curl`로 `/runs/stream` 엔드포인트 직접 호출],
)


#references-box[
- #link("../docs/langgraph/02-local-server.md")[Run a Local Server]
]
#chapter-end()
