// Source: 08_integration/11_provider_middleware/06_bedrock_prompt_caching.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Bedrock Prompt Caching", subtitle: "AWS 경유 Claude/Nova 캐시")

AWS Bedrock 경유로 Claude/Nova 모델을 호출할 때 `BedrockPromptCachingMiddleware`로 _시스템 프롬프트 · 도구 정의 · 마지막 메시지_ 위치에 캐시 체크포인트를 자동으로 박아 입력 토큰 비용을 낮춥니다. `AnthropicPromptCachingMiddleware`(ch2)와 _파라미터 이름과 의미는 거의 같지만_ 대상 패키지와 모델별 제약이 다릅니다.

#learning-header()
#learning-objectives(
  [`BedrockPromptCachingMiddleware`의 4개 파라미터를 이해한다],
  [`usage_metadata.input_token_details`에서 `cache_creation` / `cache_read`를 읽어 적중을 검증한다],
  [`ChatBedrock` vs `ChatBedrockConverse`에서 `type` 파라미터 처리 차이를 안다],
  [Nova 모델의 제약(5m TTL 전용, tool 정의 캐시 미지원)을 구분한다],
)

== 7.1 언제 쓰나

- AWS 계정·VPC 경계 안에서만 LLM을 호출해야 하는 기업 환경 (Bedrock 경유)
- Claude를 Anthropic 직접 API가 아닌 _Bedrock 요금제_로 이용할 때
- Amazon Nova 모델을 쓰면서 긴 시스템 프롬프트를 반복 사용할 때

== 7.2 환경 설정

필요 패키지: `langchain`, `langchain-aws`. AWS 자격증명(`AWS_ACCESS_KEY_ID` 등)과 리전이 `.env` 또는 환경에 설정돼 있어야 합니다. 모델별로 Bedrock 콘솔에서 _모델 액세스_를 먼저 허용해야 호출이 됩니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_aws.middleware import BedrockPromptCachingMiddleware

load_dotenv()
`````)

== 7.3 ChatBedrockConverse + Claude (권장)

Converse API는 Bedrock의 _통합 인터페이스_로, 다양한 모델을 같은 API로 호출합니다. `BedrockPromptCachingMiddleware`를 붙이면 system/tool/last-message 위치에 캐시 체크포인트가 자동으로 삽입됩니다.

#warning-box[체크포인트가 실제로 작동하려면 캐시 대상 블록이 _약 1,024 토큰 이상_이어야 합니다. 짧은 system prompt에서는 `cache_creation`이 잡히지 않을 수 있습니다.]

#code-block(`````python
long_prompt = (
    "You are an enterprise policy assistant. Always cite section numbers. "
    * 200  # ~2,000 tokens
)

agent = create_agent(
    model="bedrock_converse:anthropic.claude-sonnet-4-20250514-v2:0",
    system_prompt=long_prompt,
    tools=[],
    middleware=[BedrockPromptCachingMiddleware(ttl="1h")],
)
`````)

== 7.4 캐시 적중 검증

두 번 연속 호출한 뒤 `usage_metadata.input_token_details`를 읽어 캐시 생성/적중을 확인합니다.

#code-block(`````python
for i in range(2):
    result = agent.invoke(
        {"messages": [{"role": "user", "content": f"요청 {i}"}]},
    )
    last = result["messages"][-1]
    print(i, last.usage_metadata.get("input_token_details"))
`````)

`cache_creation`은 1회차에 채워지고, `cache_read`는 2회차 이후에 늘어납니다.

== 7.5 파라미터 전체

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
  [`ChatBedrock` 전용. `ChatBedrockConverse`는 이 값을 무시하고 `"default"` 사용],
  [`ttl`],
  [`"5m"`],
  [`"5m"` 또는 `"1h"`. _Nova 계열은 `"5m"`만 지원_],
  [`min_messages_to_cache`],
  [`0`],
  [메시지 수가 이 이상일 때만 cache 체크포인트 부착],
  [`unsupported_model_behavior`],
  [`"warn"`],
  [캐시 미지원 모델에 대해 `"ignore"` / `"warn"` / `"raise"`],
)

== 7.6 ChatBedrock (Invoke 모델) 예시

`ChatBedrock`은 이전 세대 invoke-model 래퍼입니다. `BedrockPromptCachingMiddleware`는 이쪽도 지원하며 `type="ephemeral"` 파라미터가 _여기서는 실제로 반영_됩니다. `ChatBedrock`은 Anthropic 모델 한정으로 tool 정의 캐시와 확장 TTL(1h)을 모두 지원합니다.

#code-block(`````python
from langchain_aws import ChatBedrock

model = ChatBedrock(model_id="anthropic.claude-sonnet-4-20250514-v2:0")

agent = create_agent(
    model=model,
    system_prompt=long_prompt,
    tools=[],
    middleware=[
        BedrockPromptCachingMiddleware(type="ephemeral", ttl="1h"),
    ],
)
`````)

== 7.7 Amazon Nova 제약

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[ChatBedrockConverse + Anthropic],
  text(weight: "bold")[ChatBedrockConverse + Nova],
  [시스템 프롬프트 캐시],
  [O],
  [O],
  [도구 정의 캐시],
  [O],
  [X],
  [메시지 캐시],
  [O],
  [O (tool result 메시지 제외)],
  [TTL `"1h"`],
  [O],
  [X (5m 전용)],
)

Nova 모델을 쓸 때는 `ttl="5m"`으로 고정하고, `unsupported_model_behavior="warn"`을 설정해 실수로 `"1h"`를 지정했을 때 조용히 넘어가지 않도록 경고를 남기세요.

== 핵심 정리

- AWS 경계 안에서 Claude/Nova 사용 시 Bedrock 미들웨어로 입력 토큰 비용 절감
- `ChatBedrock`과 `ChatBedrockConverse`의 `type` 파라미터 처리 차이를 인지
- Nova 모델은 5m TTL + tool 정의 캐시 미지원 — 설정 시 `ttl="5m"` 고정
- 캐시 대상 블록은 약 1,024 토큰 이상이어야 실제 적중 발생
