# LangGraph Human-in-the-Loop

`interrupt(value)` 함수, `interrupt(value, response_schema=...)`, `Command(resume=value)` 재개 패턴.

## 핵심 요구사항

- **체크포인터 필수**: interrupt는 체크포인터 없이 작동하지 않음
- **thread_id 필수**: 재개 시 동일 thread_id 사용

## 기본 패턴

```python
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import MemorySaver

def approval_node(state):
    # 사람에게 승인 요청
    answer = interrupt({"question": "승인하시겠습니까?", "data": state})

    if answer == "approved":
        return {"status": "approved"}
    return {"status": "rejected"}

graph = StateGraph(State)
graph.add_node("approve", approval_node)
app = graph.compile(checkpointer=MemorySaver())

# 실행 → interrupt에서 멈춤
result = app.invoke(input, config={"configurable": {"thread_id": "1"}})

# 사람이 승인 후 재개
result = app.invoke(
    Command(resume="approved"),
    config={"configurable": {"thread_id": "1"}},
)
```

## 응답 스키마

LangGraph 1.2.12+에서는 `interrupt`가 keyword-only `response_schema`를 받을 수 있다. 기존 `interrupt(value)` 호출은 유효하며, 승인·편집처럼 응답 형태가 정해진 경우에만 schema를 붙인다.

```python
from pydantic import BaseModel
from langgraph.types import interrupt

class ApprovalResponse(BaseModel):
    action: str
    reason: str

def approval_node(state):
    decision = interrupt(
        {"question": "승인하시겠습니까?", "data": state},
        response_schema=ApprovalResponse,
    )
    return {"status": decision.action, "reason": decision.reason}
```

`Command(resume=...)`로 재개할 때는 schema에 맞는 값을 전달한다. Pydantic schema를 쓰면 노드 안에서 typed object로 다루므로 dict처럼 인덱싱하지 않는다.

## 중요: 노드 재시작

`resume` 시 노드는 **처음부터 다시 실행**된다. interrupt 전 코드가 다시 실행되므로:

```python
def node(state):
    # ⚠️ 이 코드는 resume 시 다시 실행됨
    data = fetch_data()  # upsert 사용, insert 아님!

    answer = interrupt({"data": data})
    return {"result": answer}
```

**멱등성(idempotency)** 필수: insert 대신 upsert 사용.

## 패턴

### 검증 루프

```python
def validate_node(state):
    while True:
        answer = interrupt({"draft": state["draft"]})
        if answer["action"] == "approve":
            return {"final": state["draft"]}
        state["draft"] = answer["edited"]
```

### 병렬 인터럽트

여러 노드에서 동시에 interrupt 가능. 모든 인터럽트가 해결될 때까지 대기.

## 흔한 실수

| 실수 | 해결 |
|------|------|
| 체크포인터 누락 | `compile(checkpointer=...)` 필수 |
| thread_id 불일치 | 재개 시 동일 thread_id |
| `Command(update=...)` | 재개는 `Command(resume=...)` |
| 비멱등 코드 | interrupt 전 코드는 반드시 멱등으로 |
