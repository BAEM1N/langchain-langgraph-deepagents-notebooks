# Permissions

> Deep Agents의 built-in 파일시스템 도구(`ls`, `read_file`, `glob`, `grep`, `write_file`, `edit_file`)에 선언적 allow/deny 규칙을 적용해 경로 기반 접근 제어를 강제한다.
> 프롬프트 인젝션 방어, 읽기 전용 에이전트, 특정 디렉터리만 쓰게 하는 워크스페이스 격리를 구성할 때 읽는다.

## 개요

`permissions`는 **built-in 파일시스템 도구에만** 적용되는 경로 기반 규칙이다. 다음은 우회된다.

- 커스텀 도구
- MCP 도구
- 샌드박스의 `execute` 셸 명령

즉, 보안 경계를 permission만으로 완성할 수 없다. 샌드박스에서 임의 셸 명령이 가능한 구성에서는 **CompositeBackend의 라우팅 제약**과 함께 설계되어야 한다(아래 CompositeBackend 절 참고). 커스텀 도구에 대한 추가 검증·감사는 **backend policy hooks**가 담당한다.

## 평가 규칙: first-match-wins

규칙은 리스트 순서대로 평가되고, `operations`와 `paths`가 현재 호출과 매치되는 **첫 번째 규칙**이 결과를 결정한다. 어떤 규칙에도 매치되지 않으면 기본값은 **allow**.

이 때문에 **구체적인 deny/allow를 먼저 배치**하고, 일반적인 fallback을 뒤에 둬야 한다.

## 규칙 3요소

각 `FilesystemPermission`은 세 필드를 갖는다.

| 필드 | 값 | 설명 |
|------|----|------|
| `operations` | `list["read" \| "write"]` | `read` = `ls` / `read_file` / `glob` / `grep`, `write` = `write_file` / `edit_file` |
| `paths` | `list[str]` | 글로브 패턴, `**` 재귀, `{a,b}` 선택자 지원 |
| `mode` | `"allow" \| "deny"` | 기본 `"allow"` |

## 패턴 1: 읽기 전용 에이전트

모든 쓰기를 전역 차단. 조사·감사·리포트 생성 에이전트에 유용.

```python
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
```

## 패턴 2: 워크스페이스 격리

`/workspace/` 아래만 허용, 나머지 전면 거부. first-match-wins이므로 **allow가 먼저**, deny가 catch-all로 뒤에 온다.

```python
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
```

## 패턴 3: 특정 파일만 보호

`/workspace/.env`와 예제 디렉터리는 건드리지 못하게 하되 나머지 `/workspace/`는 자유롭게 허용.

```python
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
```

## 패턴 4: Read-only memory / policies

`/memories/`·`/policies/` 경로에 대한 **쓰기만** 막는다. 읽기는 자유. 공유 메모리·조직 정책이 프롬프트 인젝션으로 오염되는 것을 방지하는 기본 방어선이다.

```python
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
```

메모리/정책은 애플리케이션 코드로만 갱신하고 에이전트는 읽기만 하게 한다.

## Subagent 상속

기본 동작: **부모 에이전트의 permissions가 서브에이전트에 그대로 상속**된다.

서브에이전트 스펙에 `permissions`를 주면 **부모 규칙을 완전히 대체**한다(부분 오버라이드 아님). 대체할 때는 catch-all deny까지 직접 포함해야 안전하다.

```python
agent = create_deep_agent(
    model=model,
    backend=backend,
    permissions=[...parent rules...],
    subagents=[
        {
            "name": "auditor",
            "description": "읽기 전용 코드 리뷰어",
            "system_prompt": "Review the code for issues.",
            "permissions": [
                # 쓰기 전역 차단
                FilesystemPermission(
                    operations=["write"],
                    paths=["/**"],
                    mode="deny",
                ),
                # /workspace만 읽기 허용
                FilesystemPermission(
                    operations=["read"],
                    paths=["/workspace/**"],
                    mode="allow",
                ),
                # 나머지 읽기 차단
                FilesystemPermission(
                    operations=["read"],
                    paths=["/**"],
                    mode="deny",
                ),
            ],
        },
    ],
)
```

감사 전용 서브에이전트에 읽기 권한을 축소하고 메인 에이전트는 넓은 권한을 유지하는 식의 분리가 가능하다.

## CompositeBackend 제약: sandbox-default

`CompositeBackend`의 **default가 sandbox**일 때, 모든 permission path는 **선언된 route prefix 안에 있어야 한다**. 이 제약은 샌드박스가 `execute` 도구로 임의 셸 명령을 돌릴 수 있기 때문이다. 경로 기반 규칙은 셸 수준 파일 접근을 막지 못하므로, 라우팅 외부 경로에 permission을 다는 것은 **가짜 안전감**을 주는 구성이 된다.

```python
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
            operations=["write"],
            paths=["/memories/**"],
            mode="deny",
        ),
    ],
)
```

알려진 route 바깥 경로에 규칙을 걸면 `NotImplementedError`가 발생한다. 샌드박스 내부 파일시스템 제어가 필요하면 permission이 아니라 **샌드박스 구성 자체**(허용 바이너리, 네트워크 정책, 볼륨 마운트 범위)로 풀어야 한다.

## 프롬프트 인젝션 방어 관점

공유 메모리·조직 정책·외부에서 주입되는 문서는 전부 인젝션 벡터다. 대응 계층은 다음과 같다.

1. **Read-only 강제**: `/memories/**`, `/policies/**`에 write deny (위 패턴 4)
2. **Workspace 격리**: 에이전트가 건드릴 수 있는 경로를 `/workspace/**`로 한정
3. **민감 파일 보호**: `.env` 류는 패턴 3처럼 개별 deny
4. **Subagent scope 축소**: 감사/조회 전용 서브에이전트는 read-only로 별도 구성
5. **커스텀 도구/샌드박스 경계**: permission이 닿지 않으므로 policy hook + 샌드박스 정책으로 보완

## Permissions vs backend policy hooks

| 용도 | 사용 대상 |
|------|-----------|
| Built-in FS 도구의 경로 기반 allow/deny | `permissions` |
| 커스텀 검증(데이터 유효성, 로깅, rate limit) | backend policy hooks |
| 커스텀 도구 / MCP 도구 제어 | 도구 자체 래퍼 / middleware |
| 샌드박스 내부 파일·네트워크 통제 | 샌드박스 설정 (허용 바이너리·네트워크 정책) |

Permission은 **선언적 간이 규칙**, policy hook은 **로직이 필요한 통제**로 역할을 나눠 쓴다.

## 주의사항

- **first-match-wins**: 규칙 순서가 결과를 바꾼다. 더 구체적인 deny/allow를 위로.
- **매치 실패 = allow**: 의도치 않게 허용되는 걸 막으려면 마지막에 catch-all deny를 두는 것이 안전.
- **operations 누락**: 하나의 규칙에 `"read"`만 넣으면 쓰기는 별도 규칙이 없는 한 기본 허용이다.
- **Subagent 오버라이드는 전면 대체**: 부분 수정 불가. 부모 규칙 중 유지할 것은 복사해 넣어야 한다.
- **Permission은 완전한 보안 경계가 아니다**. 샌드박스·네트워크·시크릿 관리와 함께 설계되어야 의미가 있다.

## 관련 문서

- `06-backends.md` — 백엔드 종류와 `CompositeBackend` 라우팅
- `09-long-term-memory.md` — `/memories/` 스코프
- `11-sandboxes.md` — 샌드박스 경계
- `13-going-to-production.md` — 프로덕션에서의 인증/인가/공유 메모리 정책
- `14-context-engineering.md` — 공유 메모리를 통한 프롬프트 인젝션 맥락
