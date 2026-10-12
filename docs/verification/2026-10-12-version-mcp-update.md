# 전체 버전 갱신 및 MCP 계약 검증

프로젝트 v1.3.2. PyPI 안정판 메타데이터, 실제 SDK wheel, 전체 잠금 파일을 대조해 갱신했다. 현재 작성 지침과 버전 표기를 맞췄으며, 과거 릴리즈·연구 기록은 당시 사실로 보존한다.

## 의존성 갱신

직접 의존성 선언 14개를 올리고 기존 transitive FastMCP 4.1.0을 직접 선언했다. `uv lock --upgrade`로 외부 패키지 118개를 갱신했다. 모든 extra를 설치해 테스트했다.

| 항목 | 검증 버전 |
|---|---|
| LangChain / core | 1.4.4 / 1.6.9 |
| LangGraph / Deep Agents | 1.2.14 / 0.7.23 |
| LangSmith / langchain-openai | 0.14.7 / 1.7.0 |
| MCP / FastMCP / httpx2 | 2.3.0 / 4.1.0 / 2.13.1 |
| Langfuse | 4.17.0 |
| AssemblyAI / Cartesia | 1.6.1 / 4.2.0 |
| WebSocket | 15.0.1 |

WebSocket 전체 최신 안정판은 17.2지만 OpenAI realtime 및 Cartesia websocket extras가 `>=13,<16`을 요구하므로 최신 호환 버전 15.0.1을 유지한다. 버전을 올렸다는 이유만으로 이 제약을 제거하지 않았다. 상세 전체 버전은 [CSV](2026-10-12-dependency-versions.csv)에 기록했다.

## MCP 반영 확인과 수정

영문 핸드북 ch07/ch11에 남아 있던 구형 연결·서버 import·auth 설명을 수정했다. 한국어/영어 노트북, Typst, 데크 및 참고 문서에서 다음 계약을 맞췄다.

- `langchain.mcp.MCPAdapter`, `MCPConfig.mcpServers`, `await adapter.list_tools()`
- Python 서버는 `from fastmcp import FastMCP`; custom auth는 `httpx2.Auth`
- 반환된 도구가 client를 보유하므로 어댑터 문맥 종료 후 재연결 호출 가능. 세션 상태 유지가 필요하면 문맥 범위를 명시
- 현대 `InputRequiredResult` → LangGraph interrupt → `Command(resume={"responses": ...})`; accept/decline/cancel
- 구형 standalone adapter는 명시적 migration 비교로만 남김. Deep Agents Code CLI 구성과 Python 실행 API 구분

실제 KO/EN 노트북 stdio 서버를 추출해 도구 탐색·문맥 종료 후 호출·인증 설정을 검증했다. elicitation 세 동작은 로컬 SDK wire fixture로 검사했다. 외부 서버, 실제 OAuth 로그인, 모델 서비스는 호출하지 않았다.

검사 범위도 확장했다. 전체 241개 노트북에 계약 검사를 적용하고, 부분 스니펫·문자열 속 서버 코드·Typst·데크 literal source·현재 참조 문서의 구형 MCP import/auth도 검사한다. 과거 release/verification 기록은 검사에서 구분하며, 명시적 historical reference 표시는 보존한다.

## 다른 SDK 호환성

AssemblyAI versioned `RealTimeTranscriber` / TurnEvent 및 Cartesia `websocket_connect()` / context 흐름으로 음성 노트북과 교재를 수정했다. Langfuse 4.17의 callback/get_client/dataset/scoring API는 실제 wheel의 계약을 확인했다. RubricMiddleware의 실제 module import와 asyncio loader도 확인했다.

## 실행·산출물 검증

- 전체 241개: 모든 코드 셀 실행 완료 46개, 명시적 제외 후 검증 완료 195개, 오류 0건
- 실제 코드 실행 894셀, 외부·의존·환경 제외 1,088셀, 빈 코드 셀 2개
- 45개 테스트 통과; 정적 계약·Ruff·Pyright·uv.lock 일관성 통과
- 비밀값 패턴 적중 0건; 최종 소스와 실행 소스 해시 불일치 0건
- 교재 2종 및 5개 데크 재빌드. 1,206장·발표자 노트 유지, PDF/PPTX 버전 메타데이터 v1.3.2 확인

전체 실행 후 대화형 입력 오탐과 Langfuse 미설정 예외를 좁혀 관련 5개 노트북을 재실행했다. 최신 결과를 합쳤고 개별 batch 원본은 `.local/version_mcp_audit_20261012/`에 보존했다. [노트북별 해시·제외 사유 JSON](2026-10-12-version-mcp-notebook-execution.json).

환경 조건 제외에는 선택 통합 패키지·브라우저·미보유 로컬 모델·서버·대화형 실행이 포함된다. 제외한 API나 환경 조건의 실제 동작을 성공으로 주장하지 않는다. 실제 키/비밀 파일은 실행 환경에 전달하지 않았다.

## 공식 근거

- [LangChain MCP](https://docs.langchain.com/oss/python/langchain/mcp)
- [MCP Python v2 migration](https://py.sdk.modelcontextprotocol.io/migration/)
- [PyPI MCP](https://pypi.org/project/mcp/), [FastMCP](https://pypi.org/project/fastmcp/), [Langfuse](https://pypi.org/project/langfuse/), [AssemblyAI](https://pypi.org/project/assemblyai/), [Cartesia](https://pypi.org/project/cartesia/)

패키지별 PyPI JSON·release metadata 원본과 upstream 비교는 로컬 `research/`에 보존했다.
