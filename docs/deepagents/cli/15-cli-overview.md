# Deep Agents Code (`dcode`)

## Overview

Deep Agents Code는 Deep Agents SDK 위에 만든 오픈소스 터미널 코딩 에이전트다. 예전 `deepagents-cli` 문서의 대화형 코딩 에이전트 역할은 최신 문서에서 **Deep Agents Code**와 `dcode` 명령으로 정리되었다. `deepagents-cli` 패키지는 별도 deployment tooling 성격이므로, 코딩 에이전트 실습에서는 `dcode`를 기준으로 설명한다.

## Installation & Setup

공식 설치 스크립트:

```bash
curl -LsSf https://langch.in/dcode | bash
```

PyPI/uv 기반으로 실험할 때는 `deepagents-code` 패키지가 `dcode` 콘솔 스크립트를 제공한다.

```bash
uvx --from deepagents-code dcode --help
```

OpenAI, Anthropic, Gemini 등 provider credential은 `/auth` 명령 또는 `~/.deepagents/.env`로 설정한다. Tavily 웹 검색은 `TAVILY_API_KEY`가 있을 때 사용할 수 있다.

## Key Capabilities

- 파일 작업: `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`
- 셸 실행: allowlist 또는 sandbox 정책으로 제어
- 웹 검색과 URL fetch
- `write_todos` 기반 작업 계획
- AGENTS.md 메모리와 SKILL.md 스킬
- MCP 서버 도구 로딩
- Deep Agents subagent 위임
- 원격 sandbox 실행(LangSmith 기본, AgentCore/Modal/Daytona/Runloop/Vercel은 extra 필요)
- 선택적 QuickJS interpreter와 PTC allowlist

## Command-line Options

| 옵션 | 설명 |
|------|------|
| `-a/--agent NAME` | 사용할 agent profile 선택 |
| `-M/--model MODEL` | 모델 선택 (`openai:gpt-5.5`, `anthropic:...` 등) |
| `-m/--message TEXT` | 세션 시작 시 자동 제출할 첫 메시지 |
| `-n/--non-interactive MSG` | 단일 태스크 실행 후 종료 |
| `-q/--quiet` | 비대화형 출력 정리 |
| `-y/--auto-approve` | 도구 호출 자동 승인 |
| `--sandbox TYPE` | 원격 sandbox 선택 |
| `--interpreter` | JS interpreter 활성화 |
| `--interpreter-tools VALUE` | PTC allowlist (`safe`, `all`, comma-separated) |
| `--mcp-config PATH` | MCP 설정 파일 추가 로딩 |
| `--skill NAME` | 시작 시 skill 호출 |
| `--startup-cmd CMD` | 첫 prompt 전 shell command 실행 |
| `--max-turns N` | 비대화형 agentic turn 한도 |
| `--timeout SECONDS` | 비대화형 hard timeout |
| `--stdin` | 표준 입력에서 prompt 읽기 |
| `--json` | 명령 출력 JSON 형식 |
| `-S/--shell-allow-list CMDS` | 허용할 shell command 지정 (`recommended`, `all`, comma-separated) |
| `--acp` | ACP server over stdio로 실행 |

## Interactive Commands

| 명령 | 설명 |
|------|------|
| `/auth` | provider credential 연결·상태 확인 |
| `/model` | 모델 변경 |
| `/install` | optional extra 설치 |
| `/remember` | memory에 convention 저장 |
| `/tokens` | 토큰 사용량 확인 |
| `!command` | shell command 실행 |

## Non-interactive Examples

```bash
# 단일 태스크 실행 — 로컬 셸 접근 없음
dcode -n 'README.md를 요약해줘'

# 안전 command allowlist 사용
dcode -n '테스트 로그를 확인해줘' -S recommended

# 명시 allowlist
dcode -n '문서에서 RubricMiddleware 언급을 찾아줘' -S ls,cat,grep

# stdin으로 prompt 주입
cat PROMPT.md | dcode --stdin -q

# skill을 명시해 시작
dcode --skill code-review -m '이 patch를 리뷰해줘'
```

## Configuration and Data Locations

Deep Agents Code는 두 계층의 디렉터리를 사용한다.

| 위치 | 역할 |
|------|------|
| `~/.deepagents/` | agent별 memory, sessions, provider config, hooks, MCP |
| `~/.agents/` | 여러 AI CLI가 공유할 수 있는 tool-agnostic skills |
| `{project}/AGENTS.md` | 프로젝트 루트 instructions |
| `{project}/.deepagents/AGENTS.md` | 프로젝트별 Deep Agents Code instructions |
| `{project}/.deepagents/skills/` | 프로젝트별 skills |
| `{project}/.deepagents/agents/` | 프로젝트별 custom subagents |

주요 config 파일:

| 파일 | 역할 |
|------|------|
| `~/.deepagents/config.toml` | 모델 기본값, provider 설정, profile override, theme |
| `~/.deepagents/.env` | API key와 secrets |
| `~/.deepagents/hooks.json` | lifecycle event hook |
| `~/.deepagents/.mcp.json` | global MCP server definitions |

`dcode config show`, `dcode config list`, `dcode config path`로 현재 적용 설정과 출처를 확인한다.

## Skills and Subagents

Skills는 `SKILL.md`로 정의되며 필요할 때만 읽힌다.

```bash
dcode skills list
dcode skills create my-skill
dcode skills info my-skill
```

Custom subagent는 project 또는 user scope의 `AGENTS.md` 파일로 정의한다.

```text
.deepagents/agents/{subagent-name}/AGENTS.md
~/.deepagents/{agent}/agents/{subagent-name}/AGENTS.md
```

YAML frontmatter에는 `name`, `description`이 필요하고, 선택적으로 `model`을 지정할 수 있다. Deep Agents Code의 AGENTS.md subagent는 현재 sync subagent이며, 전체 SDK의 `tools`, `middleware`, `interrupt_on`, `skills` 세부 필드를 모두 노출하지는 않는다.
