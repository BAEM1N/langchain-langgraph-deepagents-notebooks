# LangGraph Functional API

> 공식 문서: <https://docs.langchain.com/oss/python/langgraph/functional-api>

## Overview

Functional API는 LangGraph의 핵심 기능 — 영속성(persistence), 메모리, human-in-the-loop, 스트리밍 — 을 최소한의 코드 변경으로 기존 애플리케이션에 통합할 수 있게 한다.

### Key Components

**`@entrypoint`** 워크플로의 시작점을 표시하고 실행 흐름을 관리하며, 장시간 실행 작업과 인터럽트를 처리한다.

**`@task`** 단위 작업(API 호출, 데이터 가공)을 비동기적으로 실행한다.

```python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver

@task()
def slow_computation(input_value):
    ...

@entrypoint(checkpointer=InMemorySaver())
def my_workflow(some_input: dict) -> int:
    ...
```

`@entrypoint` 는 단일 positional 인자를 받으며, async 버전도 지원한다.

## Functional vs. Graph API

| Aspect | Functional | Graph |
|--------|-----------|-------|
| **Control Flow** | 표준 Python 구문(if/for) 사용, 보일러플레이트 최소 | 명시적 그래프 구조 필요 |
| **State Management** | 함수 스코프, 별도 reducer 설정 없음 | State 선언 + reducer 필요 |
| **Checkpointing** | 기존 checkpoint에 태스크 결과 저장 | superstep 마다 checkpoint 생성 |
| **Visualization** | 런타임 생성, 시각화 불가 | 시각화 지원 |

## Core Concepts

### Entrypoint Definition

Entrypoint는 단일 positional 인자를 받는다(여러 값은 dict 사용). 데코레이션된 함수는 실행을 관리하는 `Pregel` 인스턴스를 반환한다.

**필수 요건**: 입력/출력은 JSON-serializable이어야 한다.

### Injectable Parameters

Entrypoint는 다음 파라미터를 자동 주입받을 수 있다.

| Parameter | Purpose |
|-----------|---------|
| **`previous`** | 직전 checkpoint state에 접근 (short-term memory) |
| **`store`** | `BaseStore` 인스턴스로 long-term memory 접근 |
| **`writer`** | `StreamWriter` 접근 — async + Python < 3.11 환경에서 필요 |
| **`config`** | `RunnableConfig` 런타임 설정 접근 |

### Task Execution

`@task` 가 반환하는 객체는 future-like이며, 결과 획득은 다음으로 수행한다.

- 동기: `.result()`
- 비동기: `await`

## Important Patterns

### Serialization Requirements

Entrypoint 입력/출력과 task 출력 모두 JSON-serializable해야 한다. Checkpointer가 설정된 상태에서 직렬화 불가 데이터를 다루면 런타임 에러가 발생한다.

### Determinism Principle

"Any randomness should be encapsulated inside of tasks" — 워크플로 재개(resume) 시 일관된 실행 순서를 보장하기 위해서다. 재실행이 발생하면 이미 계산된 task 결과는 재사용되어 중복 계산을 피한다.

### Idempotency

Side-effect를 동반하는 외부 호출은 idempotent하게 작성하거나 idempotency key를 동반해야 한다 — resume 시 동일 태스크가 다시 호출될 수 있다.

### Resumption Mechanics

워크플로 재개는 동일한 `thread_id` 와 함께 `Command(resume=value)` 를 전달한다. 에러 복구 시에는 thread id를 유지한 채 입력으로 `None` 을 전달해 재시도한다.

```python
my_workflow.stream(Command(resume=some_resume_value), config)
```

### Common Pitfalls

- **Side Effects** — 파일 쓰기, 이메일 발송 등은 task 안에 넣어 resume 시 중복 실행을 막는다.
- **Non-deterministic Control Flow** — 시간 체크, 난수 생성 같은 가변 동작은 task로 캡슐화해 실행 순서 일관성을 유지한다.

## Short-Term Memory

`previous` 파라미터는 직전 호출의 반환값을 보관한다. `entrypoint.final[return_type, save_type]` primitive로 반환값과 checkpoint 저장값을 분리할 수 있다.

```python
@entrypoint(checkpointer=checkpointer)
def accumulate(n: int, *, previous: int | None) -> entrypoint.final[int, int]:
    previous = previous or 0
    total = previous + n
    return entrypoint.final(value=previous, save=total)
```

## Execution Methods

- `invoke()` — 동기 실행
- `ainvoke()` — 비동기 실행
- `stream()` — 동기 스트리밍
- `astream()` — 비동기 스트리밍

모든 메서드는 영속성을 위해 `thread_id` 가 포함된 config가 필요하다.

## Learn More

- `22-use-functional-api.md` — 사용 예제 모음 (parallel, retry, cache, HITL, memory)
- `23-pregel.md` — `@entrypoint` 가 생성하는 Pregel 인스턴스의 런타임
