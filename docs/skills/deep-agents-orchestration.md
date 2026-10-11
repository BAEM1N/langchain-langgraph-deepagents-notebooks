# Deep Agents Orchestration

SubAgentMiddleware, TodoListMiddleware, HumanInTheLoopMiddleware.

## SubAgentMiddleware

`task` 도구로 서브에이전트에 작업을 위임한다.

```python
from deepagents import create_deep_agent

sub = {
    "name": "researcher",
    "description": "Researches topics using web search",
    "model": model,
    "system_prompt": "You are a research assistant.",
    "tools": [web_search],
}

agent = create_deep_agent(
    model=model,
    subagents=[sub],
)
```

### 서브에이전트 특성

- 기본 `mode="isolated"`에서는 위임된 작업 중심으로 실행되고, custom subagent의 `system_prompt`와 skills를 별도로 지정한다.
- `mode="fork"`는 실험적 모드로 부모의 현재 대화 문맥과 system prompt를 이어받는다. fork는 장기 메모리를 자동 제공하지 않으며 별도 `skills` 설정을 허용하지 않는다.
- custom subagent의 skills state는 부모와 격리된다. `general-purpose` 서브에이전트는 부모 스킬을 상속하는 예외다.

## TodoListMiddleware

`write_todos` 도구로 계획을 수립한다. Deep Agents 0.7 계열에서는 계획 도구를 기본 내장이라고 설명하지 말고, 계획이 필요한 예제에서 `TodoListMiddleware`를 명시한다.

```python
# TodoListMiddleware를 구성한 agent에서 단계별 계획을 파일로 저장
agent.invoke({
    "messages": [{"role": "user", "content": "복잡한 분석 수행"}]
})
```

## HumanInTheLoopMiddleware

`interrupt_on` 설정으로 특정 도구 실행 전 사람 승인을 요청한다.

```python
agent = create_deep_agent(
    model=model,
    tools=[dangerous_tool],
    interrupt_on=["dangerous_tool"],
    checkpointer=MemorySaver(),
)
```

### 결정 유형

| 유형 | 설명 |
|------|------|
| Approve | 도구 호출 승인 |
| Reject | 도구 호출 거부 |
| Edit | 도구 호출 파라미터 수정 |

### 필수 요구사항

- **체크포인터 필수**: interrupt는 체크포인터 없이 작동하지 않음
- **thread_id 필수**: 재개 시 동일 thread_id 사용
- **인터럽트 타이밍**: `invoke()` 호출 사이에 발생
