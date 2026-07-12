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

- Python 3.12 전용 커널에서 `01`~`06` 한·영 150개 노트북을 Restart & Run All 방식으로 실제 실행했다. 원본은 수정하지 않고 gitignored 로컬 복사본만 사용했다.
- 저장소의 직접 OpenAI 키는 401이었지만, 내부 OpenAI 호환 LiteLLM 게이트웨이와 전용 키는 인증 및 채팅 호출에 성공했다. 게이트웨이에 `gpt-5.4`가 없어 실행 복사본에서만 채팅 모델을 `gpt-5.5`, 임베딩 모델을 `bge-m3`로 치환했다.
- 1차 `gpt-5.5` 실행 결과는 150개 중 129개 통과, 21개 실패다. 실패는 Tavily 플랜 사용량 초과 6개, 구조화 출력 셀의 180초 타임아웃 2개, 장시간 연속 호출 뒤 `gpt-5.5` 게이트웨이 자격 증명 쿨다운(HTTP 429) 13개로 분류됐다.
- 타임아웃 2개와 429 항목 13개는 같은 게이트웨이의 `qwen3.6-35b`로 개별 재실행해 모두 통과했다. 구조화 출력 한·영 노트북도 각각 144.7초, 52.0초에 완료되어 LangChain 코드 예외가 아니라 모델별 지연 차이로 판정했다.
- 실제 Tavily 호출이 막힌 6개는 검색 반환값만 결정적 로컬 스텁으로 바꾼 실행 복사본에서 재검증했다. 에이전트 호출, 스트리밍, 서브에이전트, 후속 셀은 실제 게이트웨이 LLM을 사용했고 한·영 6개 모두 끝까지 통과했다.
- 종합하면 150개 노트북 경로 모두에서 셀 흐름을 끝까지 검증했다. 144개는 외부 LLM 호출까지 원형대로 통과했고, 6개는 Tavily 검색 호출만 스텁으로 격리했다. 현재까지 노트북 소스의 Python 예외로 판정된 실패는 없다.
- 전체 실행 중 10개 셀은 실행 복사본에서 의도적으로 제외했다. 패키지 설치 매직 2개, 비-OpenAI 공급자 호출 6개, 로컬 서버 실행 2개다. 이 셀들은 정적 구문·import 감사는 통과했지만 외부 공급자 또는 상주 프로세스의 실제 동작까지 보증하지 않는다.
- 실행 산출물과 오류 원문은 gitignored `local/notebook_execution_01_06_gpt54/`에 보관했다. 프록시 키와 기타 비밀값은 리포트와 산출물에 기록하지 않았다.

## 환경 경고 판정

- Python 3.14 경고는 `langchain-core 1.4.9`의 Pydantic 호환 유틸이 `pydantic.v1`을 import할 때 발생했다. Pydantic v1 호환 계층이 Python 3.14 이상을 지원하지 않는다는 의미이며, 노트북 코드 오류는 아니다. 프로젝트 기본 버전을 `.python-version`의 3.12로 고정했고, Python 3.12에서 10개 테스트가 해당 경고 없이 통과했다. 기존 3.14 가상환경은 Python 3.12로 다시 만들어야 고정값이 반영된다.
- `langchain-community 0.4.2` 경고는 패키지 최상위 `__init__.py`가 import될 때마다 직접 출력하는 sunset 안내다. 이번 감사에서는 FAISS와 SQLDatabase 심볼 검증이 해당 import를 유발했다. 실행 실패는 아니지만 패키지가 더 이상 적극 유지보수되지 않으므로 해당 구성요소의 독립 통합 패키지 또는 직접 구현 전환을 추적해야 한다.

## 산출물

- 한국어 핸드북: `book/agent-handbook.pdf` (628쪽)
- 영어 핸드북: `en/book/agent-handbook-en.pdf` (614쪽)
- 로컬 검사: `scripts/check_official_docs_alignment.py`
- 셀 감사: `scripts/audit_notebook_cells.py`
- CI: `.github/workflows/official-docs-alignment.yml`

두 PDF는 표지, HITL, LangGraph 인터럽트, 마지막 페이지를 PNG로 렌더링해 잘림·빈 페이지·코드 블록 붕괴가 없는지 확인했다.

## 남은 리스크

652개 장문 코드 셀은 기존 스타일 부채다. 게이트웨이가 원본 기본 모델인 `gpt-5.4`를 제공하지 않아 실행 복사본은 `gpt-5.5`와 `qwen3.6-35b`를 사용했다. Tavily 의존 노트북 6개는 사용량 한도가 복구되기 전까지 실제 검색 성공을 보증하지 않으며, 의도적으로 제외한 10개 런타임 셀도 각 공급자 키 또는 별도 서버 환경에서 확인해야 한다. `langchain-community` 사용부는 sunset 일정에 맞춘 마이그레이션 추적이 필요하다.
