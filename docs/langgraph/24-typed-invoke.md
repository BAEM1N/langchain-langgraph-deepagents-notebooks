# Type-safe Invoke (`version="v2"`)

**Since**: LangGraph 1.1 (2026-03-10)

LangGraph 1.1부터 `invoke()` / `ainvoke()`에 `version="v2"`를 opt-in하면 결과가 `GraphOutput` 객체로 반환된다. 기존 dict 반환은 그대로 동작하며 v2는 선택이다.

---

## 1. 왜 v2인가

v1의 `invoke()`는 그래프 state를 평범한 dict로 반환한다. 그 안에 인터럽트가 섞일 수 있어 호출 측에서 분기/타입 추론이 어려웠다.

v2는 다음 문제를 해결한다.

- state와 인터럽트를 **구조적으로 분리** (`.value` vs `.interrupts`)
- state를 선언된 **Pydantic / dataclass 타입으로 자동 강제**
- 편집기/타입체커에서 **정적 타입 추론** 가능
- v1 dict 접근은 deprecated하게 남겨 **점진 마이그레이션** 보장

---

## 2. 기본 사용

```python
from pydantic import BaseModel
from langgraph.graph import StateGraph, START, END


class State(BaseModel):
    topic: str
    joke: str = ""


def generate_joke(state: State) -> dict:
    return {"joke": f"Why did the {state.topic} cross the road?"}


graph = (
    StateGraph(State)
    .add_node(generate_joke)
    .add_edge(START, "generate_joke")
    .add_edge("generate_joke", END)
    .compile()
)

result = graph.invoke({"topic": "chicken"}, version="v2")

# GraphOutput
print(type(result).__name__)   # GraphOutput
print(result.value)            # State(topic='chicken', joke='...')
print(result.value.joke)       # 자동 타입 추론
print(result.interrupts)       # []  — 인터럽트 없음
```

---

## 3. `GraphOutput`

| 속성 | 타입 | 설명 |
|------|------|------|
| `.value` | `StateT` | 최종 state. Pydantic 모델 / dataclass / `TypedDict` |
| `.interrupts` | `list[Interrupt]` | 실행 중 발생한 인터럽트 목록 |

### Dict 스타일 접근 (deprecated, 호환용)

```python
result["joke"]            # 아직 동작하지만 deprecated
result.value.joke         # v2 권장
```

v1 코드에서 마이그레이션 중이라면 일시적으로 dict 접근을 유지해도 된다. 단, 새 코드는 `.value` 사용.

---

## 4. Pydantic / dataclass 자동 강제

v2에서는 state 스키마 타입이 반환 타입에 그대로 반영된다.

```python
from dataclasses import dataclass

@dataclass
class Report:
    title: str
    sections: list[str]

graph = StateGraph(Report).add_node(...).compile()

result = graph.invoke({"title": "Q2", "sections": []}, version="v2")
assert isinstance(result.value, Report)   # ✅ 자동 강제
result.value.sections.append("intro")
```

`TypedDict` state는 dict로 유지되며, Pydantic/`dataclass`만 인스턴스화된다.

---

## 5. 인터럽트 처리

```python
from langgraph.types import interrupt, Command


def ask_human(state: State) -> dict:
    decision = interrupt({"question": "approve?"})
    return {"approved": decision}


result = graph.invoke(inputs, version="v2")

if result.interrupts:
    # 인터럽트 대기 중
    for iq in result.interrupts:
        print(iq.value)      # {"question": "approve?"}

    # resume
    result = graph.invoke(
        Command(resume="yes"),
        config=thread_config,
        version="v2",
    )
```

v1은 state dict에 인터럽트가 섞여 호출 측에서 분기하기 까다로웠다. v2는 `if result.interrupts:` 한 줄로 분기 가능하다.

---

## 6. 서브그래프 + 타임트래블 버그 수정

LangGraph 1.1은 인터럽트/서브그래프 타임트래블에서 stale `RESUME` 값을 재사용하던 버그도 함께 수정했다. 재생(replay) 시 서브그래프가 부모의 과거 체크포인트를 정확히 복원한다.

관련 기능 사용자라면 1.1 이상으로 올리고, 가능하면 `version="v2"` 도 함께 적용해 타입 안전성까지 확보하는 것을 권장한다.

---

## 7. 마이그레이션 전략

1. **새 코드부터 `version="v2"` 기본값으로 작성**
2. **기존 `invoke()` 호출은 그대로 둬도 된다** — v1 동작 유지
3. 부분 마이그레이션: 핫 패스 / 새 기능 먼저 v2 적용
4. Pydantic state를 쓰고 있다면 자동 강제 덕분에 타입 안전성 이득이 가장 크다

---

## 8. 관련 문서

- `07-streaming.md` — `version="v2"` 스트리밍 (`StreamPart`)
- `09-time-travel.md` — 타임트래블 동작
- `08-interrupts.md` — 인터럽트 / `Command(resume=...)`
- `20-use-graph-api.md` — 그래프 API 일반 사용
