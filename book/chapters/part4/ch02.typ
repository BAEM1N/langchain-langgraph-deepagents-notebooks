// Auto-generated from 02_quickstart.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "첫 번째 에이전트 만들기")

== 학습 목표
#learning-objectives([`.env` 파일에서 API 키를 로드하는 방법을 익힌다], [`create_deep_agent()`로 기본 에이전트를 생성한다], [`agent.invoke()`와 `agent.stream()`으로 에이전트를 실행한다], [Tavily 검색 도구를 연동하는 리서치 에이전트를 만든다], [빌트인 도구의 종류와 역할을 이해한다])

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 설치 & API 키 설정

=== 설치

#code-block(`````bash
# uv 권장
uv init
uv add deepagents tavily-python langchain-openai
uv sync

# 또는 pip
pip install -qU deepagents tavily-python langchain-openai
`````)

`langchain-openai` 자리는 사용 모델 프로바이더로 바꿉니다 (`langchain-anthropic`, `langchain-google-genai`, `langchain-openrouter`).

=== API 키

`.env` 파일에 모델 프로바이더 키와 Tavily 키를 설정합니다. 본 노트북은 OpenAI를 기본으로 합니다.

#code-block(`````bash
# OpenAI (본 노트북 기본)
OPENAI_API_KEY=your-key

# 다른 프로바이더를 쓰면 추가
ANTHROPIC_API_KEY=your-key       # claude-sonnet-4-6
GOOGLE_API_KEY=your-key          # gemini-3.5-flash
OPENROUTER_API_KEY=your-key      # openrouter:anthropic/claude-sonnet-4-6

# 공통
TAVILY_API_KEY=your-key
`````)

#tip-box[`.env.example` 파일을 복사하여 `.env`로 만들면 됩니다.]

#code-block(`````python
# 환경 변수 로드
from dotenv import load_dotenv
import os

load_dotenv()

assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY가 설정되지 않았습니다!"
print("API 키가 정상적으로 로드되었습니다.")
`````)
#output-block(`````
API 키가 정상적으로 로드되었습니다.
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 가장 간단한 에이전트 만들기

`create_deep_agent()`는 Deep Agents의 핵심 함수입니다.
인자 없이 호출하면 기본 모델(`anthropic:claude-sonnet-4-6`)과 빌트인 도구가 자동으로 구성됩니다.

본 노트북은 OpenAI `gpt-5.4`를 사용합니다. 모델은 `ChatOpenAI` 객체로 넘기거나, `"provider:model-name"` 문자열로 전달할 수 있습니다.

#code-block(`````python
from deepagents import create_deep_agent
from langchain_openai import ChatOpenAI

# OpenAI gpt-5.4 모델 설정 (Deep Agents 기본은 anthropic:claude-sonnet-4-6)
model = ChatOpenAI(model="gpt-5.4")

# 기본 에이전트 생성
agent = create_deep_agent(model=model)

print(f"에이전트 타입: {type(agent).__name__}")
print("에이전트가 성공적으로 생성되었습니다!")
`````)
#output-block(`````
에이전트 타입: CompiledStateGraph
에이전트가 성공적으로 생성되었습니다!
`````)

`create_deep_agent()`는 LangGraph의 `CompiledStateGraph`를 반환합니다.
LangGraph의 모든 실행 메서드(`invoke`, `stream`, `batch` 등)를 그대로 쓸 수 있습니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 에이전트 실행 — `invoke()`

에이전트에 메시지를 전달하여 실행합니다.
입력 형식은 `{"messages": [{"role": "user", "content": "..."}]}` 딕셔너리입니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Tavily 검색 도구 연동 — 리서치 에이전트

커스텀 도구를 추가하면 에이전트의 기능을 확장할 수 있습니다.
여기서는 _Tavily_ 웹 검색 도구를 연동합니다.

=== 도구 정의 방법
Python 함수의 _docstring_이 도구 설명으로, _타입 힌트_가 파라미터 스키마로 변환됩니다.

#code-block(`````python
from typing import Literal
from tavily import TavilyClient

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])


def internet_search(
    query: str,
    max_results: int = 5,
    topic: Literal["general", "news", "finance"] = "general",
    include_raw_content: bool = False,
) -> dict:
    """인터넷에서 정보를 검색합니다.

    Args:
        query: 검색할 질문 또는 키워드
        max_results: 반환할 최대 결과 수
        topic: 검색 주제 카테고리
        include_raw_content: 원본 콘텐츠 포함 여부
    """
    return tavily_client.search(
        query,
        max_results=max_results,
        include_raw_content=include_raw_content,
        topic=topic,
    )


print(f"도구 이름: {internet_search.__name__}")
print(f"도구 설명: {internet_search.__doc__.strip().splitlines()[0]}")
`````)
#output-block(`````
도구 이름: internet_search
도구 설명: 인터넷에서 정보를 검색합니다.
`````)

#code-block(`````python
# 리서치 에이전트 생성 — 검색 도구 + 커스텀 시스템 프롬프트
research_agent = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="당신은 전문 리서처입니다. 사용자의 질문에 대해 인터넷 검색을 수행하고, 결과를 정리하여 한국어로 보고서를 작성합니다.",
)

print("리서치 에이전트가 생성되었습니다!")
`````)
#output-block(`````
리서치 에이전트가 생성되었습니다!
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 빌트인 도구 확인

`create_deep_agent()`가 자동으로 추가하는 빌트인 도구들입니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[설명],
  [`write_todos`],
  [구조화된 태스크 리스트 관리 (pending → in_progress → completed)],
  [`ls`],
  [디렉토리 내용 목록 (메타데이터 포함)],
  [`read_file`],
  [파일 읽기 (줄 번호 포함, 이미지 지원)],
  [`write_file`],
  [새 파일 생성],
  [`edit_file`],
  [파일 내 텍스트 교체 (`old_string` → `new_string`)],
  [`glob`],
  [패턴 기반 파일 검색 (예: `**/*.py`)],
  [`grep`],
  [파일 내용 검색 (정규식 지원)],
  [`task`],
  [서브에이전트 호출 (서브에이전트 설정 시 자동 추가)],
)

#tip-box[이 도구들은 모두 _백엔드_(Backend)를 통해 동작합니다. 기본값은 `StateBackend`로, 에이전트 상태에 파일이 저장됩니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. 스트리밍 출력 — `stream()`

`agent.stream()`을 사용하면 에이전트의 실행 과정을 실시간으로 볼 수 있습니다.
`stream_mode`에 따라 다른 수준의 정보를 받습니다:

- `"updates"` — 각 단계 완료 시 상태 업데이트
- `"messages"` — 개별 토큰 스트리밍
- `"custom"` — 사용자 정의 이벤트

#line(length: 100%, stroke: 0.5pt + luma(200))
== 핵심 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [에이전트 생성],
  [`create_deep_agent(model, tools, system_prompt)`],
  [동기 실행],
  [`agent.invoke({"messages": [...]})`],
  [스트리밍 실행],
  [`agent.stream({"messages": [...]}, stream_mode="updates")`],
  [커스텀 도구],
  [Python 함수 + docstring + 타입 힌트],
  [모델 객체],
  [`ChatOpenAI(model="gpt-5.4")` 또는 다른 프로바이더],
  [모델 문자열],
  [`provider:model-name` — `anthropic:claude-sonnet-4-6`, `openai:gpt-5.4`, `google_genai:gemini-3.5-flash`, `openrouter:anthropic/claude-sonnet-4-6`],
  [Deep Agents 기본],
  [`anthropic:claude-sonnet-4-6` (모델 미지정 시)],
)
