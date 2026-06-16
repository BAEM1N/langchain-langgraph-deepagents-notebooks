// Auto-generated from 09_custom_workflow_and_rag.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "커스텀 워크플로와 RAG")

== 학습 목표
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

`StateGraph`는 이 세 가지를 조합하여 복잡한 워크플로를 구성할 수 있게 합니다.

== 9.3 조건부 엣지

상태에 따라 다른 경로로 분기합니다. `add_conditional_edges`를 쓰면 런타임에 동적으로 다음 노드를 선택할 수 있습니다.

아래 예제에서는 입력 텍스트를 분류한 후, 카테고리에 따라 서로 다른 핸들러로 라우팅합니다.

== 9.4 에이전트를 워크플로에 통합

`create_agent`로 만든 에이전트를 `StateGraph`의 노드로 사용합니다. 이렇게 하면 여러 에이전트를 파이프라인으로 연결하여 복잡한 작업을 처리할 수 있습니다.

아래 예제에서는 리서치 에이전트와 작성 에이전트를 순차적으로 연결합니다.

#note-box[_참고 — 3노드 RAG 파이프라인 패턴_ `docs/langchain/23-custom-workflow.md`에서는 RAG 시나리오에서 자주 쓰이는 _Rewrite → Retrieve → Agent_ 3노드 구성을 소개합니다. 1. _Rewrite_: 사용자의 모호한 질문을 검색 친화적인 쿼리로 재작성 (LLM 노드) 2. _Retrieve_: 벡터 스토어에서 관련 문서를 가져오기 (결정론적 함수 노드) 3. _Agent_: 검색 컨텍스트와 도구로 최종 응답 생성 (`create_agent` 노드)]
\>
#tip-box[본 셀의 `research → writer` 예제는 동일한 패턴(LLM 노드 두 개를 직렬 연결)을 따르며, 단지 검색 노드가 에이전트의 도구로 흡수된 형태입니다.]

== 9.5 RAG (Retrieval-Augmented Generation) 개요

RAG는 외부 지식을 검색하여 LLM의 응답을 보강하는 패턴입니다. 크게 3가지 접근 방식이 있습니다:

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

=== RAG 5가지 빌딩 블록

LangChain은 RAG를 구성하는 다섯 가지 컴포넌트를 표준화된 인터페이스로 제공합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[\#],
  text(weight: "bold")[빌딩 블록],
  text(weight: "bold")[대표 클래스],
  text(weight: "bold")[역할],
  [1],
  [_Document Loaders_],
  [`PyPDFLoader`, `WebBaseLoader`, `DirectoryLoader`],
  [파일·웹·DB 등 다양한 소스를 표준 `Document` 객체로 적재],
  [2],
  [_Text Splitters_],
  [`RecursiveCharacterTextSplitter`, `MarkdownHeaderTextSplitter`],
  [긴 문서를 임베딩 가능한 청크로 분할 (chunk_size, overlap)],
  [3],
  [_Embedding Models_],
  [`OpenAIEmbeddings`, `HuggingFaceEmbeddings`],
  [텍스트를 의미 기반 벡터로 변환],
  [4],
  [_Vector Stores_],
  [`FAISS`, `Chroma`, `Pinecone`, `Milvus`],
  [임베딩을 저장하고 유사도 검색 수행],
  [5],
  [_Retrievers_],
  [`vectorstore.as_retriever()`, `MultiQueryRetriever`, `ContextualCompressionRetriever`],
  [검색 인터페이스 추상화. 재순위·필터·하이브리드 지원],
)

이 노트북에서는 2·3·4번을 직접 사용하고, 에이전트가 도구를 통해 Retriever 역할을 수행합니다. 각 블록의 상세 사용법은 `08_integration/04_document_loaders` ~ `05_retrievers` 디렉터리에서 다룹니다.

== 9.6 간단한 RAG 구현

텍스트를 청크로 분할하고, 간단한 키워드 기반 검색으로 RAG를 구현합니다. 벡터 스토어 없이도 RAG의 핵심 개념을 이해할 수 있습니다.

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

임베딩 기반 유사도 검색을 쓰면 키워드 매칭보다 훨씬 정확한 검색이 가능합니다. 아래는 FAISS 벡터 스토어를 사용하는 예시입니다.

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

다음 노트북에서는 에이전트를 프로덕션 환경으로 배포하는 방법을 알아봅니다.
