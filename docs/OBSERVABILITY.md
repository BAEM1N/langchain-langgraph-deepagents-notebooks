# Observability (관측성)

모든 노트북은 `.env` 파일만으로 두 가지 관측성 서비스를 지원합니다.

## LangSmith

환경 변수만 설정하면 **코드 수정 없이** 자동 트레이싱이 활성화됩니다.

```bash
# .env
LANGSMITH_API_KEY=lsv2-...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=agent-notebooks
```

LangChain/LangGraph의 모든 `invoke()`, `stream()` 호출이 자동으로 LangSmith에 기록됩니다.

### SmithDB run 조회

LangSmith SDK 0.14 계열에서는 run 조회를 `client.list_runs(...)`에서 SmithDB 기반 `client.runs.query(...)`로 이전한다. 단순 이름 치환이 아니다.

- Python `client.runs.query(...)`는 async API이므로 `await` 또는 `async for`로 사용한다.
- `project_name`을 직접 받지 않는다. `client.aread_project(project_name=...)`로 UUID를 얻고 `project_ids=[...]`를 넘긴다.
- 시간 범위를 생략하면 최근 하루로 좁아질 수 있으므로 `min_start_time`과 `max_start_time`을 명시한다.
- 총 조회 수와 `page_size`를 구분하고, 필요한 경우 cursor 기반 pagination을 처리한다.
- `runs.query(...)`는 `selects`를 생략하면 기본적으로 `ID`만 채운다. 이름, 입출력, 시작/종료 시각, trace, metadata, feedback, 사용자 식별자가 필요하면 `selects=["ID", "NAME", "INPUTS", "OUTPUTS", "START_TIME", "END_TIME", "TRACE_ID", "METADATA", "FEEDBACK_STATS", "LS_USER_ID"]`처럼 SCREAMING_SNAKE_CASE 필드를 명시한다.
- Prompt Hub loader, dataset/evaluate 등 다른 LangSmith API까지 전역 치환하지 않는다. SmithDB migration 대상 API별로 확인한다.

```python
project = await client.aread_project(project_name="default")

async for run in client.runs.query(
    project_ids=[str(project.id)],
    min_start_time=start,
    max_start_time=end,
    page_size=100,
    selects=[
        "ID",
        "NAME",
        "RUN_TYPE",
        "STATUS",
        "START_TIME",
        "END_TIME",
        "INPUTS",
        "OUTPUTS",
        "TRACE_ID",
        "METADATA",
        "FEEDBACK_STATS",
        "LS_USER_ID",
    ],
):
    print(run.id, run.name, run.trace_id, run.metadata)
```

## Langfuse

Langfuse는 `CallbackHandler`를 생성하여 `config`로 전달하는 방식입니다.

```python
from langfuse.langchain import CallbackHandler

langfuse_handler = CallbackHandler()

# invoke/stream 호출 시 config에 콜백 전달
result = agent.invoke(
    {"messages": [...]},
    config={"callbacks": [langfuse_handler]},
)
```

```bash
# .env
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_HOST=https://cloud.langfuse.com
```

각 노트북 상단의 Observability 셀에서 두 서비스 모두 자동으로 초기화됩니다.
