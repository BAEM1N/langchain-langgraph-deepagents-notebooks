# 공식 문서 정합성 검증 결과

## 적용 범위

- 주 검증: 한국어·영어 `01_beginner/`~`06_langsmith/`
- 제한 검증: `07_examples/`의 최신 API·버전·공식 링크
- 제외: `08_integration/`

## 셀 감사 결과

| 항목 | 결과 |
|---|---:|
| 노트북 | 150 |
| 전체 셀 | 2,973 |
| 코드 셀 | 1,356 |
| 오류 | 0 |
| 10줄 초과 스타일 경고 | 652 |

각 셀에서 노트북 JSON, 순차 셀 ID, Python 구문, 설치 모듈과 import symbol, 로컬 Markdown 링크, Markdown code fence를 검사했다. 외부 API 키·네트워크·비용·부작용이 필요한 셀은 실제 호출하지 않았다.

## 실행 검증

- LangGraph interrupt 입력 검증: 한·영 예제 모두 invalid 응답 뒤 재중단, valid 응답 뒤 완료
- LangChain HITL: 부작용 도구는 `approve/edit/reject`, 질문형 도구는 `respond`
- Deep Agents custom backend: `ls`, `read`, `grep` 결과 계약 실행 성공
- Deep Agents 버전: 안정 `0.6.12`에는 `BackendProtocol.delete` 없음, 격리 설치한 `0.7.0a6`에는 존재
- 에이전트 생성: `create_agent()`가 배포 가능한 `CompiledStateGraph` 반환

## 산출물

- 한국어 핸드북: `book/agent-handbook.pdf` (628쪽)
- 영어 핸드북: `en/book/agent-handbook-en.pdf` (614쪽)
- 로컬 검사: `scripts/check_official_docs_alignment.py`
- 셀 감사: `scripts/audit_notebook_cells.py`
- CI: `.github/workflows/official-docs-alignment.yml`

두 PDF는 표지, HITL, LangGraph 인터럽트, 마지막 페이지를 PNG로 렌더링해 잘림·빈 페이지·코드 블록 붕괴가 없는지 확인했다.

## 남은 리스크

652개 장문 코드 셀은 기존 스타일 부채다. 이번 검증에서 구문·import·링크 오류는 없지만, 외부 서비스에 연결되는 모든 셀의 실호출 성공까지 보증하지는 않는다.
