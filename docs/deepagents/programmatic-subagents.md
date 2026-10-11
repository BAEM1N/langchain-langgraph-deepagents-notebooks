# Programmatic subagents — Official Reference Note

> 공식 원문(이전): https://docs.langchain.com/oss/python/deepagents/programmatic-subagents
> 현재 공식 경로: https://docs.langchain.com/oss/python/deepagents/dynamic-subagents
> 로컬 원문 스냅샷: `.local/update-check-2026-10-11/oss__python__deepagents__dynamic-subagents.md`
> 갱신 기준: 2026-10-11 조사
> 문서 성격: Deep Agents 레퍼런스 보강 노트

## 왜 추가했나

이 페이지는 2026-06-19 공식 LangChain 문서 스냅샷에는 있지만, 이 저장소의 공개 `docs/` 트리에는 독립 레퍼런스로 남아 있지 않았던 항목이다. 원문 전체를 복제하기보다, 강의 제작자가 빠르게 위치와 반영 방식을 판단할 수 있도록 출처와 핵심 탐색 포인트를 정리한다.

## 공식 문서에서 확인할 핵심 항목

- How it works
- Guide orchestration
- Patterns
- Classify and act
- Fan-out and synthesize
- Adversarial verification
- Generate and filter
- Tournament
- Loop until done
- Disable programmatic subagents

## 강의 자료 반영 메모

현재 코스에서는 dependency gate를 먼저 확인하고, live notebook은 선택 기능으로 둔다. 현재 자료를 만들 때는 [`dynamic-subagents.md`](dynamic-subagents.md)를 우선 참조한다. `programmatic-subagents`라는 이름만으로 신규 노트북을 만들지 말고 interpreter 기반 dynamic subagents 범위와 기존 subagent 설명의 중복을 확인한다.

## 연결할 로컬 자료

- 상위 문서 지도: [`../README.md`](../README.md)
- 공식 원문 전체가 필요하면 현재 공식 URL 또는 `.local/update-check-2026-10-11/` 스냅샷을 확인한다.
- 실행 가능한 예제로 승격할 때는 관련 노트북의 셀 ID 순서, `gpt-5.4` 기본 모델 정책, LangSmith/외부 서비스 키 게이트를 함께 점검한다.
