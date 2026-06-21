# Tool calling — Official Reference Note

> 공식 원문: https://docs.langchain.com/oss/python/langchain/frontend/tool-calling
> 로컬 원문 스냅샷: `local/official_langchain_docs_2026-06-19/pages/oss__python__langchain__frontend__tool-calling.md`
> 수집일: 2026-06-19
> 문서 성격: LangChain 레퍼런스 보강 노트

## 왜 추가했나

이 페이지는 2026-06-19 공식 LangChain 문서 스냅샷에는 있지만, 이 저장소의 공개 `docs/` 트리에는 독립 레퍼런스로 남아 있지 않았던 항목이다. 원문 전체를 복제하기보다, 강의 제작자가 빠르게 위치와 반영 방식을 판단할 수 있도록 출처와 핵심 탐색 포인트를 정리한다.

## 공식 문서에서 확인할 핵심 항목

- How tool calling works
- Setting up useStream
- The AssembledToolCall type
- Filtering tool calls per message
- Building specialized tool cards
- Weather card example
- Loading and error states
- Type-safe tool arguments
- Rendering tool calls inline with streaming text
- Handling multiple concurrent tool calls
- Best practices

## 강의 자료 반영 메모

프론트엔드/React 또는 UI SDK 성격이 강하다. 기본 노트북 smoke에는 넣지 말고 `08_integration` 또는 참고 섹션에서 다룬다.

## 연결할 로컬 자료

- 상위 문서 지도: [`../../README.md`](../../README.md)
- 공식 원문 전체가 필요하면 위의 공식 URL 또는 `local/official_langchain_docs_2026-06-19/pages/` 스냅샷을 확인한다.
- 실행 가능한 예제로 승격할 때는 관련 노트북의 셀 ID 순서, `gpt-5.4` 기본 모델 정책, LangSmith/외부 서비스 키 게이트를 함께 점검한다.
