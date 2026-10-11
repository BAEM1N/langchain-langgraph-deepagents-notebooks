"""Offline behavioral checks for the SDK contracts taught by this course.

Run with ``uv run --all-extras python -m unittest discover -s tests -v``.
No model provider, remote LangSmith, database, or cloud sandbox is contacted.
"""

from __future__ import annotations

import json
import os
import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path
from types import SimpleNamespace
from typing import NotRequired
from unittest.mock import PropertyMock, patch

from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend, StoreBackend
from deepagents.middleware import FilesystemMiddleware, SkillsMiddleware
from fastmcp import FastMCP
from langchain.agents import create_agent
from langchain.agents.middleware import TodoListMiddleware
from langchain.agents.middleware.types import InputAgentState
from langchain.mcp import MCPAdapter
from langchain.tools import tool
from langchain_core.language_models.fake_chat_models import FakeMessagesListChatModel
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.runnables import RunnableConfig
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import END, START, StateGraph
from langgraph.store.memory import InMemoryStore
from langgraph.types import Command, interrupt
from langsmith import Client
from langsmith._openapi_client import AsyncLangsmith
from langsmith._openapi_client._httpx import httpx
from mcp import types as mcp_types
from pydantic import BaseModel, Field, SecretStr
from typing_extensions import TypedDict


class RecordingModel(FakeMessagesListChatModel):
    """Record tools without making a provider request."""

    bound_names: list[str] = Field(default_factory=list)

    def bind_tools(self, tools, **kwargs):
        self.bound_names = [item.name for item in tools]
        return self


def model():
    return RecordingModel(responses=[AIMessage(content="done")])


class SkillInput(InputAgentState):
    pinned_skills: NotRequired[list[str]]


def user_input(content: str) -> InputAgentState:
    return {"messages": [HumanMessage(content=content)]}


class HarnessContracts(unittest.TestCase):
    def setUp(self):
        self.environment = patch.dict(os.environ, {"LANGSMITH_TRACING": "false"})
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def test_planning_is_explicit(self):
        plain = model()
        create_deep_agent(model=plain).invoke(user_input("hello"))
        self.assertNotIn("write_todos", plain.bound_names)
        planned = model()
        create_deep_agent(model=planned, middleware=[TodoListMiddleware()]).invoke(
            user_input("plan")
        )
        self.assertIn("write_todos", planned.bound_names)

    def test_filesystem_overwrites_and_deletes_within_root(self):
        with tempfile.TemporaryDirectory() as directory:
            backend = FilesystemBackend(root_dir=directory)
            self.assertIsNone(backend.write("/note.txt", "first").error)
            self.assertIsNone(backend.write("/note.txt", "second").error)
            result = backend.read("/note.txt")
            assert result.file_data is not None
            self.assertEqual(result.file_data["content"], "second")
            self.assertEqual(Path(directory, "note.txt").read_text(), "second")
            self.assertIsNone(backend.delete("/note.txt").error)
            self.assertFalse(Path(directory, "note.txt").exists())
            with self.assertRaisesRegex(ValueError, "traversal"):
                backend.write("/../escape.txt", "blocked")

    def test_store_namespace_is_required_and_still_accepts_factory(self):
        store = InMemoryStore()
        with self.assertRaises(TypeError):
            StoreBackend(store=store)  # pyright: ignore[reportCallIssue] -- intentional invalid-input check
        first = StoreBackend(store=store, namespace=lambda runtime: ("first",))
        second = StoreBackend(store=store, namespace=lambda runtime: ("second",))
        self.assertIsNone(first.write("/memory.txt", "persistent").error)
        result = first.read("/memory.txt")
        assert result.file_data is not None
        self.assertEqual(result.file_data["content"], "persistent")
        self.assertIsNotNone(second.read("/memory.txt").error)

    def test_tool_allowlist_removes_write_and_delete(self):
        with tempfile.TemporaryDirectory() as directory:
            backend = FilesystemBackend(root_dir=directory)
            readonly = model()
            agent = create_deep_agent(
                model=readonly,
                backend=backend,
                middleware=[
                    FilesystemMiddleware(backend=backend, tools=["ls", "read_file"])
                ],
            )
            agent.invoke(user_input("inspect"))
            self.assertIn("read_file", readonly.bound_names)
            self.assertNotIn("write_file", readonly.bound_names)
            self.assertNotIn("delete", readonly.bound_names)

    def test_pinned_skill_reveals_its_tools(self):
        @tool
        def skill_echo(text: str) -> str:
            """Echo text for the selected skill."""
            return text

        with tempfile.TemporaryDirectory() as directory:
            skill = Path(directory, "skills", "echo", "SKILL.md")
            skill.parent.mkdir(parents=True)
            skill.write_text(
                "---\nname: echo\ndescription: Echo a message\nmetadata:\n"
                "  include_tools: skill_echo\n---\nUse skill_echo for echoes.\n"
            )
            backend = FilesystemBackend(root_dir=directory)
            recording = model()
            agent = create_deep_agent(
                model=recording,
                backend=backend,
                middleware=[
                    SkillsMiddleware(
                        backend=backend, sources=["/skills/"], tools=[skill_echo]
                    )
                ],
            )
            agent.invoke(user_input("hello"))
            self.assertNotIn("skill_echo", recording.bound_names)
            result = agent.invoke(
                SkillInput(
                    messages=[HumanMessage(content="echo")], pinned_skills=["echo"]
                )
            )
            self.assertIn("skill_echo", recording.bound_names)
            self.assertTrue(
                any(
                    message.additional_kwargs.get("lc_source") == "pinned_skill"
                    for message in result["messages"]
                )
            )

    def test_fork_inherits_skills_instead_of_redefining_them(self):
        with self.assertRaisesRegex(ValueError, "skills"):
            create_deep_agent(
                model=model(),
                subagents=[
                    {
                        "name": "forked",
                        "description": "Fork the task",
                        "mode": "fork",
                        "skills": ["/skills/"],
                    }
                ],
            )


class GraphContracts(unittest.TestCase):
    def test_schema_is_exposed_and_checkpoint_resume_works(self):
        class Approval(BaseModel):
            approved: bool

        class State(TypedDict):
            approved: bool

        def approve(state):
            answer = interrupt({"question": "Approve?"}, response_schema=Approval)
            return {"approved": answer.approved}

        graph = StateGraph(State)
        graph.add_node("approve", approve)
        graph.add_edge(START, "approve")
        graph.add_edge("approve", END)
        app = graph.compile(checkpointer=InMemorySaver())
        config: RunnableConfig = {"configurable": {"thread_id": "offline-approval"}}
        first = app.invoke({"approved": False}, config)
        pending = first["__interrupt__"][0]
        self.assertIsNotNone(pending.response_schema)
        final = app.invoke(Command(resume={"approved": True}), config)
        self.assertTrue(final["approved"])


class ProviderConfiguration(unittest.TestCase):
    def test_openai_explicit_key_and_responses_configuration(self):
        from langchain_openai import ChatOpenAI

        with patch.dict(os.environ, {"OPENAI_API_KEY": "environment-placeholder"}):
            configured = ChatOpenAI(
                model="gpt-5.4",
                api_key=SecretStr("explicit-placeholder"),
                base_url="https://example.invalid/v1",
                use_responses_api=True,
            )
        assert isinstance(configured.openai_api_key, SecretStr)
        self.assertEqual(
            configured.openai_api_key.get_secret_value(), "explicit-placeholder"
        )
        self.assertEqual(
            str(configured.root_client.base_url), "https://example.invalid/v1/"
        )
        self.assertTrue(configured.use_responses_api)

    def test_google_thinking_level_alias(self):
        from langchain_google_genai import ChatGoogleGenerativeAI

        configured = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            api_key="offline-placeholder",
            thinking_level="low",
        )
        self.assertEqual(configured.reasoning_effort, "low")
        self.assertEqual(configured.thinking_level, "low")


class AsyncContracts(unittest.IsolatedAsyncioTestCase):
    async def test_mcp_input_required_interrupt_and_form_resume(self):
        server = FastMCP("course-form-test")

        @server.tool
        def ask_name() -> str:
            return "replaced by the controlled modern protocol fixture"

        async def interactive_call(context, params):
            if not params.input_responses:
                question = mcp_types.ElicitRequest(
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
                    input_requests={"name_form": question}, request_state="asked"
                )
            answer = params.input_responses["name_form"]
            return mcp_types.CallToolResult(
                content=[
                    mcp_types.TextContent(type="text", text=answer.content["name"])
                ],
                structured_content={"result": answer.content["name"]},
            )

        # A wire-level fixture is needed: legacy Context.elicit() cannot
        # represent a modern InputRequiredResult server response.
        server._mcp_server.add_request_handler(
            "tools/call", mcp_types.CallToolRequestParams, interactive_call
        )
        recording = RecordingModel(
            responses=[
                AIMessage(
                    content="",
                    tool_calls=[
                        {
                            "name": "ask_name",
                            "args": {},
                            "id": "ask-1",
                            "type": "tool_call",
                        }
                    ],
                ),
                AIMessage(content="done"),
            ]
        )
        async with MCPAdapter(server) as adapter:
            agent = create_agent(
                recording, await adapter.list_tools(), checkpointer=InMemorySaver()
            )
            config: RunnableConfig = {"configurable": {"thread_id": "offline-mcp-form"}}
            paused = await agent.ainvoke(user_input("ask my name"), config)
            request = paused["__interrupt__"][0].value["requests"][0]
            self.assertEqual(request["key"], "name_form")
            resumed = await agent.ainvoke(
                Command(
                    resume={
                        "responses": {
                            request["key"]: {
                                "action": "accept",
                                "content": {"name": "learner"},
                            }
                        }
                    }
                ),
                config,
            )
            tool_reply = next(
                message for message in resumed["messages"] if message.type == "tool"
            )
            self.assertTrue(
                any(block.get("text") == "learner" for block in tool_reply.content)
            )
            self.assertEqual(resumed["messages"][-1].content, "done")

    async def test_mcp_calls_stay_inside_adapter_lifetime(self):
        server = FastMCP("course-test")

        @server.tool
        def add(left: int, right: int) -> int:
            return left + right

        async with MCPAdapter(server) as adapter:
            tools = await adapter.list_tools()
            self.assertEqual([item.name for item in tools], ["add"])
            content = await tools[0].ainvoke({"left": 2, "right": 3})
            self.assertTrue(any(block.get("text") == "5" for block in content))

    async def test_smithdb_pagination_preserves_explicit_window(self):
        requests = []

        async def handler(request):
            body = json.loads(request.content)
            requests.append(body)
            index = 2 if body.get("cursor") else 1
            # SmithDB returns ID only unless the caller requests other fields.
            row = {"id": str(index)}
            if "NAME" in body.get("selects", []):
                row["name"] = f"run-{index}"
            return httpx.Response(
                200,
                json={
                    "items": [row],
                    "next_cursor": None if index == 2 else "page-2",
                },
            )

        async with (
            httpx.AsyncClient(transport=httpx.MockTransport(handler)) as http_client,
            AsyncLangsmith(
                api_key="offline",
                base_url="https://example.invalid",
                http_client=http_client,
            ) as api,
        ):
            with (
                patch.object(
                    Client,
                    "info",
                    new_callable=PropertyMock,
                    return_value=SimpleNamespace(version="0.16.0"),
                ),
                patch.object(Client, "_get_langsmith_api", return_value=api),
            ):
                client = Client(
                    api_key="offline",
                    api_url="https://example.invalid",
                    auto_batch_tracing=False,
                )
                try:
                    start = datetime(2020, 1, 1, tzinfo=UTC)
                    runs = [
                        run
                        async for run in client.runs.query(
                            project_ids=["00000000-0000-0000-0000-000000000001"],
                            min_start_time=start,
                            max_start_time=datetime.now(UTC),
                            page_size=1,
                            selects=["ID", "NAME"],
                        )
                    ]
                finally:
                    client.close()
        self.assertEqual([run.name for run in runs], ["run-1", "run-2"])
        self.assertEqual(requests[1]["cursor"], "page-2")
        self.assertEqual(requests[0]["min_start_time"], requests[1]["min_start_time"])
        self.assertEqual(requests[0]["project_ids"], requests[1]["project_ids"])


if __name__ == "__main__":
    unittest.main()
