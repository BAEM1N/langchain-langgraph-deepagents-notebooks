// Auto-generated from 07_advanced.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "고급 기능")

== 학습 목표
#learning-objectives([Human-in-the-Loop 워크플로를 구현한다], [다양한 스트리밍 모드와 네임스페이스 시스템을 이해한다], [샌드박스(Modal, Daytona, Runloop) 연동 개념을 파악한다], [`CodeInterpreterMiddleware`와 QuickJS interpreter의 역할을 이해한다], [`RubricMiddleware`로 런타임 평가 게이트를 구성한다], [ACP(Agent Client Protocol)로 에디터와 연동하는 방법을 안다], [Deep Agents Code(`dcode`) 사용법을 익힌다])

#code-block(`````python
# 환경 설정
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
print("환경 설정 완료")
`````)
#output-block(`````
환경 설정 완료
`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")

print(f"모델 설정 완료: {model.model_name}")
`````)
#output-block(`````
모델 설정 완료: gpt-4.1
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Human-in-the-Loop (HITL)

에이전트가 민감한 도구를 호출할 때 _사람의 승인을 요구_하는 워크플로입니다.

=== 작동 방식

#image("../../assets/images/hitl_flow.png")

=== 4가지 결정 타입 (`Command(resume={"decisions": [...]})`)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[결정],
  text(weight: "bold")[동작],
  [`approve`],
  [제안된 인자 그대로 도구 실행],
  [`edit`],
  [`edited_action.name/args`로 인자를 수정한 뒤 실행],
  [`reject`],
  [호출 자체를 건너뜀],
  [`respond`],
  [도구 실행 없이 `message`를 도구 결과로 반환],
)

=== 필수 요구사항
- _Checkpointer_: 중단/재개 사이의 에이전트 상태를 유지하기 위해 반드시 필요 (`MemorySaver` 등)
- **`version="v2"`**: invoke/stream 호출에 모두 지정 — interrupt 지원의 표준 경로
- **동일한 `thread_id`**: 초기 invoke와 resume invoke가 같은 `thread_id`를 공유해야 함

=== `interrupt_on` 설정 옵션

#code-block(`````python
interrupt_on = {
    "tool_name": True,                                       # 4가지 결정 모두 허용
    "tool_name": False,                                      # 인터럽트 없음
    "tool_name": {"allowed_decisions": ["approve", "reject"]},  # 부분 집합
}
`````)


#code-block(`````python
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

# interrupt_on으로 승인이 필요한 도구 지정
hitl_agent = create_deep_agent(
    model=model,
    system_prompt="당신은 파일 관리 어시스턴트입니다. 한국어로 응답하세요.",
    checkpointer=MemorySaver(),  # 필수!
    interrupt_on={
        "write_file": True,   # 파일 쓰기 전 승인 필요
        "edit_file": True,    # 파일 편집 전 승인 필요
    },
)

print("Human-in-the-Loop 에이전트 생성 완료")
print("write_file, edit_file 호출 시 승인을 요구합니다.")
`````)
#output-block(`````
Human-in-the-Loop 에이전트 생성 완료
write_file, edit_file 호출 시 승인을 요구합니다.
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 스트리밍 심화

Deep Agents는 LangGraph의 스트리밍 인프라 위에서 작동합니다.

=== v2 통합 포맷 (표준)

**`agent.stream(..., stream_mode=..., subgraphs=True, version="v2")` 한 경로**가 표준입니다. 모든 청크는 동일한 3-필드 구조입니다.

#code-block(`````python
{
    "type": "updates" | "messages" | "custom",
    "ns":   tuple,            # 이벤트 발생 위치(메인/서브에이전트 라우팅 키)
    "data": Any,              # type 별 payload
}
`````)

=== 스트림 모드

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[data],
  text(weight: "bold")[사용 시나리오],
  [`"updates"`],
  [`{node_name: state_update}`],
  [노드/스텝 진행 추적],
  [`"messages"`],
  [`(token, metadata)`],
  [토큰 스트리밍, `tool_call_chunks` 조립],
  [`"custom"`],
  [도구가 `get_stream_writer()`로 방출한 객체],
  [커스텀 진행률/상태],
)

리스트(`stream_mode=["updates", "messages", "custom"]`)를 주면 세 모드를 한 루프에서 받습니다.

=== 네임스페이스 시스템

`ns` 튜플이 이벤트 소스를 식별합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[튜플],
  text(weight: "bold")[의미],
  [`()`],
  [메인 에이전트],
  [`("tools:abc123",)`],
  [`task` 도구가 스폰한 서브에이전트],
  [`("tools:abc123", "model_request:def456")`],
  [해당 서브에이전트 내부 노드],
)

서브에이전트 이벤트 판정:

#code-block(`````python
is_subagent = any(seg.startswith("tools:") for seg in chunk["ns"])
`````)


#code-block(`````python
from typing import Literal
from tavily import TavilyClient

tavily_client = TavilyClient(api_key=os.environ.get("TAVILY_API_KEY", ""))


def internet_search(
    query: str,
    max_results: int = 3,
    topic: Literal["general", "news"] = "general",
) -> dict:
    """인터넷에서 정보를 검색합니다."""
    return tavily_client.search(query, max_results=max_results, topic=topic)


# 서브에이전트 포함 에이전트
stream_agent = create_deep_agent(
    model=model,
    system_prompt="당신은 리서치 코디네이터입니다. 한국어로 응답하세요.",
    subagents=[
        {
            "name": "researcher",
            "description": "인터넷 검색을 통해 정보를 조사합니다.",
            "system_prompt": "인터넷을 검색하여 요청된 정보를 수집하고 간결하게 요약하세요.",
            "tools": [internet_search],
        }
    ],
)

print("스트리밍 데모 에이전트 생성 완료")
`````)
#output-block(`````
스트리밍 데모 에이전트 생성 완료
`````)

=== 커스텀 진행률 이벤트 (`get_stream_writer` + `stream_mode="custom"`)

도구 내부에서 임의 구조체를 방출해 UI에 노출합니다. 업로드 진행률·처리 건수·중간 상태 등에 활용합니다.


#code-block(`````python
from langchain.tools import tool
from langgraph.config import get_stream_writer


@tool
def analyze_data(topic: str) -> str:
    """주제 데이터를 분석하고 진행률을 스트리밍합니다."""
    writer = get_stream_writer()
    writer({"status": "starting", "progress": 0, "topic": topic})
    # ... 실제 분석 작업 ...
    writer({"status": "complete", "progress": 100, "topic": topic})
    return f"분석 완료: {topic}"


custom_example = r'''
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "..."}]},
    stream_mode="custom",
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "custom":
        print(chunk["data"])  # {"status": ..., "progress": ...}
'''
print(custom_example)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 샌드박스 (Sandbox)

샌드박스는 에이전트가 _격리된 환경_에서 코드를 실행할 수 있게 합니다.
호스트 시스템의 파일, 네트워크, 자격 증명에 접근하지 못하므로 안전합니다.

=== 지원 프로바이더

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[프로바이더],
  text(weight: "bold")[특징],
  text(weight: "bold")[적합한 용도],
  [_Modal_],
  [GPU 지원, ML 워크로드],
  [AI/ML 작업],
  [_Daytona_],
  [TypeScript/Python, 빠른 콜드 스타트],
  [웹 개발],
  [_Runloop_],
  [일회용 devbox, 격리 실행],
  [코드 테스트],
)

=== 아키텍처 패턴

_샌드박스를 도구로 사용_ (권장)

#image("../../assets/images/sandbox_architecture.png")

=== ⚠️ 보안 주의사항
- _절대 샌드박스 안에 시크릿을 넣지 마세요_ — 에이전트가 유출할 수 있습니다
- 자격 증명은 외부 도구에서만 관리
- Human-in-the-Loop으로 민감한 작업 승인
- 불필요한 네트워크 접근 차단

#code-block(`````python
# 샌드박스 연동 코드 예시 — Modal (docs/deepagents/11-sandboxes.md)
sandbox_example_code = '''
# pip install langchain-modal deepagents
import modal
from deepagents import create_deep_agent
from langchain_anthropic import ChatAnthropic
from langchain_modal import ModalSandbox

app = modal.App.lookup("your-app")
modal_sandbox = modal.Sandbox.create(app=app)
backend = ModalSandbox(sandbox=modal_sandbox)

agent = create_deep_agent(
    model=ChatAnthropic(model="claude-sonnet-4-6"),
    system_prompt="You are a Python coding assistant with sandbox access.",
    backend=backend,
)

try:
    result = agent.invoke({
        "messages": [{"role": "user", "content": "Create a small Python package and run pytest"}],
    })
finally:
    modal_sandbox.terminate()  # 필수: 리소스 해제
'''

print("샌드박스 연동 코드 예시 (참고용):")
print(sandbox_example_code)

`````)
#output-block(`````
샌드박스 연동 코드 예시 (참고용):

# pip install deepagents-modal
from deepagents.backends.sandbox import ModalSandbox

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    backend=ModalSandbox(
        image="python:3.12-slim",
        gpu="T4",  # GPU 지원
    ),
)
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Interpreters — CodeInterpreterMiddleware

Deep Agents 0.6의 interpreter는 에이전트 루프 안에 _QuickJS 기반 코드 실행 공간_을 제공합니다. 샌드박스가 외부 환경을 조작하는 격리 실행이라면, interpreter는 도구 호출 조합·중간 변수 보관·구조화 데이터 변환을 모델 컨텍스트 밖에서 수행하는 내부 작업 공간입니다.

=== 설치

#code-block(`````bash
pip install -U "deepagents[quickjs]"
# 또는
uv add "deepagents[quickjs]"
`````)

=== 언제 쓰나

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[용도],
  text(weight: "bold")[예],
  [도구 호출 조합],
  [검색 결과 20개를 loop로 점수화],
  [서브에이전트 fan-out/fan-in],
  [후보별 `task(...)` 호출 후 코드로 합성],
  [구조화 데이터 처리],
  [JSON 정렬·그룹화·검증],
  [컨텍스트 절약],
  [큰 중간 결과는 interpreter 변수에 유지],
)

=== Programmatic Tool Calling (PTC)와 programmatic subagents

PTC는 `ptc=["web_search"]`처럼 allowlist를 지정한 _일반 도구_를 QuickJS 내부의 `tools.*` async 함수로 노출합니다. 도구 이름은 camelCase로 변환됩니다(예: `web_search` → `tools.webSearch`).

서브에이전트 호출은 PTC allowlist가 아니라 interpreter의 top-level `task(...)` 함수로 다룹니다. `CodeInterpreterMiddleware(subagents=True)`가 기본값이며, interpreter 내부에서 `Promise.all`로 병렬 위임 패턴을 만들 수 있습니다.

#code-block(`````javascript
const topics = ["retrieval", "memory", "evaluation"];
const reports = await Promise.all(
  topics.map((topic) => task({
    description: `Research ${topic}`,
    subagent_type: "general-purpose",
  })),
);
`````)

민감 도구를 PTC로 노출할 때는 parent-level `interrupt_on`이 개별 interpreter dispatch마다 자동 적용된다고 가정하지 말고, 최소 권한 allowlist를 둡니다.

=== `CodeInterpreterMiddleware` 주요 옵션

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Default],
  text(weight: "bold")[Purpose],
  [`memory_limit`],
  [`64*1024*1024` (64 MB)],
  [QuickJS heap memory limit (bytes)],
  [`timeout`],
  [`5.0`],
  [Per-eval 타임아웃(초)],
  [`max_ptc_calls`],
  [`256`],
  [한 eval에서 허용되는 `tools.*` 호출 수],
  [`tool_name`],
  [`"eval"`],
  [Interpreter 도구 이름],
  [`max_result_chars`],
  [`4000`],
  [반환 결과 최대 문자 수],
  [`capture_console`],
  [`True`],
  [`console.log` 출력 캡처],
  [`subagents`],
  [`True`],
  [top-level `task(...)` 함수 노출 여부],
  [`ptc`],
  [`None`],
  [PTC allowlist],
  [`mode`],
  [`None`],
  [`thread` 등 스냅샷/상태 보존 모드],
  [`snapshot_between_turns`],
  [`None`],
  [명시적 turn 간 snapshot 제어],
  [`max_snapshot_bytes`],
  [`None`],
  [snapshot 최대 크기],
)

#code-block(`````python
# Interpreter 구성 예시 — deepagents[quickjs] extra 필요
interpreter_example = r'''
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    model="openai:gpt-5.4",
    checkpointer=MemorySaver(),
    middleware=[CodeInterpreterMiddleware(ptc=["web_search"], subagents=True, mode="thread")],
)

# QuickJS 안에서는 task(...)와 tools.webSearch(...)를 분리해서 사용합니다.
'''
print(interpreter_example)
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. RubricMiddleware — 런타임 LLM-as-a-judge

`RubricMiddleware`는 에이전트 실행 결과를 _rubric 기준으로 평가_하고, 기준을 만족하지 못하면 같은 invocation 안에서 추가 수정을 유도하는 미들웨어입니다. 오프라인 평가는 LangSmith/agentevals로 회귀를 막고, 런타임 rubric은 실제 요청마다 “이번 답변이 기준을 지켰는가”를 확인하는 방어선으로 둡니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  [`model`],
  [평가를 맡을 judge 모델],
  [`system_prompt`],
  [품질 기준과 실패 시 수정 지시],
  [`max_iterations`],
  [평가→수정 반복 상한],
  [`on_evaluation`],
  [평가 결과 로깅/모니터링 콜백],
)

주의할 점은 비용과 지연입니다. 모든 요청에 무조건 붙이기보다, 고위험 작업·최종 산출물·외부 전송 직전처럼 품질 게이트가 필요한 지점에 선택 적용합니다.

#code-block(`````python
# RubricMiddleware 구성 예시 — 실행 전 품질 기준을 먼저 코드로 고정
rubric_example = r'''
from deepagents import RubricMiddleware, create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    model="openai:gpt-5.4",
    checkpointer=MemorySaver(),
    middleware=[RubricMiddleware(
        model="openai:gpt-5.4-mini",
        system_prompt="정확성, 근거, 안전성을 1~5점으로 평가하고 부족하면 수정 지시",
        max_iterations=3,
    )],
)
'''
print(rubric_example)
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. ACP (Agent Client Protocol)

ACP는 _코딩 에이전트와 에디터/IDE 간의 통신을 표준화_하는 프로토콜입니다.

=== 지원 에디터
- _Zed_ — 네이티브 통합
- _JetBrains IDEs_ — 빌트인 지원
- _VS Code_ — vscode-acp 플러그인
- _Neovim_ — ACP 호환 플러그인

=== MCP vs ACP
#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[프로토콜],
  text(weight: "bold")[용도],
  [MCP (Model Context Protocol)],
  [외부 도구 통합],
  [ACP (Agent Client Protocol)],
  [에디터-에이전트 통합],
)

#code-block(`````python
# ACP 서버 구현 예시 (참고용) — docs/deepagents/14-acp.md
acp_example_code = '''
# pip install deepagents-acp
import asyncio

from acp import run_agent
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

from deepagents_acp.server import AgentServerACP


async def main() -> None:
    agent = create_deep_agent(
        model="google_genai:gemini-3.5-flash",
        system_prompt="You are a helpful coding assistant",
        checkpointer=MemorySaver(),
    )
    server = AgentServerACP(agent)
    await run_agent(server)


if __name__ == "__main__":
    asyncio.run(main())
'''

print("ACP 서버 구현 예시 (참고용):")
print(acp_example_code)

print("Toad로 띄우기: uv tool install -U batrachian-toad && toad acp 'python acp_server.py' .")

`````)
#output-block(`````
ACP 서버 구현 예시 (참고용):

# pip install deepagents-acp
from deepagents import create_deep_agent
from deepagents_acp import AgentServerACP
from langgraph.checkpoint.memory import MemorySaver

# 에이전트 생성
agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="당신은 코딩 어시스턴트입니다.",
    checkpointer=MemorySaver(),
)

# ACP 서버 실행 (stdio 모드)
server = AgentServerACP(agent)
server.run()
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. Deep Agents Code (`dcode`)

SDK 위에 구축된 _터미널 코딩 에이전트_입니다. 현재 CLI 문서는 `deepagents-code` 패키지와 `dcode` 명령을 기준으로 설명합니다.

=== 설치 및 실행
#code-block(`````bash
# 설치 스크립트
curl -LsSf https://langch.in/dcode | bash

# 설치 없이 도움말 확인
uvx --from deepagents-code dcode --help

# 실행
dcode
`````)

=== 주요 옵션

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[옵션],
  text(weight: "bold")[설명],
  [`-M/--model MODEL`],
  [모델 선택],
  [`-n/--non-interactive`],
  [비대화형 모드 (단일 태스크 실행)],
  [`-S/--shell-allow-list`],
  [허용할 셸 명령 지정],
  [`--interpreter`],
  [interpreter 활성화],
  [`--interpreter-tools`],
  [interpreter에서 사용할 도구 지정],
  [`--stdin`],
  [표준 입력에서 prompt 읽기],
  [`--json`],
  [명령 출력 JSON 형식],
  [`--acp`],
  [ACP server over stdio로 실행],
)

=== 인터랙티브 명령어

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[명령],
  text(weight: "bold")[설명],
  [`/model`],
  [모델 변경],
  [`/remember`],
  [메모리에 정보 저장],
  [`/tokens`],
  [토큰 사용량 확인],
  [`!command`],
  [셸 명령 실행],
)

=== 설정과 메모리
- _글로벌 설정_: `~/.deepagents/config.toml`
- _프로젝트 지침_: `AGENTS.md`
- _스킬_: `SKILL.md` 기반 progressive disclosure
- _서브에이전트_: 설정 파일 또는 프로젝트 지침으로 역할 정의

#code-block(`````python
# Deep Agents Code 비대화형 모드 예시 (셸에서 실행)
dcode_examples = """
# 기본 사용
dcode

# 특정 모델로 비대화형 실행
dcode -M openai:gpt-5.4 -n "이 프로젝트의 README.md를 검토해 줘"

# 셸 허용 목록과 함께 실행
dcode -S "pytest,python,rg" -n "테스트 실패 원인을 찾아 줘"
"""

print("dcode 사용 예시 (터미널에서 실행):")
print(dcode_examples)
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 전체 교육 자료 정리

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[노트북],
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 API],
  [_01_],
  [소개],
  [`deepagents.__version__`],
  [_02_],
  [퀵스타트],
  [`create_deep_agent()`, `invoke()`, `stream()`],
  [_03_],
  [커스터마이징],
  [`model`, `system_prompt`, `tools`, `response_format`],
  [_04_],
  [백엔드],
  [`StateBackend`, `FilesystemBackend`, `StoreBackend`, `CompositeBackend`],
  [_05_],
  [서브에이전트],
  [`SubAgent`, `CompiledSubAgent`, `subagents`],
  [_06_],
  [메모리 & 스킬],
  [`memory`, `skills`, `AGENTS.md`, `SKILL.md`],
  [_07_],
  [고급 기능],
  [`interrupt_on`, streaming, `CodeInterpreterMiddleware`, `RubricMiddleware`, Sandbox, ACP, `dcode`],
)

=== Context Engineering 보강 (docs/deepagents/14-context-engineering.md)

- `@dynamic_prompt` 미들웨어로 요청 시점 데이터(`request.runtime.context`, `request.runtime.store`)를 시스템 프롬프트에 주입
- `context_schema`로 `user_id`/`org_id`를 선언하면 _모든 서브에이전트·도구_에 자동 전파
- 도구는 `ToolRuntime[Context]`를 받아 `runtime.context.user_id`로 런타임 값 조회

=== Permissions (docs/deepagents/16-permissions.md, `deepagents\>=0.5.2`)

- `FilesystemPermission(operations=["read"|"write"], paths=[...], mode="allow"|"deny")`
- first-match-wins 평가, 매치 없으면 기본 `allow`
- built-in FS 도구에만 적용 (커스텀 도구·MCP·샌드박스 `execute`는 우회)
- 서브에이전트 `permissions`는 부모 규칙을 _전면 대체_ (부분 오버라이드 아님)

=== 추가 업데이트 포인트

- `task(...)`는 interpreter의 top-level 함수이며, PTC의 `tools.*` allowlist와 분리해 설명합니다.
- Deep Agents CLI 명령은 `deepagents-cli`가 아니라 Deep Agents Code의 `dcode`를 기준으로 사용합니다.
