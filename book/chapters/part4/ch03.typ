// Auto-generated from 03_customization.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "에이전트 커스터마이징")

== 학습 목표
#learning-objectives([다양한 LLM 프로바이더와 모델을 선택하는 방법을 익힌다], [효과적인 시스템 프롬프트를 작성한다], [docstring 기반 커스텀 도구를 만든다], [`response_format`으로 구조화된 출력(Pydantic)을 생성한다], [미들웨어 아키텍처를 이해한다])

#code-block(`````python
# 환경 설정
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
print("환경 설정 완료")

# OpenAI gpt-5.4 모델 초기화 (Deep Agents 기본은 anthropic:claude-sonnet-4-6)
from deepagents import create_deep_agent
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")
print(f"기본 모델: {model.model_name}")
`````)
#output-block(`````
환경 설정 완료

기본 모델: gpt-4.1
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 모델 선택

Deep Agents는 _LangChain ChatModel 객체_ 또는 **`provider:model`** 포맷으로 다양한 LLM을 지원합니다.
모델을 지정하지 않으면 기본값은 `anthropic:claude-sonnet-4-6` 입니다.

본 노트북에서는 **OpenAI `gpt-5.4`** 를 기본 모델로 사용합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[프로바이더],
  text(weight: "bold")[모델 예시],
  text(weight: "bold")[환경 변수],
  text(weight: "bold")[비고],
  [_OpenAI_],
  [`openai:gpt-5.4`],
  [`OPENAI_API_KEY`],
  [_본 노트북 기본_],
  [Anthropic],
  [`anthropic:claude-sonnet-4-6`],
  [`ANTHROPIC_API_KEY`],
  [_Deep Agents 기본_],
  [Google],
  [`google_genai:gemini-3.5-flash`],
  [`GOOGLE_API_KEY`],
  [],
  [Azure],
  [`azure_openai:gpt-4o`],
  [`AZURE_OPENAI_*`],
  [엔터프라이즈],
  [AWS Bedrock],
  [`bedrock:anthropic.claude-sonnet-4-6`],
  [AWS 자격 증명],
  [],
  [OpenRouter],
  [`openrouter:anthropic/claude-sonnet-4-6`],
  [`OPENROUTER_API_KEY`],
  [100+ 모델],
)

자동 재시도(기본 6회), `max_retries`, `timeout` 파라미터가 내장되어 있어 네트워크 장애·rate limit·서버 에러를 견딥니다.

#code-block(`````python
# OpenAI gpt-5.4 모델 사용 (위에서 초기화한 model 객체)
agent_oai = create_deep_agent(
    model=model,
)

print(f"에이전트 생성 완료: {type(agent_oai).__name__}")

# 참고: 다른 프로바이더를 사용하려면 해당 API 키를 설정하고 아래처럼 호출
# agent_anthropic = create_deep_agent(model="anthropic:claude-sonnet-4-6")  # Deep Agents 기본
# agent_gemini = create_deep_agent(model="google_genai:gemini-3.5-flash")
# agent_openrouter = create_deep_agent(model="openrouter:anthropic/claude-sonnet-4-6")
`````)
#output-block(`````
에이전트 생성 완료: CompiledStateGraph
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 커스텀 시스템 프롬프트

시스템 프롬프트는 에이전트의 _역할, 행동 규칙, 출력 형식_을 정의합니다.
기본 프롬프트 위에 추가되므로, 도메인 특화 지침을 작성하면 됩니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 커스텀 도구 만들기

Python 함수를 도구로 변환하는 규칙:
+ _함수 이름_ → 도구 이름
+ _docstring_ → 도구 설명 (에이전트가 도구 선택 시 참조)
+ _타입 힌트_ → 파라미터 스키마 (자동 생성)
+ _기본값_ → 선택적 파라미터

#code-block(`````python
import math


def calculate_compound_interest(
    principal: float,
    annual_rate: float,
    years: int,
    compounds_per_year: int = 12,
) -> dict:
    """복리 이자를 계산합니다.

    Args:
        principal: 원금 (원)
        annual_rate: 연이율 (예: 0.05 = 5%)
        years: 투자 기간 (년)
        compounds_per_year: 연간 복리 횟수 (기본: 12 = 월복리)
    """
    amount = principal * (1 + annual_rate / compounds_per_year) ** (compounds_per_year * years)
    interest = amount - principal
    return {
        "원금": f"{principal:,.0f}원",
        "최종 금액": f"{amount:,.0f}원",
        "이자 수익": f"{interest:,.0f}원",
        "수익률": f"{(interest / principal) * 100:.2f}%",
    }


def convert_temperature(
    value: float,
    from_unit: str,
    to_unit: str,
) -> str:
    """온도 단위를 변환합니다.

    Args:
        value: 변환할 온도 값
        from_unit: 원래 단위 ('celsius', 'fahrenheit', 'kelvin')
        to_unit: 변환할 단위 ('celsius', 'fahrenheit', 'kelvin')
    """
    # 먼저 섭씨로 변환
    if from_unit == "fahrenheit":
        celsius = (value - 32) * 5 / 9
    elif from_unit == "kelvin":
        celsius = value - 273.15
    else:
        celsius = value

    # 목표 단위로 변환
    if to_unit == "fahrenheit":
        result = celsius * 9 / 5 + 32
    elif to_unit == "kelvin":
        result = celsius + 273.15
    else:
        result = celsius

    return f"{value} {from_unit} = {result:.2f} {to_unit}"


# 커스텀 도구를 사용하는 에이전트 생성
calculator_agent = create_deep_agent(
    model=model,
    tools=[calculate_compound_interest, convert_temperature],
    system_prompt="당신은 계산과 단위 변환을 도와주는 어시스턴트입니다. 항상 도구를 사용하여 정확한 계산을 수행하세요.",
)

print("계산 에이전트가 생성되었습니다!")
`````)
#output-block(`````
계산 에이전트가 생성되었습니다!
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 구조화된 출력 — `response_format`

에이전트의 최종 응답을 _Pydantic 모델_로 구조화할 수 있습니다.
프로그래밍으로 처리하기 쉬운 형태의 출력을 받을 수 있습니다.

#note-box[`create_deep_agent()` 풀 시그니처는 17개 파라미터를 받습니다 (참고용): `model`, `tools`, `system_prompt`, `middleware`, `subagents`, `skills`, `memory`, `permissions`, `backend`, `interrupt_on`, `response_format`, `context_schema`, `checkpointer`, `store`, `debug`, `name`, `cache`. `permissions` / `context_schema` / `checkpointer` / `store` / `cache` 는 17번 advanced 노트북과 13번 production 가이드에서 자세히 다룹니다.]

#code-block(`````python
from pydantic import BaseModel, Field


# 구조화된 출력 스키마 정의
class BookRecommendation(BaseModel):
    """도서 추천 결과"""
    title: str = Field(description="책 제목")
    author: str = Field(description="저자")
    reason: str = Field(description="추천 이유 (2~3문장)")
    difficulty: str = Field(description="난이도: 초급/중급/고급")


class BookRecommendationList(BaseModel):
    """도서 추천 목록"""
    topic: str = Field(description="추천 주제")
    books: list[BookRecommendation] = Field(description="추천 도서 목록")


# response_format을 사용하는 에이전트
book_agent = create_deep_agent(
    model=model,
    system_prompt="당신은 도서 추천 전문가입니다. 사용자의 관심 분야에 맞는 책을 추천합니다.",
    response_format=BookRecommendationList,
)

print("도서 추천 에이전트 생성 완료")
`````)
#output-block(`````
도서 추천 에이전트 생성 완료
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 미들웨어 아키텍처

`create_deep_agent()`는 내부적으로 _미들웨어 스택_을 구성합니다.
미들웨어는 에이전트의 동작을 확장하는 플러그인 레이어입니다.

=== 시스템 프롬프트 조립 순서

#code-block(`````python
USER (사용자가 넘긴 system_prompt)
  → BASE/CUSTOM (SDK 기본 또는 profile)
  → SUFFIX (모델별 튜닝)
`````)

호출자(USER)의 의도가 항상 프레임워크 가이드보다 앞에 옵니다.

=== 기본 미들웨어 스택 (실행 순서)

#code-block(`````python
1. TodoListMiddleware              — 태스크 관리 (write_todos 도구)
2. MemoryMiddleware                — AGENTS.md 로딩 (memory 파라미터 사용 시)
3. SkillsMiddleware                — SKILL.md 로딩 (skills 파라미터 사용 시)
4. FilesystemMiddleware            — 파일 도구 (ls, read, write, edit, glob, grep)
5. SubAgentMiddleware              — 서브에이전트 (task 도구, 동기 서브에이전트가 있으면 자동 부착)
6. SummarizationMiddleware         — 컨텍스트 압축
7. AnthropicPromptCachingMiddleware — 프롬프트 캐싱 (Anthropic 모델)
8. PatchToolCallsMiddleware        — 잘못된 도구 호출 보정
9. [사용자 커스텀 미들웨어]           — middleware 파라미터
10. HumanInTheLoopMiddleware        — 승인 워크플로 (interrupt_on 사용 시)
`````)

=== 각 미들웨어의 역할

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[추가하는 도구],
  text(weight: "bold")[역할],
  [`TodoListMiddleware`],
  [`write_todos`],
  [구조화된 태스크 목록 관리],
  [`FilesystemMiddleware`],
  [`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`],
  [파일 시스템 접근],
  [`SubAgentMiddleware`],
  [`task`],
  [서브에이전트 생성 및 호출 (제거 불가)],
  [`SummarizationMiddleware`],
  [(없음)],
  [컨텍스트가 한도에 도달하면 자동 요약],
  [`MemoryMiddleware`],
  [(없음)],
  [AGENTS.md 파일을 시스템 프롬프트에 주입],
  [`SkillsMiddleware`],
  [(없음)],
  [관련 SKILL.md를 점진적으로 로드],
)

#warning-box[_주의_: 그래프 state를 통해 값을 추적하세요. 미들웨어 객체의 변경 가능 속성을 직접 쓰면 동시 실행 시 race condition이 발생합니다.]

#code-block(`````python
# 미들웨어 임포트 확인
from deepagents.middleware import (
    FilesystemMiddleware,
    MemoryMiddleware,
    SubAgentMiddleware,
    SkillsMiddleware,
    SummarizationMiddleware,
)

print("사용 가능한 미들웨어:")
for mw in [FilesystemMiddleware, MemoryMiddleware, SubAgentMiddleware, SkillsMiddleware, SummarizationMiddleware]:
    print(f"  - {mw.__name__}")
`````)
#output-block(`````
사용 가능한 미들웨어:
  - FilesystemMiddleware
  - MemoryMiddleware
  - SubAgentMiddleware
  - SkillsMiddleware
  - _DeepAgentsSummarizationMiddleware
`````)

#note-box[_참고_: 미들웨어는 `create_deep_agent()`가 자동으로 구성하므로, 대부분의 경우 직접 다룰 필요가 없습니다. 커스텀 미들웨어는 `middleware` 파라미터로 추가할 수 있으며, 고급 사용자를 위한 기능입니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 핵심 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[방법],
  [모델 선택],
  [`model="provider:model-name"` 또는 `ChatOpenAI(model="gpt-5.4")`],
  [Deep Agents 기본 모델],
  [`anthropic:claude-sonnet-4-6` (미지정 시)],
  [시스템 프롬프트],
  [`system_prompt="역할과 규칙을 정의"` (USER → BASE → SUFFIX 순으로 조립)],
  [커스텀 도구],
  [함수 + docstring + 타입 힌트 → `tools=[func]`],
  [구조화된 출력],
  [`response_format=PydanticModel` → `result["structured_response"]`],
  [미들웨어],
  [자동 구성 (TodoList, Filesystem, SubAgent, Summarization, ...)],
  [풀 시그니처],
  [17개 파라미터 (model, tools, system_prompt, middleware, subagents, skills, memory, permissions, backend, interrupt_on, response_format, context_schema, checkpointer, store, debug, name, cache)],
)
