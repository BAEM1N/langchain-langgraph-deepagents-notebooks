# Structured Output

## Overview

Structured output enables agents to return data in predictable, machine-readable formats. Rather than parsing natural language, applications receive JSON objects, Pydantic models, or dataclasses directly.

LangChain's `create_agent` function automatically manages structured output. Users define their schema, and when the model generates structured data, it's captured, validated, and returned in the `'structured_response'` key of the agent's state.

## Response Format Parameter

The `response_format` parameter controls structured data return:

- **`ToolStrategy[StructuredResponseT]`**: Uses tool calling for structured output
- **`ProviderStrategy[StructuredResponseT]`**: Uses provider-native structured output
- **`type[StructuredResponseT]`**: Schema type with automatic strategy selection
- **`None`**: No explicit structured output requested

When a schema type is provided directly, LangChain automatically selects:

- `ProviderStrategy` for models supporting native structured output (OpenAI, Anthropic, xAI)
- `ToolStrategy` for all other models

## Provider Strategy

Native structured output through model provider APIs offers the most reliability. Supported by OpenAI, xAI, Gemini, and Anthropic.

### Configuration

```python
class ProviderStrategy(Generic[SchemaT]):
    schema: type[SchemaT]
    strict: bool | None = None
```

**Schema** (required): Accepts Pydantic models, dataclasses, TypedDict, or JSON Schema dictionaries.

**Strict** (optional): Enables strict schema adherence for providers like OpenAI and xAI.

### Examples

**Pydantic Model:**

```python
from pydantic import BaseModel, Field
from langchain.agents import create_agent

class ContactInfo(BaseModel):
    """Contact information for a person."""
    name: str = Field(description="The name of the person")
    email: str = Field(description="The email address of the person")
    phone: str = Field(description="The phone number of the person")

agent = create_agent(
    model="gpt-5",
    response_format=ContactInfo
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Extract contact info from: John Doe, john@example.com, (555) 123-4567"}]
})

print(result["structured_response"])
# ContactInfo(name='John Doe', email='john@example.com', phone='(555) 123-4567')
```

**Dataclass:**

```python
from dataclasses import dataclass
from langchain.agents import create_agent

@dataclass
class ContactInfo:
    """Contact information for a person."""
    name: str
    email: str
    phone: str

agent = create_agent(
    model="gpt-5",
    tools=tools,
    response_format=ContactInfo
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Extract contact info from: John Doe, john@example.com, (555) 123-4567"}]
})

result["structured_response"]
# {'name': 'John Doe', 'email': 'john@example.com', 'phone': '(555) 123-4567'}
```

**TypedDict:**

```python
from typing_extensions import TypedDict
from langchain.agents import create_agent

class ContactInfo(TypedDict):
    """Contact information for a person."""
    name: str
    email: str
    phone: str

agent = create_agent(
    model="gpt-5",
    tools=tools,
    response_format=ContactInfo
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Extract contact info from: John Doe, john@example.com, (555) 123-4567"}]
})

result["structured_response"]
# {'name': 'John Doe', 'email': 'john@example.com', 'phone': '(555) 123-4567'}
```

**JSON Schema:**

```python
from langchain.agents import create_agent

contact_info_schema = {
    "type": "object",
    "description": "Contact information for a person.",
    "properties": {
        "name": {"type": "string", "description": "The name of the person"},
        "email": {"type": "string", "description": "The email address of the person"},
        "phone": {"type": "string", "description": "The phone number of the person"}
    },
    "required": ["name", "email", "phone"]
}

agent = create_agent(
    model="gpt-5",
    tools=tools,
    response_format=ProviderStrategy(contact_info_schema)
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Extract contact info from: John Doe, john@example.com, (555) 123-4567"}]
})

result["structured_response"]
# {'name': 'John Doe', 'email': 'john@example.com', 'phone': '(555) 123-4567'}
```

Provider-native structured output offers high reliability and strict validation because the model provider enforces the schema requirements.

## Tool Calling Strategy

For models without native structured output support, LangChain uses tool calling. This works with all models supporting tool calling.

### Configuration

```python
class ToolStrategy(Generic[SchemaT]):
    schema: type[SchemaT]
    tool_message_content: str | None
    handle_errors: Union[
        bool,
        str,
        type[Exception],
        tuple[type[Exception], ...],
        Callable[[Exception], str],
    ]
```

**Schema** (required): Supports Pydantic models, dataclasses, TypedDict, JSON Schema, and Union types.

**tool_message_content** (optional): Custom message for tool response when structured output is generated.

**handle_errors** (optional): Error handling strategy with these options:

- `True`: Catch all errors with default template
- `str`: Catch all errors with custom message
- `type[Exception]`: Catch only this exception type
- `tuple[type[Exception], ...]`: Catch these exception types
- `Callable[[Exception], str]`: Custom function returning error message
- `False`: No retry, let exceptions propagate

### Examples

**Pydantic Model:**

```python
from pydantic import BaseModel, Field
from typing import Literal
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy

class ProductReview(BaseModel):
    """Analysis of a product review."""
    rating: int | None = Field(description="The rating of the product", ge=1, le=5)
    sentiment: Literal["positive", "negative"] = Field(description="The sentiment of the review")
    key_points: list[str] = Field(description="The key points of the review. Lowercase, 1-3 words each.")

agent = create_agent(
    model="gpt-5",
    tools=tools,
    response_format=ToolStrategy(ProductReview)
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
})
result["structured_response"]
# ProductReview(rating=5, sentiment='positive', key_points=['fast shipping', 'expensive'])
```

**Dataclass:**

```python
from dataclasses import dataclass
from typing import Literal
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy

@dataclass
class ProductReview:
    """Analysis of a product review."""
    rating: int | None
    sentiment: Literal["positive", "negative"]
    key_points: list[str]

agent = create_agent(
    model="gpt-5",
    tools=tools,
    response_format=ToolStrategy(ProductReview)
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
})
result["structured_response"]
# {'rating': 5, 'sentiment': 'positive', 'key_points': ['fast shipping', 'expensive']}
```

**TypedDict:**

```python
from typing import Literal
from typing_extensions import TypedDict
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy

class ProductReview(TypedDict):
    """Analysis of a product review."""
    rating: int | None
    sentiment: Literal["positive", "negative"]
    key_points: list[str]

agent = create_agent(
    model="gpt-5",
    tools=tools,
    response_format=ToolStrategy(ProductReview)
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
})
result["structured_response"]
# {'rating': 5, 'sentiment': 'positive', 'key_points': ['fast shipping', 'expensive']}
```

**JSON Schema:**

```python
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy

product_review_schema = {
    "type": "object",
    "description": "Analysis of a product review.",
    "properties": {
        "rating": {
            "type": ["integer", "null"],
            "description": "The rating of the product (1-5)",
            "minimum": 1,
            "maximum": 5
        },
        "sentiment": {
            "type": "string",
            "enum": ["positive", "negative"],
            "description": "The sentiment of the review"
        },
        "key_points": {
            "type": "array",
            "items": {"type": "string"},
            "description": "The key points of the review"
        }
    },
    "required": ["sentiment", "key_points"]
}

agent = create_agent(
    model="gpt-5",
    tools=tools,
    response_format=ToolStrategy(product_review_schema)
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
})
result["structured_response"]
# {'rating': 5, 'sentiment': 'positive', 'key_points': ['fast shipping', 'expensive']}
```

**Union Types:**

```python
from pydantic import BaseModel, Field
from typing import Literal, Union
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy

class ProductReview(BaseModel):
    """Analysis of a product review."""
    rating: int | None = Field(description="The rating of the product", ge=1, le=5)
    sentiment: Literal["positive", "negative"] = Field(description="The sentiment of the review")
    key_points: list[str] = Field(description="The key points of the review. Lowercase, 1-3 words each.")

class CustomerComplaint(BaseModel):
    """A customer complaint about a product or service."""
    issue_type: Literal["product", "service", "shipping", "billing"] = Field(description="The type of issue")
    severity: Literal["low", "medium", "high"] = Field(description="The severity of the complaint")
    description: str = Field(description="Brief description of the complaint")

agent = create_agent(
    model="gpt-5",
    tools=tools,
    response_format=ToolStrategy(Union[ProductReview, CustomerComplaint])
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Analyze this review: 'Great product: 5 out of 5 stars. Fast shipping, but expensive'"}]
})
result["structured_response"]
# ProductReview(rating=5, sentiment='positive', key_points=['fast shipping', 'expensive'])
```

### Custom Tool Message Content

The `tool_message_content` parameter customizes the message appearing in conversation history:

```python
from pydantic import BaseModel, Field
from typing import Literal
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy

class MeetingAction(BaseModel):
    """Action items extracted from a meeting transcript."""
    task: str = Field(description="The specific task to be completed")
    assignee: str = Field(description="Person responsible for the task")
    priority: Literal["low", "medium", "high"] = Field(description="Priority level")

agent = create_agent(
    model="gpt-5",
    tools=[],
    response_format=ToolStrategy(
        schema=MeetingAction,
        tool_message_content="Action item captured and added to meeting notes!"
    )
)

agent.invoke({
    "messages": [{"role": "user", "content": "From our meeting: Sarah needs to update the project timeline as soon as possible"}]
})
```

Output:

```
================================ Human Message =================================

From our meeting: Sarah needs to update the project timeline as soon as possible
================================== Ai Message ==================================
Tool Calls:
  MeetingAction (call_1)
 Call ID: call_1
  Args:
    task: Update the project timeline
    assignee: Sarah
    priority: high
================================= Tool Message =================================
Name: MeetingAction

Action item captured and added to meeting notes!
```

Without custom content, the default message would display the structured response data.

### Error Handling

Models can make mistakes generating structured output via tool calling. LangChain provides intelligent retry mechanisms.

#### Multiple Structured Outputs Error

When a model incorrectly calls multiple structured output tools, the agent provides error feedback and prompts retry:

```python
from pydantic import BaseModel, Field
from typing import Union
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy

class ContactInfo(BaseModel):
    name: str = Field(description="Person's name")
    email: str = Field(description="Email address")

class EventDetails(BaseModel):
    event_name: str = Field(description="Name of the event")
    date: str = Field(description="Event date")

agent = create_agent(
    model="gpt-5",
    tools=[],
    response_format=ToolStrategy(Union[ContactInfo, EventDetails])
)

agent.invoke({
    "messages": [{"role": "user", "content": "Extract info: John Doe (john@email.com) is organizing Tech Conference on March 15th"}]
})
```

The agent detects the error, sends feedback that "Model incorrectly returned multiple structured responses", and retries until a single response is returned.

#### Schema Validation Error

When structured output doesn't match the expected schema, the agent provides specific error feedback:

```python
from pydantic import BaseModel, Field
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy

class ProductRating(BaseModel):
    rating: int | None = Field(description="Rating from 1-5", ge=1, le=5)
    comment: str = Field(description="Review comment")

agent = create_agent(
    model="gpt-5",
    tools=[],
    response_format=ToolStrategy(ProductRating),
    system_prompt="You are a helpful assistant that parses product reviews. Do not make any field or value up."
)

agent.invoke({
    "messages": [{"role": "user", "content": "Parse this: Amazing product, 10/10!"}]
})
```

The agent detects that rating "10" exceeds the maximum of 5, provides the validation error, and prompts retry.

#### Error Handling Strategies

**Custom Error Message:**

```python
ToolStrategy(
    schema=ProductRating,
    handle_errors="Please provide a valid rating between 1-5 and include a comment."
)
```

**Handle Specific Exceptions:**

```python
ToolStrategy(
    schema=ProductRating,
    handle_errors=ValueError
)
```

**Handle Multiple Exception Types:**

```python
ToolStrategy(
    schema=ProductRating,
    handle_errors=(ValueError, TypeError)
)
```

**Custom Error Handler Function:**

```python
from langchain.agents.structured_output import StructuredOutputValidationError
from langchain.agents.structured_output import MultipleStructuredOutputsError

def custom_error_handler(error: Exception) -> str:
    if isinstance(error, StructuredOutputValidationError):
        return "There was an issue with the format. Try again."
    elif isinstance(error, MultipleStructuredOutputsError):
        return "Multiple structured outputs were returned. Pick the most relevant one."
    else:
        return f"Error: {str(error)}"

agent = create_agent(
    model="gpt-5",
    tools=[],
    response_format=ToolStrategy(
        schema=Union[ContactInfo, EventDetails],
        handle_errors=custom_error_handler
    )
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Extract info: John Doe (john@email.com) is organizing Tech Conference on March 15th"}]
})

for msg in result['messages']:
    if type(msg).__name__ == "ToolMessage":
        print(msg.content)
    elif isinstance(msg, dict) and msg.get('tool_call_id'):
        print(msg['content'])
```

**No Error Handling:**

```python
response_format = ToolStrategy(
    schema=ProductRating,
    handle_errors=False
)
```

When `handle_errors=False`, all exceptions are raised without retry attempts.
