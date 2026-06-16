// Auto-generated from 00_migration.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(0, "v0 → v1 마이그레이션 가이드")

LangChain/LangGraph v0에서 v1으로 전환할 때 알아야 할 브레이킹 체인지와 코드 매핑을 다룹니다.

== 학습 목표
#learning-objectives([v1 패키지 구조 변경과 import 경로를 이해한다], [`create_react_agent` → `create_agent` 마이그레이션을 수행한다], [미들웨어 기반 동적 프롬프트, 상태 관리, 컨텍스트 주입을 적용한다], [표준 콘텐츠 블록과 구조화된 출력 전략을 활용한다])

== 0.1 패키지 구조 변경

v1에서 `langchain` 네임스페이스가 에이전트 구축에 필요한 5개 핵심 모듈로 대폭 축소되었습니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[v1 모듈],
  text(weight: "bold")[역할],
  text(weight: "bold")[주요 API],
  [`langchain.agents`],
  [에이전트 생성과 상태 관리],
  [`create_agent`, `AgentState`],
  [`langchain.messages`],
  [메시지 타입과 콘텐츠 블록],
  [`HumanMessage`, `AIMessage`, `ToolMessage`, `content_blocks`],
  [`langchain.tools`],
  [도구 정의와 런타임 주입],
  [`\@tool`, `BaseTool`, `ToolRuntime`],
  [`langchain.chat_models`],
  [모델 초기화],
  [`init_chat_model`],
  [`langchain.embeddings`],
  [임베딩 유틸리티],
  [임베딩 모델 래퍼],
)

=== 레거시 코드 마이그레이션 — `langchain-classic`

기존에 `langchain` 패키지에서 쓰던 Chains, Retrievers, Hub, 인덱싱 API 등은 모두 `langchain-classic`이라는 별도 패키지로 분리되었습니다. 기존 코드를 유지해야 한다면 `pip install langchain-classic`으로 설치한 뒤 import 경로를 변경합니다:

#code-block(`````python
# v0 — 기존 방식
from langchain.chains import LLMChain
from langchain.retrievers import MultiQueryRetriever
from langchain import hub

# v1 — langchain-classic으로 이전
from langchain_classic.chains import LLMChain
from langchain_classic.retrievers import MultiQueryRetriever
from langchain_classic import hub
`````)

이 분리로 v1의 `langchain` 패키지는 에이전트 빌딩에만 집중하는 경량 구조가 되었고, 레거시 기능은 독립적으로 유지보수됩니다.

== 0.2 에이전트 생성 API 변경

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
from langchain.tools import tool
from langchain.agents import create_agent

model = ChatOpenAI(model="gpt-5.4")

@tool
def add(a: int, b: int) -> int:
    """두 수를 더합니다."""
    return a + b

# v0: from langgraph.prebuilt import create_react_agent
# v1: from langchain.agents import create_agent
agent = create_agent(
    model=model,
    tools=[add],
    system_prompt="당신은 수학 어시스턴트입니다.",  # v0: prompt=
)
print("\u2713 v1 에이전트 생성 완료")
`````)
#output-block(`````
✓ v1 에이전트 생성 완료
`````)

=== 주요 변경점

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[v0],
  text(weight: "bold")[v1],
  text(weight: "bold")[비고],
  [`from langgraph.prebuilt import create_react_agent`],
  [`from langchain.agents import create_agent`],
  [import 경로 + 함수명],
  [`prompt=`],
  [`system_prompt=`],
  [파라미터명],
  [`ToolNode` 지원],
  [미지원],
  [함수/BaseTool/dict만],
  [`pre_hooks`, `post_hooks`],
  [`middleware=[]`],
  [통합 미들웨어],
  [Pydantic/dataclass 상태],
  [`TypedDict` only],
  [상태 스키마],
)

== 0.3 상태 스키마 — TypedDict only

v1에서 커스텀 상태는 반드시 `TypedDict` 기반 `AgentState`를 상속해야 합니다.

== 0.4 런타임 컨텍스트 주입 (신규)

v1에서는 `context_schema`와 `context` 파라미터로 _불변 런타임 데이터_를 에이전트에 전달할 수 있습니다. 사용자 ID, 역할, 세션 정보처럼 요청마다 달라지지만 실행 중에는 변하지 않는 데이터를 에이전트와 도구에 안전하게 넘기는 패턴입니다.

_작동 방식:_
+ `@dataclass`로 컨텍스트 스키마를 정의합니다.
+ `create_agent(context_schema=...)`로 스키마를 등록합니다.
+ `agent.invoke(..., context=ContextInstance(...))`로 런타임에 값을 전달합니다.
+ 도구에서는 `ToolRuntime[ContextType]` 파라미터로 컨텍스트에 접근합니다.

컨텍스트는 에이전트 상태(`AgentState`)와 달리 도구 호출 간에 _변경되지 않는 읽기 전용 데이터_입니다. 상태는 에이전트 루프 중 업데이트되지만, 컨텍스트는 `invoke` 호출 시 고정됩니다.

== 0.5 동적 프롬프트 — 미들웨어 방식 (신규)

v0의 정적 프롬프트 대신, `@dynamic_prompt`로 런타임 컨텍스트에 따라 프롬프트를 동적으로 생성합니다.

== 0.6 도구 에러 처리 — `\@wrap_tool_call` (신규)

v0의 `handle_tool_errors` 대신, v1은 미들웨어로 도구 에러를 처리합니다.

#code-block(`````python
from langchain.agents.middleware import wrap_tool_call
from langchain.messages import ToolMessage

@wrap_tool_call
def handle_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(
            content=f"도구 오류: {e}",
            tool_call_id=request.tool_call["id"],
        )

agent = create_agent(
    model=model,
    tools=[add],
    middleware=[handle_errors],
)
print("\u2713 에러 핸들링 미들웨어 적용")
`````)
#output-block(`````
✓ 에러 핸들링 미들웨어 적용
`````)

=== 미들웨어 6단계 훅 한눈에 보기

v0의 `pre_hooks`/`post_hooks` 2단계가 v1에서는 6단계로 세분화되었습니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[훅],
  text(weight: "bold")[스타일],
  text(weight: "bold")[실행 시점],
  text(weight: "bold")[대표 용도],
  [`\@before_agent`],
  [node],
  [에이전트 실행 시작 1회],
  [초기화, 인증, 사용자 컨텍스트 로드],
  [`\@before_model`],
  [node],
  [매 모델 호출 직전],
  [메시지 가공, 로깅, 호출 횟수 카운팅],
  [`\@wrap_model_call`],
  [wrap],
  [모델 호출 감싸기],
  [재시도, 캐싱, `request.override(...)` 로 동적 구성],
  [`\@wrap_tool_call`],
  [wrap],
  [도구 호출 감싸기],
  [도구 재시도, 에러 변환, 감사 로그],
  [`\@after_model`],
  [node],
  [매 모델 응답 직후],
  [가드레일, 가공, `{"jump_to": "end"}` 점프],
  [`\@after_agent`],
  [node],
  [에이전트 실행 종료 1회],
  [정리, 메트릭 전송],
)

- _Node-style_ (`before_*`/`after_*`): 등록 순서대로 순차 실행. `after_*`는 역순.
- _Wrap-style_ (`wrap_*`): 핸들러 호출 여부를 0/1/N 회로 제어 → 재시도와 캐싱에 적합.

#code-block(`````python
from langchain.agents.middleware import wrap_model_call, ModelRequest, ModelResponse
from typing import Callable

@wrap_model_call
def cache_or_call(
    request: ModelRequest,
    handler: Callable[[ModelRequest], ModelResponse],
) -> ModelResponse:
    cached = lookup_cache(request.messages)
    if cached:
        return cached
    response = handler(request)
    store_cache(request.messages, response)
    return response
`````)

== 0.7 표준 콘텐츠 블록 & 구조화된 출력 (신규)

v1에서 메시지는 프로바이더 무관한 `content_blocks`를 지원합니다. 구조화된 출력은 두 가지 전략으로 분리되었습니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[전략],
  text(weight: "bold")[import],
  text(weight: "bold")[동작],
  text(weight: "bold")[적용 시점],
  [`ToolStrategy`],
  [`from langchain.agents.structured_output import ToolStrategy`],
  [인공 도구 호출로 스키마를 강제],
  [모든 프로바이더 호환],
  [`ProviderStrategy`],
  [`from langchain.agents.structured_output import ProviderStrategy`],
  [OpenAI/Anthropic 등 네이티브 structured output API 사용],
  [지원 모델 한정, 토큰 효율],
)

#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy
from pydantic import BaseModel

class Answer(BaseModel):
    summary: str
    confidence: float

agent = create_agent(
    model="gpt-5.4",
    tools=[],
    response_format=ToolStrategy(Answer),
)
`````)

OpenAI Responses API 사용 시 메시지 콘텐츠는 기본적으로 표준 블록 형식으로 직렬화됩니다. v0 동작이 필요하면 `ChatOpenAI(..., output_version="v0")`으로 명시합니다 (기본은 `"v1"`).

== 0.8 스트리밍 변경

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[v0],
  text(weight: "bold")[v1],
  [에이전트 노드명],
  [`"agent"`],
  [`"model"`],
  [`.text`],
  [메서드 `.text()`],
  [프로퍼티 `.text`],
)

== 0.9 기타 브레이킹 체인지

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[변경],
  text(weight: "bold")[설명],
  [_Python 3.10+_],
  [모든 LangChain 패키지가 Python 3.10 이상을 요구합니다. 3.9 이하는 미지원됩니다.],
  [_반환 타입_],
  [채팅 모델의 반환 타입이 `BaseMessage`에서 `AIMessage`로 고정되었습니다.],
  [_OpenAI Responses API_],
  [메시지 콘텐츠가 기본적으로 표준 블록 형식입니다. `output_version="v0"`으로 이전 동작을 복구할 수 있습니다.],
  [_Anthropic max_tokens_],
  [기본값이 1024에서 모델별 자동 설정으로 변경되었습니다.],
  [_AIMessage.example_],
  [`example` 파라미터가 제거되었습니다. `additional_kwargs`를 사용하세요.],
  [_AIMessageChunk_],
  [`chunk_position` 속성이 추가되었습니다 (마지막 청크에 `'last'` 값).],
  [**`.text` 프로퍼티**],
  [`.text()` 메서드가 `.text` 프로퍼티로 변경되었습니다.],
  [_파일 인코딩_],
  [파일이 기본적으로 UTF-8 인코딩으로 열립니다.],
)

== 요약 — 마이그레이션 체크리스트

- [ ] Python 3.10+ 확인
- [ ] `create_react_agent` → `create_agent` 변경
- [ ] `prompt=` → `system_prompt=` 변경
- [ ] 상태 스키마를 `TypedDict` 기반 `AgentState`로 전환
- [ ] `pre_hooks`/`post_hooks` → `middleware=[]`
- [ ] `ToolNode` → 함수/BaseTool로 교체
- [ ] `.text()` → `.text` 프로퍼티
- [ ] 스트리밍 노드명 `"agent"` → `"model"` 확인
- [ ] 레거시 import를 `langchain-classic`으로 이전
