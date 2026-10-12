# Model Context Protocol (MCP) — Official Reference Note

> 공식 원문: https://docs.langchain.com/oss/python/deepagents/mcp
> 현재 Code/CLI MCP 문서: https://docs.langchain.com/oss/deepagents/code/mcp-tools
> 로컬 원문 스냅샷: `.local/update-research-2026-10-11/` 및 `.local/update-check-2026-10-11/`
> 갱신 기준: 2026-10-11 조사
> 문서 성격: Deep Agents 레퍼런스 보강 노트

## 왜 추가했나

이 페이지는 Deep Agents 쪽 MCP 표면을 LangChain Python MCP 교재와 구분해 두기 위한 레퍼런스 노트다. 원문 전체를 복제하기보다, 강의 제작자가 Python `MCPAdapter` 예제와 Deep Agents Code/CLI 설정 예제를 혼동하지 않도록 출처와 반영 방식을 정리한다.

## 공식 문서에서 확인할 핵심 항목

- LangChain Python: `langchain.mcp.MCPAdapter`, `MCPConfig.mcpServers`, `await adapter.list_tools()`
- Deep Agents Code/CLI: MCP 서버 자동 발견, 설정 파일, stdio/HTTP 서버 등록, tool filtering
- FastMCP client auth: bearer/OAuth/custom `httpx2.Auth` 호환 객체
- Gaps to keep explicit: Python `MCPAdapter`는 tool 변환 중심이며 prompt/resource wrapper는 FastMCP client 직접 사용 영역

## 강의 자료 반영 메모

외부 도구 연결 표준이다. Python 교재의 실행 예제는 LangChain `MCPAdapter`를 기준으로 쓰고, Deep Agents Code/CLI의 MCP 설정은 별도 운영 표면으로 설명한다. 키/서버 준비가 필요한 예제는 integration track으로 분리한다.

## 연결할 로컬 자료

- 상위 문서 지도: [`../README.md`](../README.md)
- LangChain Python MCP 기준 문서: [`../langchain/16-mcp.md`](../langchain/16-mcp.md)
- Deep Agents Code MCP 설정 노트: [`code/mcp-tools.md`](code/mcp-tools.md)
- 공식 원문 전체가 필요하면 위의 공식 URL 또는 `.local/update-research-2026-10-11/` 스냅샷을 확인한다.
- 실행 가능한 예제로 승격할 때는 관련 노트북의 셀 ID 순서, `gpt-5.4` 기본 모델 정책, LangSmith/외부 서비스 키 게이트를 함께 점검한다.
