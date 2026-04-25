// Source: 06_langsmith/05_production_monitoring.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "프로덕션 모니터링", subtitle: "대시보드 · 알림 · 샘플링 · PII")

프로덕션은 "트레이스 한 번 잘 찍어보자"가 아니라 _실시간 대시보드 + 자동 평가 + 알림 + 개인정보 방어_가 같이 돌아야 합니다. 이 장은 배포 후에 필요한 LangSmith 기능을 운영 관점에서 묶습니다 — Monitoring 대시보드, autoeval rule, 사용자 feedback API, 알림 룰, 샘플링, PII 스크러빙, Slack/PagerDuty 웹훅 연동까지.

#learning-header()
#learning-objectives(
  [프로젝트 대시보드(Overview/Analytics)에서 latency p50/p95, cost, 성공률을 읽는다],
  [Online evaluator를 자동 실행되는 autoeval rule로 등록한다],
  [앱에서 `client.create_feedback(run_id, ...)`로 사용자 thumbs/별점을 전송한다],
  [Metadata 기반 알림 룰(실패율 > N% → webhook)을 이해한다],
  [고볼륨 프로덕션에서 `LANGSMITH_TRACING_SAMPLING_RATE`로 샘플링한다],
  [`PIIMiddleware`와 `hide_inputs`/`anonymizer`로 이중 방어한다],
  [Slack / PagerDuty 웹훅 수신 패턴을 구성한다],
)

== 5.1 프로젝트 대시보드

UI의 프로젝트 페이지에는 기본 3개 탭이 있습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[탭],
  text(weight: "bold")[보는 것],
  text(weight: "bold")[알림 연결],
  [*Runs*],
  [trace 목록, 필터, 빠른 검색],
  [—],
  [*Monitor*],
  [latency p50·p95·p99, 성공률, error 분포, token/cost 시계열],
  [Rules로 임계 알림],
  [*Evaluators*],
  [부착된 online evaluator와 score 분포],
  [특정 key 점수 하락 알림],
)

대시보드를 _직접 만들고 싶다면_ `Dashboards`에서 커스텀 차트를 묶을 수 있습니다. 같은 지표를 `client.list_runs`로 뽑아 Grafana 같은 사내 시스템에 붙여도 됩니다.

#figure(image("../../../assets/images/langsmith/05_production_monitoring/01_monitoring_dashboards_list.png", width: 95%), caption: [Project Monitoring Dashboards — 6개 탭(Traces / LLM Calls / Cost & Tokens / Tools / Run Types / Feedback Scores) × 기간])

== 5.2 Online evaluator — autoeval rule

3장에서 UI로 붙이는 흐름을 봤다면, 여기선 _운영 관점 설계_입니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[역할],
  text(weight: "bold")[설정 예],
  [실시간 품질 게이지],
  [`has(tags, "env:prod")`인 run에 LLM-as-judge(`useful` score 0~1)],
  [비용 관리],
  [Sampling rate 0.05로 5%만 평가],
  [회귀 감지],
  [`useful` score 평균이 N% 이하로 떨어지면 Rules에서 webhook 트리거],
  [특정 유즈케이스],
  [`metadata.feature == "checkout"`인 run에만 평가 붙이기],
)

autoeval 결과는 feedback key로 저장되므로, 알림 룰·대시보드·Experiments 비교에 모두 재사용됩니다.

#figure(image("../../../assets/images/langsmith/05_production_monitoring/03_automations_tab.png", width: 95%), caption: [프로젝트 > Automations 탭 — `+ Automation`으로 조건(Feedback score < 0.5) → 액션(dataset 이관 / 웹훅 / annotation queue) 정의])

== 5.3 사용자 feedback 수집 API

앱 UI의 thumbs-up / 별점 / "이 답 도움 안 됨" 버튼 → 서버에서 `client.create_feedback` 호출이 정석 패턴입니다. 클라이언트가 기다리지 않도록 *background*로 쏩니다 (Python SDK는 `trace_id`를 주면 자동 백그라운드).

#code-block(`````python
from langsmith import Client

client = Client()
client.create_feedback(
    trace_id=trace_id,
    key="user_thumbs",
    score=1.0,
    comment="정답",
)
`````)

== 5.4 Metadata 기반 알림 룰

UI의 프로젝트 → *Rules* 탭에서 다음 액션들을 조합합니다.

- `Add to annotation queue` (사람 리뷰)
- `Add to dataset` (골든셋 축적)
- `Trigger webhook` (Slack, PagerDuty, 자체 incident 시스템)
- `Extend data retention` (중요 trace 보존 연장)
- `Run online evaluator` (조건부 품질 평가)

*필터 표현식 예*

#code-block(`````text
and(
  has(tags, "env:prod"),
  eq(status, "error")
)
`````)

액션 실행 순서(LangSmith 고정): annotation queue → dataset → webhook → online evaluator → code evaluator → alert. 샘플링 비율도 룰 단위로 다르게 줄 수 있습니다 (예: 0.5 = 매칭의 50%).

#figure(image("../../../assets/images/langsmith/05_production_monitoring/02_alerts_page.png", width: 95%), caption: [Monitoring > Alerts — 조직 전체 알림 규칙 허브. `Create Alert` 클릭 시 모달 노출])

#figure(image("../../../assets/images/langsmith/05_production_monitoring/05_create_alert_modal.png", width: 95%), caption: [Create Alert 모달 — Tracing project 선택 후 조건(에러율/지연/피드백 변화) 지정 → webhook URL 전송])

== 5.5 고볼륨 샘플링

초당 수백 요청이 되면 모든 trace를 보내는 건 비용·네트워크 낭비입니다. 두 층으로 제어합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[층위],
  text(weight: "bold")[수단],
  text(weight: "bold")[특성],
  [프로세스 전체],
  [`LANGSMITH_TRACING_SAMPLING_RATE=0.1`],
  [`@traceable`, `RunTree`, 자동 계측 모두 적용],
  [요청별],
  [`Client(tracing_sampling_rate=...)` + `tracing_context`],
  [관리자/결제 등 중요 요청만 100%],
)

조합하면 "일반 트래픽은 10%, 결제 트래픽은 100%" 같은 운영 정책을 구현할 수 있습니다.

== 5.6 PII 스크러빙

두 레이어로 방어합니다.

+ *모델 입력 단계*: `langchain.agents.middleware.PIIMiddleware`가 LLM에 전달되는 메시지에서 이메일·카드번호·API 키를 차단/마스킹 — 모델 자체가 PII를 보지 않게 합니다
+ *트레이스 전송 단계*: LangSmith 클라이언트의 `hide_inputs`/`hide_outputs` 또는 `anonymizer`가 서버로 올라가는 input/output에서 한 번 더 씻어냅니다

둘 다 걸어야 "모델에 들어갔지만 트레이스엔 안 남는" 혹은 "모델은 못 봤지만 trace에 남았다" 같은 구멍이 없습니다.

#code-block(`````dotenv
# .env
LANGSMITH_HIDE_INPUTS=true
LANGSMITH_HIDE_OUTPUTS=true
`````)

== 5.7 Slack / PagerDuty 웹훅 연동

Rules의 webhook 액션은 설정한 URL로 POST 페이로드를 쏩니다. 받는 쪽에서 Slack/PagerDuty 포맷으로 변환해 알림을 띄웁니다.

#code-block(`````python
from fastapi import FastAPI, Request
import httpx, os

app = FastAPI()
SLACK_URL     = os.environ["SLACK_INCOMING_WEBHOOK"]
PAGERDUTY_URL = os.environ.get("PAGERDUTY_EVENTS_V2_URL")

@app.post("/langsmith/alert")
async def on_alert(req: Request):
    event = await req.json()
    run_id  = event.get("run_id") or event.get("trace_id")
    status  = event.get("status", "unknown")
    tags    = event.get("tags", [])
    trace_url = f"https://smith.langchain.com/o/-/projects/-/r/{run_id}"

    async with httpx.AsyncClient() as hc:
        await hc.post(SLACK_URL, json={
            "text": f":rotating_light: LangSmith alert — status={status} tags={tags}\n<{trace_url}|trace 열기>",
        })
        if PAGERDUTY_URL and "critical" in tags:
            await hc.post(PAGERDUTY_URL, json={
                "routing_key": os.environ["PAGERDUTY_ROUTING_KEY"],
                "event_action": "trigger",
                "payload": {"summary": f"LangSmith {status}", "severity": "error", "source": "langsmith"},
            })
    return {"ok": True}
`````)

UI의 Rules에서 이 엔드포인트 URL을 webhook 대상으로 등록하고, 필터를 `and(has(tags, "env:prod"), eq(status, "error"))`로 잡으면 프로덕션 에러만 Slack으로 뜹니다.

== 5.8 Insights Agent (유료)

프로젝트 > Insights 탭 — LangSmith의 *Insights Agent*로 production trace에서 usage pattern / common failure modes를 자동 추출합니다. 무료 플랜은 upgrade가 필요합니다.

#figure(image("../../../assets/images/langsmith/05_production_monitoring/04_insights_tab.png", width: 95%), caption: [Insights 탭 — Upgrade required 상태. 유료 플랜에서 production trace 자동 분석])

== 핵심 정리

- 대시보드·Evaluators·Automations 세 탭이 프로덕션 관측의 기본축
- Online evaluator + Rules webhook이 "실시간 품질 → 알림" 연결 고리
- 사용자 feedback은 background로 쏘고, `key`별로 점수 추이를 대시보드에 노출
- 샘플링은 전역(환경 변수) + 요청별(`tracing_context`) 두 층 조합
- PII는 `PIIMiddleware`(모델) + `anonymizer`/`hide_inputs`(트레이스) 이중 방어
- Webhook 수신 서비스가 Slack/PagerDuty로 라우팅 — 필터는 `env:prod` + `status=error` 조합이 기본
