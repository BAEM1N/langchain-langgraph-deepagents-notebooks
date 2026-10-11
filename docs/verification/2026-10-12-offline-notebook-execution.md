# 전체 노트북 오프라인 실행 검증

v1.3.1 배포 전 한국어 core 86개, 영어 mirror 86개, integration 69개를 각각 새 커널에서 실행했다. 원본 노트북 출력은 바꾸지 않고 `.local/offline_all_20261012/verified/`에 실행 사본과 상세 로그를 저장했다.

| 결과 | 수량 |
|---|---:|
| 대상 노트북 | 241 |
| 모든 코드 셀 실행 완료 | 46 |
| 명시적 제외 후 로컬 실행 완료 | 195 |
| 실행 오류 / 실행기 오류 | 0 / 0 |
| 전체 코드 셀 | 1984 |
| 최종 실행에서 성공한 코드 셀 | 892 |
| 외부·의존·환경 조건으로 제외한 셀 | 1090 |
| 빈 코드 셀 | 2 |
| 비밀값 패턴 검사 적중 | 0 |
| 현재 소스와 실행 소스 해시 불일치 | 0 |

외부 모델·임베딩·클라우드 API와 그 결과에 의존하는 셀은 제외했다. 일부 선택 통합 패키지, 브라우저 바이너리, 로컬 Ollama 모델, 데이터베이스 서비스, 대화형·서버 실행 조건도 제외 사유에 포함된다. 제외 셀을 실행 성공으로 세거나 원격 응답을 모사하지 않았다. 외부 서비스의 실제 동작은 이번 검증 범위에 포함되지 않는다.

제외 집계: `{"environment": 81, "external_api": 307, "external_dependency": 702}`.

키를 전달하지 않는 환경과 별도 HOME·작업 폴더를 사용했다. dotenv 읽기를 비활성화하고 macOS sandbox-exec와 Python 연결 차단을 함께 적용했다. 실제 비밀 파일의 읽기도 차단했다. 교육용 가짜 키는 명시적인 생성식으로 바꿨고, 비밀값 검사 또는 소스 변경이 발견되면 실행기가 실패하도록 했다.

환경: Python 3.14.3, 저장소 uv.lock SDK 고정 버전. 기존 노트북에 명시된 로컬 보조 패키지는 잠금 파일 제약 아래 테스트 환경에만 추가했고 프로젝트 의존성은 확장하지 않았다.

검증 과정에서 캐싱 미들웨어 import, `create_agent(system_prompt=...)`, `SubAgentMiddleware` backend/모델 설정, 실행 메타데이터 `node_attempt`, tracing 비활성 시 run ID 처리, LiteLLM import, Jupyter async loader 호출을 수정했다. 대응 Typst와 데크 소스에도 적용했다.

추가 검사: 26개 테스트, 전체 241개 정적·API 검사, Ruff, Pyright, uv.lock 일관성 통과. 한국어 577쪽·영어 616쪽 교재를 재빌드했고, 데크 02/03/05를 재빌드해 전체 1,206장과 발표자 노트 구성을 확인했다. 수정된 교재·데크 페이지의 시각 검사도 통과했다.

- [노트북별 CSV](2026-10-12-offline-notebook-execution.csv)
- [소스 해시·셀별 제외 사유 JSON](2026-10-12-offline-notebook-execution.json)
- 재실행: `.venv/bin/python scripts/execute_notebooks_offline.py --run-root .local/offline_check --jobs 6 --timeout 120 --max-iterations 64`

전체 실행 후 원래 JSON 파일 형식을 보존한 노트북과 대응 영문 예제 6개를 추가 실행했다. 보고서에는 소스 해시가 현재 파일과 일치하는 최신 실행 결과를 사용했다. 초기 전체 실행과 추가 실행의 개별 증거도 로컬에 보존했다.
