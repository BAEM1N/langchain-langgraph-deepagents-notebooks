# Personal Assistant with Subagents

This tutorial covers building a personal assistant using the supervisor pattern with specialized sub-agents. The supervisor coordinates between a calendar agent and an email agent, each with their own tools and capabilities, while human-in-the-loop middleware ensures the user approves sensitive actions.

## Architecture

The system is organized into three layers:

```
              [Supervisor Agent]
             /                  \
    [Calendar Agent]        [Email Agent]
     /     |     \           /    |    \
  create  read  update    send  read  search
  event   event  event    email email  email
```

| Layer | Components | Responsibility |
|-------|-----------|----------------|
| **Low-level tools** | Calendar API calls, Email API calls | Direct interaction with external services |
| **Sub-agents** | Calendar Agent, Email Agent | Domain-specific reasoning over their tool set |
| **Supervisor** | Supervisor Agent | Task decomposition, delegation, and result aggregation |

## Prerequisites

```bash
pip install langchain langchain-openai google-api-python-client
```

```bash
export OPENAI_API_KEY="your-openai-key"
export GOOGLE_CALENDAR_CREDENTIALS="path/to/credentials.json"
export EMAIL_API_KEY="your-email-api-key"
```

## Step 1: Define Low-Level Tools

### Calendar Tools

```python
from langchain_core.tools import tool

@tool
def create_calendar_event(title: str, start_time: str, end_time: str, attendees: list[str] = None) -> str:
    """Create a new calendar event.

    Args:
        title: Event title.
        start_time: Start time in ISO 8601 format.
        end_time: End time in ISO 8601 format.
        attendees: Optional list of attendee email addresses.
    """
    # Google Calendar API integration
    event = calendar_service.events().insert(
        calendarId="primary",
        body={
            "summary": title,
            "start": {"dateTime": start_time},
            "end": {"dateTime": end_time},
            "attendees": [{"email": a} for a in (attendees or [])],
        },
    ).execute()
    return f"Event created: {event['htmlLink']}"

@tool
def read_calendar_events(date: str) -> str:
    """Read calendar events for a specific date.

    Args:
        date: The date to query in YYYY-MM-DD format.
    """
    events = calendar_service.events().list(
        calendarId="primary",
        timeMin=f"{date}T00:00:00Z",
        timeMax=f"{date}T23:59:59Z",
    ).execute()
    return format_events(events.get("items", []))

@tool
def update_calendar_event(event_id: str, title: str = None, start_time: str = None, end_time: str = None) -> str:
    """Update an existing calendar event.

    Args:
        event_id: The ID of the event to update.
        title: New event title (optional).
        start_time: New start time in ISO 8601 format (optional).
        end_time: New end time in ISO 8601 format (optional).
    """
    body = {}
    if title:
        body["summary"] = title
    if start_time:
        body["start"] = {"dateTime": start_time}
    if end_time:
        body["end"] = {"dateTime": end_time}
    event = calendar_service.events().patch(
        calendarId="primary", eventId=event_id, body=body
    ).execute()
    return f"Event updated: {event['summary']}"
```

### Email Tools

```python
@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Send an email message.

    Args:
        to: Recipient email address.
        subject: Email subject line.
        body: Email body text.
    """
    message = email_service.send(to=to, subject=subject, body=body)
    return f"Email sent to {to}. Message ID: {message['id']}"

@tool
def read_emails(folder: str = "inbox", limit: int = 10) -> str:
    """Read recent emails from a folder.

    Args:
        folder: Email folder to read from (default: inbox).
        limit: Maximum number of emails to return.
    """
    messages = email_service.list(folder=folder, limit=limit)
    return format_emails(messages)

@tool
def search_emails(query: str, limit: int = 10) -> str:
    """Search emails by query string.

    Args:
        query: Search query (supports sender, subject, date filters).
        limit: Maximum number of results.
    """
    results = email_service.search(query=query, limit=limit)
    return format_emails(results)
```

## Step 2: Create Sub-Agents

Each sub-agent is a specialized agent with access to its own tool set and a domain-specific system prompt.

```python
from langchain.agents import create_agent

calendar_agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[create_calendar_event, read_calendar_events, update_calendar_event],
    system_prompt=(
        "You are a calendar management assistant. You help users manage their schedule "
        "by creating, reading, and updating calendar events. Always confirm event details "
        "before creating or modifying events. Use ISO 8601 format for all dates and times."
    ),
    name="calendar_agent",
)

email_agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[send_email, read_emails, search_emails],
    system_prompt=(
        "You are an email assistant. You help users manage their email by sending, "
        "reading, and searching messages. When composing emails, match the user's "
        "tone and keep messages professional unless instructed otherwise."
    ),
    name="email_agent",
)
```

## Step 3: Create the Supervisor

The supervisor agent delegates tasks to sub-agents based on the user's request. Sub-agents appear as tools to the supervisor.

```python
supervisor = create_agent(
    model="claude-sonnet-4-6",
    tools=[calendar_agent, email_agent],
    system_prompt=(
        "You are a personal assistant that coordinates between a calendar agent "
        "and an email agent. Break complex requests into sub-tasks and delegate "
        "them to the appropriate agent.\n\n"
        "Examples:\n"
        "- 'Schedule a meeting with John and send him an invite' -> use calendar_agent "
        "to create the event, then email_agent to send the invitation.\n"
        "- 'What's on my calendar today?' -> delegate to calendar_agent.\n"
        "- 'Reply to Sarah's last email' -> delegate to email_agent.\n\n"
        "Aggregate results from sub-agents and present a unified response to the user."
    ),
)
```

## Step 4: Add Human-in-the-Loop

Use `HumanInTheLoopMiddleware` to require approval for actions that modify external state (sending emails, creating events).

```python
from langchain.middleware import HumanInTheLoopMiddleware

hitl = HumanInTheLoopMiddleware(
    tool_names=["send_email", "create_calendar_event", "update_calendar_event"],
)

supervisor = create_agent(
    model="claude-sonnet-4-6",
    tools=[calendar_agent, email_agent],
    system_prompt="You are a personal assistant...",
    middleware=[hitl],
)
```

### Handling Approval Responses

When the agent attempts to call a protected tool, execution pauses for human review.

```python
from langchain_core.commands import Command

# Agent pauses before sending an email
response = supervisor.invoke(
    {"messages": [{"role": "user", "content": "Send a meeting invite to john@example.com for tomorrow at 2pm"}]}
)

# Approve the action
result = supervisor.invoke(Command(resume="approve"))

# Edit the action before executing
result = supervisor.invoke(Command(resume={
    "type": "edit",
    "args": {
        "to": "john@example.com",
        "subject": "Meeting Tomorrow at 2:00 PM",
        "body": "Hi John,\n\nLet's meet tomorrow at 2pm to discuss the project.\n\nBest regards",
    }
}))

# Reject the action
result = supervisor.invoke(Command(resume={
    "type": "reject",
    "reason": "I changed my mind about the meeting."
}))
```

## Step 5: Context Passing with ToolRuntime

Use `ToolRuntime` to pass runtime context (such as the current user's identity or timezone) to sub-agents without including it in every message.

```python
from langchain.runtime import ToolRuntime

runtime = ToolRuntime(
    context={
        "user_email": "me@example.com",
        "user_name": "Alice",
        "timezone": "America/New_York",
        "calendar_id": "primary",
    }
)

supervisor = create_agent(
    model="claude-sonnet-4-6",
    tools=[calendar_agent, email_agent],
    system_prompt="You are a personal assistant...",
    middleware=[hitl],
    runtime=runtime,
)
```

Sub-agents can access the runtime context within their tool implementations:

```python
@tool
def send_email(to: str, subject: str, body: str, *, runtime_context: dict) -> str:
    """Send an email from the current user."""
    sender = runtime_context["user_email"]
    # ... send with sender identity
```

## Execution Example

```
User: "Check if I have anything at 2pm tomorrow, and if not, schedule a meeting
       with Sarah and send her an invite."

Supervisor -> calendar_agent: "Check events for tomorrow around 2pm"
  calendar_agent -> read_calendar_events("2026-03-06")
  calendar_agent: "You have no events between 1pm and 4pm tomorrow."

Supervisor -> calendar_agent: "Create a meeting with Sarah tomorrow at 2pm-3pm"
  calendar_agent -> create_calendar_event(
      title="Meeting with Sarah",
      start_time="2026-03-06T14:00:00-05:00",
      end_time="2026-03-06T15:00:00-05:00",
      attendees=["sarah@example.com"]
  )
  [HITL: Awaiting approval for create_calendar_event]
  -> Approved
  calendar_agent: "Event created successfully."

Supervisor -> email_agent: "Send Sarah a meeting invitation email"
  email_agent -> send_email(
      to="sarah@example.com",
      subject="Meeting Tomorrow at 2:00 PM",
      body="Hi Sarah, ..."
  )
  [HITL: Awaiting approval for send_email]
  -> Approved
  email_agent: "Email sent to sarah@example.com."

Supervisor: "Done! I've scheduled a meeting with Sarah tomorrow from 2-3 PM
             and sent her an invitation email."
```

## Design Considerations

| Consideration | Recommendation |
|--------------|----------------|
| Sub-agent granularity | One agent per domain (calendar, email, etc.) |
| Tool overlap | Avoid giving the same tool to multiple sub-agents |
| Error handling | Supervisor should handle sub-agent failures gracefully |
| Context passing | Use ToolRuntime for shared context, not repeated prompt text |
| Approval scope | Only require HITL for state-modifying operations |
