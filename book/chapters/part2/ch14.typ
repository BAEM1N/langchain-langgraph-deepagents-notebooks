// Auto-generated from 14_semantic_search.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(14, "Semantic Search", subtitle: "RAG 전에 검색만 먼저 만들기")

== 학습 목표
#learning-objectives([_Semantic Search_와 _RAG Agent_의 차이를 구분합니다.], [LangChain 문서 객체, text splitter, embedding, vector store의 최소 흐름을 연결합니다.], [LLM 호출 없이도 검색 품질을 점검하는 작은 평가 루프를 만듭니다.])

== 14.1 환경 설정

공식 Learn은 Semantic Search를 RAG 앞 단계로 분리합니다. 이 장은 생성 답변 없이 “문서를 잘 찾는가”만 확인합니다.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from langchain_core.documents import Document
from langchain_core.embeddings import DeterministicFakeEmbedding
from langchain_core.vectorstores import InMemoryVectorStore
from langchain_text_splitters import RecursiveCharacterTextSplitter
`````)

== 14.2 작은 문서 컬렉션 만들기

실제 PDF 대신 짧은 문서 세 개를 사용합니다. 검색 파이프라인 구조는 PDF, 웹 문서, Markdown에도 동일하게 적용됩니다.

#code-block(`````python
raw_docs = [
    Document(page_content="LangChain agents combine models, tools, and middleware.", metadata={"source": "langchain"}),
    Document(page_content="LangGraph persists state with checkpointers and stores.", metadata={"source": "langgraph"}),
    Document(page_content="Deep Agents include planning, files, subagents, and skills.", metadata={"source": "deepagents"}),
]
len(raw_docs)
`````)

== 14.3 청크로 나누기

Semantic Search의 기본 단위는 “문서 전체”가 아니라 검색 가능한 _chunk_입니다.

#code-block(`````python
splitter = RecursiveCharacterTextSplitter(chunk_size=60, chunk_overlap=10)
chunks = splitter.split_documents(raw_docs)

[(doc.metadata["source"], doc.page_content) for doc in chunks]
`````)

== 14.4 임베딩과 벡터스토어

실습 안정성을 위해 deterministic fake embedding을 사용합니다. 실제 서비스에서는 `OpenAIEmbeddings`, provider embedding, 또는 로컬 embedding 모델로 교체합니다.

#code-block(`````python
embedding = DeterministicFakeEmbedding(size=64)
vectorstore = InMemoryVectorStore(embedding=embedding)
vectorstore.add_documents(chunks)

retriever = vectorstore.as_retriever(search_kwargs={"k": 2})
`````)

== 14.5 검색 실행

검색 결과에는 `page_content`와 `metadata`를 함께 남깁니다. RAG에서는 이 결과가 모델 답변의 근거가 됩니다.

#code-block(`````python
query = "Which framework uses checkpointers?"
results = retriever.invoke(query)

for idx, doc in enumerate(results, 1):
    print(idx, doc.metadata["source"], "=>", doc.page_content)
`````)

== 14.6 검색 품질 미니 평가

생성형 답변을 만들기 전에 “정답 source가 top-k 안에 있는가”를 확인합니다.

#code-block(`````python
test_cases = [
    ("state checkpoint memory", "langgraph"),
    ("agent middleware tools", "langchain"),
    ("skills and subagents", "deepagents"),
]

for question, expected in test_cases:
    hits = retriever.invoke(question)
    sources = [doc.metadata["source"] for doc in hits]
    print(question, "=>", sources, "PASS", expected in sources)
`````)

== 14.7 RAG로 넘어가기 전 체크리스트

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[확인 질문],
  [chunk],
  [너무 길거나 짧지 않은가?],
  [metadata],
  [출처, 페이지, 섹션을 보존하는가?],
  [retriever],
  [top-k와 필터가 질문 유형에 맞는가?],
  [evaluation],
  [정답 source가 검색되는지 측정했는가?],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

== 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_다룬 기술_],
  [`Document`, splitter, embedding, vector store, retriever],
  [_핵심 개념_],
  [Semantic Search는 RAG의 검색 계층이며, 생성 답변 전에 독립 평가할 수 있습니다.],
  [_다음 단계_],
  [`09_custom_workflow_and_rag.ipynb`, `07_examples/01_rag_agent.ipynb`],
)

#references-box[
- `docs/langchain/knowledge-base.md`
- `docs/langchain/retrieval.md`
- `docs/langchain/rag.md`
- `docs/concepts/context.md`
]
#chapter-end()
