# Dynamic subagents — Official Reference Note

> 공식 원문: https://docs.langchain.com/oss/python/deepagents/dynamic-subagents
> 로컬 원문 스냅샷: `.local/update-check-2026-10-11/oss__python__deepagents__dynamic-subagents.md`
> 갱신 기준: 2026-10-11 조사
> 문서 성격: Deep Agents canonical reference

## 왜 추가했나

공식 문서의 `programmatic-subagents` 경로가 `dynamic-subagents`로 이동했다. 기능은 interpreter에서 `task()`를 호출해 subagent fan-out, 분류, 반복 검증 같은 workflow를 코드로 조직하는 패턴이다.

## 공식 문서에서 확인할 핵심 항목

- Interpreter 기반 subagent dispatch
- `CodeInterpreterMiddleware`
- `task({ description, subagentType, responseSchema })`
- workflow trigger 문구
- Programmatic tool calling과의 결합
- beta API와 `langchain-quickjs` 요구사항

## 로컬 대응 자료

- `docs/deepagents/programmatic-subagents.md` — 이전 slug 호환 note
- `docs/deepagents/17-interpreters.md`
- `docs/deepagents/07-subagents.md`
- `docs/skills/deep-agents-orchestration.md`

## 강의 자료 반영 메모

이동한 slug를 신규 독립 기능으로 과장하지 않는다. 기존 interpreter/task dispatch 설명을 최신 이름으로 연결하고, 실행 노트북으로 승격할 때는 `langchain-quickjs>=0.3.8`, 외부 모델 호출, beta lifecycle을 별도 gate로 둔다.

## 문서 지도

- 상위 문서 지도: [`../README.md`](../README.md)
