// Source: 08_langsmith/04_prompt_hub.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Prompt Hub 버전 관리", subtitle: "Commit SHA · Tag · Playground")

프롬프트는 사실상 _코드_지만, 엔지니어가 아닌 사람이 자주 고치고 주기도 짧습니다. 매번 재배포하지 않으려면 프롬프트를 _애플리케이션 코드와 분리된 저장소_에 두고 버전 핀을 찍습니다. LangSmith Prompt Hub가 그 역할을 합니다. 이 장은 push/pull API, commit SHA vs tag, 템플릿 엔진 선택, Playground 실험, CI 핀 전략을 다룹니다.

#learning-header()
#learning-objectives(
  [`client.push_prompt("name", object=...)`로 프롬프트를 업로드한다],
  [Commit SHA 고정 vs `prod`·`staging` 태그 참조의 차이를 이해한다],
  [f-string vs mustache 템플릿의 변수 처리 차이를 비교한다],
  [Playground에서 실험 → 커밋 → 태그 플로우를 숙지한다],
  [런타임에서 `client.pull_prompt("name:prod")`로 프롬프트를 주입한다],
  [CI 테스트에서 _특정 커밋 해시를 고정_해 회귀를 방지한다],
)

== 4.1 Prompt 생성 · 푸시

가장 단순한 형태는 `ChatPromptTemplate`을 만든 뒤 `client.push_prompt("이름", object=prompt)`로 올리는 것입니다. 첫 push는 새 prompt를 생성하고, 이후 push는 새 commit을 쌓습니다. 반환 URL로 UI에서 바로 열립니다.

#code-block(`````python
from langchain_core.prompts import ChatPromptTemplate
from langsmith import Client

client = Client()
prompt = ChatPromptTemplate.from_messages([
    ("system", "너는 날씨 비서야. 도시명만 뽑아 알려줘."),
    ("user", "{question}"),
])

url = client.push_prompt("weather-bot", object=prompt)
print(url)  # https://smith.langchain.com/hub/...
`````)

#figure(image("../../../assets/images/langsmith/04_prompt_hub/01_prompt_hub_list.png", width: 95%), caption: [Prompts 허브 목록 — `city-list`(1 commit), `weather-bot`(2 commits). Visibility, Last Commit 짧은 SHA 표시])

== 4.2 Commit SHA 고정 vs 태그 (`prod`, `staging`)

프롬프트는 Git처럼 동작합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[참조 방식],
  text(weight: "bold")[예],
  text(weight: "bold")[특성],
  text(weight: "bold")[언제 쓰나],
  [*Commit SHA*],
  [`weather-bot:12344e88`],
  [불변, 정확히 그 버전을 핀],
  [CI 회귀 테스트, 재현 필요 시],
  [*Tag*],
  [`weather-bot:prod`, `:staging`],
  [이동형 — 다른 커밋을 가리키도록 변경 가능],
  [런타임 배포 슬롯],
  [*최신*],
  [`weather-bot`],
  [가장 최근 커밋],
  [개발 초기에만, 프로덕션 금지],
)

태그는 애플리케이션 코드를 재배포하지 않고 프롬프트만 교체할 수 있는 핵심 장치입니다. UI의 Commits 뷰에서 특정 커밋에 `prod` 태그를 *promote*합니다.

#figure(image("../../../assets/images/langsmith/04_prompt_hub/02_prompt_detail.png", width: 95%), caption: [Prompt 상세 — 상단 commit + 탭(Messages/Code Snippet/Comments), Environments 패널의 Production/Staging 슬롯])

== 4.3 f-string vs mustache

템플릿 엔진 두 가지의 특성은 실무에서 자주 문제가 됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[f-string (`{var}`)],
  text(weight: "bold")[mustache (`{{var}}`)],
  [기본값],
  [LangChain 기본],
  [별도 선택],
  [JSON 예시 포함],
  [`{{` 이스케이프 필요],
  [이스케이프 불필요],
  [조건문 · 반복],
  [미지원],
  [`{{#users}}...{{/users}}`],
  [중첩 키],
  [제한적],
  [`{{user.name}}`],
  [Playground 변수 지정],
  [자동 감지],
  [수동 지정 (Inputs)],
)

JSON/코드 예시를 많이 끼워 넣거나 반복/조건이 들어가면 mustache가, 단순 변수 치환이면 f-string이 편합니다.

== 4.4 Playground — 실험에서 커밋까지

UI의 *Playground*는 프롬프트 + 모델 + 입력 변수를 같이 돌려보는 공간입니다. 흐름은:

+ 프롬프트 페이지에서 `Open in Playground` 클릭
+ 모델·temperature·출력 스키마·tools를 사이드 패널에서 조정
+ 변수 값을 넣고 `Run` — 결과와 token/cost가 곧바로 기록됨
+ `Compare`로 같은 입력에 대한 _여러 프롬프트/모델 출력 병렬 비교_
+ 만족스러운 상태에서 `Save as...` → 새 커밋 생성, 필요하면 `prod` 태그로 promote

Playground에서 돌린 모든 run은 Experiments 뷰로 넘어가 3장의 데이터셋과 직접 연결됩니다.

#figure(image("../../../assets/images/langsmith/04_prompt_hub/03_playground.png", width: 95%), caption: [Playground — SYSTEM/HUMAN 메시지 편집 + `{question}` 변수 입력 + Output 생성. f-string↔mustache 스위처 제공])

== 4.5 런타임 주입 — `pull_prompt` → `create_agent`

애플리케이션에서는 배포 슬롯 태그를 `pull_prompt`로 끌어와 _LLM/에이전트에 바로 꽂습니다_. 프롬프트를 고치면 재배포 없이 다음 요청부터 반영됩니다.

#code-block(`````python
from langchain.agents import create_agent

prompt = client.pull_prompt("weather-bot:prod")

agent = create_agent(
    model="openai:gpt-4.1",
    system_prompt=prompt.format_messages()[0].content,
    tools=[],
)
`````)

== 4.6 CI에서 특정 커밋 해시 고정

프로덕션 배포 슬롯은 `:prod` 태그로 받되, _회귀 테스트는 반드시 commit SHA를 핀_해야 합니다. 그래야 "통과한 테스트 이후 누군가 프롬프트를 고쳤다"는 사고가 자동으로 차단됩니다.

#code-block(`````python
# tests/test_prompt_regression.py
PINNED_SHA = "12344e88"  # CI 핀

def test_weather_prompt_still_extracts_city():
    prompt = client.pull_prompt(f"weather-bot:{PINNED_SHA}")
    # ... 구체 assertion
`````)

=== 배포 패턴 요약

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[환경],
  text(weight: "bold")[참조],
  text(weight: "bold")[이유],
  [dev / 로컬],
  [`weather-bot` (최신)],
  [즉시 반영],
  [staging],
  [`weather-bot:staging`],
  [태그만 promote해서 테스트],
  [prod],
  [`weather-bot:prod`],
  [태그 이동으로 무중단 롤아웃, 롤백은 태그 되돌리기],
  [CI],
  [`weather-bot:{SHA}`],
  [재현 가능, 프롬프트 변경이 바로 테스트 실패로 감지],
)

3장의 experiment에 `prompt_commit`을 metadata로 넣으면 _어떤 커밋 기준에서 낸 수치인지_ UI에서 바로 추적됩니다.

== 핵심 정리

- 프롬프트 허브는 push → commit 축적 → tag promote 구조 (Git과 유사)
- 태그는 런타임 배포 슬롯, SHA는 CI 재현용 핀
- f-string vs mustache는 반복/조건/중첩 여부로 선택
- Playground에서 실험 → Save → promote 플로우가 비개발자 편집 경로
- CI에서 SHA 핀, 프로덕션에서 태그 참조 — 이 조합이 무중단 롤아웃 + 회귀 방지의 핵심
