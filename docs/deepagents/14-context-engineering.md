# Context Engineering

> Deep Agent가 모델의 제한된 컨텍스트 창 안에서 **무엇을** 보여주고, **언제** 오프로드하고, **어떻게** 다시 끌어올지 결정하는 설계 전체.
> 에이전트가 길어질수록 품질이 떨어지거나 요약에 삼켜지는 현상을 조정할 때, 혹은 서브에이전트/스킬/메모리를 한 파이프라인 안에서 정리하고 싶을 때 읽는다.

## 개요

Deep Agents의 컨텍스트 엔지니어링은 4층으로 구성된다.

1. **Layered input context** — system prompt, AGENTS.md, SKILL.md, tool 설명이 정해진 순서로 합성
2. **Dynamic / runtime context** — `@dynamic_prompt`와 `ToolRuntime`으로 요청 시점 데이터 주입
3. **Automatic compression** — offloading(>20k 토큰 → 디스크), summarization(85% → 구조화 요약)
4. **Filesystem-centric retrieval** — `read_file` / `grep` / 서브에이전트 격리로 선별적 재주입

각 층은 독립적으로 끄고 켤 수 있지만, 기본값만으로도 장시간 대화의 90% 케이스를 처리하도록 조율되어 있다.

## Layered input context

시스템 프롬프트는 다음 순서로 자동 합성된다.

1. **Custom system prompt** — 사용자가 준 지시
2. **Base agent prompt** — planning/filesystem/subagent 기반 지시
3. **To-do list prompt**
4. **Memory prompt** — `AGENTS.md`(설정 시 항상 로드)
5. **Skills prompt** — 스킬 위치와 frontmatter 목록만
6. **Filesystem prompt** — 도구 문서
7. **Subagent prompt** — 위임 가이드
8. **Middleware prompts** — 커스텀 추가분
9. **Human-in-the-loop prompt**

```python
from deepagents import create_deep_agent

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    system_prompt=(
        "You are a research assistant specializing in scientific literature. "
        "Always cite sources. Use subagents for parallel research on different topics."
    ),
)
```

### AGENTS.md: 항상 로드되는 반영구 컨텍스트

프로젝트 규약·사용자 선호처럼 **모든 대화에 적용되어야 하는** 내용.

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    memory=["/project/AGENTS.md", "~/.deepagents/preferences.md"],
)
```

항상 로드되므로 최소한으로 유지한다. 상세 워크플로우는 SKILL.md로 뺀다.

## `@dynamic_prompt` 데코레이터

정적 문자열로 충분하지 않고 **요청 시점 데이터**(사용자 역할, 조직 ID, 현재 시각, store 내용 등)로 지시를 바꿔야 할 때 사용한다. 미들웨어는 `request.runtime.context`와 `request.runtime.store`를 읽어 동적 프롬프트를 만든다.

동적 프롬프트는 **미들웨어 레이어**에서 결정되고, 도구는 별도 설정 없이 `ToolRuntime`을 통해 런타임 값을 받는다.

## Progressive skill loading

스킬은 2단계로 로드된다.

- **Startup**: `SKILL.md`의 frontmatter(이름·설명)만 읽음 → 수백 토큰 수준
- **On demand**: 사용자 요청이 해당 스킬에 매칭될 때만 본문 전체 로드

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    skills=["/skills/research/", "/skills/web-search/"],
)
```

스킬 수십 개를 등록해도 초기 토큰 비용은 frontmatter만큼만 든다. 자세한 스펙은 `10-skills.md`.

## Runtime context propagation

`context_schema`로 선언된 컨텍스트는 에이전트뿐 아니라 **모든 서브에이전트·도구**에 자동 전달된다.

```python
from dataclasses import dataclass
from deepagents import create_deep_agent
from langchain.tools import tool, ToolRuntime

@dataclass
class Context:
    user_id: str
    api_key: str

@tool
def fetch_user_data(query: str, runtime: ToolRuntime[Context]) -> str:
    """현재 사용자 데이터를 조회한다."""
    user_id = runtime.context.user_id
    return f"Data for user {user_id}: {query}"

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    tools=[fetch_user_data],
    context_schema=Context,
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "Get my recent activity"}]},
    context=Context(user_id="user-123", api_key="sk-..."),
)
```

이 구조 덕분에 도구는 메시지에 API 키를 싣지 않고도 런타임 값을 읽을 수 있고, 서브에이전트도 동일 값을 자동 상속한다.

### 도구 문서화 품질이 곧 컨텍스트

도구 선택은 모델이 **설명만 보고** 한다. docstring + Args 섹션을 구체적으로 써야 토큰 낭비가 줄어든다.

```python
from langchain.tools import tool

@tool(parse_docstring=True)
def search_orders(
    user_id: str,
    status: str,
    limit: int = 10,
) -> str:
    """Search for user orders by status.

    Use this when the user asks about order history or wants to check
    order status. Always filter by the provided status.

    Args:
        user_id: Unique identifier for the user
        status: Order status: 'pending', 'shipped', or 'delivered'
        limit: Maximum number of results to return
    """
    ...
```

## Automatic offloading (>20k 토큰)

컨텍스트가 커지면 자동으로 두 가지 오프로딩이 발동된다.

- **Input offloading**: 큰 파일 write/edit 결과는 컨텍스트가 85% 용량을 넘으면 실제 내용 대신 **file pointer reference**로 치환된다.
- **Result offloading**: 도구 응답이 **20,000 토큰**을 초과하면 스토리지에 저장되고 컨텍스트에는 **파일 경로 + 첫 10라인 프리뷰**만 남는다.

즉 큰 결과는 일단 디스크에 쓰고, 필요해지면 `read_file` / `grep`으로 부분만 다시 끌어온다. 이것이 filesystem-centric 설계의 핵심 이유다.

## Automatic summarization (85% 트리거)

오프로드할 것이 더 없는데 컨텍스트가 여전히 크면 **구조화 요약**이 발동된다. LLM이 현재 대화를 다음 요소로 압축한다.

- Session intent
- Artifacts created
- Next steps

이 요약이 기존 대화 히스토리를 **대체**하고, 에이전트는 계속 진행한다.

기본 설정:

| 항목 | 기본값 |
|------|--------|
| 트리거 | 모델 `max_input_tokens`의 85% |
| 최근 보존 | 10% |
| Fallback | 170,000 토큰 트리거, 최근 6 메시지 보존 |
| 즉시 트리거 | `ContextOverflowError` 발생 시 |

## 수동 summarization 도구

자동 트리거 외에, 에이전트가 명시적으로 요약을 호출하도록 하고 싶을 때 미들웨어를 추가한다.

```python
from deepagents import create_deep_agent
from deepagents.backends import StateBackend
from deepagents.middleware.summarization import (
    create_summarization_tool_middleware,
)

backend = StateBackend
model = "google_genai:gemini-3.1-pro-preview"

agent = create_deep_agent(
    model=model,
    middleware=[
        create_summarization_tool_middleware(model, backend),
    ],
)
```

스트리밍 시 요약 토큰은 UI에 노출하지 않도록 필터링할 수 있다.

```python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode="messages",
    version="v2",
):
    token, metadata = chunk["data"]
    if metadata.get("lc_source") == "summarization":
        continue
```

## Subagent isolation

서브에이전트는 **자체 컨텍스트**에서 실행되고 슈퍼바이저에게는 **최종 리포트 하나만** 돌려준다. 중간 도구 호출·검색 결과는 서브에이전트 컨텍스트에 남고 슈퍼바이저 창은 깨끗하게 유지된다.

```python
research_subagent = {
    "name": "researcher",
    "description": "특정 주제 리서치 수행",
    "system_prompt": (
        "You are a research assistant.\n"
        "IMPORTANT: Return only the essential summary (under 500 words).\n"
        "Do NOT include raw search results or detailed tool outputs."
    ),
    "tools": [web_search],
}
```

서브에이전트 프롬프트에 "최종 요약만 반환해라"를 명시하는 것이 컨텍스트 오염 방지의 1차 방어선이다.

## CompositeBackend로 `/memories/` 라우팅

일부 경로만 영속 스토어, 나머지는 휘발성 상태. 에이전트는 동일한 `write_file` / `read_file`로 접근하지만 내부적으로 다른 백엔드가 처리한다.

```python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore

def make_backend(runtime):
    return CompositeBackend(
        default=StateBackend(runtime),
        routes={"/memories/": StoreBackend(runtime)},
    )

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    store=InMemoryStore(),
    backend=make_backend,
    system_prompt=(
        "When users tell you their preferences, save them to "
        "/memories/user_preferences.txt so you remember them in future conversations."
    ),
)
```

## Filesystem-centric architecture

Deep Agents의 모든 컨텍스트 압축 전략은 결국 하나의 명제로 수렴한다.

> **"Write big, read selective."**
> 큰 산출물은 디스크에 쓰고, 다시 쓸 땐 `read_file` / `grep`으로 필요한 부분만 주입한다.

이 구조가 있기에:

- 도구 결과가 20k 토큰을 넘어도 컨텍스트는 파일 레퍼런스 + 10라인 프리뷰만 유지
- 서브에이전트는 원하는 만큼 탐색해도 슈퍼바이저 창에 영향 없음
- 메모리는 항상 로드가 아니라 **필요할 때 `read_file("/memories/...")`** 로 가져옴
- 스킬은 frontmatter만 보이고 본문은 on-demand

## 패턴

### 패턴 1: 장시간 리서치

- `AGENTS.md`는 조사 양식·인용 규칙만 (최소)
- 스킬 3~10개 등록, frontmatter만 노출
- 주제별 서브에이전트가 병렬로 탐색 → 최종 요약만 회수
- 큰 검색 결과는 자동 파일 오프로드 → `grep`으로 다시 쿼리

### 패턴 2: 개인화 어시스턴트

- `/memories/` 라우팅으로 사용자별 선호 누적
- `@dynamic_prompt`로 사용자 역할별 톤·가드레일 주입
- `context_schema`에 `user_id`/`org_id` 선언해 전 서브에이전트에 전파
- 공유 정책은 `/policies/`(read-only) 네임스페이스

### 패턴 3: 비용 최적화

- 자동 summarization 트리거를 기본(85%)보다 조금 낮추기
- 서브에이전트 system_prompt에 "under 500 words" 명시
- 도구 응답이 큰 도구는 요약본 + 파일 포인터를 반환하도록 래핑

## 주의사항

- **AGENTS.md 과적재 금지**. 항상 로드되므로 5KB 넘기면 체감된다.
- **스킬 frontmatter는 설명이 전부**. 매칭이 안 되면 본문이 영영 안 읽힌다.
- **Summarization은 파괴적**. 중요한 중간 산출물은 먼저 파일로 저장해야 요약 후에도 접근 가능하다.
- **서브에이전트가 raw dump를 반환하면** 슈퍼바이저 창이 오히려 더 빨리 터진다. 시스템 프롬프트로 요약 강제.
- **도구 설명 품질**이 곧 토큰 효율이다. 모호한 docstring은 모델이 엉뚱한 도구를 고르게 만들고 재시도 비용을 낳는다.

## 관련 문서

- `10-skills.md` — SKILL.md 구조와 progressive loading
- `09-long-term-memory.md` — `/memories/` 경로·스코프
- `07-subagents.md` — 서브에이전트 격리 기본
- `15-streaming.md` — 요약 토큰을 UI에서 분리하기
- `12-async-subagents.md` — 장시간 작업의 컨텍스트 압축 회피 전략
