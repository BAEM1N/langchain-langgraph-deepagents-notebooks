// Auto-generated from 03_customization.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "에이전트 커스터마이징")

기본 에이전트를 만들었다면, 다음 단계는 목적에 맞게 세밀하게 조정하는 것이다. 이 장에서는 모델 선택, 시스템 프롬프트 작성, `docstring` 기반 커스텀 도구 정의, `response_format`을 활용한 Pydantic 구조화 출력, 그리고 미들웨어 아키텍처를 학습한다. 이 다섯 가지 커스터마이징 축을 이해하면 거의 모든 도메인에 맞는 에이전트를 설계할 수 있다.

2장에서 만든 기본 에이전트는 범용적이었다. 실무에서는 특정 도메인의 전문가 에이전트가 필요하다. 예를 들어 금융 분석 에이전트는 정형화된 보고서를 출력해야 하고, 코딩 에이전트는 특정 언어의 컨벤션을 따라야 한다. `create_deep_agent()`의 파라미터를 조합하면 모델 선택부터 출력 스키마까지 에이전트의 모든 측면을 제어할 수 있다. 이 장에서 다루는 다섯 가지 커스터마이징 축(모델, 시스템 프롬프트, 도구, 구조화된 출력, 미들웨어)은 실전 에이전트 개발의 기본 레시피다.

#learning-header()
#learning-objectives([다양한 LLM 프로바이더와 모델을 선택하는 방법을 익힌다], [효과적인 시스템 프롬프트를 작성한다], [docstring 기반 커스텀 도구를 만든다], [`response_format`으로 구조화된 출력(Pydantic)을 생성한다], [미들웨어 아키텍처를 이해한다])

#code-block(`````python
# 환경 설정
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("ANTHROPIC_API_KEY"), "ANTHROPIC_API_KEY가 설정되지 않았습니다!"
print("환경 설정 완료")

# 권장 기본 — Anthropic Claude Sonnet 4.6 (provider:model 포맷)
from deepagents import create_deep_agent

model = "anthropic:claude-sonnet-4-6"
print(f"기본 모델: {model}")
`````)
#output-block(`````
환경 설정 완료

기본 모델: anthropic:claude-sonnet-4-6
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 0. `create_deep_agent()` 전체 시그니처 (17 파라미터)

세부 커스터마이징에 들어가기 전, `create_deep_agent()`가 받는 _17개 파라미터_의 전체 시그니처를 한 번에 조감합니다. 이 모든 항목은 _선택적_이며, `model` 하나만으로도 에이전트가 작동합니다.

#code-block(`````python
def create_deep_agent(
    model=None,             # 1. LLM (ChatModel 객체 또는 "provider:model")
    tools=None,             # 2. 커스텀 도구 리스트
    system_prompt=None,     # 3. 사용자 시스템 프롬프트 (USER)
    middleware=(),          # 4. 추가 미들웨어 (사용자 정의)
    subagents=None,         # 5. SubAgent dict 리스트 / CompiledSubAgent
    skills=None,            # 6. SKILL.md 디렉터리 (progressive disclosure)
    memory=None,            # 7. AGENTS.md 경로 (항상 주입)
    response_format=None,   # 8. Pydantic 구조화 출력 스키마
    context_schema=None,    # 9. 런타임 컨텍스트 TypedDict (서브에이전트 전파)
    checkpointer=None,      # 10. LangGraph Checkpointer (지속성)
    store=None,             # 11. LangGraph BaseStore (StoreBackend용)
    cache=None,             # 12. 프롬프트 캐시 설정 (Anthropic 등)
    backend=None,           # 13. BackendProtocol 또는 lambda runtime: ...
    permissions=None,       # 14. allow_read/allow_write/deny_* ACL
    interrupt_on=None,      # 15. {"tool_name": True} HITL 게이트
    debug=False,            # 16. 디버그 로깅
    name=None,              # 17. 그래프 이름
):
    ...
`````)

#tip-box[`permissions`, `context_schema`, `cache`는 deepagents 최신 버전(`>=0.5.0`)에서 추가된 파라미터입니다. 구버전에서는 미들웨어로 직접 추가해야 합니다.]

=== 시스템 프롬프트 조립 순서

`system_prompt`에 전달한 텍스트는 _그대로_ 사용되지 않고, Deep Agents의 내부 프롬프트 빌더가 _세 부분_을 정해진 순서로 조립합니다.

#code-block(`````
[USER]    system_prompt (사용자가 전달한 문자열)
   ↓
[BASE]    하네스 BASE 프롬프트 (TodoList/Filesystem/SubAgent 사용법)
   + CUSTOM  미들웨어가 주입하는 도구 설명 (Memory · Skills · Permissions 등)
   ↓
[SUFFIX]  하네스 SUFFIX (안전 가이드, 출력 규약)
`````)

즉, _USER → BASE/CUSTOM → SUFFIX_ 순으로 결합됩니다. 사용자는 USER 부분만 채우면 되고, BASE/SUFFIX는 미들웨어가 자동으로 관리합니다. _덮어쓰지 않고 추가하는_ 구조이므로 빌트인 도구 사용법을 반복할 필요가 없습니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 모델 선택

커스터마이징의 첫 번째 축은 모델 선택입니다. 에이전트의 추론 능력, 도구 호출 정확도, 응답 품질은 모두 어떤 LLM을 사용하느냐에 크게 좌우됩니다.

Deep Agents는 _LangChain ChatModel 객체_ 또는 *`provider:model`* 포맷으로 다양한 LLM을 지원합니다. 이 유연성 덕분에 프로바이더 잠금(lock-in) 없이 프로젝트 요구사항에 가장 적합한 모델을 선택할 수 있습니다. 동일한 에이전트 코드를 유지하면서 모델만 교체하여 성능과 비용을 최적화하는 것도 가능합니다.

본 노트북에서는 _Anthropic Claude Sonnet 4.6_(`anthropic:claude-sonnet-4-6`)을 권장 기본 모델로 사용합니다. OpenAI 예제는 `gpt-5.4`를 사용합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[프로바이더],
  text(weight: "bold")[모델 예시 (provider:model)],
  text(weight: "bold")[환경 변수],
  text(weight: "bold")[비고],
  [_Anthropic_],
  [`anthropic:claude-sonnet-4-6`],
  [`ANTHROPIC_API_KEY`],
  [_권장 기본_ — 프롬프트 캐싱·HITL 최적],
  [OpenAI],
  [`openai:gpt-5.4`],
  [`OPENAI_API_KEY`],
  [도구 호출 정확도 ↑],
  [Google],
  [`google_genai:gemini-3.5-flash`],
  [`GOOGLE_API_KEY`],
  [비용 효율],
  [Azure],
  [`azure_openai:gpt-5.4`],
  [`AZURE_OPENAI_*`],
  [기업용 배포],
  [AWS Bedrock],
  [`bedrock:anthropic.claude-sonnet-4-6`],
  [AWS 자격 증명],
  [VPC 격리],
)

권장 기본 모델은 `anthropic:claude-sonnet-4-6`이며, 자동 재시도(기본 6회)와 타임아웃 처리가 내장되어 있습니다. `model` 파라미터는 LangChain `BaseChatModel` 객체 또는 `"provider:model-name"` 형태의 문자열을 모두 받습니다. 문자열로 전달하면 Deep Agents가 내부적으로 적절한 ChatModel 인스턴스를 생성합니다. ChatModel 객체를 직접 전달하면 `temperature`, `max_tokens` 등 세밀한 파라미터를 제어할 수 있으므로, 프로덕션 환경에서는 이 방식을 권장합니다.

#warning-box[모든 LLM이 도구 호출(function calling)을 동일한 수준으로 지원하는 것은 아닙니다. Deep Agents는 도구 호출에 크게 의존하므로, 도구 호출 성능이 검증된 모델(Claude Sonnet 4.5 이상, GPT-5 계열, Gemini 3.x 등)을 사용하는 것이 좋습니다. 도구 호출을 지원하지 않는 모델을 사용하면 빌트인 도구가 제대로 동작하지 않을 수 있습니다.]

아래 코드에서 `create_deep_agent()`에 `provider:model` 문자열을 전달하는 패턴을 확인하세요. 주석 처리된 부분은 다른 프로바이더를 사용하는 방법을 보여줍니다.

#code-block(`````python
# 권장 기본 — Anthropic Claude Sonnet 4.6 (provider:model 포맷)
agent_default = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
)

print(f"에이전트 생성 완료: {type(agent_default).__name__}")

# 참고: 다른 프로바이더를 사용하려면 해당 API 키를 설정하고 아래처럼 호출
# agent_openai = create_deep_agent(model="openai:gpt-5.4")
# agent_gemini = create_deep_agent(model="google_genai:gemini-3.5-flash")
# agent_bedrock = create_deep_agent(model="bedrock:anthropic.claude-sonnet-4-6")
`````)
#output-block(`````
에이전트 생성 완료: CompiledStateGraph
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 커스텀 시스템 프롬프트

모델을 선택했다면, 다음은 에이전트의 _행동 방식_을 정의하는 시스템 프롬프트입니다. 모델이 에이전트의 "두뇌"라면, 시스템 프롬프트는 "직무 기술서"에 해당합니다.

`system_prompt` 파라미터로 전달한 텍스트는 Deep Agents의 _내부 기본 프롬프트 위에 추가_됩니다. 기본 프롬프트에는 빌트인 도구 사용법, 태스크 관리 지침 등이 포함되어 있으므로, 개발자는 도메인 특화 지침(역할, 행동 규칙, 출력 형식 등)만 작성하면 됩니다. 기본 프롬프트를 _덮어쓰는 것이 아니라 추가하는 것_이므로, 빌트인 도구 사용법을 반복해서 작성할 필요가 없습니다.

#tip-box[시스템 프롬프트를 작성할 때는 _역할 정의_, _행동 규칙_, _출력 형식_ 세 가지를 명확히 분리하면 에이전트의 일관성이 높아집니다. 예를 들어: "당신은 금융 분석가입니다(역할). 모든 수치는 출처를 밝히세요(규칙). 분석 결과는 표 형식으로 정리하세요(형식)."]

#warning-box[시스템 프롬프트가 너무 길면 오히려 에이전트의 성능이 저하될 수 있습니다. 핵심 지침을 500 토큰 이내로 유지하고, 상세한 지식은 `memory`(AGENTS.md)나 `skills`(SKILL.md)로 분리하는 것이 효과적입니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 커스텀 도구 만들기

모델과 시스템 프롬프트가 에이전트의 "사고 방식"을 결정한다면, 커스텀 도구는 에이전트가 실제로 "할 수 있는 일"을 확장합니다. 빌트인 파일 도구 외에 외부 API 호출, 계산, 데이터베이스 조회 등 어떤 Python 함수든 도구로 등록할 수 있습니다.

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
== 4. 구조화된 출력 -- `response_format`

커스텀 도구로 에이전트의 _입력_ 능력을 확장했다면, 이제 _출력_ 형식을 제어할 차례입니다. 에이전트의 응답을 후속 파이프라인(데이터베이스 저장, API 응답, UI 렌더링 등)에서 사용하려면 자유 형식 텍스트보다 정형화된 구조가 훨씬 유리합니다.

`response_format`에 Pydantic `BaseModel`을 전달하면, 에이전트의 최종 응답이 해당 스키마에 맞춰 JSON 구조로 반환됩니다. 결과는 `result["structured_response"]`에서 접근할 수 있으며, 후속 파이프라인에서 _파싱 없이_ 바로 사용할 수 있습니다. Pydantic의 `Field(description=...)`을 활용하면 각 필드의 의미를 LLM에 전달할 수 있어, 출력 품질이 크게 향상됩니다.

#tip-box[`response_format`은 에이전트의 _최종 응답_에만 적용됩니다. 중간 도구 호출 결과에는 영향을 주지 않습니다. 에이전트는 여전히 자유롭게 도구를 호출하고 사고하며, _마지막 단계_에서만 지정된 스키마에 맞춰 응답을 구조화합니다.]

아래 예제에서 Pydantic 모델을 정의하는 방법과 `response_format`에 전달하는 패턴을 확인하세요. `Field`의 `description`이 LLM에게 각 필드에 어떤 값을 채워야 하는지 알려주는 역할을 한다는 점에 주목하세요.

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

지금까지 다룬 모델, 시스템 프롬프트, 도구, 출력 형식은 모두 `create_deep_agent()`의 표면적 파라미터입니다. 하지만 실제로 에이전트의 동작을 결정하는 것은 그 뒤에서 작동하는 _미들웨어 스택_입니다.

미들웨어는 에이전트의 메시지 처리 파이프라인에 삽입되는 플러그인으로, 도구 추가, 시스템 프롬프트 수정, 컨텍스트 압축 등을 담당합니다. 웹 서버의 미들웨어(인증, 로깅, CORS 등)와 유사한 개념이라고 이해할 수 있습니다. 각 미들웨어는 에이전트의 메시지가 LLM에 전달되기 전과 후에 개입하여 메시지를 변환하거나, 새로운 도구를 주입하거나, 컨텍스트를 압축합니다. 대부분의 미들웨어는 `create_deep_agent()`가 파라미터에 따라 자동으로 구성하므로, 개발자가 직접 다룰 필요는 거의 없습니다. 하지만 이 아키텍처를 이해하면 에이전트의 내부 동작을 정확히 파악하고, 필요할 때 커스텀 미들웨어를 작성할 수 있습니다.

=== 기본 미들웨어 스택 (실행 순서)

아래는 `create_deep_agent()`가 자동으로 조립하는 미들웨어 스택의 실행 순서입니다. 순서가 중요합니다. 예를 들어, `FilesystemMiddleware`가 파일 도구를 주입한 뒤에 `SubAgentMiddleware`가 서브에이전트 도구를 추가하므로, 서브에이전트는 파일 도구에 접근할 수 있습니다.

#code-block(`````python
1.  TodoListMiddleware                  — 태스크 관리 (write_todos 도구)
2.  MemoryMiddleware                    — AGENTS.md 로딩 (memory 파라미터 사용 시)
3.  SkillsMiddleware                    — SKILL.md 로딩 (skills 파라미터 사용 시)
4.  FilesystemMiddleware                — 파일 도구 (ls, read, write, edit, glob, grep)
5.  SubAgentMiddleware  [필수, 제거 불가]  — 서브에이전트 (task 도구)
6.  SummarizationMiddleware             — 컨텍스트 압축 (~85% 자동 요약)
7.  AnthropicPromptCachingMiddleware    — 프롬프트 캐싱 (Anthropic 모델 자동 적용)
8.  PatchToolCallsMiddleware            — 잘못된/누락된 도구 호출 보정
9.  [사용자 커스텀 미들웨어]                — middleware 파라미터
10. HumanInTheLoopMiddleware            — 승인 워크플로 (interrupt_on 사용 시)
`````)

#warning-box[`SubAgentMiddleware`는 `excluded_middleware`로 _제거할 수 없습니다_. `task` 도구는 Deep Agents의 핵심 위임 메커니즘이라 항상 활성화되며, 서브에이전트를 정의하지 않더라도 빌트인 `general-purpose` 서브에이전트가 자동으로 사용됩니다.]

각 미들웨어가 어떤 도구를 추가하고 어떤 역할을 하는지 아래 표에서 확인합니다. "(없음)"으로 표시된 미들웨어는 도구 대신 시스템 프롬프트 수정이나 메시지 변환을 수행합니다.

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
  [서브에이전트 생성 및 호출],
  [`SummarizationMiddleware`],
  [(없음)],
  [컨텍스트가 85%에 도달하면 자동 요약],
  [`MemoryMiddleware`],
  [(없음)],
  [AGENTS.md 파일을 시스템 프롬프트에 주입],
  [`SkillsMiddleware`],
  [(없음)],
  [관련 SKILL.md를 점진적으로 로드],
)

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

#tip-box[`SummarizationMiddleware`의 클래스 이름이 `_DeepAgentsSummarizationMiddleware`(언더스코어 프리픽스)인 이유는 내부 구현 세부사항이기 때문입니다. 직접 인스턴스화할 필요 없이 `create_deep_agent()`가 자동으로 관리합니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. 샌드박스 옵션

`tools` 파라미터로 직접 함수를 노출하는 것 외에도, Deep Agents는 _신뢰할 수 없는 코드 실행_을 안전하게 격리하는 _샌드박스_ 옵션을 제공합니다. 코딩 에이전트나 데이터 분석 에이전트가 임의의 스크립트를 실행해야 할 때 사용합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[샌드박스],
  text(weight: "bold")[실행 환경],
  text(weight: "bold")[적합 시나리오],
  [Modal],
  [원격 컨테이너 (GPU 지원)],
  [장기 실행 코드, GPU 추론],
  [Daytona],
  [원격 개발 컨테이너],
  [Git 워크스페이스 통합, 멀티 언어],
  [Deno],
  [로컬 TypeScript/JavaScript 격리],
  [경량 JS/TS 코드 실행],
  [로컬 VFS (Local Virtual FS)],
  [In-process 가상 파일시스템],
  [네트워크/디스크 없이 단위 테스트],
)

#tip-box[샌드박스는 _도구_로 노출되거나(예: `execute_python` 도구) _백엔드_로 노출됩니다(예: `SandboxBackend`로 파일 격리). 두 경로를 조합해 "파일 격리 + 코드 격리"를 동시에 달성할 수 있습니다. 자세한 사용법은 Part 4의 샌드박스 챕터를 참고하세요.]

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
  [`model="anthropic:claude-sonnet-4-6"` 등 provider 접두 형식],
  [시스템 프롬프트],
  [USER → BASE/CUSTOM → SUFFIX 순으로 조립됨],
  [커스텀 도구],
  [함수 + docstring + 타입 힌트 → `tools=[func]`],
  [구조화된 출력],
  [`response_format=PydanticModel` → `result["structured_response"]`],
  [미들웨어],
  [`SubAgentMiddleware`는 제거 불가. 나머지는 파라미터에 따라 자동 구성],
  [전체 파라미터],
  [17개 — `permissions`, `context_schema`, `checkpointer`, `store`, `cache`, `interrupt_on` 포함],
  [샌드박스],
  [Modal, Daytona, Deno, 로컬 VFS — 도구 또는 백엔드로 노출],
)

에이전트의 다섯 가지 커스터마이징 축(모델, 프롬프트, 도구, 출력 형식, 미들웨어)을 모두 살펴보았습니다. 이 다섯 가지 축은 `create_deep_agent()`의 파라미터에 1:1로 대응하므로, 필요한 파라미터만 조합하면 거의 모든 도메인의 전문가 에이전트를 설계할 수 있습니다. 다음 장에서는 에이전트의 파일 도구가 실제로 데이터를 읽고 쓰는 _스토리지 백엔드_ 계층을 심화합니다. 백엔드는 에이전트의 "기억 장치"로서, 에이전트 코드를 변경하지 않고도 저장소 전략을 완전히 전환할 수 있는 강력한 추상화를 제공합니다.

