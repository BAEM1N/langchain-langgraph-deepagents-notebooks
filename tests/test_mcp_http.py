"""Exercise real MCP Streamable HTTP requests without external services."""

from __future__ import annotations

import os
import unittest
from contextlib import asynccontextmanager
from unittest.mock import patch

import httpx2
from fastmcp import Client, ClientGroup, FastMCP
from fastmcp.client.transports.http import StreamableHttpTransport
from langchain.mcp import MCPAdapter
from langchain_core.messages import ToolMessage
from mcp.shared.exceptions import MCPError
from starlette.responses import JSONResponse

from tests.test_authored_mcp import (
    AUTHORED_MCP_NOTEBOOKS,
    _execute_auth_setup_from_notebook,
    _text_blocks,
)


@asynccontextmanager
async def http_fixture(auth=None, *, expected_authorization=None):
    server = FastMCP("http-math")
    observations = {"authorized_requests": 0, "rejected_requests": 0, "tool_calls": 0}

    @server.tool
    def add(a: int, b: int) -> int:
        """Add two integers."""
        observations["tool_calls"] += 1
        return a + b

    app = server.http_app(path="/mcp", json_response=True, stateless_http=True)

    async def guarded_app(scope, receive, send):
        if scope["type"] == "http":
            headers = dict(scope.get("headers", []))
            if (
                expected_authorization is not None
                and headers.get(b"authorization") != expected_authorization.encode()
            ):
                observations["rejected_requests"] += 1
                await JSONResponse({"error": "unauthorized"}, status_code=401)(
                    scope, receive, send
                )
                return
            observations["authorized_requests"] += 1
        await app(scope, receive, send)

    def factory(headers=None, timeout=None, auth=None, **kwargs):
        return httpx2.AsyncClient(
            transport=httpx2.ASGITransport(app=guarded_app),
            headers=headers,
            timeout=timeout or httpx2.Timeout(10.0),
            auth=auth,
            **kwargs,
        )

    transport = StreamableHttpTransport(
        "http://127.0.0.1/mcp", auth=auth, httpx_client_factory=factory
    )
    async with app.router.lifespan_context(app):
        yield Client(transport), observations


class MCPHTTPContracts(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        environment = patch.dict(
            os.environ, {"LANGSMITH_TRACING": "false", "LANGCHAIN_TRACING_V2": "false"}
        )
        environment.start()
        self.addCleanup(environment.stop)

    async def test_http_discovery_and_post_context_call(self):
        async with http_fixture() as (client, observations):
            async with MCPAdapter(client) as adapter:
                tools = await adapter.list_tools()
                add_tool = next(tool for tool in tools if tool.name == "add")
            result = await add_tool.ainvoke({"a": 8, "b": 9})
            self.assertEqual(_text_blocks(result), ["17"])
            self.assertEqual(observations["tool_calls"], 1)
            self.assertGreater(observations["authorized_requests"], 0)

    async def test_authored_bearer_auth_reaches_http_server(self):
        for path in AUTHORED_MCP_NOTEBOOKS:
            with self.subTest(notebook=path.name):
                namespace = _execute_auth_setup_from_notebook(path)
                auth = namespace["weather_client"].transport.auth
                async with http_fixture(
                    auth, expected_authorization="Bearer ${WEATHER_MCP_TOKEN}"
                ) as (client, observations):
                    async with MCPAdapter(client) as adapter:
                        tools = await adapter.list_tools()
                        result = await tools[0].ainvoke({"a": 3, "b": 4})
                    self.assertEqual(_text_blocks(result), ["7"])
                    self.assertEqual(observations["rejected_requests"], 0)
                    self.assertEqual(observations["tool_calls"], 1)

    async def test_invalid_bearer_is_rejected_before_tool_execution(self):
        async with http_fixture(
            "synthetic-wrong-token",
            expected_authorization="Bearer synthetic-expected-token",
        ) as (client, observations):
            with self.assertRaises(MCPError):
                async with MCPAdapter(client) as adapter:
                    await adapter.list_tools()
            self.assertGreater(observations["rejected_requests"], 0)
            self.assertEqual(observations["tool_calls"], 0)

    async def test_multiple_http_servers_route_same_named_tools_independently(self):
        async with (
            http_fixture() as (first, first_observations),
            http_fixture() as (second, second_observations),
        ):
            group = ClientGroup({"first": first, "second": second})
            async with MCPAdapter(group) as adapter:
                tools = {tool.name: tool for tool in await adapter.list_tools()}
                self.assertEqual(set(tools), {"first_add", "second_add"})
                first_reply = await tools["first_add"].ainvoke({"a": 2, "b": 4})
                second_reply = await tools["second_add"].ainvoke({"a": 5, "b": 7})
            self.assertEqual(_text_blocks(first_reply), ["6"])
            self.assertEqual(_text_blocks(second_reply), ["12"])
            self.assertEqual(first_observations["tool_calls"], 1)
            self.assertEqual(second_observations["tool_calls"], 1)

    async def test_http_structured_content_is_preserved_in_tool_message_artifact(self):
        async with http_fixture() as (client, observations):
            async with MCPAdapter(client) as adapter:
                tool = (await adapter.list_tools())[0]
                message = await tool.ainvoke(
                    {
                        "name": "add",
                        "args": {"a": 6, "b": 8},
                        "id": "http-structured-1",
                        "type": "tool_call",
                    }
                )
            self.assertIsInstance(message, ToolMessage)
            self.assertEqual(message.artifact, {"structured_content": {"result": 14}})
            self.assertEqual(observations["tool_calls"], 1)


if __name__ == "__main__":
    unittest.main()
