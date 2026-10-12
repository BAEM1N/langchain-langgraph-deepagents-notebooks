"""Catch retired MCP code even when a teaching snippet cannot be compiled."""

import unittest

from scripts.validate_materials import mcp_source_errors


class MCPMaterialGuards(unittest.TestCase):
    def test_retired_import_in_embedded_server_program_is_rejected(self):
        source = (
            "server_path.write_text('from mcp.server.fastmcp import FastMCP\\n...')"
        )
        self.assertTrue(mcp_source_errors(source))

    def test_partial_snippet_still_rejects_retired_adapter_import(self):
        source = "from langchain_mcp_adapters.tools import load_mcp_tools\nresult = ("
        self.assertTrue(mcp_source_errors(source))

    def test_explicit_historical_reference_is_allowed(self):
        source = "# historical MCP migration reference\nfrom langchain_mcp_adapters.client import MultiServerMCPClient"
        self.assertFalse(mcp_source_errors(source))

    def test_httpx2_alias_is_valid_for_fastmcp_auth(self):
        source = "import httpx2 as httpx\nfrom fastmcp import Client\nclass ScopedAuth(httpx.Auth):\n    pass"
        self.assertFalse(mcp_source_errors(source))

    def test_plain_httpx_auth_is_not_fastmcp_auth(self):
        source = "import httpx\nfrom fastmcp import Client\nclass ScopedAuth(httpx.Auth):\n    pass"
        self.assertTrue(mcp_source_errors(source))
