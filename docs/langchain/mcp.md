# Model Context Protocol (MCP) — Official Canonical Reference

> 공식 원문: https://docs.langchain.com/oss/python/langchain/mcp
> 로컬 원문 스냅샷: `.local/update-check-2026-10-11/oss__python__langchain__mcp.md`
> 갱신 기준: 2026-10-11 조사
> 문서 성격: LangChain canonical reference

## 왜 추가했나

공식 OSS Python 문서의 URL slug와 이 저장소의 `docs/` 경로를 1:1로 맞추기 위해 추가했다. 이 파일은 원문 전체 복제가 아니라, 공식 문서 위치·핵심 탐색 항목·로컬 대응 자료를 연결하는 공개 레퍼런스 노트다.

## 공식 문서에서 확인할 핵심 항목

- `langchain.mcp.MCPAdapter` beta API
- `langchain[mcp]` extra와 FastMCP 기반 연결
- `list_tools()` 중심 tool discovery
- URL, `Path`, in-process server, `MCPConfig`, FastMCP client target
- connection lifecycle와 multi-server prefixing
- authentication: `Client(url, auth=token)`, `Client(url, auth="oauth")`, per-server, per-user
- custom auth classes must match the installed FastMCP `httpx2.Auth` surface
- elicitation via LangGraph interrupt for servers returning `InputRequiredResult`; legacy handshake push-only elicitation is not resumable this way
- LangChain `@wrap_tool_call` middleware로 tool wrapper 구성
- migration gaps: prompt/resource/session wrappers 없음

## 로컬 대응 자료

- `docs/langchain/16-mcp.md`

## 강의 자료 반영 메모

공식 URL slug 보존용 canonical reference note다. 기존 번호형/튜토리얼 문서가 있으면 그 문서를 주 교재로 사용하고, 이 파일은 공식 경로 매핑과 최신성 확인에 사용한다. 2026-10 기준 새 예제는 `MCPAdapter`를 사용하고, `MultiServerMCPClient`는 migration 비교 표 안에서만 현재성이 있는 이름으로 취급한다. OAuth는 기본 예제에서 `auth="oauth"`를 우선 사용하고, token storage/provider 객체는 지속 저장이나 provider별 동작이 필요할 때만 별도 설명한다.

## 유지보수 규칙

- 원문 전체가 필요하면 공식 URL 또는 `.local/update-check-2026-10-11/` 스냅샷을 확인한다.
- 실행 가능한 노트북으로 승격할 때는 셀 ID 순서, 기본 모델 정책, 외부 서비스 키 게이트, smoke test 포함 여부를 함께 결정한다.
- frontend, CLI, server, cloud/provider 의존 예제는 기본 코스보다 `08_integration/` 후보로 먼저 분류한다.

## 문서 지도

- 상위 문서 지도: [`../README.md`](../README.md)
