# LangGraph Interrupts Documentation

## Overview

Interrupts enable pausing graph execution at specific points to await external input, facilitating human-in-the-loop workflows. When triggered, LangGraph persists the graph state and waits indefinitely until execution resumes.

## Core Concepts

**Key Features:**
- "Checkpointing keeps your place: the checkpointer writes the exact graph state"
- Thread IDs function as persistent cursors for resuming checkpoints
- Interrupt payloads surface in the `__interrupt__` field of results

## Implementation Basics

### Using the `interrupt()` Function

The interrupt function pauses execution and returns a value to the caller. Required components:
1. A checkpointer for state persistence
2. A thread ID in configuration
3. JSON-serializable interrupt payload

```python
from langgraph.types import interrupt

def approval_node(state: State):
    approved = interrupt("Do you approve this action?")
    return {"approved": approved}
```

### Resuming Execution

Resume using `Command(resume=...)` with the same thread ID. resume 값은 interrupt payload의 응답으로 노드에 다시 전달된다.

```python
from langgraph.types import Command

config = {"configurable": {"thread_id": "thread-1"}}
result = graph.invoke({"input": "data"}, config=config, version="v2")
print(result.interrupts)  # tuple[Interrupt, ...]

# 단순 boolean 응답
graph.invoke(Command(resume=True), config=config, version="v2")

# 텍스트 응답 (review/edit 패턴)
graph.invoke(Command(resume="The edited text"), config=config, version="v2")

# 구조화된 응답 (tool interrupt 패턴)
graph.invoke(
    Command(resume={"action": "approve", "subject": "Updated subject"}),
    config=config,
    version="v2",
)
```

`Command(resume=...)`는 단일 값 / dict 어떤 형태든 받을 수 있다. tool interrupt에서는 `{"action": "approve", ...}` 같은 decision dict를 사용해 승인 여부와 편집 내용을 함께 전달하는 패턴이 일반적이다.

## Common Patterns

### Approval Workflows

API 호출 / DB 변경 같은 critical action 직전에 중단하고, 승인 여부에 따라 라우팅한다.

```python
from typing import Literal
from langgraph.types import Command, interrupt

def approval_node(state: ApprovalState) -> Command[Literal["proceed", "cancel"]]:
    decision = interrupt({
        "question": "Approve this action?",
        "details": state["action_details"],
    })
    return Command(goto="proceed" if decision else "cancel")

# 승인
graph.invoke(Command(resume=True), config=config, version="v2")
# 거부
graph.invoke(Command(resume=False), config=config, version="v2")
```

### Review and Edit

LLM 출력을 사람이 검토·수정한 뒤 그래프에 다시 주입한다.

```python
def review_node(state: State):
    edited_content = interrupt({
        "instruction": "Review and edit this content",
        "content": state["generated_text"],
    })
    return {"generated_text": edited_content}

graph.invoke(Command(resume="The edited text"), config=config, version="v2")
```

### Tool Interrupts

tool 함수 내부에 interrupt를 두면, tool 실행 직전 사람이 승인·편집할 수 있다. resume payload는 보통 `{"action": "approve", ...}` 형태의 decision dict다.

```python
from langchain.tools import tool
from langgraph.types import interrupt

@tool
def send_email(to: str, subject: str, body: str):
    """Send an email to a recipient."""
    response = interrupt({
        "action": "send_email",
        "to": to,
        "subject": subject,
        "body": body,
        "message": "Approve sending this email?",
    })

    if response.get("action") == "approve":
        final_to = response.get("to", to)
        final_subject = response.get("subject", subject)
        final_body = response.get("body", body)
        return f"Email sent to {final_to}"
    return "Email cancelled by user"

# 승인 + 부분 편집
graph.invoke(
    Command(resume={"action": "approve", "subject": "Updated subject"}),
    config=config,
    version="v2",
)
```

### Input Validation

루프 안에서 interrupt를 반복 호출해, 유효한 값이 들어올 때까지 다시 묻는다.

```python
def get_age_node(state: State):
    prompt = "What is your age?"
    while True:
        answer = interrupt(prompt)
        if isinstance(answer, int) and answer > 0:
            break
        prompt = f"'{answer}' is not valid. Please enter a positive number."
    return {"age": answer}
```

### Multiple Interrupts

병렬 노드가 동시에 interrupt를 일으키면, interrupt id를 키로 하는 resume map을 사용해 응답을 일대일로 매칭한다.

```python
interrupted_result = graph.invoke({"vals": []}, config, version="v2")

resume_map = {
    i.id: f"answer for {i.value}" for i in interrupted_result.interrupts
}
result = graph.invoke(Command(resume=resume_map), config, version="v2")
```

### Streaming + HITL

여러 stream mode를 조합하면 interrupt 발생을 실시간으로 감지하고 곧바로 응답을 주입할 수 있다.

```python
for chunk in graph.stream(
    initial_input,
    stream_mode=["messages", "updates", "values"],
    subgraphs=True,
    config=config,
    version="v2",
):
    if chunk["type"] == "values" and chunk.get("interrupts"):
        interrupt_info = chunk["interrupts"][0].value
        user_response = get_user_input(interrupt_info)
        initial_input = Command(resume=user_response)
        break
```

## Critical Rules

**Do Not:**
- Wrap interrupt calls in bare try/except blocks (catches the interrupt exception)
- Reorder or conditionally skip interrupt calls within nodes
- Pass non-serializable objects (functions, class instances)
- Perform non-idempotent operations before interrupts

**Do:**
- Separate interrupt logic from error-prone code
- Keep interrupt call order consistent across executions
- Use simple, JSON-serializable types
- Place side effects after interrupts or in separate nodes

## Debugging

Static interrupts serve as breakpoints for testing. Compile time / runtime 양쪽에서 지정 가능하다.

```python
# Compile-time
graph = builder.compile(
    interrupt_before=["node_a"],
    interrupt_after=["node_b", "node_c"],
    checkpointer=checkpointer,
)

# Runtime
graph.invoke(
    inputs,
    interrupt_before=["node_a"],
    interrupt_after=["node_b", "node_c"],
    config=config,
)

# 그대로 재개하려면 None 입력
graph.invoke(None, config=config)
```

static interrupt는 동적 `interrupt()` 함수와 달리 테스트·디버깅용이며, 프로덕션 HITL 워크플로우에는 동적 `interrupt()`를 권장한다. LangSmith Studio는 UI에서 interrupt 설정과 상태 검사를 지원한다.
