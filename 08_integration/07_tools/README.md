# 07. Tools — 에이전트가 호출할 외부 도구

`create_agent(..., tools=[...])` 에 직접 주입되는 도구들. 여기서는 LangChain이 공식 제공하는 패키지형 도구를 다룬다.

## 커버리지 체크리스트

| # | 주제 | 주요 도구 | 패키지 | 상태 |
|---|------|----------|--------|------|
| 01 | Search (웹) | Tavily · DuckDuckGo · SerpAPI · Google Serper · Brave · Exa · You.com | `langchain-tavily`, `langchain-community` 등 | ⬜ |
| 02 | Code execution | `PythonREPLTool` · E2B Data Analysis · Riza Code Interpreter | `langchain-experimental`, `langchain-e2b`, `langchain-riza` | ⬜ |
| 03 | SQL / Database | `SQLDatabaseToolkit` · `create_sql_agent` · Spark SQL | `langchain-community` | ⬜ |
| 04 | Browser automation | Playwright toolkit (`click`, `navigate`, `extract_text` …) | `langchain-community[playwright]` | ⬜ |
| 05 | Productivity | Slack · Gmail · GitHub · Jira · Office365 toolkits | `langchain-community` | ⬜ |
| 06 | Knowledge / reference | Wikipedia · Arxiv · PubMed · Google Scholar | `langchain-community` | ⬜ |

## 학습 포인트

- **Toolkit 패턴**: 공식 toolkit(`SlackToolkit().get_tools()`)이 여러 도구를 묶어 반환
- **인증 흐름**: OAuth 콜백이 있는 도구(Slack/Gmail/GitHub)는 토큰 발급 단계 별도
- **HITL 결합**: 민감 도구는 `HumanInTheLoopMiddleware`로 승인 흐름 (02_langchain/07_hitl_and_runtime 참고)
- **Rate limit / 비용**: 검색 API별 무료 티어 차이 (Tavily 1000/m, SerpAPI 250/m)
- **에러 전파**: `ToolRetryMiddleware`를 앞에 두면 transient 실패 자동 재시도
