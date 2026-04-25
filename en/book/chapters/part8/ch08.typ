// Source: 08_integration/11_provider_middleware/07_openai_moderation.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "OpenAI Moderation", subtitle: "Pre- / post-block policy-violating content")

`OpenAIModerationMiddleware` uses the OpenAI Moderation API to scan _user input · model output · tool results_ automatically and, when a policy violation is detected, blocks, replaces, or raises an exception on the conversation. Use it to preemptively filter categories like hate, violence, or self-harm for a public chatbot, and to stop second-order contamination from external tool results.

#learning-header()
#learning-objectives(
  [Understand the meaning and cost/latency tradeoff of the three scan points `check_input` / `check_output` / `check_tool_results`],
  [Distinguish the three `exit_behavior` modes: `"end"` / `"error"` / `"replace"`],
  [Polish user-facing responses via a custom `violation_message` template],
  [Inject a pre-configured OpenAI client via `client` / `async_client`],
)

== 8.1 When to use it

- Public chatbots that need to preempt Moderation categories such as _hate / violence / self-harm_
- Preventing harmful content in tool outputs (web search, email bodies) from reaching the model
- Leaving _violation metadata_ in the response flow for audit / reporting

== 8.2 Environment setup

Required packages: `langchain`, `langchain-openai`. `OPENAI_API_KEY` in `.env`.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_openai.middleware import OpenAIModerationMiddleware

load_dotenv()
`````)

== 8.3 Basic usage — scan both input and output, end on violation

Defaults are `check_input=True`, `check_output=True`, `exit_behavior="end"`. If user input trips the Moderation API, the model call is skipped entirely and _the conversation ends with a violation message_.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Default],
  text(weight: "bold")[Description],
  [`model`],
  [`"omni-moderation-latest"`],
  [Moderation model to use],
  [`check_input`],
  [`True`],
  [Scan user messages before passing to the model],
  [`check_output`],
  [`True`],
  [Scan model-generated responses before returning to the user],
  [`check_tool_results`],
  [`False`],
  [Scan tool-execution results before they enter the model],
  [`exit_behavior`],
  [`"end"`],
  [`"end"` / `"error"` / `"replace"`],
  [`violation_message`],
  [default template],
  [The text shown to the user on violation],
  [`client` / `async_client`],
  [`None`],
  [Inject a pre-configured OpenAI client (optional)],
)

#code-block(`````python
agent = create_agent(
    model="openai:gpt-4.1",
    tools=[],
    middleware=[OpenAIModerationMiddleware()],
)
`````)

== 8.4 `exit_behavior="end"` — end immediately on violating input

When a harmful category is detected (for example self-harm encouragement), the flow ends with the violation message — no model call. The final message on the response contains the default violation text.

== 8.5 `exit_behavior="error"` — fail loudly

Use this in testing / batch environments where you would rather _not let the violation slip by silently_. It raises `OpenAIModerationError` so the upstream pipeline can catch it and write to the audit log.

#code-block(`````python
from langchain_openai.middleware import OpenAIModerationError

agent = create_agent(
    model="openai:gpt-4.1",
    tools=[],
    middleware=[OpenAIModerationMiddleware(exit_behavior="error")],
)

try:
    agent.invoke({"messages": [{"role": "user", "content": "..."}]})
except OpenAIModerationError as e:
    # Record in the audit log
    print("Moderation violation:", e.categories)
`````)

== 8.6 `exit_behavior="replace"` — swap the message and keep going

When output scanning catches a violation, _only that response_ is swapped out for the violation message and the graph keeps running. Useful in multi-turn conversations where you want to _tidy up a specific response_ without ending the whole conversation.

#code-block(`````python
agent = create_agent(
    model="openai:gpt-4.1",
    tools=[],
    middleware=[
        OpenAIModerationMiddleware(
            exit_behavior="replace",
            violation_message=(
                "This response cannot be shown under our safety policy "
                "(categories: {categories}). Please try a different question."
            ),
        ),
    ],
)
`````)

`violation_message` is a template string that supports the `{categories}`, `{category_scores}`, and `{original_content}` variables.

== 8.7 Scanning tool results (`check_tool_results=True`)

Prevents _harmful content authored by third parties_ in web search, crawling, or DB query tool results from flowing unchanged into the model. Cost scales with the number of tool calls, so only turn this on in pipelines that touch _untrusted external sources_.

#code-block(`````python
agent = create_agent(
    model="openai:gpt-4.1",
    tools=[web_search_tool, fetch_url_tool],
    middleware=[
        OpenAIModerationMiddleware(
            check_input=True,
            check_output=True,
            check_tool_results=True,
        ),
    ],
)
`````)

== 8.8 Cost / latency tradeoff

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Setting],
  text(weight: "bold")[Cost],
  text(weight: "bold")[Latency],
  text(weight: "bold")[Main effect],
  [`check_input=True`],
  [Mod 1 + Model 1],
  [+1 RT],
  [Block harmful input before it reaches the model],
  [`check_output=True`],
  [Model 1 + Mod 1],
  [+1 RT],
  [Protect the end user when the model produced a bad response],
  [`check_tool_results=True`],
  [\# of tools × Mod],
  [+1 per tool],
  [Block externally contaminated data],
)

#tip-box[*Practical guidance*: In production it is common to always keep `check_input` on, run `check_output` under a sampling strategy (e.g., 10%), and limit `check_tool_results` to untrusted external sources.]

== Key Takeaways

- Pick the three scan points on a cost/latency tradeoff: input always on, output sampled, tool_results conditional
- `exit_behavior` picks between ending the conversation (`end`), raising immediately (`error`), or swapping the message (`replace`)
- `violation_message` templating produces user-friendly guidance
- Reuse a pre-configured OpenAI client via `client` / `async_client` to save initialization cost
