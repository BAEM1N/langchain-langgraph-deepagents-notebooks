// Auto-generated from 08_multi_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "Multi", subtitle: "Agent Patterns")


== Learning Objectives

Understand and implement five multi-agent patterns.

This notebook covers:
- _Subagents_: the main agent calls specialized subagents as tools
- _Handoffs_: state transitions between agents with `Command(goto=...)`
- _Skills_: one agent loads specialized prompts depending on the task
- _Router_: a classifier routes input to the right agent
- _Custom_: developer-controlled complex workflows


== 8.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

print("Model ready:", model.model_name)
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

== 8.2 Comparing Multi-Agent Patterns

The table below compares five multi-agent patterns. Each one fits a different situation, so you should choose based on your project requirements.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Pattern],
  text(weight: "bold")[Routing Owner],
  text(weight: "bold")[State Sharing],
  text(weight: "bold")[Best Fit],
  [_Subagents_],
  [Main agent],
  [Isolated through tools],
  [Parallel work, distributed execution],
  [_Handoffs_],
  [Tool call],
  [State transition],
  [Sequential multi-hop flows],
  [_Skills_],
  [Single agent],
  [Prompt swapping],
  [Domain specialization],
  [_Router_],
  [Classifier],
  [Parallel execution],
  [Multi-domain systems],
  [_Custom_],
  [Developer-defined],
  [Full control],
  [Complex workflows],
)

=== Key differences
- _Subagents_ run independently and return only the result
- _Handoffs_ pass conversation state between agents
- _Skills_ let one agent switch roles
- _Router_ classifies input and delegates it to the right specialist


== 8.3 The Subagent Pattern

In this pattern, the main agent (supervisor) calls specialized subagents _as tools_.

=== Characteristics
- Each subagent is wrapped in a tool function
- The main agent decides which subagent to call
- The internal state of each subagent is isolated from the main agent
- Parallel execution is possible, which can improve performance


#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

# Define specialist tools
@tool
def math_expert(question: str) -> str:
    """Solves math problems. Use it when mathematical calculation is needed."""
    # Actual calculation logic would go here
    return f"Math answer: '{question}'was calculated."

@tool
def code_expert(question: str) -> str:
    """Answers programming questions. Use it for coding-related tasks."""
    return f"Code answer: '{question}'solution for the request"

@tool
def general_search(query: str) -> str:
    """Searches for general information."""
    return f"'{query}'search result for"

# Supervisor agent
supervisor = create_agent(
    model=model,
    tools=[math_expert, code_expert, general_search],
    system_prompt="""You are a supervisor agent that delegates tasks to specialists:
- Use math_expert for math questions
- Use code_expert for programming questions
- Use general_search for everything else
Always delegate to the most appropriate specialist.""",
)

result = supervisor.invoke(
    {"messages": [{"role": "user", "content": "What is the factorial of 10?"}]},
    config=lf_config,
)
print("Subagent result:", result["messages"][-1].content)
`````)

== 8.4 The Handoff Pattern

This pattern uses `Command(goto=...)` to _transfer state_ between agents.

=== Characteristics
- A tool returns a `Command` object that routes execution to another agent
- Conversation state (message history) is passed to the next agent
- A `StateGraph` defines the flow between agents
- This fits multi-hop scenarios such as customer-service transfers


#code-block(`````python
from langgraph.types import Command
from langgraph.graph import StateGraph, START, END, MessagesState

# Tools for handoffs
@tool
def transfer_to_sales() -> Command:
    """Transfers the conversation to the sales team."""
    return Command(goto="sales_agent", graph=Command.PARENT)

@tool
def transfer_to_support() -> Command:
    """Transfers the conversation to technical support."""
    return Command(goto="support_agent", graph=Command.PARENT)

@tool
def resolve_query(answer: str) -> str:
    """Provides the final answer to the user."""
    return answer

# Router agent
router_agent = create_agent(
    model=model,
    tools=[transfer_to_sales, transfer_to_support],
    system_prompt="You are a front desk agent. Route the customer to the appropriate team.",
    name="router",
)

# Sales agent
sales_agent = create_agent(
    model=model,
    tools=[resolve_query],
    system_prompt="You are a sales agent. Help with pricing and product questions.",
    name="sales_agent",
)

# Support agent
support_agent = create_agent(
    model=model,
    tools=[resolve_query],
    system_prompt="You are a technical support agent. Help with technical issues.",
    name="support_agent",
)

# Build the handoff graph
builder = StateGraph(MessagesState)
builder.add_node(router_agent)
builder.add_node(sales_agent)
builder.add_node(support_agent)
builder.add_edge(START, "router")

graph = builder.compile()

result = graph.invoke(
    {"messages": [{"role": "user", "content": "I want to know the price of the enterprise plan."}]},
    config=lf_config,
)
print("Handoff result:", result["messages"][-1].content)
`````)

== 8.5 The Skill Pattern

A single agent dynamically _loads a specialized prompt_ depending on the task.

=== Characteristics
- One agent has multiple skills
- Each skill is implemented as a specialized system prompt
- The agent dynamically loads the skill it needs
- One agent can handle many tasks without managing multiple separate agents


#code-block(`````python
# Skill definitions
skills = {
    "translator": "You are an expert translator. Translate text accurately between languages.",
    "summarizer": "You are an expert summarizer. Summarize long text concisely.",
    "coder": "You are an expert programmer. Write clean and efficient code.",
}

@tool
def load_skill(skill_name: str) -> str:
    """Loads a specialist skill. Available skills: translator, summarizer, coder."""
    if skill_name in skills:
        return f"Skill loaded: {skill_name}. Instructions: {skills[skill_name]}"
    return f"Unknown skill: {skill_name}. Available: {list(skills.keys())}"

skill_agent = create_agent(
    model=model,
    tools=[load_skill],
    system_prompt="""You are a versatile assistant with access to specialist skills.
Load the appropriate skill before handling the user request.""",
)

result = skill_agent.invoke(
    {"messages": [{"role": "user", "content": "Please translate \"Hello World\" into Korean and Japanese."}]},
    config=lf_config,
)
print("Skill pattern result:", result["messages"][-1].content)
`````)

== 8.6 The Router Pattern

A classifier _routes_ input to the most appropriate agent.

=== Characteristics
- The query is classified first
- It is then delegated to the right specialist agent or tool
- This is useful in multi-domain systems
- Routing logic can be rule-based or model-based


#code-block(`````python
from langgraph.types import Send

@tool
def classify_query(query: str) -> str:
    """Classifies a query into math, code, or general."""
    query_lower = query.lower()
    if any(w in query_lower for w in ["calculate", "math", "sum", "multiply"]):
        return "math"
    elif any(w in query_lower for w in ["code", "program", "function", "python"]):
        return "code"
    return "general"

# Router: hand off to the specialist agent based on the classification
router = create_agent(
    model=model,
    tools=[classify_query, math_expert, code_expert, general_search],
    system_prompt="""You are a routing agent. First classify the query, then hand it to the appropriate specialist:
- Math query -> use math_expert
- Code query -> use code_expert
- General query -> use general_search""",
)

result = router.invoke(
    {"messages": [{"role": "user", "content": "Please write a Python function that sorts a list."}]},
    config=lf_config,
)
print("Router result:", result["messages"][-1].content)
`````)

== 8.7 Choosing a Pattern

Which multi-agent pattern should you choose? Use the guide below.

=== Decision tree

+ _Can the agents work independently?_
- YES → _Subagents_ (parallel execution, result aggregation)
- NO → move to the next question

+ _Must conversation state be passed between agents?_
- YES → _Handoffs_ (state transition, multi-hop)
- NO → move to the next question

+ _Can a single agent just switch roles?_
- YES → _Skills_ (prompt switching)
- NO → move to the next question

+ _Is classifying input and sending it to a handler enough?_
- YES → _Router_ (classify and delegate)
- NO → _Custom_ (fully custom graph)

=== Practical guidance
- Start with the _simplest pattern_ (usually Subagents or Skills)
- Move to Handoffs or Router only when requirements become more complex
- Use a Custom pattern only when the other patterns are not enough
- You can also _combine_ patterns (for example, Router + Handoffs)


== 8.8 Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Pattern],
  text(weight: "bold")[Core API],
  text(weight: "bold")[When to use it],
  [_Subagents_],
  [`create_agent` + tool functions],
  [Independent parallel work],
  [_Handoffs_],
  [`Command(goto=...)`, `StateGraph`],
  [Multi-hop state transfer],
  [_Skills_],
  [Load prompts as tools],
  [One agent with many roles],
  [_Router_],
  [Classifier tool + specialist tools],
  [Multi-domain classification],
  [_Custom_],
  [Full `StateGraph` control],
  [Complex business logic],
)

=== Key principles
- Start simple and increase complexity only when necessary
- Design each agent around _one clear responsibility_
- Define the _interfaces_ between agents (inputs and outputs) clearly

=== Next Steps
→ _#link("./09_custom_workflow_and_rag.ipynb")[09_custom_workflow_and_rag.ipynb]_: Learn about custom workflows and RAG.
