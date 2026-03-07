# Deep Agents Overview

Deep Agents is a framework designed to streamline agent development with built-in capabilities. It functions as an "agent harness" providing task planning, file system management, subagent delegation, and persistent memory features.

## Key Components

The `deepagents` library includes two primary offerings:

1. **Deep Agents SDK** – A package for constructing agents capable of handling diverse tasks
2. **Deep Agents CLI** – A terminal-based coding agent built on the SDK

The framework builds upon LangChain's foundational agent components and utilizes LangGraph for execution management.

## Core Capabilities

- **Task Planning**: Agents can decompose complex problems into manageable steps using built-in todo functionality
- **Context Management**: File system tools enable agents to handle large datasets without overwhelming token limits
- **Flexible Storage**: Pluggable backends support in-memory storage, local disks, durable stores, and sandboxed environments
- **Subagent Delegation**: Agents can spawn specialized sub-agents to isolate context for specific subtasks
- **Persistent Memory**: Agents maintain information across multiple conversations using LangGraph's memory infrastructure

## Getting Started

The documentation recommends the SDK Quickstart and Customization guide for initial development. It also suggests using LangSmith for tracing and debugging agent behavior.

## Use Cases

The Deep Agents SDK suits complex multi-step tasks, while the CLI serves interactive command-line needs for coding and similar applications.
