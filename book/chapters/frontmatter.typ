// frontmatter.typ — Cover, preface, table of contents
#import "../metadata.typ": *
#import "../template.typ": *

// ─── Cover Page ───────────────────────────────────────────────
#page(
  header: none,
  footer: none,
  fill: white,
  margin: 0mm,
)[
  // 상단 민트 얇은 라인
  #place(top + left, rect(width: 100%, height: 3pt, fill: color-primary))

  // 우측 상단 심볼
  #place(right + top, dx: -32pt, dy: 48pt)[
    #image("../assets/baeumai-symbol.png", width: 72pt)
  ]

  // 카테고리
  #pad(left: 48pt, right: 48pt, top: 72pt)[
    #text(size: 9pt, fill: luma(140), tracking: 5pt, weight: "medium", font: font-body)[
      BAEUM.AI
    ]
  ]

  // 메인 타이틀
  #pad(left: 48pt, right: 180pt, top: 24pt)[
    #text(size: 46pt, weight: "bold", fill: color-secondary, font: font-body)[
      Agent
    ]
    #v(-6pt)
    #text(size: 46pt, weight: "bold", fill: color-secondary, font: font-body)[
      Handbook
    ]
    #v(20pt)

    // 서브타이틀 — 한 줄
    #text(size: 14pt, fill: luma(120), font: font-body)[
      with LangChain, LangGraph & DeepAgents
    ]

    #v(36pt)

    // 구분선
    #line(length: 60pt, stroke: 1.5pt + color-primary)

    #v(32pt)

    // 설명
    #text(size: 13pt, fill: luma(100), font: font-body)[
      AI 에이전트 개발 가이드
    ]
  ]

  #v(1fr)

  // 하단 로고
  #pad(left: 48pt, right: 48pt, bottom: 36pt)[
    #line(length: 100%, stroke: 0.3pt + luma(220))
    #v(14pt)
    #grid(
      columns: (auto, 1fr, auto),
      column-gutter: 12pt,
      align: (left + horizon, left + horizon, right + horizon),
      image("../assets/baeumai-logo.png", height: 16pt),
      [],
      text(size: 10pt, fill: luma(150), font: font-body)[#book-date],
    )
  ]
]

// ─── Copyright Page ───────────────────────────────────────────
#page(header: none, footer: none)[
  #v(1fr)
  #set text(size: 8.5pt, fill: luma(130))
  #set par(leading: 0.7em)

  #text(weight: "bold", size: 9pt, fill: luma(80))[#book-full-title]

  #v(16pt)
  Copyright #sym.copyright #book-date #book-author. All rights reserved.

  #v(4pt)
  이 책의 코드 예제는 교육 목적으로 자유롭게 사용할 수 있습니다.\
  본문의 무단 복제 및 배포는 금지됩니다.

  #v(20pt)
  #text(fill: luma(160))[초판 발행: #book-date]
]

// ─── Preface ──────────────────────────────────────────────────
#pagebreak()
#v(24pt)

#line(length: 40pt, stroke: 1.5pt + color-primary)
#v(6pt)
#text(size: 26pt, weight: "bold", fill: color-secondary, font: font-body)[서문]
#v(24pt)

#set text(size: 10pt, fill: luma(50))
#set par(leading: 0.85em)

AI 에이전트는 단순한 챗봇을 넘어, 도구를 사용하고, 계획을 세우며, 복잡한 작업을 자율적으로 수행하는 지능형 시스템입니다. 이 책은 세 가지 주요 프레임워크 --- *LangChain*, *LangGraph*, *Deep Agents* --- 를 활용하여 실전 AI 에이전트를 구축하는 방법을 체계적으로 안내합니다.

#v(16pt)

// 이 책의 특징
#block(
  width: 100%,
  fill: rgb("#FAFAFA"),
  stroke: (left: 3pt + color-primary),
  inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
  radius: (top-right: 3pt, bottom-right: 3pt),
  breakable: false,
)[
  #text(weight: "bold", fill: color-secondary, size: 11pt)[이 책의 특징]
  #v(8pt)
  #set text(size: 9.5pt)
  - *실습 중심* --- 59개의 Jupyter 노트북 기반 예제와 실행 결과를 포함합니다
  - *단계적 학습* --- 기초부터 프로덕션 배포까지 점진적으로 난이도가 올라갑니다
  - *프레임워크 비교* --- 각 프레임워크의 강점과 적합한 사용 사례를 비교합니다
  - *실전 응용* --- RAG, SQL, 데이터 분석, ML, 딥 리서치 에이전트를 구현합니다
]

#v(14pt)

// 대상 독자
#block(
  width: 100%,
  fill: rgb("#FAFAFA"),
  stroke: (left: 3pt + luma(200)),
  inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
  radius: (top-right: 3pt, bottom-right: 3pt),
  breakable: false,
)[
  #text(weight: "bold", fill: color-secondary, size: 11pt)[대상 독자]
  #v(8pt)
  #set text(size: 9.5pt)
  - Python 기본 문법을 아는 개발자
  - LLM 기반 애플리케이션을 구축하려는 엔지니어
  - AI 에이전트 아키텍처를 체계적으로 배우고 싶은 분
]

#v(24pt)

#text(weight: "bold", fill: color-secondary, size: 11pt)[이 책의 구성]
#v(10pt)

#table(
  columns: (auto, 1fr, auto),
  align: (center, left, center),
  fill: (_, row) => if row == 0 { color-secondary } else if calc.odd(row) { rgb("#FAFAFA") } else { white },
  stroke: 0.5pt + luma(230),
  inset: 8pt,
  text(weight: "bold", fill: white, size: 9pt)[파트],
  text(weight: "bold", fill: white, size: 9pt)[주제],
  text(weight: "bold", fill: white, size: 9pt)[챕터],
  text(fill: color-primary-dark, weight: "bold")[I], [에이전트 입문 --- 환경 설정부터 세 프레임워크 기초까지], [8],
  text(fill: color-primary-dark, weight: "bold")[II], [LangChain --- 모델, 도구, 메모리, 미들웨어, 멀티 에이전트], [13],
  text(fill: color-primary-dark, weight: "bold")[III], [LangGraph --- 상태 그래프, 워크플로, 영속성, 서브그래프], [13],
  text(fill: color-primary-dark, weight: "bold")[IV], [Deep Agents --- 백엔드, 서브에이전트, 메모리, 하네스], [10],
  text(fill: color-primary-dark, weight: "bold")[V], [고급 패턴 --- 멀티 에이전트, RAG, SQL, 프로덕션], [10],
  text(fill: color-primary-dark, weight: "bold")[VI], [실전 응용 --- 5개 실전 에이전트 프로젝트], [5],
)

#v(8pt)
#set text(size: 9.5pt, fill: luma(100))
각 챕터는 학습 목표 #sym.arrow.r 이론 설명 #sym.arrow.r 코드 실습 #sym.arrow.r 요약 구조로 구성되어 있습니다.

// ─── How to Use This Book ─────────────────────────────────────
#pagebreak()
#v(50pt)
#line(length: 40pt, stroke: 1.5pt + color-primary)
#v(8pt)
#text(size: 26pt, weight: "bold", fill: color-secondary, font: font-body)[이 책의 사용법]
#v(24pt)

#text(weight: "bold", fill: color-secondary, size: 11pt)[코드 블록 읽기]
#v(8pt)
#set text(size: 10pt)

이 책의 코드 블록은 두 가지로 구분됩니다:

#v(4pt)

#code-block(```python
# Python 코드 블록 — 민트 좌측 보더
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
result = model.invoke("Hello, Agent!")
```)

#output-block(```
실행 결과 블록 — 코랄 좌측 보더
Hello! I'm an AI agent ready to help.
```)

#v(12pt)

#text(weight: "bold", fill: color-secondary, size: 11pt)[박스 유형]
#v(8pt)

#tip-box[유용한 팁이나 추가 정보를 제공합니다.]
#note-box[중요한 참고 사항이나 배경 지식을 설명합니다.]
#warning-box[주의가 필요한 사항이나 일반적인 실수를 경고합니다.]

#v(16pt)

#text(weight: "bold", fill: color-secondary, size: 11pt)[실습 환경]
#v(8pt)
#set text(size: 9.5pt)

모든 코드는 Python 3.11+ 환경에서 테스트되었습니다. 필요한 패키지 설치와 API 키 설정은 Part I의 첫 번째 챕터에서 다룹니다.

// ─── Table of Contents ────────────────────────────────────────
#pagebreak()
#v(24pt)

#line(length: 40pt, stroke: 1.5pt + color-primary)
#v(6pt)
#text(size: 26pt, weight: "bold", fill: color-secondary, font: font-body)[목차]
#v(24pt)

#show outline.entry.where(level: 1): it => {
  let body-text = if it.element.body.has("text") { it.element.body.text } else { "" }
  if body-text.starts-with("Part ") {
    // Part entry: large, bold, extra top spacing
    v(14pt)
    block(above: 0pt, below: 2pt)[
      #text(weight: "bold", size: 10.5pt, fill: color-primary-dark)[#it]
    ]
  } else {
    // Chapter entry: gap above to separate from previous sections
    v(5pt)
    block(above: 0pt, below: 0pt)[
      #pad(left: 10pt)[
        #text(weight: "bold", size: 9.5pt, fill: luma(30))[#it]
      ]
    ]
  }
}
#show outline.entry.where(level: 2): it => {
  block(above: 1.5pt, below: 1.5pt)[
    #pad(left: 24pt)[
      #text(size: 8.5pt, fill: luma(80))[#it]
    ]
  ]
}

#outline(
  title: none,
  indent: 1em,
  depth: 1,
)
