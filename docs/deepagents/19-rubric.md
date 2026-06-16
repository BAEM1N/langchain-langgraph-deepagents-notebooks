# Grading Rubrics — Deep Agents 0.6.5+

> 에이전트가 “완료” 기준을 스스로 점검하고, 부족하면 피드백을 받아 다시 실행하도록 만드는 LLM-as-a-judge 런타임 평가 미들웨어.

## 개요

`RubricMiddleware`는 Deep Agent가 답변을 만든 뒤 별도의 grader 모델로 전체 transcript와 rubric을 평가한다. 결과가 `needs_revision`이면 기준별 피드백을 대화에 주입하고 agent를 다시 실행한다. 루프는 `satisfied`, `max_iterations_reached`, `failed`, `grader_error` 중 하나로 종료된다.

`RubricMiddleware`는 beta API이며 `deepagents>=0.6.5`가 필요하다. 프로덕션에서는 grader 모델 비용, 지연 시간, rubric 품질을 함께 관리한다.

## 언제 쓰나

| 상황 | 이유 |
|------|------|
| 보고서·제안서처럼 필수 섹션이 있는 산출물 | 누락된 항목을 criterion 단위로 재검토 |
| 코드 생성·리팩터링 | “테스트 통과”, “API 유지”, “설명 포함” 같은 완료 조건 반복 확인 |
| 교육용 답안 생성 | 학습 목표·제약·채점 기준 충족 여부를 응답 직후 점검 |
| batch eval 전 사전 품질 게이트 | LangSmith offline eval 전에 runtime self-check 수행 |

## 기본 구성

```python
from deepagents import RubricMiddleware, create_deep_agent
from langgraph.checkpoint.memory import InMemorySaver

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[
        RubricMiddleware(
            model="openai:gpt-5.4-mini",  # grader 모델
            max_iterations=3,
        ),
    ],
    checkpointer=InMemorySaver(),
)
```

rubric은 invocation state에 문자열로 넘긴다.

```python
from langchain.messages import HumanMessage

config = {"configurable": {"thread_id": "rubric-demo"}}
result = agent.invoke(
    {
        "messages": [HumanMessage("LangGraph durable execution을 5줄로 설명해줘.")],
        "rubric": (
            "- 답변은 정확히 5줄이어야 한다\n"
            "- checkpoint와 thread_id를 언급해야 한다\n"
            "- 한국어로 설명해야 한다"
        ),
    },
    config=config,
)
```

## Verdict 상태

| 상태 | 의미 | 재실행 |
|------|------|--------|
| `satisfied` | 모든 rubric criterion 통과 | 아니오 |
| `needs_revision` | 하나 이상 실패. 피드백 주입 후 agent 재실행 | 예 |
| `max_iterations_reached` | 더 수정해야 하지만 반복 한도 도달 | 아니오 |
| `failed` | rubric이 평가 불가능하거나 잘못됨 | 아니오 |
| `grader_error` | grader 모델 호출 또는 구조화 응답 처리 오류 | 아니오 |

## 진행 상황 관찰

`on_evaluation` callback은 매 grading iteration 뒤 실행된다. LangSmith tracing이나 `stream_events` custom projection 없이도 최소한의 로그를 남길 수 있다.

```python
from deepagents.middleware.rubric import RubricEvaluation


def log_evaluation(ev: RubricEvaluation) -> None:
    print(f"iteration {ev['iteration']}: {ev['result']} — {ev['explanation']}")

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[
        RubricMiddleware(
            model="openai:gpt-5.4-mini",
            max_iterations=3,
            on_evaluation=log_evaluation,
        ),
    ],
    checkpointer=InMemorySaver(),
)
```

`stream_events(..., version="v3")`와 `CustomTransformer`를 함께 쓰면 `stream.custom`에서 `rubric_evaluation_start`, `rubric_evaluation_end` 이벤트를 UI로 보낼 수 있다.

## 설계 주의사항

1. **rubric은 구체적이어야 한다.** “좋은 답변”보다 “3개 섹션 포함”, “출처 2개 이상”, “금지어 없음”처럼 판정 가능한 기준이 좋다.
2. **grader는 작업 모델과 분리한다.** 비용이 낮고 안정적인 모델을 grader로 쓰되, rubric 판정이 어려우면 더 강한 모델을 선택한다.
3. **반복 한도를 둔다.** `max_iterations`가 없으면 비용·지연 시간이 커질 수 있다.
4. **offline eval을 대체하지 않는다.** runtime self-check는 품질 게이트이고, 장기 품질 추세는 LangSmith evaluation dataset으로 따로 본다.
5. **HITL과 결합한다.** 외부 side effect가 있는 도구는 rubric 통과 여부와 별개로 `interrupt_on` 승인을 유지한다.

## 관련 문서

- `17-interpreters.md` — interpreter와 programmatic subagents
- `15-streaming.md` — event streaming v3와 custom event projection
- `../langchain/27-test.md` — unit / integration / evals 테스트 전략
