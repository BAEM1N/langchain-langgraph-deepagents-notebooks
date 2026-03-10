// Auto-generated from 11_local_server.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "로컬 서버")

10장에서 프로덕션 전환의 전체 그림을 그렸다면, 이 장에서는 그 첫 단계인 _로컬 개발 서버_를 심층적으로 다룹니다. 프로덕션 배포 전에 로컬 환경에서 에이전트를 서버로 실행하고 테스트하는 것은 개발 워크플로의 핵심 단계입니다. `langgraph dev` CLI는 인메모리 체크포인터를 내장한 개발 서버를 즉시 띄워 주며, `LangGraph Studio`와 연동하면 그래프의 노드-엣지 구조를 시각적으로 확인하고, 실시간 실행 추적, 상태 검사/수정, 타임 트래블 등을 브라우저에서 수행할 수 있습니다. 이 장에서는 로컬 서버의 설정, 실행, Python SDK를 통한 호출, 그리고 Studio 연동까지의 전체 흐름을 실습합니다.

#learning-header()
#learning-objectives([`langgraph dev` CLI로 개발 서버를 실행하는 방법을 안다], [LangGraph Studio와 연동하여 시각적으로 디버깅한다], [`langgraph.json` 설정 파일을 작성한다], [Python SDK로 로컬 서버를 호출한다], [배포 준비 과정을 이해한다])

== 11.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
`````)

== 11.2 LangGraph CLI 설치

LangGraph Platform은 에이전트를 HTTP 서버로 배포하기 위한 인프라 계층입니다. 로컬 개발 단계에서 이 인프라를 활용하려면 `langgraph-cli`를 설치해야 합니다. CLI는 프로젝트 생성, 개발 서버 실행, Docker 기반 빌드 등을 담당하는 핵심 도구입니다.

`langgraph-cli[inmem]` 패키지에는 인메모리 체크포인터가 내장되어 있어, 별도의 데이터베이스 설정 없이 즉시 개발 서버를 띄울 수 있습니다. 프로덕션 배포에는 PostgreSQL 기반 체크포인터를 사용하지만, 로컬 개발 단계에서는 인메모리 모드로 충분합니다.

#note-box[`langgraph-cli[inmem]`의 `[inmem]` extra는 개발 편의를 위한 것입니다. 이 옵션 없이 설치하면 `langgraph dev` 실행 시 별도의 체크포인터 설정이 필요합니다. 개발 환경에서는 항상 `[inmem]`을 포함하여 설치하세요.]

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

CLI 설치가 완료되었으면, 다음 단계는 프로젝트를 생성하는 것입니다. LangGraph CLI의 `langgraph new` 명령은 검증된 프로젝트 템플릿을 기반으로 디렉터리 구조, 설정 파일, 의존성 정의를 자동으로 생성해 줍니다. 템플릿을 지정하지 않으면 인터랙티브 메뉴가 표시되어 Python/TypeScript 등 원하는 스택을 선택할 수 있습니다.

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

프로젝트 구조가 준비되었으니, 이제 LangGraph 서버가 프로젝트를 어떻게 인식하는지 살펴봅시다. `langgraph.json`은 LangGraph 프로젝트의 핵심 설정 파일로, 서버 시작 시 가장 먼저 읽히는 진입점입니다. 이 파일이 없으면 `langgraph dev` 명령이 동작하지 않습니다.

`langgraph.json`은 세 가지 핵심 정보를 정의합니다: (1) 어떤 패키지를 설치할지(`dependencies`), (2) 어떤 그래프를 노출할지(`graphs`), (3) 어떤 환경 변수를 로드할지(`env`). 특히 `graphs` 필드는 `"이름": "모듈경로:변수명"` 형태로 그래프 객체의 위치를 정확히 지정합니다.

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

#align(center)[#image("../../assets/diagrams/png/local_server_stack.png", width: 78%, height: 112mm, fit: "contain")]

이 구성도는 로컬 서버를 _하나의 허브_ 로 보면 이해가 쉽다는 점을 보여줍니다. CLI는 서버를 띄우고, Studio는 시각적 디버깅을 제공하며, Python SDK와 REST는 같은 서버 기능을 서로 다른 인터페이스로 소비합니다.

설정 파일이 준비되었으면, 이제 실제로 서버를 띄울 차례입니다. `langgraph dev` 명령은 `langgraph.json`을 읽어 그래프를 로드하고, 인메모리 체크포인터를 자동으로 연결한 뒤, HTTP API 서버를 시작합니다. 서버가 정상적으로 기동되면 세 가지 URL이 출력됩니다.

#align(center)[#image("../../assets/diagrams/png/local_server_topology.png", width: 78%, height: 112mm, fit: "contain")]

이 장에서 헷갈리기 쉬운 지점은 _서버 하나로 여러 소비자가 붙는다_ 는 점입니다. 같은 로컬 API를 기준으로 CLI는 서버를 띄우고, Studio는 시각화/디버깅을 담당하며, Python SDK와 REST 클라이언트는 동일한 엔드포인트를 서로 다른 방식으로 호출합니다. 즉, `langgraph dev`는 개발 중인 그래프를 위한 _공통 허브_ 라고 생각하면 됩니다.

#warning-box[`langgraph dev`는 개발 전용 서버입니다. 인메모리 체크포인터를 사용하므로 서버를 재시작하면 모든 상태가 초기화됩니다. 프로덕션 환경에서는 `langgraph up` 명령으로 Docker 기반 서버를 실행하고, PostgreSQL 체크포인터를 연결해야 합니다.]

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

API 서버가 실행 중인 상태에서, 개발자 경험을 한 단계 끌어올리는 것이 LangGraph Studio입니다. Studio는 `langgraph dev` 실행 시 자동으로 제공되는 시각적 디버깅 도구로, 별도 설치 없이 브라우저에서 바로 사용할 수 있습니다. 에이전트의 내부 동작을 "블랙박스"가 아닌 "유리 상자"처럼 투명하게 관찰할 수 있다는 점이 가장 큰 장점입니다.

Studio에서는 그래프의 노드-엣지 구조를 시각적으로 확인하고, 각 노드의 실행 과정을 실시간으로 추적하며, 특정 시점의 상태를 수정하여 다시 실행하는 _타임 트래블_ 기능까지 제공합니다. Human-in-the-loop 패턴에서 인터럽트 지점을 확인하고 수동으로 승인/거부하는 테스트도 Studio에서 수행할 수 있습니다.

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

== 11.7 Python SDK --- 비동기 클라이언트

Studio에서 시각적으로 테스트하는 것 외에, 프로그래밍 방식으로 서버에 접근해야 하는 경우도 많습니다. 예를 들어 CI/CD 파이프라인에서 자동화된 테스트를 실행하거나, 다른 애플리케이션에서 에이전트를 호출할 때는 SDK가 필수입니다. LangGraph SDK는 비동기(`get_client()`)와 동기(`get_sync_client()`) 두 가지 클라이언트를 제공합니다.

비동기 클라이언트는 `langgraph_sdk.get_client()`로 생성합니다. `asyncio` 기반으로 동작하며, 대량의 동시 요청을 효율적으로 처리할 수 있습니다. 특히 스트리밍 응답을 처리할 때 `async for` 구문을 사용하면 각 청크가 도착할 때마다 즉시 처리할 수 있어 사용자 체감 지연 시간을 줄일 수 있습니다.

#tip-box[`RemoteGraph`를 사용하면 로컬 서버뿐 아니라 원격 LangGraph Platform 서버에 대해서도 동일한 인터페이스로 호출할 수 있습니다. `RemoteGraph(name="agent", url="https://your-deployment.langsmith.dev")`처럼 URL만 변경하면 됩니다. 이를 통해 로컬 개발과 프로덕션 배포 사이의 코드 변경을 최소화할 수 있습니다.]

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

비동기 프로그래밍이 익숙하지 않거나, Jupyter 노트북 같은 환경에서 빠르게 테스트하고 싶다면 동기 클라이언트를 사용할 수 있습니다. 동기 클라이언트는 `langgraph_sdk.get_sync_client()`로 생성하며, `asyncio` 없이 일반 `for` 루프로 스트리밍 응답을 처리합니다.

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

Python SDK는 편리하지만, 모든 클라이언트가 Python 환경인 것은 아닙니다. JavaScript 프론트엔드, Go 백엔드, 또는 타 시스템과의 통합이 필요한 경우 REST API를 직접 호출하는 방식이 적합합니다. LangGraph 로컬 서버는 표준 REST API를 제공하므로, HTTP 요청이 가능한 모든 언어와 도구에서 에이전트를 호출할 수 있습니다.

#tip-box[REST API의 전체 엔드포인트 문서는 `http://localhost:2024/docs`에서 Swagger UI로 확인할 수 있습니다. 스레드 생성, 실행, 상태 조회, 인터럽트 재개 등 모든 기능이 REST API로 제공됩니다.]

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

#note-box[_관계 요약_
- `langgraph dev` 는 실행 엔진을 띄우는 진입점입니다.
- Studio는 같은 서버에 붙는 디버깅 UI입니다.
- SDK와 REST는 자동화/앱 연동을 위한 프로그래밍 인터페이스입니다.]

== 11.10 배포 준비 체크리스트

지금까지 로컬 서버 실행, Studio 연동, SDK와 REST API 호출까지 전체 개발 워크플로를 살펴보았습니다. 이제 프로덕션으로 전환하기 전에 점검해야 할 항목들을 체크리스트로 정리합니다. 아래 항목들을 모두 확인한 후에 프로덕션 배포를 진행하세요.

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
