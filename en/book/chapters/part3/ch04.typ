// Auto-generated from 04_workflows.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "workflow Pattern", subtitle: "5 core patterns")

== Learning Objectives

Understand Prompt Chaining, Parallelization, Routing, Orchestrator-Worker, and Evaluator-Optimizer patterns.

== 4.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 4.2 Prompt Chaining — Sequential LLM calls

- The output of each step becomes the input of Next Steps
- Purpose: Translation → Verification → Proofreading, Analysis → Summary → Formatting

== 4.3 Parallelization — Simultaneous execution of independent `\@task`

== 4.4 Routing — Classification-based branching

#image("../../../../book/assets/diagrams/png/conditional_routing.png")

== 4.5 Orchestrator-Worker — Create dynamic worker with Send()

#image("../../../../book/assets/diagrams/png/orchestrator_worker.png")

== 4.6 Evaluator-Optimizer — Generate-evaluation iteration loop

== 4.7 Pattern comparison table

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[pattern],
  text(weight: "bold")[decisive],
  text(weight: "bold")[Parallel],
  text(weight: "bold")[repeat],
  text(weight: "bold")[suitable situation],
  [Prompt Chaining],
  [O],
  [X],
  [sequential],
  [Step-by-step conversion],
  [Parallelization],
  [O],
  [O],
  [X],
  [Independent Analysis],
  [Routing],
  [O],
  [X],
  [X],
  [Classification-based processing],
  [Orchestrator-Worker],
  [O],
  [O],
  [X],
  [Dynamic Subtasks],
  [Evaluator-Optimizer],
  [X],
  [X],
  [O],
  [Quality Improvement Loop],
)

=== Next Steps
→ _#link("./05_agents.ipynb")[05_agents.ipynb]_: Build ReAct agent.
