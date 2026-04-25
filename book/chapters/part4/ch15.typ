// Source: docs/deepagents/16-permissions.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(15, "권한 관리", subtitle: "FilesystemPermission · first-match-wins")

Deep Agents의 built-in 파일시스템 도구(`ls`, `read_file`, `glob`, `grep`, `write_file`, `edit_file`)에 선언적 allow/deny 규칙을 적용해 _경로 기반 접근 제어_를 강제합니다. 프롬프트 인젝션 방어, 읽기 전용 에이전트, 특정 디렉터리만 허용하는 워크스페이스 격리를 구성할 때 이 장을 씁니다.

#learning-header()
#learning-objectives(
  [`FilesystemPermission`의 3요소(`operations`, `paths`, `mode`)를 이해한다],
  [first-match-wins 평가 규칙과 기본값(allow)을 안다],
  [읽기 전용·워크스페이스 격리·민감 파일 보호·read-only memory 4가지 패턴을 구분한다],
  [서브에이전트 permission 상속과 전면 대체 규칙을 인지한다],
  [permission이 닿지 않는 커스텀 도구·MCP·샌드박스 셸의 보완 전략을 안다],
)

== 15.1 적용 범위

`permissions`는 _built-in 파일시스템 도구에만_ 적용되는 경로 기반 규칙입니다. 다음은 우회됩니다:

- 커스텀 도구
- MCP 도구
- 샌드박스의 `execute` 셸 명령

보안 경계를 permission만으로 완성할 수 없습니다. 샌드박스에서 임의 셸 명령이 가능한 구성에서는 _CompositeBackend의 라우팅 제약_과 함께 설계해야 합니다. 커스텀 도구의 추가 검증·감사는 _backend policy hooks_가 담당합니다.

== 15.2 평가 규칙: first-match-wins

규칙은 리스트 순서대로 평가되고, `operations`와 `paths`가 현재 호출과 매치되는 _첫 번째 규칙_이 결과를 결정합니다. 어떤 규칙에도 매치되지 않으면 기본값은 *allow*입니다. 그러므로 _구체적인 deny/allow를 앞에_ 두고 일반적인 fallback을 뒤에 놓아야 합니다.

== 15.3 규칙 3요소

각 `FilesystemPermission`은 세 필드를 갖습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필드],
  text(weight: "bold")[값],
  text(weight: "bold")[설명],
  [`operations`],
  [`list["read" | "write"]`],
  [`read` = `ls` / `read_file` / `glob` / `grep`, `write` = `write_file` / `edit_file`],
  [`paths`],
  [`list[str]`],
  [글로브 패턴, `**` 재귀, `{a,b}` 선택자 지원],
  [`mode`],
  [`"allow" | "deny"`],
  [기본 `"allow"`],
)

== 15.4 패턴 1: 읽기 전용 에이전트

모든 쓰기를 전역 차단합니다. 조사·감사·리포트 생성 에이전트에 알맞습니다.

#code-block(`````python
from deepagents import create_deep_agent, FilesystemPermission

agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[
        FilesystemPermission(
            operations=["write"],
            paths=["/**"],
            mode="deny",
        ),
    ],
)
`````)

== 15.5 패턴 2: 워크스페이스 격리

`/workspace/` 아래만 허용하고 나머지는 전면 거부합니다. first-match-wins이므로 _allow를 먼저_, deny는 catch-all로 뒤에 둡니다.

#code-block(`````python
agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/workspace/**"],
            mode="allow",
        ),
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/**"],
            mode="deny",
        ),
    ],
)
`````)

== 15.6 패턴 3: 특정 파일만 보호

`/workspace/.env`와 예제 디렉터리는 건드리지 못하게 막고, 나머지 `/workspace/`는 자유롭게 허용합니다.

#code-block(`````python
agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[
        # 가장 구체적인 deny를 최상단에
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/workspace/.env", "/workspace/examples/**"],
            mode="deny",
        ),
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/workspace/**"],
            mode="allow",
        ),
        FilesystemPermission(
            operations=["read", "write"],
            paths=["/**"],
            mode="deny",
        ),
    ],
)
`````)

== 15.7 패턴 4: Read-only memory / policies

`/memories/`·`/policies/` 경로의 _쓰기만_ 막습니다. 읽기는 자유입니다. 공유 메모리와 조직 정책이 프롬프트 인젝션으로 오염되는 것을 막는 기본 방어선입니다.

#code-block(`````python
from deepagents import create_deep_agent, FilesystemPermission
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend

agent = create_deep_agent(
    model=model,
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(
                namespace=lambda rt: (rt.server_info.user.identity,),
            ),
            "/policies/": StoreBackend(
                namespace=lambda rt: (rt.context.org_id,),
            ),
        },
    ),
    permissions=[
        FilesystemPermission(
            operations=["write"],
            paths=["/memories/**", "/policies/**"],
            mode="deny",
        ),
    ],
)
`````)

메모리와 정책은 애플리케이션 코드로만 갱신하고, 에이전트는 읽기만 합니다.

== 15.8 Subagent 상속

기본 동작은 _부모 에이전트의 permissions가 서브에이전트에 그대로 상속_되는 것입니다. 서브에이전트 스펙에 `permissions`를 주면 _부모 규칙을 완전히 대체_합니다(부분 오버라이드 아님). 대체할 때는 catch-all deny까지 직접 넣어야 안전합니다.

#code-block(`````python
agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[...parent_rules...],
    subagents=[
        {
            "name": "auditor",
            "description": "읽기 전용 코드 리뷰어",
            "system_prompt": "Review the code for issues.",
            "permissions": [
                # 쓰기 전역 차단
                FilesystemPermission(
                    operations=["write"], paths=["/**"], mode="deny",
                ),
                # /workspace만 읽기 허용
                FilesystemPermission(
                    operations=["read"], paths=["/workspace/**"], mode="allow",
                ),
                # 나머지 읽기 차단
                FilesystemPermission(
                    operations=["read"], paths=["/**"], mode="deny",
                ),
            ],
        },
    ],
)
`````)

감사 전용 서브에이전트는 읽기 권한만 주고 메인 에이전트는 넓은 권한을 유지하는 식으로 분리할 수 있습니다.

== 15.9 CompositeBackend 제약: sandbox-default

`CompositeBackend`의 _default가 sandbox_일 때, 모든 permission path는 _선언된 route prefix 안에 있어야 합니다_. 샌드박스가 `execute` 도구로 임의 셸 명령을 돌릴 수 있기 때문입니다. 경로 기반 규칙은 셸 수준 파일 접근을 막지 못하므로, 라우팅 외부 경로에 permission을 다는 것은 _가짜 안전감_입니다.

#code-block(`````python
from deepagents import create_deep_agent, FilesystemPermission
from deepagents.backends import CompositeBackend

composite = CompositeBackend(
    default=sandbox,
    routes={"/memories/": memories_backend},
)

# 유효: /memories/ 라우트 안에 있음
agent = create_deep_agent(
    model=model,
    backend=composite,
    permissions=[
        FilesystemPermission(
            operations=["write"], paths=["/memories/**"], mode="deny",
        ),
    ],
)
`````)

알려진 route 바깥 경로에 규칙을 걸면 `NotImplementedError`가 발생합니다. 샌드박스 내부 파일시스템을 제어하려면 permission이 아니라 _샌드박스 구성 자체_(허용 바이너리, 네트워크 정책, 볼륨 마운트 범위)로 풀어야 합니다.

== 15.10 프롬프트 인젝션 방어 관점

공유 메모리, 조직 정책, 외부에서 주입되는 문서는 모두 인젝션 벡터입니다. 대응 계층은 다음과 같습니다.

+ *Read-only 강제*: `/memories/**`, `/policies/**`에 write deny (패턴 4)
+ *Workspace 격리*: 에이전트가 건드릴 수 있는 경로를 `/workspace/**`로 한정
+ *민감 파일 보호*: `.env` 류는 패턴 3처럼 개별 deny
+ *Subagent scope 축소*: 감사/조회 전용 서브에이전트는 read-only로 별도 구성
+ *커스텀 도구/샌드박스 경계*: permission이 닿지 않으므로 policy hook + 샌드박스 정책으로 보완

== 15.11 Permissions vs backend policy hooks

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[용도],
  text(weight: "bold")[사용 대상],
  [Built-in FS 도구의 경로 기반 allow/deny],
  [`permissions`],
  [커스텀 검증(데이터 유효성, 로깅, rate limit)],
  [backend policy hooks],
  [커스텀 도구 / MCP 도구 제어],
  [도구 자체 래퍼 / middleware],
  [샌드박스 내부 파일·네트워크 통제],
  [샌드박스 설정 (허용 바이너리·네트워크 정책)],
)

Permission은 _선언적 간이 규칙_, policy hook은 _로직이 필요한 통제_입니다. 역할을 나눠 씁니다.

== 15.12 주의사항

- *first-match-wins*: 규칙 순서가 결과를 바꿈. 더 구체적인 deny/allow를 위로
- *매치 실패 = allow*: 의도치 않게 허용되는 걸 막으려면 마지막에 catch-all deny를 두는 것이 안전
- *operations 누락*: 하나의 규칙에 `"read"`만 넣으면 쓰기는 별도 규칙이 없는 한 기본 허용
- *Subagent 오버라이드는 전면 대체*: 부분 수정 불가. 부모 규칙 중 유지할 것은 복사해 넣어야 함
- *Permission은 완전한 보안 경계가 아니다*: 샌드박스·네트워크·시크릿 관리와 함께 설계되어야 의미가 있음

== 핵심 정리

- `FilesystemPermission`의 3요소(`operations`/`paths`/`mode`)와 first-match-wins 평가 규칙이 기본
- 4가지 전형 패턴(읽기 전용 / 워크스페이스 격리 / 특정 파일 보호 / read-only memory) 조합으로 대부분 대응
- Subagent permission 오버라이드는 _전면 대체_이므로 catch-all deny 복사에 주의
- CompositeBackend + sandbox-default 구성에서는 route prefix 밖 permission이 `NotImplementedError`
- Permission은 _선언적 간이 규칙_이며 커스텀 도구·MCP·샌드박스 셸은 policy hook과 샌드박스 정책으로 보완
