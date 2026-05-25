// Auto-generated from 03_langchain_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "LangChain Conversations", subtitle: "Multi-Turn Memory")

Connect `InMemorySaver` so the agent can remember previous turns.


== Learning Objectives

- Store conversation state with `InMemorySaver`
- Distinguish conversation sessions with `thread_id`
- Run a multi-turn conversation where the agent remembers earlier context


== 3.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
print("✓ Model ready")

`````)

== 3.2 The Limit of an Agent Without Memory

A basic agent _does not store state_. Each call is treated like a new conversation.


== 3.3 Adding Memory with InMemorySaver

If you set a `checkpointer`, the agent stores the conversation history.
A `thread_id` distinguishes one conversation session from another.

_Short-term memory_ means keeping information from earlier interactions within a single conversation thread. This is essential for agents that handle complex tasks across several user turns.

Implementation pattern:
- Pass `InMemorySaver()` as the `checkpointer` parameter to enable memory.
- Use `thread_id` to distinguish different conversation sessions. If you reuse the same `thread_id`, the agent remembers the previous conversation.
- In production, you can switch to a database-backed checkpointer such as `PostgresSaver` for persistence.

If a conversation becomes very long, it may exceed the token budget. In that case, manage the history with strategies such as trimming, deletion, or summarization.


#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    model=model,
    tools=[add],
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": "session-1"}}
print("✓ Memory-enabled agent created")

`````)

== 3.4 Watching the Steps with Streaming

Use `agent.stream()` to observe each step of the agent in real time.

Agent streaming is useful when an agent runs for a while and you want to inspect intermediate steps as they happen. With `stream_mode="updates"`, you receive updates from each node individually, such as model calls and tool execution results. This lets you see what the agent is doing step by step.


== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Concept],
  text(weight: "bold")[Description],
  [`InMemorySaver`],
  [Stores conversation state in memory (checkpointer)],
  [`thread_id`],
  [Key that separates conversation sessions],
  [`checkpointer=`],
  [Passes a checkpointer into `create_agent()`],
  [`stream(mode="updates")`],
  [Shows the agent's execution steps in real time],
)

=== Next Steps
→ _#link("./04_langgraph_basics_en.ipynb")[04_langgraph_basics_en.ipynb]_: Build a workflow with LangGraph.

