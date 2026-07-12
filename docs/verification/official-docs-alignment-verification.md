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

## 실제 노트북 실행 상태

- Python 3.12 전용 커널과 `gpt-5.4` 실행 복사본으로 `01`~`06` 한·영 150개 노트북을 대상으로 설정했다.
- 저장소 `.env`의 `OPENAI_API_KEY`로 최소 SDK 인증 요청을 보냈으나 HTTP 401 `AuthenticationError`가 반환됐다.
- 첫 LLM 호출 노트북 `01_beginner/01_llm_basics.ipynb`도 같은 401에서 중단됐다.
- 따라서 API 키가 필요한 셀의 실제 실행은 완료로 판정하지 않는다. 유효한 OpenAI 키를 설정한 뒤 전수 실행을 재개해야 한다.

## 환경 경고 판정

- Python 3.14 경고는 `langchain-core`가 하위 호환을 위해 `pydantic.v1`을 import할 때 발생했다. 프로젝트 기본 버전을 `.python-version`의 3.12로 고정했고, Python 3.12에서 10개 테스트가 해당 Pydantic 경고 없이 통과했다.
- `langchain-community 0.4.2` 경고는 FAISS와 SQLDatabase import 시 패키지 자체가 출력하는 sunset 안내다. 실행 실패는 아니지만 해당 구성요소의 별도 패키지 또는 직접 구현 전환을 추적해야 한다.

## 산출물

- 한국어 핸드북: `book/agent-handbook.pdf` (628쪽)
- 영어 핸드북: `en/book/agent-handbook-en.pdf` (614쪽)
- 로컬 검사: `scripts/check_official_docs_alignment.py`
- 셀 감사: `scripts/audit_notebook_cells.py`
- CI: `.github/workflows/official-docs-alignment.yml`

두 PDF는 표지, HITL, LangGraph 인터럽트, 마지막 페이지를 PNG로 렌더링해 잘림·빈 페이지·코드 블록 붕괴가 없는지 확인했다.

## 남은 리스크

652개 장문 코드 셀은 기존 스타일 부채다. 이번 검증에서 구문·import·링크 오류는 없지만, OpenAI 인증 실패로 외부 서비스에 연결되는 셀의 실호출 성공은 아직 보증하지 않는다.
