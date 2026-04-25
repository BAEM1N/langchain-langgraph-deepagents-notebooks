---
name: rag-agent
description: >
  RAG(Retrieval-Augmented Generation) 에이전트 구축 가이드.
  벡터 스토어 검색, 문서 청킹, content_and_artifact 패턴을 다룹니다.
license: MIT
compatibility: Python 3.12+
metadata:
  category: rag
  difficulty: intermediate
allowed-tools: retrieve
---

# RAG Agent 스킬

## 사용 시기
- 사용자가 문서 기반 질의응답 시스템을 구축할 때
- 벡터 스토어에서 관련 문서를 검색하고 답변을 생성할 때
- RAG 파이프라인의 검색 품질을 개선할 때

## 워크플로
1. **문서 준비**: 원본 문서를 RecursiveCharacterTextSplitter로 청킹
2. **임베딩 & 저장**: OpenAIEmbeddings → InMemoryVectorStore (또는 FAISS, Chroma)
3. **검색 도구 정의**: `@tool(response_format="content_and_artifact")` 패턴 사용
4. **에이전트 생성**: `create_deep_agent(tools=[retrieve])` — 검색 도구 전달
5. **질의 & 검증**: 단순 질의 → 비교 질의 → 출처 확인

## 핵심 패턴

### content_and_artifact 반환
```python
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """벡터 스토어에서 관련 문서를 검색합니다."""
    results = vectorstore.similarity_search(query, k=3)
    content = "\n\n".join(d.page_content for d in results)
    return content, results  # (요약 텍스트, 원본 객체)
```

### 청킹 전략
| 파라미터 | 권장값 | 이유 |
|---------|--------|------|
| `chunk_size` | 1000 | 충분한 컨텍스트 유지 |
| `chunk_overlap` | 200 | 문맥 연결 보장 |
| `separators` | `["\n\n", "\n", " "]` | 자연스러운 경계 |

## 안전 규칙
- 검색된 문서에 없는 내용은 추측하지 않는다
- 출처(문서 제목, 페이지)를 반드시 명시한다
- 검색 결과가 부족하면 사용자에게 알린다
