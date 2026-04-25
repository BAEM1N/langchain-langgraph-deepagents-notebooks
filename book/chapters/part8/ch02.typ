// Source: 08_integration/11_provider_middleware/01_anthropic_prompt_caching.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Anthropic Prompt Caching", subtitle: "서버 측 캐시로 입력 토큰 90% 절감")

Claude 모델 전용 프롬프트 캐시 미들웨어 `AnthropicPromptCachingMiddleware`는 긴 system prompt, 도구 정의, 초기 대화 컨텍스트를 Anthropic 서버 측에 5분~1시간 캐시해 _입력 토큰 비용과 지연을 크게 절감_합니다. 같은 에이전트가 같은 시스템 프롬프트로 여러 번 호출될 때, 두 번째 호출부터는 입력 토큰 단가가 약 90% 할인됩니다.

#learning-header()
#learning-objectives(
  [4개 파라미터(`type`, `ttl`, `min_messages_to_cache`, `unsupported_model_behavior`)를 이해한다],
  [`usage_metadata.input_token_details`에서 `cache_creation` / `cache_read`를 읽어 캐시 적중을 확인한다],
  [1시간 TTL beta와 5분 기본값의 선택 기준을 안다],
  [비(非) Anthropic 모델에 적용할 때 `warn` / `ignore` / `raise` 동작을 구분한다],
)

== 2.1 언제 쓰나

- 긴 system prompt(수천 토큰의 기업 정책, 스타일 가이드)를 매 턴 전송하는 에이전트
- 큰 tool 정의 목록(20개 이상의 JSON schema)을 반복 전송하는 구성
- RAG 컨텍스트 재사용: 같은 문서 묶음을 여러 질의에 걸쳐 사용
- 멀티턴 대화에서 앞부분 컨텍스트가 안정적인 경우

== 2.2 환경 설정

필요 패키지: `langchain`, `langchain-anthropic`. `.env`에 `ANTHROPIC_API_KEY`가 있어야 합니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import AnthropicPromptCachingMiddleware

load_dotenv()
`````)

== 2.3 기본 사용

미들웨어를 `create_agent`의 `middleware` 리스트에 넣으면 LangChain이 _system prompt · tool 정의 · 마지막 메시지_ 위치에 `cache_control: {"type": "ephemeral"}` 마커를 자동 부착합니다.

#code-block(`````python
long_system_prompt = (
    "You are a senior software engineer... " * 200  # 약 2,000 토큰 가정
)

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt=long_system_prompt,
    tools=[],
    middleware=[AnthropicPromptCachingMiddleware()],
)
`````)

== 2.4 캐시 적중 확인

같은 에이전트로 연속 두 번 호출하고 `usage_metadata`를 읽으면 캐시 적중 여부가 드러납니다. 1회차는 `cache_creation_input_tokens`가, 2회차 이후는 `cache_read_input_tokens`가 커집니다.

#code-block(`````python
for i in range(2):
    result = agent.invoke(
        {"messages": [{"role": "user", "content": f"요청 {i}"}]},
    )
    last = result["messages"][-1]
    print(i, last.usage_metadata.get("input_token_details"))
`````)

#output-block(`````
0 {'cache_creation': 2048, 'cache_read': 0}
1 {'cache_creation': 0, 'cache_read': 2048}
`````)

== 2.5 파라미터 전체

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[기본값],
  text(weight: "bold")[설명],
  [`type`],
  [`"ephemeral"`],
  [현재 Anthropic이 지원하는 유일한 타입],
  [`ttl`],
  [`"5m"`],
  [캐시 유지 시간. `"5m"` 또는 `"1h"`. 1시간은 Anthropic beta],
  [`min_messages_to_cache`],
  [`0`],
  [메시지 수가 이 값 이상일 때만 cache_control 부착],
  [`unsupported_model_behavior`],
  [`"warn"`],
  [비 Anthropic 모델 적용 시 `"warn"` / `"ignore"` / `"raise"`],
)

=== 1시간 TTL 예

#code-block(`````python
AnthropicPromptCachingMiddleware(
    ttl="1h",
    min_messages_to_cache=2,
)
`````)

1시간 캐시는 긴 상담 세션, 일간 배치 분석 작업처럼 _같은 시스템 프롬프트로 수 시간 동안 반복 호출_되는 시나리오에 적합합니다. 5분 기본값은 실시간 챗봇의 사용자 연속 입력용입니다.

== 2.6 비 Anthropic 모델 동작

이 미들웨어는 내부적으로 `cache_control` 블록을 주입하므로, 다른 공급자 모델에서는 무시되거나 에러가 됩니다. 모델 교체 가능한 파이프라인을 설계할 때는 `unsupported_model_behavior`를 명시하세요.

#code-block(`````python
# 경고만 남기고 계속
AnthropicPromptCachingMiddleware(unsupported_model_behavior="warn")

# 조용히 스킵
AnthropicPromptCachingMiddleware(unsupported_model_behavior="ignore")

# 즉시 실패 (CI/테스트용)
AnthropicPromptCachingMiddleware(unsupported_model_behavior="raise")
`````)

== 2.7 Bedrock과의 차이

AWS Bedrock 경유로 Claude를 호출하는 경우에는 `BedrockPromptCachingMiddleware`(ch7)를 사용합니다. 두 미들웨어는 파라미터 이름과 의미가 거의 같지만, _대상 패키지_와 TTL 제약(Nova 모델은 5m만 지원, tool 정의 캐시 미지원)이 다릅니다.

== 핵심 정리

- 긴 system prompt·tool 정의를 반복 전송하는 에이전트에서 입력 토큰 비용을 90% 절감
- `cache_creation_input_tokens` → `cache_read_input_tokens` 이동으로 캐시 적중 검증
- TTL `"5m"`은 실시간 대화, `"1h"`는 장시간 배치·상담 세션용
- 멀티 프로바이더 파이프라인은 `unsupported_model_behavior="warn"`을 명시해 조용한 실패 방지
