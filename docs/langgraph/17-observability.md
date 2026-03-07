# LangSmith Observability Documentation

## Overview
LangSmith provides visualization capabilities for application execution traces. A trace represents the journey from input to output through individual steps called runs.

## Key Capabilities
According to the documentation, LangSmith enables users to:
- "Debug a locally running application"
- Evaluate application performance through assessments
- Monitor applications via dashboards

## Getting Started Requirements
Users need two things: a free LangSmith account at smith.langchain.com and an API key obtained through their account settings.

## Enabling Tracing
To activate tracing, set these environment variables:
```
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY=<your-api-key>
```

Traces log to a "default" project by default, but custom project names are configurable.

## Selective Tracing
The `tracing_context` context manager allows tracing specific operations while leaving others untraced, providing granular control over what gets monitored.

## Metadata and Tagging
Both the `invoke()` method and `tracing_context` accept configuration for tags and metadata, enabling users to annotate traces with contextual information like user IDs and environment details.

## Data Privacy
LangSmith supports anonymizers that mask sensitive information patterns (like Social Security Numbers) before logging to prevent exposure of protected data.
