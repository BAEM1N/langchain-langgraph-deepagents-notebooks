// Source: 06_langsmith/01_quickstart.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LangSmith Quickstart", subtitle: "첫 트레이스부터 UI 투어까지")

LangSmith는 LangChain 팀이 만든 _LLM 애플리케이션 관측 플랫폼_입니다. 에이전트 코드를 고칠 필요 없이 환경변수 세 줄만 추가하면 모든 LLM 호출과 도구 실행이 자동으로 트레이스로 기록됩니다. 이 장은 API 키 발급부터 UI에서 첫 트레이스를 확인하고, `@traceable` 데코레이터와 `langsmith.Client`로 순수 Python 함수까지 트레이스에 편입하는 흐름을 다룹니다.

#learning-header()
#learning-objectives(
  [LangSmith API 키를 발급하고 `.env`에 주입한다],
  [`LANGSMITH_TRACING=true` 설정만으로 기존 에이전트가 자동 트레이싱되는 것을 확인한다],
  [`run_name` · `tags` · `metadata`로 트레이스를 검색 가능하게 만든다],
  [UI에서 트레이스 트리, latency, 토큰 사용량, 비용을 읽는다],
  [`@traceable`로 일반 함수를 트레이스에 편입한다],
)

== 1.1 API 키와 환경 변수

LangSmith는 코드 변경 없이 환경 변수 세 줄만으로 트레이싱을 활성화합니다. `.env` 파일에 다음을 추가합니다.

#code-block(`````dotenv
LANGSMITH_API_KEY=lsv2_pt_xxxxxxxx
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langsmith-quickstart
`````)

`LANGSMITH_PROJECT`는 UI 좌측 _Projects_ 메뉴에서 구분되는 네임스페이스입니다. 설정하지 않으면 `default` 프로젝트에 기록됩니다. API 키 발급은 한 번만 표시되므로, 생성 직후 바로 `.env`에 복사해야 합니다.

=== 온보딩 플로우 (최초 1회)

최초 로그인 시 역할 선택 → 모드 선택 → 홈 → 퀵스타트 다이얼로그 순서로 4단계 온보딩이 진행됩니다. Technical 역할과 LangSmith(code-first) 모드를 선택해 개발자용 흐름을 사용합니다.

#figure(image("../../../assets/images/langsmith/01_quickstart/00_onboarding_step1_role.png", width: 85%), caption: [역할 선택 — Technical 선택 시 개발자용 code-first 흐름으로 진입])

#figure(image("../../../assets/images/langsmith/01_quickstart/01_onboarding_step2_mode.png", width: 85%), caption: [LangSmith(code-first) vs Fleet(no-code) 분기 — 이 장은 LangSmith 경로])

#figure(image("../../../assets/images/langsmith/01_quickstart/02_home_empty_state.png", width: 85%), caption: [온보딩 완료 직후 Home — Tracing/Datasets/Prompts 모두 초기 상태])

#figure(image("../../../assets/images/langsmith/01_quickstart/03_get_started_tracing_dialog.png", width: 85%), caption: [Home의 첫 카드로 열리는 4단계 퀵스타트 다이얼로그])

#figure(image("../../../assets/images/langsmith/01_quickstart/04_api_key_generated_RAW.png", width: 85%), caption: [Generate API Key 클릭 시 `lsv2_pt_…` 키 생성 — 한 번만 표시되므로 즉시 `.env`로 복사])

== 1.2 첫 트레이스 — LangChain 에이전트

`create_agent`는 _자동 계측_되어 있습니다. 환경변수만 설정되어 있으면 아래 코드가 실행되는 순간 LangSmith에 기록됩니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain.tools import tool

load_dotenv()

@tool
def get_weather(city: str) -> str:
    """도시의 날씨를 조회한다."""
    return f"{city} 맑음"

agent = create_agent(
    model="openai:gpt-4.1",
    tools=[get_weather],
)

agent.invoke({"messages": [{"role": "user", "content": "서울 날씨 알려줘"}]})
`````)

실행 후 UI의 _Projects → langsmith-quickstart_ 에서 방금 실행이 한 행으로 보이고, 클릭하면 LLM 호출 → 도구 호출 → LLM 호출 트리가 시각적으로 재구성됩니다.

#figure(image("../../../assets/images/langsmith/01_quickstart/05_projects_list.png", width: 95%), caption: [Projects 리스트 — Trace Count, P50/P99 Latency, Total Tokens, Total Cost 자동 집계])

#figure(image("../../../assets/images/langsmith/01_quickstart/06_project_runs_list.png", width: 95%), caption: [프로젝트 상세의 Run 테이블 — Input/Output/Latency/Tokens/Cost/Tags/Metadata 한 화면])

#figure(image("../../../assets/images/langsmith/01_quickstart/07_trace_tree_view.png", width: 95%), caption: [Trace Tree — `model → tools → model` 순서와 각 단계의 토큰/지연이 waterfall로 표시])

== 1.3 run_name · tags · metadata

`invoke(..., config=...)`로 트레이스에 검색·필터용 메타 정보를 부착합니다. 운영에서 "이 사용자가 이 세션에서 낸 실패만 보겠다" 같은 질의를 가능하게 해 주는 핵심 레버입니다.

#code-block(`````python
agent.invoke(
    {"messages": [{"role": "user", "content": "부산 날씨"}]},
    config={
        "run_name": "weather-query-demo",
        "tags": ["env:dev", "feature:weather"],
        "metadata": {
            "user_id": "u_00123",
            "session_id": "s_demo",
            "app_version": "0.1.0",
        },
    },
)
`````)

UI에서 `Filter → Tags contains env:dev` 또는 `Metadata.user_id = u_00123`으로 필터링되는 것을 확인합니다.

#figure(image("../../../assets/images/langsmith/01_quickstart/08_trace_attributes.png", width: 95%), caption: [Attributes 탭 — 부착한 Tags/Metadata가 그대로 보이고 환경·런타임 정보도 자동 캡처])

== 1.4 순수 Python 함수 트레이싱 — `@traceable`

LangChain을 거치지 않는 전처리/후처리 유틸리티 함수도 `@traceable`로 트레이스에 편입할 수 있습니다. 부모 트레이스 아래 자식 span으로 묶이므로 "왜 이 도시로 쿼리를 보냈는가" 같은 추적이 가능합니다.

#code-block(`````python
from langsmith import traceable

@traceable(run_type="chain", name="normalize_city")
def normalize_city(raw: str) -> str:
    return raw.strip().replace("시", "")

@traceable(run_type="chain", name="weather-pipeline")
def run_weather(user_text: str) -> str:
    city = normalize_city(user_text)
    result = agent.invoke(
        {"messages": [{"role": "user", "content": f"{city} 날씨"}]},
    )
    return result["messages"][-1].content

run_weather("부산시")
`````)

UI에서 `weather-pipeline`이 루트, 그 아래 `normalize_city`와 `AgentExecutor`가 자식으로 묶인 하나의 트리로 보입니다.

== 1.5 트레이스를 코드에서 다시 조회

`langsmith.Client`로 UI 없이도 트레이스를 프로그램적으로 꺼낼 수 있습니다. 회귀 테스트의 입력, 야간 배치 리포트의 원천 데이터, 데이터셋 빌드의 시드로 사용됩니다.

#code-block(`````python
from langsmith import Client

client = Client()

runs = list(
    client.list_runs(
        project_name="langsmith-quickstart",
        filter='and(has(tags, "env:dev"), eq(is_root, true))',
        limit=10,
    )
)

for r in runs:
    print(r.id, r.name, r.total_tokens, r.total_cost)
`````)

`filter` 표현식은 UI의 `Add filter`가 만들어내는 것과 동일한 DSL을 그대로 씁니다.

== 1.6 비용 · 토큰 집계

UI 프로젝트 페이지 우상단의 _Analytics_ 탭에서 프로젝트 단위 총 비용/토큰 시계열을 볼 수 있습니다. 모델별 단가는 LangSmith가 자동으로 계산해 `total_cost` 필드에 채우며, 자체 호스팅 모델의 경우 _Settings → Model pricing_ 에서 단가를 커스텀할 수 있습니다.

== 1.7 API 키 재발급

온보딩 이후 키를 재발급하거나 revoke하려면 _Settings → Access and Security → API Keys_ 로 이동합니다. 기존 키는 Last Used At 정보가 자동으로 기록되므로, 유출 의심 시 즉시 revoke 후 새 키를 발급합니다.

#figure(image("../../../assets/images/langsmith/01_quickstart/09_settings_api_keys.png", width: 95%), caption: [Settings > API Keys — 테이블의 Key 컬럼은 자동으로 앞뒤만 표시되고 Last Used At이 기록됨])

== 핵심 정리

- 환경변수 세 줄(`LANGSMITH_API_KEY`, `LANGSMITH_TRACING=true`, `LANGSMITH_PROJECT`)로 기존 에이전트가 자동 트레이싱된다
- `run_name` · `tags` · `metadata`로 UI 필터와 `client.list_runs(filter=...)` 질의에 걸리게 한다
- `@traceable`로 LangChain 외부 함수도 같은 트레이스 트리에 편입한다
- `langsmith.Client`로 UI 없이 프로그램적으로 트레이스를 꺼내 평가·회귀 테스트의 시드로 쓴다
- UI의 Projects/Runs/Trace 트리 3단계로 "어떤 호출이 왜 이렇게 나왔는가"를 재현한다
