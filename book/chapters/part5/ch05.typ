// Auto-generated from 05_agentic_rag.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Agentic RAG", subtitle: "- LangGraph로 직접 구축")

이전 장에서 학습한 컨텍스트 엔지니어링의 가장 대표적인 실전 응용이 RAG입니다. Retrieval-Augmented Generation(RAG)을 세 가지 방법으로 구현합니다: LangChain RAG Agent, LangChain RAG Chain, 그리고 LangGraph StateGraph 기반 커스텀 RAG. 문서 관련성 평가, 쿼리 리라이트, 조건부 라우팅 등 심화 패턴을 다룹니다.

#learning-header()
#learning-objectives([RAG 파이프라인(인덱싱 -\> 검색 -\> 생성)의 전체 구조를 이해한다], [`RecursiveCharacterTextSplitter`로 문서를 청킹한다], [`InMemoryVectorStore`로 벡터 스토어를 구축한다], [LangChain `create_agent` + `@tool`로 RAG Agent를 구현한다], [`@dynamic_prompt` 미들웨어로 RAG Chain(단일 LLM 호출)을 구현한다], [LangGraph `StateGraph`로 커스텀 RAG 에이전트를 구축한다], [`GradeDocuments` 구조화 출력으로 문서 관련성을 평가한다], [쿼리 리라이트와 조건부 라우팅을 구현한다])

== 5.1 환경 설정

RAG 파이프라인을 구축하기 위해 LLM과 임베딩 모델을 초기화합니다. `ChatOpenAI`는 텍스트 생성을, `OpenAIEmbeddings`는 문서를 벡터로 변환하는 역할을 담당합니다. 두 모델은 RAG의 서로 다른 단계에서 사용되므로 모두 필요합니다.

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI, OpenAIEmbeddings

llm = ChatOpenAI(model="gpt-4.1")
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
print("환경 준비 완료.")
`````)
#output-block(`````
환경 준비 완료.
`````)

== 5.2 RAG 개요

RAG(Retrieval-Augmented Generation)는 외부 지식을 검색하여 LLM 응답의 정확도를 높이는 패턴입니다. LLM은 두 가지 핵심 제약을 가집니다:
- _유한한 컨텍스트_: 전체 코퍼스를 한 번에 처리할 수 없음
- _정적 지식_: 학습 데이터가 시간이 지나면 구식이 됨

RAG는 쿼리 시점에 관련 외부 정보를 가져와 이 제약을 극복합니다.

#align(center)[#image("../../assets/diagrams/png/rag_pipeline_overview.png", width: 92%, height: 82mm, fit: "contain")]

RAG를 처음 볼 때는 _오프라인 인덱싱_ 과 _온라인 질의 처리_ 를 분리해서 보는 것이 가장 중요합니다. 문서를 청킹하고 임베딩하는 단계는 미리 준비해 두는 백오피스 작업이고, 사용자가 질문했을 때는 이미 준비된 벡터 스토어에서 관련 문서를 찾은 뒤 그 결과만 LLM에 넣어 답을 생성합니다.

=== 파이프라인: 인덱싱 -\> 검색 -\> 생성

#align(center)[#image("../../assets/diagrams/png/rag_end_to_end.png", width: 92%, height: 82mm, fit: "contain")]

파이프라인을 두 개의 시간 축으로 나눠 보면 이해가 쉬워집니다. _인덱싱 단계_ 는 미리 준비하는 오프라인 작업이고, _질의 단계_ 는 사용자의 질문이 들어올 때마다 반복되는 온라인 작업입니다. 이 구분을 기억하면 청킹/임베딩 최적화와 검색/생성 최적화를 분리해서 설계할 수 있습니다.

=== 5가지 핵심 구성 요소

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구성 요소],
  text(weight: "bold")[역할],
  [_Document Loaders_],
  [외부 소스(Google Drive, Notion 등)에서 데이터를 표준 Document 객체로 수집],
  [_Text Splitters_],
  [대규모 문서를 컨텍스트 윈도우에 맞는 청크로 분할],
  [_Embedding Models_],
  [텍스트를 의미적으로 유사한 내용이 가까이 모이는 벡터로 변환],
  [_Vector Stores_],
  [임베딩을 저장하고 유사도 검색을 수행하는 전문 데이터베이스],
  [_Retrievers_],
  [비정형 쿼리를 기반으로 관련 문서를 반환],
)

=== 세 가지 RAG 아키텍처

#align(center)[#image("../../assets/diagrams/png/rag_architecture_choices.png", width: 54%, height: 128mm, fit: "contain")]

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[접근법],
  text(weight: "bold")[아키텍처],
  text(weight: "bold")[LLM 호출],
  text(weight: "bold")[유연성],
  text(weight: "bold")[적합한 경우],
  [_2-Step RAG_],
  [검색 후 즉시 생성],
  [단일],
  [낮음],
  [FAQ, 문서 봇 (빠르고 예측 가능)],
  [_Agentic RAG_],
  [에이전트가 검색 시점/방법 결정],
  [다중],
  [높음],
  [복잡한 리서치, 다중 도구 접근],
  [_Hybrid RAG_],
  [쿼리 강화 + 검색 검증 + 답변 품질 체크],
  [다중],
  [높음],
  [반복적 정제가 필요한 경우],
)

=== Agent vs Chain 접근 (LangChain 구현)

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[접근법],
  text(weight: "bold")[아키텍처],
  text(weight: "bold")[LLM 호출],
  text(weight: "bold")[적합한 경우],
  [_RAG Agent_],
  [에이전트 + retriever 도구],
  [다중],
  [복잡한 쿼리, 쿼리 재구성 필요],
  [_RAG Chain_],
  [미들웨어 주입 컨텍스트],
  [단일],
  [단순 Q&A, 예측 가능한 비용],
  [_LangGraph 커스텀_],
  [StateGraph + 커스텀 노드],
  [다중],
  [관련성 평가, 리라이트 등 세밀한 제어],
)

#note-box[_선택 기준 요약_
- _Agent_ 는 검색 횟수나 도구 사용을 스스로 결정해야 할 때 적합합니다.
- _Chain_ 은 비용과 지연 시간을 예측 가능하게 유지해야 할 때 가장 단순합니다.
- _Graph_ 는 관련성 평가, 재작성, 재시도 규칙을 명시적으로 통제해야 할 때 선택합니다.]

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
`RecursiveCharacterTextSplitter`는 `\n\n` -\> `\n` -\> ` ` -\> `""` 순으로 재귀적으로 분할하여 의미적 연관성을 유지합니다. 가장 범용적인 분할기로 권장됩니다. 분할 순서가 중요한 이유는, 가능한 한 단락 단위로 분할하여 _의미가 끊기지 않는 청크_를 만들기 위해서입니다. 단락 경계(`\n\n`)에서 분할할 수 없을 만큼 긴 텍스트만 문장 경계(`\n`)로 넘어가고, 그래도 안 되면 공백 경계로 내려갑니다.

#tip-box[`chunk_size`와 `chunk_overlap`의 최적값은 데이터와 사용 사례에 따라 달라집니다. 일반적으로 FAQ 봇에는 작은 청크(500자)가 정밀한 검색에 유리하고, 보고서 생성에는 큰 청크(1500~2000자)가 맥락 보존에 효과적입니다. 시작 시 chunk_size=1000, chunk_overlap=200을 권장하며, 검색 품질 평가를 통해 조정하세요.]

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

문서가 청크로 분할되었으니, 다음 단계는 이 청크들을 벡터로 변환하여 검색 가능한 형태로 저장하는 것입니다. 이 과정이 _인덱싱_이며, RAG 파이프라인의 오프라인 준비 단계에 해당합니다.

== 5.4 벡터 스토어 구축

벡터 스토어는 임베딩을 인덱싱하고 유사도 검색을 수행하는 전문 데이터베이스입니다. `InMemoryVectorStore`는 개발/테스트용으로 적합합니다. 벡터 스토어의 핵심 원리는 _의미적 유사도 검색_입니다. 전통적인 키워드 검색이 정확한 단어 매칭에 의존하는 반면, 벡터 검색은 임베딩 공간에서의 거리(코사인 유사도, 유클리드 거리 등)를 기준으로 의미적으로 가까운 문서를 찾습니다. 예를 들어 "LLM 애플리케이션 구축"이라는 쿼리는 "AI 시스템 개발"이라는 문서와도 높은 유사도를 보일 수 있습니다.

#warning-box[`InMemoryVectorStore`는 프로세스 종료 시 모든 데이터가 소멸합니다. 프로덕션에서는 반드시 영속적 벡터 스토어(Chroma, FAISS, Pinecone 등)를 사용하세요. 또한 대규모 데이터셋(수만 건 이상)에서는 인프로세스 벡터 스토어의 메모리 사용량이 급격히 증가하므로, 클라이언트-서버 아키텍처의 벡터 스토어를 고려해야 합니다.]

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

벡터 스토어가 구축되었으니, 에이전트가 이를 활용하여 문서를 검색할 수 있도록 _도구(tool)_ 형태로 래핑해야 합니다. 에이전트는 도구를 통해서만 외부 시스템과 상호작용하므로, 벡터 스토어를 도구로 정의하는 것이 RAG 통합의 핵심입니다.

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

== 5.6 LangChain RAG Agent -- `create_agent` + `\@tool`

가장 간단한 방법: retriever를 도구로 등록하고 에이전트가 필요할 때 호출합니다.

=== 다중 단계 검색 흐름
RAG Agent는 자동으로 다중 검색 단계를 실행할 수 있습니다:
+ _초기 검색_ -- 사용자 질문 기반 쿼리 생성
+ _결과 평가_ -- 검색된 문서가 질문에 충분한지 판단
+ _재구성 및 재검색_ -- 결과가 부족하면 쿼리를 수정하여 재검색
+ _통합_ -- 모든 검색 결과를 결합하여 최종 답변 생성

이 접근법은 복잡한 리서치 질문에 적합하지만, 여러 번의 LLM 호출로 비용과 지연이 증가합니다.

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

_고급 활용_: `@dynamic_prompt`로 기본 컨텍스트를 주입하면서 동시에 retriever 도구를 제공하여 두 접근법을 결합할 수도 있습니다.

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

RAG Agent와 RAG Chain은 각각 유연성과 단순성에서 장점이 있습니다. 그러나 검색 결과의 품질을 자동으로 평가하고, 부적합한 경우 쿼리를 리라이트하여 재검색하는 _적응형 RAG_를 구현하려면 LangGraph `StateGraph`가 필요합니다. 이것이 Agentic RAG의 핵심입니다: retrieve → grade → generate → hallucination check의 순환 루프를 통해 답변 품질을 보장합니다.

== 5.8 LangGraph 커스텀 RAG -- StateGraph 구축

LangGraph `StateGraph`로 세밀한 제어가 가능한 RAG 에이전트를 직접 구축합니다. 이 방식의 핵심 장점은 _조건부 라우팅_을 통해 검색 결과의 관련성을 평가하고, 관련 없는 경우 쿼리를 리라이트하여 재검색하는 등의 세밀한 흐름 제어가 가능하다는 것입니다.

=== 아키텍처

#align(center)[#image("../../assets/diagrams/png/rag_architecture_choices.png", width: 54%, height: 128mm, fit: "contain")]

이 장의 LangGraph 구현은 위 세 번째 패턴에 해당합니다. 즉, 검색 자체보다도 _검색 이후의 판단_ — 관련성 평가, 재작성, 종료 조건 — 을 그래프로 명시하는 데 의미가 있습니다.

#code-block(`````python
        [generate_query_or_respond]
             /              \
       (tool call)       (no tool call)
           |                  |
      [retrieve]           [END]
           |
   [grade_documents]
      /          \
(relevant)    (not relevant)
    |              |
[generate]   [rewrite_question]
    |              |
  [END]    [generate_query_or_respond]
`````)

=== 각 노드의 역할

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[노드],
  text(weight: "bold")[역할],
  [`generate_query_or_respond`],
  [진입 노드. 검색할지 직접 응답할지 결정],
  [`retrieve`],
  [`ToolNode`로 검색 실행],
  [`grade_documents`],
  [구조화 출력(`GradeDocuments`)으로 문서 관련성 평가],
  [`rewrite_question`],
  [관련 없는 결과 시 더 구체적인 쿼리로 리라이트],
  [`generate_answer`],
  [관련 문서 기반 최종 답변 생성],
)

#warning-box[`rewrite_question` → `generate_query_or_respond` 순환이 발생할 수 있습니다. `retry_count`를 State에 추가하여 최대 재시도 횟수를 제한하는 것이 권장됩니다. 기본적으로 2~3회 재시도 후 가용한 정보로 답변하는 전략이 효과적입니다.]

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

Agentic RAG에서 가장 핵심적인 노드입니다. 검색된 문서가 사용자 질문과 실제로 관련이 있는지를 LLM이 평가합니다. 이 평가가 없으면 에이전트는 관련 없는 문서를 기반으로 환각(hallucination)을 생성할 위험이 있습니다. `GradeDocuments` 스키마로 LLM이 문서 관련성을 평가하며, `with_structured_output`으로 구조화된 응답을 받아 프로그래밍적으로 후속 처리를 결정합니다.

#tip-box[`GradeDocuments`에 `reasoning` 필드를 포함하면 LLM이 평가 이유를 명시하게 됩니다. 이는 디버깅에 유용할 뿐 아니라, Chain-of-Thought 효과로 평가 정확도 자체도 향상시킵니다. 프로덕션에서는 이 이유를 로깅하여 검색 품질 분석에 활용할 수 있습니다.]

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

문서 관련성 평가에서 "not_relevant"이 반환되면, 단순히 실패로 처리하지 않고 _쿼리를 개선하여 재검색_하는 전략을 취합니다. 이것이 Agentic RAG가 단순 RAG와 차별화되는 핵심 메커니즘입니다.

== 5.11 `rewrite_question` 노드

검색된 문서가 관련 없을 때, 원래 질문을 더 구체적으로 리라이트하여 검색 품질을 향상시킵니다. 리라이트 전략은 다양합니다: 모호한 용어를 구체화하거나, 질문의 범위를 좁히거나, 동의어를 사용하여 다른 각도에서 검색할 수 있습니다. LLM이 원래 질문의 의도를 파악하여 벡터 검색에 더 적합한 형태로 변환합니다.

== 5.12 `generate_answer` 노드

관련 문서가 확인되면, 검색 결과와 원본 질문을 결합하여 최종 답변을 생성합니다.

개별 노드가 모두 정의되었으니, 이제 이들을 하나의 그래프로 조립하는 마지막 단계입니다. LangGraph의 핵심 강점은 이러한 노드들을 _선언적으로_ 연결하여 복잡한 흐름을 명확하게 표현할 수 있다는 것입니다.

== 5.13 그래프 조립 & 실행

모든 노드를 `StateGraph`에 등록하고, 조건부 엣지(`tools_condition`, `relevance_router`)로 연결합니다. 그래프 조립 과정은 세 단계로 이루어집니다: (1) 노드 등록 -- 각 함수를 이름과 함께 그래프에 추가, (2) 엣지 연결 -- 노드 간의 고정 경로 설정, (3) 조건부 엣지 -- 상태에 따른 동적 라우팅 설정. `compile()` 호출 후에는 그래프가 실행 가능한 상태가 됩니다.

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

Agentic RAG는 비정형 문서에서 정보를 검색하는 패턴입니다. 그러나 기업 데이터의 상당 부분은 정형 데이터베이스에 저장되어 있습니다. 다음 장에서는 자연어를 SQL로 변환하여 데이터베이스에 질의하는 SQL 에이전트를 구축합니다.


