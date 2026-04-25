// Source: 08_integration/11_provider_middleware/07_openai_moderation.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "OpenAI Moderation", subtitle: "정책 위반 콘텐츠 사전/사후 차단")

`OpenAIModerationMiddleware`는 OpenAI Moderation API로 _사용자 입력 · 모델 출력 · 도구 결과_를 자동 스캔하고, 정책 위반이 감지되면 대화를 차단·교체·예외 처리합니다. 공개 챗봇의 혐오·폭력·자해 카테고리 선제 차단, 외부 도구 결과의 2차 오염 방지에 쓰입니다.

#learning-header()
#learning-objectives(
  [`check_input` / `check_output` / `check_tool_results` 세 스캔 지점의 의미와 비용 트레이드오프를 안다],
  [`exit_behavior` 세 모드(`"end"` / `"error"` / `"replace"`)의 동작을 구분한다],
  [커스텀 `violation_message` 템플릿으로 사용자 응답을 다듬는다],
  [사전 구성된 OpenAI 클라이언트를 `client` / `async_client`로 주입한다],
)

== 8.1 언제 쓰나

- 공개 챗봇에서 _혐오·폭력·자해_ 같은 Moderation 카테고리를 선제 차단할 때
- 도구 결과(예: 웹 검색, 이메일 본문)에 유해 콘텐츠가 섞여 모델에 들어가는 것을 막을 때
- 로그/감사용으로 _위반 메타데이터_를 응답 흐름에 남겨 보고서를 만들 때

== 8.2 환경 설정

필요 패키지: `langchain`, `langchain-openai`. `.env`에 `OPENAI_API_KEY`가 있어야 합니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_openai.middleware import OpenAIModerationMiddleware

load_dotenv()
`````)

== 8.3 기본 사용 — 입출력 모두 검사, 위반 시 종료

기본 설정은 `check_input=True`, `check_output=True`, `exit_behavior="end"`. 사용자 입력이 Moderation API에 걸리면 모델 호출 자체를 건너뛰고 _위반 메시지로 대화가 종료_됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[기본값],
  text(weight: "bold")[설명],
  [`model`],
  [`"omni-moderation-latest"`],
  [사용할 Moderation 모델],
  [`check_input`],
  [`True`],
  [사용자 메시지를 모델에 넘기기 전 검사],
  [`check_output`],
  [`True`],
  [모델 생성 응답을 사용자에게 반환하기 전 검사],
  [`check_tool_results`],
  [`False`],
  [도구 실행 결과를 모델 입력 전에 검사],
  [`exit_behavior`],
  [`"end"`],
  [`"end"` / `"error"` / `"replace"`],
  [`violation_message`],
  [기본 템플릿],
  [위반 시 사용자에게 보여줄 텍스트],
  [`client` / `async_client`],
  [`None`],
  [사전 구성된 OpenAI 클라이언트 주입 (선택)],
)

#code-block(`````python
agent = create_agent(
    model="openai:gpt-4.1",
    tools=[],
    middleware=[OpenAIModerationMiddleware()],
)
`````)

== 8.4 `exit_behavior="end"` — 위반 입력 즉시 종료

유해 카테고리(예: 자해 유도)가 감지되면 모델 호출 없이 바로 위반 메시지로 마감됩니다. 응답 마지막 메시지에는 기본 위반 메시지가 들어갑니다.

== 8.5 `exit_behavior="error"` — 예외로 빠르게 실패

테스트/배치 환경에서 위반을 _조용히 넘기지 않고_ 예외로 띄우고 싶을 때 사용합니다. `OpenAIModerationError`가 발생하며 상위 파이프라인에서 catch해 감사 로그에 남길 수 있습니다.

#code-block(`````python
from langchain_openai.middleware import OpenAIModerationError

agent = create_agent(
    model="openai:gpt-4.1",
    tools=[],
    middleware=[OpenAIModerationMiddleware(exit_behavior="error")],
)

try:
    agent.invoke({"messages": [{"role": "user", "content": "..."}]})
except OpenAIModerationError as e:
    # 감사 로그에 기록
    print("Moderation violation:", e.categories)
`````)

== 8.6 `exit_behavior="replace"` — 메시지만 교체하고 계속

출력 검사에서 위반이 잡히면 _해당 응답만 위반 메시지로 교체_하고 그래프 실행은 계속됩니다. 멀티턴 대화에서 _대화 자체는 끊지 않고_ 특정 응답만 정리할 때 유용합니다.

#code-block(`````python
agent = create_agent(
    model="openai:gpt-4.1",
    tools=[],
    middleware=[
        OpenAIModerationMiddleware(
            exit_behavior="replace",
            violation_message=(
                "이 응답은 안전 정책에 따라 표시할 수 없습니다 "
                "(카테고리: {categories}). 다른 질문을 해 주세요."
            ),
        ),
    ],
)
`````)

`violation_message`는 `{categories}`, `{category_scores}`, `{original_content}` 변수를 지원하는 템플릿 문자열입니다.

== 8.7 도구 결과 스캔 (`check_tool_results=True`)

웹 검색·크롤링·DB 조회 도구 결과에 _제3자가 작성한 유해 콘텐츠_가 섞여 모델에 그대로 들어가는 걸 막습니다. 비용은 도구 호출 수에 비례해 늘어나므로 _신뢰할 수 없는 외부 소스_를 건드리는 파이프라인에서만 켭니다.

#code-block(`````python
agent = create_agent(
    model="openai:gpt-4.1",
    tools=[web_search_tool, fetch_url_tool],
    middleware=[
        OpenAIModerationMiddleware(
            check_input=True,
            check_output=True,
            check_tool_results=True,
        ),
    ],
)
`````)

== 8.8 비용·지연 트레이드오프

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[설정],
  text(weight: "bold")[비용],
  text(weight: "bold")[지연],
  text(weight: "bold")[주요 효과],
  [`check_input=True`],
  [Mod 1 + Model 1],
  [+1 RT],
  [유해 입력이 모델에 들어가기 전 차단],
  [`check_output=True`],
  [Model 1 + Mod 1],
  [+1 RT],
  [모델이 잘못된 응답을 냈을 때 최종 사용자 보호],
  [`check_tool_results=True`],
  [도구 수 × Mod],
  [도구당 +1],
  [외부 오염 데이터 차단],
)

#tip-box[*실전 가이드*: 프로덕션에서는 `check_input`만 항상 켜고 `check_output`은 샘플링(예: 10%) 전략으로 운영하는 경우가 많습니다. `check_tool_results`는 외부 신뢰할 수 없는 소스 전용으로 제한합니다.]

== 핵심 정리

- 세 스캔 지점을 비용/지연 트레이드오프로 선택: input 항상 켜기, output 샘플링, tool_results 조건부
- `exit_behavior`로 대화 종료(`end`)/즉시 예외(`error`)/메시지 교체(`replace`) 선택
- `violation_message` 템플릿으로 사용자 친화적 안내 구성
- `client` / `async_client`로 사전 구성된 OpenAI 클라이언트를 재사용해 초기화 비용 절감
