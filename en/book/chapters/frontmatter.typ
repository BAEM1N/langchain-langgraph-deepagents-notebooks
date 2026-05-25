// frontmatter.typ — English cover, preface, table of contents
#import "../metadata.typ": *
#import "../template.typ": *

#page(
  header: none,
  footer: none,
  fill: white,
  margin: 0mm,
)[
  #place(top + left, rect(width: 100%, height: 3pt, fill: color-primary))

  #place(right + top, dx: -32pt, dy: 48pt)[
    #image("../../../book/assets/baeumai-symbol.png", width: 72pt)
  ]

  #pad(left: 48pt, right: 48pt, top: 72pt)[
    #text(size: 9pt, fill: luma(140), tracking: 5pt, weight: "medium", font: font-body)[
      BAEUM.AI
    ]
  ]

  #pad(left: 48pt, right: 180pt, top: 24pt)[
    #text(size: 46pt, weight: "bold", fill: color-secondary, font: font-body)[
      Agent
    ]
    #v(-6pt)
    #text(size: 46pt, weight: "bold", fill: color-secondary, font: font-body)[
      Handbook
    ]
    #v(20pt)

    #text(size: 14pt, fill: luma(120), font: font-body)[
      with LangChain, LangGraph & Deep Agents
    ]

    #v(36pt)
    #line(length: 60pt, stroke: 1.5pt + color-primary)
    #v(32pt)

    #text(size: 13pt, fill: luma(100), font: font-body)[
      A Practical Guide to AI Agent Development
    ]
  ]

  #v(1fr)

  #pad(left: 48pt, right: 48pt, bottom: 36pt)[
    #line(length: 100%, stroke: 0.3pt + luma(220))
    #v(14pt)
    #grid(
      columns: (auto, 1fr, auto),
      column-gutter: 12pt,
      align: (left + horizon, left + horizon, right + horizon),
      image("../../../book/assets/baeumai-logo.png", height: 16pt),
      [],
      text(size: 10pt, fill: luma(150), font: font-body)[#book-date],
    )
  ]
]

#page(header: none, footer: none)[
  #v(1fr)
  #set text(size: 8.5pt, fill: luma(130))
  #set par(leading: 0.7em)

  #text(weight: "bold", size: 9pt, fill: luma(80))[#book-full-title]

  #v(16pt)
  Copyright #sym.copyright #book-date #book-author. All rights reserved.

  #v(4pt)
  The code examples in this book may be freely used for educational purposes.\
  Unauthorized reproduction or redistribution of the written content is prohibited.

  #v(20pt)
  #text(fill: luma(160))[First edition: #book-date]
]

#pagebreak()
#v(24pt)

#line(length: 40pt, stroke: 1.5pt + color-primary)
#v(6pt)
#text(size: 26pt, weight: "bold", fill: color-secondary, font: font-body)[Preface]
#v(24pt)

#set text(size: 10pt, fill: luma(50))
#set par(leading: 0.85em)

AI agents go beyond simple chatbots. They are intelligent systems that use tools, make plans, and autonomously carry out complex tasks. This handbook presents a structured, hands-on path to building real-world AI agents with three major frameworks — *LangChain*, *LangGraph*, and *Deep Agents*.

#v(16pt)

#block(
  width: 100%,
  fill: rgb("#FAFAFA"),
  stroke: (left: 3pt + color-primary),
  inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
  radius: (top-right: 3pt, bottom-right: 3pt),
  breakable: false,
)[
  #text(weight: "bold", fill: color-secondary, size: 11pt)[What This Book Offers]
  #v(8pt)
  #set text(size: 9.5pt)
  - *Hands-on learning* --- Includes 59 Jupyter notebook-based examples with code and outputs
  - *Progressive difficulty* --- Moves step by step from fundamentals to production deployment
  - *Framework comparison* --- Compares the strengths and best-fit use cases of each framework
  - *Applied projects* --- Builds RAG, SQL, data analysis, ML, and deep research agents
]

#v(14pt)

#block(
  width: 100%,
  fill: rgb("#FAFAFA"),
  stroke: (left: 3pt + luma(200)),
  inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
  radius: (top-right: 3pt, bottom-right: 3pt),
  breakable: false,
)[
  #text(weight: "bold", fill: color-secondary, size: 11pt)[Target Audience]
  #v(8pt)
  #set text(size: 9.5pt)
  - Developers who know basic Python syntax
  - Engineers who want to build LLM-powered applications
  - Learners who want a structured path into AI agent architecture
]

#v(24pt)

#text(weight: "bold", fill: color-secondary, size: 11pt)[How This Book Is Organized]
#v(10pt)

#table(
  columns: (auto, 1fr, auto),
  align: (center, left, center),
  fill: (_, row) => if row == 0 { color-secondary } else if calc.odd(row) { rgb("#FAFAFA") } else { white },
  stroke: 0.5pt + luma(230),
  inset: 8pt,
  text(weight: "bold", fill: white, size: 9pt)[Part],
  text(weight: "bold", fill: white, size: 9pt)[Topic],
  text(weight: "bold", fill: white, size: 9pt)[Chapters],
  text(fill: color-primary-dark, weight: "bold")[I], [Agent Foundations --- from environment setup to the basics of the three frameworks], [8],
  text(fill: color-primary-dark, weight: "bold")[II], [LangChain --- models, tools, memory, middleware, and multi-agent patterns], [13],
  text(fill: color-primary-dark, weight: "bold")[III], [LangGraph --- state graphs, workflows, persistence, and subgraphs], [13],
  text(fill: color-primary-dark, weight: "bold")[IV], [Deep Agents --- backends, subagents, memory, and harnesses], [10],
  text(fill: color-primary-dark, weight: "bold")[V], [Advanced Patterns --- multi-agent systems, RAG, SQL, and production], [10],
  text(fill: color-primary-dark, weight: "bold")[VI], [Applied Examples --- five end-to-end agent projects], [5],
)

#v(8pt)
#set text(size: 9.5pt, fill: luma(100))
Each chapter follows a consistent structure: Learning Objectives #sym.arrow.r theory #sym.arrow.r hands-on code #sym.arrow.r Summary.

#pagebreak()
#v(50pt)
#line(length: 40pt, stroke: 1.5pt + color-primary)
#v(8pt)
#text(size: 26pt, weight: "bold", fill: color-secondary, font: font-body)[How to Use This Book]
#v(24pt)

#text(weight: "bold", fill: color-secondary, size: 11pt)[Reading Code Blocks]
#v(8pt)
#set text(size: 10pt)

This handbook uses two main block styles:

#v(4pt)

#code-block(```python
# Python code block — mint left border
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
result = model.invoke("Hello, Agent!")
```)

#output-block(```
Output block — coral left border
Hello! I'm an AI agent ready to help.
```)

#v(12pt)

#text(weight: "bold", fill: color-secondary, size: 11pt)[Callout Types]
#v(8pt)

#tip-box[Provides a useful tip or extra information.]
#note-box[Explains an important note or background concept.]
#warning-box[Warns about caution points or common mistakes.]

#v(16pt)

#text(weight: "bold", fill: color-secondary, size: 11pt)[Practice Environment]
#v(8pt)
#set text(size: 9.5pt)

All code has been tested with Python 3.11+. Package installation and API key setup are covered in the first chapter of Part I.

#pagebreak()
#v(24pt)

#line(length: 40pt, stroke: 1.5pt + color-primary)
#v(8pt)
#text(size: 26pt, weight: "bold", fill: color-secondary, font: font-body)[Table of Contents]
#v(16pt)
#outline(depth: 2)
