// Auto-generated from 01_rag_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "RAG 에이전트", subtitle: "벡터 검색 기반 질의응답")

== 학습 목표
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
