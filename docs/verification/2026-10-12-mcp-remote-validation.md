# MCP 원격 HTTP 추가 실행 검증

v1.3.2 이후 사용자 요청에 따라 공개 원격 MCP 연결을 실제 실행했다. 원래 오프라인 릴리즈 검증과 구분하는 추가 기록이다. 패키지와 교육 소스는 v1.3.2 그대로 사용했다.

## 실제 원격 서버

- 대상: `https://docs.langchain.com/mcp`
- 전송: Streamable HTTP (`fastmcp.Client` → `langchain.mcp.MCPAdapter`)
- 인증: 공개 서버, 자격증명 미전달
- 발견 도구: 검색·문서 읽기·피드백 3개
- 호출 도구: 읽기용 `search_docs_by_lang_chain`, `query_docs_filesystem_docs_by_lang_chain`
- 문맥 안 검색 호출과 문맥 종료 후 동일 도구 재연결 호출 모두 `ToolMessage.status == "success"`
- 두 호출 모두 문서 결과 10개 수신. 결과 본문은 배포 보고서에 복제하지 않음
- 문서 파일 검색에서 경로 17개를 확인하고, 반환된 경로의 MCP 문서 읽기 성공
- 모델 API 호출 0회, 변경/피드백 도구 호출 0회

원격 서버가 선언한 `args_schema`의 `query` 필드에 맞춰 호출했다. 입력 스키마는 실제 MCP schema를 사용했고, 일반 BaseTool 입력 래퍼와 혼동하지 않았다. [측정 결과 JSON](2026-10-12-mcp-remote-validation.json).

## 로컬 HTTP 회귀 검사

`tests/test_mcp_http.py`는 외부 서버 없이 실제 FastMCP HTTP ASGI app와 httpx2 전송을 사용한다.

- 도구 탐색 및 어댑터 종료 후 HTTP 재연결 호출
- KO/EN 노트북의 authored bearer auth 설정이 서버 요청 헤더로 전달되는지 확인
- 잘못된 synthetic token은 HTTP 401로 거부되고 도구 함수는 실행되지 않음
- 동일 이름의 도구를 가진 두 HTTP 서버가 `ClientGroup` prefix로 독립 라우팅되는지 확인
- 구조화된 결과가 `ToolMessage.artifact.structured_content`로 보존되는지 확인

추가 5개 HTTP 테스트 및 기존 테스트를 합쳐 50개 통과. 정적·Ruff·Pyright 검사도 수행했다. 실제 개인 키를 테스트에 넣지 않았고, 키 패턴 검사 적중은 0건이다.

## 범위

공식 공개 서버의 연결·도구 탐색·읽기용 검색을 검증한 결과다. 다른 사설 MCP 서버, 실제 OAuth 로그인, 특정 계정 권한, 모델을 포함한 전체 agent 실행을 검증했다고 주장하지 않는다. 원격 측 사양이나 서비스 상태가 바뀔 수 있으므로 기본 단위 테스트에는 인터넷 의존 호출을 넣지 않았다.
