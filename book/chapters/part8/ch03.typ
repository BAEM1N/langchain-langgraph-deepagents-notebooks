// Source: 07_integration/11_provider_middleware/02_claude_bash_tool.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Claude Bash Tool", subtitle: "네이티브 bash_20250124 + 실행 정책")

`ClaudeBashToolMiddleware`는 Claude 모델에 Anthropic 네이티브 `bash_20250124` 도구를 주입합니다. 범용 `ShellToolMiddleware`와 달리 _Anthropic 서버가 bash 호출 스키마를 직접 관리_하므로 프롬프트가 간결하고 tool schema 토큰이 거의 0에 수렴합니다. 본 장에서는 3종 실행 정책(Host/Docker/CodexSandbox)의 트레이드오프를 비교하고, 민감정보 마스킹을 위한 `redaction_rules`까지 다룹니다.

#learning-header()
#learning-objectives(
  [`ClaudeBashToolMiddleware`의 4개 주요 파라미터를 이해한다],
  [`HostExecutionPolicy` / `DockerExecutionPolicy` / `CodexSandboxExecutionPolicy`의 격리 수준을 구분한다],
  [`RedactionRule`로 출력에서 토큰·키를 마스킹한다],
  [Claude 네이티브 bash와 범용 shell 도구의 차이를 안다],
)

== 3.1 언제 쓰나

- Claude에게 실제 쉘 명령을 실행시켜 코드 실행, 파일 조사, 빌드를 맡길 때
- Deep Agents처럼 장시간 작업 공간에서 세션 상태(cwd, 환경변수)를 유지해야 할 때
- 격리된 Docker 컨테이너에서 안전하게 임의 코드를 실행하고 싶을 때
- 쉘 출력에 API 키·자격증명이 섞일 가능성이 있어 출력 리다이렉션이 필요할 때

== 3.2 환경 설정

필요 패키지: `langchain`, `langchain-anthropic`. Docker 정책 예시를 실행하려면 로컬에 Docker 데몬이 떠 있어야 합니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import ClaudeBashToolMiddleware

load_dotenv()
`````)

== 3.3 호스트 실행 정책 (가장 단순)

`HostExecutionPolicy`는 로컬 프로세스에서 명령을 실행합니다. 빠르고 설정이 없지만 _격리가 없다_ — 네트워크, 파일시스템, 환경변수에 그대로 접근하므로 신뢰할 수 있는 스크립트나 로컬 개발 용도로만 씁니다.

#code-block(`````python
from langchain.agents.middleware import HostExecutionPolicy

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        ClaudeBashToolMiddleware(
            workspace_root="/tmp/work",
            startup_commands=["export PATH=$HOME/.local/bin:$PATH"],
            execution_policy=HostExecutionPolicy(),
        ),
    ],
)
`````)

- `workspace_root`: 쉘 세션의 기본 디렉터리
- `startup_commands`: 세션 시작 시 자동 실행되는 명령들 (PATH 설정, venv 활성화 등)

== 3.4 Docker 실행 정책 (권장, 격리)

`DockerExecutionPolicy`는 명령을 _컨테이너 안_에서 실행합니다. 호스트 파일시스템과 네트워크에서 완전히 분리되므로, 모델이 생성한 임의 코드를 실행할 때 사실상 기본값으로 둬야 합니다.

#code-block(`````python
from langchain.agents.middleware import DockerExecutionPolicy

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        ClaudeBashToolMiddleware(
            execution_policy=DockerExecutionPolicy(image="python:3.11"),
            startup_commands=["pip install requests numpy"],
        ),
    ],
)
`````)

컨테이너는 첫 bash 호출 시 생성되고 세션이 끝나면 정리됩니다. 패키지 요구가 있다면 `startup_commands`에 `pip install ...`을 넣습니다.

== 3.5 Codex 샌드박스 정책

`CodexSandboxExecutionPolicy`는 Anthropic이 제공하는 샌드박스 러너에서 실행합니다. 로컬 Docker 없이 격리를 얻고 싶을 때의 대안입니다. 네트워크 화이트리스트와 리소스 한도가 기본값으로 강하게 설정됩니다.

== 3.6 출력 리다이렉션 (`redaction_rules`)

쉘 출력에 API 키·토큰·이메일 같은 민감정보가 흘러나올 수 있습니다. `RedactionRule`을 리스트로 넘겨 도구 응답을 _에이전트 컨텍스트에 담기 전에_ 마스킹합니다. LangChain 1.2부터 `RedactionRule`은 `PIIMiddleware`와 동일한 `(pii_type, strategy, detector)` 시그니처를 사용합니다 — 과거 `pattern=` / `replacement=` 인자는 제거되었습니다.

#code-block(`````python
from langchain.agents.middleware import RedactionRule

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        ClaudeBashToolMiddleware(
            execution_policy=DockerExecutionPolicy(),
            redaction_rules=[
                RedactionRule(
                    pii_type="openai_api_key",
                    strategy="redact",
                    detector=r"sk-[a-zA-Z0-9]{32,}",
                ),
                RedactionRule(
                    pii_type="github_token",
                    strategy="redact",
                    detector=r"ghp_[a-zA-Z0-9]{36}",
                ),
            ],
        ),
    ],
)
`````)

== 3.7 네이티브 vs 범용 비교

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[`ClaudeBashToolMiddleware`],
  text(weight: "bold")[범용 `ShellToolMiddleware`],
  [도구 타입],
  [Anthropic 네이티브 `bash_20250124`],
  [일반 `@tool` 함수],
  [지원 모델],
  [Claude 전용],
  [모든 모델],
  [tool schema 토큰],
  [서버 측 → 거의 0],
  [매 턴 전송],
  [세션 상태],
  [cwd, env 누적 유지],
  [구현에 따라 다름],
  [실행 정책 API],
  [공유 (`HostExecutionPolicy` 등)],
  [공유],
)

*선택 기준*: Claude만 쓸 거면 네이티브가 싸고 깔끔합니다. 멀티 프로바이더 파이프라인이라면 범용 `ShellToolMiddleware`로 통일합니다.

== 핵심 정리

- Claude 네이티브 bash 도구는 tool schema 토큰을 거의 0으로 만든다
- 실행 정책은 Host(격리 없음) → Docker(권장) → CodexSandbox(Anthropic 관리) 세 층으로 선택
- `redaction_rules`로 도구 응답의 민감정보를 에이전트 컨텍스트 진입 전에 마스킹
- 멀티 프로바이더 파이프라인에서는 범용 `ShellToolMiddleware`로 통일하는 것이 안전
