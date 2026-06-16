// Auto-generated from 05_agentic_rag.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Agentic RAG", subtitle: "- LangGraph로 직접 구축")

Retrieval-Augmented Generation(RAG)을 세 가지 방법으로 구현합니다: LangChain RAG Agent, LangChain RAG Chain, 그리고 LangGraph StateGraph 기반 커스텀 RAG. 문서 관련성 평가, 쿼리 리라이트, 조건부 라우팅 등 심화 패턴을 다룹니다.

== 학습 목표
#learning-objectives([RAG 파이프라인(인덱싱 -\> 검색 -\> 생성)의 전체 구조를 이해한다], [`RecursiveCharacterTextSplitter`로 문서를 청킹한다], [`InMemoryVectorStore`로 벡터 스토어를 구축한다], [LangChain `create_agent` + `@tool`로 RAG Agent를 구현한다], [`@dynamic_prompt` 미들웨어로 RAG Chain(단일 LLM 호출)을 구현한다], [LangGraph `StateGraph`로 커스텀 RAG 에이전트를 구축한다], [`GradeDocuments` 구조화 출력으로 문서 관련성을 평가한다], [쿼리 리라이트와 조건부 라우팅을 구현한다])

== 5.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI, OpenAIEmbeddings

llm = ChatOpenAI(model="gpt-5.4")
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
print("환경 준비 완료.")
`````)
#output-block(`````
환경 준비 완료.
`````)

== 5.2 RAG 개요

RAG(Retrieval-Augmented Generation)는 외부 지식을 검색하여 LLM 응답의 정확도를 높이는 패턴입니다. LLM 의 두 가지 한계 — 유한한 컨텍스트(Finite context)와 정적 학습 지식(Static knowledge) — 을 검색으로 보완합니다.

=== 5가지 빌딩 블록

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[빌딩 블록],
  text(weight: "bold")[역할],
  [_Document loaders_],
  [Google Drive, Slack, Notion 등 외부 소스에서 표준화된 `Document` 객체로 데이터 수집],
  [_Text splitters_],
  [큰 문서를 컨텍스트 윈도우에 맞는 청크로 분할],
  [_Embedding models_],
  [텍스트를 벡터로 변환. 의미적으로 유사한 콘텐츠가 가까운 위치에 군집화],
  [_Vector stores_],
  [임베딩을 저장하고 유사도 기반으로 검색하는 전문 데이터베이스],
  [_Retrievers_],
  [비정형 쿼리에 대해 관련 문서를 반환하는 통일된 인터페이스],
)

=== 3가지 RAG 아키텍처

#table(
  columns: 6,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[아키텍처],
  text(weight: "bold")[설명],
  text(weight: "bold")[레이턴시],
  text(weight: "bold")[유연성],
  text(weight: "bold")[제어성],
  text(weight: "bold")[적합 사례],
  [_2-Step RAG_],
  [검색 후 생성. 예측 가능한 순서],
  [빠름],
  [낮음],
  [높음],
  [FAQ, 문서 봇],
  [_Agentic RAG_],
  [에이전트가 추론 중 검색 여부와 방법을 결정],
  [가변],
  [높음],
  [중간],
  [리서치 어시스턴트],
  [_Hybrid RAG_],
  [두 방식 결합 + 쿼리 강화·검색 검증·답변 품질 체크 등 반복 단계 추가],
  [가변],
  [높음],
  [높음],
  [프로덕션 어시스턴트],
)

이 노트북에서는 _Agentic RAG_(LangChain `create_agent` + retriever tool)와 _Hybrid RAG_(LangGraph `StateGraph` Rewrite → Retrieve → Agent 3-노드 패턴)를 모두 구현합니다.


== 5.3 문서 로딩 & 청킹

=== 문서 로더 (Document Loaders)
문서 로더는 다양한 소스에서 원시 콘텐츠를 읽어 `page_content`와 `metadata` 필드를 가진 `Document` 객체로 반환합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[로더],
  text(weight: "bold")[소스],
  text(weight: "bold")[패키지],
  [`PyPDFLoader`],
  [PDF 파일],
  [`pypdf`],
  [`TextLoader`],
  [텍스트 파일],
  [내장],
  [`CSVLoader`],
  [CSV 파일],
  [내장],
  [`WebBaseLoader`],
  [웹 페이지],
  [`beautifulsoup4`],
  [`DirectoryLoader`],
  [디렉토리 내 파일들],
  [내장],
)

=== 텍스트 분할 (Text Splitting)
`RecursiveCharacterTextSplitter`는 `\n\n` -\> `\n` -\> ` ` -\> `""` 순으로 재귀적으로 분할하여 의미적 연관성을 유지합니다. 가장 범용적인 분할기로 권장됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[설명],
  text(weight: "bold")[권장값],
  [`chunk_size`],
  [청크 최대 문자 수],
  [500-2000 (작으면 정밀 검색, 크면 맥락 보존)],
  [`chunk_overlap`],
  [인접 청크 공유 문자 수],
  [chunk_size의 10-20% (경계 정보 손실 방지)],
)

=== 기타 분할기

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[분할기],
  text(weight: "bold")[적합한 경우],
  [`MarkdownHeaderTextSplitter`],
  [마크다운 문서],
  [`HTMLHeaderTextSplitter`],
  [HTML 문서],
  [`TokenTextSplitter`],
  [토큰 예산 기반 분할],
  [`CodeTextSplitter`],
  [소스 코드 (언어 인식)],
)

#code-block(`````python
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

raw_docs = [
    Document(page_content="LangGraph는 LLM으로 상태 기반 멀티 액터 "
        "애플리케이션을 구축하기 위한 프레임워크입니다.",
        metadata={"source": "langgraph-docs"}),
    Document(page_content="에이전트는 도구를 사용하여 외부 시스템과 "
        "상호작용합니다. ReAct 패턴은 추론과 행동을 번갈아 수행합니다.",
        metadata={"source": "agent-guide"}),
]
print(f"문서 {len(raw_docs)}개 로드됨.")
`````)
#output-block(`````
문서 2개 로드됨.
`````)

#code-block(`````python
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000, chunk_overlap=200,
)
splits = text_splitter.split_documents(raw_docs)

for i, doc in enumerate(splits):
    print(f"청크 {i}: {doc.page_content[:60]}...")
print(f"총 청크 수: {len(splits)}")
`````)
#output-block(`````
청크 0: LangGraph는 LLM으로 상태 기반 멀티 액터 애플리케이션을 구축하기 위한 프레임워크입니다....
청크 1: 에이전트는 도구를 사용하여 외부 시스템과 상호작용합니다. ReAct 패턴은 추론과 행동을 번갈아 수행합니다....
총 청크 수: 2
`````)

== 5.4 벡터 스토어 구축

벡터 스토어는 임베딩을 인덱싱하고 유사도 검색을 수행하는 전문 데이터베이스입니다. `InMemoryVectorStore`는 개발/테스트용으로 적합합니다.

=== 주요 벡터 스토어 비교

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[벡터 스토어],
  text(weight: "bold")[유형],
  text(weight: "bold")[적합한 경우],
  [`InMemoryVectorStore`],
  [인프로세스],
  [개발, 소규모 데이터셋],
  [`Chroma`],
  [임베디드/클라이언트-서버],
  [프로토타이핑, 중규모 데이터셋],
  [`FAISS`],
  [인프로세스],
  [고성능 로컬 검색],
  [`Pinecone`],
  [매니지드 클라우드],
  [프로덕션, 확장성],
  [`PGVector`],
  [PostgreSQL 확장],
  [기존 PostgreSQL 인프라 활용],
)

=== 검색 유형

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[검색 타입],
  text(weight: "bold")[설명],
  [`"similarity"`],
  [표준 최근접 이웃 검색],
  [`"mmr"`],
  [Maximal Marginal Relevance -- 관련성과 다양성의 균형 (중복 감소)],
  [`"similarity_score_threshold"`],
  [최소 유사도 점수 이상인 문서만 반환],
)

#code-block(`````python
from langchain_core.vectorstores import InMemoryVectorStore

vector_store = InMemoryVectorStore.from_documents(
    documents=splits, embedding=embeddings,
)
test_results = vector_store.similarity_search("LangGraph", k=2)
for doc in test_results:
    print(f"  [{doc.metadata['source']}] {doc.page_content[:80]}")
print(f"벡터 스토어 준비 완료. 문서 {len(splits)}개.")
`````)
#output-block(`````
[langgraph-docs] LangGraph는 LLM으로 상태 기반 멀티 액터 애플리케이션을 구축하기 위한 프레임워크입니다.
  [agent-guide] 에이전트는 도구를 사용하여 외부 시스템과 상호작용합니다. ReAct 패턴은 추론과 행동을 번갈아 수행합니다.
벡터 스토어 준비 완료. 문서 2개.
`````)

== 5.5 검색 도구 정의

`response_format="content_and_artifact"`를 사용하면 도구 출력을 두 부분으로 분리합니다:
- _Content_: 모델에 전달되는 문자열 표현 (추론에 사용)
- _Artifact_: 원본 Document 객체 (프로그래밍 방식으로 접근 가능하지만 모델에 전송되지 않음)

이 분리를 통해 모델에는 읽기 쉬운 텍스트를, 후속 처리에는 메타데이터가 포함된 원본 객체를 사용할 수 있습니다.

#code-block(`````python
from langchain_core.tools import tool

@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """지식 베이스에서 관련 문서를 검색합니다."""
    docs = vector_store.similarity_search(query, k=4)
    serialized = "\n\n".join(
        f"출처: {d.metadata.get('source', '?')}\n{d.page_content}"
        for d in docs
    )
    return serialized, docs
`````)

== 5.6 LangChain RAG Agent — `create_agent` + `\@tool` (Agentic RAG)

가장 단순한 Agentic RAG 구현입니다. retriever 를 `@tool` 로 노출하고, 에이전트가 _언제 검색할지 / 어떤 쿼리로 검색할지_ 를 자율적으로 결정합니다.

- `create_agent` 가 도구 호출 루프를 관리
- 검색 호출 자체가 도구이므로, 다른 도구(웹 검색, 계산기 등)와 자연스럽게 조합 가능
- 검색이 필요 없는 질문은 LLM 이 곧바로 답변 — 2-Step RAG 와의 가장 큰 차이


== 5.7 LangChain RAG Chain -- `\@dynamic_prompt` 미들웨어

단일 LLM 호출로 RAG를 구현합니다. `@dynamic_prompt`가 LLM 호출 전에 문서를 검색하고 시스템 프롬프트에 자동으로 주입합니다. 미들웨어 방식이므로 에이전트 루프 없이 _단일 패스_로 동작합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[RAG Agent],
  text(weight: "bold")[RAG Chain],
  [LLM 호출 수],
  [다중 (에이전트 결정)],
  [단일],
  [검색 횟수],
  [1회 이상 (에이전트 제어)],
  [정확히 1회 (미들웨어 제어)],
  [쿼리 재구성],
  [자동],
  [미지원],
  [지연],
  [높음 (여러 왕복)],
  [낮음 (단일 패스)],
  [비용],
  [높음 (더 많은 토큰)],
  [낮음 (더 적은 토큰)],
  [투명성],
  [에이전트 추론이 메시지에 노출],
  [컨텍스트 주입이 암묵적],
)

_고급 활용_: `@dynamic_prompt`로 기본 컨텍스트를 주입하면서 retriever 도구를 함께 제공하여 두 접근법을 결합할 수도 있습니다.

#code-block(`````python
from langchain.agents.middleware import dynamic_prompt

@dynamic_prompt
def rag_prompt(request):
    """문서를 검색하여 시스템 프롬프트에 주입합니다."""
    user_msg = request.state["messages"][-1].content
    docs = vector_store.similarity_search(user_msg, k=4)
    ctx = "\n\n".join(d.page_content for d in docs)
    return f"컨텍스트를 기반으로 답변하세요:\n\n{ctx}"
`````)

== 5.8 LangGraph 커스텀 RAG — StateGraph 구축

`docs/langchain/23-custom-workflow.md` 의 _Rewrite → Retrieve → Agent_ 3-노드 패턴을 일반화하여, 검색 품질 검증과 질문 리라이트를 추가한 Hybrid RAG 를 구현합니다.

=== 노드 구성

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[노드 유형],
  text(weight: "bold")[노드 이름],
  text(weight: "bold")[역할],
  [_Model node (Rewrite)_],
  [`rewrite_question`],
  [검색에 더 적합한 형태로 질문을 재작성 (구조화 출력 사용 가능)],
  [_Deterministic node (Retrieve)_],
  [`retrieve` (`ToolNode`)],
  [벡터 유사도 검색을 수행],
  [_Agent node (Generate)_],
  [`generate_query_or_respond` / `generate_answer`],
  [검색 결과를 추론하고 필요 시 추가 도구 호출],
)

이 패턴은 노드 단위로 검증/재시도/분기를 쉽게 추가할 수 있어 Hybrid RAG 구현에 적합합니다.


#code-block(`````python
from langgraph.graph import MessagesState

class AgentState(MessagesState):
    """커스텀 RAG 에이전트 상태."""
    relevance: str  # "relevant" or "not_relevant"

print(f"AgentState 키: {list(AgentState.__annotations__)}")
`````)
#output-block(`````
AgentState 키: ['messages', 'relevance']
`````)

== 5.9 `generate_query_or_respond` 노드

진입 노드입니다. LLM이 retrieve 도구를 호출할지, 직접 응답할지 결정합니다.

== 5.10 `grade_documents` 노드 -- 구조화 출력으로 관련성 평가

`GradeDocuments` 스키마로 LLM이 문서 관련성을 평가합니다. `with_structured_output`으로 구조화된 응답을 받습니다.

#code-block(`````python
from pydantic import BaseModel, Field
from typing import Literal

class GradeDocuments(BaseModel):
    """검색된 문서의 이진 관련성 점수."""
    relevance: Literal["relevant", "not_relevant"] = Field(
        description="문서가 관련이 있는지 여부."
    )
    reasoning: str = Field(description="간략한 설명.")

grader = llm.with_structured_output(GradeDocuments)
`````)

#code-block(`````python
def grade_documents(state: AgentState):
    """
    검색된 문서의 관련성을 평가합니다.
    """

    msgs = state["messages"]

    user_q = next(
        (m.content for m in msgs if m.type == "human"),
        ""
    )

    tool_content = msgs[-1].content

    grade = grader.invoke(
        f"질문: {user_q}\n문서:\n{tool_content}\n"
        f"이 문서들이 관련이 있습니까?"
    )

    return {
        "relevance": grade.relevance,
        "messages": msgs
    }
`````)

== 5.11 `rewrite_question` 노드

검색된 문서가 관련 없을 때, 원래 질문을 더 구체적으로 리라이트하여 검색 품질을 높입니다.

== 5.12 `generate_answer` 노드

관련 문서가 확인되면, 검색 결과와 원본 질문을 결합하여 최종 답변을 생성합니다.

== 5.13 그래프 조립 & 실행

모든 노드를 `StateGraph`에 등록하고, 조건부 엣지(`tools_condition`, `relevance_router`)로 연결합니다.

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from langgraph.prebuilt import ToolNode, tools_condition

def relevance_router(state: AgentState):
    if state.get("relevance") == "relevant":
        return "generate_answer"
    return "rewrite_question"

graph = StateGraph(AgentState)
graph.add_node("gen_query", generate_query_or_respond)
`````)
#output-block(`````
<langgraph.graph.state.StateGraph at 0x29f10457080>
`````)

#code-block(`````python
graph.add_node("retrieve", ToolNode([retrieve]))
graph.add_node("grade_documents", grade_documents)
graph.add_node("rewrite_question", rewrite_question)
graph.add_node("generate_answer", generate_answer)

graph.add_edge(START, "gen_query")
graph.add_conditional_edges(
    "gen_query", tools_condition,
    {"tools": "retrieve", "__end__": END},
)
`````)
#output-block(`````
<langgraph.graph.state.StateGraph at 0x29f10457080>
`````)

#code-block(`````python
graph.add_edge("retrieve", "grade_documents")
graph.add_conditional_edges(
    "grade_documents", relevance_router,
    {"generate_answer": "generate_answer",
     "rewrite_question": "rewrite_question"},
)
graph.add_edge("rewrite_question", "gen_query")
graph.add_edge("generate_answer", END)

app = graph.compile()
print("그래프 컴파일 성공.")
`````)
#output-block(`````
그래프 컴파일 성공.
`````)

#chapter-summary-header()

=== 세 가지 RAG 접근법 비교

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[RAG Agent],
  text(weight: "bold")[RAG Chain],
  text(weight: "bold")[LangGraph 커스텀],
  [LLM 호출 수],
  [다중],
  [단일],
  [다중],
  [검색 횟수],
  [에이전트 결정],
  [정확히 1회],
  [커스텀],
  [쿼리 재구성],
  [자동],
  [미지원],
  [명시적 노드],
  [관련성 평가],
  [암묵적],
  [없음],
  [`GradeDocuments`],
  [제어 수준],
  [낮음],
  [낮음],
  [높음],
  [구현 복잡도],
  [낮음],
  [최저],
  [높음],
)

=== 핵심 LangGraph 패턴

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[구현],
  [조건부 라우팅],
  [`add_conditional_edges` + `tools_condition`],
  [구조화 출력],
  [`llm.with_structured_output(GradeDocuments)`],
  [도구 노드],
  [`ToolNode([retrieve])`],
  [루프 제어],
  [`rewrite_question` -\\\> `gen_query` 순환],
)
