// Auto-generated from 04_backends.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "스토리지 백엔드")

== 학습 목표
#learning-objectives([백엔드가 에이전트의 파일 시스템을 어떻게 구현하는지 이해한다], [5가지 내장 백엔드의 특성과 사용 시나리오를 파악한다], [`CompositeBackend`로 경로별 백엔드 라우팅을 구성한다], [`BackendProtocol`을 구현하여 커스텀 백엔드를 만든다])

#code-block(`````python
# 환경 설정
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
print("환경 설정 완료")

from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")
`````)
#output-block(`````
환경 설정 완료
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 백엔드란?

Deep Agents의 빌트인 파일 도구(`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`)는
모두 _백엔드(Backend)_ 를 거쳐 동작합니다. `read_file`은 모든 백엔드에서 이미지 파일을 멀티모달 content로 반환합니다.

백엔드는 에이전트가 파일을 읽고 쓰는 _스토리지 계층_을 추상화합니다.

#image("../../assets/images/backend_abstraction.png")

=== 사용 가능한 백엔드

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[백엔드],
  text(weight: "bold")[저장 위치],
  text(weight: "bold")[영속성],
  text(weight: "bold")[사용 시나리오],
  [`StateBackend`],
  [에이전트 상태 (LangGraph state)],
  [스레드 내],
  [임시 작업, 스크래치패드 (기본값)],
  [`FilesystemBackend`],
  [로컬 디스크],
  [영구],
  [로컬 파일 접근, 코딩 에이전트],
  [`LocalShellBackend`],
  [디스크 + 셸 실행],
  [영구],
  [개발 환경 (보안 주의)],
  [`StoreBackend`],
  [LangGraph `BaseStore`],
  [크로스 스레드],
  [장기 메모리, 사용자 선호도],
  [`ContextHubBackend`],
  [LangSmith Hub 저장소],
  [영구],
  [공유 가능한 파일 트리, lazy fetch + write-through],
  [`CompositeBackend`],
  [경로별 라우팅],
  [혼합],
  [메모리 + 임시 파일 병용],
  [_샌드박스_],
  [Modal / Daytona / Deno / local VFS],
  [격리],
  [격리된 셸·파일 실행],
)

#tip-box[`deepagents>=0.5.2` 부터 백엔드는 _사전 생성된 인스턴스_가 권장됩니다. 옛 factory 패턴(`lambda runtime: ...`)은 deprecated 입니다. `StoreBackend(namespace=...)` 의 namespace callable은 LangGraph `Runtime` 객체를 받습니다.]

#code-block(`````python
# 백엔드 임포트 확인
from deepagents.backends import (
    StateBackend,
    FilesystemBackend,
    StoreBackend,
    CompositeBackend,
)

# ContextHubBackend는 langsmith-hub 통합이 필요 (선택적)
try:
    from deepagents.backends import ContextHubBackend
    print("ContextHubBackend 사용 가능")
except ImportError:
    print("ContextHubBackend는 LangSmith Hub 의존성이 필요합니다 (선택).")

from deepagents.backends.protocol import BackendProtocol

print("모든 백엔드 클래스를 성공적으로 임포트했습니다!")
`````)
#output-block(`````
모든 백엔드 클래스를 성공적으로 임포트했습니다!
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. StateBackend (기본값)

에이전트 상태(LangGraph state)에 파일을 저장합니다.
_에페메럴(ephemeral)_: 대화 스레드 내에서만 파일이 유지됩니다.

=== 특징
- `create_deep_agent()`에서 `backend`를 지정하지 않으면 자동 사용
- 파일이 체크포인트를 통해 에이전트 턴 간에는 유지됨
- 스레드가 종료되면 파일 소멸
- 외부 스토리지 없이 바로 사용 가능

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. FilesystemBackend — 로컬 디스크 접근

에이전트가 _실제 로컬 파일 시스템_에 접근할 수 있게 합니다.

=== 주요 옵션
- `root_dir` — 접근 가능한 루트 디렉토리 (기본: 현재 디렉토리)
- `virtual_mode=True` — 경로 제한 활성화 (`..`, `~`, _`root_dir` 밖의 절대 경로_를 모두 차단)
- `max_file_size_mb` — 읽을 수 있는 최대 파일 크기

=== ⚠️ 보안 주의사항
#tip-box[`FilesystemBackend`는 에이전트에게 실제 파일 시스템 접근 권한을 부여합니다. 에이전트가 `.env`, API 키, 자격 증명 같은 모든 접근 가능한 파일을 읽을 수 있고, 네트워크 도구와 결합되면 _SSRF 공격으로 시크릿이 유출될 수 있습니다_. 프로덕션 환경에서는 `virtual_mode=True`를 사용하거나 _샌드박스 백엔드_를 사용하세요.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. StoreBackend — 크로스 스레드 영속 저장소

LangGraph의 `BaseStore`를 활용하여 _대화 스레드를 넘어서_ 파일을 영속적으로 저장합니다.

=== 특징
- 다른 스레드에서도 같은 파일에 접근 가능 (Redis, PostgreSQL, 클라우드 구현 지원)
- LangSmith 배포 시 PostgreSQL 기반 store가 자동 프로비저닝
- `namespace` 콜러블로 멀티 유저 격리 — `deepagents>=0.5.2` 부터 LangGraph `Runtime` 객체를 받습니다
- 사전 생성된 `StoreBackend()` 인스턴스 사용을 권장 (옛 factory 패턴은 deprecated)

=== namespace 패턴

#code-block(`````python
# user-scoped
StoreBackend(namespace=lambda rt: (rt.context.user_id,))

# assistant-scoped (server 정보가 있을 때)
StoreBackend(namespace=lambda rt: (rt.server_info.assistant_id,))
`````)

#code-block(`````python
from langgraph.store.memory import InMemoryStore
from langgraph.checkpoint.memory import MemorySaver

# InMemoryStore — 개발용 (프로덕션에서는 PostgresStore 등 사용)
store = InMemoryStore()
checkpointer = MemorySaver()

# StoreBackend — 사전 생성 인스턴스 (deepagents>=0.5.2 권장 패턴)
# namespace 콜러블은 LangGraph Runtime 객체를 받음
store_backend = StoreBackend(
    namespace=lambda rt: ("demo-user",),  # 데모용 고정 namespace; 운영 시 rt.context.user_id 사용
)

store_agent = create_deep_agent(
    model=model,
    system_prompt="당신은 메모를 관리하는 어시스턴트입니다. 한국어로 응답하세요.",
    backend=store_backend,
    store=store,
    checkpointer=checkpointer,
)

print("StoreBackend 에이전트가 생성되었습니다!")
`````)
#output-block(`````
StoreBackend 에이전트가 생성되었습니다!
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. CompositeBackend — 경로별 라우팅

서로 다른 경로를 서로 다른 백엔드로 라우팅합니다.
가장 일반적인 패턴: _`/memories/*`는 영속 저장_, _나머지는 에페메럴_

#image("../../assets/images/composite_backend.png")

#code-block(`````python
# CompositeBackend — 사전 생성 인스턴스 사용 (deepagents>=0.5.2 권장)
composite_store = InMemoryStore()
composite_checkpointer = MemorySaver()

composite_backend = CompositeBackend(
    default=StateBackend(),
    routes={
        "/memories/": StoreBackend(
            namespace=lambda rt: ("composite-demo",),
        ),
    },
)

composite_agent = create_deep_agent(
    model=model,
    system_prompt="""당신은 메모 관리 어시스턴트입니다.
- 영구 저장이 필요한 메모는 /memories/ 경로에 저장하세요.
- 임시 작업 파일은 루트(/) 경로에 저장하세요.
한국어로 응답하세요.""",
    backend=composite_backend,
    store=composite_store,
    checkpointer=composite_checkpointer,
)

print("CompositeBackend 에이전트가 생성되었습니다!")
`````)
#output-block(`````
CompositeBackend 에이전트가 생성되었습니다!
`````)

#note-box[_참고_: `CompositeBackend`는 라우트 프리픽스를 제거한 후 저장합니다. 예: `/memories/preferences.txt` → 내부적으로 `/preferences.txt`로 저장 하지만 에이전트는 항상 전체 경로(`/memories/preferences.txt`)로 접근합니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. LocalShellBackend — 셸 실행

`LocalShellBackend`는 `FilesystemBackend`에 _셸 명령 실행 기능_(`execute` 도구)을 추가합니다.

=== ⚠️ 보안 경고
#note-box[호스트 시스템에서 _사용자 권한으로 `subprocess.run(shell=True)`_ 가 직접 실행됩니다. 샌드박스 없음, CPU/메모리/디스크 무제한, 비가역적입니다. 개발 환경에서만 사용하고, 공유 또는 프로덕션 시스템에서는 _샌드박스 백엔드_를 사용하세요.]

=== 정책 적용 방법

+ _권한 시스템_ — `permissions=[...]` 파라미터로 read/write 규칙을 선언적으로 정의
+ _정책 훅_ — 백엔드를 상속하거나 wrap (예: `GuardedBackend`가 특정 prefix 의 `write()`/`edit()` 거부)

#code-block(`````python
from deepagents.backends import LocalShellBackend

# ⚠️ 개발 환경에서만 사용하세요!
agent = create_deep_agent(
    model=model,
    backend=LocalShellBackend(root_dir="./workspace", virtual_mode=True),
    interrupt_on={"execute": True},  # 셸 명령은 승인 필요
)
`````)

#note-box[이 노트북에서는 안전상의 이유로 `LocalShellBackend`를 직접 실행하지 않습니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. 커스텀 백엔드 구현

`BackendProtocol`을 구현하면 나만의 백엔드를 만들 수 있습니다.

=== 필수 메서드 (deepagents\\>=0.5.2)

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[메서드],
  text(weight: "bold")[반환 타입],
  text(weight: "bold")[설명],
  [`ls(path)`],
  [`LsResult`],
  [디렉토리 내용 목록 (`path`, `is_dir`, `size`, `modified_at`, 정렬 결정적)],
  [`read(file_path, offset=0, limit=2000)`],
  [`ReadResult`],
  [파일 읽기. 없으면 `ReadResult(error=...)`],
  [`write(file_path, content)`],
  [`WriteResult`],
  [create-only. 충돌 시 `WriteResult(error=...)`. 외부 백엔드는 `files_update=None`],
  [`edit(file_path, old_string, new_string, replace_all=False)`],
  [`EditResult`],
  [`old_string`의 유일성 강제, 성공 시 `occurrences` 포함],
  [`grep(pattern, path=None, glob=None)`],
  [`GrepResult`],
  [결과 매치. 오류 시 raise 대신 `GrepResult(error=...)` 반환],
  [`glob(pattern, path="/")`],
  [`list[FileInfo]`],
  [글로브 매치, 비어 있으면 `[]`],
)

#warning-box[_버전 주의_: 이전 메서드명(`ls_info`, `grep_raw`, `glob_info`)은 deprecated. 0.5.2 이후로는 위 표의 이름으로 통일되었습니다.]

#code-block(`````python
# 간단한 커스텀 백엔드 예시: 읽기 전용 딕셔너리 기반
# deepagents>=0.5.2 BackendProtocol 메서드명 사용
from deepagents.backends.protocol import (
    FileInfo, LsResult, ReadResult, WriteResult, EditResult, GrepResult, GrepMatch,
)


class ReadOnlyDictBackend:
    """딕셔너리에 파일을 저장하는 읽기 전용 백엔드 예시"""

    def __init__(self, files: dict[str, str]):
        self._files = files

    def ls(self, path: str = "/") -> LsResult:
        entries = [
            FileInfo(path=p, is_dir=False, size=len(c), modified_at=None)
            for p, c in self._files.items()
            if p.startswith(path)
        ]
        return LsResult(entries=sorted(entries, key=lambda e: e.path))

    def read(self, file_path: str, offset: int = 0, limit: int = 2000) -> ReadResult:
        content = self._files.get(file_path)
        if content is None:
            return ReadResult(error=f"파일 없음: {file_path}")
        lines = content.splitlines()
        selected = lines[offset:offset + limit]
        text = "\n".join(f"{i + offset + 1}\t{line}" for i, line in enumerate(selected))
        return ReadResult(data=text)

    def write(self, file_path: str, content: str) -> WriteResult:
        return WriteResult(error="읽기 전용 백엔드입니다.")

    def edit(self, file_path: str, old_string: str, new_string: str, replace_all: bool = False) -> EditResult:
        return EditResult(error="읽기 전용 백엔드입니다.")

    def grep(self, pattern: str, path: str | None = None, glob: str | None = None) -> GrepResult:
        import re
        matches = []
        for fpath, content in self._files.items():
            for i, line in enumerate(content.splitlines(), 1):
                if re.search(pattern, line):
                    matches.append(GrepMatch(path=fpath, line=i, text=line))
        return GrepResult(matches=matches)

    def glob(self, pattern: str, path: str = "/") -> list[FileInfo]:
        import fnmatch
        return [
            FileInfo(path=p, is_dir=False, size=len(c), modified_at=None)
            for p, c in self._files.items()
            if fnmatch.fnmatch(p, pattern)
        ]


# 사용 예시
custom_backend = ReadOnlyDictBackend({
    "/docs/guide.md": "# 가이드\n이것은 가이드 문서입니다.\n## 설치 방법\npip install deepagents",
    "/docs/faq.md": "# FAQ\nQ: 지원하는 모델은?\nA: Anthropic, OpenAI 등 다양한 모델을 지원합니다.",
})

# 커스텀 백엔드 동작 확인
print("파일 목록:", custom_backend.ls("/"))
print()
print("파일 내용:")
print(custom_backend.read("/docs/guide.md"))
print()
print("검색 결과:", custom_backend.grep("설치"))
`````)
#output-block(`````
파일 목록: [{'path': '/docs/guide.md', 'is_dir': False, 'size': 52, 'modified_at': None}, {'path': '/docs/faq.md', 'is_dir': False, 'size': 56, 'modified_at': None}]

파일 내용:
1	# 가이드
2	이것은 가이드 문서입니다.
3	## 설치 방법
4	pip install deepagents

검색 결과: [{'path': '/docs/guide.md', 'line': 3, 'text': '## 설치 방법'}]
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 백엔드 선택 가이드

#image("../../assets/images/backend_decision_tree.png")

#line(length: 100%, stroke: 0.5pt + luma(200))
== 핵심 정리

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[백엔드],
  text(weight: "bold")[특징],
  text(weight: "bold")[파라미터],
  [`StateBackend`],
  [에페메럴, 기본값],
  [`backend` 생략 시 자동],
  [`FilesystemBackend`],
  [로컬 디스크],
  [`root_dir`, `virtual_mode` (`..`, `~`, root 밖 절대 경로 차단)],
  [`LocalShellBackend`],
  [디스크 + 셸 실행],
  [`root_dir` (보안 주의)],
  [`StoreBackend`],
  [크로스 스레드 영속],
  [`namespace` (LangGraph `Runtime` 수신) + `store` + `checkpointer`],
  [`ContextHubBackend`],
  [LangSmith Hub],
  [lazy fetch + write-through 캐시],
  [`CompositeBackend`],
  [경로별 라우팅],
  [`default` + `routes` (긴 prefix 우선)],
  [_샌드박스_],
  [격리된 실행],
  [Modal / Daytona / Deno / local VFS],
)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[`BackendProtocol` 메서드],
  text(weight: "bold")[반환 타입],
  [`ls`, `read`, `write`, `edit`, `grep`, `glob`],
  [`LsResult`, `ReadResult`, `WriteResult`, `EditResult`, `GrepResult`, `list[FileInfo]`],
)

`deepagents>=0.5.2` 기준 사전 생성된 백엔드 인스턴스가 권장됩니다.
