// Auto-generated from 08_interrupts_and_time_travel.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "인터럽트와 타임 트래블", subtitle: "실행 중단, 승인, 되감기")

== 학습 목표
`interrupt()`로 실행을 중단하고, `Command(resume=...)`로 재개합니다. 타임 트래블로 이전 상태로 돌아갑니다.

- Human-in-the-loop 패턴을 구현할 수 있습니다
- Functional API에서도 interrupt를 사용할 수 있습니다
- 체크포인트 히스토리를 활용한 타임 트래블을 수행할 수 있습니다
- `update_state()`로 외부에서 상태를 수정할 수 있습니다

== 8.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI

# docs/langgraph 패치 기준 canonical 모델 ID
model = ChatOpenAI(model="gpt-5.4-mini")
print("모델 준비 완료")
`````)

#code-block(`````python
# Observability 설정 (선택) - LangSmith 또는 Langfuse
# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    project = os.environ.get("LANGSMITH_PROJECT", "default")
    print(f"LangSmith tracing ON \u2014 project: {project}")

# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON \u2014 {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)
#output-block(`````
Langfuse tracing ON — https://lf.ddok.ai
`````)

== 8.2 interrupt() — 실행을 중단하고 사람의 입력을 기다립니다

- `interrupt(value)`: 현재 상태를 체크포인트에 저장하고 실행을 중단합니다
- `Command(resume=value)`: 중단된 지점에서 값을 전달하며 재개합니다

민감한 작업 전 사람의 승인을 받거나, 추가 정보를 입력받을 때 사용합니다.

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import InMemorySaver
from typing import TypedDict


class ReviewState(TypedDict):
    document: str
    approved: bool
    final_result: str


def draft_document(state: ReviewState) -> dict:
    return {
        "document": f"초안: {state.get('document', '주제')}에 대한 중요 문서"
    }


def human_review(state: ReviewState) -> dict:
    # 사람의 승인을 기다립니다
    decision = interrupt(
        {
            "document": state["document"],
            "question": "이 문서를 승인하시겠습니까? (yes/no)"
        }
    )

    return {
        "approved": decision == "yes"
    }


def finalize(state: ReviewState) -> dict:
    if state["approved"]:
        return {
            "final_result": f"승인됨: {state['document']}"
        }

    return {
        "final_result": f"거절됨: {state['document']}"
    }


builder = StateGraph(ReviewState)

builder.add_node("draft", draft_document)
builder.add_node("review", human_review)
builder.add_node("finalize", finalize)

builder.add_edge(START, "draft")
builder.add_edge("draft", "review")
builder.add_edge("review", "finalize")
builder.add_edge("finalize", END)

graph = builder.compile(
    checkpointer=InMemorySaver()
)

config = {
    "configurable": {
        "thread_id": "review-1"
    }
}

# Step 1: 실행 → review 노드에서 중단
result = graph.invoke(
    {
        "document": "AI 안전성"
    },
    {**config, **lf_config}
)

print("Step 1 - review에서 중단됨")

state = graph.get_state(config)

print(f"  다음 노드: {state.next}")
print(f"  인터럽트 값: {state.tasks}")
`````)
#output-block(`````
Step 1 - review에서 중단됨
  다음 노드: ('review',)
  인터럽트 값: (PregelTask(id='478b41b2-f068-6fb7-cc7f-e9a49c46793d', name='review', path=('__pregel_pull', 'review'), error=None, interrupts=(Interrupt(value={'document': '초안: AI 안전성에 대한 중요 문서', 'question': '이 문서를 승인하시겠습니까? (yes/no)'}, id='f0c89de1e19ac278a95201cae2f56848'),), state=None, result=None),)
`````)

== 8.3 Command(resume=...) — 중단된 실행을 재개합니다

`Command(resume=value)`를 사용하면 `interrupt()`가 호출된 지점에서 실행이 재개됩니다. `resume`에 전달한 값이 `interrupt()`의 반환값이 됩니다.

#code-block(`````python
# Step 2: 승인하여 재개

result = graph.invoke(
    Command(resume="yes"),
    {**config, **lf_config}
)

print(f"Step 2 - 승인으로 재개됨")
print(f"  결과: {result['final_result']}")
`````)
#output-block(`````
Step 2 - 승인으로 재개됨
  결과: 승인됨: 초안: AI 안전성에 대한 중요 문서
`````)

== 8.4 Functional API에서의 interrupt

Functional API(`@entrypoint`, `@task`)에서도 `interrupt()`를 동일하게 사용할 수 있습니다.

#code-block(`````python
from langgraph.func import entrypoint, task

@task
def generate_proposal(topic: str) -> str:
    response = model.invoke(f"다음에 대한 한 문장 제안을 작성해주세요: {topic}", config=lf_config)
    return response.content

@entrypoint(checkpointer=InMemorySaver())
def proposal_workflow(topic: str) -> dict:
    proposal = generate_proposal(topic).result()

    # 사람의 승인 대기
    approval = interrupt({
        "proposal": proposal,
        "action": "승인 또는 거절하세요"
    })

    return {
        "proposal": proposal,
        "approved": approval,
    }

config = {"configurable": {"thread_id": "proposal-1"}}

# 실행 → 중단
result = proposal_workflow.invoke("재생 에너지", {**config, **lf_config})
print("제안 워크플로 중단됨")

# 재개
result = proposal_workflow.invoke(Command(resume="승인"), {**config, **lf_config})
print(f"최종: {result}")
`````)
#output-block(`````
제안 워크플로 중단됨
최종: {'proposal': '재생 에너지는 자연에서 반복적으로 얻을 수 있어 환경 오염을 줄이는 친환경 에너지원입니다.', 'approved': '승인'}
`````)

== 8.5 Common Patterns — 5가지 표준 interrupt 패턴

공식 문서는 interrupt 활용을 5가지 패턴으로 분류합니다. 모두 `interrupt()` + `Command(resume=...)` 조합이며, 차이는 _resume payload의 형태_와 _노드 내부 로직_입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[resume 형태],
  text(weight: "bold")[용도],
  [Approval],
  [`bool` (`True` / `False`)],
  [API 호출·DB 변경 같은 critical action 직전 승인],
  [Review & Edit],
  [`str` 또는 edited dict],
  [LLM 출력 검토·수정 후 재주입],
  [Tool Interrupt],
  [`{"action": "approve", ...}` decision dict],
  [tool 함수 내부에 interrupt를 두고 부분 편집 + 승인],
  [Input Validation],
  [임의 값, 노드당 한 번 입력],
  [조건부 엣지로 유효한 값까지 재질문],
  [Multiple Interrupts],
  [`{interrupt_id: 응답값}` map],
  [병렬 노드의 동시 interrupt에 id로 매칭],
)

`Command(resume=...)`는 단일 값 / dict 어떤 형태든 받을 수 있고, 노드의 `interrupt()` 반환값으로 그대로 전달됩니다.

=== 8.5.1 패턴 1 — Approval (`resume=True/False`)

`Command(goto=...)`와 결합해 승인 여부에 따라 라우팅합니다.

#code-block(`````python
from typing import Literal, TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import InMemorySaver

class ApprovalState(TypedDict):
    action_details: str
    outcome: str

def approval_node(state: ApprovalState) -> Command[Literal["proceed", "cancel"]]:
    decision = interrupt({
        "question": "Approve this action?",
        "details": state["action_details"],
    })
    return Command(goto="proceed" if decision else "cancel")

def proceed(state: ApprovalState) -> dict:
    return {"outcome": f"실행됨: {state['action_details']}"}

def cancel(state: ApprovalState) -> dict:
    return {"outcome": f"취소됨: {state['action_details']}"}

b = StateGraph(ApprovalState)
b.add_node("approval", approval_node)
b.add_node("proceed", proceed)
b.add_node("cancel", cancel)
b.add_edge(START, "approval")
b.add_edge("proceed", END)
b.add_edge("cancel", END)
approval_graph = b.compile(checkpointer=InMemorySaver())

# --- 승인 케이스 ---
cfg_yes = {"configurable": {"thread_id": "approval-yes"}}
out = approval_graph.invoke({"action_details": "결제 처리 $100"}, {**cfg_yes, **lf_config}, version="v2")
print(f"[승인 요청] interrupts={len(out.interrupts)}, value={out.interrupts[0].value}")
out = approval_graph.invoke(Command(resume=True), {**cfg_yes, **lf_config}, version="v2")
print(f"  resume=True  → {out.value['outcome']}")

# --- 거부 케이스 ---
cfg_no = {"configurable": {"thread_id": "approval-no"}}
approval_graph.invoke({"action_details": "결제 처리 $999"}, {**cfg_no, **lf_config}, version="v2")
out = approval_graph.invoke(Command(resume=False), {**cfg_no, **lf_config}, version="v2")
print(f"  resume=False → {out.value['outcome']}")
`````)

=== 8.5.2 패턴 2 — Review & Edit (`resume="edited text"`)

LLM 출력을 사람이 검토·수정한 뒤 그래프에 다시 주입합니다. resume 값이 그대로 state에 반영됩니다.

#code-block(`````python
class ReviewEditState(TypedDict):
    topic: str
    generated_text: str

def generate(state: ReviewEditState) -> dict:
    return {"generated_text": f"AI 초안: {state['topic']}에 대한 짧은 글입니다."}

def review_edit(state: ReviewEditState) -> dict:
    edited = interrupt({
        "instruction": "Review and edit this content",
        "content": state["generated_text"],
    })
    return {"generated_text": edited}

b = StateGraph(ReviewEditState)
b.add_node("generate", generate)
b.add_node("review_edit", review_edit)
b.add_edge(START, "generate")
b.add_edge("generate", "review_edit")
b.add_edge("review_edit", END)
review_graph = b.compile(checkpointer=InMemorySaver())

cfg = {"configurable": {"thread_id": "review-edit-1"}}
out = review_graph.invoke({"topic": "LangGraph"}, {**cfg, **lf_config}, version="v2")
print(f"[검토 요청] 원본: {out.interrupts[0].value['content']}")

# 사람이 텍스트를 편집해서 resume
out = review_graph.invoke(
    Command(resume="사람이 수정한 글: LangGraph로 상태 기반 워크플로를 만들 수 있다."),
    {**cfg, **lf_config},
    version="v2",
)
print(f"  resume=str  → state.generated_text = {out.value['generated_text']}")
`````)

=== 8.5.3 패턴 3 — Tool Interrupt (`resume={"action": "approve", ...}`)

tool 함수 내부에 `interrupt()`를 두면 tool 실행 직전 사람이 승인·편집할 수 있습니다. resume payload는 보통 `{"action": "approve", ...}` 형태의 decision dict로, 승인 여부와 부분 편집을 함께 전달합니다.

#code-block(`````python
from langchain.tools import tool

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Send an email to a recipient (sample tool with interrupt)."""
    response = interrupt({
        "action": "send_email",
        "to": to,
        "subject": subject,
        "body": body,
        "message": "Approve sending this email?",
    })

    if response.get("action") == "approve":
        # 사람이 일부 필드만 편집했을 수 있음 → 원본 값과 덮어쓰기
        final_to      = response.get("to", to)
        final_subject = response.get("subject", subject)
        final_body    = response.get("body", body)
        return f"Email sent to {final_to} (subject={final_subject!r})"
    return "Email cancelled by user"

# tool을 그래프 노드로 직접 감싸 데모
class ToolState(TypedDict):
    args: dict
    result: str

def email_node(state: ToolState) -> dict:
    result = send_email.invoke(state["args"])
    return {"result": result}

b = StateGraph(ToolState)
b.add_node("email", email_node)
b.add_edge(START, "email")
b.add_edge("email", END)
tool_graph = b.compile(checkpointer=InMemorySaver())

cfg = {"configurable": {"thread_id": "tool-interrupt-1"}}
out = tool_graph.invoke(
    {"args": {"to": "alice@example.com", "subject": "Hi", "body": "Hello!"}},
    {**cfg, **lf_config},
    version="v2",
)
print(f"[Tool 승인 요청] {out.interrupts[0].value['message']}")

# 승인 + subject 편집을 동시에
out = tool_graph.invoke(
    Command(resume={"action": "approve", "subject": "Updated subject"}),
    {**cfg, **lf_config},
    version="v2",
)
print(f"  resume=dict → {out.value['result']}")
`````)

=== 8.5.4 패턴 4 — Input Validation (노드당 한 번 interrupt)

노드는 호출될 때마다 `interrupt()`를 한 번만 실행합니다. 잘못된 값이면 재질문 문구를 상태에 저장하고, 조건부 엣지가 같은 노드로 되돌립니다. resume 시 노드가 처음부터 재실행되므로 한 노드의 반복문에서 interrupt를 여러 번 호출하면 이전 시도까지 누적 재실행됩니다.

#code-block(`````python
class FormState(TypedDict):
    age: int | None
    pending_question: str | None

def collect_age(state: FormState) -> dict:
    question = state.get("pending_question") or "나이를 입력하세요 (양의 정수)."
    answer = interrupt(question)
    if isinstance(answer, int) and answer > 0:
        return {"age": answer, "pending_question": None}
    return {"pending_question": f"'{answer}'은(는) 유효하지 않습니다. 양의 정수를 입력하세요."}
`````)

#code-block(`````python
def route_age(state: FormState) -> str:
    return END if state.get("age") is not None else "collect_age"

b = StateGraph(FormState)
b.add_node("collect_age", collect_age)
b.add_edge(START, "collect_age")
b.add_conditional_edges("collect_age", route_age)
age_graph = b.compile(checkpointer=InMemorySaver())
`````)

#code-block(`````python
cfg = {"configurable": {"thread_id": "validation-1"}}
out = age_graph.invoke(
    {"age": None, "pending_question": None},
    {**cfg, **lf_config}, version="v2",
)
print(f"  ask : {out.interrupts[0].value}")
`````)

#code-block(`````python
out = age_graph.invoke(Command(resume=-5), {**cfg, **lf_config}, version="v2")
print(f"  -5  : {out.interrupts[0].value}")
out = age_graph.invoke(Command(resume="abc"), {**cfg, **lf_config}, version="v2")
print(f"  abc : {out.interrupts[0].value}")
out = age_graph.invoke(Command(resume=30), {**cfg, **lf_config}, version="v2")
print(f"  30  : 통과 → state.age = {out.value['age']}")
`````)

=== 8.5.5 패턴 5 — Multiple Interrupts (`resume={interrupt_id: 응답}`)

병렬 노드가 동시에 interrupt를 일으키면, _interrupt id를 키로 하는 resume map_으로 응답을 일대일 매칭합니다.

#code-block(`````python
interrupted = graph.invoke({"vals": []}, config, version="v2")

resume_map = {
    i.id: f"answer for {i.value}" for i in interrupted.interrupts
}
result = graph.invoke(Command(resume=resume_map), config, version="v2")
`````)

`interrupted.interrupts`는 v2의 `GraphOutput.interrupts`로, 각 `Interrupt`에는 고유 `id`와 노드가 넘긴 `value`가 들어 있습니다. resume map의 키가 일치해야 해당 노드로 값이 전달됩니다.

== 8.6 타임 트래블 — Replay vs Fork

LangGraph의 체크포인트 시스템은 모든 실행 상태를 저장합니다. `get_state_history()`로 이전 체크포인트를 조회하고, 그 시점에서 두 가지 동작을 할 수 있습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[동작],
  text(weight: "bold")[API],
  text(weight: "bold")[효과],
  [_Replay_],
  [`invoke(None, prev.config)`],
  [그 시점부터 _다시 실행_. `next`로 표시된 노드부터 재실행되고, 이전 노드 결과는 캐시에서 재사용],
  [_Fork_],
  [`update_state(prev.config, values=...)` → 반환된 `fork_config`로 `invoke(None, fork_config)`],
  [그 시점에서 state를 _수정한 새 branch_ 생성 → 대체 경로 탐색. 원본 thread는 그대로 유지],
)

#warning-box[_주의_ — Replay는 결과를 "캐시에서 읽기만 하는" 게 아니라 _실제로 다시 실행_합니다. LLM 호출 / API 호출 / interrupt가 다시 발생하며 결과가 달라질 수 있습니다.]

#code-block(`````python
from langgraph.graph import StateGraph, START, END, MessagesState
from langchain.messages import HumanMessage

def chatbot(state: MessagesState) -> dict:
    response = model.invoke(state["messages"], config=lf_config)
    return {"messages": [response]}

builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

graph = builder.compile(checkpointer=InMemorySaver())

config = {"configurable": {"thread_id": "timetravel-1"}}

# 3번의 대화
graph.invoke({"messages": [HumanMessage(content="제가 좋아하는 색은 파랑입니다.")]}, {**config, **lf_config})
graph.invoke({"messages": [HumanMessage(content="제가 좋아하는 음식은 피자입니다.")]}, {**config, **lf_config})
graph.invoke({"messages": [HumanMessage(content="저는 서울에 살고 있습니다.")]}, {**config, **lf_config})

# 히스토리에서 특정 체크포인트 선택
history = list(graph.get_state_history(config))
print(f"전체 체크포인트 수: {len(history)}")

# 두 번째 대화 시점으로 되돌아가기 (REPLAY 데모)
target = history[2]  # older checkpoint
target_config = target.config
print(f"\n[Replay] 체크포인트={target_config['configurable']['checkpoint_id'][:20]}...")

# 그 시점에서 새로운 대화 시작
result = graph.invoke(
    {"messages": [HumanMessage(content="제가 좋아하는 음식은 뭔가요?")]},
    {**target_config, **lf_config},
)
print(f"응답: {result['messages'][-1].content[:200]}")
`````)

=== 8.6.1 Replay 표준 패턴 — `invoke(None, prev.config)`

문서 표준 예제로 다시 짚어봅니다. 2-노드 그래프(`generate_topic` → `write_joke`)에서 `write_joke` 직전 체크포인트로 돌아가 replay하면, `generate_topic`은 캐시된 결과를 재사용하고 `write_joke`만 재실행됩니다.

#code-block(`````python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver

class JokeState(TypedDict):
    topic: str
    joke: str

def generate_topic(state: JokeState) -> dict:
    """간단한 토픽 생성 (LLM 호출 비용을 절약하려고 결정적 값을 사용)"""
    return {"topic": "cats"}

def write_joke(state: JokeState) -> dict:
    response = model.invoke(
        f"{state['topic']}에 대한 한 줄 농담을 만들어주세요.",
        config=lf_config,
    )
    return {"joke": response.content}

b = StateGraph(JokeState)
b.add_node("generate_topic", generate_topic)
b.add_node("write_joke", write_joke)
b.add_edge(START, "generate_topic")
b.add_edge("generate_topic", "write_joke")
b.add_edge("write_joke", END)
joke_graph = b.compile(checkpointer=InMemorySaver())

cfg = {"configurable": {"thread_id": "joke-replay"}}
first_run = joke_graph.invoke({"topic": "", "joke": ""}, {**cfg, **lf_config})
print(f"원본:  topic={first_run['topic']!r}, joke={first_run['joke'][:80]!r}")

# write_joke 직전 체크포인트 찾기
history = list(joke_graph.get_state_history(cfg))
before_joke = next(s for s in history if s.next == ("write_joke",))
print(f"\nbefore_joke 체크포인트: next={before_joke.next}, topic={before_joke.values['topic']!r}")

# Replay — generate_topic 결과는 재사용, write_joke만 재실행
replay = joke_graph.invoke(None, {**before_joke.config, **lf_config})
print(f"\nReplay: topic={replay['topic']!r} (재사용), joke={replay['joke'][:80]!r} (재생성)")
`````)

=== 8.6.2 Fork 표준 패턴 — `update_state(prev.config, values=...)` + `as_node`

같은 `before_joke` 시점에서 _topic을 바꿔 다른 농담_을 만들어봅니다.

- `update_state(before_joke.config, values={"topic": "chickens"})` → 수정된 state를 적용한 _새 checkpoint(fork_config)_ 반환
- `invoke(None, fork_config)`로 fork branch 실행 → 원본 thread는 그대로 유지
- `as_node="generate_topic"` 옵션으로 "이 update가 generate_topic이 만든 것"임을 명시 → 후속 노드(`write_joke`)부터 실행 재개

#code-block(`````python
# before_joke 체크포인트에서 topic을 바꾼 fork branch 생성
fork_config = joke_graph.update_state(
    before_joke.config,
    values={"topic": "chickens"},
    as_node="generate_topic",  # 이 update를 generate_topic이 만든 것으로 간주 → write_joke부터 실행
)
print(f"fork_config checkpoint_id: {fork_config['configurable']['checkpoint_id'][:20]}...")

# Fork 실행 — 새 branch에서 write_joke만 실행
fork_result = joke_graph.invoke(None, {**fork_config, **lf_config})
print(f"\nFork:  topic={fork_result['topic']!r} (수정됨), joke={fork_result['joke'][:80]!r}")

# 원본 thread는 그대로 유지
original = joke_graph.get_state(cfg)
print(f"\n원본 유지: topic={original.values['topic']!r}, joke={original.values['joke'][:80]!r}")
print("→ update_state는 thread를 롤백하지 않고, 새 branch를 만들어 갈라집니다.")
`````)

== 8.7 update_state() — 외부에서 상태 직접 수정

`update_state()`로 외부에서 그래프의 상태를 직접 수정할 수 있습니다. 디버깅, 테스트, 또는 수동 개입이 필요한 경우에 유용합니다.

채널에 reducer가 있으면 값이 _병합_되고, reducer가 없으면 _덮어쓰기_됩니다. `MessagesState`의 `messages` 채널은 reducer로 append되므로 아래 호출은 메시지 목록 끝에 새 메시지를 추가합니다.

#code-block(`````python
# 현재 상태에 정보 추가
from langchain.messages import AIMessage

graph.update_state(config, {
    "messages": [AIMessage(content="(업데이트: 사용자는 고양이도 좋아합니다.)")]
})

result = graph.invoke(
    {"messages": [HumanMessage(content="제 선호에 대해 뭘 알고 있나요?")]},
    {**config, **lf_config}
)
print("상태 업데이트 후:", result["messages"][-1].content[:200])
`````)
#output-block(`````
상태 업데이트 후: 지금까지 말씀해 주신 내용을 바탕으로, 당신의 선호에 대해 다음과 같이 알고 있습니다:

1. **좋아하는 색:** 파랑
2. **좋아하는 음식:** 피자

혹시 더 공유하고 싶으신 취향이나 선호가 있으시면 알려주세요! 앞으로 대화에서 참고해서 더 맞춤형으로 답변드릴 수 있습니다. 😊
`````)

== 8.8 `version="v2"` — `GraphOutput`으로 인터럽트 분기 (LangGraph 1.1+)

v1의 `invoke()`는 state dict에 인터럽트 정보가 섞여 반환됩니다. 호출 측에서 _"이번 결과가 최종인지, 인터럽트 대기 중인지"_ 구분하려면 `graph.get_state(config)`를 따로 호출해야 했습니다.

v2에서는 _`GraphOutput` 객체_가 반환됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[속성],
  text(weight: "bold")[타입],
  text(weight: "bold")[설명],
  [`.value`],
  [`StateT`],
  [최종 state (Pydantic/dataclass면 자동 인스턴스화)],
  [`.interrupts`],
  [`tuple[Interrupt, ...]`],
  [실행 중 발생한 인터럽트 목록],
)

→ `if result.interrupts:` 한 줄로 분기 가능. 위 Common Patterns 코드도 모두 이 형태로 사용했습니다.

=== 서브그래프 타임트래블 버그 수정 (1.1)

LangGraph 1.1은 _인터럽트 + 서브그래프 타임트래블_에서 과거 `RESUME` 값을 재사용하던 버그도 함께 수정했습니다. 서브그래프를 쓰며 타임트래블하는 코드가 있다면 1.1로 올리고, 가능하면 `version="v2"`도 함께 적용하길 권장합니다.

#code-block(`````python
# 8.2절에서 만든 리뷰 그래프를 v2로 다시 호출
from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import InMemorySaver
from typing import TypedDict

class ReviewState(TypedDict):
    document: str
    approved: bool
    final_result: str

def draft(state):   return {"document": f"초안: {state.get('document','주제')}"}
def review(state):  return {"approved": interrupt({"q": "승인?"}) == "yes"}
def finalize(state):
    verdict = "승인" if state["approved"] else "거절"
    return {"final_result": f"{verdict}: {state['document']}"}

b = StateGraph(ReviewState)
b.add_node("draft", draft); b.add_node("review", review); b.add_node("finalize", finalize)
b.add_edge(START, "draft"); b.add_edge("draft", "review"); b.add_edge("review", "finalize"); b.add_edge("finalize", END)
v2_graph = b.compile(checkpointer=InMemorySaver())

cfg = {"configurable": {"thread_id": "v2-review"}}

# Step 1: v2로 실행 → GraphOutput 반환
out = v2_graph.invoke({"document": "AI 안전성"}, {**cfg, **lf_config}, version="v2")

print(f"type: {type(out).__name__}")
print(f"interrupts: {len(out.interrupts)}개")

# v2는 인터럽트 분기가 한 줄
if out.interrupts:
    for iq in out.interrupts:
        print(f"  질문: {iq.value}")
else:
    print(f"  완료 state: {out.value}")
`````)

#code-block(`````python
# Step 2: resume도 v2로 — 최종 state는 .value
out = v2_graph.invoke(Command(resume="yes"), {**cfg, **lf_config}, version="v2")

print(f"interrupts: {len(out.interrupts)}개")
print(f"최종: {out.value['final_result']}")

# v1 호환용 dict-스타일 접근도 여전히 동작 (deprecated)
# 마이그레이션 중 섞여 있어도 깨지지 않음
print(f"dict 접근(호환): {out['final_result']}")
`````)

#chapter-summary-header()

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[API],
  text(weight: "bold")[비고],
  [`interrupt(value)`],
  [`langgraph.types`],
  [실행 중단, JSON-serializable value 전달],
  [`Command(resume=value)`],
  [`langgraph.types`],
  [중단 지점에서 재개 — `True/False`, `str`, `dict`, `{id: 응답}` map 모두 가능],
  [_Approval_ 패턴],
  [`resume=True/False`],
  [critical action 승인/거부 + `Command(goto=...)`],
  [_Review & Edit_ 패턴],
  [`resume="edited text"`],
  [LLM 출력 검토·수정],
  [_Tool Interrupt_ 패턴],
  [`resume={"action": "approve", ...}`],
  [tool 함수 내부 interrupt, 부분 편집 가능],
  [_Input Validation_ 패턴],
  [노드당 한 번 `interrupt()`],
  [조건부 엣지로 유효한 값까지 재요청],
  [_Multiple Interrupts_ 패턴],
  [`resume={interrupt_id: 응답}`],
  [병렬 노드 동시 interrupt],
  [`get_state_history()`],
  [Graph],
  [체크포인트 이력 (최신순)],
  [_Replay_],
  [`invoke(None, prev.config)`],
  [그 시점부터 재실행 — LLM 호출은 다시 발생],
  [_Fork_],
  [`update_state(prev.config, values=..., as_node=...)` → `invoke(None, fork_config)`],
  [새 branch 생성 — 원본 thread 유지],
  [`update_state()`],
  [Graph],
  [외부에서 상태 수정 — reducer 있으면 병합, 없으면 덮어쓰기],
  [`invoke(..., version="v2")`],
  [LangGraph 1.1+],
  [`GraphOutput.value` / `.interrupts` 분기],
)

_핵심 규칙_:
- `interrupt()`를 try/except로 감싸지 말 것 (인터럽트 예외를 잡아버림)
- interrupt 호출 순서를 일관되게 유지 — 노드 내부 분기에 따라 reorder/skip 금지
- side effect는 interrupt 이후 또는 별도 노드에 둘 것 (재실행 시 중복 방지)
