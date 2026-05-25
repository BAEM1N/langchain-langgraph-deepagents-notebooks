// Auto-generated from 02_quickstart.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "첫 번째 에이전트 만들기")

에이전트를 직접 만들어 보는 것이 프레임워크를 이해하는 가장 빠른 방법이다. 이 장에서는 `create_deep_agent()` 함수를 사용하여 기본 에이전트를 생성하고, `invoke()`와 `stream()`으로 실행하는 전 과정을 실습한다. Tavily 검색 도구를 연동한 리서치 에이전트 예제를 통해 커스텀 도구 추가 방법까지 다룬다.

1장에서 살펴본 아키텍처를 코드로 옮기는 첫 단계다. `create_deep_agent()`가 반환하는 `CompiledStateGraph` 객체는 LangGraph의 표준 실행 인터페이스를 그대로 제공하므로, 기존 LangGraph 경험이 있다면 즉시 익숙하게 사용할 수 있다. `model` 파라미터 하나만 전달하면 나머지 인프라(빌트인 도구, 미들웨어 스택, 상태 스키마)가 합리적 기본값으로 자동 조립되므로, 최소한의 코드로 완전한 에이전트를 구동할 수 있다. 이후 `invoke`, `stream`, `batch` 등 LangGraph의 모든 실행 메서드를 그대로 활용한다.

#learning-header()
#learning-objectives([`.env` 파일에서 API 키를 로드하는 방법을 익힌다], [`create_deep_agent()`로 기본 에이전트를 생성한다], [`agent.invoke()`와 `agent.stream()`으로 에이전트를 실행한다], [Tavily 검색 도구를 연동하는 리서치 에이전트를 만든다], [빌트인 도구의 종류와 역할을 이해한다])

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 프로젝트 부트스트랩과 API 키 설정

에이전트를 만들기 전에 프로젝트와 API 키부터 설정합니다. Deep Agents 자체는 모델 무관(model-agnostic)이며, _권장 기본 모델_은 Anthropic `claude-sonnet-4-6`입니다. OpenAI(`gpt-5.4`), Google(`gemini-3.5-flash`), OpenRouter 등 다양한 프로바이더 중 환경에 맞는 것을 선택해 키를 발급받습니다. 리서치 에이전트 예제에서는 Tavily 검색 API도 사용합니다.

=== uv 기반 프로젝트 부트스트랩

권장하는 단계별 흐름은 다음과 같습니다. `uv`는 의존성 잠금과 가상환경을 자동으로 관리하므로 `pip`보다 재현성이 높습니다.

#code-block(`````bash
# 1) 프로젝트 초기화
uv init my-deepagent
cd my-deepagent

# 2) deepagents + 사용할 프로바이더 패키지 추가
uv add deepagents langchain-anthropic   # 권장 기본
# uv add deepagents langchain-openai
# uv add deepagents langchain-google-genai
uv add tavily-python python-dotenv

# 3) 잠금 파일 동기화
uv sync
`````)

=== 프로바이더별 API 키 분기

사용할 프로바이더에 따라 `.env`에 필요한 키를 채웁니다.

#code-block(`````bash
# Anthropic (권장 기본)
ANTHROPIC_API_KEY=your-key-here

# OpenAI
OPENAI_API_KEY=your-key-here

# Google Gemini
GOOGLE_API_KEY=your-key-here

# OpenRouter (OpenAI 호환)
OPENAI_API_KEY=your-openrouter-key
OPENAI_BASE_URL=https://openrouter.ai/api/v1

# 공통 — 리서치 예제에서 사용
TAVILY_API_KEY=your-key-here
`````)

#tip-box[`.env.example` 파일을 복사하여 `.env`로 만들면 됩니다. 모든 키를 다 설정할 필요는 없고, 자신이 사용할 프로바이더의 키만 채우면 됩니다.]

#code-block(`````python
# 환경 변수 로드
from dotenv import load_dotenv
import os

load_dotenv()

# 권장 기본 — Anthropic
assert os.environ.get("ANTHROPIC_API_KEY"), "ANTHROPIC_API_KEY가 설정되지 않았습니다!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY가 설정되지 않았습니다!"
print("API 키가 정상적으로 로드되었습니다.")
`````)
#output-block(`````
API 키가 정상적으로 로드되었습니다.
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 가장 간단한 에이전트 만들기

API 키가 준비되었으니, 이제 첫 번째 에이전트를 생성합니다.

`create_deep_agent()`는 Deep Agents의 유일한 진입점입니다. 이 함수는 내부적으로 `AgentHarness`를 통해 모델, 빌트인 도구, 미들웨어 스택, 상태 스키마를 조립한 뒤 `StateGraph`를 컴파일하여 반환합니다. `model` 파라미터만 전달하면 나머지는 합리적인 기본값으로 자동 구성됩니다. 이때 `model`이 _유일한 필수 파라미터_라는 점이 중요합니다. 어떤 LLM을 사용할지만 결정하면, 빌트인 도구(`write_todos`, `ls`, `read_file` 등), 컨텍스트 압축 미들웨어, 에페메럴 백엔드가 자동으로 포함됩니다.

아래 코드에서 `type(agent).__name__`이 `CompiledStateGraph`로 출력되는지 확인하세요. 이는 `create_deep_agent()`가 LangGraph의 표준 그래프 객체를 반환한다는 것을 의미하며, Part 3에서 배운 모든 실행 메서드를 그대로 사용할 수 있음을 뜻합니다.

#code-block(`````python
from deepagents import create_deep_agent

# 권장 기본 — Anthropic Claude Sonnet 4.6
# 문자열 한 줄로 provider:model 포맷 전달
agent = create_deep_agent(model="anthropic:claude-sonnet-4-6")

# (대안 1) OpenAI gpt-5.4
# agent = create_deep_agent(model="openai:gpt-5.4")

# (대안 2) Google Gemini 3.5 Flash
# agent = create_deep_agent(model="google_genai:gemini-3.5-flash")

# (대안 3) ChatModel 객체로 세밀 제어
# from langchain_anthropic import ChatAnthropic
# model = ChatAnthropic(model="claude-sonnet-4-6", temperature=0)
# agent = create_deep_agent(model=model)

print(f"에이전트 타입: {type(agent).__name__}")
print("에이전트가 성공적으로 생성되었습니다!")
`````)
#output-block(`````
에이전트 타입: CompiledStateGraph
에이전트가 성공적으로 생성되었습니다!
`````)

`create_deep_agent()`는 LangGraph의 `CompiledStateGraph`를 반환합니다.
따라서 LangGraph의 모든 실행 메서드(`invoke`, `stream`, `batch` 등)를 사용할 수 있습니다. 이것은 Deep Agents의 핵심 설계 철학을 반영합니다: _새로운 실행 인터페이스를 만들지 않고, 이미 검증된 LangGraph 위에서 동작합니다._ 기존 LangGraph 프로젝트에 Deep Agents를 점진적으로 도입할 수 있는 이유이기도 합니다.

#warning-box[`create_deep_agent()`에 `model`을 전달하지 않으면 기본 모델이 사용됩니다. 프로덕션 환경에서는 항상 명시적으로 모델을 지정하는 것이 좋습니다. 모델에 따라 도구 호출 성능, 토큰 한도, 비용이 크게 달라지므로, 용도에 맞는 모델을 선택하세요.]

#tip-box[`create_deep_agent()`는 한 번 호출하면 _불변(immutable)_ 그래프를 반환합니다. 에이전트 설정을 바꾸려면 새로 `create_deep_agent()`를 호출해야 합니다. 이 불변성 덕분에 같은 에이전트 객체를 여러 스레드에서 안전하게 공유할 수 있습니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 에이전트 실행 — `invoke()`

에이전트를 생성했으니 실제로 메시지를 보내서 실행해 봅니다. `invoke()`는 가장 기본적인 실행 방식으로, 에이전트가 모든 도구 호출을 완료하고 최종 응답을 생성할 때까지 _동기적으로 블로킹_합니다.

입력 형식은 LangGraph 표준인 `{"messages": [{"role": "user", "content": "..."}]}` 딕셔너리입니다. 반환값도 동일한 형식의 딕셔너리이며, `result["messages"][-1].content`로 최종 응답 텍스트에 접근할 수 있습니다. 에이전트가 도구를 호출한 경우, 중간 단계의 도구 호출 메시지와 도구 응답 메시지도 `messages` 리스트에 포함됩니다.

#tip-box[`invoke()`의 반환값에서 `result["messages"]`를 출력하면 에이전트의 전체 사고 과정(도구 호출 포함)을 확인할 수 있습니다. 디버깅할 때 매우 유용합니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Tavily 검색 도구 연동 -- 리서치 에이전트

`invoke()`로 기본 에이전트를 실행해 보았습니다. 하지만 기본 에이전트는 빌트인 파일 도구만 사용할 수 있어, 외부 정보를 가져올 수 없습니다. 실제 업무에서는 웹 검색, 데이터베이스 조회, API 호출 등 외부 도구가 필요합니다. `tools` 파라미터에 Python 함수 목록을 전달하면, Deep Agents가 자동으로 도구 스키마를 생성하여 LLM에 제공합니다.

여기서는 _Tavily_ 웹 검색 API를 도구로 연동하여 리서치 에이전트를 만듭니다. Tavily는 AI 에이전트에 최적화된 검색 API로, 웹 페이지의 핵심 내용을 구조화된 형태로 반환합니다.

=== 도구 정의 방법
Deep Agents(및 LangChain)는 Python 함수를 분석하여 도구 메타데이터를 자동 생성합니다. _함수 이름_이 도구 이름이 되고, _docstring_이 도구 설명(LLM이 도구 선택 시 참조)으로, _타입 힌트_가 파라미터 JSON Schema로 변환됩니다. 따라서 도구 함수를 작성할 때 docstring과 타입 힌트를 정확하게 기술하는 것이 매우 중요합니다. docstring이 부실하면 LLM이 언제 이 도구를 사용해야 하는지 판단하지 못하고, 타입 힌트가 없으면 파라미터 검증이 불가능합니다.

#warning-box[도구 함수의 _docstring_은 LLM이 도구를 선택하는 데 결정적인 역할을 합니다. "검색합니다"처럼 모호한 설명보다 "인터넷에서 최신 뉴스, 기술 문서, 학술 논문을 검색합니다"처럼 구체적으로 작성하세요. docstring이 없는 함수는 도구로 등록되지만, LLM이 올바르게 선택하지 못할 수 있습니다.]

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
    model="anthropic:claude-sonnet-4-6",
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

커스텀 도구를 추가하는 방법을 배웠으니, 이제 `create_deep_agent()`가 _별도 설정 없이 자동으로_ 추가하는 빌트인 도구들을 확인합니다. 이 도구들은 `FilesystemMiddleware`와 `TodoListMiddleware`가 주입하며, 에이전트가 파일 시스템을 탐색하고 태스크를 관리하는 데 필수적인 역할을 합니다:

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

#tip-box[이 도구들은 모두 _백엔드_(Backend)를 통해 동작합니다. 기본값은 `StateBackend`로, 에이전트 상태에 파일이 저장됩니다. 4장에서 백엔드를 교체하는 방법을 다룹니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. 스트리밍 출력 -- `stream()`

`invoke()`는 간단하지만, 장기 실행 에이전트의 경우 최종 결과만 기다리면 사용자 경험이 나빠집니다. 에이전트가 10개의 도구를 순차적으로 호출하는 동안 사용자는 아무런 피드백 없이 기다려야 하기 때문입니다.

`agent.stream()`을 사용하면 에이전트가 도구를 호출하고 응답을 생성하는 과정을 실시간으로 관찰할 수 있습니다. Deep Agents는 LangGraph의 스트리밍 인프라 위에서 동작하므로, `stream_mode`에 따라 다른 수준의 정보를 받을 수 있습니다:

- `"updates"` — 각 단계(노드) 완료 시 상태 업데이트를 반환합니다. 에이전트의 진행 상황을 단계별로 추적할 때 사용합니다.
- `"messages"` — LLM이 생성하는 개별 토큰을 실시간으로 스트리밍합니다. ChatGPT와 같은 실시간 타이핑 효과를 구현할 때 사용합니다.
- `"custom"` — 사용자 정의 이벤트를 수신합니다. 특정 도구 호출 결과를 UI에 실시간으로 반영하는 등 고급 사용 사례에 적합합니다.

#tip-box[프로덕션 환경에서는 `stream_mode="updates"`가 가장 실용적입니다. 각 도구 호출과 응답을 단계별로 추적할 수 있어, 사용자에게 "검색 중...", "분석 중...", "보고서 작성 중..." 같은 진행 상태를 표시할 수 있습니다.]

#note-box[`stream()`과 `invoke()`는 _입력 형식이 동일_합니다. 기존 `invoke()` 코드를 `stream()`으로 전환할 때 입력 부분은 변경할 필요가 없으며, 반환값 처리 방식만 이터레이터로 바꾸면 됩니다.]

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
  [모델 포맷],
  [Provider 접두 권장 — `"anthropic:claude-sonnet-4-6"`, `"openai:gpt-5.4"`, `"google_genai:gemini-3.5-flash"`. ChatModel 객체도 가능],
)

기본 에이전트의 생성과 실행을 마쳤습니다. 다음 장에서는 모델 선택, 시스템 프롬프트 작성, 구조화된 출력, 미들웨어 아키텍처 등 에이전트를 목적에 맞게 세밀하게 커스터마이징하는 방법을 다룹니다.

