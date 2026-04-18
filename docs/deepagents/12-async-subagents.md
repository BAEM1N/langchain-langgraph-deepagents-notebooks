# Async Subagents

> Deep Agents 0.5.0의 플래그십 기능. 슈퍼바이저가 블록되지 않고 서브에이전트를 백그라운드로 기동해 장시간 작업을 병렬 진행하며, 대화 중에도 새 지시를 밀어 넣거나 취소할 수 있다.
> 장시간 리서치·코딩·병렬 서브에이전트 조율이 필요할 때 읽는다.

## 개요

기존 서브에이전트는 **동기**였다. `task` 도구가 호출되면 슈퍼바이저는 서브에이전트가 끝날 때까지 멈춰 있고, 사용자는 그 시간 동안 새 지시를 줄 수 없었다. 0.5.0의 `AsyncSubAgentMiddleware`는 이 제약을 제거한다.

- **Non-blocking 실행**: `start_async_task`가 task id만 즉시 반환. 슈퍼바이저는 곧바로 사용자와 대화를 계속한다.
- **Mid-flight steering**: 실행 중인 서브에이전트에 follow-up 지시를 보내거나 취소할 수 있다.
- **독립 스레드**: 각 서브에이전트 태스크는 자체 thread와 run을 가진다. 슈퍼바이저의 컨텍스트 압축이 일어나도 상태가 손실되지 않는다.

단, 이 기능은 **Agent Protocol 서버**가 필요하다. LangSmith Deployments 또는 Agent Protocol 호환 자체 호스트 환경(예: `langgraph dev`) 위에서만 동작한다.

## 5 supervisor tools

`AsyncSubAgentMiddleware`가 슈퍼바이저에게 주입하는 도구는 다섯 개다.

| 도구 | 역할 |
|------|------|
| `start_async_task` | 서브에이전트 백그라운드 기동. task id 즉시 반환 |
| `check_async_task` | 현재 상태 조회, 완료되었으면 최종 출력 추출 |
| `update_async_task` | 실행 중인 태스크의 같은 스레드에 새 지시 주입 (interrupt 전략) |
| `cancel_async_task` | 서버에 cancel 신호 전송, 태스크를 `cancelled`로 마킹 |
| `list_async_tasks` | 추적 중인 모든 태스크의 현재 상태 일괄 조회 |

## 기본 사용

`AsyncSubAgent` 스펙 리스트를 `subagents`에 전달하면 `create_deep_agent`가 `AsyncSubAgentMiddleware`를 자동 부착한다.

```python
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
```

### AsyncSubAgent 핵심 필드

| 필드 | 설명 |
|------|------|
| `name` | 슈퍼바이저가 참조하는 고유 식별자 |
| `description` | 어떤 태스크에 위임할지 판단 근거. 동기 서브에이전트와 동일하게 중요 |
| `graph_id` | `langgraph.json`의 graph 이름과 일치해야 함 |
| `url` | 선택. 없으면 ASGI(in-process), 있으면 원격 HTTP 호출 |
| `headers` | 선택. 자체 호스트 서버의 인증 헤더 |

## `async_tasks` state channel

태스크 메타데이터는 메시지 히스토리와 **분리된** `async_tasks` state 채널에 저장된다. 각 레코드는 다음을 담는다:

- task id
- agent name
- thread id, run id
- status (`pending` / `running` / `success` / `error` / `cancelled`)
- created_at, updated_at

이 분리 설계 덕분에 슈퍼바이저의 컨텍스트가 압축(summarization)되어 오래된 메시지가 요약으로 대체되어도 **task id가 손실되지 않는다**. 압축 후에도 `check_async_task` / `update_async_task`를 정상 호출할 수 있다.

## 전송 모드

### ASGI (co-deploy, 기본 권장)

`url`을 생략하면 서브에이전트가 슈퍼바이저와 **같은 프로세스**에서 함수 호출처럼 실행된다. 네트워크 레이턴시 제로, 동일 `langgraph.json`에 두 그래프를 등록한다.

```json
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
```

```python
AsyncSubAgent(
    name="researcher",
    description="...",
    graph_id="researcher",   # url 없음 → ASGI
)
```

### HTTP (원격)

독립 배포된 서브에이전트를 `url`로 호출한다. 리서치 전용 저가 모델 배포, 코딩 전용 GPU 배포처럼 **리소스 프로파일이 다른** 서브에이전트를 따로 스케일할 때 쓴다.

```python
AsyncSubAgent(
    name="coder",
    description="...",
    graph_id="coder",
    url="https://coder-deployment.langsmith.dev",
    headers={"x-api-key": os.environ["CODER_API_KEY"]},
)
```

### 하이브리드

둘을 섞을 수 있다. 경량 서브에이전트는 ASGI, 리소스 집약 서브에이전트는 원격 HTTP.

## 실행 라이프사이클

1. **Launch** — `start_async_task`가 새 thread 생성, run 시작, task id 즉시 반환
2. **Check** — `check_async_task`가 상태 조회, 완료 시 최종 출력 추출
3. **Update** — `update_async_task`가 기존 thread에 history를 유지한 채 새 instruction으로 interrupt 기반 새 run 기동
4. **Cancel** — `cancel_async_task`가 `runs.cancel()` 호출 후 cancelled로 마킹
5. **List** — 비종결 태스크의 live status를 병렬 조회, 종결된 건 캐시 반환

## Mid-flight steering 패턴

대화 도중 사용자가 방향을 바꾸면 슈퍼바이저가 `update_async_task`를 호출한다.

```
사용자: 경쟁사 리서치 시작해줘.
슈퍼바이저: [start_async_task(agent="researcher", ...)] → task_abc123

사용자: 아, Series A 이상만 봐줘.
슈퍼바이저: [update_async_task(task_id="task_abc123",
                               instruction="범위를 Series A 이상으로 좁혀줘")]

사용자: 그만, 대신 SaaS 쪽으로 다시 파줘.
슈퍼바이저: [cancel_async_task(task_id="task_abc123")]
           [start_async_task(agent="researcher",
                             description="SaaS 경쟁사 리서치")]
```

`update_async_task`는 **같은 스레드**에 새 run을 만들기 때문에 서브에이전트는 이전까지의 탐색 결과를 그대로 이어받고, 새 지시만 얹는다. 완전히 새 태스크로 시작하고 싶을 때만 cancel + start 조합을 쓴다.

## 로컬 개발: `--n-jobs-per-worker`

`langgraph dev`의 기본 worker pool은 작아서 동시 서브에이전트 기동 시 큐잉이 발생한다. 슬롯 수를 늘려 준다.

```bash
langgraph dev --n-jobs-per-worker 10
```

동시 서브에이전트 3개를 돌리는 슈퍼바이저는 최소 **4 슬롯**이 필요하다(슈퍼바이저 1 + 서브에이전트 3). 여유 있게 10~20으로 잡는 것을 권장한다.

## 동기 vs 비동기 선택 기준

| 축 | Sync SubAgent | AsyncSubAgent |
|----|---------------|---------------|
| 실행 | 슈퍼바이저 블록, 완료까지 대기 | 즉시 task id 반환, 슈퍼바이저 계속 진행 |
| 결과 회수 | 자동으로 슈퍼바이저에 반환 | `check_async_task`로 폴링 필요 |
| Mid-task 지시 | 불가 | `update_async_task`로 가능 |
| 취소 | 불가 | `cancel_async_task`로 가능 |
| 상태 유지 | 스테이트리스(일회성) | 자체 thread에 상태 유지, 상호작용 가능 |
| 인프라 요구 | 특별 요구 없음 | Agent Protocol 서버(LangSmith Deployments 등) |
| 적합 작업 | 수초~수십초, 결과만 필요한 작업 | 분~시간 단위 장시간, 중간 개입 가능한 작업 |

**판단 흐름**

- 작업이 수초 내 끝나고 슈퍼바이저가 결과를 바로 써야 한다 → **Sync**
- 작업이 수 분 이상이거나, 여러 서브에이전트를 **병렬**로 돌리고 싶다 → **Async**
- 사용자가 도중에 방향을 바꾸거나 중단시킬 수 있다 → **Async**
- LangSmith Deployments를 쓰지 않고 Agent Protocol 서버도 띄울 수 없다 → **Sync만 가능**

## 주의사항

- **Agent Protocol 의존성**: `AsyncSubAgent`를 선언했는데 실행 환경이 Agent Protocol을 지원하지 않으면 초기화 단계에서 실패한다.
- **`async_tasks` 채널은 보존하라**: 커스텀 state reducer나 middleware로 state를 재구성할 때 이 채널을 덮어쓰면 실행 중인 태스크 추적을 잃는다.
- **폴링 비용**: `check_async_task`를 너무 자주 호출하지 않도록 시스템 프롬프트에 가이드를 넣는다(예: "한 번에 2~3개 태스크를 기동한 뒤 사용자 반응을 기다려라").
- **장시간 태스크 정리**: 장기 미종결 태스크는 `list_async_tasks` + `cancel_async_task`로 정기적으로 정리한다. LangSmith Deployments는 checkpoint 기반이라 비용이 남아 있다.
- **HTTP 모드 타임아웃**: 원격 URL은 헤더·네트워크 타임아웃·재시도 정책을 별도로 확인한다.

## 관련 문서

- `07-subagents.md` — 동기 서브에이전트, 일반 서브에이전트 개념
- `13-going-to-production.md` — LangSmith Deployments, Agent Protocol 배포 맥락
- `15-streaming.md` — 서브에이전트 실행을 프런트엔드에 실시간 노출하기
- `14-context-engineering.md` — 컨텍스트 압축과 서브에이전트 격리 전략
