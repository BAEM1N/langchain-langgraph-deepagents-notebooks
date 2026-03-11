// Auto-generated from 01_middleware.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "미들웨어 시스템 심화", subtitle: "v1 최대 신기능")

미들웨어는 LangGraph v1에서 가장 주목할 만한 신기능으로, 에이전트 실행 루프의 각 단계에 모니터링, 변환, 거버넌스 로직을 비침습적으로 삽입할 수 있게 합니다. 이 장에서는 7가지 빌트인 미들웨어의 동작 원리를 파악하고, 데코레이터 및 클래스 기반으로 커스텀 미들웨어를 작성하는 방법을 심층적으로 다룹니다. 다중 미들웨어 조합 시 실행 순서 제어까지 익히면, 프로덕션 수준의 에이전트 파이프라인을 설계할 수 있습니다.

#learning-header()
#learning-objectives([에이전트 루프에서 미들웨어 훅의 역할과 실행 흐름을 이해한다], [7가지 빌트인 미들웨어의 설정과 실전 사용법을 익힌다], [데코레이터/클래스 기반 커스텀 미들웨어를 작성할 수 있다], [다중 미들웨어 조합 시 실행 순서를 정확히 예측할 수 있다])

== 1.1 환경 설정

웹 프레임워크(Express, Django 등)의 미들웨어가 HTTP 요청/응답 파이프라인에 로직을 삽입하듯, LangGraph v1의 미들웨어는 에이전트 실행 루프에 횡단 관심사(cross-cutting concerns)를 삽입합니다. 횡단 관심사란 로깅, 인증, 에러 처리, PII 마스킹처럼 여러 모듈에 걸쳐 공통으로 필요하지만, 핵심 비즈니스 로직과는 분리되어야 하는 기능을 말합니다.

미들웨어 없이 이러한 기능을 구현하면, 도구 함수마다 로깅 코드를 넣고, 에이전트 호출마다 에러 핸들링을 감싸야 합니다. 미들웨어를 사용하면 이 로직을 에이전트 코어 로직과 분리하여, _단일 책임 원칙_을 유지하면서도 강력한 프로덕션 파이프라인을 구성할 수 있습니다. `create_agent` 함수의 `middleware` 파라미터에 미들웨어 인스턴스 리스트를 전달하여 사용합니다.

다음 코드로 이 장에서 사용할 환경을 준비합니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-4.1")
`````)

환경 설정이 완료되었으므로, 미들웨어가 에이전트 루프의 어느 지점에 개입하는지 전체 아키텍처를 살펴보겠습니다.

== 1.2 미들웨어 아키텍처 개요

에이전트 루프는 _모델 호출 → 도구 선택 → 도구 실행 → 종료 판단_의 반복 사이클입니다. 이 사이클이 한 번 돌 때마다 에이전트는 사용자의 요청에 한 걸음 더 가까워집니다. 미들웨어는 이 사이클의 각 단계에 훅(hook)을 삽입하여 세밀한 제어를 가능하게 합니다. 훅은 특정 시점에 자동으로 호출되는 콜백 함수로, 개발자는 훅에 원하는 로직만 구현하면 됩니다.

=== 훅 유형

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[훅 유형],
  text(weight: "bold")[실행 시점],
  text(weight: "bold")[대표 용도],
  [`before_model`],
  [모델 호출 직전],
  [프롬프트 수정, 로깅, 상태 업데이트],
  [`after_model`],
  [모델 응답 직후],
  [응답 검증, 가드레일, 결과 변환],
  [`before_agent`],
  [에이전트 실행 시작 시],
  [초기화, 전처리],
  [`after_agent`],
  [에이전트 실행 종료 시],
  [정리, 후처리],
  [`wrap_model_call`],
  [모델 호출 감싸기],
  [재시도, 캐싱, 폴백],
  [`wrap_tool_call`],
  [도구 호출 감싸기],
  [도구 재시도, 감사 로그, 에러 핸들링],
)

=== 두 가지 훅 스타일

미들웨어 훅은 동작 방식에 따라 두 가지 스타일로 나뉩니다. 이 구분을 이해하는 것이 미들웨어 설계의 기초입니다.

- _Node-style 훅_ (`before_*`, `after_*`): 순차적으로 실행되며, 로깅/검증/상태 업데이트에 적합합니다. 파이프라인의 특정 지점에서 "관찰"하거나 "검증"하는 용도입니다.
- _Wrap-style 훅_ (`wrap_*`): 핸들러(`next_fn`) 호출 여부를 제어할 수 있습니다. 0회(차단), 1회(통과), 다회(재시도) 호출이 가능하여 재시도, 캐싱, 변환 로직에 적합합니다. Python의 데코레이터 패턴과 유사하게, 원래 함수를 감싸서 전후 처리를 추가합니다.

미들웨어는 에이전트의 핵심 로직을 변경하지 않고도 모니터링, 변환, 신뢰성, 거버넌스 등 횡단 관심사(cross-cutting concerns)를 깔끔하게 분리할 수 있게 해줍니다. 7가지 빌트인 미들웨어(`SummarizationMiddleware`, `HumanInTheLoopMiddleware`, `ModelCallLimitMiddleware`, `ToolCallLimitMiddleware`, `ModelFallbackMiddleware`, `PIIMiddleware`, `LLMToolSelectorMiddleware`)가 제공되며, 데코레이터 또는 클래스 기반으로 커스텀 미들웨어를 작성할 수도 있습니다.

#tip-box[빌트인 미들웨어는 프로덕션에서 반복적으로 필요한 패턴을 사전 구현한 것입니다. 커스텀 미들웨어를 작성하기 전에, 빌트인으로 해결 가능한지 먼저 확인하세요. 대부분의 프로덕션 요구사항은 빌트인의 조합만으로 충족됩니다.]

다음 코드는 미들웨어를 에이전트에 적용하는 기본 패턴을 보여줍니다. `middleware` 파라미터에 인스턴스 리스트를 전달합니다.

이제 각 빌트인 미들웨어를 하나씩 살펴보겠습니다. 먼저 장시간 대화에서 가장 빈번하게 필요한 `SummarizationMiddleware`부터 시작합니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.middleware import (
    SummarizationMiddleware,
    HumanInTheLoopMiddleware,
)

agent = create_agent(
    model="gpt-4.1", tools=[],
    middleware=[
        SummarizationMiddleware(model="gpt-4.1-mini", trigger=("messages", 50)),
        HumanInTheLoopMiddleware(interrupt_on={}),
    ],
)
`````)

== 1.3 SummarizationMiddleware

대화가 길어져 컨텍스트 윈도우를 초과할 때 자동으로 이전 대화를 요약하여 압축합니다. LLM의 컨텍스트 윈도우는 유한하므로, 수십 턴 이상의 대화에서는 오래된 메시지가 윈도우 밖으로 밀려나 맥락을 잃는 문제가 발생합니다. `SummarizationMiddleware`는 이 문제를 트리거 조건에 따라 자동으로 해결합니다.

장시간 실행되는 대화, 다중 턴 대화, 전체 대화 맥락 보존이 필요한 애플리케이션에 필수적입니다.

=== 주요 파라미터

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[설명],
  text(weight: "bold")[예시],
  [`model`],
  [요약 생성에 사용할 경량 모델 (비용 절감)],
  [`"gpt-4.1-mini"`],
  [`trigger`],
  [요약 트리거 조건],
  [`("tokens", 4000)`, `("messages", 50)`, `("fraction", 0.8)`],
  [`keep`],
  [요약 후 유지할 최근 컨텍스트],
  [`("messages", 20)`],
  [`token_counter`],
  [커스텀 토큰 카운팅 함수],
  [선택적],
  [`summary_prompt`],
  [커스텀 요약 프롬프트 템플릿],
  [선택적],
)

`trigger`는 토큰 수, 메시지 수, 윈도우 비율 중 하나를 기준으로 설정할 수 있으며, 조건에 도달하면 `keep`에 지정된 최근 메시지를 제외한 나머지를 요약문으로 교체합니다.

#tip-box[요약 모델로 `gpt-4.1-mini` 같은 경량 모델을 사용하면 비용을 절감할 수 있습니다. 요약의 목적은 핵심 맥락 보존이므로 메인 모델만큼의 추론 능력은 필요하지 않습니다.]

#code-block(`````python
from langchain.agents.middleware import SummarizationMiddleware

summarizer = SummarizationMiddleware(
    model="gpt-4.1-mini",
    trigger=("tokens", 4000),
    keep=("messages", 20),
)
`````)

대화 컨텍스트 관리와 더불어, 프로덕션 에이전트에서 빠질 수 없는 요소가 인간 감독입니다. 다음 미들웨어는 고위험 작업에 대한 인간 승인 게이트를 제공합니다.

== 1.4 HumanInTheLoopMiddleware

자율적으로 동작하는 에이전트가 위험한 작업을 수행하기 전에 "잠깐, 이거 해도 되나요?"라고 물어보는 메커니즘입니다. 고위험 도구 호출 전에 에이전트 실행을 중단하고 인간 승인을 기다립니다. 데이터베이스 쓰기, 금융 거래, 이메일 전송 등 고위험 작업이나 컴플라이언스 워크플로우에서 인간 감독이 필요한 경우에 사용합니다.

*`checkpointer` 필수* — 중단 후 상태를 복원하기 위해 체크포인터가 반드시 필요합니다. 체크포인터 없이 HITL을 사용하면 중단 시점의 상태가 유실되어, 승인 후 에이전트가 처음부터 다시 실행됩니다.

#warning-box[HITL 미들웨어는 에이전트 실행을 _완전히 중단_합니다. 웹 애플리케이션에서 사용할 때는 중단 상태를 클라이언트에 적절히 전달하고, 사용자 응답을 비동기로 처리하는 UI 설계가 필요합니다.]

=== 결정 유형

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[결정],
  text(weight: "bold")[설명],
  text(weight: "bold")[사용 방법],
  [`approve`],
  [도구 호출 승인 및 실행],
  [`Command(resume="approve")`],
  [`edit`],
  [도구 인자 수정 후 실행],
  [`Command(resume={"type": "edit", "args": {...}})`],
  [`reject`],
  [도구 호출 거부],
  [`Command(resume={"type": "reject", "reason": "..."})`],
)

`interrupt_on` 딕셔너리에서 각 도구별로 승인 정책을 설정합니다. `False`로 설정하면 해당 도구는 중단 없이 실행됩니다.

#code-block(`````python
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

hitl = HumanInTheLoopMiddleware(
    interrupt_on={
        "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},
        "read_email": False,
    }
)
`````)

#code-block(`````python
agent = create_agent(
    model="gpt-4.1", tools=[],
    checkpointer=InMemorySaver(),
    middleware=[hitl],
)
`````)

HITL이 인간의 판단을 에이전트 루프에 통합한다면, 다음 두 미들웨어는 에이전트의 _자원 소비_를 프로그래밍 방식으로 제한합니다. 에이전트가 무한 루프에 빠지거나 예상치 못한 고비용 경로를 탈 때 자동으로 제동을 거는 안전장치입니다.

== 1.5 ModelCallLimitMiddleware & ToolCallLimitMiddleware

에이전트가 복잡한 문제를 풀 때, 의도치 않게 무한 루프에 빠지거나 수백 번의 모델/도구 호출을 수행하여 예상치 못한 비용이 발생할 수 있습니다. 호출 제한 미들웨어는 이러한 상황에서 자동으로 제동을 거는 안전장치입니다.

=== ModelCallLimitMiddleware

에이전트가 모델을 호출하는 횟수를 제한합니다. 폭주하는 에이전트 방지, 프로덕션 비용 제어, 테스트 시 호출 예산 관리에 사용됩니다. `thread_limit`은 동일 스레드의 전체 생명주기에 걸친 제한이고, `run_limit`은 단일 `invoke()` 호출에 대한 제한입니다. 두 제한을 조합하면 세밀한 비용 관리가 가능합니다.

=== ToolCallLimitMiddleware

도구 호출 횟수를 전역적으로 또는 특정 도구별로 제한합니다. 비용이 높은 외부 API 호출 제한, 검색/DB 쿼리 빈도 제어, 특정 도구의 레이트 리밋 적용에 유용합니다.

=== 공통 파라미터

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[설명],
  [`thread_limit`],
  [전체 스레드(모든 invoke)에서의 최대 호출 수],
  [`run_limit`],
  [단일 invoke 실행에서의 최대 호출 수],
  [`exit_behavior`],
  [`"end"` (정상 종료), `"error"` (예외 발생), `"continue"` (에러 메시지와 함께 계속 — ToolCallLimit 전용)],
)

ToolCallLimitMiddleware는 추가로 `tool_name` 파라미터를 받아 특정 도구에만 제한을 적용할 수 있습니다. 예를 들어, 외부 API 호출 도구에는 엄격한 제한을, 로컬 계산 도구에는 느슨한 제한을 적용하는 차별화된 정책을 구현할 수 있습니다.

다음 코드들은 모델 호출 제한과 도구 호출 제한을 각각 설정하는 예시입니다.

#code-block(`````python
from langchain.agents.middleware import ModelCallLimitMiddleware

model_limit = ModelCallLimitMiddleware(
    thread_limit=10,
    run_limit=5,
    exit_behavior="end",
)
`````)

#code-block(`````python
from langchain.agents.middleware import ToolCallLimitMiddleware

# 전역 제한
global_tool_limit = ToolCallLimitMiddleware(thread_limit=20, run_limit=10)

# 특정 도구 제한
search_limit = ToolCallLimitMiddleware(
    tool_name="search",
    thread_limit=5, run_limit=3,
    exit_behavior="continue",
)
`````)

호출 제한은 비용과 안정성을 보호합니다. 그러나 모델 자체가 장애를 일으킬 수도 있습니다. 다음 미들웨어는 모델 레벨의 장애 복구를 자동화합니다.

#tip-box[개발/테스트 환경에서는 `run_limit`을 낮게 설정(예: 3~5)하여 의도치 않은 폭주를 빠르게 감지하세요. 프로덕션에서는 태스크 복잡도에 맞게 적절히 높여야 합니다.]

호출 제한으로 비용과 안정성을 보호했습니다. 그러나 모델 서비스 자체가 장애를 일으키는 경우도 대비해야 합니다. 다음 미들웨어는 모델 레벨의 장애 복구를 자동화합니다.

== 1.6 ModelFallbackMiddleware

주 모델 실패 시 대체 모델 체인으로 자동 전환합니다. 프로덕션 장애 대응, 비용 최적화(비싼 모델 → 저렴한 모델 폴백), 멀티 프로바이더 중복성(OpenAI + Anthropic 등) 확보에 유용합니다. 단일 프로바이더에 의존하면 해당 서비스 장애 시 전체 시스템이 중단되므로, 프로덕션 환경에서는 폴백 전략이 필수적입니다.

생성자에 폴백 모델을 순서대로 전달하면, 주 모델 호출이 실패할 때 지정된 순서로 대체 모델을 시도합니다. 모든 폴백이 실패하면 최종 에러가 발생합니다. 폴백 체인은 비용 순서(고성능 → 저비용)로 구성하는 것이 일반적입니다.

#code-block(`````python
from langchain.agents.middleware import ModelFallbackMiddleware

# gpt-4.1 실패 -> gpt-4.1-mini -> claude
fallback = ModelFallbackMiddleware(
    "gpt-4.1-mini",
    "claude-3-5-sonnet-20241022",
)
`````)

모델 안정성 확보 다음으로 중요한 것은 데이터 보안입니다. 에이전트가 처리하는 메시지에 개인정보가 포함될 수 있으며, 이를 로그나 외부 API에 노출하면 법적 문제가 발생합니다.

== 1.7 PIIMiddleware

에이전트가 처리하는 메시지에는 이메일 주소, 신용카드 번호, 전화번호 등 개인 식별 정보(PII)가 포함될 수 있습니다. 이러한 정보가 로그, 외부 API, 또는 LLM 프로바이더에 노출되면 개인정보보호법(GDPR, CCPA 등) 위반이 될 수 있습니다. `PIIMiddleware`는 개인 식별 정보를 자동 탐지하고 설정된 전략에 따라 처리합니다. 의료/금융 컴플라이언스, 고객 서비스 에이전트의 로그 세정, 민감한 사용자 데이터 처리 등에 필수적입니다.

=== 빌트인 PII 타입
`email`, `credit_card`, `ip`, `mac_address`, `url`

=== 처리 전략

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[전략],
  text(weight: "bold")[동작],
  text(weight: "bold")[예시 (이메일)],
  [`block`],
  [예외 발생 — PII 발견 시 실행 중단],
  [에러 발생],
  [`redact`],
  [`[REDACTED_TYPE]`으로 교체],
  [`[REDACTED_EMAIL]`],
  [`mask`],
  [부분 마스킹],
  [`u***\@example.com`],
  [`hash`],
  [결정적 해싱],
  [`a1b2c3d4...`],
)

=== 적용 범위
- `apply_to_input`: 사용자 입력 메시지 검사
- `apply_to_output`: AI 응답 메시지 검사
- `apply_to_tool_results`: 도구 실행 결과 검사

=== 커스텀 탐지기
빌트인 PII 타입(email, credit_card, ip, mac_address, url)만으로는 도메인 특화된 민감 정보를 처리할 수 없습니다. 커스텀 탐지기는 세 가지 방식으로 만들 수 있으며, 복잡도에 따라 적절한 방식을 선택합니다:
+ _정규식 문자열_: 간단한 패턴 매칭 (가장 간단)
+ *컴파일된 정규식 (`re.compile`)*: 복잡한 정규식 (중간)
+ _함수_: 검증 로직이 필요한 고급 탐지 (반환: `list[dict]` — `text`, `start`, `end` 키 포함, 가장 유연)

다음 코드들은 각 방식의 예시를 순서대로 보여줍니다.

#code-block(`````python
from langchain.agents.middleware import PIIMiddleware

email_pii = PIIMiddleware("email", strategy="redact", apply_to_input=True)
card_pii = PIIMiddleware("credit_card", strategy="mask", apply_to_input=True)
`````)

#code-block(`````python
# 커스텀 탐지기: 정규식 문자열
api_key_pii = PIIMiddleware(
    "api_key",
    detector=r"sk-[a-zA-Z0-9]{32}",
    strategy="block",
)
`````)

#code-block(`````python
import re

# 커스텀 탐지기: 컴파일된 정규식
phone_pii = PIIMiddleware(
    "phone_number",
    detector=re.compile(r"\+?\d{1,3}[\s.-]?\d{3,4}[\s.-]?\d{4}"),
    strategy="mask",
)
`````)

#code-block(`````python
# 커스텀 탐지기: 함수 (SSN 예시)
def detect_ssn(content: str) -> list[dict]:
    matches = []
    for m in re.finditer(r"\d{3}-\d{2}-\d{4}", content):
        first = int(m.group(0)[:3])
        if first not in [0, 666] and not (900 <= first <= 999):
            matches.append({"text": m.group(0), "start": m.start(), "end": m.end()})
    return matches

ssn_pii = PIIMiddleware("ssn", detector=detect_ssn, strategy="hash")
`````)

PII 미들웨어로 데이터 보안을 확보했다면, 마지막 빌트인 미들웨어는 에이전트의 _도구 선택 정확도_를 높이는 최적화입니다.

#warning-box[PII 탐지는 정규식 기반이므로 100% 정확하지 않을 수 있습니다. 높은 보안 수준이 필요한 시스템에서는 PII 미들웨어를 _방어 계층 중 하나_로 사용하고, 별도의 DLP(Data Loss Prevention) 솔루션과 병행하는 것을 권장합니다.]

PII 미들웨어로 데이터 보안을 확보했다면, 마지막 빌트인 미들웨어는 에이전트의 _도구 선택 정확도_를 높이는 최적화입니다.

== 1.8 LLMToolSelectorMiddleware

도구가 10개 이상일 때, 경량 LLM이 사용자 쿼리를 분석하여 관련 도구만 선별합니다. 도구 수가 많아지면 LLM이 모든 도구의 description을 처리해야 하므로 입력 토큰이 급증하고, 잘못된 도구를 선택할 확률도 높아집니다. 이 미들웨어는 사전 필터링을 통해 두 문제를 동시에 해결합니다. 비유하자면, 도서관에서 책을 찾을 때 전체 서가를 훑는 대신, 사서에게 먼저 관련 섹션을 물어보는 것과 같습니다.

=== 주요 파라미터

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[설명],
  text(weight: "bold")[기본값],
  [`model`],
  [도구 선택용 모델],
  [에이전트의 메인 모델],
  [`system_prompt`],
  [커스텀 선택 지침],
  [내장 프롬프트],
  [`max_tools`],
  [최대 선택 도구 수],
  [전체],
  [`always_include`],
  [항상 포함할 도구 이름 리스트],
  [`[]`],
)

선택 모델로 `gpt-4.1-mini` 같은 경량 모델을 사용하면 비용을 절감하면서도 효과적인 도구 필터링이 가능합니다.

#code-block(`````python
from langchain.agents.middleware import LLMToolSelectorMiddleware

tool_selector = LLMToolSelectorMiddleware(
    model="gpt-4.1-mini",
    max_tools=3,
    always_include=["search"],
)
`````)

7가지 빌트인 미들웨어만으로 대부분의 프로덕션 요구사항을 충족할 수 있지만, 비즈니스 고유의 로직이 필요한 경우 커스텀 미들웨어를 작성해야 합니다.

7가지 빌트인 미들웨어만으로 대부분의 프로덕션 요구사항을 충족할 수 있지만, 비즈니스 고유의 로직이 필요한 경우 커스텀 미들웨어를 작성해야 합니다. 예를 들어, 도메인 특화 감사 로그, 커스텀 메트릭 수집, 비즈니스 규칙 기반 가드레일 등은 커스텀 미들웨어로 구현합니다.

== 1.9 커스텀 미들웨어 작성

두 가지 구현 방식이 있으며, 복잡도와 요구사항에 따라 선택합니다:

=== 1. 데코레이터 방식
단일 훅, 간단한 로직에 적합합니다. `@before_model`, `@after_model`, `@wrap_model_call`, `@wrap_tool_call` 데코레이터를 사용합니다. 함수 하나로 미들웨어를 정의할 수 있어 빠른 프로토타이핑에 유리합니다.

=== 2. 클래스 방식 (`AgentMiddleware`)
여러 훅을 조합하거나 설정이 필요한 경우 `AgentMiddleware`를 상속합니다. sync/async 구현을 동시에 제공할 수 있습니다. 생성자에서 설정을 받고, 여러 훅 메서드를 오버라이드하여 복합적인 동작을 정의할 수 있습니다.

=== 커스텀 상태
미들웨어는 `NotRequired` 타입 힌트를 사용해 에이전트 상태를 확장할 수 있습니다. 이를 통해 실행 간 값 추적, 훅 간 데이터 공유, 레이트 리밋이나 감사 로깅 같은 횡단 관심사 구현이 가능합니다.

=== 에이전트 점프
미들웨어의 강력한 기능 중 하나는 에이전트의 실행 흐름 자체를 변경할 수 있다는 것입니다. `after_model` 등에서 딕셔너리를 반환하여 에이전트 흐름을 제어할 수 있습니다:
- `{"jump_to": "end"}` — 에이전트 즉시 종료 (가드레일 위반 시 강제 중단)
- `{"jump_to": "tools"}` — 도구 실행 단계로 이동 (모델 응답을 무시하고 특정 도구 강제 실행)
- `{"jump_to": "model"}` — 모델 호출 단계로 이동 (도구 결과를 바탕으로 재추론 요청)

다음 코드들은 데코레이터 방식과 클래스 방식의 커스텀 미들웨어 구현 예시를 보여줍니다.

#code-block(`````python
from langchain.agents.middleware import before_model

@before_model
def log_before(state, runtime):
    """모델 호출 전 메시지 수를 기록합니다."""
    print(f"[LOG] 메시지 {len(state.get('messages', []))}개")
`````)

#code-block(`````python
from langchain.agents.middleware import after_model

@after_model
def validate_output(state, runtime):
    """가드: 금지된 콘텐츠를 차단합니다."""
    last = state["messages"][-1].content
    if "FORBIDDEN" in last:
        return {"jump_to": "end"}
`````)

#code-block(`````python
from langchain.agents.middleware import wrap_model_call

@wrap_model_call
def retry_on_error(request, handler):
    """실패 시 모델 호출을 최대 2회 재시도합니다."""
    for attempt in range(3):
        try:
            return handler(request)
        except Exception as e:
            if attempt == 2: raise
`````)

#code-block(`````python
from langchain.agents.middleware import AgentMiddleware

class AuditMiddleware(AgentMiddleware):
    def __init__(self, log_file="audit.log"):
        self.log_file = log_file
    def before_model(self, state, config):
        print(f"[AUDIT] before -> {self.log_file}")
    def after_model(self, state, config):
        print(f"[AUDIT] after -> {self.log_file}")
`````)

커스텀 미들웨어를 작성할 수 있게 되었으니, 여러 미들웨어를 함께 사용할 때의 실행 순서를 이해하는 것이 중요합니다. 순서에 따라 미들웨어 간 상호작용이 달라지기 때문입니다.

== 1.10 미들웨어 실행 순서

다중 미들웨어 등록 시 실행 순서를 정확히 이해해야 예상치 못한 동작을 방지할 수 있습니다.

#warning-box[`before_*` 훅은 등록 순서(A → B → C)로 실행되지만, `after_*` 훅은 역순(C → B → A)으로 실행됩니다. 이는 함수 호출 스택의 LIFO(Last In, First Out) 원리와 동일합니다. `wrap_*` 훅은 중첩 래핑(A가 B를 감싸고, B가 C를 감싸는) 방식으로 동작합니다.]

`middleware=[A, B, C]` 등록 시:

#align(center)[#image("../../assets/diagrams/png/middleware_execution_order.png", width: 88%, height: 112mm, fit: "contain")]

=== 실전 팁
- _PII 검출은 로깅보다 먼저_ 등록해야 로그에 PII가 포함되지 않습니다.
- _폴백 미들웨어는 재시도 미들웨어보다 뒤에_ 배치하여, 재시도 실패 후 폴백이 작동하도록 합니다.
- `wrap` 훅에서 `next_fn`을 호출하지 않으면 이후 미들웨어와 실제 호출이 모두 건너뛰어집니다.

#code-block(`````python
@before_model
def mw_a(state, runtime): print("before A")

@before_model
def mw_b(state, runtime): print("before B")

@before_model
def mw_c(state, runtime): print("before C")

# 실행: A -> B -> C (after_model이면 C -> B -> A)
`````)

실행 순서를 이해했다면, 이제 프로덕션에서 실제로 미들웨어를 어떻게 조합하는지 살펴보겠습니다.

== 1.11 미들웨어 조합 (Stacking)

프로덕션 환경에서는 여러 미들웨어를 함께 사용하여 종합적인 에이전트 거버넌스를 구현합니다. 미들웨어는 등록 순서에 따라 실행되므로, 배치 순서가 매우 중요합니다. 권장 순서는 다음과 같습니다:

+ *보안(PII)*: 가장 먼저 실행하여 민감 정보가 후속 미들웨어나 로그에 노출되지 않도록 합니다
+ *신뢰성(폴백)*: 모델 장애 시 대체 모델로 자동 전환합니다
+ *비용 제어(호출 제한)*: 호출 횟수를 제한하여 예산을 보호합니다
+ *컨텍스트 관리(요약)*: 긴 대화를 자동 요약하여 윈도우 초과를 방지합니다
+ *최적화(도구 선택)*: 관련 도구만 필터링하여 정확도를 높입니다
+ *감독(HITL)*: 고위험 작업에 대해 인간 승인을 요청합니다

이러한 조합을 통해 각 미들웨어는 단일 책임 원칙을 유지하면서도, 전체적으로 강력한 프로덕션 에이전트 파이프라인을 구성할 수 있습니다.

다음 코드는 프로덕션 환경에서 권장되는 미들웨어 스택 구성 예시입니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.middleware import (
    PIIMiddleware, ModelFallbackMiddleware,
    ModelCallLimitMiddleware, SummarizationMiddleware,
    HumanInTheLoopMiddleware, LLMToolSelectorMiddleware,
)
from langgraph.checkpoint.memory import InMemorySaver
`````)

#code-block(`````python
middleware_stack = [
    PIIMiddleware("email", strategy="redact", apply_to_input=True),
    ModelFallbackMiddleware("gpt-4.1-mini", "claude-3-5-sonnet-20241022"),
    ModelCallLimitMiddleware(thread_limit=50, run_limit=10),
    SummarizationMiddleware(model="gpt-4.1-mini", trigger=("tokens", 4000)),
]

production_agent = create_agent(
    model="gpt-4.1", tools=[], checkpointer=InMemorySaver(), middleware=middleware_stack,
)
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심 내용],
  [_아키텍처_],
  [4가지 훅: `before_model`, `after_model`, `wrap_model_call`, `wrap_tool_call`],
  [_빌트인 7종_],
  [Summarization, HITL, ModelCallLimit, ToolCallLimit, ModelFallback, PII, LLMToolSelector],
  [_커스텀_],
  [데코레이터(`\@before_model` 등) / `AgentMiddleware` 클래스],
  [_실행 순서_],
  [`before`: 순방향, `after`: 역방향, `wrap`: 중첩],
  [_프로덕션_],
  [PII → Fallback → Limit → Summarization → ToolSelector → HITL],
)

미들웨어는 단일 에이전트의 동작을 제어하는 강력한 도구입니다. 그러나 복잡한 도메인 문제를 해결하려면 여러 에이전트가 협력하는 멀티에이전트 아키텍처가 필요합니다. 다음 장에서는 감독자 패턴으로 서브에이전트를 조율하는 멀티에이전트 시스템을 다룹니다.
