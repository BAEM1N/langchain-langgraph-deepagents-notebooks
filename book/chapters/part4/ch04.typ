// Auto-generated from 04_backends.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "스토리지 백엔드")

에이전트가 파일을 읽고 쓰는 방식은 백엔드에 의해 결정된다. Deep Agents는 `StateBackend`, `FilesystemBackend`, `StoreBackend`, `CompositeBackend`, `LocalShellBackend` 등 다양한 플러거블 백엔드를 제공하여 에페메럴 스크래치패드부터 크로스 스레드 영속 저장소까지 유연하게 전환할 수 있다. 이 장에서는 각 백엔드의 특성과 선택 기준을 학습하고, `BackendProtocol`을 구현하여 커스텀 백엔드를 만드는 방법까지 다룬다.

3장에서 미들웨어가 에이전트 동작을 확장하는 방식을 살펴보았다. 그 중 `FilesystemMiddleware`가 제공하는 파일 도구(`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`)의 실제 저장소 계층이 바로 이 장에서 다루는 _백엔드_다. 백엔드를 교체하면 에이전트 코드는 한 줄도 바꾸지 않고 저장소 전략만 완전히 전환할 수 있다. 이 추상화는 소프트웨어 공학의 _의존성 역전 원칙(DIP)_을 적용한 것으로, 에이전트가 구체적인 저장소 구현이 아닌 `BackendProtocol` 인터페이스에 의존하도록 설계되어 있다. 덕분에 프로토타이핑 단계에서는 `StateBackend`로 빠르게 시작하고, 프로덕션 단계에서 `FilesystemBackend`나 `StoreBackend`로 전환하는 점진적 마이그레이션이 가능하다.

#learning-header()
#learning-objectives([백엔드가 에이전트의 파일 시스템을 어떻게 구현하는지 이해한다], [5가지 내장 백엔드의 특성과 사용 시나리오를 파악한다], [`CompositeBackend`로 경로별 백엔드 라우팅을 구성한다], [`BackendProtocol`을 구현하여 커스텀 백엔드를 만든다])

#code-block(`````python
# 환경 설정
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
print("환경 설정 완료")

from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")
`````)
#output-block(`````
환경 설정 완료
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 백엔드란?

Deep Agents의 빌트인 파일 도구(`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`)는
모두 _백엔드(Backend)_ 를 통해 동작합니다.

백엔드는 에이전트가 파일을 읽고 쓰는 _스토리지 계층_을 추상화합니다. 에이전트 입장에서는 "파일을 쓴다"는 동일한 명령을 내리지만, 그 뒤에서 실제로 메모리에 저장하는지, 디스크에 저장하는지, 원격 데이터베이스에 저장하는지는 백엔드 구현에 따라 달라집니다. 이 추상화 덕분에 에이전트의 시스템 프롬프트나 도구 호출 로직을 전혀 변경하지 않고도, `create_deep_agent()`의 `backend` 파라미터 한 줄만 바꿔서 저장소 전략을 완전히 전환할 수 있습니다.

#align(center)[#image("../../assets/diagrams/png/backend_abstraction.png", width: 84%, height: 120mm, fit: "contain")]

위 다이어그램에서 에이전트의 파일 도구와 백엔드 사이에 위치한 추상화 계층에 주목하세요. 에이전트는 항상 동일한 인터페이스(`read`, `write`, `ls` 등)를 호출하며, 실제 저장 방식은 백엔드가 결정합니다.

아래 표에서 각 백엔드의 저장 위치, 영속성, 사용 시나리오를 비교합니다. 자신의 프로젝트에 가장 적합한 백엔드를 선택하는 기준으로 활용하세요.

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
  [에이전트 상태 (메모리)],
  [스레드 내],
  [임시 작업, 스크래치패드 (기본값)],
  [`FilesystemBackend`],
  [로컬 디스크],
  [영구],
  [로컬 파일 접근, 코딩 에이전트],
  [`StoreBackend`],
  [LangGraph Store],
  [크로스 스레드],
  [장기 메모리, 사용자 선호도],
  [`CompositeBackend`],
  [경로별 라우팅],
  [혼합],
  [메모리 + 임시 파일 병용],
  [`LocalShellBackend`],
  [디스크 + 셸],
  [영구],
  [개발 환경 (보안 주의)],
)

#code-block(`````python
# 백엔드 임포트 확인
from deepagents.backends import (
    StateBackend,
    FilesystemBackend,
    StoreBackend,
    CompositeBackend,
)
from deepagents.backends.protocol import BackendProtocol

print("모든 백엔드 클래스를 성공적으로 임포트했습니다!")
`````)
#output-block(`````
모든 백엔드 클래스를 성공적으로 임포트했습니다!
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. StateBackend (기본값)

가장 단순한 백엔드부터 살펴봅니다. 각 백엔드를 하나씩 이해한 뒤, 후반부에서 이들을 조합하는 방법을 배울 것입니다.

`StateBackend`는 에이전트 상태(LangGraph state)에 파일을 딕셔너리 형태로 저장합니다. _에페메럴(ephemeral)_ 특성을 가지므로, 대화 스레드 내에서만 파일이 유지됩니다. 내부적으로는 LangGraph 상태의 `files` 키에 `{경로: 내용}` 형태의 딕셔너리로 파일을 관리합니다. 이 딕셔너리는 각 체크포인트에 포함되므로, 에이전트의 턴 간에는 데이터가 유지되지만 프로세스가 종료되면 소멸합니다.

=== 특징
- `create_deep_agent()`에서 `backend`를 지정하지 않으면 자동 사용 (기본값)
- 파일이 LangGraph 체크포인트에 포함되므로, 에이전트 턴 간에는 유지됨
- 프로세스가 종료되면 데이터가 소멸 -- 영속성이 필요 없는 임시 작업에 적합
- 외부 스토리지 불필요 -- 추가 설정 없이 바로 사용 가능

#tip-box[`StateBackend`는 프로토타이핑과 단기 작업에 이상적입니다. 에이전트에게 "보고서를 작성해서 파일로 저장해"라고 요청하면, 결과가 상태에 저장되어 같은 대화 내에서 다시 읽을 수 있습니다.]

#warning-box[`StateBackend`에 저장된 파일은 체크포인트에 포함되므로, 대량의 파일이나 큰 파일을 저장하면 체크포인트 크기가 급격히 증가합니다. 일반적으로 총 파일 크기가 1MB를 넘지 않도록 관리하는 것이 좋습니다. 대용량 데이터는 `FilesystemBackend`나 `StoreBackend`를 사용하세요.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. FilesystemBackend -- 로컬 디스크 접근

`StateBackend`의 에페메럴 특성이 부적합한 경우가 있습니다. 에이전트가 _실제 로컬 파일 시스템_에 접근해야 하는 시나리오가 대표적입니다. 코딩 에이전트가 프로젝트 소스 코드를 읽고 수정하거나, 데이터 분석 에이전트가 CSV 파일을 처리하는 경우에 `FilesystemBackend`를 사용합니다.

`FilesystemBackend`는 `DATA_DIR` 환경 변수 또는 `root_dir` 파라미터로 접근 가능한 루트 디렉토리를 설정할 수 있습니다. 이 루트 디렉토리 아래의 모든 파일과 디렉토리에 에이전트가 접근할 수 있으므로, 보안을 위해 접근 범위를 최소한으로 설정하는 것이 중요합니다.

=== 주요 옵션
- `root_dir` — 접근 가능한 루트 디렉토리 (기본: 현재 디렉토리)
- `virtual_mode=True` — 경로 제한 활성화 (`..`, `~` 등 차단)
- `max_file_size_mb` — 읽을 수 있는 최대 파일 크기

=== 보안 주의사항
#warning-box[`FilesystemBackend`는 에이전트에게 실제 파일 시스템 접근 권한을 부여합니다. `virtual_mode=True`를 설정하면 `..`, `~` 등의 경로 이스케이프를 차단하여 `root_dir` 범위 밖으로의 접근을 방지합니다. 프로덕션 환경에서는 반드시 `virtual_mode=True`를 사용하거나, 10장에서 다루는 샌드박스 백엔드를 고려하세요.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. StoreBackend -- 크로스 스레드 영속 저장소

`StateBackend`는 스레드 종료 시 소멸하고, `FilesystemBackend`는 로컬 파일에 직접 접근합니다. 그 중간 지점이 바로 `StoreBackend`입니다.

`StoreBackend`는 LangGraph의 `BaseStore` 인터페이스를 활용하여, _대화 스레드를 넘어서_ 파일을 영속적으로 저장합니다. 사용자 선호도, 학습된 패턴 등 장기 메모리에 적합합니다. 예를 들어, 사용자가 "나는 한국어로 응답해 줘"라고 한번 말하면, 그 선호도를 `StoreBackend`에 저장하여 이후 모든 대화에서 자동으로 적용할 수 있습니다.

=== 특징
- 다른 스레드에서도 같은 파일에 접근 가능 — 이전 대화에서 저장한 파일을 새 대화에서 읽을 수 있습니다
- Redis, PostgreSQL 등 다양한 스토어 구현 지원 — 프로덕션 환경에서는 `InMemoryStore` 대신 영속 스토어를 사용하세요
- LangSmith 배포 시 자동 프로비저닝
- `assistant_id` 기반 네임스페이스로 에이전트 간 격리 — 서로 다른 에이전트가 같은 스토어를 사용해도 데이터가 섞이지 않습니다

#tip-box[`StoreBackend`는 팩토리 패턴으로 전달해야 합니다. 에이전트 실행 시 `runtime` 객체가 주입되므로, `backend=lambda runtime: StoreBackend(runtime)` 형태로 지연 생성합니다. 이 패턴은 아래 코드 예제에서 확인할 수 있습니다.]

아래 코드는 `InMemoryStore`를 사용하여 개발 환경에서 `StoreBackend`를 시연합니다. 프로덕션에서는 `PostgresStore`나 `RedisStore`로 교체하여 영속성을 보장합니다. `store`와 `checkpointer`를 함께 전달하는 것이 `StoreBackend` 사용의 핵심 패턴입니다.

#code-block(`````python
from langgraph.store.memory import InMemoryStore
from langgraph.checkpoint.memory import MemorySaver

# InMemoryStore — 개발용 (프로덕션에서는 PostgresStore 등 사용)
store = InMemoryStore()
checkpointer = MemorySaver()

# StoreBackend를 사용하는 에이전트
# StoreBackend는 BackendFactory 형태로 전달해야 합니다
store_agent = create_deep_agent(
    model=model,
    system_prompt="당신은 메모를 관리하는 어시스턴트입니다. 한국어로 응답하세요.",
    backend=lambda runtime: StoreBackend(runtime),
    store=store,
    checkpointer=checkpointer,
)

print("StoreBackend 에이전트가 생성되었습니다!")
`````)
#output-block(`````
StoreBackend 에이전트가 생성되었습니다!
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. CompositeBackend -- 경로별 라우팅

지금까지 살펴본 `StateBackend`, `FilesystemBackend`, `StoreBackend`는 각각 장단점이 있습니다. 실제 에이전트에서는 이들을 _조합_해야 하는 경우가 대부분입니다. "임시 작업 파일은 에페메럴로, 장기 메모리는 영속으로" 같은 혼합 전략이 필요하기 때문입니다.

`CompositeBackend`는 경로 프리픽스에 따라 서로 다른 백엔드로 요청을 라우팅합니다. 가장 일반적인 패턴은 *`/memories/`는 영속 저장, 나머지는 에페메럴*입니다. 이 패턴은 에이전트가 작업 중 생성하는 임시 파일(초안, 중간 결과 등)은 세션이 끝나면 자동 정리되고, 중요한 학습 결과나 사용자 선호도는 영구 보존되도록 합니다.

#align(center)[#image("../../assets/diagrams/png/composite_backend.png", width: 82%, height: 132mm, fit: "contain")]

#code-block(`````python
# CompositeBackend 팩토리 함수
def create_composite_backend(runtime):
    """경로 기반 라우팅 백엔드 생성"""
    return CompositeBackend(
        default=StateBackend(runtime),           # 기본: 에페메럴
        routes={
            "/memories/": StoreBackend(runtime),  # /memories/* → 영속 저장
        },
    )


composite_store = InMemoryStore()
composite_checkpointer = MemorySaver()

composite_agent = create_deep_agent(
    model=model,
    system_prompt="""당신은 메모 관리 어시스턴트입니다.
- 영구 저장이 필요한 메모는 /memories/ 경로에 저장하세요.
- 임시 작업 파일은 루트(/) 경로에 저장하세요.
한국어로 응답하세요.""",
    backend=create_composite_backend,
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
== 6. LocalShellBackend -- 셸 실행

파일 읽기/쓰기를 넘어, 에이전트가 시스템 명령을 실행해야 하는 경우가 있습니다. 코딩 에이전트가 테스트를 실행하거나, 패키지를 설치하거나, Git 커밋을 수행하는 시나리오가 대표적입니다.

`LocalShellBackend`는 `FilesystemBackend`의 모든 파일 도구에 _셸 명령 실행 기능_(`execute` 도구)을 추가합니다. 에이전트가 `pip install`, `pytest`, `git` 등의 명령을 직접 실행할 수 있어, 개발 환경에서 코딩 에이전트를 구축할 때 유용합니다. 단, 이는 호스트 시스템에 직접 영향을 줄 수 있으므로 _보안에 각별히 주의_해야 합니다.

#warning-box[`LocalShellBackend`는 호스트 시스템에서 _사용자 권한으로 명령이 직접 실행_됩니다. 악의적이거나 잘못된 명령이 시스템에 영구적인 손상을 줄 수 있습니다. 개발 환경에서만 사용하고, 프로덕션에서는 반드시 10장에서 다루는 _샌드박스 백엔드_(Modal, Daytona, Runloop)를 사용하세요. `interrupt_on` 파라미터로 Human-in-the-Loop 승인을 추가하는 것을 강력히 권장합니다.]

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

5가지 내장 백엔드를 살펴보았습니다. 하지만 실무에서는 S3 버킷, 데이터베이스, 원격 API 등 내장 백엔드로 커버할 수 없는 저장소를 사용해야 하는 경우가 있습니다.

내장 백엔드가 요구사항에 맞지 않는 경우, `BackendProtocol`을 구현하여 나만의 백엔드를 만들 수 있습니다. `BackendProtocol`은 Python의 프로토콜(structural subtyping) 패턴을 사용하므로, 상속 없이 필요한 메서드만 구현하면 됩니다. 총 6개의 필수 메서드(`ls_info`, `read`, `write`, `edit`, `grep_raw`, `glob_info`)를 정의하면 에이전트의 모든 파일 도구가 자동으로 커스텀 백엔드를 통해 동작합니다.

아래 예제는 읽기 전용 딕셔너리 기반 백엔드를 구현합니다. 실제 프로덕션에서는 이 패턴을 확장하여 S3, GCS, 데이터베이스 등 다양한 저장소를 파일시스템처럼 추상화할 수 있습니다.

=== 필수 메서드

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[메서드],
  text(weight: "bold")[설명],
  [`ls_info(path)`],
  [디렉토리 내용 목록],
  [`read(file_path, offset, limit)`],
  [파일 읽기 (줄 번호 포함)],
  [`write(file_path, content)`],
  [새 파일 생성],
  [`edit(file_path, old_string, new_string)`],
  [텍스트 교체],
  [`grep_raw(pattern, path, glob)`],
  [패턴 기반 파일 내용 검색],
  [`glob_info(pattern, path)`],
  [글로브 패턴으로 파일 검색],
)

#code-block(`````python
# 간단한 커스텀 백엔드 예시: 읽기 전용 딕셔너리 기반
from deepagents.backends.protocol import FileInfo, GrepMatch, WriteResult, EditResult


class ReadOnlyDictBackend:
    """딕셔너리에 파일을 저장하는 읽기 전용 백엔드 예시"""

    def __init__(self, files: dict[str, str]):
        self._files = files

    def ls_info(self, path: str = "/") -> list[FileInfo]:
        return [
            {"path": p, "is_dir": False, "size": len(c), "modified_at": None}
            for p, c in self._files.items()
            if p.startswith(path)
        ]

    def read(self, file_path: str, offset: int = 0, limit: int = 2000) -> str:
        content = self._files.get(file_path, "")
        lines = content.splitlines()
        selected = lines[offset:offset + limit]
        return "\n".join(f"{i + offset + 1}\t{line}" for i, line in enumerate(selected))

    def write(self, file_path: str, content: str) -> WriteResult:
        return WriteResult(error="읽기 전용 백엔드입니다.", path=None, files_update=None)

    def edit(self, file_path: str, old_string: str, new_string: str, replace_all: bool = False) -> EditResult:
        return EditResult(error="읽기 전용 백엔드입니다.", path=None, files_update=None, occurrences=None)

    def grep_raw(self, pattern: str, path: str | None = None, glob: str | None = None) -> list[GrepMatch]:
        import re
        results = []
        for fpath, content in self._files.items():
            for i, line in enumerate(content.splitlines(), 1):
                if re.search(pattern, line):
                    results.append({"path": fpath, "line": i, "text": line})
        return results

    def glob_info(self, pattern: str, path: str = "/") -> list[FileInfo]:
        import fnmatch
        return [
            {"path": p, "is_dir": False, "size": len(c), "modified_at": None}
            for p, c in self._files.items()
            if fnmatch.fnmatch(p, pattern)
        ]


# 사용 예시
custom_backend = ReadOnlyDictBackend({
    "/docs/guide.md": "# 가이드\n이것은 가이드 문서입니다.\n## 설치 방법\npip install deepagents",
    "/docs/faq.md": "# FAQ\nQ: 지원하는 모델은?\nA: Anthropic, OpenAI 등 다양한 모델을 지원합니다.",
})

# 커스텀 백엔드 동작 확인
print("파일 목록:", custom_backend.ls_info("/"))
print()
print("파일 내용:")
print(custom_backend.read("/docs/guide.md"))
print()
print("검색 결과:", custom_backend.grep_raw("설치"))
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

아래 코드를 실행한 뒤, `ls_info`가 파일 목록을 반환하고 `read`가 줄 번호와 함께 내용을 출력하며 `grep_raw`가 패턴 검색 결과를 반환하는 것을 확인하세요. 이 세 가지가 동작하면 해당 백엔드는 `FilesystemMiddleware`의 모든 도구와 호환됩니다.

#tip-box[커스텀 백엔드를 구현할 때 가장 중요한 것은 `read` 메서드의 반환 형식입니다. 줄 번호와 탭으로 구분된 `"1\t내용"` 형태를 반환해야 에이전트가 `edit_file` 도구로 정확한 위치를 지정할 수 있습니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 백엔드 선택 가이드

어떤 백엔드를 선택해야 할지 결정할 때 아래 의사결정 트리를 참고하세요. 핵심 질문은 "데이터가 대화 세션을 넘어 유지되어야 하는가?"와 "에이전트가 로컬 파일 시스템에 접근해야 하는가?"입니다.

#align(center)[#image("../../assets/diagrams/png/backend_decision_tree.png", width: 96%, height: 140mm, fit: "contain")]

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
  [`root_dir`, `virtual_mode`],
  [`StoreBackend`],
  [크로스 스레드 영속],
  [`store` + `checkpointer` 필요],
  [`CompositeBackend`],
  [경로별 라우팅],
  [`default` + `routes`],
  [`LocalShellBackend`],
  [디스크 + 셸 실행],
  [`root_dir` (보안 주의)],
)

백엔드는 에이전트의 "기억 장치"입니다. `BackendProtocol`이라는 통일된 인터페이스 덕분에, 에이전트 코드를 변경하지 않고 `create_deep_agent()`의 `backend` 파라미터 한 줄만 수정하여 저장소 전략을 완전히 전환할 수 있습니다. 프로토타이핑 단계에서는 `StateBackend`로 빠르게 시작하고, 프로덕션에서는 `CompositeBackend`로 에페메럴과 영속 저장소를 조합하는 것이 가장 일반적인 패턴입니다. 다음 장에서는 에이전트의 컨텍스트 블로트 문제를 해결하는 _서브에이전트_ 패턴을 다룹니다.
