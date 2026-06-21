# Event streaming — Official Reference Note

> 공식 원문: https://docs.langchain.com/oss/python/deepagents/event-streaming
> 로컬 원문 스냅샷: `local/official_langchain_docs_2026-06-19/pages/oss__python__deepagents__event-streaming.md`
> 수집일: 2026-06-19
> 문서 성격: Deep Agents 레퍼런스 보강 노트

## 왜 추가했나

이 페이지는 2026-06-19 공식 LangChain 문서 스냅샷에는 있지만, 이 저장소의 공개 `docs/` 트리에는 독립 레퍼런스로 남아 있지 않았던 항목이다. 원문 전체를 복제하기보다, 강의 제작자가 빠르게 위치와 반영 방식을 판단할 수 있도록 출처와 핵심 탐색 포인트를 정리한다.

## 공식 문서에서 확인할 핵심 항목

- Stream subagents
- Subagent stream fields
- Track subagent lifecycle
- Stream messages
- Stream tool calls
- Stream nested work
- Consume concurrently
- Subagents versus subgraphs
- Related

## 강의 자료 반영 메모

일반 streaming과 event streaming을 구분해 노트북에서 용어를 혼동하지 않도록 한다.

## 연결할 로컬 자료

- 상위 문서 지도: [`../README.md`](../README.md)
- 공식 원문 전체가 필요하면 위의 공식 URL 또는 `local/official_langchain_docs_2026-06-19/pages/` 스냅샷을 확인한다.
- 실행 가능한 예제로 승격할 때는 관련 노트북의 셀 ID 순서, `gpt-5.4` 기본 모델 정책, LangSmith/외부 서비스 키 게이트를 함께 점검한다.
