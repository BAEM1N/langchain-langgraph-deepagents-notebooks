// Auto-generated from 09_subgraphs.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "Subgraph", subtitle: "Graph within a graph")

== Learning Objectives

Modularize complex workflow with subgraphs.

== 9.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

#code-block(`````python
# Observability settings (optional) - LangSmith or Langfuse
# Set the key in .env, or uncomment it below and enter it yourself.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: Automatically activated when LANGSMITH_TRACING=true (no code modification required)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON \u2014 project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: Pass config={"callbacks": [langfuse_handler]} when calling invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON \u2014 {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 9.2 Subgraph concept

- _Subgraph_: Independent graph used as a node in another graph
- _Advantages_: Modularization, reuse, independent development by team
- Each subgraph has its own state(State)
- state between parent \<-\> subgraph is mapped to _shared key_

== 9.3 Creating a subgraph

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict, Annotated
import operator

# === Subgraph 1: Text Analysis ===
class AnalysisState(TypedDict):
    text: str
    word_count: int
    char_count: int

def count_words(state: AnalysisState) -> dict:
    return {"word_count": len(state["text"].split())}

def count_chars(state: AnalysisState) -> dict:
    return {"char_count": len(state["text"])}

analysis_builder = StateGraph(AnalysisState)
analysis_builder.add_node("words", count_words)
analysis_builder.add_node("chars", count_chars)
analysis_builder.add_edge(START, "words")
analysis_builder.add_edge("words", "chars")
analysis_builder.add_edge("chars", END)
analysis_subgraph = analysis_builder.compile()

# Test subgraph independently
result = analysis_subgraph.invoke({"text": "Greetings from LangGraph"}, config=lf_config)
print(f"Subgraph test: words={result['word_count']}, chars={result['char_count']}")
`````)

== 9.4 Adding a subgraph to the parent graph

#code-block(`````python
# === Parent Graph: Text Pipeline ===

class PipelineState(TypedDict):
    text: str
    word_count: int
    char_count: int
    summary: str


def create_summary(state: PipelineState) -> dict:
    return {
        "summary": f"The text contains {state['word_count']} words and {state['char_count']} characters."
    }


parent_builder = StateGraph(PipelineState)

# Add subgraph as a node (shared keys: text, word_count, char_count)
parent_builder.add_node("analyze", analysis_subgraph)
parent_builder.add_node("summarize", create_summary)

parent_builder.add_edge(START, "analyze")
parent_builder.add_edge("analyze", "summarize")
parent_builder.add_edge("summarize", END)

pipeline = parent_builder.compile()

result = pipeline.invoke(
    {
        "text": "LangGraph enables the powerful state based agent workflow"
    },
    config=lf_config
)

print(f"Summary: {result['summary']}")
`````)

== 9.4.1 Pattern 1: Subgraph call through wrapper node (if `state_schema` is different)

In the above example (9.4), the parent graph and subgraph shared _the same keys_ (`text`, `word_count`, `char_count`), so the compiled subgraph could be passed directly to `add_node()`.

However, in practice, the parent graph and subgraph often have completely different _state schemas_. In this case, use a _wrapper function_ to:

+ _Extract_ the required fields from the parent state and convert them to subgraph input.
+ _Run_ the subgraph
+ _Map_ the subgraph output to the parent state format.

Use the pattern. This is how the official documentation calls it _Pattern 1: Call Subgraph Inside a Node_.

#code-block(`````python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END


# ── Step 1: Subgraph definition (self `state_schema`: SubState) ──
class SubState(TypedDict):
    log_entry: str
    sentiment: str
    confidence: float


def analyze_sentiment(state: SubState) -> dict:
    """Simple rule-based sentiment analysis"""
    text = state["log_entry"].lower()

    positive_words = {
        "good", "great", "excellent", "happy", "love", "amazing", "wonderful"
    }

    negative_words = {
        "bad", "terrible", "awful", "hate", "poor", "horrible", "sad"
    }

    pos = sum(1 for w in text.split() if w in positive_words)
    neg = sum(1 for w in text.split() if w in negative_words)

    total = pos + neg

    if total == 0:
        return {"sentiment": "neutral", "confidence": 0.5}

    elif pos > neg:
        return {"sentiment": "positive", "confidence": round(pos / total, 2)}

    else:
        return {"sentiment": "negative", "confidence": round(neg / total, 2)}


sub_builder = StateGraph(SubState)

sub_builder.add_node("analyze_sentiment", analyze_sentiment)
sub_builder.add_edge(START, "analyze_sentiment")
sub_builder.add_edge("analyze_sentiment", END)

sentiment_subgraph = sub_builder.compile()


# Subgraph stand-alone test
sub_result = sentiment_subgraph.invoke(
    {"log_entry": "The product is great and amazing"},
    config=lf_config
)

print(
    f"[Standalone subgraph test] sentiment={sub_result['sentiment']}, confidence={sub_result['confidence']}"
)


# ── Step 2: Define the parent graph (other `state_schema`: ParentState) ──
class ParentState(TypedDict):
    customer_name: str
    feedback_text: str
    analysis_result: str


# ── Step 3: Wrapper function — state The key to conversion ──
def call_sentiment_subgraph(state: ParentState) -> dict:
    """What the wrapper function does:

    1) ‘feedback_text’ of parent state → converted to ‘log_entry’ of subgraph
    2) Subgraph execution
    3) Map subgraph output to ‘analysis_result’ of parent state"""

    # Parent → Subgraph: state conversion
    subgraph_input = {
        "log_entry": state["feedback_text"]
    }

    # Subgraph execution
    subgraph_output = sentiment_subgraph.invoke(
        subgraph_input,
        config=lf_config
    )

    # Subgraph → Parent: Result Mapping
    result_str = (
        f"{subgraph_output['sentiment']} "
        f"(confidence: {subgraph_output['confidence']})"
    )

    return {"analysis_result": result_str}


def generate_report(state: ParentState) -> dict:
    """Generate final report"""
    report = (
        f"[Report] {state['customer_name']}: "
        f"{state['analysis_result']}"
    )

    return {"analysis_result": report}


# ── Step 4: Constructing the parent graph ──
parent_builder = StateGraph(ParentState)

parent_builder.add_node("sentiment_analysis", call_sentiment_subgraph)
parent_builder.add_node("report", generate_report)

parent_builder.add_edge(START, "sentiment_analysis")
parent_builder.add_edge("sentiment_analysis", "report")
parent_builder.add_edge("report", END)

parent_graph = parent_builder.compile()


# execution
result = parent_graph.invoke(
    {
        "customer_name": "Alice",
        "feedback_text": "The product is great and the service was excellent",
    },
    config=lf_config
)

print(f"\n[Final result] {result['analysis_result']}")


# Additional tests with different inputs
result2 = parent_graph.invoke(
    {
        "customer_name": "Bob",
        "feedback_text": "The experience was terrible and the quality is poor",
    },
    config=lf_config
)

print(f"[Final result] {result2['analysis_result']}")
`````)

== 9.5 LLM-based subgraph

Organize the full text agent into subgraphs.

#code-block(`````python
from langchain.messages import HumanMessage, AnyMessage
from langgraph.graph import MessagesState

# Subgraph: Translation Agent
def translator(state: MessagesState) -> dict:
    response = model.invoke(
        state["messages"] + [HumanMessage(content="Please translate the above into Korean. Please only translate.")],
        config=lf_config,
)
    return {"messages": [response]}

translator_builder = StateGraph(MessagesState)
translator_builder.add_node("translate", translator)
translator_builder.add_edge(START, "translate")
translator_builder.add_edge("translate", END)
translator_subgraph = translator_builder.compile()

# Subgraph: Summarization Agent
def summarizer(state: MessagesState) -> dict:
    response = model.invoke(
        state["messages"] + [HumanMessage(content="Please Summary the above in one sentence.")],
        config=lf_config,
)
    return {"messages": [response]}

summarizer_builder = StateGraph(MessagesState)
summarizer_builder.add_node("summarize", summarizer)
summarizer_builder.add_edge(START, "summarize")
summarizer_builder.add_edge("summarize", END)
summarizer_subgraph = summarizer_builder.compile()

# Parent: Translate-then-Summarize Pipeline
parent_builder = StateGraph(MessagesState)
parent_builder.add_node("translator", translator_subgraph)
parent_builder.add_node("summarizer", summarizer_subgraph)
parent_builder.add_edge(START, "translator")
parent_builder.add_edge("translator", "summarizer")
parent_builder.add_edge("summarizer", END)

pipeline = parent_builder.compile()

result = pipeline.invoke({
    "messages": [HumanMessage(content="LangGraph is a framework for building state based multi-actor applications using LLM.")]
}, config=lf_config)
print("Final output:", result["messages"][-1].content)
`````)

== 9.6 Subgraph streaming

Steps inside a subgraph are also streaming possible.

#code-block(`````python
print("Subgraph streaming:")
for chunk in pipeline.stream(
    {"messages": [HumanMessage(content="Python is a general-purpose programming language.")]},
    stream_mode="updates",
    subgraphs=True,
    config=lf_config,
):
    if isinstance(chunk, tuple) and len(chunk) == 2:
        ns, update = chunk
        for node, data in update.items():
            prefix = f"[{'/'.join(ns)}]" if ns else "[root]"
            print(f"  {prefix} {node}")
`````)

== 9.7 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[concept],
  text(weight: "bold")[Description],
  [Subgraph],
  [Using independently compiled graphs as nodes],
  [shared key],
  [state mapping between parent and subgraph],
  [Modularization],
  [Separating complex workflow into smaller units],
  [streaming],
  [Track internal steps with `subgraphs=True`],
)

=== Next Steps
→ _#link("./10_production.ipynb")[10_production.ipynb]_: Learn production deployment.
