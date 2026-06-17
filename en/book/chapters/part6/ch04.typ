// Auto-generated from 04_prompt_hub.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Prompt Hub", subtitle: "Prompt Version Control")

Prompts are essentially _code_, but they are frequently edited by non-engineers and have short update cycles. To avoid redeploying every time, prompts should be stored in a _repository separate from application code_ and version-pinned. LangSmith Prompt Hub serves this purpose.

== Learning Objectives

- Upload prompts using `client.push_prompt("name", object=...)`
- Understand the difference between pinning to a Commit SHA vs referencing `prod`/`staging` tags
- Compare variable handling between f-string and mustache templates
- Learn the Playground → Commit → Tag workflow
- Inject prompts at runtime with `client.pull_prompt("name:prod")` and connect to `create_agent(system_prompt=...)`
- In CI tests, _pin to a specific commit hash_ to prevent regressions

== Prerequisites

#code-block(`````dotenv
LANGSMITH_API_KEY=lsv2_pt_...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langsmith-prompt-hub
OPENAI_API_KEY=sk-...
`````)

Prompt Hub is separate from tracing, but push/pull calls are also traced, so it's convenient to use the same project name. The SDK requires `langsmith >= 0.1.99`.

#code-block(`````python
# !pip install -U langsmith langchain langchain-openai

from dotenv import load_dotenv
import os
load_dotenv(override=True)

assert os.environ.get("LANGSMITH_API_KEY"), "LANGSMITH_API_KEY not set"
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY not set"
# If the project is not set, LangSmith records to `default`.
os.environ.setdefault("LANGSMITH_PROJECT", "langsmith-prompt-hub")
print("Project:", os.environ["LANGSMITH_PROJECT"])
`````)

== 6.04.1 Creating and Pushing a Prompt

The simplest way is to create a `ChatPromptTemplate` and upload it with `client.push_prompt("name", object=prompt)`. The first push creates a new prompt, and subsequent pushes add new commits. The returned URL opens directly in the UI.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/04_prompt_hub/01_prompt_hub_list.png")

_Prompt list — `city-list` (1 commit) and `weather-bot` (2 commits). The Visibility column shows Private/Public badges, and the Last Commit column displays short SHAs (`e3d8a720`, `054fbccb`). In addition to the `+ Prompt` button at the top, there is a `+ Webhook` option (to trigger a webhook on prompt changes)._

#code-block(`````python
from langsmith import Client
from langchain_core.prompts import ChatPromptTemplate

client = Client()

weather_prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a friendly weather bot. Please answer concisely in one sentence."),
    ("human", "Tell me the weather in {city}"),
])

url = client.push_prompt("weather-bot", object=weather_prompt)
print("Push complete ->", url)
`````)

== 6.04.2 Commit SHA Pinning vs Tags (`prod`, `staging`)

Prompts work like Git.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Reference Type],
  text(weight: "bold")[Example],
  text(weight: "bold")[Characteristics],
  text(weight: "bold")[When to Use],
  [_Commit SHA_],
  [`weather-bot:12344e88`],
  [Immutable, pins exactly that version],
  [CI regression tests, when reproducibility is needed],
  [_Tag_],
  [`weather-bot:prod`, `weather-bot:staging`],
  [Movable — the same tag can point to different commits],
  [Runtime deployment slots],
  [_Latest_],
  [`weather-bot`],
  [Most recent commit],
  [Only in early development, not for production],
)

Tags are a key mechanism for swapping prompts without redeploying application code. In the UI's `Commits` view, you can _promote_ a specific commit to the `prod` tag.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/04_prompt_hub/02_prompt_detail.png")

_`weather-bot` details. Top shows commit `054fbccb` + tabs (Messages / Code Snippet / Comments). Messages tab shows System/User templates (with `{city}` variable), Code Snippet tab shows a Python SDK example `client.pull_prompt("weather-bot")`. The left Environments panel has Production/Staging slots with `Promote` tagging. Top right has Permissions/Fork/Playground buttons._

#code-block(`````python
# Extract the commit hash from the returned URL, excluding the query string
from urllib.parse import urlparse

commit_hash = urlparse(url).path.rstrip("/").split("/")[-1]  # e.g., '12344e88'
print("Commit to pin:", commit_hash)

# Modify the same prompt again to create a new commit
weather_prompt_v2 = ChatPromptTemplate.from_messages([
    ("system", "You are a friendly weather bot. Answer in Korean in one sentence. Add an emoji if needed."),
    ("human", "Tell me the weather in {city}"),
])
url_v2 = client.push_prompt("weather-bot", object=weather_prompt_v2)
print("v2 push ->", url_v2)
print("-> In the UI, try tagging the v1 commit as prod and the v2 commit as staging")
`````)

== 6.04.3 f-string vs mustache

The characteristics of these two template engines often matter in practice.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[f-string (`{var}`)],
  text(weight: "bold")[mustache (`{{var}}`)],
  [Default],
  [✅ LangChain default],
  [Separate selection],
  [Including JSON examples],
  [Need to escape `{{`],
  [No need to escape],
  [Conditionals/Loops],
  [❌ Not supported],
  [✅ `{{\#users}}...{{/users}}`],
  [Nested keys],
  [Limited],
  [✅ `{{user.name}}`],
  [Playground variable detection],
  [Auto-detected],
  [Manual (Inputs)],
)

If you need to include lots of JSON/code examples or use loops/conditionals, mustache is better. For simple variable substitution, f-string is more convenient.

#code-block(`````python
# Example of mustache template — template_format="mustache"
mustache_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", "Introduce the list of cities in Korean, one per line."),
        ("human", "{{#cities}}- {{name}} ({{country}})\n{{/cities}}"),
    ],
    template_format="mustache",
)

client.push_prompt("city-list", object=mustache_prompt)
# Bind the repeat variable as a list
print(mustache_prompt.invoke({"cities": [
    {"name": "Seoul", "country": "KR"},
    {"name": "Tokyo", "country": "JP"},
]}).to_messages()[-1].content)
`````)

== 6.04.4 Playground — From Experiment to Commit

The UI _Playground_ is a space to try out prompts, models, and input variables together. The workflow:

+ Click `Open in Playground` on the prompt page
+ Adjust model, temperature, output schema, and tools in the side panel
+ Enter variable values and click `Run` — results and token/cost are immediately recorded
+ Use `Compare` to _compare outputs from multiple prompts/models in parallel_ for the same input (manual pairwise)
+ When satisfied, click `Save as...` to create a new commit, and promote to `prod` tag if needed

All runs executed in Playground are sent to the Experiments view and can be directly linked to datasets from `03_datasets_and_evaluation`.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/04_prompt_hub/03_playground.png")

_Playground — prompt loaded, editing SYSTEM/HUMAN messages + entering `{question}` variable + generating Output. Default model is `gpt-5.4`, with options for + Message / + Output Schema / + Tool / f-string↔mustache switcher. The `Set up Evaluation` button allows you to attach a dataset and expand into an experiment._

== 6.04.5 Runtime Injection — `pull_prompt` -\\> `create_agent`

In applications, you pull the deployment slot tag with `pull_prompt` and _plug it directly into the LLM/agent_. When you update the prompt, the change is reflected in the next request without redeployment.

#code-block(`````python
from langchain_openai import ChatOpenAI

# 1) Pull the prompt by tag — in production, use the :prod tag
prompt = client.pull_prompt("weather-bot")  # For production: "weather-bot:prod"

# 2) Connect directly to the model and chain
model = ChatOpenAI(model="gpt-5.4")
chain = prompt | model
result = chain.invoke({"city": "Seoul"})
print(result.content)
`````)

#code-block(`````python
# When plugging into an agent as system_prompt, extract only the system message text
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def get_weather(city: str) -> str:
    """Returns the current weather for a city."""
    return f"{city}: Clear, 21°C"

system_text = prompt.messages[0].prompt.template  # The raw template of the 'system' message
agent = create_agent(
    model="openai:gpt-5.4",
    tools=[get_weather],
    system_prompt=system_text,      # Inject the latest system prompt from Prompt Hub
)

out = agent.invoke({"messages": [{"role": "user", "content": "What's the weather in Busan?"}]})
print(out["messages"][-1].content)
`````)

=== Public hub + `LangSmithUserError` Exception Handling

Names with an _author handle_ like `hwchase17/rag-prompt` are public prompts from the LangChain Hub. If you pull without a handle, it only searches your own workspace. If you request a non-existent prompt/tag/SHA with `pull_prompt`, a `langsmith.utils.LangSmithUserError` is raised, so you should wrap fallback logic.

#code-block(`````python
from langsmith.utils import LangSmithUserError, LangSmithNotFoundError

# 1) Public hub prompt — 'author/name' format
# Public prompts may include serialized objects, so only enable the explicit flag if you trust the source.
try:
    public_prompt = client.pull_prompt(
        "hwchase17/rag-prompt",
        dangerously_pull_public_prompt=True,
    )
    print("public prompt messages:", len(public_prompt.messages))
except (LangSmithUserError, LangSmithNotFoundError, ValueError) as e:
    print(f"Failed to fetch public prompt — check handle/name: {e}")

# 2) Fallback to latest commit if :prod tag does not exist
def safe_pull(name: str, tag: str = "prod"):
    try:
        return client.pull_prompt(f"{name}:{tag}")
    except (LangSmithUserError, LangSmithNotFoundError):
        # Tag does not exist → fallback to latest main commit
        return client.pull_prompt(name)

prod_or_latest = safe_pull("weather-bot", tag="prod")
print("safe_pull succeeded:", type(prod_or_latest).__name__)
`````)

== 6.04.6 Pinning to a Specific Commit Hash in CI

For production deployment slots, use the `:prod` tag, but _for regression tests, always pin to a commit SHA_. This ensures that "someone changed the prompt after the tests passed" is automatically prevented.

#code-block(`````python
# Inject the pinned version via environment variable — set PROMPT_PIN in CI
PROMPT_PIN = os.environ.get("WEATHER_BOT_PIN", commit_hash)
pinned = client.pull_prompt(f"weather-bot:{PROMPT_PIN}")

# CI test example: does the pinned prompt include the expected string?
rendered = pinned.invoke({"city": "Seoul"}).to_messages()[0].content
assert "weather bot" in rendered, "system prompt does not match expectations — check prompt commit"
print(f"CI passed (pin: weather-bot:{PROMPT_PIN})")
`````)

=== Deployment Pattern Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Environment],
  text(weight: "bold")[Reference],
  text(weight: "bold")[Reason],
  [dev / local],
  [`weather-bot` (latest)],
  [Immediate reflection],
  [staging],
  [`weather-bot:staging`],
  [Test by promoting only the tag],
  [prod],
  [`weather-bot:prod`],
  [Zero-downtime rollout by moving the tag, rollback by reverting the tag],
  [CI],
  [`weather-bot:{SHA}`],
  [Reproducible, prompt changes immediately cause test failures],
)

If you add `prompt_commit` as metadata in the experiment of `03_datasets_and_evaluation`, you can _track exactly which commit the metrics are based on_ directly in the UI.

== Checklist

- [ ] Create a new commit with `client.push_prompt("name", object=prompt)`
- [ ] Promote `prod` / `staging` tags to commits in the UI's Commits view
- [ ] Understand when to use f-string vs mustache (loops/conditionals/nesting → mustache)
- [ ] Experience the Playground → Save → Tag promote workflow
- [ ] Inject at runtime with `client.pull_prompt("name:prod")`
- [ ] Use public hub prompts with `client.pull_prompt("author/name")`
- [ ] Fallback for `langsmith.utils.LangSmithUserError` / `LangSmithNotFoundError`
- [ ] Regression test in CI with `name:{SHA}` pin

== Next

- `05_production_monitoring.ipynb` — Wrap production agents using deployed prompts with dashboards, alerts, and PII protection

== References

- Prompt engineering concepts: https://docs.langchain.com/langsmith/prompt-engineering-concepts
- Manage prompts programmatically: https://docs.langchain.com/langsmith/manage-prompts-programmatically
- Playground: https://docs.langchain.com/langsmith/playground
