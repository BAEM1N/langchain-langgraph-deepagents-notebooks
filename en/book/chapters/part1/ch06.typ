// Auto-generated from 06_comparison.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Comparing the Three Frameworks & Choosing What Comes Next")

Compare LangChain, LangGraph, and Deep Agents at a glance, then decide where to continue next.


== Learning Objectives

- Understand the _core differences_ between LangChain, LangGraph, and Deep Agents
- Judge the _best-fit use cases_ for each framework
- Choose a _learning path_ into the intermediate tracks


== 6.1 Framework Comparison

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[_Level of abstraction_],
  text(weight: "bold")[High],
  text(weight: "bold")[Medium],
  text(weight: "bold")[Very high],
  [_Core concept_],
  [Agents + tools],
  [Graphs + state + nodes],
  [All-in-one agents],
  [_Agent creation_],
  [`create_agent()`],
  [`StateGraph` → `compile()`],
  [`create_deep_agent()`],
  [_Execution_],
  [`agent.invoke()`],
  [`graph.invoke()`],
  [`agent.invoke()`],
  [_Customization_],
  [Tools / prompts / memory],
  [Nodes / edges / state / reducers],
  [Tools / backends / subagents],
  [_Best fit_],
  [Fast prototyping],
  [Complex workflows],
  [Agents that need file and task management],
)

_Additional comparison details:_

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Feature],
  text(weight: "bold")[LangChain],
  text(weight: "bold")[LangGraph],
  text(weight: "bold")[Deep Agents],
  [_Model support_],
  [Model-agnostic (100+ providers)],
  [Shares LangChain model integrations],
  [Shares LangChain model integrations],
  [_License_],
  [MIT],
  [MIT],
  [MIT],
  [_Sandbox integration_],
  [No built-in support],
  [No built-in support],
  [Agents can run tasks in sandboxes],
  [_State management_],
  [Middleware-based],
  [Checkpointer-based (supports time travel)],
  [Reuses LangGraph checkpointers],
  [_Observability_],
  [LangSmith integration],
  [Native LangSmith tracing],
  [LangSmith support],
)

The three frameworks are not mutually exclusive. Deep Agents uses LangGraph internally and shares LangChain's model and tool interfaces. A natural learning path is to build your foundations with LangChain, design complex workflows with LangGraph, and then create production-grade agents with Deep Agents.


== 6.2 Which One Should You Choose?

#code-block(`````python
"I need a simple tool-calling agent."             → LangChain
"I need a workflow with branching and loops."     → LangGraph
"I want file operations and planning in one place." → Deep Agents
`````)

#tip-box[The three frameworks are not mutually exclusive. Deep Agents uses LangGraph internally and shares LangChain's model and tool interfaces.]


== 6.3 Code Comparison — The Same Task in Three Styles

Below is the smallest working version of the same task implemented with each framework.

=== LangChain
#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

agent = create_agent(model=model, tools=[add])
agent.invoke({"messages": [{"role": "user", "content": "3+4?"}]})
`````)

=== LangGraph
#code-block(`````python
from langgraph.graph import StateGraph, START, END, MessagesState

def chatbot(state):
    return {"messages": [model.invoke(state["messages"])]}

builder = StateGraph(MessagesState)
builder.add_node("chat", chatbot)
builder.add_edge(START, "chat")
builder.add_edge("chat", END)
graph = builder.compile()
graph.invoke({"messages": [{"role": "user", "content": "3+4?"}]})
`````)

=== Deep Agents
#code-block(`````python
from deepagents import create_deep_agent

agent = create_deep_agent(model=model)
agent.invoke({"messages": [{"role": "user", "content": "3+4?"}]})
`````)


== Summary

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[LangChain],
  text(weight: "bold")[LangGraph],
  text(weight: "bold")[Deep Agents],
  [Core role],
  [Agent creation (ReAct loop)],
  [Workflow orchestration (state graphs)],
  [All-in-one agents (built-in tools)],
  [State management],
  [Middleware-oriented],
  [Explicit `StateGraph` state],
  [Automated (filesystem + memory)],
  [Best for],
  [Fast prototyping, tool calling],
  [Complex workflows, branching],
  [Coding agents, data analysis, multi-step work],
  [Learning curve],
  [Low],
  [Medium],
  [Low],
)


== 6.4 What Comes Next

=== Mini Project
→ _#link("./07_mini_project.ipynb")[07_mini_project.ipynb]_: Build a search + summarization agent

=== Intermediate Tracks

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Track],
  text(weight: "bold")[Description],
  text(weight: "bold")[Notebook Count],
  [LangChain],
  [Models, messages, tools, memory, middleware, multi-agent patterns],
  [13],
  [LangGraph],
  [Graph API, workflows, agents, persistence, subgraphs],
  [13],
  [Deep Agents],
  [Customization, backends, subagents, memory, advanced features],
  [10],
)

Recommended order:
+ _LangChain_ — strengthen your model and tool fundamentals
+ _LangGraph_ — design graph-based workflows
+ _Deep Agents_ — build production-ready agents

The English intermediate notebooks will be translated next in this same order.
