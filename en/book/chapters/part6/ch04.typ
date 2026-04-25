// Source: 06_langsmith/04_prompt_hub.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Prompt Hub Versioning", subtitle: "Commit SHA · Tag · Playground")

Prompts are effectively _code_, yet non-engineers often edit them and the cadence is tight. Avoiding redeploy on every tweak means keeping prompts in _storage decoupled from the application code_ and pinning versions. LangSmith's Prompt Hub plays that role. This chapter covers the push/pull API, commit SHA vs tag, template-engine choices, Playground experiments, and a CI pin strategy.

#learning-header()
#learning-objectives(
  [Upload a prompt with `client.push_prompt("name", object=...)`],
  [Understand the difference between pinning a commit SHA and referencing a tag like `prod` / `staging`],
  [Compare the variable handling of f-string vs mustache templates],
  [Follow the Playground → experiment → commit → tag flow],
  [Inject prompts at runtime via `client.pull_prompt("name:prod")`],
  [Pin a specific commit hash in CI tests to prevent regression],
)

== 4.1 Creating and pushing a prompt

The simplest flow is to build a `ChatPromptTemplate` and upload it with `client.push_prompt("name", object=prompt)`. The first push creates a new prompt; subsequent pushes add commits. The returned URL opens the prompt directly in the UI.

#code-block(`````python
from langchain_core.prompts import ChatPromptTemplate
from langsmith import Client

client = Client()
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a weather assistant. Extract only the city name."),
    ("user", "{question}"),
])

url = client.push_prompt("weather-bot", object=prompt)
print(url)  # https://smith.langchain.com/hub/...
`````)

#figure(image("../../../../assets/images/langsmith/04_prompt_hub/01_prompt_hub_list.png", width: 95%), caption: [Prompts hub listing — `city-list` (1 commit), `weather-bot` (2 commits). Visibility and short-SHA Last Commit shown])

== 4.2 Commit SHA pinning vs tags (`prod`, `staging`)

Prompts behave like Git.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Reference style],
  text(weight: "bold")[Example],
  text(weight: "bold")[Characteristic],
  text(weight: "bold")[When to use],
  [*Commit SHA*],
  [`weather-bot:12344e88`],
  [Immutable, pins exactly that version],
  [CI regression tests, any time reproducibility is required],
  [*Tag*],
  [`weather-bot:prod`, `:staging`],
  [Movable — can be repointed at a different commit],
  [Runtime deployment slots],
  [*Latest*],
  [`weather-bot`],
  [The most recent commit],
  [Early development only; never in production],
)

Tags are the mechanism that lets you swap a prompt without redeploying application code. In the UI's Commits view, *promote* a specific commit to the `prod` tag.

#figure(image("../../../../assets/images/langsmith/04_prompt_hub/02_prompt_detail.png", width: 95%), caption: [Prompt detail — top commit + tabs (Messages / Code Snippet / Comments) with Production / Staging slots on the Environments panel])

== 4.3 f-string vs mustache

The characteristics of the two template engines often matter in practice.

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
  [LangChain default],
  [Opt-in],
  [Embedded JSON examples],
  [Need `{{` escaping],
  [No escaping needed],
  [Conditionals · loops],
  [Not supported],
  [`{{#users}}...{{/users}}`],
  [Nested keys],
  [Limited],
  [`{{user.name}}`],
  [Playground variable declaration],
  [Auto-detected],
  [Manual (Inputs)],
)

Mustache is easier when you embed a lot of JSON / code examples or need loops / conditionals; f-string is easier for plain variable substitution.

== 4.4 Playground — from experiment to commit

The UI's *Playground* is where prompts, models, and input variables run together. Flow:

+ Click `Open in Playground` on the prompt page
+ Adjust model · temperature · output schema · tools in the side panel
+ Enter variable values and hit `Run` — results and token/cost are recorded immediately
+ Use `Compare` to run _multiple prompt/model outputs in parallel_ for the same input
+ Once satisfied, `Save as...` creates a new commit; promote to `prod` if appropriate

All runs started from Playground flow into the Experiments view and connect directly to the datasets from chapter 3.

#figure(image("../../../../assets/images/langsmith/04_prompt_hub/03_playground.png", width: 95%), caption: [Playground — SYSTEM/HUMAN message editing, `{question}` variable input, and output generation with an f-string↔mustache switcher])

== 4.5 Runtime injection — `pull_prompt` → `create_agent`

In the application, fetch the deployment-slot tag with `pull_prompt` and _wire it straight into the LLM / agent_. Editing the prompt takes effect on the next request without redeployment.

#code-block(`````python
from langchain.agents import create_agent

prompt = client.pull_prompt("weather-bot:prod")

agent = create_agent(
    model="openai:gpt-4.1",
    system_prompt=prompt.format_messages()[0].content,
    tools=[],
)
`````)

== 4.6 Pinning a specific commit hash in CI

Take the production deployment slot via the `:prod` tag, but _CI regression tests must pin a commit SHA_. That way, "someone changed the prompt after the tests passed" is auto-blocked.

#code-block(`````python
# tests/test_prompt_regression.py
PINNED_SHA = "12344e88"  # CI pin

def test_weather_prompt_still_extracts_city():
    prompt = client.pull_prompt(f"weather-bot:{PINNED_SHA}")
    # ... concrete assertions
`````)

=== Deployment-pattern summary

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
  [Promote a tag to test],
  [prod],
  [`weather-bot:prod`],
  [Zero-downtime rollout by moving the tag; rollback is reverting the tag],
  [CI],
  [`weather-bot:{SHA}`],
  [Reproducible; a prompt change immediately shows up as a test failure],
)

When you attach `prompt_commit` as experiment metadata in chapter 3, the UI can trace _which commit produced these numbers_ directly.

== Key Takeaways

- Prompt Hub works as push → commit accumulation → tag promotion (similar to Git)
- Tags are runtime deployment slots; SHAs are CI reproducibility pins
- Pick f-string vs mustache based on loops / conditionals / nesting
- Playground → Save → promote is the editing path for non-developers
- Pin SHAs in CI and reference tags in production — that combination is the core of zero-downtime rollout + regression prevention
