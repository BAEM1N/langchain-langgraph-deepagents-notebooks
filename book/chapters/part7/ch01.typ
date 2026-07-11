// Auto-generated from 01_rag_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "RAG 에이전트", subtitle: "5 building blocks + 3-Node 패턴")

== 학습 목표
#learning-objectives([LangChain RAG의 _5 building blocks_(document loaders / text splitters / embedding models / vector stores / retrievers)를 이해한다], [_2-Step / Agentic / Hybrid_ 세 가지 RAG 아키텍처의 차이를 안다], [`Rewrite → Retrieve → Agent` 3-node 패턴으로 질의 재작성과 검색을 분리한다], [`content_and_artifact` 반환 형식으로 검색 도구를 정의한다], [`create_deep_agent`로 RAG 에이전트를 만들고 v1 미들웨어를 적용한다], [_Skills 시스템_으로 RAG 도메인 지식을 점진적 공개(Progressive Disclosure)한다])

== 개요

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_프레임워크_],
  [LangChain v1 + Deep Agents],
  [_5 building blocks_],
  [Document loaders · Text splitters · Embedding models · Vector stores · Retrievers],
  [_아키텍처_],
  [2-Step (정적 RAG) · Agentic (도구 호출) · Hybrid (Rewrite → Retrieve → Agent)],
  [_에이전트 패턴_],
  [`content_and_artifact` 도구 → `create_deep_agent`],
  [_백엔드_],
  [`FilesystemBackend(root_dir=".", virtual_mode=True)`],
  [_스킬_],
  [`skills/rag-agent/SKILL.md` — RAG 도메인 지식 점진적 공개],
)

#note-box[참고: `docs/langchain/24-retrieval.md` — 2-Step / Agentic / Hybrid RAG 아키텍처 비교]

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"

`````)

#code-block(`````python
# Observability 설정 (선택)
import os

# LangSmith — LANGSMITH_* 가 표준. LANGCHAIN_* 는 하위 호환 shim
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    project = os.environ.get("LANGSMITH_PROJECT", "default")
    print(f"LangSmith tracing ON — project: {os.environ['LANGSMITH_PROJECT']}")

langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")

`````)

== RAG 5 building blocks

`docs/langchain/24-retrieval.md` 가 정의하는 다섯 가지 구성 요소를 노트북 흐름에 매핑하면 다음과 같습니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[\#],
  text(weight: "bold")[컴포넌트],
  text(weight: "bold")[역할],
  text(weight: "bold")[본 노트북 매핑],
  [1],
  [_Document loaders_],
  [외부 소스에서 표준화된 `Document` 객체로 데이터를 적재],
  [1단계: 6개 `Document` 직접 생성],
  [2],
  [_Text splitters_],
  [큰 문서를 검색 가능한 청크로 분할],
  [2단계: `RecursiveCharacterTextSplitter`],
  [3],
  [_Embedding models_],
  [의미적으로 가까운 텍스트가 모이도록 벡터로 변환],
  [3단계: `OpenAIEmbeddings(text-embedding-3-small)`],
  [4],
  [_Vector stores_],
  [임베딩 저장 + 유사도 검색],
  [3단계: `InMemoryVectorStore`],
  [5],
  [_Retrievers_],
  [비정형 질의로부터 관련 문서 반환],
  [4단계: `retrieve` 도구 (`similarity_search`)],
)

== 세 가지 RAG 아키텍처

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[아키텍처],
  text(weight: "bold")[검색 시점],
  text(weight: "bold")[지연 시간],
  text(weight: "bold")[유연성],
  text(weight: "bold")[적합 시나리오],
  [_2-Step RAG_],
  [항상 검색 후 생성],
  [Fast],
  [Low],
  [FAQ, 문서 봇],
  [_Agentic RAG_],
  [에이전트가 필요할 때 도구 호출],
  [Variable],
  [High],
  [리서치 어시스턴트, 다중 도구],
  [_Hybrid RAG_],
  [Rewrite → Retrieve → Agent + 검증],
  [Variable],
  [High],
  [품질 검증이 필요한 도메인],
)

본 노트북은 _Agentic RAG_(에이전트가 `retrieve` 도구를 호출)를 기본으로 하고, 마지막에 `Rewrite → Retrieve → Agent` 3-node Hybrid 패턴을 한 번 더 보입니다.

== 1단계: 샘플 문서 생성

RAG 파이프라인의 첫 단계는 검색 대상 문서를 준비하는 것입니다. 실제 환경에서는 PDF, 웹 페이지, 데이터베이스 등에서 문서를 로드하지만, 여기서는 학습 목적으로 `Document` 객체를 직접 생성합니다.


#code-block(`````python
from langchain_core.documents import Document

docs = [
    Document(page_content="LangChain은 LLM 애플리케이션 개발 프레임워크입니다. 도구, 체인, 에이전트를 지원합니다.", metadata={"source": "langchain"}),
    Document(page_content="LangGraph는 상태 기반 워크플로를 구축하는 프레임워크입니다. 그래프 API와 Functional API를 제공합니다.", metadata={"source": "langgraph"}),
    Document(page_content="Deep Agents는 올인원 에이전트 SDK입니다. create_deep_agent로 에이전트를 생성하고, 백엔드와 서브에이전트를 지원합니다.", metadata={"source": "deepagents"}),
    Document(page_content="RAG는 검색 증강 생성의 약자로, 외부 지식을 LLM에 주입하여 정확한 응답을 생성합니다.", metadata={"source": "rag"}),
    Document(page_content="벡터 스토어는 임베딩을 저장하고 유사도 검색을 수행하는 데이터베이스입니다. FAISS, Chroma 등이 있습니다.", metadata={"source": "vectorstore"}),
    Document(page_content="에이전트는 LLM이 도구를 사용하여 자율적으로 작업을 수행하는 시스템입니다. ReAct 패턴이 대표적입니다.", metadata={"source": "agent"}),
]
print(f"문서 {len(docs)}개 생성 완료")

`````)
#output-block(`````
문서 6개 생성 완료
`````)

== 2단계: 텍스트 분할

큰 문서를 검색에 적합한 크기의 청크로 분할합니다. `RecursiveCharacterTextSplitter`는 단락 → 문장 → 단어 순으로 자연스러운 경계에서 분할을 시도합니다.


#code-block(`````python
from langchain_text_splitters import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=200, chunk_overlap=50
)
splits = splitter.split_documents(docs)
print(f"분할 결과: {len(splits)}개 청크")

`````)
#output-block(`````
분할 결과: 6개 청크
`````)

== 3단계: 벡터 스토어 구축

OpenAI 임베딩 모델로 텍스트를 벡터로 변환한 뒤 `InMemoryVectorStore`에 저장합니다. 프로덕션에서는 FAISS나 Chroma 같은 영구 저장소를 씁니다.


#code-block(`````python
from langchain_openai import OpenAIEmbeddings
from langchain_core.vectorstores import InMemoryVectorStore

embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = InMemoryVectorStore.from_documents(splits, embeddings)
print(f"벡터 스토어 구축 완료 — {len(splits)}개 문서 임베딩됨")

`````)
#output-block(`````
벡터 스토어 구축 완료 — 6개 문서 임베딩됨
`````)

== 4단계: 검색 도구 정의 (content_and_artifact)

`response_format="content_and_artifact"` 패턴은 도구가 두 가지를 반환하게 합니다:
- _content_: 에이전트에게 보여줄 텍스트 요약
- _artifact_: 전체 Document 객체 (후속 처리용)

에이전트의 컨텍스트를 절약하면서 원본 데이터에도 접근할 수 있습니다.


#code-block(`````python
from langchain.tools import tool

@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """벡터 스토어에서 관련 문서를 검색합니다."""
    results = vectorstore.similarity_search(query, k=3)
    content = "\n\n".join(d.page_content for d in results)
    return content, results

`````)

== 5단계: 검색 도구 단독 테스트

에이전트에 연결하기 전에 도구가 올바르게 동작하는지 확인합니다.


#code-block(`````python
result = retrieve.invoke({"query": "에이전트란 무엇인가?"})
print(result)

`````)
#output-block(`````
에이전트는 LLM이 도구를 사용하여 자율적으로 작업을 수행하는 시스템입니다. ReAct 패턴이 대표적입니다.

Deep Agents는 올인원 에이전트 SDK입니다. create_deep_agent로 에이전트를 생성하고, 백엔드와 서브에이전트를 지원합니다.

벡터 스토어는 임베딩을 저장하고 유사도 검색을 수행하는 데이터베이스입니다. FAISS, Chroma 등이 있습니다.
`````)

== 6단계: RAG 에이전트 생성 (v1 미들웨어 적용)

에서 프롬프트를 로드합니다. LangSmith Hub → Langfuse → 기본값 순으로 시도합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[역할],
  [\\],
  [무한 루프 방지 — 최대 모델 호출 횟수 제한],
  [\\],
  [검색 도구 실패 시 자동 재시도],
)

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langchain.agents.middleware import (
    ModelCallLimitMiddleware,
    ToolRetryMiddleware,
)
from prompts import RAG_AGENT_PROMPT

agent = create_deep_agent(
    model=model,
    tools=[retrieve],
    system_prompt=RAG_AGENT_PROMPT,
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
    middleware=[
        ModelCallLimitMiddleware(run_limit=10),
        ToolRetryMiddleware(max_retries=2),
    ],
)
`````)
#output-block(`````
Prompt 'rag-agent-label:production' not found during refresh, evicting from cache.

Prompt 'sql-agent-label:production' not found during refresh, evicting from cache.

Prompt 'data-analysis-agent-label:production' not found during refresh, evicting from cache.

Prompt 'ml-agent-label:production' not found during refresh, evicting from cache.

Prompt 'deep-research-agent-label:production' not found during refresh, evicting from cache.
`````)

== 7단계: 단순 질의 및 비교 질의

단순 질의(하나의 검색)와 비교 질의(다중 검색)로 에이전트의 RAG 동작을 확인합니다.


#code-block(`````python
# 단순 질의
response = agent.invoke(
    {"messages": [{"role": "user", "content": "LangGraph가 뭔가요?"}]},
    config=lf_config,
)
print(response["messages"][-1].content)

`````)
#output-block(`````
LangGraph는 상태 기반 워크플로를 구축하기 위한 프레임워크입니다. 그래프 API와 Functional API를 통해 복잡한 LLM(대형 언어 모델) 기반 애플리케이션의 흐름을 정의하고 관리할 수 있습니다.

출처: 검색 결과(내부 문서 검색)
`````)

== 8단계: Hybrid RAG — `Rewrite → Retrieve → Agent` 3-node 패턴

Agentic RAG 는 에이전트가 한 번에 검색·답변을 다 결정하지만, 도메인 어휘가 풍부할수록 _질의 재작성(rewrite)_ 을 분리하면 재현율이 올라갑니다. LangGraph 의 `StateGraph` 로 3개 노드를 명시적으로 구성합니다.

#code-block(`````python
사용자 입력
   │
   ▼
[1] rewrite   ─ 모델이 질의를 검색용 키워드로 재작성
   │
   ▼
[2] retrieve  ─ 벡터 스토어에서 후보 문서 K개 조회
   │
   ▼
[3] agent     ─ create_deep_agent 가 근거 기반 답변 생성
`````)

`retrieve` 도구는 4단계에서 이미 정의했으므로 그대로 재사용합니다.

#code-block(`````python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END


class HybridState(TypedDict):
    question: str
    rewritten: str
    contexts: list
    answer: str


def rewrite_node(state: HybridState) -> dict:
    """질의를 벡터 검색에 친화적인 키워드 형태로 재작성합니다."""
    prompt = (
        "다음 질문을 한국어 벡터 검색용 핵심 키워드 한 줄로 다시 써주세요. "
        "불필요한 조사·어미는 제거하고 명사 중심으로 작성합니다.\n\n"
        f"질문: {state['question']}"
    )
    rewritten = model.invoke(prompt).content.strip()
    return {"rewritten": rewritten}


def retrieve_node(state: HybridState) -> dict:
    """재작성된 질의로 벡터 스토어에서 K=3 컨텍스트를 조회합니다."""
    docs = vectorstore.similarity_search(state["rewritten"], k=3)
    return {"contexts": [d.page_content for d in docs]}


def agent_node(state: HybridState) -> dict:
    """검색 결과를 컨텍스트로 주입한 뒤 에이전트가 최종 답변을 생성합니다."""
    context_block = "\n\n".join(f"- {c}" for c in state["contexts"])
    user_msg = (
        f"다음 컨텍스트만 근거로 사용해 질문에 답하세요.\n\n"
        f"[컨텍스트]\n{context_block}\n\n[질문] {state['question']}"
    )
    out = agent.invoke({"messages": [{"role": "user", "content": user_msg}]}, config=lf_config)
    return {"answer": out["messages"][-1].content}


graph = (
    StateGraph(HybridState)
    .add_node("rewrite", rewrite_node)
    .add_node("retrieve", retrieve_node)
    .add_node("agent", agent_node)
    .add_edge(START, "rewrite")
    .add_edge("rewrite", "retrieve")
    .add_edge("retrieve", "agent")
    .add_edge("agent", END)
    .compile()
)

result = graph.invoke({"question": "LangGraph 와 Deep Agents 차이는?"})
print("재작성 질의:", result["rewritten"])
print("검색 컨텍스트 수:", len(result["contexts"]))
print()
print(result["answer"])

`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_5 building blocks_],
  [loaders · splitters · embeddings · vector stores · retrievers — RAG 표준 구성],
  [_벡터 스토어_],
  [`InMemoryVectorStore.from_documents()` — 임베딩 기반 유사도 검색],
  [_검색 도구_],
  [`\@tool(response_format="content_and_artifact")` — 요약 + 원본 분리],
  [_Agentic RAG_],
  [`create_deep_agent(model, tools=[retrieve], backend=..., skills=["/skills/"])`],
  [_Hybrid RAG_],
  [`Rewrite → Retrieve → Agent` 3-node `StateGraph`],
  [_스킬_],
  [`skills/rag-agent/SKILL.md` — Progressive Disclosure 로 토큰 절약],
)


#references-box[
- `docs/langchain/24-retrieval.md` — 5 building blocks · 2-Step / Agentic / Hybrid 아키텍처
- #link("https://docs.langchain.com/oss/python/langchain/rag")[LangChain RAG Tutorial]
- `docs/deepagents/10-skills.md`
_다음 단계:_ → #link("./02_sql_agent.ipynb")[02_sql_agent.ipynb]: SQL 에이전트를 구축합니다.
]
#chapter-end()
