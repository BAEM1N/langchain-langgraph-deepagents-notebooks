// Auto-generated from 07_data_analysis.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "데이터 분석 에이전트", subtitle: "Deep Agents + 샌드박스")

CSV 데이터를 입력받아 탐색적 데이터 분석(EDA)을 수행하고, 시각화 결과를 생성한 뒤 Slack으로 공유하는 자율 에이전트를 구축합니다.

Deep Agents SDK의 `create_deep_agent`, 백엔드 시스템, 빌트인 도구, 체크포인터를 활용합니다.

== 학습 목표
이 노트북을 완료하면 다음을 수행할 수 있습니다:

+ _백엔드 선택_ — `LocalShellBackend`(개발)과 `DaytonaSandbox`/`Modal`/`Runloop`(운영) 간 차이를 이해하고 선택할 수 있다
+ _커스텀 도구 정의_ — `@tool` 데코레이터로 Slack 연동 등 외부 서비스 도구를 만들 수 있다
+ _에이전트 생성_ — `create_deep_agent()`로 모델, 도구, 백엔드, 체크포인터를 조합한 에이전트를 구성할 수 있다
+ _스트리밍 관찰_ — 에이전트의 분석 과정을 실시간으로 모니터링할 수 있다
+ _도구 활용_ — `ls`, `read_file`, `write_file`, `edit_file`, `delete`, `glob`, `grep`, `execute`와 opt-in `write_todos`의 역할을 이해할 수 있다
+ _체크포인터_ — `InMemorySaver`로 대화 상태를 유지하고 이어서 분석을 수행할 수 있다
+ _하네스 해부_ — `create_agent()` + 미들웨어 관점으로 `create_deep_agent()`를 이해할 수 있다

== 7.1 환경 설정

Deep Agents SDK와 Tavily(웹 검색), Slack SDK를 설치합니다. 실행 환경에 따라 `pip` 또는 `uv`를 사용합니다.

#code-block(`````python
from dotenv import load_dotenv

load_dotenv()
`````)
#output-block(`````
True
`````)

== 7.2 데이터 분석 에이전트 개요

Deep Agents의 데이터 분석 에이전트는 다음 파이프라인을 실행합니다:

#code-block(`````
CSV 입력 → 계획 수립(선택: TodoListMiddleware) → 파일 읽기(read_file) → 코드 생성 & 실행 → 반복 분석 → 결과 전달(Slack)
`````)

=== 실행 흐름 상세

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[단계],
  text(weight: "bold")[설명],
  text(weight: "bold")[사용 도구],
  [_Planning_],
  [복잡한 분석이면 `TodoListMiddleware`를 추가해 `write_todos`로 계획을 관리],
  [`write_todos`],
  [_File Reading_],
  [CSV 구조, 컬럼명, 데이터 타입, 행 수를 파악. 이미지 파일도 멀티모달로 읽기 가능],
  [`read_file`],
  [_Code Execution_],
  [pandas, matplotlib 등 Python 코드를 작성하여 백엔드에서 격리 실행],
  [Backend `execute`],
  [_Iterative Analysis_],
  [초기 결과를 기반으로 추가 분석 수행, 웹 검색으로 도메인 맥락 확보],
  [Tavily, `edit_file`],
  [_Result Delivery_],
  [분석 결과를 포맷팅하여 Slack 채널에 전송],
  [`slack_send_message`],
)

=== 자율 에이전트의 핵심 특성

+ _계획 수립(선택)_: `TodoListMiddleware`가 있을 때 `write_todos`로 분석 작업을 세분화합니다.
+ _적응적 실행_: 분석 중 오류가 발생하면 코드를 수정(`edit_file`)하고 재실행합니다.
+ _서브에이전트 위임_: 복잡한 작업은 전문 서브에이전트를 생성하여 병렬 처리합니다.
+ _컨텍스트 관리_: 파일 시스템 도구로 중간 결과를 저장하고 필요할 때 다시 참조합니다.

== 7.3 백엔드 선택

Deep Agents는 _플러그형 백엔드 아키텍처_로 파일시스템 및 코드 실행 환경을 제공합니다. 모든 백엔드는 동일한 `BackendProtocol`을 구현하므로, 코드를 변경하지 않고 백엔드만 교체할 수 있습니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[백엔드],
  text(weight: "bold")[용도],
  text(weight: "bold")[보안 수준],
  text(weight: "bold")[설정 난이도],
  [`LocalShellBackend`],
  [로컬 개발/테스트],
  [낮음 (호스트 시스템 전체 접근)],
  [설정 불필요],
  [`Daytona`],
  [클라우드 샌드박스 환경],
  [높음 (격리된 컨테이너)],
  [API 키 필요],
  [`Modal`],
  [서버리스 GPU/CPU 연산],
  [높음],
  [Modal 계정 필요],
  [`Runloop`],
  [관리형 클라우드 실행],
  [높음],
  [API 키 필요],
)

=== 백엔드 유형별 상세

- _`StateBackend`_ (기본값): 파일을 LangGraph 에이전트 상태에 저장합니다. 스크래치패드 용도로 적합하며, 큰 출력물은 자동 제거됩니다.
- _`FilesystemBackend`_: `root_dir` 설정으로 로컬 디스크 접근을 제공합니다. `virtual_mode=True` 옵션으로 경로 제한 및 디렉터리 탐색 방지가 가능합니다.
- _`LocalShellBackend`_: 파일시스템 접근에 더해 `execute` 도구로 _무제한 셸 명령 실행_을 제공합니다. 호스트 시스템에 대한 전체 사용자 권한으로 실행됩니다.
- _`CompositeBackend`_: 경로별로 다른 백엔드를 라우팅합니다. 예: 임시 파일은 `StateBackend`, `/memories/`는 `StoreBackend`.

=== 샌드박스 보안 원칙

샌드박스는 에이전트가 코드를 안전하게 실행할 수 있는 격리된 환경을 제공합니다. 핵심 보안 원칙:

- _절대로 시크릿을 샌드박스 안에 넣지 마세요_ -- 컨텍스트 주입 공격으로 에이전트가 환경 변수나 마운트된 파일의 자격 증명을 읽어 유출할 수 있습니다
- 자격 증명은 샌드박스 외부의 도구에 보관하세요
- 민감한 작업에는 Human-in-the-Loop 승인을 사용하세요
- 불필요한 네트워크 접근을 차단하세요

#warning-box[_주의_: `LocalShellBackend`는 호스트 시스템에 대한 _무제한 셸 실행 권한_을 가집니다. 프로덕션에서는 반드시 샌드박스 백엔드를 사용하세요.]

#code-block(`````python
from deepagents.backends import LocalShellBackend

# 개발용 — 로컬 셸 백엔드
dev_backend = LocalShellBackend(virtual_mode=True)

# 운영용 — 클라우드 샌드박스 (택 1)
# prod_backend = ...  # 프로덕션에서는 클라우드 샌드박스 백엔드를 사용하세요
`````)

== 7.4 샘플 데이터 업로드

에이전트가 분석할 CSV 파일을 백엔드의 작업 디렉터리에 생성합니다. `create_deep_agent`의 백엔드는 `write_file` 도구를 내장하고 있어 에이전트가 직접 파일을 쓸 수 있지만, 여기서는 미리 데이터를 준비합니다.

#code-block(`````python
import os

workspace = "/tmp/analysis"
os.makedirs(workspace, exist_ok=True)

csv_content = (
    "region,quarter,revenue,units_sold\n"
    "Seoul,Q1,120000,340\nSeoul,Q2,135000,380\n"
    "Seoul,Q3,128000,355\nSeoul,Q4,150000,420\n"
    "Busan,Q1,85000,240\nBusan,Q2,92000,260\n"
    "Busan,Q3,88000,250\nBusan,Q4,105000,300"
)
`````)

#code-block(`````python
with open(f"{workspace}/sales_2025.csv", "w") as f:
    f.write(csv_content)
print(f"CSV 저장됨: {workspace}/sales_2025.csv")
`````)
#output-block(`````
CSV 저장됨: /tmp/analysis/sales_2025.csv
`````)

== 7.5 커스텀 도구 -- Slack 연동

`@tool` 데코레이터로 에이전트가 호출할 수 있는 커스텀 도구를 정의합니다. 도구의 _docstring_이 에이전트에게 사용법을 알려주는 역할을 합니다.

아래는 분석 결과를 Slack 채널로 전송하는 도구입니다.

#code-block(`````python
from langchain_core.tools import tool
try:
    from slack_sdk import WebClient
except ImportError:
    WebClient = None
    print("slack_sdk 미설치 -- Slack 도구는 스텁으로 작동합니다")

slack_client = WebClient(token=os.environ.get("SLACK_BOT_TOKEN", "xoxb-placeholder")) if WebClient else None

@tool
def slack_send_message(message: str) -> str:
    """분석 결과를 Slack 채널로 전송합니다."""
    resp = slack_client.chat_postMessage(
        channel=os.environ.get("SLACK_CHANNEL_ID", "general"), text=message)
    return f"전송 완료. 타임스탬프: {resp['ts']}"
`````)

=== 웹 검색 도구 (Tavily)

에이전트가 분석 중 도메인 맥락이 필요할 때 웹 검색을 수행할 수 있도록 Tavily 도구를 준비합니다.

#code-block(`````python
from tavily import TavilyClient

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

def tavily_search(query: str) -> str:
    """분석에 관련된 정보를 웹에서 검색합니다."""
    results = tavily_client.search(query, max_results=5)
    return "\n".join(
        [r["content"] for r in results["results"]]
    )
`````)

== 7.6 에이전트 생성

`create_deep_agent()`는 모델, 도구, 백엔드, 체크포인터, 시스템 프롬프트를 조합하여 에이전트를 생성합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[타입],
  text(weight: "bold")[설명],
  [`model`],
  [`str`],
  [모델 식별자 (기본값: `claude-sonnet-4-6`)],
  [`tools`],
  [`list`],
  [에이전트가 사용할 도구 함수 목록],
  [`backend`],
  [`Backend`],
  [코드 실행 및 파일시스템 백엔드],
  [`checkpointer`],
  [`Checkpointer`],
  [상태 영속화 메커니즘],
  [`system_prompt`],
  [`str`],
  [에이전트 행동 지침],
)

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import LocalShellBackend
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import TodoListMiddleware

backend = LocalShellBackend(virtual_mode=True)
checkpointer = InMemorySaver()
`````)

#code-block(`````python
agent = create_deep_agent(
    model="gpt-5.4",
    tools=[tavily_search, slack_send_message],
    backend=backend,
    checkpointer=checkpointer,
    middleware=[TodoListMiddleware()],
    system_prompt="당신은 데이터 분석가입니다.",
)
`````)

=== 7.6.5 `create_agent()`로 해부해 보기

`create_deep_agent()`는 교육과 실무에서 바로 쓰기 좋은 shortcut입니다. 내부 관점에서는 LangChain `create_agent()`에 filesystem, subagent, skills/memory, 선택적 planning 미들웨어를 조합한 하네스라고 이해하면 됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[관점],
  text(weight: "bold")[`create_deep_agent()`],
  text(weight: "bold")[`create_agent()` + middleware],
  [목적],
  [Deep Agent 기본 하네스 빠른 구성],
  [필요한 정책만 직접 조립],
  [장점],
  [파일 도구·서브에이전트·skills/memory 기본 제공],
  [최소 구성, 세밀한 제어],
  [계획],
  [`TodoListMiddleware()`를 명시적으로 추가],
  [같은 미들웨어를 직접 추가],
  [교육 포인트],
  [“완성형 하네스 사용”],
  [“하네스 내부 구조 해부”],
)

데이터 분석 에이전트처럼 파일 읽기·코드 실행·결과 저장이 핵심이면 `create_deep_agent()`가 기본값입니다. 아주 작은 도구 호출 assistant나 미들웨어 실험은 `create_agent()`로 시작해도 됩니다.

#code-block(`````python
# 하네스 해부용 reference code — 실제 분석 에이전트는 위의 create_deep_agent() 사용
agent_anatomy = r'''
from langchain.agents import create_agent

base_agent = create_agent(
    model="openai:gpt-5.4",
    tools=[tavily_search, slack_send_message],
    system_prompt="당신은 데이터 분석가입니다.",
    # 필요 시 middleware=[...]로 정책을 직접 조합
)
'''
print(agent_anatomy)
`````)

== 7.7 실행 — 분석 요청

`agent.invoke()`로 분석 요청을 전달하면 에이전트가 자율적으로 계획 수립 → 파일 읽기 → 코드 실행 → 결과 전달 파이프라인을 수행합니다.

== 7.8 스트리밍으로 분석 과정 관찰

`agent.stream()`을 사용하면 에이전트의 실행 과정을 _실시간으로_ 관찰할 수 있습니다. Deep Agents는 LangGraph의 스트리밍 인프라를 기반으로 서브에이전트의 실행까지 추적할 수 있는 강력한 모니터링을 제공합니다.

=== 스트림 모드

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[설명],
  text(weight: "bold")[사용 사례],
  [_Updates_],
  [각 단계(노드) 완료 시 이벤트 수신],
  [진행 상황 대시보드, 로그],
  [_Messages_],
  [개별 토큰 스트리밍, 소스 에이전트 메타데이터 포함],
  [실시간 채팅 UI],
  [_Custom_],
  [`get_stream_writer()`로 커스텀 진행 이벤트 발행],
  [분석 진행률 표시, 커스텀 알림],
)

=== 네임스페이스 시스템

스트리밍 이벤트에는 소스를 식별하는 네임스페이스가 포함됩니다:

- `()` (빈 튜플) = 메인 에이전트
- `("tools:abc123",)` = 도구 호출로 생성된 서브에이전트
- `("tools:abc123", "model_request:def456")` = 서브에이전트 내부의 모델 요청 노드

`subgraphs=True`를 설정하면 서브에이전트의 실행까지 추적할 수 있으며, 여러 스트림 모드를 동시에 사용할 수도 있습니다:

#code-block(`````python
for namespace, chunk in agent.stream(
    {"messages": [...]},
    stream_mode=["updates", "messages", "custom"],
    subgraphs=True,
):
    mode, data = chunk
    # 각 모드별로 다르게 처리
`````)

=== 서브에이전트 라이프사이클 추적

서브에이전트는 세 단계를 거칩니다:
+ _Pending_ -- 메인 에이전트의 `model_request`에 태스크 도구 호출이 포함될 때 감지
+ _Running_ -- `tools:UUID` 네임스페이스에서 이벤트가 발생할 때 시작
+ _Complete_ -- 메인 에이전트의 `tools` 노드가 결과를 반환할 때 완료

== 7.9 도구 활용

Deep Agents는 백엔드를 통해 파일 도구를 제공하고, 계획 도구는 `TodoListMiddleware`로 명시적으로 추가합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[설명],
  text(weight: "bold")[사용 예시],
  [`write_todos`],
  [구조화된 작업 계획 수립 및 추적 (`TodoListMiddleware` 필요)],
  [분석 단계별 TODO 리스트 생성],
  [`ls`],
  [디렉터리 내용 나열],
  [CSV 파일 존재 여부 확인],
  [`read_file`],
  [파일 읽기 (이미지 멀티모달 지원)],
  [CSV 구조 파악, 차트 이미지 확인],
  [`write_file`],
  [파일 쓰기 또는 기존 파일 교체],
  [분석 스크립트, 결과 파일 저장],
  [`edit_file`],
  [기존 파일 수정 (find-and-replace)],
  [코드 수정, 설정 파일 업데이트],
  [`delete`],
  [delete 지원 백엔드에서 파일 삭제],
  [임시 산출물 정리],
  [`glob`],
  [glob 패턴 기반 파일 탐색],
  [`*.csv` 패턴으로 데이터 파일 검색],
  [`grep`],
  [패턴 매칭 검색],
  [특정 컬럼명이나 값 검색],
)

=== 커스텀 백엔드 구현

새 교육 코드에서는 `BackendProtocol`의 `ls`, `read`, `write`, `edit`, `grep`, `glob` 메서드를 구현합니다. `delete`는 선택 메서드이며 구현한 백엔드에서만 `delete`이 노출됩니다.

=== Skills 패턴 — 도메인 지식을 진보적 공개로 분리

복잡한 데이터 분석은 도메인별 컨텍스트가 비대해지기 쉽습니다. _Skills_ 는 `SKILL.md`와 선택적 `metadata.include_tools`로 도메인 지식을 분리하여, 에이전트가 필요할 때만 로드합니다.

#code-block(`````text
skills/
└── pandas_eda/
    ├── SKILL.md       # name, description, metadata.include_tools
    └── helpers.py     # 결정적 헬퍼
`````)

`metadata.include_tools`는 공백으로 구분한 도구 이름 문자열입니다. 도구 구현은 agent tools 또는 `SkillsMiddleware(tools=...)`로 따로 제공해야 합니다.

== 7.10 체크포인터로 대화 유지

체크포인터는 에이전트 상태를 저장하여 _중단 후 재개_가 가능하게 합니다. `thread_id`로 대화 세션을 식별하며, 동일한 `thread_id`로 이어서 요청하면 이전 대화 맥락이 유지됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[체크포인터],
  text(weight: "bold")[용도],
  text(weight: "bold")[영속성],
  [`InMemorySaver`],
  [개발/테스트],
  [프로세스 종료 시 소멸],
  [`SQLiteSaver`],
  [로컬 영속],
  [디스크에 저장 (`./agent_checkpoints.db`)],
  [`PostgresSaver`],
  [프로덕션],
  [데이터베이스에 저장, 다중 인스턴스 지원],
)

=== 체크포인터의 역할

체크포인터는 단순한 대화 이력 저장을 넘어 다음을 가능하게 합니다:

- _중단 복구_: 네트워크 오류나 타임아웃 시 마지막 완료된 단계부터 재개
- _`interrupt()` 지원_: Human-in-the-Loop에서 그래프 상태를 저장하여 사람의 응답 후 정확한 위치에서 재개
- _멀티턴 분석_: 동일 세션에서 여러 분석 요청을 연속으로 처리하면서 이전 결과를 참조

=== 샌드박스 수명 관리

샌드박스를 사용할 때는 _명시적인 종료(shutdown)_가 필요합니다. 종료하지 않으면 불필요한 비용이 발생합니다. 채팅 애플리케이션에서는 대화 스레드별로 고유한 샌드박스를 사용하고, TTL(Time-to-Live) 설정으로 자동 정리를 구성하세요.

#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()
config = {"configurable": {"thread_id": "analysis-session-1"}}

agent_with_memory = create_deep_agent(
    model="gpt-5.4",
    tools=[tavily_search, slack_send_message],
    backend=LocalShellBackend(virtual_mode=True),
    checkpointer=checkpointer,
)
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [_백엔드_],
  [`LocalShell`(개발)은 호스트 셸 접근, 프로덕션에서는 `Daytona`/`Modal`/`Runloop` 샌드박스 사용],
  [_커스텀 도구_],
  [`\@tool` 데코레이터 + docstring으로 정의, 에이전트가 자율 호출],
  [_에이전트 생성_],
  [`create_deep_agent(model, tools, backend, checkpointer, middleware, system_prompt)`],
  [_계획_],
  [`TodoListMiddleware()`를 명시적으로 추가하면 `write_todos` 사용 가능],
  [_스트리밍_],
  [`agent.stream(stream_mode="updates", subgraphs=True)`로 실시간 관찰],
  [_파일 도구_],
  [`ls`, `read_file`, `write_file`, `edit_file`, `delete`, `glob`, `grep`],
  [_체크포인터_],
  [`InMemorySaver`(개발) → `SQLiteSaver` → `PostgresSaver`(프로덕션)],
)
