// Source: docs/deepagents/12-async-subagents.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "비동기 서브에이전트", subtitle: "AsyncSubAgent · Non-blocking · Mid-flight steering")

Deep Agents 0.5.0의 플래그십 기능 `AsyncSubAgentMiddleware`는 슈퍼바이저가 블록되지 않고 서브에이전트를 백그라운드로 기동합니다. 장시간 리서치·코딩·병렬 서브에이전트 조율처럼 _수 분에서 수 시간 단위_ 작업에서 기존 동기 서브에이전트의 한계를 넘는 인프라입니다. 단, 이 기능은 _Agent Protocol 서버_가 필요합니다 — LangSmith Deployments 또는 `langgraph dev` 같은 자체 호스트 환경에서만 동작합니다.

#learning-header()
#learning-objectives(
  [동기 서브에이전트와 `AsyncSubAgent`의 실행 모델 차이를 설명한다],
  [`start_async_task` / `check_async_task` / `update_async_task` / `cancel_async_task` / `list_async_tasks` 5개 도구의 역할을 구분한다],
  [ASGI(co-deploy)와 HTTP(원격) 전송 모드를 비교하고 하이브리드 구성을 만든다],
  [`async_tasks` state 채널이 컨텍스트 압축을 넘어 상태를 보존하는 원리를 이해한다],
  [Mid-flight steering 패턴(update/cancel)과 `--n-jobs-per-worker` 슬롯 튜닝을 안다],
)

== 11.1 기존 동기 서브에이전트의 한계

기존 서브에이전트는 _동기_였습니다. `task` 도구가 호출되면 슈퍼바이저는 서브에이전트가 끝날 때까지 멈추고, 사용자는 그 동안 새 지시를 줄 수 없었습니다. 분 단위 이상의 리서치 작업을 동기로 돌리면 프런트엔드가 응답 없이 굳어 있고, 사용자는 "아직 살아 있는가"를 확인할 방법이 없었습니다.

0.5.0의 `AsyncSubAgentMiddleware`는 이 제약을 제거합니다.

- *Non-blocking 실행*: `start_async_task`가 task id만 즉시 반환. 슈퍼바이저는 곧바로 사용자와 대화를 계속합니다.
- *Mid-flight steering*: 실행 중인 서브에이전트에 follow-up 지시를 보내거나 취소할 수 있습니다.
- *독립 스레드*: 각 서브에이전트 태스크는 자체 thread와 run을 가집니다. 슈퍼바이저의 컨텍스트 압축이 일어나도 상태가 손실되지 않습니다.

== 11.2 슈퍼바이저에게 주입되는 5개 도구

`AsyncSubAgentMiddleware`는 슈퍼바이저에게 다섯 개 도구를 주입합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[역할],
  [`start_async_task`],
  [서브에이전트 백그라운드 기동. task id 즉시 반환],
  [`check_async_task`],
  [현재 상태 조회, 완료되었으면 최종 출력 추출],
  [`update_async_task`],
  [실행 중인 태스크의 같은 스레드에 새 지시 주입 (interrupt 전략)],
  [`cancel_async_task`],
  [서버에 cancel 신호 전송, 태스크를 `cancelled`로 마킹],
  [`list_async_tasks`],
  [추적 중인 모든 태스크의 현재 상태 일괄 조회],
)

== 11.3 기본 사용

`AsyncSubAgent` 스펙 리스트를 `subagents`에 전달하면 `create_deep_agent`가 `AsyncSubAgentMiddleware`를 자동 부착합니다.

#code-block(`````python
from deepagents import AsyncSubAgent, create_deep_agent

async_subagents = [
    AsyncSubAgent(
        name="researcher",
        description="정보 수집과 종합이 필요한 리서치 작업",
        graph_id="researcher",
    ),
    AsyncSubAgent(
        name="coder",
        description="코드 생성/리뷰 작업",
        graph_id="coder",
        url="https://coder-deployment.langsmith.dev",  # 원격 HTTP 호출
    ),
]

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    subagents=async_subagents,
)
`````)

=== AsyncSubAgent 핵심 필드

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필드],
  text(weight: "bold")[설명],
  [`name`],
  [슈퍼바이저가 참조하는 고유 식별자],
  [`description`],
  [어떤 태스크에 위임할지 판단 근거. 동기 서브에이전트와 동일하게 중요],
  [`graph_id`],
  [`langgraph.json`의 graph 이름과 일치해야 함],
  [`url`],
  [선택. 없으면 ASGI(in-process), 있으면 원격 HTTP 호출],
  [`headers`],
  [선택. 자체 호스트 서버의 인증 헤더],
)

== 11.4 `async_tasks` state 채널

태스크 메타데이터는 메시지 히스토리와 _분리된_ `async_tasks` state 채널에 저장됩니다. 레코드 하나에는 다음이 들어갑니다:

- task id
- agent name
- thread id, run id
- status (`pending` / `running` / `success` / `error` / `cancelled`)
- `created_at`, `updated_at`

이 분리 구조 덕분에 슈퍼바이저의 컨텍스트가 압축(summarization)되어 오래된 메시지가 요약으로 대체되어도 _task id는 사라지지 않습니다_. 압축 후에도 `check_async_task` / `update_async_task`를 그대로 호출할 수 있습니다.

#warning-box[커스텀 state reducer나 middleware로 state를 재구성할 때 `async_tasks` 채널을 덮어쓰면 실행 중인 태스크 추적을 잃습니다. 병합 전략을 명시하세요.]

== 11.5 전송 모드

=== ASGI (co-deploy, 기본 권장)

`url`을 생략하면 서브에이전트가 슈퍼바이저와 _같은 프로세스_에서 함수 호출로 실행됩니다. 네트워크 레이턴시 없이, 동일 `langgraph.json`에 두 그래프를 등록합니다.

#code-block(`````json
// langgraph.json
{
  "dependencies": ["."],
  "graphs": {
    "supervisor": "./agent.py:supervisor",
    "researcher": "./subagents/researcher.py:graph",
    "coder": "./subagents/coder.py:graph"
  },
  "env": ".env"
}
`````)

#code-block(`````python
AsyncSubAgent(
    name="researcher",
    description="...",
    graph_id="researcher",   # url 없음 → ASGI
)
`````)

=== HTTP (원격)

독립 배포된 서브에이전트를 `url`로 호출합니다. 리서치 전용 저가 모델, 코딩 전용 GPU 배포처럼 _리소스 프로파일이 다른_ 서브에이전트를 따로 스케일하고 싶을 때 씁니다.

#code-block(`````python
import os

AsyncSubAgent(
    name="coder",
    description="...",
    graph_id="coder",
    url="https://coder-deployment.langsmith.dev",
    headers={"x-api-key": os.environ["CODER_API_KEY"]},
)
`````)

=== 하이브리드

둘을 섞어도 됩니다. 경량 서브에이전트는 ASGI, 리소스 집약 서브에이전트는 원격 HTTP로 배포 토폴로지를 워크로드에 맞게 나눕니다.

== 11.6 실행 라이프사이클

+ *Launch* — `start_async_task`가 새 thread 생성, run 시작, task id 즉시 반환
+ *Check* — `check_async_task`가 상태 조회, 완료 시 최종 출력 추출
+ *Update* — `update_async_task`가 기존 thread에 history를 유지한 채 새 instruction으로 interrupt 기반 새 run 기동
+ *Cancel* — `cancel_async_task`가 `runs.cancel()` 호출 후 cancelled로 마킹
+ *List* — 비종결 태스크의 live status를 병렬 조회, 종결된 건 캐시 반환

== 11.7 Mid-flight steering 패턴

대화 도중 사용자가 방향을 바꾸면 슈퍼바이저가 `update_async_task`를 호출합니다.

#code-block(`````text
사용자: 경쟁사 리서치 시작해줘.
슈퍼바이저: [start_async_task(agent="researcher", ...)] → task_abc123

사용자: 아, Series A 이상만 봐줘.
슈퍼바이저: [update_async_task(task_id="task_abc123",
                               instruction="범위를 Series A 이상으로 좁혀줘")]

사용자: 그만, 대신 SaaS 쪽으로 다시 파줘.
슈퍼바이저: [cancel_async_task(task_id="task_abc123")]
           [start_async_task(agent="researcher",
                             description="SaaS 경쟁사 리서치")]
`````)

`update_async_task`는 _같은 스레드_에 새 run을 만들므로, 서브에이전트는 이전 탐색 결과를 그대로 이어받고 새 지시만 얹습니다. 완전히 새 태스크로 시작할 때만 cancel + start 조합을 씁니다.

== 11.8 로컬 개발: `--n-jobs-per-worker`

`langgraph dev`의 기본 worker pool은 작아서 동시 서브에이전트 기동 시 큐잉이 발생합니다. 슬롯 수를 늘려 줍니다.

#code-block(`````bash
langgraph dev --n-jobs-per-worker 10
`````)

서브에이전트 3개를 동시에 돌리는 슈퍼바이저는 최소 *4 슬롯*이 필요합니다(슈퍼바이저 1 + 서브에이전트 3). 여유 있게 10~20으로 잡아 두세요.

== 11.9 동기 vs 비동기 선택 기준

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[축],
  text(weight: "bold")[Sync SubAgent],
  text(weight: "bold")[AsyncSubAgent],
  [실행],
  [슈퍼바이저 블록, 완료까지 대기],
  [즉시 task id 반환, 슈퍼바이저 계속 진행],
  [결과 회수],
  [자동으로 슈퍼바이저에 반환],
  [`check_async_task`로 폴링 필요],
  [Mid-task 지시],
  [불가],
  [`update_async_task`로 가능],
  [취소],
  [불가],
  [`cancel_async_task`로 가능],
  [상태 유지],
  [스테이트리스 (일회성)],
  [자체 thread에 상태 유지, 상호작용 가능],
  [인프라 요구],
  [특별 요구 없음],
  [Agent Protocol 서버 필요],
  [적합 작업],
  [수초~수십초, 결과만 필요한 작업],
  [분~시간 단위 장시간, 중간 개입 가능한 작업],
)

*판단 흐름*

- 작업이 수초 내 끝나고 슈퍼바이저가 결과를 바로 써야 한다 → *Sync*
- 작업이 수 분 이상이거나, 여러 서브에이전트를 _병렬_로 돌리고 싶다 → *Async*
- 사용자가 도중에 방향을 바꾸거나 중단시킬 수 있다 → *Async*
- LangSmith Deployments를 쓰지 않고 Agent Protocol 서버도 띄울 수 없다 → *Sync만 가능*

== 11.10 주의사항

- *Agent Protocol 의존성*: `AsyncSubAgent`를 선언했는데 실행 환경이 Agent Protocol을 지원하지 않으면 초기화 단계에서 실패
- *`async_tasks` 채널은 보존하라*: 커스텀 state reducer나 middleware로 state를 재구성할 때 이 채널을 덮어쓰면 추적 상실
- *폴링 비용*: `check_async_task`를 너무 자주 호출하지 않도록 시스템 프롬프트에 가이드를 넣음 (예: "한 번에 2~3개 태스크를 기동한 뒤 사용자 반응을 기다려라")
- *장시간 태스크 정리*: 장기 미종결 태스크는 `list_async_tasks` + `cancel_async_task`로 정기적으로 정리. LangSmith Deployments는 checkpoint 기반이라 비용이 남음
- *HTTP 모드 타임아웃*: 원격 URL은 헤더·네트워크 타임아웃·재시도 정책을 별도로 확인

== 핵심 정리

- `AsyncSubAgent`는 슈퍼바이저를 블록하지 않고 서브에이전트를 백그라운드로 기동하는 0.5.0 플래그십 기능
- 5개 도구(`start` / `check` / `update` / `cancel` / `list`)로 라이프사이클을 제어
- ASGI는 co-deploy 기본, HTTP는 리소스 분리 시 사용, 하이브리드 가능
- `async_tasks` state 채널이 컨텍스트 압축에도 태스크 추적을 유지
- 수 분 이상 걸리거나 사용자 개입이 필요한 작업, 다중 병렬 서브에이전트에 적합
