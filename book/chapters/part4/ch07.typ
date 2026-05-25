// Auto-generated from 07_advanced.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "고급 기능")

기본적인 에이전트 구축을 넘어, 프로덕션 수준의 에이전트에는 안전장치와 확장 기능이 필요하다. 이 장에서는 `interrupt_on`을 활용한 Human-in-the-Loop 워크플로, 네임스페이스 기반 스트리밍 심화, 샌드박스 프로바이더(Modal, Daytona, Runloop) 연동, `ACP`를 통한 에디터 통합, 그리고 Deep Agents CLI 사용법을 다룬다. 이 기능들을 조합하면 안전하고 관측 가능한 에이전트 시스템을 구축할 수 있다.

6장까지 에이전트의 핵심 기능(도구, 백엔드, 서브에이전트, 메모리, 스킬)을 모두 다루었다. 이 장에서는 이러한 기능들을 프로덕션 환경에서 안전하게 운영하기 위한 _가드레일과 통합 기능_에 집중한다. 특히 에이전트의 자율성이 높아질수록 _안전장치_의 중요성도 비례하여 커진다. 파일을 수정하거나 셸 명령을 실행하는 에이전트가 실수하면 복구 비용이 크기 때문이다. 또한 Deep Agents의 미들웨어 스택을 커스터마이징하여 로깅, 인증, 속도 제한 등의 횡단 관심사를 에이전트 로직과 분리하는 방법도 다룬다.

#learning-header()
#learning-objectives([Human-in-the-Loop 워크플로를 구현한다], [다양한 스트리밍 모드와 네임스페이스 시스템을 이해한다], [샌드박스(Modal, Daytona, Runloop) 연동 개념을 파악한다], [ACP(Agent Client Protocol)로 에디터와 연동하는 방법을 안다], [Deep Agents CLI 사용법을 익힌다])

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
모델 설정 완료: gpt-5.4
`````)

환경 설정을 마쳤으므로, 가장 기본적이면서도 중요한 안전장치인 Human-in-the-Loop부터 시작한다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Human-in-the-Loop (HITL)

자율 에이전트가 파일을 수정하거나 셸 명령을 실행할 때, 잘못된 판단이 치명적인 결과를 초래할 수 있습니다. 예를 들어 에이전트가 `rm -rf /` 같은 위험한 명령을 생성하거나, 프로덕션 데이터베이스에 잘못된 마이그레이션을 적용할 수 있다.

`interrupt_on` 파라미터를 사용하면, 에이전트가 지정된 도구를 호출하려 할 때 실행을 _중단하고 사람의 승인을 요구_합니다. Deep Agents의 HITL은 _4가지 결정 타입_을 지원하며, 각 결정은 `Command(resume={"decisions": [...]})` 형태의 dict로 재개 시 전달한다. 이 메커니즘은 LangGraph의 인터럽트 기능 위에 구축되어 있으며, 체크포인터가 중단 시점의 전체 상태를 보존하므로 승인 후 _정확히 그 지점_에서 실행이 재개된다.

=== 작동 방식

#align(center)[#image("../../assets/diagrams/png/hitl_flow.png", width: 84%, height: 120mm, fit: "contain")]

=== 4가지 결정 타입

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

=== 인터럽트 확인과 재개 (v2 표준)

`invoke(..., version="v2")`로 호출하면, 인터럽트는 `result.interrupts`에 노출된다. 옛 `result["__interrupt__"]` 키가 아니다. 각 인터럽트의 `interrupt_value["action_requests"]` 가 제안된 도구 호출과 `allowed_decisions`를 담는다. 같은 `thread_id`로 `Command(resume={"decisions": [...]})`을 dict 형태로 invoke하면 재개된다.

#code-block(`````python
from langgraph.types import Command

# 인터럽트 추출
result = hitl_agent.invoke(inputs, config=config, version="v2")
for itr in result.interrupts:
    for req in itr.value["action_requests"]:
        print(req["action"]["name"], req["allowed_decisions"])

# 재개 — 인터럽트와 동일한 순서의 decisions 배열
hitl_agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config,
    version="v2",
)
`````)

=== 필수 요구사항
#warning-box[Human-in-the-Loop을 사용하려면 반드시 `checkpointer`를 설정해야 합니다. 에이전트가 중단된 시점의 상태를 보존하고, 승인 후 정확히 그 지점에서 재개하기 위해 체크포인터가 필수입니다.]

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

위 예시에서 `interrupt_on`의 키는 도구 이름이고, 값이 `True`이면 해당 도구 호출 전에 항상 중단한다. 값에 조건 함수를 전달하여 _특정 조건에서만_ 중단하도록 설정할 수도 있다(예: 파일 크기가 일정 이상일 때만 승인 요구). `interrupt_on`은 서브에이전트에도 개별적으로 설정할 수 있어, 메인 에이전트는 자유롭게 동작하되 서브에이전트의 위험한 작업만 승인하는 구성도 가능하다.

#tip-box[HITL을 _모든_ 도구에 걸면 에이전트의 자율성이 크게 떨어진다. 파일 쓰기, 셸 실행, 외부 API 호출 등 _부작용(side effect)이 있는 도구_에만 선택적으로 적용하고, 읽기 전용 도구는 자유롭게 호출하도록 허용하는 것이 실용적이다.]

HITL로 안전장치를 구축했다면, 다음은 에이전트의 실행 과정을 실시간으로 관찰하는 _스트리밍_ 기능이다. 관찰 가능성(observability)은 디버깅과 사용자 경험 양면에서 중요하다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 스트리밍 심화

Deep Agents는 LangGraph의 스트리밍 인프라 위에서 작동하며, 특히 서브에이전트를 사용할 때 _네임스페이스 기반 이벤트 구분_이 중요합니다. 스트리밍을 통해 에이전트가 어떤 서브에이전트를 호출 중인지, 도구 실행이 어디까지 진행되었는지를 실시간으로 파악할 수 있다.

=== v2 통합 포맷 (표준)

_`agent.stream(..., stream_mode=..., subgraphs=True, version="v2")` 한 경로_가 표준입니다. 옛 v1의 중첩 튜플 포맷은 분기가 복잡하므로 v2를 권장하며, v3·projection 같은 비공식 변형은 사용하지 마세요. 모든 청크는 동일한 3-필드 구조입니다.

#code-block(`````python
{
    "type": "updates" | "messages" | "custom",
    "ns":   tuple,            # 이벤트 발생 위치 (메인/서브에이전트 라우팅)
    "data": Any,              # type 별 payload
}
`````)

#tip-box[`subgraphs=True`가 없으면 서브에이전트 내부 이벤트가 보이지 않는다. UI에서 서브에이전트 진행을 표시하려면 반드시 켜라. 요약(summarization) 토큰을 사용자에게 숨기려면 `metadata.get("lc_source") == "summarization"`로 필터링한다.]

=== 스트림 모드

Deep Agents에서 `stream()` 메서드 호출 시 `stream_mode` 파라미터로 스트림 모드를 선택한다. 각 모드는 서로 다른 수준의 정보를 제공하므로, 목적에 맞게 선택해야 한다. 리스트로 전달하면 한 루프에서 여러 모드를 동시에 받는다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[설명],
  text(weight: "bold")[사용 시나리오],
  [`"updates"`],
  [각 노드 완료 시 상태 업데이트],
  [진행 상황 추적],
  [`"messages"`],
  [개별 토큰 단위 스트리밍],
  [실시간 텍스트 출력],
  [`"custom"`],
  [도구 내부에서 발행하는 이벤트],
  [커스텀 진행률],
)

=== 네임스페이스 시스템

서브에이전트가 포함된 에이전트 시스템에서는 이벤트의 _출처_를 구분하는 것이 중요하다. 메인 에이전트의 토큰인지, researcher 서브에이전트의 토큰인지에 따라 UI 표시 방식이 달라져야 하기 때문이다. Deep Agents는 이를 네임스페이스 튜플로 구분한다:

#code-block(`````python
()                          # 메인 에이전트
("tools:abc123",)           # 서브에이전트 (tool call ID)
("tools:abc123", "model:def456")  # 서브에이전트 내부 노드
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

위 코드로 생성한 에이전트를 `stream()` 호출 시, 메인 에이전트의 이벤트는 빈 네임스페이스 `()`로, researcher 서브에이전트의 이벤트는 `("tools:xxx",)` 형태의 네임스페이스로 전달된다. 클라이언트 측에서 네임스페이스를 필터링하면 "현재 researcher가 작업 중입니다..." 같은 _진행 상황 표시_를 구현할 수 있다.

=== 커스텀 진행률 이벤트 (`get_stream_writer` + `stream_mode="custom"`)

도구 내부에서 임의 구조체를 방출해 UI에 노출한다. 업로드 진행률·처리 건수·중간 상태 등에 활용한다. 도구마다 스키마가 제각각이면 UI 라우팅이 깨지므로, `{"status", "progress", "message"}` 같은 공통 필드를 고정해 두는 편이 좋다.

#code-block(`````python
from langchain.tools import tool
from langgraph.config import get_stream_writer


@tool
def analyze_data(topic: str) -> str:
    """주제 데이터를 분석하고 진행률을 스트리밍한다."""
    writer = get_stream_writer()
    writer({"status": "starting", "progress": 0, "topic": topic})
    # ... 실제 분석 ...
    writer({"status": "complete", "progress": 100, "topic": topic})
    return f"분석 완료: {topic}"


for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "..."}]},
    stream_mode=["updates", "messages", "custom"],
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "custom":
        print(chunk["data"])
`````)

스트리밍으로 에이전트의 동작을 실시간 관찰할 수 있게 되었다. 다음 단계는 에이전트가 _실제 코드를 실행_할 때의 안전성이다. 샌드박스는 코드 실행을 격리된 환경으로 제한하여 호스트 시스템을 보호한다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 샌드박스 (Sandbox)

샌드박스는 에이전트가 _격리된 환경_에서 코드를 실행할 수 있게 합니다. 호스트 시스템의 파일, 네트워크, 자격 증명에 접근하지 못하므로 에이전트의 실수나 악의적 행동으로부터 시스템을 보호합니다. Deep Agents에서 샌드박스는 _백엔드_로 통합되므로, 기존 파일 도구(`read_file`, `write_file`, `run_command` 등)를 그대로 사용하면서 실행 환경만 격리할 수 있습니다. 에이전트 코드를 한 줄도 수정하지 않고 백엔드만 교체하면 로컬 실행에서 샌드박스 실행으로 전환할 수 있다는 것이 핵심이다.

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

#align(center)[#image("../../assets/diagrams/png/sandbox_architecture.png", width: 92%, height: 118mm, fit: "contain")]

#warning-box[_절대 샌드박스 안에 시크릿을 넣지 마세요._ 에이전트는 환경 변수를 읽거나 파일을 탐색하여 자격 증명을 외부로 유출할 수 있습니다. 자격 증명은 반드시 호스트(에이전트 측)의 전용 도구에서만 관리하세요.]

=== 보안 가이드라인
- 자격 증명은 외부 도구에서만 관리 -- 샌드박스 환경에 API 키를 환경 변수로 주입하지 마라
- Human-in-the-Loop으로 민감한 작업 승인 -- 샌드박스와 HITL을 결합하면 이중 안전장치가 된다
- 불필요한 네트워크 접근 차단 -- 샌드박스의 네트워크 정책을 화이트리스트 방식으로 설정
- 실행 시간 제한 설정 -- 무한 루프를 방지하기 위해 타임아웃을 반드시 지정

다음은 Modal 샌드박스를 연동하는 코드 예시이다. 다른 프로바이더(Daytona, Runloop)도 유사한 인터페이스를 따른다.

#code-block(`````python
# Modal 샌드박스 연동 — langchain-modal 패키지 사용
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
    modal_sandbox.terminate()    # 필수: 리소스 해제
`````)

#tip-box[샌드박스 프로바이더를 선택할 때는 워크로드 특성을 고려하라. GPU가 필요한 ML 작업에는 Modal이, 빠른 콜드 스타트가 중요한 웹 개발에는 Daytona가, 일회용 격리 실행이 필요한 테스트에는 Runloop이 적합하다. 각 프로바이더는 별도 패키지(`langchain-modal`, `langchain-daytona` 등)로 설치하고, `try/finally`로 반드시 `terminate()`(또는 `stop()`/`shutdown()`)를 호출해 정리한다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3-1. Interpreters — CodeInterpreterMiddleware

Deep Agents 0.6 계열은 _QuickJS 기반 interpreter_를 `CodeInterpreterMiddleware`로 붙일 수 있다. 샌드박스가 “외부 환경에서 코드를 실행”하는 격리 실행이라면, interpreter는 “에이전트 루프 내부에서 작은 프로그램을 실행”하는 내부 작업 공간이다. 도구 호출 조합, 서브에이전트 fan-out/fan-in, 구조화 데이터 처리에 쓰인다.

=== 설치

#code-block(`````bash
pip install -U "deepagents[quickjs]"
# 또는
uv add "deepagents[quickjs]"
`````)

=== Programmatic Tool Calling (PTC)

`ptc=["task"]`처럼 allowlist를 지정하면, 도구가 camelCase로 변환되어 `tools.*` async 함수로 노출된다 (예: `web_search` → `tools.webSearch`). interpreter 내부에서 `Promise.all`로 fan-out 가능하다.

#code-block(`````python
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[
        CodeInterpreterMiddleware(
            ptc=["task"],                # allowlist: task만 노출
            snapshot_between_turns=True, # turn 간 interpreter state 복원
            timeout=5.0,
            max_ptc_calls=256,
        ),
    ],
)
`````)

=== Middleware 옵션 10가지

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[기본값],
  text(weight: "bold")[용도],
  [`memory_limit`], [`64*1024*1024`], [QuickJS heap memory limit (bytes)],
  [`timeout`], [`5.0`], [Per-eval 타임아웃(초)],
  [`max_ptc_calls`], [`256`], [한 eval에서 허용되는 `tools.*` 호출 수],
  [`tool_name`], [`"eval"`], [Interpreter 도구 이름],
  [`max_result_chars`], [`4000`], [반환 결과 최대 문자 수],
  [`capture_console`], [`True`], [`console.log` 캡처],
  [`ptc`], [`None`], [PTC allowlist],
  [`skills_backend`], [`None`], [Interpreter skill 모듈용 backend],
  [`snapshot_between_turns`], [`True`], [turn 간 상태 보존],
  [`max_snapshot_bytes`], [`None`], [snapshot 최대 크기],
)

#warning-box[PTC는 일반 tool-calling 경로와 다르게 동작하므로 도구별 `interrupt_on` 승인 정책이 자동 적용된다고 가정하지 마라. 비용 발생·데이터 변경·네트워크 접근 도구는 interpreter에 노출하지 않거나 별도 승인 래퍼를 둔다.]

샌드박스가 에이전트의 _코드 실행_을 격리한다면, 다음에 다루는 ACP는 에이전트와 _개발자의 작업 환경_을 연결하는 프로토콜이다. 코딩 에이전트가 IDE와 자연스럽게 통합되려면 표준화된 통신 규약이 필요하다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. ACP (Agent Client Protocol)

ACP(Agent Client Protocol)는 코딩 에이전트와 에디터/IDE 간의 통신을 표준화하는 프로토콜로, 에이전트가 에디터 내에서 파일을 편집하고, 터미널 명령을 실행하며, 코드 변경 사항을 동기화할 수 있게 합니다. ACP를 통해 에이전트는 에디터의 _파일 시스템 뷰_, _열린 파일 목록_, _커서 위치_ 등의 맥락 정보를 활용하여 더 정확한 코드 수정을 수행할 수 있다.

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
# ACP 서버 — canonical 패턴 (asyncio + acp.run_agent)
# pip install deepagents-acp
import asyncio

from acp import run_agent
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

from deepagents_acp.server import AgentServerACP


async def main() -> None:
    agent = create_deep_agent(
        model="anthropic:claude-sonnet-4-6",
        system_prompt="You are a helpful coding assistant",
        checkpointer=MemorySaver(),
    )
    server = AgentServerACP(agent)
    await run_agent(server)


if __name__ == "__main__":
    asyncio.run(main())
`````)

#tip-box[Toad CLI로 로컬에서 ACP 서버를 띄울 수 있다 — `uv tool install -U batrachian-toad` 설치 후 `toad acp "python path/to/your_server.py" .` 로 실행. 프로세스의 시작·종료·재시작을 자동으로 관리해 준다.]

=== Context Engineering — `@dynamic_prompt`

요청 시점 데이터를 시스템 프롬프트에 주입하려면 `@dynamic_prompt` 미들웨어를 사용한다. `request.runtime.context`와 `request.runtime.store`에 접근할 수 있어, `context_schema`로 선언한 `user_id`/`org_id`가 모든 서브에이전트·도구에 자동 전파된다. 도구는 `ToolRuntime[Context]`를 받아 `runtime.context.user_id`로 런타임 값을 조회한다.

#code-block(`````python
from deepagents.middleware import dynamic_prompt

@dynamic_prompt
def inject_user(request):
    user_id = request.runtime.context.user_id
    pref = request.runtime.store.get(("prefs", user_id), "lang")
    return f"\n\nUser: {user_id} / Preferred language: {pref}"
`````)

=== Permissions (`deepagents>=0.5.2`)

`FilesystemPermission`으로 built-in FS 도구의 읽기/쓰기 권한을 _first-match-wins_ 방식으로 제어한다. 매치가 하나도 없으면 기본 `allow`다. 커스텀 도구·MCP·샌드박스 `execute`는 이 권한을 우회하므로 별도 가드가 필요하다. 서브에이전트의 `permissions`는 부모 규칙을 _전면 대체_(부분 오버라이드 아님).

#code-block(`````python
from deepagents.permissions import FilesystemPermission

permissions = [
    FilesystemPermission(operations=["write"], paths=["/policies/**"], mode="deny"),
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/**"], mode="allow"),
]
`````)

#tip-box[MCP(Model Context Protocol)와 ACP의 차이를 기억하세요. MCP는 에이전트가 _외부 서비스_(데이터베이스, API 등)에 접근하기 위한 프로토콜이고, ACP는 에이전트가 _개발 환경_(에디터/IDE)과 상호작용하기 위한 프로토콜입니다. 두 프로토콜은 상호 배타적이 아니라 _보완적_으로 사용된다. 하나의 에이전트가 MCP로 데이터베이스에 접근하면서, ACP로 에디터와 소통하는 것이 일반적인 구성이다.]

=== 미들웨어 스택 커스터마이징

Deep Agents의 에이전트 실행 파이프라인은 미들웨어 스택으로 구성되어 있다. 기본 미들웨어(MemoryMiddleware, SkillsMiddleware, InterruptMiddleware 등) 외에 _커스텀 미들웨어_를 추가하여 로깅, 인증, 속도 제한, 토큰 추적 등의 횡단 관심사를 에이전트 로직과 분리할 수 있다. `create_deep_agent()`의 `middleware` 파라미터에 미들웨어 리스트를 전달하면 된다. 미들웨어는 _순서가 중요_하며, 먼저 등록된 미들웨어가 먼저 실행된다. 예를 들어 인증 미들웨어를 로깅 미들웨어보다 앞에 두면, 인증 실패 시 로깅도 수행되지 않는다.

#warning-box[커스텀 미들웨어를 추가할 때 기본 미들웨어를 _덮어쓰지_ 않도록 주의하라. `middleware` 파라미터를 지정하면 기본 미들웨어에 _추가_되는 방식이지만, 같은 이름의 미들웨어가 있으면 교체될 수 있다. 기본 미들웨어(Memory, Skills, Interrupt 등)를 실수로 제거하면 해당 기능이 동작하지 않는다.]

SDK로 에이전트를 프로그래밍 방식으로 구축하는 것 외에, Deep Agents는 터미널에서 바로 사용할 수 있는 CLI도 제공한다. 다음 섹션에서 CLI의 설치와 사용법을 알아본다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Deep Agents CLI

SDK로 에이전트를 프로그래밍 방식으로 구축하는 것 외에, Deep Agents는 SDK 위에 구축된 _터미널 코딩 에이전트_ CLI도 제공합니다. 별도의 코드 작성 없이 터미널에서 즉시 사용할 수 있습니다. CLI는 `create_deep_agent()`로 만든 에이전트와 동일한 기능(도구, 백엔드, 서브에이전트, 메모리, 스킬, 샌드박스)을 모두 지원하며, 프로젝트 루트의 `.deepagents/AGENTS.md` 파일을 자동으로 인식한다.

=== 설치 및 실행
#code-block(`````bash
# 설치
uv tool install deepagents-cli

# 실행
deepagents-cli

# 직접 실행 (설치 없이)
uvx deepagents-cli
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
  [`-a/--agent AGENT`],
  [에이전트 이름 지정],
  [`-M/--model MODEL`],
  [모델 선택],
  [`-n/--non-interactive`],
  [비대화형 모드 (단일 태스크 실행)],
  [`--auto-approve`],
  [인간 확인 스킵],
  [`--sandbox {none,modal,daytona,runloop}`],
  [샌드박스 백엔드 선택],
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
  [쉘 명령 실행],
)

=== 메모리 시스템
CLI의 메모리 시스템은 두 가지 계층으로 동작한다. 글로벌 메모리는 모든 프로젝트에서 공유되며, 프로젝트 메모리는 해당 프로젝트에서만 적용된다.
- _글로벌_: `~/.deepagents/<agent_name>/memories/` -- 사용자 선호도, 공통 설정
- _프로젝트_: `.deepagents/AGENTS.md` (프로젝트 루트) -- 프로젝트 컨벤션, 아키텍처 결정

#warning-box[CLI에서 `--auto-approve` 옵션을 사용하면 모든 도구 호출이 승인 없이 실행된다. 신뢰할 수 있는 환경에서만 사용하고, 프로덕션 서버에서는 _절대 사용하지 마라_. 실수로 위험한 명령이 실행될 수 있다.]

#code-block(`````python
# CLI 비대화형 모드 예시 (셸에서 실행)
cli_examples = """
# 기본 사용
deepagents-cli

# 특정 모델로 비대화형 실행
deepagents-cli -M claude-sonnet-4-6 -n "이 프로젝트의 README.md를 작성해 줘"

# 샌드박스에서 실행
deepagents-cli --sandbox modal "테스트 코드를 실행해 줘"

# 스킬 관리
deepagents-cli skills list
deepagents-cli skills create my-skill
"""

print("CLI 사용 예시 (터미널에서 실행):")
print(cli_examples)
`````)
#output-block(`````
CLI 사용 예시 (터미널에서 실행):

# 기본 사용
deepagents-cli

# 특정 모델로 비대화형 실행
deepagents-cli -M claude-sonnet-4-6 -n "이 프로젝트의 README.md를 작성해 줘"

# 샌드박스에서 실행
deepagents-cli --sandbox modal "테스트 코드를 실행해 줘"

# 스킬 관리
deepagents-cli skills list
deepagents-cli skills create my-skill
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
  [`interrupt_on`, `stream_mode`, Sandbox, ACP, CLI],
)

이 장에서 다룬 고급 기능들(HITL, 스트리밍, 샌드박스, ACP, CLI)은 에이전트를 프로덕션 환경에서 안전하게 운영하기 위한 필수 요소입니다. 다음 장에서는 `create_deep_agent()` 내부에서 이 모든 기능을 조립하는 _AgentHarness_의 구조를 분석합니다.
