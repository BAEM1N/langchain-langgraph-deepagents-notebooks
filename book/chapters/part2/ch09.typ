// Auto-generated from 09_custom_workflow_and_rag.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "커스텀 워크플로와 RAG")

지금까지 `create_agent()`가 내부적으로 처리해주던 워크플로를 직접 구성해야 할 때가 있습니다 — 조건부 분기, 에이전트를 노드로 포함하는 복합 파이프라인, 검색 증강 생성(RAG) 등. 이 장에서는 LangGraph의 `StateGraph`를 사용하여 LangChain 에이전트를 워크플로 노드로 통합하고, 실전에서 가장 많이 사용되는 RAG 패턴을 구현합니다.

8장의 멀티 에이전트 패턴 중 _Custom_ 패턴이 바로 이 `StateGraph`를 직접 다루는 방식입니다. `create_agent()`는 내부적으로 "모델 호출 → 도구 실행 → 반복" 루프를 자동으로 구성하지만, 검색 결과의 품질을 평가하여 재검색할지 결정하거나, 생성된 답변의 환각 여부를 검증하는 등의 _비선형 로직_은 개발자가 직접 그래프를 설계해야 합니다.

#learning-header()
LangGraph `StateGraph`로 커스텀 워크플로를 만들고, RAG 패턴을 구현합니다.

이 노트북에서 다루는 내용:
- `StateGraph`의 기본 구조 (노드, 엣지, 상태)
- 조건부 엣지를 활용한 분기 처리
- `create_agent`를 워크플로 노드로 통합
- RAG (Retrieval-Augmented Generation) 패턴 구현

== 9.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("환경 준비 완료.")
`````)
#output-block(`````
환경 준비 완료.
`````)

== 9.2 StateGraph 기초

LangGraph의 핵심 빌딩 블록을 살펴봅니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  [_노드(Node)_],
  [처리 단위. 함수 또는 에이전트가 될 수 있습니다],
  [_엣지(Edge)_],
  [노드 간 연결. 실행 흐름을 정의합니다],
  [_상태(State)_],
  [노드 간 공유 데이터. `TypedDict`로 정의합니다],
)

`StateGraph`는 이 세 가지를 조합하여 복잡한 워크플로를 구성할 수 있게 합니다. 상태는 `TypedDict`로 정의하며, 그래프의 모든 노드가 이 상태를 읽고 쓸 수 있습니다. 노드는 상태를 입력으로 받아 변경된 부분만 딕셔너리로 반환하는 순수 함수입니다. 엣지는 노드 간의 실행 순서를 결정하며, 정적 엣지(항상 같은 다음 노드)와 조건부 엣지(상태에 따라 동적으로 결정)로 나뉩니다.

#tip-box[`StateGraph`를 구성할 때는 `START` → 첫 번째 노드 → ... → `END` 형태로 명시적 엣지를 연결해야 합니다. 엣지를 빠뜨리면 해당 노드가 실행되지 않으므로, 그래프 시각화(`graph.get_graph().draw_mermaid()`)로 연결 상태를 확인하는 습관을 들이세요.]

== 9.3 조건부 엣지

상태에 따라 다른 경로로 분기합니다. `add_conditional_edges`를 사용하면 런타임에 동적으로 다음 노드를 선택할 수 있습니다. 조건부 엣지의 핵심은 _라우팅 함수_입니다. 이 함수는 현재 상태를 받아 다음에 실행할 노드의 이름(문자열)을 반환합니다.

아래 예제에서는 입력 텍스트를 분류한 후, 카테고리에 따라 서로 다른 핸들러로 라우팅합니다.

조건부 엣지를 통해 그래프 내에서 동적 분기가 가능해졌습니다. 다음으로, 이 노드 자리에 `create_agent`로 생성한 에이전트를 배치하여 에이전트 기반 워크플로를 구성해 보겠습니다.

== 9.4 에이전트를 워크플로에 통합

`create_agent`로 만든 에이전트를 `StateGraph`의 노드로 사용합니다. 에이전트를 노드로 통합하면, 에이전트 내부에서는 자유롭게 도구를 호출하면서도 에이전트 _간_의 실행 순서와 데이터 흐름은 그래프가 엄격하게 제어합니다. 이렇게 하면 여러 에이전트를 파이프라인으로 연결하여 복잡한 작업을 처리할 수 있습니다.

아래 예제에서는 리서치 에이전트와 작성 에이전트를 순차적으로 연결합니다.

#warning-box[에이전트를 `StateGraph` 노드로 사용할 때, 에이전트의 출력 상태 키가 그래프의 상태 스키마와 일치해야 합니다. 특히 `messages` 키는 LangGraph의 `add_messages` 리듀서를 사용하여 메시지가 덮어쓰기 대신 누적되도록 설정하세요.]

지금까지 `StateGraph`의 기본 구조와 에이전트 통합 방법을 살펴보았습니다. 이제 커스텀 워크플로의 가장 대표적인 실전 사례인 RAG 파이프라인을 구현해 보겠습니다.

== 9.5 RAG (Retrieval-Augmented Generation) 개요

RAG는 외부 지식을 검색하여 LLM의 응답을 보강하는 패턴입니다. LLM은 학습 데이터에 포함되지 않은 최신 정보나 조직 내부 문서에 대해 정확한 답변을 생성하기 어렵습니다. RAG는 이 문제를 "검색(Retrieve) → 생성(Generate)" 2단계로 해결합니다. 먼저 사용자의 질문과 관련된 문서를 벡터 유사도 검색으로 찾아낸 뒤, 이 문서를 LLM의 컨텍스트에 주입하여 _사실에 근거한_ 응답을 생성하도록 유도합니다. 3가지 주요 접근 방식이 있습니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[설명],
  text(weight: "bold")[특징],
  [_기본 2단계_],
  [검색 → 생성],
  [단순하고 빠름],
  [_에이전틱 RAG_],
  [에이전트가 검색 도구를 호출하여 반복],
  [유연하고 정확],
  [_하이브리드_],
  [키워드 + 시맨틱 검색 결합],
  [검색 품질 향상],
)

- _기본 2단계_: 쿼리로 문서를 검색한 후, 검색된 문서를 컨텍스트로 LLM에 전달하여 답변을 생성합니다.
- _에이전틱 RAG_: 에이전트가 검색 도구를 사용하여 필요한 정보를 반복적으로 검색하고, 충분한 정보를 모은 후 답변합니다.

=== RAG 5 빌딩 블록

LangChain 의 RAG 파이프라인은 다음 다섯 컴포넌트로 구성됩니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[컴포넌트],
  text(weight: "bold")[역할],
  [_Document Loaders_],
  [PDF, 웹페이지, Notion 등에서 원본 문서를 적재],
  [_Text Splitters_],
  [긴 문서를 의미 단위 청크로 분할 (`RecursiveCharacterTextSplitter` 등)],
  [_Embedding Models_],
  [텍스트를 벡터로 변환 (`OpenAIEmbeddings` 등)],
  [_Vector Stores_],
  [임베딩 인덱싱·검색 (FAISS, Chroma, Pinecone 등)],
  [_Retrievers_],
  [검색 인터페이스 통일 — 벡터/하이브리드/MultiQuery 등을 같은 API로],
)

=== Rewrite → Retrieve → Agent 3-노드 패턴

에이전틱 RAG 의 한 변형으로, _쿼리 재작성_을 별도 노드로 분리합니다. 사용자 입력을 검색 친화적인 형태로 다듬은 뒤 retriever 가 동작하고, 그 결과를 에이전트가 답변에 반영합니다.

#code-block(`````python
# Rewrite → Retrieve → Agent
graph.add_node("rewrite", query_rewriter_node)
graph.add_node("retrieve", retriever_node)
graph.add_node("agent", create_agent(model, tools=[]))

graph.add_edge(START, "rewrite")
graph.add_edge("rewrite", "retrieve")
graph.add_edge("retrieve", "agent")
graph.add_edge("agent", END)
`````)

아래 research → writer 예제는 _컨텐츠 생성_ 워크플로를 보여주며, Rewrite → Retrieve → Agent 는 _검색 품질_을 끌어올리는 워크플로입니다. 둘 다 `StateGraph` 의 자연스러운 활용입니다.

== 9.6 간단한 RAG 구현

텍스트를 청크로 분할하고, 간단한 키워드 기반 검색으로 RAG를 구현합니다. 벡터 스토어 없이도 RAG의 핵심 개념을 이해할 수 있습니다.

RAG 파이프라인의 첫 번째 단계는 문서를 적절한 크기의 _청크(chunk)_로 분할하는 것입니다. `RecursiveCharacterTextSplitter`는 문단, 문장, 단어 순서로 재귀적으로 분할점을 찾아 의미 단위가 최대한 보존되도록 합니다. `chunk_overlap` 파라미터는 인접 청크 간에 겹치는 문자 수를 지정하여, 분할 경계에서 문맥이 단절되는 것을 방지합니다.

#code-block(`````python
from langchain_text_splitters import RecursiveCharacterTextSplitter

# 샘플 문서
documents = [
    "LangChain is a framework for building applications with large language models. It provides tools for prompt engineering, memory management, and agent creation.",
    "LangGraph is a low-level orchestration framework for building stateful agents. It uses a graph-based approach with nodes and edges.",
    "Middleware in LangChain v1 allows you to intercept and modify agent behavior at every step. You can add logging, guardrails, and custom logic.",
    "Multi-agent systems in LangChain support five patterns: subagents, handoffs, skills, router, and custom workflows.",
    "RAG (Retrieval-Augmented Generation) combines information retrieval with text generation to provide grounded, factual responses.",
]

# 텍스트 분할
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=200,
    chunk_overlap=50,
)

chunks = []
for doc in documents:
    chunks.extend(text_splitter.split_text(doc))

print(f"원본 문서: {len(documents)}개")
print(f"분할 청크: {len(chunks)}개")
for i, chunk in enumerate(chunks):
    print(f"  [{i}] {chunk[:80]}...")
`````)
#output-block(`````
원본 문서: 5개
분할 청크: 5개
  [0] LangChain is a framework for building applications with large language models. I...
  [1] LangGraph is a low-level orchestration framework for building stateful agents. I...
  [2] Middleware in LangChain v1 allows you to intercept and modify agent behavior at ...
  [3] Multi-agent systems in LangChain support five patterns: subagents, handoffs, ski...
  [4] RAG (Retrieval-Augmented Generation) combines information retrieval with text ge...
`````)

== 9.7 FAISS 벡터 스토어 (선택)

임베딩 기반 유사도 검색을 사용하면 키워드 매칭보다 훨씬 정확한 검색이 가능합니다. 키워드 검색은 "LLM 에이전트"라는 쿼리로 "AI 기반 자동화 도우미"라는 문서를 찾지 못하지만, 임베딩 유사도 검색은 의미적으로 유사한 문서를 정확히 찾아냅니다. LangChain은 `InMemoryVectorStore`, FAISS, Chroma 등 다양한 벡터 스토어를 지원하며, 아래는 FAISS 벡터 스토어를 사용하는 예시입니다.

#tip-box[프로덕션 RAG 파이프라인에서는 검색된 문서의 관련성을 평가하는 _그레이딩(grading)_ 단계와, 생성된 답변의 환각 여부를 검증하는 _할루시네이션 체크_ 단계를 추가하는 것이 권장됩니다. 이러한 검증 로직은 `StateGraph`의 조건부 엣지로 자연스럽게 구현할 수 있습니다.]

#code-block(`````python
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS

# 임베딩 모델  생성
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

# 벡터 스토어 생성
vectorstore = FAISS.from_texts(chunks, embeddings)

# 검색
results = vectorstore.similarity_search("LangChain agent patterns", k=3)
for doc in results:
    print(doc.page_content)
`````)
#output-block(`````
Multi-agent systems in LangChain support five patterns: subagents, handoffs, skills, router, and custom workflows.
LangChain is a framework for building applications with large language models. It provides tools for prompt engineering, memory management, and agent creation.
Middleware in LangChain v1 allows you to intercept and modify agent behavior at every step. You can add logging, guardrails, and custom logic.
`````)

#chapter-summary-header()

이 노트북에서 배운 내용:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [_StateGraph 기초_],
  [노드, 엣지, 상태로 워크플로를 구성합니다],
  [_조건부 엣지_],
  [`add_conditional_edges`로 런타임에 분기 처리합니다],
  [_에이전트 통합_],
  [`create_agent`를 StateGraph 노드로 사용하여 파이프라인을 구성합니다],
  [_RAG 패턴_],
  [검색 + 생성을 결합하여 사실 기반 응답을 제공합니다],
  [_벡터 스토어_],
  [FAISS 등으로 임베딩 기반 유사도 검색이 가능합니다],
)

이 장에서 학습한 `StateGraph`와 RAG 패턴은 에이전트 개발의 핵심 빌딩 블록입니다. 다음 장에서는 이렇게 구축한 에이전트를 프로덕션 환경으로 배포하기 위한 테스트, 배포, 모니터링 전략을 다룹니다.


