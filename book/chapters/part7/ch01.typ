// Auto-generated from 01_rag_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "RAG 에이전트", subtitle: "벡터 검색 기반 질의응답")

Part 5에서 학습한 이론과 패턴을 실전에 적용하는 Part 6의 첫 번째 프로젝트입니다. RAG(Retrieval-Augmented Generation)는 LLM의 지식 한계를 외부 문서 검색으로 보완하는 가장 실용적인 에이전트 패턴입니다. 이 장에서는 `InMemoryVectorStore`로 벡터 검색 파이프라인을 구축하고, `content_and_artifact` 반환 형식의 도구를 `create_deep_agent`에 연결하여 완전한 RAG 에이전트를 구현합니다. v1 미들웨어와 Skills 시스템을 활용한 점진적 공개(Progressive Disclosure) 패턴까지 적용합니다.

#learning-header()
#learning-objectives([InMemoryVectorStore로 벡터 검색 파이프라인을 구축한다], [`content_and_artifact` 반환 형식으로 검색 도구를 정의한다], [`create_deep_agent`로 RAG 에이전트를 생성하고 질의한다], [v1 미들웨어(ModelCallLimitMiddleware, ToolRetryMiddleware)를 적용한다], [_Skills 시스템_으로 RAG 도메인 지식을 점진적 공개(Progressive Disclosure)한다])

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
  [LangChain + Deep Agents],
  [_핵심 컴포넌트_],
  [InMemoryVectorStore, OpenAIEmbeddings, RecursiveCharacterTextSplitter],
  [_에이전트 패턴_],
  [`content_and_artifact` 도구 → `create_deep_agent`],
  [_백엔드_],
  [`FilesystemBackend(root_dir=".", virtual_mode=True)`],
  [_스킬_],
  [`skills/rag-agent/SKILL.md` — RAG 도메인 지식 점진적 공개],
)

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

`````)

RAG 파이프라인은 크게 세 단계로 나뉩니다: _인덱싱_(문서를 벡터로 변환하여 저장), _검색_(쿼리와 유사한 문서 탐색), _생성_(검색된 문서를 기반으로 답변 생성). 1~3단계에서 인덱싱을, 4~5단계에서 검색을, 6~7단계에서 에이전트 통합과 생성을 다룹니다.

== 1단계: 샘플 문서 생성

RAG 파이프라인의 첫 단계는 검색 대상 문서를 준비하는 것입니다. 실제 환경에서는 PDF, 웹 페이지, 데이터베이스 등에서 문서를 로드하지만, 여기서는 학습 목적으로 직접 `Document` 객체를 생성합니다. 각 문서에는 `page_content`(실제 텍스트)와 `metadata`(출처 등 부가 정보)가 포함됩니다. `metadata`는 검색 결과에 출처를 표시하거나, 특정 소스의 문서만 필터링하는 데 활용됩니다.

#tip-box[프로덕션 RAG에서는 `PyPDFLoader`, `WebBaseLoader`, `NotionDBLoader` 등 50개 이상의 LangChain 문서 로더를 활용할 수 있습니다. 문서 로더는 `Document` 객체 리스트를 반환하므로, 이후의 분할/임베딩/검색 단계는 데이터 소스에 관계없이 동일하게 동작합니다.]


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

문서가 준비되었으면, 임베딩 모델의 입력 크기에 맞게 텍스트를 분할해야 합니다. 분할 전략은 검색 품질에 직접적인 영향을 미칩니다.

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

청크가 준비되면 임베딩 모델을 통해 각 청크를 고차원 벡터로 변환하고, 벡터 스토어에 인덱싱합니다. 이후 쿼리 시 쿼리 벡터와 가장 유사한 문서 벡터를 찾아 반환합니다.

== 3단계: 벡터 스토어 구축

OpenAI 임베딩 모델로 텍스트를 벡터로 변환하고, `InMemoryVectorStore`에 저장합니다. 프로덕션에서는 FAISS나 Chroma 같은 영구 저장소를 사용합니다.


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

벡터 스토어가 구축되었으니, 에이전트가 검색을 수행할 수 있도록 도구 인터페이스를 정의합니다. 이 단계가 인덱싱(오프라인)에서 검색(온라인)으로 넘어가는 전환점입니다.

== 4단계: 검색 도구 정의 (content_and_artifact)

`response_format="content_and_artifact"` 패턴은 도구가 두 가지를 반환하게 합니다:

#warning-box[`content_and_artifact` 패턴을 사용하지 않고 전체 `Document` 객체를 반환하면, 에이전트의 컨텍스트 윈도우에 메타데이터까지 모두 포함됩니다. 문서 수가 많을 경우 토큰 낭비가 심각해질 수 있으므로, 에이전트에게 보여줄 텍스트와 프로그래밍 용도의 원본 객체를 분리하는 이 패턴을 권장합니다.]
- _content_: 에이전트에게 보여줄 텍스트 요약
- _artifact_: 전체 Document 객체 (후속 처리용)

이 패턴은 에이전트의 컨텍스트를 절약하면서도 원본 데이터에 접근할 수 있게 합니다.


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

에이전트에 통합하기 전에 도구가 올바르게 동작하는지 단독으로 검증합니다. 이는 Part 5 ch09에서 학습한 단위 테스트 원칙의 실천입니다.


#code-block(`````python
result = retrieve.invoke({"query": "에이전트란 무엇인가?"})
print(result)

`````)
#output-block(`````
에이전트는 LLM이 도구를 사용하여 자율적으로 작업을 수행하는 시스템입니다. ReAct 패턴이 대표적입니다.

Deep Agents는 올인원 에이전트 SDK입니다. create_deep_agent로 에이전트를 생성하고, 백엔드와 서브에이전트를 지원합니다.

벡터 스토어는 임베딩을 저장하고 유사도 검색을 수행하는 데이터베이스입니다. FAISS, Chroma 등이 있습니다.
`````)

검색 도구가 단독으로 정상 동작하는 것을 확인했으니, 이제 에이전트에 통합합니다. `create_deep_agent`는 도구, 백엔드, 미들웨어, Skills 시스템을 한 번에 조립하는 팩토리 함수입니다.

== 6단계: RAG 에이전트 생성 (v1 미들웨어 적용)

벡터 스토어와 검색 도구가 준비되었으니, 이제 `create_deep_agent`로 완전한 RAG 에이전트를 생성합니다. v1 미들웨어로 무한 루프 방지와 도구 재시도를 적용하고, Skills 시스템으로 RAG 도메인 지식을 점진적으로 공개(Progressive Disclosure)합니다. 프롬프트는 LangSmith Hub → Langfuse → 기본값 순으로 시도합니다.

#tip-box[Skills 기반 Progressive Disclosure는 Part 5 ch04에서 학습한 패턴입니다. 에이전트가 모든 도메인 지식을 한 번에 로드하지 않고, 필요한 시점에 `load_skill` 도구로 관련 지식만 가져옵니다. 이를 통해 토큰 비용을 절감하면서도 정확한 답변을 생성할 수 있습니다.]

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

에이전트가 생성되었습니다. 단순 질의(하나의 검색)와 비교 질의(다중 검색)를 통해 에이전트의 RAG 동작을 확인합니다. 단순 질의에서 에이전트는 `retrieve` 도구를 한 번 호출하여 관련 문서를 가져오고 답변을 생성합니다. 비교 질의("LangChain과 LangGraph의 차이는?")에서는 에이전트가 각 주제에 대해 별도의 검색을 수행하여 정보를 종합합니다. 이 차이가 RAG _Agent_의 핵심 장점입니다 -- 에이전트가 질문의 복잡도에 따라 검색 전략을 자율적으로 조정합니다.

#tip-box[비교 질의에서 에이전트가 검색을 한 번만 수행하고 부정확한 비교를 하는 경우, 시스템 프롬프트에 "비교 질문에는 각 주제별로 별도 검색을 수행하세요"라는 지시를 추가하면 효과적입니다. 또한 `ModelCallLimitMiddleware`의 `run_limit`이 너무 낮으면 다중 검색 전에 실행이 중단될 수 있으므로 적절히 설정하세요.] 단순 질의에서는 에이전트가 검색 도구를 한 번 호출하여 답변하고, 비교 질의에서는 여러 번 검색하여 정보를 종합합니다.


#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_벡터 스토어_],
  [`InMemoryVectorStore.from_documents()` — 임베딩 기반 유사도 검색],
  [_검색 도구_],
  [`\@tool(response_format="content_and_artifact")` — 요약 + 원본 분리],
  [_에이전트_],
  [`create_deep_agent(model, tools=[retrieve], backend=..., skills=["/skills/"])`],
  [_스킬_],
  [`skills/rag-agent/SKILL.md` — Progressive Disclosure로 토큰 절약],
)


#references-box[
- `docs/langchain/24-retrieval.md`
- #link("https://python.langchain.com/docs/tutorials/rag/")[LangChain RAG Tutorial]
- `docs/deepagents/10-skills.md`
_다음 단계:_ → #link("./02_sql_agent.ipynb")[02_sql_agent.ipynb]: SQL 에이전트를 구축합니다.
]
#chapter-end()
