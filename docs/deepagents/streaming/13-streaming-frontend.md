# Streaming Frontend

## Overview
The `useStream` React hook enables developers to build real-time UIs that display subagent streaming from deep agents. It manages lifecycle tracking, message separation, and tool call visibility.

## Key Features

- **Subagent tracking**: Automated lifecycle management with states (pending, running, complete, error)
- **Message filtering**: Ability to isolate subagent communications from primary conversation
- **Tool call visibility**: Access to tool execution details within subagents
- **State reconstruction**: Recovery of subagent state after page reloads

## Configuration

Basic setup requires:
- Importing the hook from LangGraph SDK
- Setting `filterSubagentMessages: true` to separate streams
- Passing `streamSubgraphs: true` during message submission

## SubagentStream Interface

Each subagent exposes properties including:
- Identity markers (id, toolCall details)
- Lifecycle timestamps and status indicators
- Message arrays and state values
- Tool call tracking with results
- Hierarchy information (depth, parentId)

## UI Implementation Patterns

Three rendering approaches:
1. Individual subagent cards showing status, content, and results
2. Message-to-subagent mapping for contextual association
3. Pipeline views with progress bars and grid layouts

## Thread Persistence

URL parameter-based persistence allows users to resume conversations after page reloads, with automatic state reconstruction from history.
