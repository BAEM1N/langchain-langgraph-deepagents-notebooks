// Auto-generated from 10_sandboxes_and_acp.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "샌드박스와 ACP")

에이전트가 코드를 실행하고 파일을 조작할 때, 호스트 시스템의 보안을 보장하는 것은 프로덕션 배포의 필수 조건이다. 이 장에서는 격리된 실행 환경인 샌드박스의 개념과 `Modal`, `Daytona`, `Runloop` 등 프로바이더별 특징을 비교하고, `ACP`(Agent Client Protocol)를 통해 에디터/IDE와 에이전트를 통합하는 방법을 다룬다. 샌드박스와 ACP를 결합한 아키텍처는 안전한 코드 실행과 직관적인 개발자 경험을 동시에 제공한다.

7장에서 샌드박스와 ACP를 개념적으로 소개했다면, 이 장에서는 아키텍처 패턴, 프로바이더 선택 기준, 보안 가이드라인, 에디터 통합 설정까지 실무에 필요한 세부 사항을 심화한다. Deep Agents 기반 프로덕션 에이전트를 배포할 때 이 두 기술은 _안전성_(샌드박스)과 _개발자 경험_(ACP)이라는 두 축을 담당한다.

이 장을 관통하는 핵심 질문은 다음과 같다: "에이전트에게 코드 실행 능력을 부여하면서, 어떻게 호스트 시스템을 안전하게 보호하고, 동시에 개발자에게 자연스러운 사용 경험을 제공할 수 있는가?" 샌드박스는 이 질문의 _보안_ 측면을, ACP는 _사용성_ 측면을 해결한다.

#learning-header()
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
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

print(f"모델 설정 완료: {model.model_name}")
`````)
#output-block(`````
모델 설정 완료: gpt-4.1
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 샌드박스 개념

_샌드박스_는 AI 에이전트가 코드를 실행하고, 파일을 관리하고, 쉘 명령을 수행할 수 있는 _격리된 실행 환경_입니다. 일반적인 소프트웨어 개발에서도 컨테이너(Docker)로 실행 환경을 격리하지만, AI 에이전트의 경우 격리의 중요성이 훨씬 큽니다. 에이전트는 _비결정적(non-deterministic)_이기 때문입니다. 동일한 프롬프트에도 매번 다른 명령을 실행할 수 있으며, 모델의 할루시네이션으로 인해 의도치 않은 위험한 명령(예: `rm -rf /`)을 생성할 가능성이 항상 존재합니다.

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

Deep Agents에서 샌드박스는 _백엔드_로 기능합니다. 4장에서 학습한 `BackendProtocol`을 구현하므로, 기존 파일시스템 도구(`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`)를 그대로 사용할 수 있으며, 추가로 `execute` 도구가 노출됩니다. 에이전트 코드를 변경하지 않고 `backend` 파라미터만 교체하면 로컬 실행에서 샌드박스 실행으로 전환할 수 있습니다.

#tip-box[샌드박스를 도입할 때 가장 큰 장점은 _코드 변경 없는 전환_입니다. 개발 단계에서는 로컬 파일시스템 백엔드로 빠르게 반복하고, 프로덕션 배포 시에만 `backend=ModalSandbox(...)` 한 줄을 추가하면 됩니다. 이 플러거블 설계 덕분에 개발-배포 간의 마찰이 최소화됩니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 아키텍처 패턴

샌드박스의 필요성을 이해했으니, 이제 에이전트와 샌드박스를 _어떻게_ 연결할 것인지 아키텍처를 살펴봅니다.

샌드박스를 에이전트와 통합하는 방식에는 두 가지 근본적으로 다른 접근법이 있습니다. 이 선택은 단순한 구현 방식의 차이가 아니라, _보안 경계(security boundary)_를 어디에 설정하느냐의 문제입니다. 각 패턴의 보안 모델과 운영 특성을 이해하면 프로젝트에 맞는 올바른 선택을 할 수 있습니다.

#align(center)[#image("../../assets/diagrams/png/sandbox_acp_sequence.png", width: 78%, height: 112mm, fit: "contain")]

위 시퀀스 다이어그램에서 핵심은 _에이전트의 지능_ 과 _실행 권한_ 이 분리된다는 점입니다. ACP는 개발자 경험을 담당하고, 샌드박스는 실제 실행을 격리합니다. 따라서 실무에서는 “어디서 추론하고, 어디서 실행하는가?”를 먼저 결정하면 패턴 선택이 훨씬 쉬워집니다.

=== Agent-in-Sandbox
에이전트가 샌드박스 _내부_에서 실행되며, 네트워크 프로토콜을 통해 외부와 통신합니다.

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
에이전트가 _외부(호스트)_에서 실행되며, 샌드박스 API를 호출하여 코드를 실행합니다. Deep Agents의 기본 접근법이며, 보안상 이 패턴을 강력히 권장합니다. 에이전트의 _두뇌_(모델 호출, 상태 관리)와 _손_(코드 실행, 파일 조작)을 물리적으로 분리하는 것이 핵심입니다.

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

#warning-box[Agent-in-Sandbox 패턴에서는 에이전트가 자격 증명에 접근할 수 있어 보안 위험이 크게 증가합니다. 에이전트가 `os.environ`으로 API 키를 읽거나, `cat ~/.ssh/id_rsa`로 SSH 키를 확인하거나, 네트워크를 통해 외부로 데이터를 전송할 수 있습니다. 프로덕션 환경에서는 반드시 Sandbox-as-Tool 패턴을 사용하세요.]

#note-box[_패턴 선택 요약_
- _Agent-in-Sandbox_ 는 로컬 개발 경험은 단순하지만 보안 경계가 약합니다.
- _Sandbox-as-Tool_ 은 네트워크 호출이 추가되지만 시크릿과 실행 권한을 분리할 수 있습니다.
- ACP를 함께 쓰면 에디터 UX는 유지하면서도 실제 코드는 샌드박스에서만 실행되도록 설계할 수 있습니다.]

다음 코드는 두 아키텍처 패턴의 구조적 차이를 ASCII 다이어그램으로 보여줍니다.

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
== 3. 샌드박스 프로바이더 비교

아키텍처 패턴을 결정했다면, 다음 질문은 "어떤 프로바이더를 사용할 것인가?"입니다. Deep Agents는 여러 클라우드 샌드박스 프로바이더를 지원하며, 각 프로바이더는 고유한 강점을 가지고 있습니다. 프로바이더 선택의 핵심 기준은 _워크로드 유형_, _콜드 스타트 시간_, _비용 구조_입니다.

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
  [AI/ML 작업, 데이터 처리],
  [_Daytona_],
  [TypeScript/Python, 빠른 콜드 스타트],
  [웹 개발, 빠른 반복],
  [_Runloop_],
  [일회용 devbox, 격리 실행],
  [코드 테스트, 일회성 작업],
)

프로바이더 선택 기준을 정리하면:
- *GPU가 필요한 ML/AI 작업* -- Modal이 유일한 선택입니다. 모델 학습, 추론, 대규모 데이터 처리에 적합합니다.
- *웹 개발 에이전트* -- Daytona의 빠른 콜드 스타트가 유리합니다. TypeScript/Python 환경이 즉시 준비됩니다.
- *일회성 코드 검증* -- Runloop의 일회용 devbox가 비용 효율적입니다. 테스트 실행 후 자동 삭제됩니다.

다음 코드는 Modal 프로바이더를 사용한 샌드박스 설정 예시입니다.

#code-block(`````python
# Modal 샌드박스 설정 예시 (참고용)
modal_config = {
    "provider": "modal",
    "image": "python:3.12-slim",
    "gpu": "T4",
    "timeout": 300,
}

print("=== Modal 샌드박스 설정 ===")
for key, value in modal_config.items():
    print(f"  {key}: {value}")

print()
print("코드 예시 (참고용):")
print('  from deepagents.backends.sandbox import ModalSandbox')
print('  agent = create_deep_agent(')
print('      model="gpt-4.1",')
print('      backend=ModalSandbox(image="python:3.12-slim", gpu="T4"),')
print('  )')
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
      model="gpt-4.1",
      backend=ModalSandbox(image="python:3.12-slim", gpu="T4"),
  )
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 보안 가이드라인

프로바이더를 선택하고 샌드박스를 설정하더라도, 보안 관행을 따르지 않으면 격리의 의미가 퇴색됩니다. 이 섹션은 샌드박스 운영에서 반드시 지켜야 할 보안 원칙을 정리합니다.

#warning-box[_절대 샌드박스 안에 시크릿을 넣지 마세요._ 에이전트는 환경 변수를 읽거나(`os.environ`), 파일을 탐색하거나(`cat ~/.ssh/id_rsa`), 네트워크를 통해 외부로 데이터를 전송할 수 있습니다. API 키, 데이터베이스 자격 증명, SSH 키 등은 반드시 샌드박스 외부의 전용 도구에서만 관리하세요.]

=== 안전한 관행

+ _자격 증명은 외부 도구에서만 관리_ — 샌드박스 외부의 전용 도구 사용
+ _Human-in-the-Loop_ — 민감한 작업에 대해 사람 승인 요구
+ _네트워크 접근 차단_ — 불필요한 아웃바운드 연결 차단
+ _아웃바운드 모니터링_ — 예기치 않은 외부 연결 감시. 에이전트가 `curl` 등으로 외부 서버에 데이터를 전송하는지 모니터링
+ _출력 검토_ — 샌드박스 출력을 애플리케이션에 적용하기 전 검토. 특히 에이전트가 생성한 파일이 악성 코드를 포함하지 않는지 확인
+ _최소 권한 원칙_ — 샌드박스에 필요한 최소한의 권한만 부여. root 접근, 불필요한 파일 마운트, 과도한 메모리 할당을 제한

#note-box[보안은 _계층적(defense-in-depth)_ 접근이 효과적입니다. 샌드박스 격리만으로는 완벽한 보안을 보장할 수 없습니다. Human-in-the-Loop(8장), 네트워크 정책, 출력 검증을 함께 적용하여 여러 계층의 방어선을 구축하세요.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 파일 전송과 라이프사이클

보안 가이드라인을 확립했으니, 이제 샌드박스를 실제로 운영하는 방법을 다룹니다.

샌드박스를 실무에서 운영할 때는 파일 전송과 라이프사이클 관리가 중요합니다. 샌드박스 내부의 파일시스템은 격리되어 있으므로, 입력 데이터를 업로드하고 결과물을 다운로드하는 메커니즘이 필요합니다. 이 과정을 _시딩(seeding)_과 _아티팩트 수집(artifact collection)_이라고 합니다.

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
샌드박스는 불필요한 비용을 방지하기 위해 _명시적 종료_가 필요합니다.
채팅 애플리케이션에서는 대화 스레드별 고유 샌드박스에 TTL(Time-to-Live) 설정을 사용합니다. 샌드박스를 종료하지 않으면 클라우드 프로바이더 비용이 계속 발생하므로, 반드시 타임아웃이나 명시적 종료 메커니즘을 구현해야 합니다.

#tip-box[대화형 에이전트에서는 대화 스레드마다 고유한 샌드박스를 할당하고, TTL을 30분 정도로 설정하는 것이 일반적입니다. 사용자가 대화를 재개하면 새 샌드박스를 생성하되, 이전 상태를 파일 전송 API로 복원할 수 있습니다.]

#code-block(`````python
# 파일 전송과 라이프사이클 설정 예시 (참고용)
lifecycle_config = {
    "ttl_seconds": 1800,  # 30분
    "auto_shutdown": True,
    "thread_isolation": True,
}

file_operations = [
    "uploadFiles(['/local/data.csv'], '/sandbox/data/')",
    "downloadFiles(['/sandbox/output/result.json'], '/local/results/')",
]

print("=== 라이프사이클 설정 ===")
for key, value in lifecycle_config.items():
    print(f"  {key}: {value}")

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

여기서부터 이 장의 두 번째 주제인 ACP로 전환합니다. 샌드박스가 에이전트의 _안전한 실행 환경_을 제공했다면, ACP는 에이전트를 _개발자의 일상 도구_로 통합하는 역할을 합니다.

샌드박스가 에이전트의 _실행 환경 안전성_을 담당한다면, ACP는 에이전트와 _개발자 워크플로_를 연결하는 역할을 합니다. _ACP(Agent Client Protocol)_는 코딩 에이전트와 개발 환경(에디터/IDE) 간의 통신을 표준화하는 프로토콜로, 에이전트가 에디터 내에서 직접 파일을 편집하고, 변경 사항을 실시간으로 동기화할 수 있게 합니다.

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

ACP는 에이전트가 에디터와 직접 상호작용하여 코드 편집, 파일 탐색, 터미널 명령을 수행할 수 있게 합니다. stdio(표준 입출력) 기반 통신을 사용하므로, 에디터가 에이전트 프로세스를 자식 프로세스로 실행하고 stdin/stdout 파이프로 메시지를 주고받습니다. 이 방식은 네트워크 설정이 필요 없어 로컬 개발 환경에 특히 적합합니다.

#note-box[ACP는 7장에서 소개한 MCP(Model Context Protocol)와 상호 보완적입니다. MCP로 외부 도구(데이터베이스, API)를 에이전트에 연결하고, ACP로 에이전트를 에디터에 연결하면, 완전한 개발자 도구 체인이 구성됩니다. 두 프로토콜의 역할을 혼동하지 마세요: MCP는 _에이전트가 사용하는 도구_를 확장하고, ACP는 _에이전트를 사용하는 인터페이스_를 확장합니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. ACP 서버 구현

ACP의 개념을 이해했으니, 실제 구현을 살펴봅니다. ACP 서버는 Deep Agents 에이전트를 에디터가 소비할 수 있는 형태로 노출하는 역할을 합니다. `deepagents-acp` 패키지의 `AgentServerACP` 클래스가 이를 담당합니다.

다음 코드는 ACP 서버의 최소 구현 예시입니다. `create_deep_agent()`로 에이전트를 생성하고, `AgentServerACP`로 감싸면 에디터와 통신할 수 있는 ACP 서버가 완성됩니다.

#code-block(`````python
# ACP 서버 구현 예시 (참고용)
acp_server_code = """
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
"""

print("=== ACP 서버 구현 예시 ===")
print(acp_server_code)

print("설치: pip install deepagents-acp")
print("실행: python acp_server.py (stdio 모드)")
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

ACP 서버를 구현했다면, 이제 어떤 에디터에서 이 서버에 연결할 수 있는지 확인합니다. 현재 ACP를 지원하는 주요 에디터와 통합 방식은 다음과 같습니다.

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

=== 추가 도구: Toad
_Toad_는 ACP 서버를 로컬 개발 도구로 실행하기 위한 프로세스 관리자입니다.
`uv`를 통해 설치할 수 있습니다. Toad를 사용하면 ACP 서버의 시작, 종료, 재시작을 자동으로 관리할 수 있어, 수동으로 프로세스를 관리하는 번거로움을 줄여줍니다.

#note-box[에디터별 ACP 통합의 성숙도는 다릅니다. Zed와 JetBrains는 네이티브/빌트인 지원을 제공하여 설정이 간단하지만, VS Code와 Neovim은 별도 플러그인 설치가 필요합니다. 에디터 선택 시 ACP 지원 수준도 함께 고려하세요.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 9. 샌드박스 + ACP 통합

마지막으로, 이 장의 두 주제를 하나로 결합합니다. 샌드박스와 ACP를 결합하면, 에디터에서 에이전트를 제어하면서 코드 실행은 격리된 환경에서 수행하는 _완전한 프로덕션 아키텍처_를 구현할 수 있습니다. 이것이 Deep Agents 기반 코딩 에이전트의 궁극적인 배포 형태입니다.

이 통합 아키텍처에서 각 컴포넌트의 역할은 명확하게 분리됩니다: _에디터_는 사용자 인터페이스, _에이전트_는 지능과 조율, _샌드박스_는 안전한 실행을 담당합니다. 세 컴포넌트가 각자의 역할에 집중하므로, 개별 컴포넌트를 독립적으로 업그레이드하거나 교체할 수 있습니다.

=== 통합 아키텍처

#code-block(`````python
[에디터/IDE] <-- ACP --> [에이전트] <-- API --> [샌드박스]
    |                       |                      |
  코드 편집              태스크 관리            코드 실행
  파일 탐색              컨텍스트 관리          파일 격리
  터미널 UI              도구 호출              보안 환경
`````)

=== 장점
- 에디터에서 직접 에이전트와 상호작용 — 개발자가 익숙한 도구를 떠나지 않아도 됩니다
- 코드 실행은 안전한 샌드박스에서 수행 — 호스트 시스템에 영향을 주지 않습니다
- 시크릿은 호스트(에이전트 측)에서만 관리 — API 키, 데이터베이스 자격 증명이 샌드박스에 노출되지 않습니다
- Human-in-the-Loop과 결합하면 민감한 작업에 대한 사람의 승인까지 추가할 수 있습니다

#warning-box[통합 아키텍처에서 ACP 서버와 샌드박스 프로바이더 모두에 장애가 발생할 수 있습니다. ACP 연결이 끊어지면 에디터에서 에이전트를 제어할 수 없고, 샌드박스가 중단되면 코드 실행이 불가능합니다. 프로덕션 환경에서는 양쪽 모두에 대한 오류 처리와 재연결 로직을 구현하세요.]

다음 코드는 샌드박스 백엔드와 ACP 서버를 결합한 완전한 구성 예시입니다.

#code-block(`````python
# 샌드박스 + ACP 통합 예시 (참고용)
integrated_config = """
from deepagents import create_deep_agent
from deepagents.backends.sandbox import ModalSandbox
from deepagents_acp import AgentServerACP
from langgraph.checkpoint.memory import MemorySaver

# 샌드박스 백엔드 + ACP 서버 통합
agent = create_deep_agent(
    model="gpt-4.1",
    system_prompt="당신은 코딩 어시스턴트입니다.",
    backend=ModalSandbox(image="python:3.12-slim"),
    checkpointer=MemorySaver(),
    interrupt_on={"execute": True},  # 코드 실행 전 승인
)

# ACP로 에디터와 연결
server = AgentServerACP(agent)
server.run()
"""

print("=== 샌드박스 + ACP 통합 예시 ===")
print(integrated_config)

print("이 구성의 효과:")
print("  1. 에디터에서 ACP를 통해 에이전트와 상호작용")
print("  2. 코드 실행은 Modal 샌드박스에서 안전하게 수행")
print("  3. execute 호출 시 Human-in-the-Loop 승인 필요")
`````)
#output-block(`````
=== 샌드박스 + ACP 통합 예시 ===

from deepagents import create_deep_agent
from deepagents.backends.sandbox import ModalSandbox
from deepagents_acp import AgentServerACP
from langgraph.checkpoint.memory import MemorySaver

# 샌드박스 백엔드 + ACP 서버 통합
agent = create_deep_agent(
    model="gpt-4.1",
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
  [Modal(GPU), Daytona(빠른 시작), Runloop(일회용)],
  [`ModalSandbox`],
  [보안],
  [시크릿 외부 관리, HITL, 네트워크 차단],
  [`interrupt_on`],
  [ACP 개요],
  [에디터-에이전트 통신 표준화],
  [`AgentServerACP`],
  [ACP 서버],
  [stdio 모드로 에이전트 노출],
  [`deepagents-acp`],
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
