# -*- coding: utf-8 -*-
"""05_advanced — 슬라이드 콘텐츠.

Portable editable source normalized on 2026-10-11 so SLIDES is literal final content.
Do not reintroduce runtime overlay functions that hide stale base snippets.
"""
BRAND = '© 주식회사 똑똑한청년들 · 배움 에이아이'
SLIDES = [{'type': 'cover',
  'eyebrow': 'ADVANCED TRACK',
  'title': 'AI 에이전트 개발 고급',
  'tagline': 'LangChain · LangGraph · Deep Agents',
  'credit': '주식회사 똑똑한청년들 · 배움 에이아이'},
 {'type': 'divider',
  'kicker': 'PART 01',
  'title': '오리엔테이션',
  'sub': 'LangChain 기초, LangGraph 심화, Deep Agents 실전 위에 미들웨어·멀티에이전트·메모리·RAG·SQL·데이터 분석·음성·프로덕션을 얹습니다.',
  'lab': None},
 {'type': 'statement',
  'course': 'AI 에이전트 개발 고급',
  'meta': '01 / 오리엔테이션',
  'title': '고급 트랙은 에이전트를 기능 구현에서 운영 가능한 시스템으로 끌어올립니다',
  'lead': '목표는 새로운 API를 많이 아는 것이 아니라 실패·권한·상태·평가를 설계할 수 있게 되는 것입니다',
  'big': 'Middleware · Multi-agent · Context/Memory · Agentic RAG · SQL/Data/Voice · Production',
  'note': '이 덱은 고급 트랙 노트북 10개를 따라가는 학습 안내서입니다.'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '01 / 오리엔테이션',
  'title': '05_advanced는 10개 노트북으로 고급 운영 패턴을 묶습니다',
  'lead': '각 노트북은 하나의 운영 문제를 다룹니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['마이그레이션', 'v1 패키지·API·상태 스키마 전환', '기존 코드를 최신 구조로 옮깁니다'],
           ['미들웨어', '6단계 훅과 wrap_model/tool_call', '실행 경계를 제어합니다'],
           ['멀티에이전트', 'Subagents, Handoffs, Router', '작업 분리와 상태 전환을 설계합니다'],
           ['컨텍스트/메모리', 'runtime context, Store, semantic memory', '정보 수명을 분리합니다'],
           ['응용 에이전트', 'RAG, SQL, 데이터 분석, 음성', '현업 데이터 작업으로 확장합니다'],
           ['프로덕션', '테스트, 평가, 배포, 관측성', '출시 기준을 세웁니다']]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': '01 / 오리엔테이션',
  'title': '고급 트랙의 공통 축은 실행 흐름을 제어하고 상태를 회수 가능하게 만드는 것입니다',
  'lead': '모든 노트북은 모델 답변이 아니라 실행 경계와 운영 루프를 설명합니다',
  'img_src': 'assets/diagrams/deepagents_architecture.png',
  'cap': 'advanced architecture map',
  'points': [{'h': 'Control', 'p': '미들웨어와 그래프로 실행 흐름을 제어합니다.'},
             {'h': 'State', 'p': '체크포인터, Store, runtime context로 정보를 나눕니다.'},
             {'h': 'Evaluation', 'p': '테스트와 평가로 출시 기준을 검증합니다.'}]},
 {'type': 'divider',
  'kicker': 'PART 02',
  'title': 'v1 마이그레이션',
  'sub': '레거시 LangChain 코드를 v1 패키지 구조, create_agent, TypedDict state, runtime context, middleware 방식으로 옮깁니다.',
  'lab': '05_advanced/00_migration.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '02 / 마이그레이션',
  'title': '마이그레이션 실습은 import, agent 생성, state, middleware를 순서대로 검증합니다',
  'lead': '한 번에 전부 바꾸지 말고 실행 표면별로 통과 여부를 확인합니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['import', 'langchain-classic 의존 위치 확인', 'deprecated 경로가 남지 않습니다'],
           ['agent 생성', 'create_agent로 모델·도구 연결', '기존 질문이 같은 도구를 호출합니다'],
           ['state', 'TypedDict 기반 상태 정리', '그래프와 타입 오류가 없습니다'],
           ['middleware', '동적 프롬프트와 오류 처리 이동', '실패 케이스가 ToolMessage 등으로 복구됩니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '02 / 마이그레이션',
  'title': '마이그레이션 리스크는 조용한 행동 변화에서 발생합니다',
  'lead': '코드가 실행돼도 도구 순서나 출력 계약이 바뀌면 운영 회귀입니다',
  'groups': [{'t': '주의할 회귀',
              'kids': [{'t': '도구 호출 이름이 바뀌어 기존 평가가 실패합니다'},
                       {'t': 'context 전달 위치가 바뀌어 사용자 권한이 누락됩니다'},
                       {'t': 'Pydantic state를 그대로 두어 LangGraph 호환성이 떨어집니다'}]},
             {'t': '완료 기준', 'kids': [{'t': '대표 질문 세트가 이전과 같은 행동을 보입니다'}, {'t': 'trace에서 도구 호출과 오류 처리가 확인됩니다'}]}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '02 / 마이그레이션',
  'title': '마이그레이션은 import 변경보다 실행 모델 변경을 먼저 봐야 합니다',
  'lead': '패키지 이름만 바꾸면 코드가 돌아가도 운영 기능을 놓칠 수 있습니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['패키지', 'langchain-classic 분리', '레거시 chain/agent 경로를 확인합니다'],
           ['Agent API', 'create_react_agent 중심에서 create_agent 중심으로 이동', '도구·모델·미들웨어 결합 표면이 바뀝니다'],
           ['State', 'Pydantic state보다 TypedDict state를 사용', 'LangGraph 호환성을 확보합니다'],
           ['Runtime context', 'config가 아니라 context_schema로 런타임 정보를 주입', '도구와 미들웨어가 같은 정보를 읽습니다'],
           ['Middleware', '동적 프롬프트와 도구 오류 처리를 훅으로 이동', '프롬프트 분기와 예외 처리를 구조화합니다']]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '02 / 마이그레이션',
  'title': 'create_agent는 모델·도구·미들웨어를 한 실행 표면에서 묶습니다',
  'lead': '고급 트랙에서는 create_agent를 기본 조립 단위로 보고 LangGraph/Deep Agents로 확장합니다',
  'points': [{'h': 'model', 'p': '모델 객체 또는 모델 문자열을 전달합니다.'},
             {'h': 'tools', 'p': '도구는 함수 또는 Tool 객체로 연결합니다.'},
             {'h': 'middleware', 'p': '동적 프롬프트, HITL, 오류 처리 등을 삽입합니다.'}],
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'agent = create_agent(\n'
          '    model="openai:gpt-5.4-mini",\n'
          '    tools=[search_tool, calculator],\n'
          '    middleware=[dynamic_prompt_middleware],\n'
          ')\n'
          '\n'
          'result = agent.invoke({\n'
          '    "messages": [{"role": "user", "content": "분석해줘"}]\n'
          '})',
  'file': '00_migration.ipynb',
  'note': 'create_agent'},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '02 / 마이그레이션',
  'title': '마이그레이션 검수는 동작 여부보다 의미 보존 여부를 봐야 합니다',
  'lead': '기존 코드가 실행되는 것과 기존 권한·상태·출력 계약이 유지되는 것은 다릅니다',
  'groups': [{'t': '코드 검수',
              'kids': [{'t': 'import 경로와 deprecated API를 확인합니다'},
                       {'t': 'state schema가 TypedDict 기준으로 정리됐는지 봅니다'},
                       {'t': 'configurable 값이 context_schema로 옮겨졌는지 봅니다'}]},
             {'t': '행동 검수',
              'kids': [{'t': '도구 호출 순서가 유지되는지 확인합니다'},
                       {'t': '오류 처리와 재시도 정책이 middleware로 이동했는지 봅니다'},
                       {'t': '테스트 질문에서 이전 답변 계약이 유지되는지 검증합니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 03',
  'title': '미들웨어',
  'sub': '모델 호출 전후, 도구 호출 전후, 에이전트 전후 훅으로 실행 흐름을 제어합니다.',
  'lab': '05_advanced/01_middleware.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '03 / 미들웨어',
  'title': '미들웨어 실습은 훅 위치와 반환 타입을 함께 확인해야 합니다',
  'lead': '훅은 실행 위치에 따라 허용되는 입력과 반환이 다릅니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['before_agent', '입력 검증과 초기 상태', '차단 또는 상태 업데이트가 명확합니다'],
           ['wrap_model_call', '모델 호출 감싸기', 'handler 호출 전후 정책이 분리됩니다'],
           ['wrap_tool_call', '도구 오류와 권한', 'ToolMessage 또는 Command 처리가 맞습니다'],
           ['after_agent', '최종 응답 검사', '로그와 평가 정보가 남습니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '03 / 미들웨어',
  'title': '미들웨어 리스크는 너무 많은 정책을 한 훅에 넣을 때 커집니다',
  'lead': '정책을 섞으면 실패 원인과 테스트 범위가 불분명해집니다',
  'groups': [{'t': '분리 원칙',
              'kids': [{'t': '입력 차단은 before_agent에 둡니다'},
                       {'t': '모델 선택은 wrap_model_call에 둡니다'},
                       {'t': '도구 오류 복구는 wrap_tool_call에 둡니다'}]},
             {'t': '테스트 기준', 'kids': [{'t': '허용 케이스와 차단 케이스를 모두 둡니다'}, {'t': '예외가 사용자에게 그대로 노출되지 않아야 합니다'}]}]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': '03 / 미들웨어',
  'title': '미들웨어는 에이전트 실행 파이프라인의 각 지점에 정책을 삽입합니다',
  'lead': '고급 에이전트는 프롬프트보다 미들웨어로 운영 정책을 관리하는 경우가 많습니다',
  'img_src': 'assets/diagrams/middleware_pipeline.png',
  'cap': 'middleware pipeline',
  'points': [{'h': 'before_agent', 'p': '입력 검증과 초기 컨텍스트 조립을 수행합니다.'},
             {'h': 'wrap_model_call', 'p': '모델 호출을 감싸 모델·프롬프트·응답을 제어합니다.'},
             {'h': 'wrap_tool_call', 'p': '도구 오류, 재시도, 권한 확인을 처리합니다.'}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '03 / 미들웨어',
  'title': '6단계 훅은 정책을 어디에 넣을지 정하는 지도입니다',
  'lead': '같은 정책도 위치가 다르면 의미가 달라집니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['before_agent', '에이전트 실행 전', '입력 검증, PII 차단'],
           ['before_model', '모델 호출 전', '동적 프롬프트, 컨텍스트 압축'],
           ['wrap_model_call', '모델 호출 감싸기', '모델 라우팅, fallback, 비용 제어'],
           ['wrap_tool_call', '도구 호출 감싸기', '권한, 오류 복구, 재시도'],
           ['after_model', '모델 응답 후', '출력 검사, 도구 호출 정책 확인'],
           ['after_agent', '최종 응답 후', '감사 로그, 결과 검증']]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '03 / 미들웨어',
  'title': 'wrap_tool_call은 도구 오류를 모델이 읽을 수 있는 관측값으로 바꿉니다',
  'lead': '예외를 그대로 터뜨리면 대화가 끊기지만 ToolMessage로 바꾸면 에이전트가 복구할 수 있습니다',
  'points': [{'h': 'request', 'p': '도구 호출 이름과 인자를 포함합니다.'},
             {'h': 'handler', 'p': '실제 도구 실행을 호출합니다.'},
             {'h': 'ToolMessage', 'p': '오류를 도구 관측값으로 반환합니다.'}],
  'code': 'from langchain.agents.middleware import wrap_tool_call\n'
          'from langchain.messages import ToolMessage\n'
          '\n'
          '@wrap_tool_call\n'
          'def handle_tool_errors(request, handler):\n'
          '    try:\n'
          '        return handler(request)\n'
          '    except Exception as exc:\n'
          '        return ToolMessage(\n'
          '            content=f"도구 실행 실패: {exc}",\n'
          '            tool_call_id=request.tool_call["id"],\n'
          '        )',
  'file': '01_middleware.ipynb',
  'note': 'wrap_tool_call'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '03 / 미들웨어',
  'title': 'HumanInTheLoopMiddleware는 위험 도구를 실행 전에 멈춥니다',
  'lead': '승인·수정·거절이 필요한 도구는 모델 판단만으로 실행하지 않습니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['approve', '도구 호출을 그대로 실행', '낮은 위험의 확인 절차'],
           ['edit', '인자를 사람이 수정해 실행', '파일 경로, SQL 조건, 수신자 수정'],
           ['reject', '도구 호출을 실행하지 않음', '위험 요청 차단'],
           ['respond', '사람이 직접 사용자 응답 제공', '정책 판단이 필요한 경우']]},
 {'type': 'divider',
  'kicker': 'PART 04',
  'title': 'Subagents',
  'sub': '전문 에이전트를 도구처럼 호출해 컨텍스트를 격리하고 역할별 도구 권한을 제한합니다.',
  'lab': '05_advanced/02_multi_agent_subagents.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '04 / Subagents',
  'title': 'Subagents 실습은 역할 경계와 권한 경계를 같이 검수합니다',
  'lead': '전문 역할을 나눴다면 호출 조건과 도구 범위도 달라야 합니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['description', '호출 조건 문장', '감독자가 역할을 안정적으로 고릅니다'],
           ['tools', '역할별 최소 도구', '권한이 불필요하게 넓지 않습니다'],
           ['output', '하위 결과 형식', '감독자가 짧게 합성할 수 있습니다'],
           ['state', '히스토리 관리 방식', '상속/독립 체크포인터가 의도와 맞습니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '04 / Subagents',
  'title': 'Subagents 리스크는 위임이 아니라 결과 회수에서 드러납니다',
  'lead': '하위 작업 결과가 길거나 모호하면 메인 컨텍스트가 다시 부풀어 오릅니다',
  'groups': [{'t': '좋은 회수', 'kids': [{'t': '핵심 결론과 출처만 반환합니다'}, {'t': '다음 행동이 필요한 경우 명시합니다'}]},
             {'t': '나쁜 회수', 'kids': [{'t': '원문 전체를 그대로 반환합니다'}, {'t': '하위 에이전트가 사용자에게 직접 말하는 톤을 유지합니다'}]}]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': '04 / Subagents',
  'title': 'Subagents는 감독자가 전문 에이전트를 도구처럼 호출하는 중앙 집중 패턴입니다',
  'lead': '사용자는 감독자와 대화하고, 전문 작업은 별도 컨텍스트에서 처리됩니다',
  'img_src': 'assets/diagrams/supervisor_subagents.png',
  'cap': 'supervisor + subagents',
  'points': [{'h': 'Supervisor', 'p': '라우팅과 최종 응답을 책임집니다.'},
             {'h': 'Subagent', 'p': '전문 도구와 프롬프트만 가지고 독립 작업합니다.'},
             {'h': 'Context isolation', 'p': '긴 하위 작업이 메인 대화를 오염시키지 않습니다.'}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '04 / Subagents',
  'title': '서브에이전트는 역할 분리와 컨텍스트 격리를 동시에 제공합니다',
  'lead': '역할을 많이 만드는 것보다 description과 도구 권한을 선명하게 하는 것이 중요합니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['name', '도구 이름처럼 노출되는 식별자', '짧고 명확해야 합니다'],
           ['description', '언제 호출할지 판단하는 라우팅 문장', '가장 중요한 필드입니다'],
           ['system_prompt', '하위 역할의 행동 계약', '출력 형식과 금지 행동을 넣습니다'],
           ['tools', '하위 역할이 쓸 수 있는 도구', '최소 권한 원칙을 적용합니다'],
           ['checkpointer', '히스토리 유지 방식', '상속과 독립 히스토리를 구분합니다']]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '04 / Subagents',
  'title': 'SubAgentMiddleware는 supervisor에게 task 디스패치 도구를 노출합니다',
  'lead': '직접 @tool로 감싸는 방식보다 역할 목록을 선언적으로 관리할 수 있습니다',
  'points': [{'h': 'subagents', 'p': '역할 정의 목록입니다.'},
             {'h': 'middleware', 'p': '감독자 에이전트에 위임 도구를 주입합니다.'},
             {'h': 'task', 'p': '모델이 하위 역할에게 작업을 보냅니다.'}],
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.agents.middleware import SubAgentMiddleware\n'
          '\n'
          'subagents = [{\n'
          '    "name": "researcher",\n'
          '    "description": "자료 조사와 출처 수집이 필요할 때 사용합니다.",\n'
          '    "system_prompt": "근거 중심 리서처로 답하세요.",\n'
          '    "tools": [search_tool],\n'
          '}]\n'
          '\n'
          'supervisor = create_agent(\n'
          '    model=model,\n'
          '    tools=[],\n'
          '    middleware=[SubAgentMiddleware(subagents=subagents)],\n'
          ')',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'SubAgentMiddleware'},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '04 / Subagents',
  'title': '서브에이전트 설계의 실패는 대부분 역할 경계가 흐릴 때 생깁니다',
  'lead': '각 역할이 같은 도구와 같은 출력 형식을 가지면 분리 효과가 줄어듭니다',
  'groups': [{'t': '좋은 분리',
              'kids': [{'t': '역할마다 입력과 출력이 다릅니다'}, {'t': '도구 권한이 역할별로 제한됩니다'}, {'t': '감독자는 결과 요약만 받습니다'}]},
             {'t': '나쁜 분리',
              'kids': [{'t': '모든 서브에이전트가 같은 일을 할 수 있습니다'},
                       {'t': 'description이 모호해 라우팅이 흔들립니다'},
                       {'t': '하위 결과가 너무 길어 메인 컨텍스트를 다시 채웁니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 05',
  'title': 'Handoffs와 Router',
  'sub': '상태 기반 순차 전환과 분류 기반 병렬 라우팅을 구분합니다.',
  'lab': '05_advanced/03_multi_agent_handoffs_router.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '05 / Handoffs와 Router',
  'title': 'Handoffs와 Router 실습은 전이 메시지와 fan-out 결과를 확인합니다',
  'lead': '멀티에이전트 오류는 대부분 상태 전이 또는 결과 합성에서 발생합니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['Handoff ToolMessage', 'tool_call_id 매칭', '대화 히스토리가 malformed 되지 않습니다'],
           ['current_step', '상태 전이 값', '단계별 프롬프트와 도구가 바뀝니다'],
           ['Send fan-out', '워커 호출 목록', '필요한 도메인만 병렬 실행됩니다'],
           ['Reducer', '결과 합성', '출처와 충돌 내용이 남습니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '05 / Handoffs와 Router',
  'title': '패턴 선택 리스크는 순차 업무를 병렬화하거나 병렬 검색을 순차화할 때 생깁니다',
  'lead': '제어 흐름이 업무 흐름과 맞지 않으면 성능보다 사용자 경험이 먼저 무너집니다',
  'groups': [{'t': 'Handoffs가 맞는 경우', 'kids': [{'t': '사용자와 단계별로 직접 대화합니다'}, {'t': '앞 단계 정보가 뒤 단계의 전제입니다'}]},
             {'t': 'Router가 맞는 경우', 'kids': [{'t': '여러 지식 소스를 동시에 검색합니다'}, {'t': '분류 결과에 따라 필요한 워커 수가 달라집니다'}]}]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': '05 / Handoffs와 Router',
  'title': 'Handoffs는 단일 에이전트가 상태에 따라 다른 페르소나와 도구를 갖는 패턴입니다',
  'lead': '고객 지원처럼 순차 단계가 있는 업무는 current_step 상태로 진행 단계를 관리합니다',
  'img_src': 'assets/diagrams/handoffs_state_machine.png',
  'cap': 'handoff state machine',
  'points': [{'h': 'current_step', 'p': '현재 단계를 추적하는 상태 변수입니다.'},
             {'h': 'Command(update)', 'p': '핸드오프 도구가 상태를 바꿉니다.'},
             {'h': 'wrap_model_call', 'p': '단계별 system prompt와 tools를 교체합니다.'}]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '05 / Handoffs와 Router',
  'title': '핸드오프 도구는 Command(update)와 ToolMessage를 함께 반환해야 합니다',
  'lead': '도구 호출/응답 쌍이 맞지 않으면 모델 대화 히스토리가 잘못된 형태가 됩니다',
  'points': [{'h': 'runtime', 'p': 'tool_call_id를 얻습니다.'},
             {'h': 'current_step', 'p': '다음 단계로 상태를 전환합니다.'},
             {'h': 'ToolMessage', 'p': '핸드오프 ack를 메시지에 남깁니다.'}],
  'code': 'from langchain.tools import tool, ToolRuntime\n'
          'from langgraph.types import Command\n'
          'from langchain.messages import ToolMessage\n'
          '\n'
          '@tool\n'
          'def transfer_to_resolve(runtime: ToolRuntime[None, SupportState]) -> Command:\n'
          '    return Command(update={\n'
          '        "current_step": "resolve_issue",\n'
          '        "messages": [ToolMessage(\n'
          '            content="Transferred to resolve step",\n'
          '            tool_call_id=runtime.tool_call_id,\n'
          '        )],\n'
          '    })',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'handoff tool'},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': '05 / Handoffs와 Router',
  'title': 'Router는 분류 후 Send로 여러 도메인에 fan-out하고 reducer에서 합성합니다',
  'lead': '병렬 지식 검색과 결과 합성이 필요한 경우 Handoffs보다 Router가 적합합니다',
  'img_src': 'assets/diagrams/router_fanout_fanin.png',
  'cap': 'router fan-out / fan-in',
  'points': [{'h': 'Classify', 'p': '질문을 도메인 또는 작업 유형으로 분류합니다.'},
             {'h': 'Send', 'p': '필요한 워커를 병렬로 실행합니다.'},
             {'h': 'Reducer', 'p': '여러 결과를 출처와 함께 합성합니다.'}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '05 / Handoffs와 Router',
  'title': 'Subagents, Handoffs, Router는 제어 주체가 다릅니다',
  'lead': '멀티에이전트 패턴은 에이전트 수가 아니라 제어 흐름으로 구분합니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['Subagents', '감독자가 제어', '전문 작업 위임'],
           ['Handoffs', '상태가 제어', '순차 단계와 사용자 직접 대화'],
           ['Router', '분류 결과가 제어', '병렬 검색과 fan-out'],
           ['Custom', '그래프 설계자가 제어', '복합 정책과 특수 요구사항']]},
 {'type': 'divider',
  'kicker': 'PART 06',
  'title': '컨텍스트와 메모리',
  'sub': 'runtime context, store, semantic memory, progressive disclosure로 정보 수명과 가변성을 분리합니다.',
  'lab': '05_advanced/04_context_memory.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '06 / 컨텍스트와 메모리',
  'title': '컨텍스트 실습은 정보의 수명과 가변성을 먼저 분류합니다',
  'lead': '정보가 어디에 있어야 하는지 정해야 비용과 보안 경계가 보입니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['Runtime context', '실행 중 고정 정보', '권한·사용자 id가 도구에 주입됩니다'],
           ['State', '현재 실행 중 변화 정보', '노드 사이 값이 추적됩니다'],
           ['Store', '스레드 밖 장기 정보', '다음 대화에서도 검색됩니다'],
           ['Prompt', '이번 호출에 필요한 지시', '토큰 낭비가 없습니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '06 / 컨텍스트와 메모리',
  'title': '메모리 리스크는 오래 보관할 필요 없는 정보를 장기 저장할 때 커집니다',
  'lead': '장기 메모리는 편리하지만 삭제, 권한, 개인정보 책임을 함께 가집니다',
  'groups': [{'t': '저장 전 질문',
              'kids': [{'t': '다음 대화에서도 필요한 정보인가요?'},
                       {'t': '사용자가 삭제를 요청할 수 있나요?'},
                       {'t': '다른 thread나 사용자에게 보이면 안 되나요?'}]},
             {'t': '운영 기준', 'kids': [{'t': 'namespace로 사용자와 조직을 분리합니다'}, {'t': '민감정보는 저장 전 마스킹하거나 저장하지 않습니다'}]}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '06 / 컨텍스트와 메모리',
  'title': '컨텍스트는 가변성과 수명을 기준으로 나눠야 합니다',
  'lead': '무엇을 prompt에 넣을지보다 어디에 얼마나 오래 보관할지를 먼저 결정합니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['Static runtime context', '실행 중 바뀌지 않는 설정', '사용자 id, 권한, 조직 정보'],
           ['Dynamic state', '그래프 실행 중 바뀌는 상태', 'messages, 중간 결과'],
           ['Cross-thread store', '스레드 밖에서 공유되는 장기 정보', '사용자 프로필, 장기 메모리'],
           ['Skill/procedure', '필요할 때 읽는 절차 지식', '작업 규칙, 도구 사용법']]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '06 / 컨텍스트와 메모리',
  'title': 'context_schema는 런타임 정보를 타입 있는 객체로 주입합니다',
  'lead': '도구와 미들웨어가 같은 사용자·권한 정보를 일관되게 읽게 만듭니다',
  'points': [{'h': 'dataclass', 'p': '런타임 컨텍스트 스키마입니다.'},
             {'h': 'context_schema', 'p': 'agent가 받을 context 타입을 지정합니다.'},
             {'h': 'runtime.context', 'p': '도구 실행 중 컨텍스트를 읽습니다.'}],
  'code': 'from dataclasses import dataclass\n'
          'from langchain.tools import ToolRuntime, tool\n'
          '\n'
          '@dataclass\n'
          'class UserContext:\n'
          '    user_id: str\n'
          '    role: str\n'
          '\n'
          '@tool\n'
          'def lookup_policy(query: str, runtime: ToolRuntime[UserContext]) -> str:\n'
          '    role = runtime.context.role\n'
          '    return f"{role} 권한으로 정책 검색: {query}"',
  'file': '04_context_memory.ipynb',
  'note': 'context_schema'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '06 / 컨텍스트와 메모리',
  'title': 'Store는 thread를 넘어 공유되는 장기 메모리를 저장합니다',
  'lead': 'checkpointer가 실행 이력을 저장한다면 Store는 사용자나 조직 단위의 장기 지식을 저장합니다',
  'points': [{'h': 'namespace', 'p': '사용자나 도메인별 저장 공간입니다.'},
             {'h': 'put', 'p': '장기 사실을 저장합니다.'},
             {'h': 'search', 'p': '필요한 기억을 검색합니다.'}],
  'code': 'namespace = ("users", user_id, "memories")\n'
          'store.put(namespace, "preference", {"topic": "LangGraph"})\n'
          '\n'
          'memories = store.search(namespace, query="관심 주제")\n'
          'for item in memories:\n'
          '    print(item.value)',
  'file': '04_context_memory.ipynb',
  'note': 'Store memory'},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '06 / 컨텍스트와 메모리',
  'title': '컨텍스트 엔지니어링은 많이 넣는 기술이 아니라 필요한 정보만 회수하는 기술입니다',
  'lead': '정보를 잘못된 층에 넣으면 비용, 누락, 권한 문제가 동시에 생깁니다',
  'groups': [{'t': 'prompt에 넣을 것', 'kids': [{'t': '이번 답변에 반드시 필요한 짧은 지침'}, {'t': '모델이 바로 따라야 하는 출력 계약'}]},
             {'t': 'store에 넣을 것', 'kids': [{'t': '다음 대화에서도 필요한 장기 사실'}, {'t': '사용자별로 검색 가능한 선호와 히스토리'}]},
             {'t': 'state에 넣을 것', 'kids': [{'t': '현재 실행 중만 필요한 중간 결과'}, {'t': '그래프 노드 사이에 전달되는 작업 상태'}]}]},
 {'type': 'divider',
  'kicker': 'PART 07',
  'title': 'Agentic RAG',
  'sub': '검색 결과를 평가하고 질문을 다시 쓰는 그래프형 RAG를 구축합니다.',
  'lab': '05_advanced/05_agentic_rag.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '07 / Agentic RAG',
  'title': 'Agentic RAG 실습은 검색 품질과 복구 경로를 따로 검증합니다',
  'lead': '최종 답변만 보면 검색 실패와 생성 실패를 구분할 수 없습니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['검색 결과', '정답 문서가 상위에 있는지', 'top-k 안에 기대 근거가 있습니다'],
           ['관련성 평가', 'grade_documents 결과', '무관한 문서는 답변으로 가지 않습니다'],
           ['질문 재작성', 'rewrite_question 효과', '재검색 결과가 개선됩니다'],
           ['최종 답변', '출처와 한계', '근거 없는 답변이 없습니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '07 / Agentic RAG',
  'title': 'Agentic RAG 리스크는 재시도가 품질 개선이 아니라 루프가 될 때 발생합니다',
  'lead': '복구 경로에는 항상 횟수 제한과 실패 응답 정책이 필요합니다',
  'groups': [{'t': '제한할 것', 'kids': [{'t': '질문 재작성 횟수'}, {'t': '검색 top-k와 컨텍스트 길이'}, {'t': '모델 호출 총량'}]},
             {'t': '실패 시 응답', 'kids': [{'t': '근거 부족을 명시합니다'}, {'t': '추가로 필요한 문서나 질문을 제안합니다'}]}]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': '07 / Agentic RAG',
  'title': 'Agentic RAG는 검색 후 관련성 평가와 질문 재작성을 포함합니다',
  'lead': '단순 RAG가 실패하는 지점을 그래프의 복구 경로로 명시합니다',
  'img_src': 'assets/diagrams/rag_architecture_choices.png',
  'cap': 'RAG architecture choices',
  'points': [{'h': 'Retrieve', 'p': '질문에 맞는 문서 후보를 가져옵니다.'},
             {'h': 'Grade', 'p': '문서가 질문에 답할 수 있는지 평가합니다.'},
             {'h': 'Rewrite', 'p': '관련성이 낮으면 질문을 검색 친화적으로 다시 씁니다.'}]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '07 / Agentic RAG',
  'title': 'retrieve 도구는 content와 artifact를 함께 반환해야 평가와 출처 추적이 가능합니다',
  'lead': '모델이 읽을 문자열과 운영자가 추적할 Document 객체를 분리합니다',
  'points': [{'h': 'serialized', 'p': '모델 입력에 넣는 근거 문자열입니다.'},
             {'h': 'docs', 'p': '원본 Document 객체입니다.'},
             {'h': 'metadata', 'p': '출처 표시와 필터링에 사용합니다.'}],
  'code': 'from langchain_core.tools import tool\n'
          '\n'
          '@tool(response_format="content_and_artifact")\n'
          'def retrieve(query: str):\n'
          '    docs = vector_store.similarity_search(query, k=4)\n'
          '    serialized = "\\n\\n".join(\n'
          '        f"출처: {d.metadata.get(\'source\', \'?\')}\\n{d.page_content}"\n'
          '        for d in docs\n'
          '    )\n'
          '    return serialized, docs',
  'file': '05_agentic_rag.ipynb',
  'note': 'retrieve tool'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '07 / Agentic RAG',
  'title': 'relevance_router는 관련성 평가 결과를 답변 또는 재검색 경로로 바꿉니다',
  'lead': '그래프형 RAG의 핵심은 검색 실패를 최종 답변 전에 감지하는 것입니다',
  'points': [{'h': 'relevant', 'p': '답변 생성으로 이동합니다.'},
             {'h': 'not relevant', 'p': '질문 재작성으로 이동합니다.'},
             {'h': 'StateGraph', 'p': '복구 경로를 실행 그래프에 고정합니다.'}],
  'code': 'def relevance_router(state: AgentState):\n'
          '    if state.get("relevance") == "relevant":\n'
          '        return "generate_answer"\n'
          '    return "rewrite_question"\n'
          '\n'
          'graph = StateGraph(AgentState)\n'
          'graph.add_node("retrieve", ToolNode([retrieve]))\n'
          'graph.add_node("grade_documents", grade_documents)\n'
          'graph.add_node("rewrite_question", rewrite_question)\n'
          'graph.add_node("generate_answer", generate_answer)',
  'file': '05_agentic_rag.ipynb',
  'note': 'relevance routing'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '07 / Agentic RAG',
  'title': '세 가지 RAG 접근은 제어 가능성과 비용이 다릅니다',
  'lead': '복잡한 질문일수록 복구 경로가 필요하지만 호출 비용과 지연이 늘어납니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['RAG Chain', '검색 후 답변 흐름 고정', '단순 질의응답'],
           ['RAG Agent', '도구 사용 여부를 모델이 판단', '다단계 검색 질문'],
           ['LangGraph RAG', '평가·재작성·답변을 그래프로 고정', '운영 복구와 관찰 가능성'],
           ['Deep Agent RAG', '파일·스킬·장기 작업까지 포함', '프로젝트형 리서치 작업']]},
 {'type': 'divider',
  'kicker': 'PART 08',
  'title': 'SQL Agent',
  'sub': '자연어 질문을 안전한 SQL 조회와 검증 가능한 답변으로 연결합니다.',
  'lab': '05_advanced/06_sql_agent.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '08 / SQL Agent',
  'title': 'SQL Agent 실습은 생성 SQL을 최종 답변만큼 중요하게 다룹니다',
  'lead': '데이터 기반 답변은 SQL과 결과를 함께 검토해야 합니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['schema 조회', '사용 가능한 테이블 확인', '없는 컬럼을 쓰지 않습니다'],
           ['query 생성', 'SELECT와 조건 구성', '허용 테이블과 LIMIT를 지킵니다'],
           ['query 실행', '결과 행과 오류 확인', '오류를 수정 루프로 보냅니다'],
           ['answer', '업무 언어로 해석', '쿼리와 결과 근거가 남습니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '08 / SQL Agent',
  'title': 'SQL Agent 리스크는 자연어가 권한 높은 쿼리로 바뀌는 순간 발생합니다',
  'lead': '읽기 전용이어도 민감 데이터 대량 조회는 운영 사고가 될 수 있습니다',
  'groups': [{'t': '차단할 요청', 'kids': [{'t': '개인정보 전체 추출'}, {'t': '권한 밖 테이블 조회'}, {'t': '쓰기·삭제·스키마 변경'}]},
             {'t': '완화 방법', 'kids': [{'t': '허용 테이블과 행 수를 제한합니다'}, {'t': '위험 쿼리는 HITL 승인을 둡니다'}]}]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '08 / SQL Agent',
  'title': 'SQLDatabaseToolkit은 DB 스키마 조회와 SQL 실행 도구를 에이전트에 제공합니다',
  'lead': 'SQL 에이전트는 먼저 스키마를 읽고, 쿼리를 작성하고, 결과를 해석해야 합니다',
  'points': [{'h': 'SQLDatabase', 'p': '연결 대상 DB와 테이블 정보를 제공합니다.'},
             {'h': 'Toolkit', 'p': '스키마 조회와 쿼리 실행 도구를 만듭니다.'},
             {'h': 'Agent', 'p': '도구를 사용해 자연어 질문에 답합니다.'}],
  'code': 'from langchain_community.utilities import SQLDatabase\n'
          'from langchain_community.agent_toolkits import SQLDatabaseToolkit\n'
          'from langchain.agents import create_agent\n'
          '\n'
          'db = SQLDatabase.from_uri("sqlite:///Chinook.db")\n'
          'toolkit = SQLDatabaseToolkit(db=db, llm=model)\n'
          'agent = create_agent(model=model, tools=toolkit.get_tools())',
  'file': '06_sql_agent.ipynb',
  'note': 'SQL toolkit'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '08 / SQL Agent',
  'title': 'SQL 에이전트 안전 수칙은 조회 범위와 실행 권한을 제한하는 데서 시작합니다',
  'lead': '자연어가 SQL이 되는 순간 데이터 삭제와 대량 조회 위험을 함께 봐야 합니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['읽기 전용', 'SELECT 중심 권한 사용', '쓰기·삭제 차단'],
           ['테이블 제한', '허용 테이블만 노출', '민감 테이블 보호'],
           ['쿼리 검토', '실행 전 SQL 확인', 'HITL 승인'],
           ['행 수 제한', 'LIMIT 기본 적용', '비용과 정보 노출 제한'],
           ['감사 로그', '질문·SQL·결과 기록', '사후 추적']]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': '08 / SQL Agent',
  'title': 'SQL Agent도 위험한 실행 전에는 HITL 경계를 둘 수 있습니다',
  'lead': '사용자 질문이 데이터베이스 실행으로 이어지므로 승인과 검토 루프가 중요합니다',
  'img_src': 'assets/diagrams/hitl_flow.png',
  'cap': 'HITL flow',
  'points': [{'h': 'Generate SQL', 'p': '모델이 조회 쿼리를 제안합니다.'},
             {'h': 'Review', 'p': '사람 또는 정책이 위험 쿼리를 검토합니다.'},
             {'h': 'Execute', 'p': '허용된 쿼리만 실행합니다.'}]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '08 / SQL Agent',
  'title': 'SQL 답변은 쿼리, 결과, 해석을 분리해 검증해야 합니다',
  'lead': '최종 한국어 답변만 남기면 어떤 데이터에서 나온 결론인지 추적할 수 없습니다',
  'groups': [{'t': '남겨야 할 것', 'kids': [{'t': '사용자 질문'}, {'t': '생성된 SQL'}, {'t': '실행 결과 행 수와 샘플'}, {'t': '최종 해석과 한계'}]},
             {'t': '거절해야 할 것', 'kids': [{'t': '권한 밖 테이블 조회'}, {'t': '대량 개인정보 추출'}, {'t': '쓰기·삭제·스키마 변경'}]}]},
 {'type': 'divider',
  'kicker': 'PART 09',
  'title': '데이터 분석 에이전트',
  'sub': 'Deep Agents와 샌드박스 실행으로 데이터 분석 작업을 산출물 중심으로 수행합니다.',
  'lab': '05_advanced/07_data_analysis.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '09 / 데이터 분석',
  'title': '데이터 분석 실습은 산출물 파일과 해석 문장을 함께 검수합니다',
  'lead': '분석 에이전트는 코드를 실행하므로 결과 재현성이 핵심입니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['입력 데이터', '파일과 스키마 확인', '행 수와 컬럼이 기록됩니다'],
           ['분석 코드', '전처리·집계·시각화', '재실행 가능합니다'],
           ['산출물', '표·차트·보고서 파일', '작업 폴더에 남습니다'],
           ['해석', '결론과 한계', '업무 판단과 연결됩니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '09 / 데이터 분석',
  'title': '데이터 분석 리스크는 그럴듯한 차트가 검증 없이 제시될 때 커집니다',
  'lead': '에이전트가 만든 분석도 사람이 만든 분석과 같은 검산 절차가 필요합니다',
  'groups': [{'t': '검산 항목', 'kids': [{'t': '분모와 집계 단위'}, {'t': '결측과 이상치 처리'}, {'t': '필터와 기간 조건'}]},
             {'t': '보고 항목', 'kids': [{'t': '분석 질문'}, {'t': '사용한 데이터'}, {'t': '결론과 한계'}]}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '09 / 데이터 분석',
  'title': '데이터 분석 에이전트는 질문·코드·파일·해석이 모두 남아야 합니다',
  'lead': '분석 에이전트는 답변보다 재현 가능한 작업 흔적이 중요합니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['질문', '분석 목표와 지표 정의', '모호하면 잘못된 코드가 생성됩니다'],
           ['코드', '전처리·집계·시각화 실행', '재현성과 리뷰 대상입니다'],
           ['파일', '입력 데이터와 출력 산출물', '작업 공간 경계가 필요합니다'],
           ['해석', '결과의 의미와 한계', '업무 의사결정으로 연결합니다'],
           ['검증', '샘플 수, 결측, 단위 확인', '그럴듯한 오답을 줄입니다']]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '09 / 데이터 분석',
  'title': 'Deep Agents는 파일 백엔드와 도구를 묶어 분석 작업 공간을 만듭니다',
  'lead': '데이터 분석은 중간 파일과 코드 실행 결과가 남아야 하므로 파일 시스템 경계가 중요합니다',
  'points': [{'h': 'FilesystemBackend', 'p': '분석 파일을 읽고 씁니다. 0.7 기준 FilesystemBackend의 기본 격리 설정과 root_dir 경계를 확인합니다.'},
             {'h': 'tools', 'p': '데이터 로딩과 코드 실행 도구를 제한합니다.'},
             {'h': 'system_prompt', 'p': '검증과 해석 기준을 명시합니다.'},
             {'h': 'planning', 'p': '분석 절차가 길어질 때는 TodoListMiddleware를 명시적으로 붙입니다.'}],
  'code': 'from deepagents import create_deep_agent\n'
          'from langchain.agents.middleware import TodoListMiddleware\n'
          'from deepagents.backends import FilesystemBackend\n'
          '\n'
          'analysis_agent = create_deep_agent(\n'
          '    model=model,\n'
          '    tools=[python_repl, read_file, write_file],\n'
          '    middleware=[TodoListMiddleware()],\n'
          '    backend=FilesystemBackend(root_dir="./analysis", virtual_mode=True),\n'
          '    system_prompt="데이터 분석 과정과 한계를 함께 기록하세요.",\n'
          ')',
  'file': '07_data_analysis.ipynb',
  'note': 'analysis agent'},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': '09 / 데이터 분석',
  'title': '분석 코드 실행은 에이전트 제어면과 샌드박스를 분리해서 봐야 합니다',
  'lead': '데이터와 코드를 실행하는 곳에는 보안·비용·재현성 기준이 필요합니다',
  'img_src': 'assets/diagrams/sandbox_architecture.png',
  'cap': 'sandbox architecture',
  'points': [{'h': 'Agent', 'p': '분석 계획과 해석을 담당합니다.'},
             {'h': 'Sandbox', 'p': '코드 실행과 파일 처리를 격리합니다.'},
             {'h': 'Artifacts', 'p': '표, 차트, 보고서 파일을 산출합니다.'},
             {'h': 'Provider settings',
              'p': 'OpenAI prompt_cache_options, Google thinking_config처럼 provider별 설정은 환경 회귀 항목으로 분리합니다.'}]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '09 / 데이터 분석',
  'title': '분석 결과는 숫자보다 검증 문장이 먼저 필요합니다',
  'lead': '차트와 표가 있어도 단위, 필터, 결측 기준이 없으면 업무 의사결정에 쓰기 어렵습니다',
  'groups': [{'t': '검증 문장',
              'kids': [{'t': '사용한 데이터 기간과 필터를 밝힙니다'}, {'t': '행 수, 결측, 이상치를 확인합니다'}, {'t': '집계 단위와 분모를 설명합니다'}]},
             {'t': '해석 문장', 'kids': [{'t': '결론과 근거 지표를 연결합니다'}, {'t': '대체 설명과 한계를 적습니다'}, {'t': '다음 분석 질문을 제안합니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 10',
  'title': 'Voice Agent',
  'sub': 'STT, Agent, TTS와 멀티모달 content blocks로 음성 에이전트 아키텍처를 설계합니다.',
  'lab': '05_advanced/08_voice_agent.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '10 / Voice Agent',
  'title': 'Voice Agent 실습은 정확도보다 지연·중단·승인 흐름을 함께 봐야 합니다',
  'lead': '음성 UI에서는 사용자가 기다리는 시간과 끼어들기가 제품 품질을 좌우합니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['STT 지연', '음성 인식까지 걸리는 시간', '사용자가 긴 침묵을 느끼지 않습니다'],
           ['Agent 지연', '도구 호출과 추론 시간', '중간 상태를 안내합니다'],
           ['TTS 제어', '응답 재생과 중단', 'barge-in을 처리합니다'],
           ['승인 흐름', '위험 작업 확인', '음성만으로 민감 작업을 실행하지 않습니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '10 / Voice Agent',
  'title': 'Voice Agent 리스크는 오인식과 과잉 실행이 결합될 때 커집니다',
  'lead': '잘못 들은 명령을 곧바로 도구 실행으로 연결하지 않아야 합니다',
  'groups': [{'t': '안전 장치',
              'kids': [{'t': '민감 작업은 다시 읽고 승인받습니다'},
                       {'t': '사용자 발화를 텍스트로 확인할 수 있게 합니다'},
                       {'t': '실패 시 텍스트 fallback을 제공합니다'}]},
             {'t': '로그 기준', 'kids': [{'t': '음성 원문 저장 여부를 정책화합니다'}, {'t': '인식 결과와 실행 명령을 분리해 기록합니다'}]}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '10 / Voice Agent',
  'title': 'Voice Agent는 STT, Agent, TTS가 지연 시간 안에서 이어지는 시스템입니다',
  'lead': '음성은 정확도뿐 아니라 응답 지연과 중간 끊김이 사용자 경험을 좌우합니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['STT', '사용자 음성을 텍스트로 변환', '실시간성, 화자 구분'],
           ['Agent', '텍스트 질문을 이해하고 도구를 사용', '대화 상태와 권한'],
           ['TTS', '응답을 음성으로 변환', '톤, 속도, 중단 처리'],
           ['Streaming', '부분 결과를 즉시 전달', '지연 시간 체감 개선'],
           ['Content blocks', '텍스트·이미지·reasoning 구조화', '멀티모달 응답 표준화']]},
 {'type': 'cards',
  'course': 'AI 에이전트 개발 고급',
  'meta': '10 / Voice Agent',
  'title': '음성 에이전트 아키텍처는 세 가지 방식으로 비교합니다',
  'lead': '어떤 컴포넌트가 실시간 스트림을 잡고 있는지에 따라 구현 난도가 달라집니다',
  'cards': [{'h': 'Sandwich', 'p': 'STT → Agent → TTS를 순서대로 연결합니다. 가장 이해하기 쉽습니다.', 'm': 'simple'},
            {'h': 'Realtime', 'p': '모델 또는 런타임이 음성 스트림을 직접 다룹니다. 지연이 낮습니다.', 'm': 'low latency'},
            {'h': 'Hybrid', 'p': '중요 도구 호출은 텍스트 에이전트로, 대화 입출력은 음성으로 처리합니다.', 'm': 'control'},
            {'h': 'Fallback', 'p': '음성 실패 시 텍스트 UI로 전환합니다. 운영 안정성이 높습니다.', 'm': 'resilience'}]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '10 / Voice Agent',
  'title': '음성 에이전트는 끼어들기와 중단을 제품 요구사항으로 다뤄야 합니다',
  'lead': '텍스트 채팅과 달리 사용자는 말하는 중간에 멈추거나 수정하거나 말을 끊을 수 있습니다',
  'groups': [{'t': '대화 제어',
              'kids': [{'t': '사용자 barge-in을 감지합니다'},
                       {'t': 'TTS 재생을 중단할 수 있어야 합니다'},
                       {'t': '부분 인식 결과와 최종 인식 결과를 구분합니다'}]},
             {'t': '운영 제어',
              'kids': [{'t': '민감 작업은 음성만으로 실행하지 않습니다'},
                       {'t': '승인 문구를 명확히 다시 읽어 줍니다'},
                       {'t': '오인식 로그와 재시도 경로를 남깁니다'}]}]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '10 / Voice Agent',
  'title': 'output_version="v1"은 멀티모달 content blocks를 표준 형태로 받기 위한 설정입니다',
  'lead': '음성·이미지·텍스트가 섞이는 앱에서는 응답 구조를 고정해야 프런트엔드 처리가 단순해집니다',
  'points': [{'h': 'TextContentBlock', 'p': '일반 텍스트 응답입니다.'},
             {'h': 'ImageContentBlock', 'p': '이미지 입력 또는 출력과 연결됩니다.'},
             {'h': 'Reasoning block', 'p': '모델 제공자별 추론 블록을 표준 구조로 다룹니다.'}],
  'code': 'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          '    output_version="v1",\n'
          ')\n'
          '\n'
          'response = model.invoke("음성 에이전트의 핵심 설계를 요약해줘")\n'
          'print(response.content)',
  'file': '08_voice_agent.ipynb',
  'note': 'content blocks'},
 {'type': 'divider',
  'kicker': 'PART 11',
  'title': '프로덕션',
  'sub': '테스트, 평가, 관측성, 배포, 롤백을 에이전트 제품 출시 기준으로 묶습니다.',
  'lab': '05_advanced/09_production.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / 프로덕션',
  'title': '프로덕션 실습은 평가셋과 배포 체크리스트가 있어야 완료됩니다',
  'lead': '기능이 돌아가도 평가와 롤백 기준이 없으면 출시 상태가 아닙니다',
  'cols': [{'t': '체크포인트', 'w': '28%'}, {'t': '확인할 내용', 'w': '40%'}, {'t': '통과 기준', 'accent': True}],
  'rows': [['평가셋', '대표 질문과 기대 결과', '릴리즈마다 재실행됩니다'],
           ['관측성', 'trace와 비용 지표', '실패 지점이 보입니다'],
           ['보안', '권한·PII·HITL 정책', '감사 로그가 남습니다'],
           ['롤백', '프롬프트·도구·그래프 변경 이력', '문제 발생 시 되돌릴 수 있습니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / 프로덕션',
  'title': '프로덕션 리스크는 모델 품질보다 변경 관리 부재에서 자주 발생합니다',
  'lead': '프롬프트 한 줄 변경도 도구 호출 경로와 비용을 바꿀 수 있습니다',
  'groups': [{'t': '변경 전', 'kids': [{'t': '회귀 평가셋을 실행합니다'}, {'t': '비용과 지연 변화를 비교합니다'}, {'t': '위험 도구 케이스를 재검증합니다'}]},
             {'t': '변경 후', 'kids': [{'t': '실패 trace를 데이터셋에 추가합니다'}, {'t': '사용자 피드백을 평가 항목으로 바꿉니다'}]}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / 프로덕션',
  'title': '에이전트 테스트는 Unit, Integration, Evals로 나눠야 합니다',
  'lead': '함수 테스트만 통과해도 실제 에이전트 행동은 실패할 수 있습니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['Unit', '도구 함수와 라우터 단위 검증', '결정론적 테스트'],
           ['Integration', '모델·도구·그래프 연결 검증', 'mock 또는 fake model'],
           ['Evals', '실제 질문 세트 품질 평가', 'LangSmith dataset'],
           ['Trajectory', '도구 호출 경로 평가', '예상 도구 순서와 비교'],
           ['Regression', '이전 실패 재발 방지', '릴리즈 전 고정 평가']]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / 프로덕션',
  'title': 'LangSmith 평가는 질문, 기대 답변, 실행 결과를 데이터셋으로 비교합니다',
  'lead': '프로덕션에서는 한두 번의 수동 시연보다 반복 가능한 평가셋이 필요합니다',
  'points': [{'h': 'dataset', 'p': '대표 질문과 기대 결과 모음입니다.'},
             {'h': 'evaluator', 'p': '정답성, 도구 경로, 안전성을 채점합니다.'},
             {'h': 'experiment', 'p': '모델·프롬프트 변경 전후를 비교합니다.'}],
  'code': 'from langsmith import Client\n'
          '\n'
          'client = Client()\n'
          '# dataset = client.create_dataset("agent-regression")\n'
          '# client.create_examples(dataset_id=dataset.id, examples=examples)\n'
          '\n'
          '# evaluate(agent, data=dataset.name, evaluators=[trajectory_evaluator])',
  'file': '09_production.ipynb',
  'note': 'LangSmith eval'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / LangSmith',
  'title': 'SmithDB 조회는 runs.query로 프로젝트·기간·projection을 명시합니다',
  'lead': 'runs.query는 projection을 명시하지 않으면 기본적으로 ID만 돌려줍니다. 분석에 필요한 필드는 uppercase selects로 요청합니다',
  'points': [{'h': 'project_ids', 'p': '프로젝트 이름이 아니라 UUID 리스트로 조회 범위를 고정합니다.'},
             {'h': 'time window', 'p': '현재 시각 기준 window를 계산해 배포 전후 비교 구간을 재현합니다.'},
             {'h': 'selects',
              'p': "기본 projection은 ID뿐입니다. 이름·시간·입출력이 필요하면 <span class='mono'>ID, NAME, START_TIME, END_TIME, INPUTS, "
                   'OUTPUTS</span>를 명시합니다.'}],
  'code': 'from datetime import datetime, timedelta, timezone\n'
          'from langsmith import Client\n'
          '\n'
          'client = Client()\n'
          'project_id = "00000000-0000-0000-0000-000000000000"\n'
          'now = datetime.now(timezone.utc)\n'
          'selects = ["ID", "NAME", "START_TIME", "END_TIME", "INPUTS", "OUTPUTS"]\n'
          '\n'
          'async for run in client.runs.query(\n'
          '    project_ids=[project_id],\n'
          '    min_start_time=now - timedelta(days=7),\n'
          '    max_start_time=now,\n'
          '    page_size=100,\n'
          '    selects=selects,\n'
          '):\n'
          '    print(run["ID"], run.get("NAME"), run.get("START_TIME"))',
  'file': '09_production.ipynb',
  'note': 'SmithDB runs.query'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / LangSmith',
  'title': 'LangSmith migration은 runs, feedback, sharing 영역을 따로 판단합니다',
  'lead': '모든 legacy 호출을 한 번에 치환하지 않고 서비스 지원 범위와 예외 경로를 확인합니다',
  'cols': [{'t': '영역', 'w': '26%'}, {'t': '확인할 것', 'w': '38%'}, {'t': '덱 판단', 'accent': True}],
  'rows': [['runs.query',
            'project_ids, min/max_start_time, page_size, uppercase selects',
            'selects 생략 시 기본 ID projection만 반환'],
           ['feedback', '점수·코멘트·run 연결 API', '평가 루프와 함께 검증'],
           ['sharing', '공유 링크와 self-hosted 지원 차이', '배포 환경별 조건부 항목'],
           ['exceptions', '클라우드와 self-hosted의 오류 경로', '전역 치환 금지']]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / 평가',
  'title': 'evaluation tracing은 비용과 디버깅 사이에서 선택합니다',
  'lead': 'evaluate 호출은 유지하되 evaluator 내부 trace를 남길지 별도 옵션으로 결정합니다',
  'cols': [{'t': '옵션', 'w': '28%'}, {'t': '효과', 'w': '38%'}, {'t': '운영 판단', 'accent': True}],
  'rows': [['evaluate 기본', '실험 결과와 run 비교를 남김', '회귀 평가의 기준 경로'],
           ['disable_evaluator_tracing', 'evaluator 내부 trace 비용을 줄임', '채점 과정 디버깅이 덜 필요할 때'],
           ['grader hooks', 'criterion별 실패 원인 기록', '루브릭 coverage와 함께 검수'],
           ['피드백 연결', '사용자·자동 채점 결과를 run에 연결', '운영 모니터링으로 이어짐']]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Reference / Update map',
  'title': '공식 문서 이동과 신규 항목은 기존 트랙에 연결해 읽습니다',
  'lead': 'Code, dynamic subagents, fault tolerance, multimodal, retrieval은 새 파일을 늘리기보다 기존 주제의 기준점을 갱신합니다',
  'cols': [{'t': '항목', 'w': '28%'}, {'t': '연결 위치', 'w': '38%'}, {'t': '수업 판단', 'accent': True}],
  'rows': [['Code / plugins', 'Deep Agents code 문서와 통합 트랙', '코어 노트북에 CLI 의존성 주입 금지'],
           ['dynamic subagents', '서브에이전트 설계와 fork 비교', '정적 선언과 동적 생성을 분리'],
           ['fault tolerance', 'LangGraph durable execution과 production', '재시도·중단·복구를 한 루프로 설명'],
           ['multimodal / retrieval', 'RAG·voice·data analysis', '기존 실습과 중복을 확인한 뒤 확장']]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / 프로덕션',
  'title': '운영 모니터링은 답변 품질과 시스템 비용을 함께 봐야 합니다',
  'lead': '에이전트는 모델 호출, 도구 호출, 사람 승인, 외부 API 비용이 함께 발생합니다',
  'cols': [{'t': '항목', 'w': '25%'}, {'t': '핵심', 'w': '40%'}, {'t': '실전 판단', 'accent': True}],
  'rows': [['품질', '정답성, 근거성, 거절 정확도', '평가셋과 사용자 피드백'],
           ['경로', '도구 호출 순서와 실패 지점', 'trace와 trajectory'],
           ['비용', '토큰, 도구 API, 실행 시간', '예산과 호출 제한'],
           ['지연', '최종 응답과 중간 스트림 시간', '사용자 경험'],
           ['안전', 'HITL, PII, 권한 위반', '감사 로그와 알림']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 고급',
  'meta': '11 / 프로덕션',
  'title': '출시 기준은 기능 완료가 아니라 실패 대응 절차가 준비됐는지로 판단합니다',
  'lead': '고급 에이전트는 실패하지 않는 시스템이 아니라 실패를 발견하고 되돌릴 수 있는 시스템이어야 합니다',
  'groups': [{'t': '출시 전', 'kids': [{'t': '회귀 평가셋을 통과합니다'}, {'t': '민감 도구의 승인 정책을 검증합니다'}, {'t': '비용과 지연 예산을 정합니다'}]},
             {'t': '출시 후',
              'kids': [{'t': '실패 trace를 수집합니다'}, {'t': '오답을 데이터셋에 추가합니다'}, {'t': '프롬프트, 도구, 그래프 변경을 실험 단위로 비교합니다'}]}]},
 {'type': 'divider',
  'kicker': 'REFERENCE',
  'title': '개념 근거와 고급 패턴',
  'sub': '고급 패턴 설명은 ReAct, RAG, Pregel 논문, Anthropic 에이전트 패턴 문서, LangChain/LangGraph 공식 문서를 기준으로 보강합니다.'},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Reference / Patterns',
  'title': '고급 에이전트 패턴은 control loop, retrieval loop, evaluation loop로 나눠 설명할 수 있습니다',
  'lead': 'ReAct는 추론과 행동의 교차 루프를, RAG는 검색과 생성 결합을, Anthropic은 workflow와 agent 패턴의 구분을 제시합니다.',
  'img_src': 'assets/diagrams/svg_agent_loops.svg',
  'cap': 'agent loops from trusted sources',
  'points': [{'h': 'ReAct', 'p': 'reasoning과 acting을 번갈아 수행합니다.'},
             {'h': 'RAG', 'p': 'parametric memory와 non-parametric memory를 결합합니다.'},
             {'h': 'Evaluator', 'p': '생성 결과를 평가하고 개선하는 루프입니다.'}]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Reference / Production',
  'title': '프로덕션 에이전트는 trace, eval, guardrail, rollback을 한 루프로 관리합니다',
  'lead': '공식 LangSmith/LangGraph 문서와 Anthropic 패턴은 평가와 관찰 가능성을 운영 루프의 핵심으로 봅니다.',
  'img_src': 'assets/diagrams/svg_production_loop.svg',
  'cap': 'production evaluation loop',
  'points': [{'h': 'Trace', 'p': '도구 호출과 상태 변화를 기록합니다.'},
             {'h': 'Eval', 'p': '대표 질문 세트로 회귀를 확인합니다.'},
             {'h': 'Rollback', 'p': '문제 변경을 되돌릴 수 있어야 합니다.'}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Reference / Advanced',
  'title': '고급 개념 보강 출처는 논문과 공식 문서를 함께 사용합니다',
  'lead': '응용별 개념은 가장 직접적인 신뢰 출처를 기준으로 설명합니다.',
  'cols': [{'t': '개념', 'w': '24%'}, {'t': '출처', 'w': '36%'}, {'t': '덱 반영', 'accent': True}],
  'rows': [['Tool-using agent', 'ReAct, arXiv:2210.03629', 'reason-act-observe 루프와 trajectory'],
           ['RAG', 'Lewis et al., NeurIPS 2020', 'parametric/non-parametric memory와 provenance'],
           ['Workflow patterns',
            'Anthropic Building Effective Agents',
            'prompt chaining, routing, parallelization, orchestrator-worker, evaluator-optimizer'],
           ['Durable state', 'LangGraph official docs', 'persistence, HITL, time travel, durable execution']]},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '00_migration.ipynb',
  'sub': '00_migration.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/00_migration.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 01',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 5',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          'from langchain.tools import tool\n'
          'from langchain.agents import create_agent\n'
          '\n'
          'model = ChatOpenAI(model="gpt-5.4")\n'
          '\n'
          '@tool\n'
          'def add(a: int, b: int) -> int:\n'
          '    """두 수를 더합니다."""\n'
          '    return a + b\n'
          '\n'
          '# v0: from langgraph.prebuilt import create_react_agent\n'
          '# v1: from langchain.agents import create_agent\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add],\n'
          '    system_prompt="당신은 수학 어시스턴트입니다.",  # v0: prompt=\n'
          ')\n'
          'print("\\u2713 v1 에이전트 생성 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 6',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON \\u2014 project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON \\u2014 {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 03',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 9',
  'code': 'from langchain.agents import AgentState, create_agent\n'
          '\n'
          'class CustomState(AgentState):\n'
          '    user_id: str\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add],\n'
          '    state_schema=CustomState,\n'
          ')\n'
          '\n'
          'result = agent.invoke({\n'
          '    "messages": [{"role": "user", "content": "3+4는 얼마인가요?"}],\n'
          '    "user_id": "user_123",\n'
          '}, config=lf_config)\n'
          'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 04 (1/2)',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 11',
  'code': 'from dataclasses import dataclass\n'
          'from langchain.tools import tool, ToolRuntime\n'
          '\n'
          '@dataclass\n'
          'class UserContext:\n'
          '    user_id: str\n'
          '    role: str\n'
          '\n'
          '@tool\n'
          'def get_role(runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """현재 사용자의 역할을 조회합니다."""\n'
          '    return f"사용자 {runtime.context.user_id}의 역할: {runtime.context.role}"\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[get_role],\n'
          '    context_schema=UserContext,\n'
          ')\n'
          '\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "제 역할이 뭔가요?"}]},\n'
          '    context=UserContext(user_id="u1", role="admin"),'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 04 (2/2)',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 11',
  'code': '    config=lf_config,\n)\nprint(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 05',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 13',
  'code': 'from langchain.agents.middleware import dynamic_prompt, ModelRequest\n'
          '\n'
          '@dynamic_prompt\n'
          'def role_based_prompt(request: ModelRequest) -> str:\n'
          '    role = request.runtime.context.role\n'
          '    if role == "admin":\n'
          '        return "당신은 전체 접근 권한을 가진 관리자 어시스턴트입니다."\n'
          '    return "당신은 읽기 전용 어시스턴트입니다."\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add],\n'
          '    context_schema=UserContext,\n'
          '    middleware=[role_based_prompt],\n'
          ')\n'
          '\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "안녕하세요!"}]},\n'
          '    context=UserContext(user_id="u1", role="admin"),\n'
          '    config=lf_config,\n'
          ')\n'
          'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 06',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 15',
  'code': 'from langchain.agents.middleware import wrap_tool_call\n'
          'from langchain.messages import ToolMessage\n'
          '\n'
          '@wrap_tool_call\n'
          'def handle_errors(request, handler):\n'
          '    try:\n'
          '        return handler(request)\n'
          '    except Exception as e:\n'
          '        return ToolMessage(\n'
          '            content=f"도구 오류: {e}",\n'
          '            tool_call_id=request.tool_call["id"],\n'
          '        )\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add],\n'
          '    middleware=[handle_errors],\n'
          ')\n'
          'print("\\u2713 에러 핸들링 미들웨어 적용")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 07',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 18',
  'code': '# 표준 콘텐츠 블록\n'
          '\n'
          'response = model.invoke(\n'
          '    "인사해 주세요.",\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'for block in response.content_blocks:\n'
          '    print(f"  [{block[\'type\']}] {block.get(\'text\', \'\')[:100]}")\n'
          '\n'
          '# .text 프로퍼티 (v0: .text() 메서드 → v1: .text 프로퍼티)\n'
          '\n'
          'print(f"\\n.text: {response.text[:100]}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 00_migration',
  'title': '00_migration 코드 08',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '00_migration.ipynb',
  'note': 'cell 20',
  'code': 'for chunk in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "5+3은 얼마인가요?"}]},\n'
          '    context=UserContext(user_id="u1", role="admin"),\n'
          '    stream_mode="updates",\n'
          '    config=lf_config,\n'
          '):\n'
          '    for node_name, update in chunk.items():\n'
          '        # v1: node_name은 "model" (v0에서는 "agent")\n'
          '        if "messages" in update:\n'
          '            last = update["messages"][-1]\n'
          '            if hasattr(last, "content") and last.content:\n'
          '                print(f"[{node_name}] {last.content[:200]}")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '01_middleware.ipynb',
  'sub': '01_middleware.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/01_middleware.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 3',
  'code': 'from dotenv import load_dotenv\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'load_dotenv()\n'
          '\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 4',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON — project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 03',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 6',
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.agents.middleware import (\n'
          '    SummarizationMiddleware,\n'
          '    HumanInTheLoopMiddleware,\n'
          ')\n'
          '\n'
          'agent = create_agent(\n'
          '    model="gpt-5.4", tools=[],\n'
          '    middleware=[\n'
          '        SummarizationMiddleware(model="gpt-5.4-mini", trigger=("messages", 50)),\n'
          '        HumanInTheLoopMiddleware(interrupt_on={}),\n'
          '    ],\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 04',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 8',
  'code': 'from langchain.agents.middleware import SummarizationMiddleware\n'
          '\n'
          'summarizer = SummarizationMiddleware(\n'
          '    model="gpt-5.4-mini",\n'
          '    trigger=("tokens", 4000),\n'
          '    keep=("messages", 20),\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 05',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 10',
  'code': 'from langchain.agents.middleware import HumanInTheLoopMiddleware\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'hitl = HumanInTheLoopMiddleware(\n'
          '    interrupt_on={\n'
          '        "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},\n'
          '        "read_email": False,\n'
          '    }\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 06',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 11',
  'code': 'agent = create_agent(\n'
          '    model="gpt-5.4", tools=[],\n'
          '    checkpointer=InMemorySaver(),\n'
          '    middleware=[hitl],\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 07',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 12',
  'code': 'from langgraph.types import Command\n'
          '\n'
          '# result = agent.invoke(Command(resume="approve"), config=lf_config)\n'
          '# result = agent.invoke(Command(resume={"type": "edit", "args": {"to": "new@ex.com"}}), config=lf_config)\n'
          '# result = agent.invoke(Command(resume={"type": "reject", "reason": "필요 없음"}), config=lf_config)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 08',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 14',
  'code': 'from langchain.agents.middleware import ModelCallLimitMiddleware\n'
          '\n'
          'model_limit = ModelCallLimitMiddleware(\n'
          '    thread_limit=10,\n'
          '    run_limit=5,\n'
          '    exit_behavior="end",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 09',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 15',
  'code': 'from langchain.agents.middleware import ToolCallLimitMiddleware\n'
          '\n'
          '# 전역 제한\n'
          'global_tool_limit = ToolCallLimitMiddleware(thread_limit=20, run_limit=10)\n'
          '\n'
          '# 특정 도구 제한\n'
          'search_limit = ToolCallLimitMiddleware(\n'
          '    tool_name="search",\n'
          '    thread_limit=5, run_limit=3,\n'
          '    exit_behavior="continue",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 10',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 17',
  'code': 'from langchain.agents.middleware import ModelFallbackMiddleware\n'
          '\n'
          '# gpt-5.4 실패 -> gpt-5.4-mini -> claude\n'
          'fallback = ModelFallbackMiddleware(\n'
          '    "gpt-5.4-mini",\n'
          '    "claude-sonnet-4-6",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 11',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 19',
  'code': 'from langchain.agents.middleware import PIIMiddleware\n'
          '\n'
          'email_pii = PIIMiddleware("email", strategy="redact", apply_to_input=True)\n'
          'card_pii = PIIMiddleware("credit_card", strategy="mask", apply_to_input=True)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 12',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 20',
  'code': '# 커스텀 탐지기: 정규식 문자열\n'
          'api_key_pii = PIIMiddleware(\n'
          '    "api_key",\n'
          '    detector=r"sk-[a-zA-Z0-9]{32}",\n'
          '    strategy="block",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 13',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 21',
  'code': 'import re\n'
          '\n'
          '# 커스텀 탐지기: 컴파일된 정규식\n'
          'phone_pii = PIIMiddleware(\n'
          '    "phone_number",\n'
          '    detector=re.compile(r"\\+?\\d{1,3}[\\s.-]?\\d{3,4}[\\s.-]?\\d{4}"),\n'
          '    strategy="mask",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 14',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 22',
  'code': '# 커스텀 탐지기: 함수 (SSN 예시)\n'
          'def detect_ssn(content: str) -> list[dict]:\n'
          '    matches = []\n'
          '    for m in re.finditer(r"\\d{3}-\\d{2}-\\d{4}", content):\n'
          '        first = int(m.group(0)[:3])\n'
          '        if first not in [0, 666] and not (900 <= first <= 999):\n'
          '            matches.append({"text": m.group(0), "start": m.start(), "end": m.end()})\n'
          '    return matches\n'
          '\n'
          'ssn_pii = PIIMiddleware("ssn", detector=detect_ssn, strategy="hash")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 15',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 24',
  'code': 'from langchain.agents.middleware import LLMToolSelectorMiddleware\n'
          '\n'
          'tool_selector = LLMToolSelectorMiddleware(\n'
          '    model="gpt-5.4-mini",\n'
          '    max_tools=3,\n'
          '    always_include=["search"],\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 16',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 26',
  'code': '# AnthropicPromptCachingMiddleware — 긴 시스템 프롬프트/도구를 캐시 히트로\n'
          'from langchain_anthropic import ChatAnthropic\n'
          'from langchain_anthropic.middleware import AnthropicPromptCachingMiddleware\n'
          'from langchain.agents import create_agent\n'
          '\n'
          'cached_agent = create_agent(\n'
          '    model=ChatAnthropic(model="claude-sonnet-4-6"),\n'
          '    system_prompt="<긴 시스템 프롬프트>",\n'
          '    middleware=[AnthropicPromptCachingMiddleware(ttl="5m", min_messages_to_cache=0)],\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 17',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 27',
  'code': '# BedrockPromptCachingMiddleware — Bedrock 호스팅 Claude 동일 캐싱\n'
          'from langchain_aws import ChatBedrockConverse\n'
          'from langchain_aws.middleware.prompt_caching import BedrockPromptCachingMiddleware\n'
          '\n'
          'bedrock_agent = create_agent(\n'
          '    model=ChatBedrockConverse(model="us.anthropic.claude-sonnet-4-5-20250929-v1:0"),\n'
          '    system_prompt="<긴 시스템 프롬프트>",\n'
          '    middleware=[BedrockPromptCachingMiddleware(ttl="1h")],\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 18',
  'lead': '이 코드는 Deep Agent 생성과 하네스 옵션 연결을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 28',
  'code': '# PatchToolCallsMiddleware — 잘못된 도구 호출을 도구 노드 도달 전에 보정\n'
          'from deepagents.middleware.patch_tool_calls import PatchToolCallsMiddleware\n'
          '\n'
          'patched_agent = create_agent(\n'
          '    model="claude-sonnet-4-6",\n'
          '    tools=[],\n'
          '    middleware=[PatchToolCallsMiddleware()],\n'
          ')\n'
          '# 참고: create_deep_agent(...) 사용 시 기본 미들웨어 스택에 자동 포함'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 19',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 29',
  'code': '# ContextEditingMiddleware — 토큰 임계 도달 시 오래된 도구 출력을 placeholder로 교체\n'
          'from langchain.agents.middleware import ContextEditingMiddleware, ClearToolUsesEdit\n'
          '\n'
          'ctx_edit_agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[],\n'
          '    middleware=[\n'
          '        ContextEditingMiddleware(\n'
          '            edits=[ClearToolUsesEdit(trigger=100_000, keep=3)],\n'
          '        ),\n'
          '    ],\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 20',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 31',
  'code': 'from langchain.agents.middleware import before_model\n'
          '\n'
          '@before_model\n'
          'def log_before(state, runtime):\n'
          '    """모델 호출 전 메시지 수를 기록합니다."""\n'
          '    print(f"[LOG] 메시지 {len(state.get(\'messages\', []))}개")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 21',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 32',
  'code': 'from langchain.agents.middleware import after_model\n'
          '\n'
          '@after_model\n'
          'def validate_output(state, runtime):\n'
          '    """가드: 금지된 콘텐츠를 차단합니다."""\n'
          '    last = state["messages"][-1].content\n'
          '    if "FORBIDDEN" in last:\n'
          '        return {"jump_to": "end"}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 22',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 33',
  'code': 'from typing import Callable\n'
          'from langchain.agents.middleware import wrap_model_call, ModelRequest, ModelResponse\n'
          '\n'
          '@wrap_model_call\n'
          'def retry_on_error(\n'
          '    request: ModelRequest,\n'
          '    handler: Callable[[ModelRequest], ModelResponse],\n'
          ') -> ModelResponse:\n'
          '    """실패 시 모델 호출을 최대 2회 재시도합니다."""\n'
          '    for attempt in range(3):\n'
          '        try:\n'
          '            return handler(request)\n'
          '        except Exception:\n'
          '            if attempt == 2: raise'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 23',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 34',
  'code': '# wrap_tool_call — 도구 호출을 감싸 감사 로그/에러 변환\n'
          'from typing import Callable\n'
          'from langchain.agents.middleware import wrap_tool_call, ToolCallRequest\n'
          'from langchain.messages import ToolMessage\n'
          'from langgraph.types import Command\n'
          '\n'
          '@wrap_tool_call\n'
          'def audit_tool(\n'
          '    request: ToolCallRequest,\n'
          '    handler: Callable[[ToolCallRequest], ToolMessage | Command],\n'
          ') -> ToolMessage | Command:\n'
          '    """도구 호출 전후로 감사 로그를 남기고 예외를 ToolMessage 로 변환."""\n'
          '    name = request.tool_call["name"]\n'
          '    print(f"[AUDIT] tool={name} args={request.tool_call[\'args\']}")\n'
          '    try:\n'
          '        return handler(request)\n'
          '    except Exception as e:\n'
          '        return ToolMessage(\n'
          '            content=f"도구 오류: {e}",\n'
          '            tool_call_id=request.tool_call["id"],\n'
          '        )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 24',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 35',
  'code': '# request.override(...) — wrap_model_call 에서 모델/도구/시스템 프롬프트를 단일 호출 한정으로 교체\n'
          '@wrap_model_call\n'
          'def dynamic_config(\n'
          '    request: ModelRequest,\n'
          '    handler: Callable[[ModelRequest], ModelResponse],\n'
          ') -> ModelResponse:\n'
          '    """상태 기반으로 모델 호출 시 system_prompt 와 tools 를 동적으로 교체."""\n'
          '    if request.state.get("expert_mode"):\n'
          '        request = request.override(\n'
          '            system_prompt="당신은 시니어 분석가입니다.",\n'
          '            # tools=[...specialist_tools],\n'
          '        )\n'
          '    return handler(request)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 25',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 36',
  'code': '# @hook_config(can_jump_to=[...]) — after_model 에서 합법 점프 대상 선언\n'
          'from typing import Any\n'
          'from langchain.agents.middleware import after_model, hook_config, AgentState\n'
          'from langchain.messages import AIMessage\n'
          'from langgraph.runtime import Runtime\n'
          '\n'
          '@after_model\n'
          '@hook_config(can_jump_to=["end"])\n'
          'def block_forbidden(state: AgentState, runtime: Runtime) -> dict[str, Any] | None:\n'
          '    last = state["messages"][-1]\n'
          '    if "BLOCKED" in getattr(last, "content", ""):\n'
          '        return {\n'
          '            "messages": [AIMessage("요청에 응답할 수 없습니다.")],\n'
          '            "jump_to": "end",\n'
          '        }\n'
          '    return None'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 26',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 37',
  'code': '# ExtendedModelResponse — wrap_model_call 에서 모델 응답 + 영구 상태 업데이트를 함께 반환\n'
          'from langchain.agents.middleware import ExtendedModelResponse\n'
          '\n'
          '@wrap_model_call\n'
          'def track_tokens(\n'
          '    request: ModelRequest,\n'
          '    handler: Callable[[ModelRequest], ModelResponse],\n'
          ') -> ExtendedModelResponse:\n'
          '    response = handler(request)\n'
          '    return ExtendedModelResponse(\n'
          '        model_response=response,\n'
          '        command=Command(update={"last_model_call_tokens": 150}),\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 27',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 38',
  'code': 'from langchain.agents.middleware import AgentMiddleware\n'
          '\n'
          'class AuditMiddleware(AgentMiddleware):\n'
          '    def __init__(self, log_file="audit.log"):\n'
          '        self.log_file = log_file\n'
          '    def before_model(self, state, config):\n'
          '        print(f"[AUDIT] before -> {self.log_file}")\n'
          '    def after_model(self, state, config):\n'
          '        print(f"[AUDIT] after -> {self.log_file}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 28',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 40',
  'code': '@before_model\n'
          'def mw_a(state, runtime): print("before A")\n'
          '\n'
          '@before_model\n'
          'def mw_b(state, runtime): print("before B")\n'
          '\n'
          '@before_model\n'
          'def mw_c(state, runtime): print("before C")\n'
          '\n'
          '# 실행: A -> B -> C (after_model이면 C -> B -> A)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 29',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 42',
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.agents.middleware import (\n'
          '    PIIMiddleware, ModelFallbackMiddleware,\n'
          '    ModelCallLimitMiddleware, SummarizationMiddleware,\n'
          '    HumanInTheLoopMiddleware, LLMToolSelectorMiddleware,\n'
          '    ContextEditingMiddleware, ClearToolUsesEdit,\n'
          ')\n'
          'from deepagents.middleware.patch_tool_calls import PatchToolCallsMiddleware\n'
          'from langgraph.checkpoint.memory import InMemorySaver'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 01_middleware',
  'title': '01_middleware 코드 30',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '01_middleware.ipynb',
  'note': 'cell 43',
  'code': 'middleware_stack = [\n'
          '    PIIMiddleware("email", strategy="redact", apply_to_input=True),\n'
          '    PatchToolCallsMiddleware(),\n'
          '    ModelFallbackMiddleware("gpt-5.4-mini", "claude-sonnet-4-6"),\n'
          '    ModelCallLimitMiddleware(thread_limit=50, run_limit=10),\n'
          '    ContextEditingMiddleware(edits=[ClearToolUsesEdit(trigger=100_000, keep=3)]),\n'
          '    SummarizationMiddleware(model="gpt-5.4-mini", trigger=("fraction", 0.8)),\n'
          ']\n'
          '\n'
          'production_agent = create_agent(\n'
          '    model="gpt-5.4", tools=[], checkpointer=InMemorySaver(), middleware=middleware_stack,\n'
          ')'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '02_multi_agent_subagents.ipynb',
  'sub': '02_multi_agent_subagents.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/02_multi_agent_subagents.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 3',
  'code': 'from dotenv import load_dotenv\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'load_dotenv()\n'
          '\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 4',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON — project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 7',
  'code': 'from langchain_core.tools import tool\n'
          '\n'
          '@tool\n'
          'def create_calendar_event(\n'
          '    title: str, start_time: str, end_time: str,\n'
          '    attendees: list[str] = None,\n'
          ') -> str:\n'
          '    """새 캘린더 이벤트를 생성합니다."""\n'
          '    return f"이벤트 \'{title}\' 생성됨: {start_time} ~ {end_time}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 04',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 8',
  'code': '@tool\n'
          'def read_calendar_events(date: str) -> str:\n'
          '    """날짜(YYYY-MM-DD)의 캘린더 이벤트를 조회합니다."""\n'
          '    return f"{date}에 이벤트가 없습니다."'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 05',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 9',
  'code': '@tool\n'
          'def send_email(to: str, subject: str, body: str) -> str:\n'
          '    """이메일 메시지를 전송합니다."""\n'
          '    return f"{to}에게 이메일 전송됨: \'{subject}\'"\n'
          '\n'
          '@tool\n'
          'def read_emails(folder: str = "inbox", limit: int = 10) -> str:\n'
          '    """폴더에서 최근 이메일을 읽습니다."""\n'
          '    return f"{folder}에 이메일 3개"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 06',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 10',
  'code': '@tool\n'
          'def search_emails(query: str, limit: int = 10) -> str:\n'
          '    """검색어로 이메일을 검색합니다."""\n'
          '    return f"\'{query}\' 검색 결과 2건"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 07',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 12',
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'calendar_agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[create_calendar_event, read_calendar_events],\n'
          '    system_prompt="당신은 캘린더 어시스턴트입니다. ISO 8601 날짜 형식을 사용하세요.",\n'
          '    name="calendar_agent",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 08',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 13',
  'code': 'email_agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[send_email, read_emails, search_emails],\n'
          '    system_prompt="당신은 이메일 어시스턴트입니다. 메시지를 전문적으로 작성하세요.",\n'
          '    name="email_agent",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 09',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 15',
  'code': '@tool("schedule_event", description="캘린더 이벤트 예약")\n'
          'def call_calendar(query: str) -> str:\n'
          '    """캘린더 작업을 캘린더 에이전트에 위임합니다."""\n'
          '    result = calendar_agent.invoke(\n'
          '        {"messages": [{"role": "user", "content": query}]},\n'
          '        config=lf_config,\n'
          ')\n'
          '    return result["messages"][-1].content'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 10',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 16',
  'code': '@tool("manage_email", description="이메일 전송, 읽기, 검색")\n'
          'def call_email(query: str) -> str:\n'
          '    """이메일 작업을 이메일 에이전트에 위임합니다."""\n'
          '    result = email_agent.invoke(\n'
          '        {"messages": [{"role": "user", "content": query}]},\n'
          '        config=lf_config,\n'
          ')\n'
          '    return result["messages"][-1].content'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 11',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 18',
  'code': 'supervisor = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[call_calendar, call_email],\n'
          '    system_prompt=(\n'
          '        "당신은 개인 비서입니다. 복잡한 요청을 "\n'
          '        "하위 작업으로 분해하고 적절한 에이전트에 위임하세요."\n'
          '    ),\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 12',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 20',
  'code': '# response = supervisor.invoke({\n'
          '#     "messages": [{"role": "user",\n'
          '#         "content": "내일 2시에 Sarah와 미팅 잡고 "\n'
          '#                    "초대 이메일 보내줘."}]\n'
          '# }, config=lf_config)\n'
          '# print(response["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 13',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 22',
  'code': 'from langchain.agents.middleware import HumanInTheLoopMiddleware\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'hitl = HumanInTheLoopMiddleware(interrupt_on={\n'
          '    "schedule_event": {"allowed_decisions": ["approve", "edit", "reject"]},\n'
          '    "manage_email": {"allowed_decisions": ["approve", "reject"]},\n'
          '})'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 14',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 23',
  'code': 'supervisor_hitl = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[call_calendar, call_email],\n'
          '    checkpointer=InMemorySaver(),\n'
          '    middleware=[hitl],\n'
          '    system_prompt="당신은 개인 비서입니다.",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 15',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 24',
  'code': 'from langgraph.types import Command\n'
          '\n'
          '# result = supervisor_hitl.invoke(Command(resume="approve"), config=lf_config)\n'
          '# result = supervisor_hitl.invoke(Command(resume={"type": "reject", "reason": "마음이 바뀌었습니다"}), '
          'config=lf_config)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 16',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 26',
  'code': 'from dataclasses import dataclass\n'
          'from langchain.tools import tool, ToolRuntime\n'
          'from langchain.agents import AgentState, create_agent\n'
          '\n'
          '@dataclass\n'
          'class UserContext:\n'
          '    user_email: str\n'
          '    user_name: str\n'
          '    timezone: str\n'
          '\n'
          'class SupervisorState(AgentState):\n'
          '    # 부모 에이전트가 보유한 추가 상태 키 예시\n'
          '    user_id: str'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 17',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 27',
  'code': 'supervisor_ctx = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[call_calendar, call_email],\n'
          '    system_prompt="당신은 개인 비서입니다.",\n'
          '    context_schema=UserContext,\n'
          '    state_schema=SupervisorState,\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 18',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 28',
  'code': '# 도구에서 부모 상태 + 컨텍스트 동시 접근\n'
          '@tool\n'
          'def send_email_ctx(\n'
          '    to: str, subject: str, body: str,\n'
          '    runtime: ToolRuntime[UserContext, SupervisorState],\n'
          ') -> str:\n'
          '    """현재 사용자로 이메일을 전송합니다."""\n'
          '    sender = runtime.context.user_email\n'
          '    user_id = runtime.state.get("user_id", "anon")\n'
          '    return f"[{user_id}] {sender}에서 {to}로 이메일 전송: \'{subject}\'"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 19 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 30',
  'code': 'import uuid\n'
          'from datetime import datetime\n'
          '\n'
          'job_store: dict[str, dict] = {}\n'
          '\n'
          '@tool("start_async_task", description="서브에이전트 백그라운드 기동, task id 반환")\n'
          'def start_async_task(agent_name: str, instruction: str) -> str:\n'
          '    """비동기 서브에이전트 작업을 시작하고 task id를 반환합니다."""\n'
          '    task_id = "task_" + uuid.uuid4().hex[:12]\n'
          '    job_store[task_id] = {\n'
          '        "agent": agent_name,\n'
          '        "status": "running",\n'
          '        "instruction": instruction,\n'
          '        "result": None,\n'
          '        "created_at": datetime.utcnow().isoformat(),\n'
          '    }\n'
          '    return f"started {task_id} (agent={agent_name})"\n'
          '\n'
          '@tool("check_async_task", description="task 상태 조회 / 완료 시 결과 추출")\n'
          'def check_async_task(task_id: str) -> str:\n'
          '    job = job_store.get(task_id)\n'
          '    if not job:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 19 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 30',
  'code': '        return f"not_found: {task_id}"\n'
          '    # 학습용 스텁: 한 번 호출되면 완료로 표시\n'
          '    if job["status"] == "running":\n'
          '        job["status"] = "success"\n'
          '        job["result"] = f"{job[\'agent\']} 결과: {job[\'instruction\'][:60]}"\n'
          '    return f"{task_id} status={job[\'status\']} result={job.get(\'result\')!r}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 20 (1/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 31',
  'code': '@tool("update_async_task", description="실행 중 task 에 follow-up 지시 주입")\n'
          'def update_async_task(task_id: str, instruction: str) -> str:\n'
          '    job = job_store.get(task_id)\n'
          '    if not job:\n'
          '        return f"not_found: {task_id}"\n'
          '    job["instruction"] = instruction\n'
          '    job["status"] = "running"   # interrupt 기반 재기동\n'
          '    return f"updated {task_id} with new instruction"\n'
          '\n'
          '@tool("cancel_async_task", description="task 취소")\n'
          'def cancel_async_task(task_id: str) -> str:\n'
          '    job = job_store.get(task_id)\n'
          '    if not job:\n'
          '        return f"not_found: {task_id}"\n'
          '    job["status"] = "cancelled"\n'
          '    return f"cancelled {task_id}"\n'
          '\n'
          '@tool("list_async_tasks", description="추적 중 task 일괄 조회")\n'
          'def list_async_tasks() -> str:\n'
          '    if not job_store:\n'
          '        return "no tasks"\n'
          '    return "\\n".join('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 20 (2/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 31',
  'code': '        f"{tid} agent={j[\'agent\']} status={j[\'status\']}"\n'
          '        for tid, j in job_store.items()\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 21',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 33',
  'code': 'from typing import Literal\n'
          '\n'
          'AGENT_REGISTRY = {"calendar": calendar_agent, "email": email_agent}\n'
          '\n'
          '@tool("delegate", description="전문 에이전트에 위임")\n'
          'def dispatch(agent_name: Literal["calendar", "email"], query: str) -> str:\n'
          '    """지정된 서브에이전트에 작업을 라우팅합니다."""\n'
          '    agent = AGENT_REGISTRY[agent_name]\n'
          '    result = agent.invoke({"messages": [{"role": "user", "content": query}]}, config=lf_config)\n'
          '    return result["messages"][-1].content'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 22',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 34',
  'code': 'supervisor_dispatch = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[dispatch],\n'
          '    system_prompt=(\n'
          '        "delegate 도구를 사용하여 작업을 라우팅하세요. "\n'
          '        "에이전트: \'calendar\'(일정), \'email\'(이메일)."\n'
          '    ),\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 23 (1/2)',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 35',
  'code': '# Deep Agents — SubAgentMiddleware 로 일괄 등록 (수동 @tool 래핑 불필요)\n'
          'from deepagents.middleware.subagents import SubAgentMiddleware\n'
          '\n'
          'supervisor_dag = create_agent(\n'
          '    model="claude-sonnet-4-6",\n'
          '    middleware=[\n'
          '        SubAgentMiddleware(\n'
          '            backend=StateBackend(),\n'
          '            subagents=[\n'
          '                {\n'
          '                    "name": "calendar",\n'
          '                    "description": "캘린더 이벤트 생성/조회",\n'
          '                    "system_prompt": "당신은 캘린더 어시스턴트입니다. ISO 8601 사용.",\n'
          '                    "tools": [create_calendar_event, read_calendar_events],\n'
          '                    "model": "claude-sonnet-4-6",\n'
          '                },\n'
          '                {\n'
          '                    "name": "email",\n'
          '                    "description": "이메일 전송/읽기/검색",\n'
          '                    "system_prompt": "당신은 이메일 어시스턴트입니다.",\n'
          '                    "tools": [send_email, read_emails, search_emails],\n'
          '                    "model": "gpt-5.4",   # 서브에이전트별 모델 오버라이드'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 02_multi_agent_subagents',
  'title': '02_multi_agent_subagents 코드 23 (2/2)',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '02_multi_agent_subagents.ipynb',
  'note': 'cell 35',
  'code': '                },\n'
          '            ],\n'
          '        ),\n'
          '    ],\n'
          ')\n'
          '# 감독자는 자동 주입된 `task(subagent_name, instruction)` 도구로 위임'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '03_multi_agent_handoffs_router.ipynb',
  'sub': '03_multi_agent_handoffs_router.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/03_multi_agent_handoffs_router.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'load_dotenv()\n'
          '\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON — project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 8',
  'code': 'from langchain.agents import AgentState\n'
          'from typing import Literal\n'
          '\n'
          'class SupportState(AgentState):\n'
          '    current_step: Literal[\n'
          '        "identify_customer", "diagnose_issue",\n'
          '        "resolve_issue", "close_ticket",\n'
          '    ] = "identify_customer"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 04',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 10',
  'code': 'from langchain_core.tools import tool\n'
          'from langgraph.types import Command\n'
          '\n'
          '# --- Identify Customer ---\n'
          '@tool\n'
          'def lookup_customer(email: str) -> Command:\n'
          '    """이메일로 고객을 조회합니다."""\n'
          '    return Command(\n'
          '        update={"customer": {"name": "Alice", "id": "C-1234"}, "current_step": "diagnose_issue"},\n'
          '        result="고객 찾음: Alice (C-1234). 진단 단계로 이동합니다.",\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 05',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 11',
  'code': '# --- Diagnose Issue ---\n'
          '@tool\n'
          'def check_service_status(service_name: str) -> str:\n'
          '    """서비스의 현재 상태를 확인합니다."""\n'
          '    return f"서비스 \'{service_name}\': 정상 (99.9% 가동률)"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 06',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 12',
  'code': '@tool\n'
          'def escalate_to_resolve(diagnosis: str) -> Command:\n'
          '    """진단 후 해결 단계로 이동합니다."""\n'
          '    return Command(\n'
          '        update={"diagnosis": diagnosis, "current_step": "resolve_issue"},\n'
          '        result=f"진단 완료: {diagnosis}. 해결 단계로 이동합니다.",\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 07',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 13',
  'code': '# --- Resolve Issue ---\n'
          '@tool\n'
          'def apply_fix(fix_type: str, customer_id: str) -> Command:\n'
          '    """고객 계정에 수정 사항을 적용합니다."""\n'
          '    return Command(\n'
          '        update={"resolution": {"type": fix_type}},\n'
          '        result=f"수정 적용됨: {customer_id}에 {fix_type}",\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 08',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 14',
  'code': '@tool\n'
          'def mark_resolved(summary: str) -> Command:\n'
          '    """이슈를 해결 완료로 표시하고 종료 단계로 이동합니다."""\n'
          '    return Command(\n'
          '        update={"current_step": "close_ticket", "resolution_summary": summary},\n'
          '        result="해결됨. 종료 단계로 이동합니다.",\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 09',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 15',
  'code': '# 정식 핸드오프 시그니처 — ToolRuntime.tool_call_id 를 ToolMessage 에 echo\n'
          'from langchain.tools import ToolRuntime\n'
          'from langchain.messages import ToolMessage\n'
          '\n'
          '@tool\n'
          'def transfer_to_resolve(\n'
          '    diagnosis: str,\n'
          '    runtime: ToolRuntime[None, SupportState],\n'
          ') -> Command:\n'
          '    """진단 후 해결 단계로 이동 (tool_call_id echo 패턴)."""\n'
          '    return Command(update={\n'
          '        "current_step": "resolve_issue",\n'
          '        "diagnosis": diagnosis,\n'
          '        "messages": [ToolMessage(\n'
          '            content=f"진단 완료: {diagnosis}. 해결 단계로 이동합니다.",\n'
          '            tool_call_id=runtime.tool_call_id,\n'
          '        )],\n'
          '    })'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 10',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 16',
  'code': '# --- Close Ticket ---\n'
          '@tool\n'
          'def send_satisfaction_survey(customer_id: str) -> str:\n'
          '    """만족도 설문을 전송합니다."""\n'
          '    return "설문 전송 완료."\n'
          '\n'
          '@tool\n'
          'def close_ticket(ticket_id: str, notes: str) -> str:\n'
          '    """지원 티켓을 종료합니다."""\n'
          '    return f"티켓 {ticket_id} 종료됨."'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 11',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 18',
  'code': 'STEP_CONFIG = {\n'
          '    "identify_customer": {\n'
          '        "tools": [lookup_customer],\n'
          '        "system_prompt": "고객을 식별하세요. 이메일 또는 계정 ID를 요청하세요.",\n'
          '    },\n'
          '    "diagnose_issue": {\n'
          '        "tools": [check_service_status, escalate_to_resolve],\n'
          '        "system_prompt": "이슈를 진단하세요. 도구를 사용한 후 escalate_to_resolve를 호출하세요.",\n'
          '    },\n'
          '}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 12',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 19',
  'code': 'STEP_CONFIG["resolve_issue"] = {\n'
          '    "tools": [apply_fix, mark_resolved],\n'
          '    "system_prompt": "이슈를 해결하세요. 수정을 적용한 후 mark_resolved를 호출하세요.",\n'
          '}\n'
          'STEP_CONFIG["close_ticket"] = {\n'
          '    "tools": [send_satisfaction_survey, close_ticket],\n'
          '    "system_prompt": "고객에게 감사를 전하고, 설문을 보내고, 티켓을 종료하세요.",\n'
          '}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 13',
  'lead': '이 코드는 미들웨어 훅과 실행 정책 삽입 지점을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 20',
  'code': 'from typing import Callable\n'
          'from langchain.agents.middleware import wrap_model_call, ModelRequest, ModelResponse\n'
          '\n'
          '@wrap_model_call\n'
          'def step_middleware(\n'
          '    request: ModelRequest,\n'
          '    handler: Callable[[ModelRequest], ModelResponse],\n'
          ') -> ModelResponse:\n'
          '    """current_step 에 따라 system_prompt 와 tools 를 단일 호출 한정으로 교체."""\n'
          '    step = request.state.get("current_step", "identify_customer")\n'
          '    cfg = STEP_CONFIG[step]\n'
          '    request = request.override(\n'
          '        system_prompt=cfg["system_prompt"],\n'
          '        tools=cfg["tools"],\n'
          '    )\n'
          '    return handler(request)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 14',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 22',
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'all_tools = [\n'
          '    lookup_customer, check_service_status,\n'
          '    escalate_to_resolve, apply_fix, mark_resolved,\n'
          '    send_satisfaction_survey, close_ticket,\n'
          ']\n'
          'support_agent = create_agent(\n'
          '    model="gpt-5.4", tools=all_tools,\n'
          '    state_schema=SupportState, middleware=[step_middleware],\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 15',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 23',
  'code': '# [identify_customer]\n'
          '#   User: "Can\'t log in. Email: alice@example.com"\n'
          '#   Agent -> lookup_customer("alice@example.com")\n'
          '#        <- Command(update={current_step: "diagnose_issue"})\n'
          '#\n'
          '# [diagnose_issue] (auto transition)\n'
          '#   Agent -> check_service_status("auth-service")\n'
          '#   Agent -> escalate_to_resolve("Locked out")\n'
          '#\n'
          '# [resolve_issue] -> [close_ticket]'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 16',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 27',
  'code': 'from pydantic import BaseModel, Field\n'
          'from typing import Literal\n'
          '\n'
          'class SubQuery(BaseModel):\n'
          '    """소스별 하위 쿼리."""\n'
          '    source: Literal["github", "notion", "slack"] = Field(description="지식 소스.")\n'
          '    query: str = Field(description="해당 소스에 최적화된 검색 쿼리.")\n'
          '\n'
          'class QueryClassification(BaseModel):\n'
          '    """사용자 쿼리의 분류 결과."""\n'
          '    sources: list[Literal["github", "notion", "slack"]] = Field(\n'
          '        description="관련 지식 소스."\n'
          '    )\n'
          '    reasoning: str = Field(description="해당 소스를 선택한 이유.")\n'
          '    sub_queries: list[SubQuery] = Field(description="소스별 하위 쿼리.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 17',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 28',
  'code': 'from langchain.agents import AgentState\n'
          '\n'
          'class RouterState(AgentState):\n'
          '    classification: QueryClassification = None\n'
          '    sources: list[str] = []\n'
          '    sub_queries: list[SubQuery] = []\n'
          '    agent_results: list[dict] = []'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 18',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 30',
  'code': 'from langchain_openai import ChatOpenAI\n'
          '\n'
          'classifier = ChatOpenAI(model="gpt-5.4").with_structured_output(\n'
          '    QueryClassification\n'
          ')\n'
          '\n'
          'def route_query(state):\n'
          '    """쿼리를 분류하고 라우팅을 결정합니다."""\n'
          '    msg = state["messages"][-1].content\n'
          '    cls = classifier.invoke(f"분류하고 하위 쿼리를 생성하세요:\\n\\n{msg}", config=lf_config)\n'
          '    sq_dict = {sq.source: sq.query for sq in cls.sub_queries}\n'
          '    return {"classification": cls, "sources": cls.sources, "sub_queries": cls.sub_queries}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 19',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 32',
  'code': 'from langchain_core.tools import tool\n'
          'from langchain.agents import create_agent\n'
          '\n'
          '@tool\n'
          'def search_github_code(query: str) -> str:\n'
          '    """GitHub 저장소를 검색합니다."""\n'
          '    return f"\'{query}\'에 대한 GitHub 결과"\n'
          '\n'
          '@tool\n'
          'def search_notion_pages(query: str) -> str:\n'
          '    """Notion 워크스페이스를 검색합니다."""\n'
          '    return f"\'{query}\'에 대한 Notion 결과"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 20',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 33',
  'code': '@tool\n'
          'def search_slack_messages(query: str) -> str:\n'
          '    """Slack 메시지를 검색합니다."""\n'
          '    return f"\'{query}\'에 대한 Slack 결과"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 21',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 34',
  'code': 'github_agent = create_agent(\n'
          '    model="gpt-5.4", tools=[search_github_code],\n'
          '    system_prompt="GitHub에서 코드와 PR을 검색합니다.",\n'
          '    name="github_agent",\n'
          ')\n'
          'notion_agent = create_agent(\n'
          '    model="gpt-5.4", tools=[search_notion_pages],\n'
          '    system_prompt="Notion에서 문서를 검색합니다.",\n'
          '    name="notion_agent",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 22',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 35',
  'code': 'slack_agent = create_agent(\n'
          '    model="gpt-5.4", tools=[search_slack_messages],\n'
          '    system_prompt="Slack에서 토론을 검색합니다.",\n'
          '    name="slack_agent",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 23',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 36',
  'code': 'from langgraph.types import Command, Send\n'
          '\n'
          'def dispatch_to_agents(state):\n'
          '    """하위 쿼리를 에이전트들에게 병렬로 전달합니다 (Send fan-out)."""\n'
          '    cls = state["classification"]\n'
          '    sq_dict = {sq.source: sq.query for sq in cls.sub_queries}\n'
          '    return [\n'
          '        Send(\n'
          '            src,\n'
          '            {\n'
          '                "messages": [{"role": "user", "content": sq_dict.get(src, "")}],\n'
          '                "source": src,\n'
          '            },\n'
          '        )\n'
          '        for src in cls.sources\n'
          '    ]'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 24',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 38',
  'code': 'def reduce_results(state):\n'
          '    """모든 에이전트의 결과를 집계합니다."""\n'
          '    results = state.get("agent_results", [])\n'
          '    formatted = "\\n".join(f"[{r[\'source\']}] {r[\'content\']}" for r in results)\n'
          '    prompt = f"일관된 답변으로 합성하세요. 출처를 인용하세요.\\n\\n{formatted}"\n'
          '    resp = ChatOpenAI(model="gpt-5.4").invoke(prompt, config=lf_config)\n'
          '    return {"messages": [{"role": "assistant", "content": resp.content}]}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 25',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 39',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          '\n'
          'graph = StateGraph(RouterState)\n'
          'graph.add_node("router", route_query)\n'
          'graph.add_node("github", github_agent)\n'
          'graph.add_node("notion", notion_agent)\n'
          'graph.add_node("slack", slack_agent)\n'
          'graph.add_node("reducer", reduce_results)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 26',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 40',
  'code': 'graph.add_edge(START, "router")\n'
          'graph.add_conditional_edges("router", dispatch_to_agents)\n'
          'graph.add_edge("github", "reducer")\n'
          'graph.add_edge("notion", "reducer")\n'
          'graph.add_edge("slack", "reducer")\n'
          'graph.add_edge("reducer", END)\n'
          '\n'
          'app = graph.compile()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 03_multi_agent_handoffs_router',
  'title': '03_multi_agent_handoffs_router 코드 27',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_multi_agent_handoffs_router.ipynb',
  'note': 'cell 41',
  'code': 'response = app.invoke({\n'
          '    "messages": [{"role": "user",\n'
          '        "content": "결제 서비스를 어떻게 배포하나요?"}]\n'
          '}, config=lf_config)\n'
          'print(response["messages"][-1].content)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '04_context_memory.ipynb',
  'sub': '04_context_memory.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/04_context_memory.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI, OpenAIEmbeddings\n'
          '\n'
          'model = ChatOpenAI(model="gpt-5.4")\n'
          'embeddings = OpenAIEmbeddings(model="text-embedding-3-small")\n'
          'print("환경 준비 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON \\u2014 project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON \\u2014 {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 03',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 8',
  'code': 'from dataclasses import dataclass\n'
          'from langchain.tools import tool, ToolRuntime\n'
          'from langchain.agents import create_agent\n'
          '\n'
          '@dataclass\n'
          'class UserContext:\n'
          '    user_id: str\n'
          '    role: str\n'
          '    department: str'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 04',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 9',
  'code': '@tool\n'
          'def get_permissions(runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """현재 사용자의 역할에 따른 권한을 조회합니다."""\n'
          '    ctx = runtime.context\n'
          '    perms = {"admin": "read,write,delete", "editor": "read,write"}\n'
          '    return f"사용자 {ctx.user_id} ({ctx.department}): {perms.get(ctx.role, \'read\')}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 05',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 10',
  'code': 'agent = create_agent(\n'
          '    model=model, tools=[get_permissions], context_schema=UserContext,\n'
          ')\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "제 권한이 어떻게 되나요?"}]},\n'
          '    context=UserContext(user_id="u42", role="admin", department="eng"),\n'
          '    config=lf_config,\n'
          ')\n'
          'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 06',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 13',
  'code': 'from langchain.agents import AgentState\n'
          '\n'
          'class RAGState(AgentState):\n'
          '    """동적 검색 컨텍스트를 포함한 상태."""\n'
          '    retrieved_docs: list[str]\n'
          '    query_count: int\n'
          '\n'
          'print(f"상태 키: {list(RAGState.__annotations__.keys())}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 07',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 14',
  'code': 'agent_with_state = create_agent(\n'
          '    model=model, tools=[get_permissions],\n'
          '    state_schema=RAGState, context_schema=UserContext,\n'
          ')\n'
          'result = agent_with_state.invoke(\n'
          '    {"messages": [{"role": "user", "content": "안녕하세요!"}],\n'
          '     "retrieved_docs": [], "query_count": 0},\n'
          '    context=UserContext(user_id="u1", role="editor", department="sales"),\n'
          '    config=lf_config,\n'
          ')\n'
          'print(f"최종 상태 키: {list(result.keys())}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 08',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 17',
  'code': '# execution_info / server_info 노출 패턴\n'
          '@tool\n'
          'def whoami(runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """현재 run 의 identity 와 서버 메타데이터를 한 줄로 요약."""\n'
          '    info = runtime.execution_info\n'
          '    parts = [\n'
          '        f"thread={info.thread_id}",\n'
          '        f"run={info.run_id}",\n'
          '        f"attempt={info.node_attempt}",\n'
          '    ]\n'
          '    server = runtime.server_info\n'
          '    if server is not None:\n'
          '        parts.append(f"assistant={server.assistant_id}")\n'
          '        parts.append(f"graph={server.graph_id}")\n'
          '        if server.user is not None:\n'
          '            parts.append(f"user={server.user.identity}")\n'
          '    else:\n'
          '        parts.append("env=local")\n'
          '    return " | ".join(parts)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 09',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 19',
  'code': 'from langgraph.store.memory import InMemoryStore\n'
          '\n'
          'store = InMemoryStore()\n'
          'user_id = "user_42"\n'
          'store.put((user_id, "preferences"), "theme", {"value": "dark"})\n'
          'store.put((user_id, "preferences"), "language", {"value": "ko"})\n'
          '\n'
          'item = store.get((user_id, "preferences"), "theme")\n'
          'print(f"테마: {item.value}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 10',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 20',
  'code': 'items = store.search((user_id, "preferences"))\n'
          'for item in items:\n'
          '    print(f"  [{item.key}] = {item.value}")\n'
          '\n'
          'filtered = store.search(\n'
          '    (user_id, "preferences"), filter={"value": "dark"}\n'
          ')\n'
          'print(f"필터 결과: {len(filtered)}건")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 11',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 22',
  'code': 'semantic_store = InMemoryStore(\n'
          '    index={"embed": embeddings, "dims": 1536}\n'
          ')\n'
          'ns = ("user_42", "memories")\n'
          'semantic_store.put(ns, "mem1", {"content": "pytest를 unittest보다 선호"})\n'
          'semantic_store.put(ns, "mem2", {"content": "모든 함수에 타입 힌트 사용"})\n'
          'semantic_store.put(ns, "mem3", {"content": "좋아하는 음식은 초밥"})\n'
          'semantic_store.put(ns, "mem4", {"content": "ML 인프라 팀에서 근무"})\n'
          'print("임베딩과 함께 메모리 4개 저장 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 12',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 23',
  'code': 'results = semantic_store.search(\n'
          '    ("user_42", "memories"), query="testing preferences", limit=2\n'
          ')\n'
          'for r in results:\n'
          '    print(f"  [{r.key}] {r.value[\'content\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 13',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 24',
  'code': 'results2 = semantic_store.search(\n'
          '    ("user_42", "memories"), query="machine learning work", limit=2\n'
          ')\n'
          'for r in results2:\n'
          '    print(f"  [{r.key}] {r.value[\'content\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 14',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 27',
  'code': '@tool\n'
          'def get_user_info(runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """현재 사용자의 저장된 정보를 조회합니다."""\n'
          '    store = runtime.store\n'
          '    user_id = runtime.context.user_id\n'
          '    info = store.get(("users",), user_id)\n'
          '    return str(info.value) if info else "사용자 정보를 찾을 수 없습니다."'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 15',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 28',
  'code': '@tool\n'
          'def save_preference(key: str, value: str, runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """사용자 선호도를 저장합니다."""\n'
          '    store = runtime.store\n'
          '    user_id = runtime.context.user_id\n'
          '    store.put((user_id, "preferences"), key, {"value": value})\n'
          '    return f"선호도 저장됨: {key}={value}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 16',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 29',
  'code': 'memory_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[get_user_info, save_preference],\n'
          '    context_schema=UserContext,\n'
          '    store=semantic_store,\n'
          ')\n'
          'result = memory_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "테마를 다크로 저장해 주세요"}]},\n'
          '    context=UserContext(user_id="u42", role="admin", department="eng"),\n'
          '    config=lf_config,\n'
          ')\n'
          'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 17',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 30',
  'code': '# TypedDict 입력을 store 에 저장할 때 dict() 캐스트 — runtime.context.user_id 를 namespace 에 사용\n'
          'from typing_extensions import TypedDict\n'
          '\n'
          'class UserInfo(TypedDict):\n'
          '    name: str\n'
          '    language: str\n'
          '\n'
          '@tool\n'
          'def save_user_info(user_info: UserInfo, runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """사용자 프로필을 저장합니다. TypedDict → dict 캐스트 필수."""\n'
          '    assert runtime.store is not None\n'
          '    runtime.store.put(("users",), runtime.context.user_id, dict(user_info))\n'
          '    return f"saved user_info for {runtime.context.user_id}"\n'
          '\n'
          '@tool\n'
          'def get_user_info_typed(runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """저장된 프로필을 조회합니다."""\n'
          '    assert runtime.store is not None\n'
          '    item = runtime.store.get(("users",), runtime.context.user_id)\n'
          '    return str(item.value) if item else "Unknown user"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 18',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 32',
  'code': 'mem_store = InMemoryStore(index={"embed": embeddings, "dims": 1536})\n'
          'uid = "user_42"\n'
          '\n'
          '# Semantic -- Profile (single JSON)\n'
          'mem_store.put((uid, "profile"), "main", {\n'
          '    "name": "Alice", "language": "Python",\n'
          '    "preferred_style": "concise",\n'
          '})\n'
          '# Semantic -- Collection (multiple docs)\n'
          'mem_store.put((uid, "facts"), "f1", {"content": "pytest 선호"})'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 19',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 33',
  'code': '# Episodic -- past experiences (few-shot)\n'
          'mem_store.put((uid, "episodes"), "ep1", {\n'
          '    "content": "SQL 최적화 -> EXPLAIN ANALYZE 사용",\n'
          '})\n'
          '\n'
          '# Procedural -- rules/guidelines\n'
          'mem_store.put((uid, "procedures"), "rules", {\n'
          '    "content": "항상 에러 처리를 포함. logging 사용.",\n'
          '})\n'
          'print("3가지 메모리 유형 모두 저장 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 20',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 34',
  'code': '# Episodic search: find similar past experiences\n'
          'episodes = mem_store.search(\n'
          '    (uid, "episodes"), query="database query help", limit=1\n'
          ')\n'
          'for ep in episodes:\n'
          '    print(f"관련 에피소드: {ep.value[\'content\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 21',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 36',
  'code': 'skills = [\n'
          '    {"name": "db_overview",\n'
          '     "description": "모든 테이블의 고수준 개요",\n'
          '     "content": "테이블: customers, orders, products"},\n'
          '    {"name": "customers_schema",\n'
          '     "description": "customers 테이블의 전체 스키마",\n'
          '     "content": "CREATE TABLE customers (id INT PK, name VARCHAR)"},\n'
          ']\n'
          'SKILL_MAP = {s["name"]: s for s in skills}\n'
          'print(f"스킬 {len(skills)}개 정의됨.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 22',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 37',
  'code': 'from langchain_core.tools import tool\n'
          '\n'
          '@tool\n'
          'def load_skill(skill_name: str) -> str:\n'
          '    """데이터베이스 스킬에 대한 상세 정보를 로드합니다."""\n'
          '    skill = SKILL_MAP.get(skill_name)\n'
          '    if skill is None:\n'
          '        return f"찾을 수 없음. 사용 가능: {\', \'.join(SKILL_MAP.keys())}"\n'
          '    return f"## {skill[\'name\']}\\n\\n{skill[\'content\']}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 23',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 40',
  'code': 'from langgraph.store.base import BaseStore\n'
          '\n'
          '# Hot path: write inline (adds latency)\n'
          'def reflect_node(state, store: BaseStore):\n'
          '    """메모리를 인라인으로 추출하고 저장합니다."""\n'
          '    last_msg = state["messages"][-1].content\n'
          '    store.put(("user", "reflections"), "latest", {"content": last_msg})\n'
          '    return state\n'
          '\n'
          'print("Hot path: 즉시 저장, 다음 턴에 사용 가능.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 04_context_memory',
  'title': '04_context_memory 코드 24',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '04_context_memory.ipynb',
  'note': 'cell 41',
  'code': 'import asyncio\n'
          '\n'
          '# Background: write in separate async task\n'
          'async def background_memory_writer(state, store: BaseStore):\n'
          '    """백그라운드에서 메모리를 저장합니다 (지연 없음)."""\n'
          '    last_msg = state["messages"][-1].content\n'
          '    await store.aput(\n'
          '        ("user", "reflections"), "latest", {"content": last_msg}\n'
          '    )\n'
          'print("Background: 최종 일관성, 지연 없음.")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '05_agentic_rag.ipynb',
  'sub': '05_agentic_rag.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/05_agentic_rag.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI, OpenAIEmbeddings\n'
          '\n'
          'llm = ChatOpenAI(model="gpt-5.4")\n'
          'embeddings = OpenAIEmbeddings(model="text-embedding-3-small")\n'
          'print("환경 준비 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON \\u2014 project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON \\u2014 {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 8',
  'code': 'from langchain_text_splitters import RecursiveCharacterTextSplitter\n'
          'from langchain_core.documents import Document\n'
          '\n'
          'raw_docs = [\n'
          '    Document(page_content="LangGraph는 LLM으로 상태 기반 멀티 액터 "\n'
          '        "애플리케이션을 구축하기 위한 프레임워크입니다.",\n'
          '        metadata={"source": "langgraph-docs"}),\n'
          '    Document(page_content="에이전트는 도구를 사용하여 외부 시스템과 "\n'
          '        "상호작용합니다. ReAct 패턴은 추론과 행동을 번갈아 수행합니다.",\n'
          '        metadata={"source": "agent-guide"}),\n'
          ']\n'
          'print(f"문서 {len(raw_docs)}개 로드됨.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 04',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 9',
  'code': 'text_splitter = RecursiveCharacterTextSplitter(\n'
          '    chunk_size=1000, chunk_overlap=200,\n'
          ')\n'
          'splits = text_splitter.split_documents(raw_docs)\n'
          '\n'
          'for i, doc in enumerate(splits):\n'
          '    print(f"청크 {i}: {doc.page_content[:60]}...")\n'
          'print(f"총 청크 수: {len(splits)}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 05',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 11',
  'code': 'from langchain_core.vectorstores import InMemoryVectorStore\n'
          '\n'
          'vector_store = InMemoryVectorStore.from_documents(\n'
          '    documents=splits, embedding=embeddings,\n'
          ')\n'
          'test_results = vector_store.similarity_search("LangGraph", k=2)\n'
          'for doc in test_results:\n'
          '    print(f"  [{doc.metadata[\'source\']}] {doc.page_content[:80]}")\n'
          'print(f"벡터 스토어 준비 완료. 문서 {len(splits)}개.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 06',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 13',
  'code': 'from langchain_core.tools import tool\n'
          '\n'
          '@tool(response_format="content_and_artifact")\n'
          'def retrieve(query: str):\n'
          '    """지식 베이스에서 관련 문서를 검색합니다."""\n'
          '    docs = vector_store.similarity_search(query, k=4)\n'
          '    serialized = "\\n\\n".join(\n'
          '        f"출처: {d.metadata.get(\'source\', \'?\')}\\n{d.page_content}"\n'
          '        for d in docs\n'
          '    )\n'
          '    return serialized, docs'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 07',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 15',
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'rag_agent = create_agent(\n'
          '    model=llm, tools=[retrieve],\n'
          '    system_prompt="당신은 리서치 어시스턴트입니다. "\n'
          '    "답변하기 전에 retrieve를 사용하여 검색하세요.",\n'
          ')\n'
          'response = rag_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "LangGraph란 무엇인가요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print(response["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 08',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 17',
  'code': 'from langchain.agents.middleware import dynamic_prompt\n'
          '\n'
          '@dynamic_prompt\n'
          'def rag_prompt(request):\n'
          '    """문서를 검색하여 시스템 프롬프트에 주입합니다."""\n'
          '    user_msg = request.state["messages"][-1].content\n'
          '    docs = vector_store.similarity_search(user_msg, k=4)\n'
          '    ctx = "\\n\\n".join(d.page_content for d in docs)\n'
          '    return f"컨텍스트를 기반으로 답변하세요:\\n\\n{ctx}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 09',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 18',
  'code': 'chain = create_agent(model=llm, middleware=[rag_prompt])\n'
          'resp = chain.invoke(\n'
          '    {"messages": [{"role": "user", "content": "에이전트는 어떻게 작동하나요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print(resp["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 10',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 20',
  'code': 'from langgraph.graph import MessagesState\n'
          '\n'
          'class AgentState(MessagesState):\n'
          '    """커스텀 RAG 에이전트 상태."""\n'
          '    relevance: str  # "relevant" or "not_relevant"\n'
          '\n'
          'print(f"AgentState 키: {list(AgentState.__annotations__)}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 11',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 22',
  'code': 'llm_with_tools = llm.bind_tools([retrieve])\n'
          '\n'
          'def generate_query_or_respond(state: AgentState):\n'
          '    """검색할지 직접 응답할지 결정합니다."""\n'
          '    system = ("당신은 유용한 어시스턴트입니다. "\n'
          '              "지식 베이스 관련 질문에는 retrieve 도구를 사용하세요.")\n'
          '    msgs = [{"role": "system", "content": system}] + state["messages"]\n'
          '    response = llm_with_tools.invoke(msgs, config=lf_config)\n'
          '    return {"messages": [response]}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 12',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 24',
  'code': 'from pydantic import BaseModel, Field\n'
          'from typing import Literal\n'
          '\n'
          'class GradeDocuments(BaseModel):\n'
          '    """검색된 문서의 이진 관련성 점수."""\n'
          '    relevance: Literal["relevant", "not_relevant"] = Field(\n'
          '        description="문서가 관련이 있는지 여부."\n'
          '    )\n'
          '    reasoning: str = Field(description="간략한 설명.")\n'
          '\n'
          'grader = llm.with_structured_output(GradeDocuments)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 13 (1/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 25',
  'code': 'def grade_documents(state: AgentState):\n'
          '    """\n'
          '    검색된 문서의 관련성을 평가합니다.\n'
          '    """\n'
          '\n'
          '    msgs = state["messages"]\n'
          '\n'
          '    user_q = next(\n'
          '        (m.content for m in msgs if m.type == "human"),\n'
          '        ""\n'
          '    )\n'
          '\n'
          '    tool_content = msgs[-1].content\n'
          '\n'
          '    grade = grader.invoke(\n'
          '        f"질문: {user_q}\\n문서:\\n{tool_content}\\n"\n'
          '        f"이 문서들이 관련이 있습니까?"\n'
          '    )\n'
          '\n'
          '    return {\n'
          '        "relevance": grade.relevance,\n'
          '        "messages": msgs'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 13 (2/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 25',
  'code': '    }'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 14 (1/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 27',
  'code': 'def rewrite_question(state: AgentState):\n'
          '    """\n'
          '    검색 품질 향상을 위해 질문을 리라이트합니다.\n'
          '    """\n'
          '\n'
          '    user_q = next(\n'
          '        (m.content for m in state["messages"] if m.type == "human"),\n'
          '        ""\n'
          '    )\n'
          '\n'
          '    prompt = (\n'
          '        f"다른 용어를 사용하여 리라이트하세요.\\n"\n'
          '        f"원본: {user_q}\\n"\n'
          '        f"리라이트:"\n'
          '    )\n'
          '\n'
          '    response = llm.invoke(prompt, config=lf_config)\n'
          '\n'
          '    return {\n'
          '        "messages": [\n'
          '            {\n'
          '                "role": "human",'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 14 (2/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 27',
  'code': '                "content": response.content\n            }\n        ]\n    }'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 15 (1/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 29',
  'code': 'def generate_answer(state: AgentState):\n'
          '    """\n'
          '    검색된 문서를 사용하여 답변을 생성합니다.\n'
          '    """\n'
          '\n'
          '    user_q = next(\n'
          '        (m.content for m in state["messages"] if m.type == "human"),\n'
          '        ""\n'
          '    )\n'
          '\n'
          '    docs = next(\n'
          '        (m.content for m in state["messages"] if m.type == "tool"),\n'
          '        ""\n'
          '    )\n'
          '\n'
          '    prompt = (\n'
          '        f"컨텍스트만을 사용하여 답변하세요.\\n"\n'
          '        f"컨텍스트:\\n{docs}\\n\\n"\n'
          '        f"질문: {user_q}"\n'
          '    )\n'
          '\n'
          '    resp = llm.invoke(prompt, config=lf_config)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 15 (2/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 29',
  'code': '\n'
          '    return {\n'
          '        "messages": [\n'
          '            {\n'
          '                "role": "assistant",\n'
          '                "content": resp.content\n'
          '            }\n'
          '        ]\n'
          '    }'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 16',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 31',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.prebuilt import ToolNode, tools_condition\n'
          '\n'
          'def relevance_router(state: AgentState):\n'
          '    if state.get("relevance") == "relevant":\n'
          '        return "generate_answer"\n'
          '    return "rewrite_question"\n'
          '\n'
          'graph = StateGraph(AgentState)\n'
          'graph.add_node("gen_query", generate_query_or_respond)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 17',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 32',
  'code': 'graph.add_node("retrieve", ToolNode([retrieve]))\n'
          'graph.add_node("grade_documents", grade_documents)\n'
          'graph.add_node("rewrite_question", rewrite_question)\n'
          'graph.add_node("generate_answer", generate_answer)\n'
          '\n'
          'graph.add_edge(START, "gen_query")\n'
          'graph.add_conditional_edges(\n'
          '    "gen_query", tools_condition,\n'
          '    {"tools": "retrieve", "__end__": END},\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 18',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 33',
  'code': 'graph.add_edge("retrieve", "grade_documents")\n'
          'graph.add_conditional_edges(\n'
          '    "grade_documents", relevance_router,\n'
          '    {"generate_answer": "generate_answer",\n'
          '     "rewrite_question": "rewrite_question"},\n'
          ')\n'
          'graph.add_edge("rewrite_question", "gen_query")\n'
          'graph.add_edge("generate_answer", END)\n'
          '\n'
          'app = graph.compile()\n'
          'print("그래프 컴파일 성공.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 05_agentic_rag',
  'title': '05_agentic_rag 코드 19',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agentic_rag.ipynb',
  'note': 'cell 34',
  'code': 'for event in app.stream(\n'
          '    {"messages": [{"role": "user", "content": "LangGraph란 무엇인가요?"}]},\n'
          '    config=lf_config,\n'
          '):\n'
          '    for node_name, output in event.items():\n'
          '        print(f"--- {node_name} ---")\n'
          '        if "messages" in output:\n'
          '            last = output["messages"][-1]\n'
          '            txt = last.content if hasattr(last, "content") else str(last)\n'
          '            print(txt[:200])'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '06_sql_agent.ipynb',
  'sub': '06_sql_agent.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/06_sql_agent.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 01',
  'lead': '이 코드는 SQL 데이터베이스 연결과 에이전트 도구화를 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 4',
  'code': '# %pip install langchain langchain-openai langchain-community langgraph sqlalchemy python-dotenv\n'
          '\n'
          'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          'from langchain_community.utilities import SQLDatabase\n'
          '\n'
          'llm = ChatOpenAI(model="gpt-5.4")\n'
          'db = SQLDatabase.from_uri("sqlite:///Chinook.db")\n'
          'print(f"Dialect: {db.dialect}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON \\u2014 project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON \\u2014 {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 03',
  'lead': '이 코드는 SQL 데이터베이스 연결과 에이전트 도구화를 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 8',
  'code': 'from langchain_community.agent_toolkits import SQLDatabaseToolkit\n'
          '\n'
          'toolkit = SQLDatabaseToolkit(db=db, llm=llm)\n'
          'tools = toolkit.get_tools()\n'
          '\n'
          'for t in tools:\n'
          '    print(f"  {t.name}: {t.description[:60]}...")\n'
          'print(f"총 도구 수: {len(tools)}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 04',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 10',
  'code': 'system_prompt = (\n'
          '    "당신은 SQL 에이전트입니다. 단계:\\n"\n'
          '    "1. sql_db_list_tables\\n2. sql_db_schema\\n"\n'
          '    "3. 쿼리 작성 + sql_db_query_checker\\n"\n'
          '    "4. sql_db_query\\n5. 결과를 해석하세요.\\n"\n'
          '    f"규칙: LIMIT 10 사용. DML 금지. Dialect: {db.dialect}"\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 05',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 11',
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'sql_agent = create_agent(\n'
          '    model=llm, tools=tools, system_prompt=system_prompt,\n'
          ')\n'
          'print("LangChain SQL 에이전트 생성됨.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 06',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 13',
  'code': 'response = sql_agent.invoke(\n'
          '    {"messages": [{"role": "user",\n'
          '     "content": "어떤 나라의 고객이 가장 많나요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print(response["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 07',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 15',
  'code': 'from langchain.agents.middleware import HumanInTheLoopMiddleware\n'
          '\n'
          '# DELETE / UPDATE 가 위험한 환경: sql_db_query 를 전부 가로채거나,\n'
          '# 특정 도구만 allowed_decisions 로 제한할 수 있습니다.\n'
          'hitl = HumanInTheLoopMiddleware(\n'
          '    interrupt_on={\n'
          '        "sql_db_query": {"allowed_decisions": ["approve", "edit", "reject"]},\n'
          '    },\n'
          '    description_prefix="SQL 쿼리 실행 승인 필요",\n'
          ')\n'
          'sql_agent_hitl = create_agent(\n'
          '    model=llm, tools=tools,\n'
          '    system_prompt=system_prompt, middleware=[hitl],\n'
          ')\n'
          'print("HITL이 적용된 SQL 에이전트 생성됨.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 08 (1/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 16',
  'code': 'from langgraph.types import Command\n'
          '\n'
          'config = {"configurable": {"thread_id": "sql-review-1"}}\n'
          '\n'
          '# v2 invocation 필요 (version="v2")\n'
          '# 1) 첫 실행 — interrupt 발생 시점까지 진행\n'
          '# result = sql_agent_hitl.invoke(\n'
          '#     {"messages": [{"role": "user", "content": "고객이 가장 많은 나라는?"}]},\n'
          '#     config=config, version="v2",\n'
          '# )\n'
          '# print(result.interrupts)  # HITLRequest 확인\n'
          '\n'
          '# Option 1: Approve\n'
          '# result = sql_agent_hitl.invoke(\n'
          '#     Command(resume={"decisions": [{"type": "approve"}]}),\n'
          '#     config=config, version="v2",\n'
          '# )\n'
          '\n'
          '# Option 2: Edit\n'
          '# result = sql_agent_hitl.invoke(\n'
          '#     Command(resume={"decisions": [\n'
          '#         {"type": "edit",'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 08 (2/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 16',
  'code': '#          "edited_action": {\n'
          '#              "name": "sql_db_query",\n'
          '#              "args": {"query": "SELECT Country, COUNT(*) FROM Customer GROUP BY Country LIMIT 10"},\n'
          '#          }}\n'
          '#     ]}),\n'
          '#     config=config, version="v2",\n'
          '# )\n'
          '\n'
          '# Option 3: Reject (DELETE/UPDATE 차단 시 사용)\n'
          '# result = sql_agent_hitl.invoke(\n'
          '#     Command(resume={"decisions": [\n'
          '#         {"type": "reject", "message": "DELETE 가 의심됩니다. SELECT 로 다시 작성하세요."}\n'
          '#     ]}),\n'
          '#     config=config, version="v2",\n'
          '# )\n'
          'print("HITL 재개 옵션: approve / edit / reject / respond (v2 invocation 필수)")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 09',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 18',
  'code': 'from typing import Annotated\n'
          'from typing_extensions import TypedDict\n'
          'from langgraph.graph.message import add_messages\n'
          '\n'
          'class SQLState(TypedDict):\n'
          '    messages: Annotated[list, add_messages]\n'
          '\n'
          'print(f"SQLState 키: {list(SQLState.__annotations__)}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 10',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 20',
  'code': 'tool_map = {t.name: t for t in tools}\n'
          '\n'
          'list_tbl = tool_map["sql_db_list_tables"]\n'
          'schema_tl = tool_map["sql_db_schema"]\n'
          'query_tl = tool_map["sql_db_query"]\n'
          'check_tl = tool_map["sql_db_query_checker"]\n'
          '\n'
          '\n'
          'def list_tables_node(state: SQLState):\n'
          '    tables = list_tbl.invoke("", config=lf_config)\n'
          '\n'
          '    msg = {\n'
          '        "role": "assistant",\n'
          '        "content": f"테이블: {tables}"\n'
          '    }\n'
          '\n'
          '    return {"messages": [msg]}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 11',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 21',
  'code': 'def get_schema_node(state: SQLState):\n'
          '    """관련 테이블의 스키마를 가져옵니다."""\n'
          '    resp = llm.invoke(state["messages"] + [\n'
          '        {"role": "user",\n'
          '         "content": "관련 테이블이 어떤 것인가요? 이름만 알려주세요."}\n'
          '    ], config=lf_config)\n'
          '    schema = schema_tl.invoke(resp.content.strip(), config=lf_config)\n'
          '    msg = {"role": "assistant", "content": f"스키마:\\n{schema}"}\n'
          '    return {"messages": [msg]}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 12',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 23',
  'code': 'llm_forced = llm.bind_tools(\n'
          '    [check_tl], tool_choice="sql_db_query_checker"\n'
          ')\n'
          '\n'
          'def generate_query_node(state: SQLState):\n'
          '    """SQL 쿼리를 생성합니다."""\n'
          '    prompt = "SQL 쿼리를 작성해주세요. checker 도구를 사용하세요."\n'
          '    msgs = state["messages"] + [{"role": "user", "content": prompt}]\n'
          '    response = llm_forced.invoke(msgs, config=lf_config)\n'
          '    return {"messages": [response]}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 13',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 24',
  'code': 'def check_query_node(state: SQLState):\n'
          '    """\n'
          '    생성된 쿼리를 검증합니다.\n'
          '    """\n'
          '\n'
          '    last = state["messages"][-1]\n'
          '\n'
          '    if hasattr(last, "tool_calls") and last.tool_calls:\n'
          '        query = last.tool_calls[0]["args"].get("query", "")\n'
          '\n'
          '        result = check_tl.invoke(query, config=lf_config)\n'
          '\n'
          '        return {\n'
          '            "messages": [\n'
          '                {\n'
          '                    "role": "tool",\n'
          '                    "content": result\n'
          '                }\n'
          '            ]\n'
          '        }\n'
          '\n'
          '    return state'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 14 (1/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 26',
  'code': 'from langgraph.types import interrupt\n'
          '\n'
          'def execute_query_node(state: SQLState):\n'
          '    """\n'
          '    사람의 리뷰 후 쿼리를 실행합니다.\n'
          '    """\n'
          '\n'
          '    query = state["messages"][-1].content\n'
          '\n'
          '    review = interrupt({\n'
          '        "query": query,\n'
          '        "action": "review_sql"\n'
          '    })\n'
          '\n'
          '    if review.get("action") == "accept":\n'
          '        result = query_tl.invoke(query, config=lf_config)\n'
          '\n'
          '    elif review.get("action") == "edit":\n'
          '        result = query_tl.invoke(review["edited_query"], config=lf_config)\n'
          '\n'
          '    else:\n'
          '        result = f"거부됨: {review.get(\'reason\', \'\')}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 14 (2/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 26',
  'code': '\n'
          '    return {\n'
          '        "messages": [\n'
          '            {\n'
          '                "role": "assistant",\n'
          '                "content": result\n'
          '            }\n'
          '        ]\n'
          '    }'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 15',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 28',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'builder = StateGraph(SQLState)\n'
          'builder.add_node("list_tables", list_tables_node)\n'
          'builder.add_node("get_schema", get_schema_node)\n'
          'builder.add_node("generate_query", generate_query_node)\n'
          'builder.add_node("check_query", check_query_node)\n'
          'builder.add_node("execute_query", execute_query_node)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 16',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 29',
  'code': 'builder.add_edge(START, "list_tables")\n'
          'builder.add_edge("list_tables", "get_schema")\n'
          'builder.add_edge("get_schema", "generate_query")\n'
          'builder.add_edge("generate_query", "check_query")\n'
          'builder.add_edge("check_query", "execute_query")\n'
          'builder.add_edge("execute_query", END)\n'
          '\n'
          'checkpointer = InMemorySaver()\n'
          'sql_graph = builder.compile(checkpointer=checkpointer)\n'
          'print("LangGraph SQL 에이전트 컴파일됨.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 06_sql_agent',
  'title': '06_sql_agent 코드 17',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '06_sql_agent.ipynb',
  'note': 'cell 30',
  'code': 'from langgraph.types import Command\n'
          '\n'
          'config = {"configurable": {"thread_id": "sql-1"}}\n'
          '\n'
          '# Resume examples after interrupt:\n'
          '# sql_graph.invoke(Command(resume={"action": "accept"}), {**config, **lf_config})\n'
          '# sql_graph.invoke(Command(resume={\n'
          '#     "action": "edit", "edited_query": "SELECT ..."\n'
          '# }), {**config, **lf_config})\n'
          'print("Command(resume=...) 패턴: accept / edit / reject")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '07_data_analysis.ipynb',
  'sub': '07_data_analysis.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/07_data_analysis.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n\nload_dotenv()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON — project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 8',
  'code': 'from deepagents.backends import LocalShellBackend\n'
          '\n'
          '# 개발용 — 로컬 셸 백엔드\n'
          'dev_backend = LocalShellBackend(virtual_mode=True)\n'
          '\n'
          '# 운영용 — 클라우드 샌드박스 (택 1)\n'
          '# prod_backend = ...  # 프로덕션에서는 클라우드 샌드박스 백엔드를 사용하세요'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 04',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 10',
  'code': 'import os\n'
          '\n'
          'workspace = "/tmp/analysis"\n'
          'os.makedirs(workspace, exist_ok=True)\n'
          '\n'
          'csv_content = (\n'
          '    "region,quarter,revenue,units_sold\\n"\n'
          '    "Seoul,Q1,120000,340\\nSeoul,Q2,135000,380\\n"\n'
          '    "Seoul,Q3,128000,355\\nSeoul,Q4,150000,420\\n"\n'
          '    "Busan,Q1,85000,240\\nBusan,Q2,92000,260\\n"\n'
          '    "Busan,Q3,88000,250\\nBusan,Q4,105000,300"\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 05',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 11',
  'code': 'with open(f"{workspace}/sales_2025.csv", "w") as f:\n'
          '    f.write(csv_content)\n'
          'print(f"CSV 저장됨: {workspace}/sales_2025.csv")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 06',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 13',
  'code': 'from langchain_core.tools import tool\n'
          'try:\n'
          '    from slack_sdk import WebClient\n'
          'except ImportError:\n'
          '    WebClient = None\n'
          '    print("slack_sdk 미설치 -- Slack 도구는 스텁으로 작동합니다")\n'
          '\n'
          'slack_client = WebClient(token=os.environ.get("SLACK_BOT_TOKEN", "xoxb-placeholder")) if WebClient else '
          'None\n'
          '\n'
          '@tool\n'
          'def slack_send_message(message: str) -> str:\n'
          '    """분석 결과를 Slack 채널로 전송합니다."""\n'
          '    resp = slack_client.chat_postMessage(\n'
          '        channel=os.environ.get("SLACK_CHANNEL_ID", "general"), text=message)\n'
          '    return f"전송 완료. 타임스탬프: {resp[\'ts\']}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 07',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 15',
  'code': 'from tavily import TavilyClient\n'
          '\n'
          'tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])\n'
          '\n'
          'def tavily_search(query: str) -> str:\n'
          '    """분석에 관련된 정보를 웹에서 검색합니다."""\n'
          '    results = tavily_client.search(query, max_results=5)\n'
          '    return "\\n".join(\n'
          '        [r["content"] for r in results["results"]]\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 08',
  'lead': '이 코드는 Deep Agent 생성과 하네스 옵션 연결을 보여줍니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 17',
  'code': 'from deepagents import create_deep_agent\n'
          'from deepagents.backends import LocalShellBackend\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'backend = LocalShellBackend(virtual_mode=True)\n'
          'checkpointer = InMemorySaver()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 09',
  'lead': '이 코드는 Deep Agent 생성과 하네스 옵션 연결을 보여줍니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 18',
  'code': 'agent = create_deep_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[tavily_search, slack_send_message],\n'
          '    backend=backend,\n'
          '    checkpointer=checkpointer,\n'
          '    system_prompt="당신은 데이터 분석가입니다.",\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 10',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 20',
  'code': 'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "/tmp/analysis/sales_2025.csv의 매출 데이터를 분석하세요. 성과가 좋은 지역을 찾고, '
          '분기별 트렌드를 파악하고, 시각화를 만들고, 요약을 Slack에 전송하세요."}]},\n'
          '    config={**lf_config, "configurable": {"thread_id": "data-analysis-1"}},\n'
          ')\n'
          'print(result)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 11',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 22',
  'code': 'for namespace, chunk in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "지역별 매출을 요약해 주세요."}]},\n'
          '    stream_mode="updates",\n'
          '    subgraphs=True,\n'
          '    config={**lf_config, "configurable": {"thread_id": "data-analysis-1"}},\n'
          '):\n'
          '    source = f"[subagent: {namespace}]" if namespace else "[main]"\n'
          '    print(source, chunk)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 12',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 24',
  'code': 'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "glob을 사용하여 /tmp/analysis/의 모든 CSV 파일을 나열하고, 첫 번째 파일을 읽어 구조를 '
          '설명해 주세요."}]},\n'
          '    config={**lf_config, "configurable": {"thread_id": "data-analysis-1"}},\n'
          ')\n'
          'print(result)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 13',
  'lead': '이 코드는 Deep Agent 생성과 하네스 옵션 연결을 보여줍니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 26',
  'code': 'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'checkpointer = InMemorySaver()\n'
          'config = {"configurable": {"thread_id": "analysis-session-1"}}\n'
          '\n'
          'agent_with_memory = create_deep_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[tavily_search, slack_send_message],\n'
          '    backend=LocalShellBackend(virtual_mode=True),\n'
          '    checkpointer=checkpointer,\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 14',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 27',
  'code': 'r1 = agent_with_memory.invoke(\n'
          '    {"messages": [{"role": "user", "content": "/tmp/analysis/sales_2025.csv를 읽고 요약해 주세요."}]},\n'
          '    config={**config, **lf_config},\n'
          ')\n'
          'print("턴:", r1)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 07_data_analysis',
  'title': '07_data_analysis 코드 15',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_data_analysis.ipynb',
  'note': 'cell 28',
  'code': 'r2 = agent_with_memory.invoke(\n'
          '    {"messages": [{"role": "user", "content": "서울과 부산의 Q4 실적을 비교해 주세요."}]},\n'
          '    config={**config, **lf_config},\n'
          ')\n'
          'print("턴:", r2)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '08_voice_agent.ipynb',
  'sub': '08_voice_agent.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/08_voice_agent.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 08_voice_agent',
  'title': '08_voice_agent 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '08_voice_agent.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'load_dotenv()\n'
          '\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 08_voice_agent',
  'title': '08_voice_agent 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '08_voice_agent.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON — project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 08_voice_agent',
  'title': '08_voice_agent 코드 03',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '08_voice_agent.ipynb',
  'note': 'cell 10',
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'def search_tool(query: str) -> str:\n'
          '    """웹에서 최신 정보를 검색합니다."""\n'
          '    return f"검색 결과: {query}"\n'
          '\n'
          'def calendar_tool(action: str, details: str) -> str:\n'
          '    """캘린더 이벤트를 관리합니다."""\n'
          '    return f"캘린더 {action}: {details}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 08_voice_agent',
  'title': '08_voice_agent 코드 04',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '08_voice_agent.ipynb',
  'note': 'cell 11',
  'code': 'agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[search_tool, calendar_tool],\n'
          '    system_prompt=(\n'
          '        "당신은 유용한 음성 어시스턴트입니다. "\n'
          '        "응답을 간결하고 대화체로 유지하세요."\n'
          '    ),\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 08_voice_agent',
  'title': '08_voice_agent 코드 05',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '08_voice_agent.ipynb',
  'note': 'cell 13',
  'code': 'async def stream_agent_response(user_text: str):\n'
          '    """에이전트 응답 토큰을 하나씩 스트리밍합니다."""\n'
          '    async for chunk in agent.astream(\n'
          '        {"messages": [{"role": "user",\n'
          '                        "content": user_text}]}\n'
          '    ):\n'
          '        if "messages" in chunk:\n'
          '            for msg in chunk["messages"]:\n'
          '                if hasattr(msg, "content") and msg.content:\n'
          '                    yield msg.content'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 08_voice_agent',
  'title': '08_voice_agent 코드 06',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '08_voice_agent.ipynb',
  'note': 'cell 19',
  'code': 'def weather_tool(city: str) -> str:\n'
          '    """도시의 현재 날씨를 조회합니다."""\n'
          '    return f"{city} 날씨: 15도, 구름 조금"\n'
          '\n'
          'def reminder_tool(time: str, message: str) -> str:\n'
          '    """지정된 시간에 알림을 설정합니다."""\n'
          '    return f"{time}에 알림 설정됨: {message}"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 08_voice_agent',
  'title': '08_voice_agent 코드 07',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '08_voice_agent.ipynb',
  'note': 'cell 20',
  'code': 'voice_agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[search_tool, calendar_tool,\n'
          '           weather_tool, reminder_tool],\n'
          '    system_prompt=(\n'
          '        "당신은 음성 어시스턴트입니다. "\n'
          '        "1-2문장으로 간결하고 대화체로 응답하세요."\n'
          '    ),\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 08_voice_agent',
  'title': '08_voice_agent 코드 08',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '08_voice_agent.ipynb',
  'note': 'cell 21',
  'code': '# 에이전트 단독 테스트 (텍스트 입력으로 동작 확인)\n'
          'response = voice_agent.invoke(\n'
          '    {"messages": [{"role": "user",\n'
          '      "content": "서울 날씨가 어떤가요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print(response["messages"][-1].content)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '09_production.ipynb',
  'sub': '09_production.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '05_advanced/09_production.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          '\n'
          'load_dotenv()\n'
          '\n'
          'import os\n'
          '# Only enable LangSmith tracing if API key is available\n'
          'if os.environ.get("LANGSMITH_API_KEY"):\n'
          '    os.environ["LANGSMITH_TRACING"] = "true"\n'
          'else:\n'
          '    os.environ["LANGSMITH_TRACING"] = "false"\n'
          '    print("LANGSMITH_API_KEY 미설정. LangSmith 트레이싱 비활성화.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON — project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 8',
  'code': 'try:\n'
          '    from langsmith import Client\n'
          '\n'
          '    ls_client = Client()\n'
          '\n'
          '    dataset = ls_client.create_dataset("agent-eval-v1")\n'
          '    ls_client.create_examples(\n'
          '        inputs=[{"query": "LangGraph란 무엇인가요?"}],\n'
          '        outputs=[{"expected": "에이전트를 위한 프레임워크"}],\n'
          '        dataset_id=dataset.id,\n'
          '    )\n'
          '    print("데이터셋 생성됨:", dataset.name)\n'
          'except Exception as e:\n'
          '    print(f"LangSmith 미설정 (건너뜀): {e}")\n'
          '    ls_client = None\n'
          '    dataset = None'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 04',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 9',
  'code': 'try:\n'
          '    from agentevals.trajectory import create_trajectory_llm_as_judge\n'
          '\n'
          '    evaluator = create_trajectory_llm_as_judge(\n'
          '        rubric=(\n'
          '            "에이전트가 적절한 도구를 사용했습니까? "\n'
          '            "최종 답변이 정확했습니까?"\n'
          '        ),\n'
          '    )\n'
          '    print("평가자 생성됨:", type(evaluator).__name__)\n'
          'except ImportError:\n'
          '    print("agentevals 미설치. 설치: pip install agentevals")\n'
          '    evaluator = None\n'
          'except Exception as e:\n'
          '    print(f"평가자 생성 건너뜀 (LLM API 키 필요): {e}")\n'
          '    evaluator = None'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 05',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 11',
  'code': 'from langchain_core.language_models import GenericFakeChatModel\n'
          'from langchain_core.messages import AIMessage\n'
          '\n'
          'fake_responses = [\n'
          '    AIMessage(content="LangGraph는 프레임워크입니다."),\n'
          '    AIMessage(content="상태 기반 에이전트를 지원합니다."),\n'
          ']\n'
          'fake_model = GenericFakeChatModel(\n'
          '    messages=iter(fake_responses)\n'
          ')\n'
          'print(fake_model.invoke("LangGraph란 무엇인가요?", config=lf_config).content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 06',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '09_production.ipynb',
  'note': 'cell 12',
  'code': 'def search_tool(query: str) -> str:\n'
          '    """웹에서 정보를 검색합니다."""\n'
          '    return f"검색 결과: {query}"\n'
          '\n'
          'def test_search_tool():\n'
          '    """검색 도구가 예상 형식을 반환하는지 테스트합니다."""\n'
          '    result = search_tool("test query")\n'
          '    assert isinstance(result, str) and len(result) > 0\n'
          '    print("통과: test_search_tool")\n'
          '\n'
          'test_search_tool()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 07',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 15',
  'code': 'print("LANGSMITH_TRACING:", os.environ.get("LANGSMITH_TRACING"))\n'
          'print("LANGSMITH_PROJECT:", os.environ.get("LANGSMITH_PROJECT"))\n'
          '\n'
          'try:\n'
          '    from langsmith import tracing_context\n'
          '\n'
          '    with tracing_context(project_name="debug-session"):\n'
          '        print("이 블록에 대해 트레이싱 활성화됨")\n'
          'except Exception as e:\n'
          '    print(f"LangSmith 트레이싱 사용 불가: {e}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 08',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 17',
  'code': 'try:\n'
          '    from langsmith import tracing_context\n'
          '\n'
          '    with tracing_context(\n'
          '        project_name="production-agent",\n'
          '        tags=["v2.1", "experiment-A"],\n'
          '        metadata={"user_tier": "premium", "region": "kr"},\n'
          '    ):\n'
          '        print("태그된 트레이싱 활성화됨")\n'
          'except Exception as e:\n'
          '    print(f"LangSmith 트레이싱 사용 불가: {e}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 09',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 21',
  'code': 'import json\n'
          '\n'
          'langgraph_config = {\n'
          '    "dependencies": ["."],\n'
          '    "graphs": {"agent": "./src/agent.py:graph"},\n'
          '    "env": ".env",\n'
          '}\n'
          'print(json.dumps(langgraph_config, indent=2))'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 고급',
  'meta': 'Code / 09_production',
  'title': '09_production 코드 10',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_production.ipynb',
  'note': 'cell 24',
  'code': 'try:\n'
          '    from langgraph_sdk import get_sync_client\n'
          '\n'
          '    api_key = os.environ.get("LANGSMITH_API_KEY", "")\n'
          '    if not api_key:\n'
          '        print("LANGSMITH_API_KEY 미설정. 클라이언트 연결 건너뜀.")\n'
          '    else:\n'
          '        client = get_sync_client(\n'
          '            url="https://your-deployment.langsmith.com",\n'
          '            api_key=api_key,\n'
          '        )\n'
          '        print("클라이언트 연결됨:", type(client).__name__)\n'
          'except Exception as e:\n'
          '    print(f"LangGraph SDK 클라이언트 사용 불가: {e}")'},
 {'type': 'closing',
  'kicker': 'CLOSING',
  'title': '고급 에이전트는 실행 흐름과 상태를 설계할 때 운영 가능해집니다',
  'sub': 'AI 에이전트 개발 고급. Middleware · Multi-agent · Memory · Production'}]
