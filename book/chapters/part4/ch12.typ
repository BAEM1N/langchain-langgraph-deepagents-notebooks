// Source: docs/deepagents/13-going-to-production.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "프로덕션 준비", subtitle: "Thread · User · Assistant 기반 10대 영역")

로컬 프로토타입을 다중 사용자·다중 테넌트·장기 운영 가능한 프로덕션 에이전트로 전환할 때 짚어야 할 열 가지 영역을 다룹니다. Deep Agent를 실서비스에 올리기 직전, 또는 올렸는데 운영 이슈가 쌓일 때 이 장을 체크리스트로 씁니다.

#learning-header()
#learning-objectives(
  [Thread·User·Assistant 세 추상을 프로덕션 설계의 출발점으로 이해한다],
  [`langgraph.json` + LangSmith Deployments가 자동 프로비저닝하는 인프라를 안다],
  [멀티 테넌트 authz, 엔드유저 자격증명, 메모리 스코핑을 구분한다],
  [샌드박스 thread-scoped vs assistant-scoped 패턴을 선택한다],
  [내구성·레이트 리밋·에러 3층·PII·실시간 프런트엔드를 미들웨어와 SDK로 구성한다],
)

== 12.1 세 가지 핵심 추상

프로덕션 Deep Agent는 세 가지 핵심 추상 위에서 운영됩니다.

- *Thread* — 한 번의 대화. 메시지·파일·체크포인트의 단위
- *User* — 인증된 신원. 자원 소유권과 접근 범위의 단위
- *Assistant* — 설정된 에이전트 인스턴스 (프롬프트·도구·모델 조합)

이 세 개념 위에서 관리할 영역이 열 개이며, 각 영역은 독립적으로 도입할 수 있고 리스크 프로파일에 따라 골라 적용합니다.

== 12.2 LangSmith Deployments

`deepagents deploy` CLI 또는 LangSmith Deployment로 배포하면 다음 인프라가 자동 프로비저닝됩니다.

- Assistants / Threads / Runs API
- Store + Checkpointer (퍼시스턴스)
- 인증, Webhook, Cron, Observability
- MCP/A2A 노출 옵션

#code-block(`````json
// langgraph.json 최소 설정
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./agent.py:agent"
  },
  "env": ".env"
}
`````)

== 12.3 멀티 테넌트 접근 제어

=== 커스텀 auth/authz 핸들러

LangSmith Deployments는 커스텀 인증으로 사용자 신원을 확립하고, 별도 authorization 핸들러로 thread / assistant / store namespace 접근을 제어합니다. 핸들러는 리소스에 소유권 메타데이터를 태깅하고 사용자별 가시성을 필터링하며, HTTP 403으로 접근을 거부합니다.

=== Workspace RBAC

팀 단위 권한(LangSmith 자체 기능).

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[역할],
  text(weight: "bold")[권한],
  [Workspace Admin],
  [전체 권한],
  [Workspace Editor],
  [생성/수정, 삭제·멤버 관리 불가],
  [Workspace Viewer],
  [읽기 전용],
)

== 12.4 엔드유저 자격증명 관리

에이전트가 사용자 대신 외부 서비스(GitHub, Slack, Gmail 등)를 호출할 때 자격증명을 _에이전트 코드 밖에서_ 관리합니다.

=== Agent Auth (OAuth 2.0)

관리형 OAuth 플로우입니다. 첫 호출 때 사용자에게 consent URL을 interrupt로 제시하고, 토큰를 받으면 자동으로 resume·refresh합니다.

#code-block(`````python
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
`````)

=== Sandbox Auth Proxy

샌드박스에서 실행되는 사용자 코드(또는 에이전트가 생성한 코드)가 외부 API를 호출할 때 프록시가 자격증명을 _주입_합니다. API 키가 샌드박스 안 코드에 노출되지 않습니다.

#code-block(`````json
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
`````)

`${SECRET_KEY}`는 워크스페이스 시크릿에서 해석됩니다.

== 12.5 메모리 영속 스코핑

`StoreBackend`의 `namespace` 함수로 메모리 범위를 정합니다. `CompositeBackend`가 `/memories/`만 `StoreBackend`로 라우팅하고 나머지는 `StateBackend` 휘발성으로 두는 것이 기본 패턴입니다.

=== User-scoped (권장 기본값)

#code-block(`````python
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
`````)

=== Assistant-scoped / Organization-scoped

같은 assistant를 쓰는 모든 사용자가 공유(assistant-scoped)하거나 조직 전체에 공유(org-scoped)하는 구성도 가능합니다. 조직 공유는 _read-only로 두는 것이 원칙_입니다.

#warning-box[*Prompt injection 경고*: 공유 메모리는 프롬프트 인젝션 벡터입니다. 사용자가 조작 가능한 범위에 쓰기 권한을 주지 말 것. 자세한 정책은 Part IV ch15(권한 관리) 참고.]

== 12.6 실행 격리 — Sandbox

호스트 파일시스템과 네트워크를 그대로 노출하지 말고 _샌드박스_를 씁니다.

=== Thread-scoped sandbox (가장 흔한 패턴)

#code-block(`````python
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
`````)

=== Assistant-scoped sandbox

모든 스레드가 한 샌드박스를 공유해 도구 체인 캐시와 설치물을 보존해야 할 때 씁니다.

== 12.7 내구성·Async I/O

=== 매 스텝 체크포인트

LangSmith Deployments는 자동으로 체크포인터를 붙입니다. 매 스텝 상태가 저장되므로:

- *Indefinite interrupt*: HITL 승인 대기가 _며칠_이어도 정확히 멈춘 자리에서 재개
- *Time travel*: 임의 체크포인트 시점으로 되감아 분기 실행
- *Audit trail*: 결제·관리자 동작 같은 민감 연산 직전 상태 감사

#code-block(`````python
await agent.ainvoke(
    {"messages": [...]},
    config={"configurable": {"thread_id": "thread-abc"}},
)
`````)

=== Async I/O

LLM 앱은 I/O 바운드입니다. 비동기 도구와 미들웨어 훅(`abefore_agent`, `astream`)을 쓰면 처리량이 늘어납니다.

== 12.8 레이트 리밋과 비용 제어

#code-block(`````python
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
`````)

`run_limit`는 `invoke` 한 번마다 리셋, `thread_limit`는 스레드 수명 동안 누적합니다. 폭주·무한 루프가 비용 폭탄이 되기 전에 잘라냅니다.

== 12.9 에러 핸들링 3층

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[분류],
  text(weight: "bold")[예시],
  text(weight: "bold")[전략],
  text(weight: "bold")[미들웨어],
  [Transient],
  [타임아웃, rate limit, 네트워크 일시 실패],
  [자동 재시도 (backoff)],
  [`ModelRetryMiddleware`, `ToolRetryMiddleware`],
  [Recoverable],
  [잘못된 도구 인자, 파싱 실패],
  [모델에 피드백 → 재시도],
  [도구 래퍼 에러 메시지],
  [Human required],
  [권한 없음, 불명확한 요청],
  [에이전트 일시 정지],
  [HITL `interrupt_on`],
)

#code-block(`````python
from langchain.agents.middleware import (
    ModelRetryMiddleware,
    ModelFallbackMiddleware,
    ToolRetryMiddleware,
)

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    middleware=[
        ModelRetryMiddleware(max_retries=3, backoff_factor=2.0, initial_delay=1.0),
        ModelFallbackMiddleware("gpt-4.1"),
        ToolRetryMiddleware(
            max_retries=2,
            tools=["search", "fetch_url"],
            retry_on=(TimeoutError, ConnectionError),
        ),
    ],
)
`````)

== 12.10 데이터 프라이버시와 실시간 프런트엔드

=== PIIMiddleware

이메일·카드 번호·주민번호 등 PII를 입출력 경계에서 가공합니다. 전략은 `redact`(삭제), `mask`(마스킹), `hash`(해시), `block`(차단)이며 커스텀 detector도 등록할 수 있습니다. PII가 로그에 섞이기 전 입력 단계에서 처리하는 게 핵심입니다. LangSmith 트레이스에도 마스킹된 채로 기록됩니다.

=== `useStream` 훅

`@langchain/react`의 `useStream` 훅으로 실시간 스트리밍·재연결·히스토리 로드를 한 번에 처리합니다.

#code-block(`````tsx
import { useStream } from "@langchain/react";

function App() {
  const stream = useStream<typeof agent>({
    apiUrl: "https://your-deployment.langsmith.dev",
    assistantId: "agent",
    reconnectOnMount: true,
    fetchStateHistory: true,
  });
}
`````)

서브에이전트를 많이 띄우는 Deep Agent는 서브그래프 이벤트까지 스트리밍해 UI에 서브에이전트 진행 카드를 보여줍니다(`streamSubgraphs: true`).

== 12.11 프로덕션 체크리스트

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

== 핵심 정리

- Thread·User·Assistant 세 추상 위에서 10대 운영 영역을 독립적으로 도입
- `langgraph.json` + LangSmith Deployments가 체크포인터·Store·인증·관측을 자동 프로비저닝
- 메모리 스코프는 user-scoped 기본, 공유 스코프는 반드시 read-only
- 에러는 3층(Transient/Recoverable/Human)으로 분류해 미들웨어와 HITL로 대응
- PII는 모델 입력 단계와 트레이스 전송 단계 두 레이어에서 이중 방어
