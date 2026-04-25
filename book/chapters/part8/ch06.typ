// Source: 08_integration/11_provider_middleware/05_anthropic_file_search.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Anthropic File Search", subtitle: "가상 파일의 glob + grep")

`StateFileSearchMiddleware`는 그래프 상태 안에 들어 있는 가상 파일(예: `text_editor_files`, `memory_files`)을 _glob + grep_으로 검색할 수 있게 해 주는 Claude 네이티브 도구를 제공합니다. 텍스트 에디터/메모리 미들웨어가 "파일을 만들고 편집"한다면, 이 미들웨어는 그 위에서 "파일을 찾고 읽는" 역할을 담당합니다.

#learning-header()
#learning-objectives(
  [`StateFileSearchMiddleware(state_key=...)`로 검색 대상 저장소를 선택한다],
  [`StateClaudeTextEditorMiddleware`와 조합해 "쓰고 → 찾고 → 읽는" 루프를 완성한다],
  [`state_key="memory_files"`로 메모리 파일도 검색 대상으로 돌린다],
  [중복 미들웨어 제약과 서브클래싱 회피 패턴을 안다],
)

== 6.1 언제 쓰나

- 에이전트가 _수십~수백 개_의 가상 파일을 상태에 쌓아놓고 탐색해야 할 때
- 이름만 기억나는 파일을 패턴(`**/*.md`)으로 찾거나, 특정 키워드를 포함한 파일만 골라야 할 때
- 메모리에 쌓인 과거 노트를 모델이 스스로 grep 해서 참조하게 하고 싶을 때

== 6.2 환경 설정

필요 패키지: `langchain`, `langchain-anthropic`. `.env`에 `ANTHROPIC_API_KEY`.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import (
    StateClaudeTextEditorMiddleware,
    StateFileSearchMiddleware,
)

load_dotenv()
`````)

== 6.3 텍스트 에디터 + 파일 검색 조합

검색은 단독으로는 의미가 없습니다 — _파일이 먼저 상태에 있어야_ 합니다. 가장 흔한 조합은 text editor로 파일을 만들고 file search로 찾는 패턴입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[기본값],
  text(weight: "bold")[설명],
  [`state_key`],
  [`"text_editor_files"`],
  [검색할 파일 dict가 들어 있는 상태 키. `"memory_files"`로 바꾸면 메모리 쪽 검색],
)

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        StateClaudeTextEditorMiddleware(),
        StateFileSearchMiddleware(state_key="text_editor_files"),
    ],
)
`````)

== 6.4 1단계 — 여러 파일을 상태에 심는다

모델에게 몇 개의 노트 파일을 `/docs/` 아래에 만들어 달라고 요청합니다. 이후 검색 쿼리에서 이 파일들이 타깃이 됩니다.

#code-block(`````python
cfg = {"configurable": {"thread_id": "search-demo"}}
agent.invoke(
    {
        "messages": [
            {
                "role": "user",
                "content": (
                    "/docs/architecture.md, /docs/api.md, /docs/release-notes.md 세 파일을 "
                    "간단한 초안으로 만들어 줘."
                ),
            }
        ]
    },
    config=cfg,
)
`````)

== 6.5 2단계 — 같은 에이전트가 glob/grep으로 검색

동일 스레드에서 이어 호출하면 이전 파일들이 상태에 남아 있습니다. 모델은 `StateFileSearchMiddleware`가 제공하는 `glob`과 `grep` 도구로 파일을 찾고 내용을 읽습니다.

#code-block(`````python
result = agent.invoke(
    {
        "messages": [
            {
                "role": "user",
                "content": "/docs/ 아래 md 파일 중 'API'가 언급된 파일만 알려줘",
            }
        ]
    },
    config=cfg,
)
print(result["messages"][-1].content)
`````)

== 6.6 메모리 파일도 검색 대상으로

`state_key="memory_files"`로 바꾸면 `StateClaudeMemoryMiddleware`가 쌓아둔 메모를 검색할 수 있습니다.

#warning-box[*중복 미들웨어 제약* — LangChain 1.2 `create_agent`는 같은 미들웨어 클래스의 중복 인스턴스를 거부합니다(`AssertionError: Please remove duplicate middleware instances.`). 텍스트 에디터 파일과 메모리 파일 두 저장소를 동시에 검색하려면 한 번에 하나만 등록하거나, `StateFileSearchMiddleware`를 서브클래싱해 별도 클래스로 분리해야 합니다.]

#code-block(`````python
class MemoryFileSearchMiddleware(StateFileSearchMiddleware):
    """`memory_files` 전용 검색 미들웨어."""

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        StateClaudeTextEditorMiddleware(),
        StateClaudeMemoryMiddleware(),
        StateFileSearchMiddleware(state_key="text_editor_files"),
        MemoryFileSearchMiddleware(state_key="memory_files"),
    ],
)
`````)

== 6.7 vectorstore와의 선택 기준

- *정확한 파일명/패턴*이 중요하고, 의미 검색이 아닌 _리터럴 grep_이면 충분할 때
- 문서 수가 _수십~수백 개_ 수준이고 매 턴 임베딩을 다시 할 비용이 아까울 때
- 파일이 _현재 세션에서 방금 만들어진_ 것이라 벡터 인덱스가 없을 때

대규모 코퍼스나 의미 검색이 필요하면 Part VIII Chat Models/Vector Stores 영역(향후 확장)으로 넘어갑니다.

== 핵심 정리

- `StateFileSearchMiddleware`는 상태 안 가상 파일에 대해 glob + grep을 제공한다
- text editor + file search 조합이 "쓰고 → 찾고 → 읽는" 루프의 기본
- `state_key`를 바꿔 메모리 파일도 검색 대상으로 돌리되, 중복 미들웨어 제약은 서브클래싱으로 우회
- 리터럴 검색이 충분할 때는 벡터스토어보다 이 미들웨어가 저비용
