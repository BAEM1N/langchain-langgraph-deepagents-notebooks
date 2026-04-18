# Going to Production

> 로컬 프로토타입을 다중 사용자·다중 테넌트·장기 운영 가능한 프로덕션 에이전트로 전환할 때 짚어야 할 10가지 영역.
> Deep Agent를 실서비스에 올리기 직전, 또는 이미 올렸지만 운영 이슈를 정리할 때 읽는다.

## 개요

프로덕션 Deep Agent는 세 가지 핵심 추상 위에서 운영된다.

- **Thread** — 한 번의 대화. 메시지·파일·체크포인트의 단위.
- **User** — 인증된 신원. 자원 소유권과 접근 범위의 단위.
- **Assistant** — 설정된 에이전트 인스턴스(프롬프트·도구·모델 조합).

이 세 개념 위에서 관리해야 할 영역이 다음 10개다. 각 영역은 독립적으로 도입 가능하며, 리스크 프로파일에 따라 선택적으로 적용한다.

## 1. LangSmith Deployments

`deepagents deploy` CLI 또는 LangSmith Deployment를 통해 배포하면 다음 인프라가 자동 프로비저닝된다.

- Assistants / Threads / Runs API
- Store + Checkpointer (퍼시스턴스)
- 인증, Webhook, Cron, Observability
- MCP/A2A 노출 옵션

`langgraph.json` 최소 설정:

```json
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./agent.py:agent"
  },
  "env": ".env"
}
```

- `dependencies`: 패키지 설치 대상
- `graphs`: graph id → 코드 매핑
- `env`: 시크릿 파일 경로

## 2. Multi-tenant access control

### 커스텀 auth/authz 핸들러

LangSmith Deployments는 커스텀 인증으로 사용자 신원을 확립하고, 별도 authorization 핸들러로 thread / assistant / store namespace 접근을 제어한다. 핸들러는 다음을 할 수 있다.

- 리소스에 소유권 메타데이터 태깅
- 사용자별 가시성으로 리소스 필터링
- HTTP 403으로 접근 거부

### Workspace RBAC

팀 단위 권한(LangSmith 자체 기능).

| 역할 | 권한 |
|------|------|
| Workspace Admin | 전체 권한 |
| Workspace Editor | 생성/수정, 삭제·멤버 관리 불가 |
| Workspace Viewer | 읽기 전용 |

## 3. End-user credential management

에이전트가 사용자 대신 외부 서비스(GitHub, Slack, Gmail 등)를 호출해야 할 때 자격증명을 **에이전트 코드 밖에서** 관리한다.

### OAuth via Agent Auth

관리형 OAuth 2.0 플로우. 첫 호출 시 사용자에게 consent URL을 interrupt로 제시하고, 토큰 수신 후 자동으로 resume·refresh한다.

```python
from langchain_auth import Client
from langchain.tools import tool, ToolRuntime

auth_client = Client()

@tool
async def github_action(runtime: ToolRuntime):
    """사용자 명의로 GitHub 작업 수행."""
    auth_result = await auth_client.authenticate(
        provider="github",
        scopes=["repo", "read:org"],
        user_id=runtime.server_info.user.identity,
    )
    # auth_result.token으로 GitHub API 호출
```

### Sandbox Auth Proxy

샌드박스에서 실행되는 사용자 코드(또는 에이전트 생성 코드)가 외부 API를 호출할 때 프록시가 자격증명을 **주입**한다. API 키가 샌드박스 안 코드에 절대 노출되지 않는다.

```json
{
  "proxy_config": {
    "rules": [
      {
        "name": "openai-api",
        "match_hosts": ["api.openai.com"],
        "inject_headers": {
          "Authorization": "Bearer ${OPENAI_API_KEY}"
        }
      }
    ]
  }
}
```

`${SECRET_KEY}`는 워크스페이스 시크릿에서 해석된다.

## 4. Memory persistence scoping

`StoreBackend`의 `namespace` 함수로 메모리 범위를 결정한다. `CompositeBackend`가 `/memories/`만 `StoreBackend`로 라우팅하고 나머지는 `StateBackend` 휘발성을 유지하는 것이 기본 패턴.

### User-scoped (권장 기본값)

사용자별 개인 메모리. 서로 격리된다.

```python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(
                namespace=lambda rt: (
                    rt.server_info.assistant_id,
                    rt.server_info.user.identity,
                ),
            ),
        },
    ),
    system_prompt=(
        "대화 시작 시 /memories/instructions.txt를 읽어라. "
        "지속 가치 있는 인사이트는 갱신한다."
    ),
)
```

### Assistant-scoped

같은 assistant를 쓰는 모든 사용자가 공유.

```python
backend=CompositeBackend(
    default=StateBackend(),
    routes={
        "/memories/": StoreBackend(
            namespace=lambda rt: (rt.server_info.assistant_id,),
        ),
    },
)
```

### Organization-scoped

조직 전체 공유. **반드시 read-only를 권장한다.**

```python
routes={
    "/memories/": StoreBackend(
        namespace=lambda rt: (rt.context.org_id,),
    ),
}
```

> **Prompt injection 경고**: 공유 메모리는 프롬프트 인젝션 벡터다. 사용자가 조작 가능한 범위에 쓰기 권한을 주지 말 것. 자세한 정책은 `16-permissions.md` 참고.

## 5. Execution isolation

호스트 파일시스템·네트워크를 그대로 노출하지 말고 **샌드박스**를 쓴다.

### Thread-scoped sandbox (가장 흔한 패턴)

대화마다 새 샌드박스를 생성해 격리한다.

```python
from daytona import CreateSandboxFromSnapshotParams, Daytona
from deepagents import create_deep_agent
from langchain_core.runnables import RunnableConfig
from langchain_daytona import DaytonaSandbox

client = Daytona()

async def agent(config: RunnableConfig):
    thread_id = config["configurable"]["thread_id"]
    try:
        sandbox = await client.find_one(labels={"thread_id": thread_id})
    except Exception:
        sandbox = await client.create(
            CreateSandboxFromSnapshotParams(
                labels={"thread_id": thread_id},
                auto_delete_interval=3600,  # TTL
            )
        )
    return create_deep_agent(
        model="google_genai:gemini-3.1-pro-preview",
        backend=DaytonaSandbox(sandbox=sandbox),
    )
```

### Assistant-scoped sandbox

모든 스레드가 한 샌드박스를 공유해 도구 체인 캐시·설치물을 보존할 때.

```python
async def agent(config: RunnableConfig):
    assistant_id = config["configurable"]["assistant_id"]
    try:
        sandbox = await client.find_one(labels={"assistant_id": assistant_id})
    except Exception:
        sandbox = await client.create(
            CreateSandboxFromSnapshotParams(labels={"assistant_id": assistant_id})
        )
    return create_deep_agent(
        model="google_genai:gemini-3.1-pro-preview",
        backend=DaytonaSandbox(sandbox=sandbox),
    )
```

## 6. Resilience & durability

### 매 스텝 체크포인트

LangSmith Deployments는 자동으로 체크포인터를 붙인다. 매 스텝 상태가 저장되므로:

- **Indefinite interrupt**: HITL 승인 대기가 **며칠**이어도 정확히 멈춘 자리에서 재개
- **Time travel**: 임의 체크포인트 시점으로 되감아 분기 실행
- **Audit trail**: 결제·관리자 동작 같은 민감 연산 직전 상태 감사

```python
# invoke with thread_id — 중단돼도 동일 thread로 재개
await agent.ainvoke(
    {"messages": [...]},
    config={"configurable": {"thread_id": "thread-abc"}},
)
```

### Async I/O

LLM 앱은 I/O 바운드다. 비동기 도구·미들웨어 훅(`abefore_agent`, `astream`) 사용으로 처리량이 크게 증가한다.

## 7. Rate limiting & cost control

모델/도구 호출 횟수를 미들웨어로 제한한다.

```python
from deepagents import create_deep_agent
from langchain.agents.middleware import (
    ModelCallLimitMiddleware,
    ToolCallLimitMiddleware,
)

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    middleware=[
        ModelCallLimitMiddleware(run_limit=50),
        ToolCallLimitMiddleware(run_limit=200),
    ],
)
```

- `run_limit`: 한 번의 `invoke`마다 리셋
- `thread_limit`: 스레드 수명 동안 누적

폭주/무한 루프를 비용 폭탄이 되기 전에 차단한다.

## 8. Error handling strategy

오류는 3층으로 분류해 각기 다른 전략을 적용한다.

| 분류 | 예시 | 전략 | 미들웨어 |
|------|------|------|----------|
| Transient | 타임아웃, rate limit, 네트워크 일시 실패 | 자동 재시도(backoff) | `ModelRetryMiddleware`, `ToolRetryMiddleware` |
| Recoverable | 잘못된 도구 인자, 파싱 실패 | 모델에 피드백 → 재시도 | 도구 래퍼에서 에러 메시지 반환 |
| Human required | 권한 없음, 불명확한 요청 | 에이전트 일시 정지 | HITL `interrupt_on` |

```python
from langchain.agents.middleware import (
    ModelRetryMiddleware,
    ModelFallbackMiddleware,
    ToolRetryMiddleware,
)

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    middleware=[
        ModelRetryMiddleware(max_retries=3, backoff_factor=2.0, initial_delay=1.0),
        ModelFallbackMiddleware("gpt-4.1"),   # 다른 프로바이더로 fallback
        ToolRetryMiddleware(
            max_retries=2,
            tools=["search", "fetch_url"],
            retry_on=(TimeoutError, ConnectionError),
        ),
    ],
)
```

## 9. Data privacy (PIIMiddleware)

이메일·카드 번호·주민번호 등 PII를 입출력 경계에서 가공한다.

```python
from langchain.agents.middleware import PIIMiddleware

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    middleware=[
        PIIMiddleware("email", strategy="redact", apply_to_input=True),
        PIIMiddleware("credit_card", strategy="mask", apply_to_input=True),
    ],
)
```

전략: `redact`(삭제), `mask`(마스킹), `hash`(해시), `block`(차단). 커스텀 detector도 등록 가능.

로깅 대상에 PII가 섞이기 전에 입력 쪽에서 가공하는 것이 핵심. LangSmith 트레이스에도 마스킹된 상태로 기록된다.

## 10. Real-time frontend

`@langchain/react`의 `useStream` 훅으로 실시간 스트리밍·재연결·히스토리 로드를 한 번에 처리한다. Vue/Svelte/Angular용도 제공된다.

```tsx
import { useStream } from "@langchain/react";

function App() {
  const stream = useStream<typeof agent>({
    apiUrl: "https://your-deployment.langsmith.dev",
    assistantId: "agent",
    reconnectOnMount: true,     // 페이지 새로고침 후 진행 중 run 자동 이어받기
    fetchStateHistory: true,    // 재방문 사용자에게 과거 대화 전체 로드
  });
}
```

서브에이전트를 많이 띄우는 Deep Agent는 서브그래프 이벤트까지 스트리밍해 UI에 서브에이전트 진행 카드 형태로 노출한다.

```tsx
stream.submit(
  { messages: [{ type: "human", content: text }] },
  {
    streamSubgraphs: true,
    config: { recursionLimit: 10000 },
  },
);
```

- `reconnectOnMount`: 실행 중 새로고침·네트워크 단절을 자연스럽게 복구
- `fetchStateHistory`: 돌아온 사용자에게 즉시 대화 컨텍스트 복원
- `streamSubgraphs`: 서브에이전트 단위 렌더링 (상세는 `15-streaming.md`)

## 프로덕션 체크리스트

- [ ] `langgraph.json`에 graph·env가 선언되어 있다
- [ ] 사용자별 authz 핸들러가 thread/store에 적용된다
- [ ] 외부 서비스 토큰은 Agent Auth/Proxy로 관리되고 코드에 하드코딩되지 않는다
- [ ] `/memories/`는 `StoreBackend`로 라우팅되고 스코프가 명시적이다(user/assistant/org)
- [ ] 공유 메모리는 read-only이거나 쓰기 권한이 엄격히 제한된다
- [ ] 호스트 파일시스템·셸에 직접 노출되지 않고 샌드박스를 경유한다
- [ ] `ModelCallLimitMiddleware`/`ToolCallLimitMiddleware`로 비용 상한이 설정되어 있다
- [ ] 재시도·fallback·HITL이 전부 구성되어 있다
- [ ] PII가 입출력 경계에서 마스킹된다
- [ ] 프런트엔드가 `reconnectOnMount` + `fetchStateHistory`를 사용한다

## 관련 문서

- `06-backends.md` — 백엔드 종류
- `09-long-term-memory.md` — 메모리 스코프 심화
- `11-sandboxes.md` — 샌드박스 공급자별 통합
- `12-async-subagents.md` — LangSmith Deployments 위에서의 비동기 서브에이전트
- `15-streaming.md` — 프런트엔드 스트리밍 세부
- `16-permissions.md` — 파일시스템 접근 제어
