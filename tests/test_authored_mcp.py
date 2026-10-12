"""Behavioral checks for the MCP examples authored in the notebooks.

These tests avoid model providers and remote MCP servers. They extract the
local stdio example from the learner notebooks, then exercise it through the
installed LangChain MCPAdapter/FastMCP stack.
"""

from __future__ import annotations

import json
import os
import tempfile
import unittest
import warnings
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from typing import Any
from unittest.mock import patch

import httpx2
from fastmcp import FastMCP
from langchain.agents import create_agent
from langchain.mcp import MCPAdapter
from langchain_core.language_models.fake_chat_models import FakeMessagesListChatModel
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.runnables import RunnableConfig
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command
from mcp import types as mcp_types
from pydantic import Field

REPO_ROOT = Path(__file__).resolve().parents[1]
AUTHORED_MCP_NOTEBOOKS = (
    REPO_ROOT / "02_langchain" / "11_mcp.ipynb",
    REPO_ROOT / "en" / "02_langchain" / "11_mcp.ipynb",
)


class RecordingModel(FakeMessagesListChatModel):
    """Record bound tool names while using canned model messages."""

    bound_names: list[str] = Field(default_factory=list)

    def bind_tools(self, tools, **kwargs):
        self.bound_names = [item.name for item in tools]
        return self


def _notebook_cells(path: Path, *, cell_type: str | None = None) -> list[str]:
    notebook = json.loads(path.read_text())
    cells: list[str] = []
    for cell in notebook["cells"]:
        if cell_type is None or cell["cell_type"] == cell_type:
            cells.append("".join(cell.get("source", [])))
    return cells


def _code_cell_containing(path: Path, marker: str) -> str:
    for source in _notebook_cells(path, cell_type="code"):
        if marker in source:
            return source
    raise AssertionError(
        f"{path.relative_to(REPO_ROOT)} has no code cell containing {marker!r}"
    )


def _execute_stdio_setup_from_notebook(path: Path, tmpdir: Path) -> dict[str, Any]:
    namespace: dict[str, Any] = {}
    source = _code_cell_containing(path, 'server_code = """from fastmcp import FastMCP')
    with patch.object(tempfile, "gettempdir", return_value=str(tmpdir)):
        exec(source, namespace)  # noqa: S102 -- trusted authored cell, isolated offline fixture
    return namespace


def _execute_auth_setup_from_notebook(path: Path) -> dict[str, Any]:
    namespace: dict[str, Any] = {}
    source = _code_cell_containing(path, 'weather_token = "${WEATHER_MCP_TOKEN}"')
    with warnings.catch_warnings(), redirect_stdout(StringIO()):
        warnings.simplefilter("ignore", UserWarning)
        exec(source, namespace)  # noqa: S102 -- trusted authored cell, isolated offline fixture
    return namespace


def _text_blocks(content: Any) -> list[str]:
    return [
        block["text"]
        for block in content
        if isinstance(block, dict) and block.get("type") == "text"
    ]


class AuthoredMCPNotebookContracts(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.environment = patch.dict(
            os.environ,
            {
                "LANGSMITH_TRACING": "false",
                "OPENAI_API_KEY": "",
                "ANTHROPIC_API_KEY": "",
                "GOOGLE_API_KEY": "",
            },
            clear=False,
        )
        self.environment.start()
        self.addCleanup(self.environment.stop)

    async def test_authored_stdio_example_invokes_returned_tool_after_adapter_context_exits(
        self,
    ):
        """Returned MCP tools retain their client and can reopen after context exit."""
        for notebook_path in AUTHORED_MCP_NOTEBOOKS:
            with self.subTest(notebook=notebook_path.relative_to(REPO_ROOT)):
                with tempfile.TemporaryDirectory() as directory:
                    namespace = _execute_stdio_setup_from_notebook(
                        notebook_path, Path(directory)
                    )
                    async with MCPAdapter(namespace["stdio_config"]) as adapter:
                        tools = await adapter.list_tools()
                        add_tool = next(
                            tool for tool in tools if tool.name.endswith("add")
                        )

                    result = await add_tool.ainvoke({"a": 4, "b": 6})

                self.assertEqual(_text_blocks(result), ["10"])

    async def test_authored_stdio_config_constructs_adapter_and_discovers_tools(self):
        """The exact authored MCPConfig discovers tools through MCPAdapter."""
        for notebook_path in AUTHORED_MCP_NOTEBOOKS:
            with self.subTest(notebook=notebook_path.relative_to(REPO_ROOT)):
                with tempfile.TemporaryDirectory() as directory:
                    namespace = _execute_stdio_setup_from_notebook(
                        notebook_path, Path(directory)
                    )
                    async with MCPAdapter(namespace["stdio_config"]) as adapter:
                        tools = await adapter.list_tools()

                self.assertEqual([tool.name for tool in tools], ["add"])
                metadata = tools[0].metadata
                assert metadata is not None
                self.assertEqual(metadata["mcp"]["server"]["name"], "math")


class ModernMCPProtocolContracts(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.environment = patch.dict(os.environ, {"LANGSMITH_TRACING": "false"})
        self.environment.start()
        self.addCleanup(self.environment.stop)

    async def _run_form_resume(
        self, action: str, content: dict[str, str] | None = None
    ) -> str:
        server = FastMCP(f"course-form-{action}")

        @server.tool
        def ask_name() -> str:
            return "replaced by the InputRequiredResult handler"

        async def interactive_call(context, params):
            if not params.input_responses:
                request = mcp_types.ElicitRequest(
                    method="elicitation/create",
                    params=mcp_types.ElicitRequestFormParams(
                        message="Your name?",
                        requested_schema={
                            "type": "object",
                            "properties": {"name": {"type": "string"}},
                            "required": ["name"],
                        },
                    ),
                )
                return mcp_types.InputRequiredResult(
                    input_requests={"name_form": request},
                    request_state="asked",
                )

            answer = params.input_responses["name_form"]
            if answer.action == "accept":
                text = f"accepted:{answer.content['name']}"
            else:
                text = answer.action
            return mcp_types.CallToolResult(
                content=[mcp_types.TextContent(type="text", text=text)],
                structured_content={"result": text},
            )

        server._mcp_server.add_request_handler(
            "tools/call", mcp_types.CallToolRequestParams, interactive_call
        )
        model = RecordingModel(
            responses=[
                AIMessage(
                    content="",
                    tool_calls=[
                        {
                            "name": "ask_name",
                            "args": {},
                            "id": f"ask-{action}",
                            "type": "tool_call",
                        }
                    ],
                ),
                AIMessage(content="done"),
            ]
        )
        async with MCPAdapter(server) as adapter:
            agent = create_agent(
                model, await adapter.list_tools(), checkpointer=InMemorySaver()
            )
            config: RunnableConfig = {
                "configurable": {"thread_id": f"offline-mcp-{action}"}
            }
            paused = await agent.ainvoke(
                {"messages": [HumanMessage(content="ask my name")]}, config
            )
            request = paused["__interrupt__"][0].value["requests"][0]
            response: dict[str, Any] = {"action": action}
            if content is not None:
                response["content"] = content
            resumed = await agent.ainvoke(
                Command(resume={"responses": {request["key"]: response}}), config
            )

        tool_reply = next(
            message for message in resumed["messages"] if message.type == "tool"
        )
        return _text_blocks(tool_reply.content)[0]

    async def test_form_resume_accept_returns_structured_content_to_the_tool(self):
        result = await self._run_form_resume("accept", {"name": "learner"})
        self.assertEqual(result, "accepted:learner")

    async def test_form_resume_decline_reaches_the_tool_without_form_content(self):
        result = await self._run_form_resume("decline")
        self.assertEqual(result, "decline")

    async def test_form_resume_cancel_reaches_the_tool_without_form_content(self):
        result = await self._run_form_resume("cancel")
        self.assertEqual(result, "cancel")


class FastMCPAuthContracts(unittest.TestCase):
    def test_authored_static_token_auth_uses_httpx2_bearer_flow(self):
        """The authored FastMCP Client token example produces an httpx2 auth flow."""
        for notebook_path in AUTHORED_MCP_NOTEBOOKS:
            with self.subTest(notebook=notebook_path.relative_to(REPO_ROOT)):
                namespace = _execute_auth_setup_from_notebook(notebook_path)
                auth_group = namespace["auth_group"]
                weather_client = namespace["weather_client"]
                calendar_client = namespace["calendar_client"]

                self.assertEqual(list(auth_group.clients), ["weather", "calendar"])
                self.assertIs(auth_group.clients["weather"], weather_client)
                self.assertIs(auth_group.clients["calendar"], calendar_client)
                self.assertIsInstance(weather_client.transport.auth, httpx2.Auth)

                request = httpx2.Request("GET", "https://weather-mcp.example.com/mcp")
                authorized = next(weather_client.transport.auth.auth_flow(request))

                self.assertEqual(
                    authorized.headers["authorization"],
                    "Bearer ${WEATHER_MCP_TOKEN}",
                )

    def test_authored_oauth_client_uses_fastmcp_httpx2_auth(self):
        """The authored OAuth Client example stays on FastMCP's httpx2 auth surface."""
        for notebook_path in AUTHORED_MCP_NOTEBOOKS:
            with self.subTest(notebook=notebook_path.relative_to(REPO_ROOT)):
                namespace = _execute_auth_setup_from_notebook(notebook_path)
                calendar_client = namespace["calendar_client"]

                self.assertIsInstance(calendar_client.transport.auth, httpx2.Auth)


if __name__ == "__main__":
    unittest.main()
