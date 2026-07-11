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

#code-block(`````python
# Optional observability setup: LangSmith or Langfuse
# Set the keys in .env, or uncomment the lines below to enter them manually.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: automatically enabled when LANGSMITH_TRACING=true
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: pass config={"callbacks": [langfuse_handler]} to invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 3.2 The Limit of an Agent Without Memory

A basic agent _does not store state_. Each call is treated like a new conversation.


#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

# Agent without memory
agent_no_mem = create_agent(model=model, tools=[add])

r1 = agent_no_mem.invoke({"messages": [{"role": "user", "content": "What is 3 + 4?"}]}, config=lf_config)
print("Turn 1:", r1["messages"][-1].content)

# The agent cannot remember the previous result
r2 = agent_no_mem.invoke({"messages": [{"role": "user", "content": "Add 10 to the previous result."}]}, config=lf_config)
print("Turn 2:", r2["messages"][-1].content)

`````)

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

#code-block(`````python
# First question
r1 = agent.invoke(
    {"messages": [{"role": "user", "content": "What is 7 + 8?"}]},
    config={**config, **lf_config},
)
print("Turn 1:", r1["messages"][-1].content)

# Second question that depends on the previous context
r2 = agent.invoke(
    {"messages": [{"role": "user", "content": "Now multiply that result by 2."}]},
    config={**config, **lf_config},
)
print("Turn 2:", r2["messages"][-1].content)

`````)

== 3.4 Watching the Steps with Streaming

Use `agent.stream()` to observe each step of the agent in real time.

Agent streaming is useful when an agent runs for a while and you want to inspect intermediate steps as they happen. With `stream_mode="updates"`, you receive updates from each node individually, such as model calls and tool execution results. This lets you see what the agent is doing step by step.


#code-block(`````python
config2 = {"configurable": {"thread_id": "session-2"}}

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Add 100 and 200, then add 50 to the result."}]},
    config={**config2, **lf_config},
    stream_mode="updates",
):
    for node_name, update in chunk.items():
        if "messages" in update:
            last = update["messages"][-1]
            if hasattr(last, "content") and last.content:
                print(f"[{node_name}] {last.content[:200]}")

`````)

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
→ _#link("./04_langgraph_basics.ipynb")[04_langgraph_basics.ipynb]_: Build a workflow with LangGraph.
