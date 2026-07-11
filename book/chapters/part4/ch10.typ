// Auto-generated from 10_sandboxes_and_acp.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "샌드박스와 ACP")

== 학습 목표
#learning-objectives([샌드박스 격리 개념과 보안 원칙을 이해한다], [E2B, Modal, Docker 등 샌드박스 프로바이더를 비교한다], [ACP(Agent Communication Protocol)의 개요와 용도를 안다], [에이전트-에디터 통합 패턴을 이해한다], [샌드박스 + ACP 통합 아키텍처를 설계한다])

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

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")

print(f"모델 설정 완료: {model.model_name}")
`````)
#output-block(`````
모델 설정 완료: gpt-5.4
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 샌드박스 개념

_샌드박스_는 AI 에이전트가 코드를 실행하고, 파일을 관리하고, 쉘 명령을 수행할 수 있는 _격리된 실행 환경_입니다.

=== 왜 격리가 중요한가?

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[위험],
  text(weight: "bold")[격리 없을 때],
  text(weight: "bold")[샌드박스 사용 시],
  [파일 시스템 접근],
  [호스트 파일 변경/삭제 가능],
  [격리된 파일시스템만 접근],
  [네트워크 접근],
  [무제한 외부 통신],
  [제한된 네트워크 접근],
  [자격 증명],
  [환경 변수 유출 가능],
  [시크릿 격리],
  [시스템 영향],
  [호스트 OS에 영향],
  [호스트 시스템 보호],
)

Deep Agents에서 샌드박스는 _백엔드_로 동작하며, 파일시스템 도구(`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`)와 `execute` 도구를 제공합니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 아키텍처 패턴

샌드박스 통합에는 두 가지 주요 패턴이 있습니다.

=== Agent-in-Sandbox
에이전트가 샌드박스 _내부_에서 실행되며, 네트워크 프로토콜로 외부와 통신합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[장점],
  text(weight: "bold")[단점],
  [개발 환경과 동일한 경험],
  [자격 증명 노출 위험],
  [간단한 설정],
  [인프라 복잡성 증가],
)

=== Sandbox-as-Tool (권장)
에이전트가 _외부_에서 실행되며, 샌드박스 API를 호출하여 코드를 실행합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[장점],
  text(weight: "bold")[단점],
  [에이전트 상태와 실행 분리],
  [네트워크 지연],
  [시크릿을 샌드박스 외부에 유지],
  [],
  [병렬 태스크 실행 가능],
  [],
)

#code-block(`````python
# 두 가지 아키텍처 패턴 비교 (참고용)
print("=== 패턴 1: Agent-in-Sandbox ===")
print("  [샌드박스]")
print("    |-- 에이전트 (내부 실행)")
print("    |-- 파일시스템")
print("    |-- 코드 실행")
print("    <---> 네트워크 프로토콜 <---> 외부 시스템")

print()
print("=== 패턴 2: Sandbox-as-Tool (권장) ===")
print("  [호스트]")
print("    |-- 에이전트 (외부 실행)")
print("    |-- 자격 증명 관리")
print("    |-- API 호출 --> [샌드박스]")
print("                       |-- 파일시스템")
print("                       |-- 코드 실행")
`````)
#output-block(`````
=== 패턴 1: Agent-in-Sandbox ===
  [샌드박스]
    |-- 에이전트 (내부 실행)
    |-- 파일시스템
    |-- 코드 실행
    <---> 네트워크 프로토콜 <---> 외부 시스템

=== 패턴 2: Sandbox-as-Tool (권장) ===
  [호스트]
    |-- 에이전트 (외부 실행)
    |-- 자격 증명 관리
    |-- API 호출 --> [샌드박스]
                       |-- 파일시스템
                       |-- 코드 실행
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 샌드박스 프로바이더 비교 (Deep Agents 0.4+ 공식 패키지)

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패키지],
  text(weight: "bold")[공급자],
  text(weight: "bold")[특징],
  [`langchain-modal`],
  [_Modal_],
  [GPU 지원, ML/AI 워크로드, 데이터 처리],
  [`langchain-daytona`],
  [_Daytona_],
  [TypeScript/Python, 빠른 콜드 스타트],
  [`langchain-runloop`],
  [_Runloop_],
  [일회용 devbox 기반 격리],
  [`langsmith[sandbox]`],
  [_LangSmith_],
  [LangSmith Deployments 통합 (private beta)],
  [`langchain-agentcore-codeinterpreter`],
  [_AgentCore_],
  [AWS Bedrock 기반 코드 인터프리터],
)

공통 흐름: 공급자 SDK로 샌드박스 생성 → `*Sandbox` 래퍼로 backend 생성 → `create_deep_agent(backend=...)` → `try/finally`로 정리(`terminate`/`stop`/`shutdown`).


#code-block(`````python
# Modal 샌드박스 예시 (참고용) — docs/deepagents/11-sandboxes.md
import textwrap

modal_example = textwrap.dedent('''
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
''')

print("=== Modal 샌드박스 예시 ===")
print(modal_example)

`````)
#output-block(`````
=== Modal 샌드박스 설정 ===
  provider: modal
  image: python:3.12-slim
  gpu: T4
  timeout: 300

코드 예시 (참고용):
  from deepagents.backends.sandbox import ModalSandbox
  agent = create_deep_agent(
      model="gpt-5.4",
      backend=ModalSandbox(image="python:3.12-slim", gpu="T4"),
  )
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 보안 가이드라인

=== 절대 샌드박스 안에 시크릿을 넣지 마세요

컨텍스트에 주입된 에이전트는 환경 변수나 마운트된 파일로 저장된 자격 증명을 읽고 유출할 수 있습니다.

=== 안전한 관행

+ _자격 증명은 외부 도구에서만 관리_ — 샌드박스 외부의 전용 도구 사용
+ _Human-in-the-Loop_ — 민감한 작업에 사람 승인 요구
+ _네트워크 접근 차단_ — 불필요한 아웃바운드 연결 차단
+ _아웃바운드 모니터링_ — 예기치 않은 외부 연결 감시
+ _출력 검토_ — 샌드박스 출력을 애플리케이션에 적용하기 전 검토

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 파일 전송과 라이프사이클

=== 파일 접근 방법

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[방법],
  text(weight: "bold")[설명],
  [에이전트 파일시스템 도구],
  [`execute()`를 통한 직접 파일 작업],
  [파일 전송 API],
  [`uploadFiles()`, `downloadFiles()`로 시드/아티팩트 관리],
)

=== 라이프사이클 관리
샌드박스는 불필요한 비용을 막기 위해 _명시적 종료_가 필요합니다.
채팅 애플리케이션에서는 대화 스레드별 고유 샌드박스에 TTL(Time-to-Live) 설정을 사용합니다.

#code-block(`````python
# 라이프사이클 모드 (참고용) — docs/deepagents/11-sandboxes.md
lifecycle_modes = {
    "Thread-scoped (기본)": {
        "설명": "대화 thread 1개당 샌드박스 1개. 첫 run에서 생성, 같은 thread의 다음 turn에서 재사용",
        "정리": "idle TTL로 자동 정리",
        "적합": "멀티 턴 대화, 사용자별 격리",
    },
    "Assistant-scoped": {
        "설명": "같은 assistant의 모든 thread가 샌드박스 1개를 공유. 파일·패키지·레포지토리가 대화 사이에 누적",
        "정리": "반드시 TTL 또는 주기적 스냅샷 설정 필요 (누적 무한정)",
        "적합": "개발 환경 공유, 캐시 누적이 이득인 워크로드",
    },
}

file_operations = [
    "uploadFiles(['/local/data.csv'], '/sandbox/data/')",
    "downloadFiles(['/sandbox/output/result.json'], '/local/results/')",
]

print("=== 라이프사이클 모드 ===")
for mode, attrs in lifecycle_modes.items():
    print(f"\n[{mode}]")
    for k, v in attrs.items():
        print(f"  {k}: {v}")

print("\n=== 파일 전송 예시 ===")
for op in file_operations:
    print(f"  {op}")

`````)
#output-block(`````
=== 라이프사이클 설정 ===
  ttl_seconds: 1800
  auto_shutdown: True
  thread_isolation: True

=== 파일 전송 예시 ===
  uploadFiles(['/local/data.csv'], '/sandbox/data/')
  downloadFiles(['/sandbox/output/result.json'], '/local/results/')
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. ACP 개요

_ACP(Agent Client Protocol)_는 코딩 에이전트와 개발 환경(에디터/IDE) 간의 통신을 표준화하는 프로토콜입니다.

=== MCP vs ACP

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[프로토콜],
  text(weight: "bold")[용도],
  text(weight: "bold")[대상],
  [_MCP_ (Model Context Protocol)],
  [외부 도구 통합],
  [에이전트 ↔ 외부 서비스],
  [_ACP_ (Agent Client Protocol)],
  [에디터-에이전트 통합],
  [에이전트 ↔ 에디터/IDE],
)

ACP를 쓰면 에이전트가 에디터와 직접 상호작용하여 코드 편집, 파일 탐색, 터미널 명령을 수행할 수 있습니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. ACP 서버 구현

#code-block(`````python
# ACP 서버 구현 예시 (참고용) — docs/deepagents/14-acp.md
acp_server_code = '''
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

print("=== ACP 서버 구현 예시 ===")
print(acp_server_code)

print("설치: pip install deepagents-acp")
print("실행: python acp_server.py  (stdio 모드)")

`````)
#output-block(`````
=== ACP 서버 구현 예시 ===

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

설치: pip install deepagents-acp
실행: python acp_server.py (stdio 모드)
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 8. ACP 지원 에디터

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[에디터],
  text(weight: "bold")[통합 방식],
  [_Zed_],
  [네이티브 통합],
  [_JetBrains IDEs_],
  [빌트인 지원],
  [_Visual Studio Code_],
  [vscode-acp 플러그인],
  [_Neovim_],
  [ACP 호환 플러그인],
)

=== Zed 설정 예시

#code-block(`````json
// Zed settings.json
{
  "agent_servers": [
    {
      "command": "python",
      "args": ["acp_server.py"],
      "env": {
        "ANTHROPIC_API_KEY": "sk-..."
      }
    }
  ]
}
`````)

=== 추가 도구: Toad (`batrachian-toad`)

_Toad_는 ACP 서버를 로컬 개발 도구로 실행하기 위한 프로세스 관리자입니다. `uv tool`로 설치합니다.

#code-block(`````bash
# 설치
uv tool install -U batrachian-toad

# 실행
toad acp "python path/to/your_server.py" .
# 또는
toad acp "uv run python path/to/your_server.py" .
`````)


#line(length: 100%, stroke: 0.5pt + luma(200))
== 9. 샌드박스 + ACP 통합

샌드박스와 ACP를 결합하면 에디터에서 에이전트를 제어하면서, 코드 실행은 격리된 환경에서 수행하는 _완전한 아키텍처_를 구현할 수 있습니다.

=== 통합 아키텍처

#code-block(`````python
[에디터/IDE] <-- ACP --> [에이전트] <-- API --> [샌드박스]
    |                       |                      |
  코드 편집              태스크 관리            코드 실행
  파일 탐색              컨텍스트 관리          파일 격리
  터미널 UI              도구 호출              보안 환경
`````)

=== 장점
- 에디터에서 직접 에이전트와 상호작용
- 코드 실행은 안전한 샌드박스에서 수행
- 시크릿은 호스트(에이전트 측)에서만 관리

#code-block(`````python
# 샌드박스 + ACP 통합 예시 (참고용)
integrated_config = '''
# pip install langchain-modal deepagents deepagents-acp
import asyncio

import modal
from acp import run_agent
from deepagents import create_deep_agent
from langchain_anthropic import ChatAnthropic
from langchain_modal import ModalSandbox
from langgraph.checkpoint.memory import MemorySaver

from deepagents_acp.server import AgentServerACP


async def main() -> None:
    app = modal.App.lookup("your-app")
    modal_sandbox = modal.Sandbox.create(app=app)
    backend = ModalSandbox(sandbox=modal_sandbox)

    agent = create_deep_agent(
        model=ChatAnthropic(model="claude-sonnet-4-6"),
        system_prompt="당신은 코딩 어시스턴트입니다.",
        backend=backend,
        checkpointer=MemorySaver(),
        interrupt_on={"execute": True},  # 코드 실행 전 승인
    )

    server = AgentServerACP(agent)
    try:
        await run_agent(server)
    finally:
        modal_sandbox.terminate()


if __name__ == "__main__":
    asyncio.run(main())
'''

print("=== 샌드박스 + ACP 통합 예시 ===")
print(integrated_config)

print("이 구성의 효과:")
print("  1. 에디터에서 ACP를 통해 에이전트와 상호작용")
print("  2. 코드 실행은 Modal 샌드박스에서 안전하게 수행")
print("  3. execute 호출 시 Human-in-the-Loop 승인 필요 (interrupt_on)")

`````)
#output-block(`````
=== 샌드박스 + ACP 통합 예시 ===

from deepagents import create_deep_agent
from deepagents.backends.sandbox import ModalSandbox
from deepagents_acp import AgentServerACP
from langgraph.checkpoint.memory import MemorySaver

# 샌드박스 백엔드 + ACP 서버 통합
agent = create_deep_agent(
    model="gpt-5.4",
    system_prompt="당신은 코딩 어시스턴트입니다.",
    backend=ModalSandbox(image="python:3.12-slim"),
    checkpointer=MemorySaver(),
    interrupt_on={"execute": True},  # 코드 실행 전 승인
)

# ACP로 에디터와 연결
server = AgentServerACP(agent)
server.run()

이 구성의 효과:
  1. 에디터에서 ACP를 통해 에이전트와 상호작용
  2. 코드 실행은 Modal 샌드박스에서 안전하게 수행
  3. execute 호출 시 Human-in-the-Loop 승인 필요
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
#chapter-summary-header()

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 개념],
  text(weight: "bold")[핵심 API/도구],
  [샌드박스 개념],
  [격리된 실행 환경으로 호스트 보호],
  [`execute`, 파일시스템 도구],
  [아키텍처 패턴],
  [Agent-in-Sandbox vs Sandbox-as-Tool],
  [Sandbox-as-Tool 권장],
  [프로바이더],
  [Modal(GPU), Daytona(빠른 시작), Runloop(일회용), LangSmith[sandbox], AgentCore],
  [`ModalSandbox`, `DaytonaSandbox`, `RunloopSandbox`],
  [라이프사이클],
  [_Thread-scoped(기본)_ vs _Assistant-scoped(공유, TTL 필수)_],
  [`terminate`/`stop`/`shutdown`],
  [보안],
  [시크릿 외부 관리, HITL, 네트워크 차단],
  [`interrupt_on`],
  [ACP 개요],
  [에디터-에이전트 통신 표준화],
  [`AgentServerACP`, `run_agent`],
  [ACP 서버],
  [asyncio + `run_agent`로 stdio 모드 띄우기],
  [`deepagents-acp`],
  [Toad CLI],
  [ACP 서버 프로세스 관리자],
  [`uv tool install -U batrachian-toad`, `toad acp`],
  [에디터 통합],
  [Zed, JetBrains, VS Code, Neovim],
  [ACP 프로토콜],
  [통합 패턴],
  [에디터 ↔ 에이전트 ↔ 샌드박스],
  [ACP + Sandbox 결합],
)



#references-box[
- #link("../docs/deepagents/11-sandboxes.md")[Sandboxes]
- #link("../docs/deepagents/14-acp.md")[Agent Client Protocol (ACP)]
]
#chapter-end()
