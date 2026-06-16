# Interpreters — Deep Agents 0.6+

> 에이전트 루프 안에서 가벼운 코드 실행 공간을 제공해 도구 호출 조합, 구조화 데이터 변환, 서브에이전트 fan-out/fan-in을 모델 컨텍스트 밖에서 수행하는 기능.

## 개요

Deep Agents 0.6 계열은 `CodeInterpreterMiddleware`를 통해 **QuickJS 기반 interpreter**를 붙일 수 있다. 샌드박스가 “외부 환경에서 코드를 실행”하는 기능이라면, interpreter는 “에이전트 루프 내부에서 작은 프로그램을 실행”하는 기능이다.

| 구분 | Sandbox | Interpreter |
|------|---------|-------------|
| 실행 위치 | 격리된 외부 런타임/컨테이너 | 에이전트 루프 내부 QuickJS runtime |
| 주 용도 | 파일/패키지/셸/데이터 분석 환경 조작 | 도구 조합, 중간 상태 유지, 구조화 데이터 가공 |
| 보안 경계 | provider sandbox 정책 | QuickJS + allowlist bridge |
| 컨텍스트 절약 | 실행 결과만 모델로 반환 | 변수 공간을 interpreter에 유지 |

Interpreters는 experimental API다. 공식 최소 요구는 `langchain-quickjs>=0.1.0`과 Python 3.11+이며, 2026-06 점검 기준 최신 패키지는 `langchain-quickjs==0.2.0`이다.

## 설치

```bash
pip install -U "deepagents[quickjs]"
```

또는 uv:

```bash
uv add "deepagents[quickjs]"
```

## 언제 쓰나

- 여러 도구 호출을 loop/branch/retry로 조합해야 할 때
- 큰 후보군을 runtime 변수로 보관하고 일부만 모델 컨텍스트로 돌려보낼 때
- 표/JSON/list를 정렬·그룹화·검증·집계해야 할 때
- 여러 서브에이전트 결과를 코드로 병합해 최종 요약만 반환할 때

## 기본 구성

```python
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[CodeInterpreterMiddleware()],
)
```

`CodeInterpreterMiddleware`는 interpreter state lifecycle을 `mode="thread" | "turn" | "call"`로 고를 수 있다. 새 예제에서는 의도를 명확히 하려고 `mode="thread"`처럼 명시한다.

```python
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    model="openai:gpt-5.4",
    checkpointer=MemorySaver(),
    middleware=[
        CodeInterpreterMiddleware(mode="thread"),
    ],
)
```

## Programmatic Tool Calling (PTC)

Interpreter 코드가 allowlist된 도구를 직접 호출할 수 있다. 일반 LLM tool-calling 경로와 달리 interpreter bridge를 통과하므로, 어떤 도구를 노출할지 최소 권한 원칙으로 정한다. PTC를 켜면 도구 이름이 camelCase로 변환되어 `tools.*` 네임스페이스에 async 함수로 노출된다(예: `web_search` → `tools.webSearch`).

```python
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[CodeInterpreterMiddleware(ptc=["web_search"])],
)
```

Interpreter 안에서는 `await`로 호출한다.

```typescript
const result: string = await tools.webSearch({
  query: "deepagents interpreters",
});
```

주의: PTC는 일반 tool-calling 경로와 다르게 동작하므로, 도구별 `interrupt_on` 승인 정책이 호출마다 자동 적용된다고 가정하지 않는다. 민감 도구는 interpreter에 노출하지 않거나 별도 승인 wrapper를 둔다.

## Programmatic subagents

서브에이전트 fan-out/fan-in은 PTC allowlist가 아니라 `CodeInterpreterMiddleware(subagents=True)`가 제공하는 top-level `task(...)` JavaScript API를 사용한다. `subagents=True`가 기본값이며, 현재 에이전트에 Deep Agents의 `task` 도구가 있을 때 interpreter 안에서 `task(...)`가 노출된다.

여러 서브에이전트를 병렬로 fan-out 하는 패턴:

```javascript
const topics = ["retrieval", "memory", "evaluation"];

const reports = await Promise.all(
  topics.map((topic) =>
    task({
      description: `Research ${topic} in Deep Agents and return three concise findings.`,
      subagent_type: "general-purpose",
    }),
  ),
);

reports.join("\n\n");
```

`task(...)` 호출도 이미 승인된 `eval` 실행 안에서 일어나므로 parent-level `interrupt_on`이 subagent dispatch마다 다시 실행되지 않는다. per-dispatch 승인이 필요하면 `eval` 자체를 승인 게이트로 감싸거나, subagent spec 내부에 approval middleware를 넣거나, `CodeInterpreterMiddleware(subagents=False)`로 top-level `task(...)` 노출을 끈다.

## Middleware options

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `memory_limit` | `64 * 1024 * 1024` (64 MB) | QuickJS heap memory limit (bytes) |
| `timeout` | `5.0` | Per-eval 타임아웃(초) |
| `max_ptc_calls` | `256` | 한 번의 eval에서 허용되는 `tools.*` 호출 수 |
| `tool_name` | `"eval"` | Interpreter 도구 이름 |
| `max_result_chars` | `4000` | 반환 결과의 최대 문자 수 |
| `capture_console` | `True` | `console.log` 출력 캡처 여부 |
| `subagents` | `True` | top-level `task(...)` JavaScript API 노출 |
| `ptc` | `None` | PTC allowlist |
| `mode` | `None` → `"thread"` | interpreter context lifecycle (`thread` / `turn` / `call`) |
| `snapshot_between_turns` | `None` | 구버전 호환용 lifecycle 옵션. 새 코드는 `mode` 사용 |
| `max_snapshot_bytes` | `memory_limit` | snapshot 최대 크기 |

## 보안 원칙

1. **QuickJS는 host filesystem/network/shell을 기본 제공하지 않는다.** 외부 능력은 bridge로 명시 노출된 도구에 한정된다.
2. **PTC allowlist가 권한 경계다.** 비용 발생, 데이터 변경, 네트워크 접근 도구는 매우 신중히 노출한다.
3. **`task(...)`는 subagent dispatch 권한 경계다.** parent-level 승인 정책이 dispatch마다 자동 적용된다고 가정하지 않는다.
4. **snapshot은 interpreter 메모리만 복원한다.** 외부 도구 호출로 발생한 부작용은 되돌리지 않는다.
5. **장기 데이터 분석은 sandbox와 구분한다.** 패키지 설치·파일 처리·셸 실행이 필요하면 sandbox backend를 쓴다.

## 관련 문서

- `15-streaming.md` — interpreter/서브에이전트 진행 상태를 UI로 노출
- `11-sandboxes.md` — 외부 코드 실행 격리 환경
- `12-async-subagents.md` — interpreter에서 여러 subagent 작업을 조합하는 패턴
- `16-permissions.md` — 파일시스템 권한과 최소 권한 정책
