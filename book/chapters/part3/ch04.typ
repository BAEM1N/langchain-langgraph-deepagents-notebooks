// Auto-generated from 04_workflows.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "워크플로 패턴", subtitle: "5가지 핵심 패턴")

2장과 3장에서 Graph API와 Functional API의 기초를 각각 익혔다면, 이제 이 도구들로 실전 워크플로를 구성할 차례입니다. 실전에서 에이전트 워크플로는 대부분 소수의 반복되는 구조적 패턴으로 분류할 수 있습니다. Anthropic이 제시한 다섯 가지 핵심 패턴 --- `Prompt Chaining`, `Parallelization`, `Routing`, `Orchestrator-Worker`, `Evaluator-Optimizer` --- 은 복잡한 에이전트 시스템을 설계할 때 출발점이 됩니다. 이 패턴들은 LangGraph의 그래프 구조에 직접 대응됩니다: 순차 패턴은 일직선 엣지, 병렬 패턴은 팬아웃/팬인 구조, 조건부 패턴은 조건부 엣지, 반복 패턴은 순환 그래프로 자연스럽게 표현됩니다. 이 장에서는 각 패턴을 `Graph API`와 `Functional API` 양쪽으로 구현하며, 어떤 상황에서 어떤 패턴을 선택해야 하는지 감을 잡아 봅니다.

#learning-header()

+ 다섯 가지 핵심 워크플로 패턴의 구조와 적합한 사용 상황을 설명할 수 있다.
+ 각 패턴을 Graph API와 Functional API 양쪽으로 구현할 수 있다.
+ `Send()` API를 활용하여 런타임에 동적으로 워커 노드를 생성하는 Map-Reduce 패턴을 구현할 수 있다.
+ 반복 루프 패턴에서 `recursion_limit`으로 무한 루프를 방지할 수 있다.
+ 패턴을 조합하여 복합 워크플로를 설계할 수 있다.

== 4.1 환경 설정

이 장의 예제에서는 LLM 호출 외에도 `Send` 등 LangGraph 타입을 사용하므로, 필요한 모듈을 함께 임포트합니다.

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
`````)

== 4.2 Prompt Chaining --- 순차적 LLM 호출

첫 번째 패턴은 가장 단순하면서도 강력한 _Prompt Chaining_입니다. 하나의 복잡한 작업을 여러 개의 작은 LLM 호출로 분해하고, 각 단계의 출력을 다음 단계의 입력으로 전달합니다. 이 패턴은 "분할 정복(divide and conquer)" 전략의 LLM 버전이라 할 수 있습니다. 각 단계가 하나의 구체적인 작업만 담당하므로, 프롬프트가 간결해지고 LLM의 응답 품질이 향상됩니다.

Graph API에서는 `add_edge(A, B)`, `add_edge(B, C)` 형태의 일직선 연결로 구현합니다. `add_sequence([step1, step2, step3])`를 사용하면 더 간결하게 작성할 수 있습니다. Functional API에서는 순차적인 `@task` 호출로 동일한 효과를 냅니다.

- 각 단계의 출력이 다음 단계의 입력이 됩니다
- 용도: 번역 -> 검증 -> 교정, 분석 -> 요약 -> 포맷팅
- 중간 단계에서 품질 검사(gate)를 삽입하여 기준 미달 시 조기 종료할 수도 있습니다

#code-block(`````python
# Graph API: 순차 체인
builder.add_edge(START, "step1")
builder.add_edge("step1", "step2")
builder.add_edge("step2", "step3")
builder.add_edge("step3", END)

# 또는 축약 형태
builder.add_sequence([step1, step2, step3])
`````)

#tip-box[Prompt Chaining에서 각 단계의 프롬프트를 설계할 때, 이전 단계의 출력 형식과 다음 단계의 입력 형식을 _명확하게 정의_하는 것이 중요합니다. 구조화된 출력(`with_structured_output`)을 활용하면 단계 간 데이터 전달이 안정적입니다.]

== 4.3 Parallelization --- 독립적 태스크의 동시 실행

Prompt Chaining이 순차적 파이프라인이라면, Parallelization은 독립적인 작업을 _동시에_ 수행하는 패턴입니다. 서로 독립적인 분석 작업(예: 감정 분석, 키워드 추출, 요약)을 동시에 수행하면 전체 실행 시간을 크게 줄일 수 있습니다. N개의 독립 태스크를 순차로 실행하면 총 시간이 합산되지만, 병렬로 실행하면 가장 느린 태스크의 시간만 소요됩니다.

Graph API에서는 하나의 노드에서 여러 노드로 엣지를 연결하는 _팬아웃(fan-out)_ 구조를 사용합니다. LangGraph의 Pregel 실행 모델에서 같은 슈퍼스텝에 속하는 노드들은 자동으로 병렬 실행됩니다. 병렬로 실행된 결과는 이후 하나의 노드에서 _팬인(fan-in)_ 으로 합쳐집니다. 이때 결과가 같은 상태 필드에 기록된다면, 반드시 리듀서(예: `operator.add`)를 지정하여 안전한 병합을 보장해야 합니다.

Functional API에서는 여러 `@task`를 먼저 호출하고 `.result()`를 나중에 일괄 호출하면 동일한 효과를 얻습니다. 3장에서 배운 Future 패턴이 바로 이 병렬 실행 패턴의 핵심입니다.

#code-block(`````python
# Graph API: 팬아웃 구조
builder.add_edge("start_node", "sentiment")  # 병렬 분기 1
builder.add_edge("start_node", "keywords")   # 병렬 분기 2
builder.add_edge("start_node", "summary")    # 병렬 분기 3
# sentiment, keywords, summary는 같은 슈퍼스텝에서 동시 실행
builder.add_edge("sentiment", "merge")
builder.add_edge("keywords", "merge")
builder.add_edge("summary", "merge")
`````)

#tip-box[Graph API에서 병렬 실행은 같은 슈퍼스텝에 속하는 노드끼리 자동으로 발생합니다. 명시적인 비동기 코드 없이도 엣지 구조만으로 병렬화가 이루어진다는 점이 큰 장점입니다. 다만 병렬 노드들이 동일한 상태 필드에 값을 쓸 경우 리듀서가 없으면 데이터 손실이 발생할 수 있으므로, `Annotated[list, operator.add]`와 같은 리듀서를 반드시 설정하세요.]

== 4.4 Routing --- 분류 기반 분기

순차와 병렬 패턴이 _모든_ 단계를 실행하는 반면, Routing은 입력의 유형에 따라 _하나의_ 처리 경로만 선택하는 패턴입니다. 예를 들어, 사용자 질문을 먼저 "날씨", "수학", "일반" 등으로 분류한 뒤, 해당 카테고리에 특화된 노드로 라우팅합니다. 이를 통해 각 경로는 해당 유형에 최적화된 프롬프트와 도구를 사용할 수 있고, 불필요한 처리를 건너뛰어 비용과 지연 시간을 줄일 수 있습니다.

Graph API에서는 2장에서 배운 `add_conditional_edges()`로 자연스럽게 구현됩니다. 라우팅 함수가 현재 상태를 분석하여 다음 노드를 결정합니다. Functional API에서는 Python의 `if/elif` 분기문으로 동일한 효과를 냅니다. 라우팅 로직을 LLM에게 위임하여 구조화된 출력으로 분류 결과를 받는 것이 일반적인 패턴입니다.

#code-block(`````python
# Graph API: 조건부 엣지로 라우팅
def route(state) -> Literal["weather", "math", "general"]:
    return state["classification"]

builder.add_conditional_edges("classify", route)

# Functional API: if/elif로 라우팅
if classification == "weather":
    result = handle_weather(query).result()
elif classification == "math":
    result = handle_math(query).result()
else:
    result = handle_general(query).result()
`````)

#align(center)[#image("../../assets/diagrams/png/conditional_routing.png", width: 78%, height: 112mm, fit: "contain")]

#warning-box[라우팅 함수에서 `Literal` 타입 힌트를 사용하면 그래프 시각화에 가능한 경로가 모두 표시됩니다. 타입 힌트가 없으면 시각화 도구가 분기 경로를 추론할 수 없어, 디버깅 시 불편할 수 있습니다.]

== 4.5 Orchestrator-Worker --- Send()로 동적 워커 생성

Parallelization 패턴에서 병렬 경로는 _컴파일 시점_에 고정되어 있었습니다. 그러나 실제로는 입력 데이터에 따라 병렬 작업의 _수_가 달라지는 경우가 대부분입니다. 예를 들어 "이 문서를 5개 언어로 번역하라"는 요청에서, 번역 대상 언어 수는 런타임에 결정됩니다. Orchestrator-Worker 패턴은 이러한 _실행 시점 동적 팬아웃_을 해결합니다.

LangGraph의 `Send()` API가 이 패턴의 핵심입니다. `Send(node_name, state)` 형태로 호출하면, 지정된 노드를 _해당 상태로_ 새로 생성합니다. 오케스트레이터 노드가 `Send` 객체의 리스트를 반환하면, 각 `Send`가 독립적인 워커 인스턴스를 생성하여 병렬로 실행됩니다. 각 워커는 자신만의 상태를 받으므로, 동일한 노드 함수가 서로 다른 데이터를 처리할 수 있습니다. 이는 MapReduce 패턴의 Map 단계에 정확히 대응합니다.

아래 코드에서 `route_to_workers` 함수는 `add_conditional_edges`의 라우팅 함수로 사용되지만, 문자열 대신 `Send` 객체의 리스트를 반환한다는 점이 다릅니다. 각 `Send`는 `"worker"` 노드를 서로 다른 `task` 값으로 호출합니다.

#code-block(`````python
from langgraph.types import Send

def route_to_workers(state):
    # 런타임에 태스크 수만큼 워커 생성
    return [Send("worker", {"task": t}) for t in state["tasks"]]

builder.add_conditional_edges("planner", route_to_workers)
builder.add_node("worker", worker_fn)
builder.add_edge("worker", "aggregator")
`````)

#align(center)[#image("../../assets/diagrams/png/orchestrator_worker.png", width: 68%, height: 122mm, fit: "contain")]

#tip-box[`Send()` API에서 각 워커는 _독립적인 상태_를 받습니다. 워커 노드의 결과를 하나로 합치려면 팬인(fan-in) 노드에서 리듀서를 활용해야 합니다. 예를 들어 `results: Annotated[list, operator.add]` 필드를 정의하면, 각 워커가 반환한 결과가 자동으로 리스트에 누적됩니다.]

== 4.6 Evaluator-Optimizer --- 생성-평가 반복 루프

지금까지의 네 패턴이 _일회성 처리_(한 번 실행하고 끝)에 초점을 맞추었다면, Evaluator-Optimizer는 _반복적 개선_을 다루는 유일한 순환(cyclic) 패턴입니다. 핵심 구조는 간단합니다: 생성 노드가 결과를 만들고, 평가 노드가 품질을 판단한 뒤, 기준에 미치지 못하면 피드백과 함께 다시 생성 노드로 돌아가는 루프입니다. 이 패턴은 코드 생성 후 테스트 실행, 글 작성 후 품질 평가, 이미지 생성 후 평가 등 _자기 개선(self-improvement)_이 필요한 모든 시나리오에 적용됩니다.

Graph API에서는 평가 노드에서 조건부 엣지로 "다시 생성"(`improve`) 또는 "종료"(`END`)를 선택합니다. `improve` -> `evaluate` 방향의 엣지가 순환 구조를 만들어, 품질 기준을 만족할 때까지 반복합니다. Functional API에서는 `while` 루프 안에 품질 검사 조건을 넣으면 됩니다.

#code-block(`````python
# Graph API: 순환 루프
def should_continue(state):
    if state["score"] > 0.8:
        return END
    return "improve"  # 생성 노드로 복귀

builder.add_conditional_edges("evaluate", should_continue)
builder.add_edge("improve", "evaluate")  # 순환 엣지

# Functional API: while 루프
score = 0
while score <= 0.8 and attempts < max_attempts:
    result = generate(feedback).result()
    score = evaluate(result).result()
    attempts += 1
`````)

#warning-box[반복 루프 패턴에서는 무한 루프를 방지하기 위해 최대 반복 횟수를 반드시 설정하세요. Graph API에서는 `graph.invoke(inputs, config=\{"recursion_limit": 50\})`로 최대 슈퍼스텝 수를 제한하거나, 상태에 카운터 필드를 추가하여 직접 관리할 수 있습니다. 기본 `recursion_limit`은 1000이므로, 프로덕션 환경에서는 반드시 적절한 값으로 낮추는 것을 권장합니다.]

다섯 가지 패턴을 모두 살펴보았습니다. 각 패턴은 독립적으로 사용할 수도 있지만, 실전에서는 여러 패턴을 _조합_하는 것이 일반적입니다. 이제 각 패턴의 특성을 한눈에 비교하여, 어떤 상황에서 어떤 패턴을 선택해야 하는지 정리해 봅시다.

== 4.7 패턴 비교표

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[결정적],
  text(weight: "bold")[병렬],
  text(weight: "bold")[반복],
  text(weight: "bold")[적합 상황],
  [Prompt Chaining],
  [O],
  [X],
  [순차],
  [단계별 변환],
  [Parallelization],
  [O],
  [O],
  [X],
  [독립 분석],
  [Routing],
  [O],
  [X],
  [X],
  [분류 기반 처리],
  [Orchestrator-Worker],
  [O],
  [O],
  [X],
  [동적 하위 작업],
  [Evaluator-Optimizer],
  [X],
  [X],
  [O],
  [품질 개선 루프],
)

#tip-box[실제 프로젝트에서는 이 패턴들을 _조합_하여 사용합니다. 예를 들어, Routing으로 입력을 분류한 뒤 각 경로에서 Prompt Chaining을 수행하거나, Orchestrator-Worker로 병렬 처리한 결과를 Evaluator-Optimizer로 품질 검증하는 식입니다. 서브그래프를 활용하면 각 패턴을 독립적인 그래프로 구현한 뒤, 부모 그래프에서 노드로 조합할 수 있습니다.]

#warning-box[패턴 선택 시 가장 중요한 원칙은 _단순함_입니다. Prompt Chaining으로 충분한 문제에 Orchestrator-Worker를 적용하면 불필요한 복잡성만 추가됩니다. 항상 가장 단순한 패턴에서 시작하고, 성능이나 품질 요구사항에 따라 점진적으로 복잡한 패턴으로 전환하세요.]

#next-step-box[다음 장에서는 이 워크플로 패턴들 중 가장 중요한 _ReAct 에이전트_를 Graph API와 Functional API 모두로 구현합니다. LLM이 스스로 도구를 선택하고 호출하는 자율적 에이전트의 구축 방법을 배웁니다.]

#chapter-end()
