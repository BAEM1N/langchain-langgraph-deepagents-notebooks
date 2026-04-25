// Source: 08_integration/11_provider_middleware/03_claude_text_editor.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Claude Text Editor", subtitle: "State vs Filesystem 변형")

Claude 네이티브 `text_editor_20250728` 도구는 `view` / `create` / `str_replace` / `insert` / `delete` / `rename` 6가지 오퍼레이션을 지원합니다. LangChain은 이 도구를 두 변형으로 래핑한 미들웨어를 제공합니다 — _State 변형_은 LangGraph 상태 안의 가상 파일로, _Filesystem 변형_은 실제 디렉터리에 쓰기를 수행합니다. 산출물의 수명이 스레드 내에서 끝나는지, 디스크에 남아야 하는지로 선택합니다.

#learning-header()
#learning-objectives(
  [Claude 네이티브 text editor의 6가지 오퍼레이션을 사용한다],
  [State 변형과 Filesystem 변형의 수명·공유 범위 차이를 구분한다],
  [`allowed_path_prefixes` / `allowed_prefixes`로 접근 경로를 제한한다],
  [`root_path`, `max_file_size_mb`로 디스크 변형의 경계를 설정한다],
)

== 4.1 언제 쓰나

- 코드/문서 편집을 모델이 _멀티스텝_으로 수행해야 할 때 (diff를 한 번에 뽑기 어려운 큰 변경)
- 결과물이 _그래프 상태 안에서만 살아 있으면 되는 경우_: State 변형
- 결과물을 _실제 리포지터리/디렉터리에 남겨야 하는 경우_: Filesystem 변형
- 일반 `@tool`로 `read_file` / `write_file`을 짜는 대신 Claude가 학습해둔 도구 스키마를 재사용하고 싶을 때

== 4.2 환경 설정

필요 패키지: `langchain`, `langchain-anthropic`. `.env`에 `ANTHROPIC_API_KEY`.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import (
    StateClaudeTextEditorMiddleware,
    FilesystemClaudeTextEditorMiddleware,
)

load_dotenv()
`````)

== 4.3 State 변형 — 그래프 상태 안 가상 파일

`StateClaudeTextEditorMiddleware`는 파일 내용을 LangGraph 상태의 `text_editor_files` 키에 저장합니다. 디스크에 쓰지 않으므로 _스레드가 끝나면 사라지는_ 임시 작업에 적합합니다.

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        StateClaudeTextEditorMiddleware(
            allowed_path_prefixes=["/src"],  # 가상 경로 제한
        ),
    ],
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "/src/hello.py에 hello world를 써줘"}]},
)
print(result.get("text_editor_files"))
`````)

- `allowed_path_prefixes`: 접근 허용 가상 경로 접두사. 미지정 시 전체 허용

#tip-box[`allowed_path_prefixes` 밖 경로로 쓰려고 하면 도구가 에러를 반환하고, 모델은 그 에러를 읽은 뒤 허용 경로로 재시도합니다. 경로 제한은 _에이전트 자율성_과 _안전_의 타협점입니다.]

== 4.4 Filesystem 변형 — 실제 디스크

`FilesystemClaudeTextEditorMiddleware`는 실제 디렉터리를 루트로 삼아 파일을 읽고 씁니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[기본값],
  text(weight: "bold")[설명],
  [`root_path`],
  [(필수)],
  [파일 오퍼레이션의 실제 루트 디렉터리],
  [`allowed_prefixes`],
  [`["/"]`],
  [허용 가상 경로 접두사 (root_path 기준 상대 경로)],
  [`max_file_size_mb`],
  [`10`],
  [읽기/쓰기 허용 최대 파일 크기],
)

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        FilesystemClaudeTextEditorMiddleware(
            root_path="/tmp/editor-demo",
            allowed_prefixes=["/drafts", "/reports"],
            max_file_size_mb=5,
        ),
    ],
)
`````)

== 4.5 State vs Filesystem 선택 기준

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[축],
  text(weight: "bold")[State 변형],
  text(weight: "bold")[Filesystem 변형],
  [저장소],
  [LangGraph 상태 dict],
  [실제 디렉터리],
  [수명],
  [스레드와 함께 소멸],
  [영구 (디스크에 남음)],
  [체크포인터 호환],
  [상태에 포함 → 자동 저장],
  [경로만 저장, 파일은 별도 관리],
  [동시성],
  [스레드별 완전 격리],
  [같은 `root_path` 공유 시 충돌 가능],
  [적합한 용도],
  [임시 draft, 1회성 분석],
  [실제 코드베이스 수정, 보고서 산출물],
)

*규칙*: 결과물을 _스레드 종료 후에도 보존_해야 하면 Filesystem, 그렇지 않으면 State를 씁니다.

== 4.6 일반 파일 도구와의 관계

Deep Agents의 `FilesystemMiddleware`나 커스텀 `@tool`로 짠 `read_file` / `write_file`도 동일한 목적을 달성할 수 있습니다. 차이점은 _Claude가 이 도구를 학습 단계에서 이미 봤다_는 것 — 도구 스키마 토큰이 줄고 오류가 적습니다. Claude 전용 파이프라인이라면 이 미들웨어를 우선 쓰고, 멀티 프로바이더면 일반 파일 도구로 내리는 것이 기본 전략입니다.

== 핵심 정리

- Claude 네이티브 text editor는 tool schema 토큰을 거의 0으로 만들고 6가지 오퍼레이션을 지원
- 산출물 수명으로 State(스레드와 함께 소멸) vs Filesystem(디스크 영구 보존) 선택
- `allowed_path_prefixes` / `allowed_prefixes`로 접근 경계를 강제
- Filesystem 변형은 `max_file_size_mb`로 메모리 안전성 확보
