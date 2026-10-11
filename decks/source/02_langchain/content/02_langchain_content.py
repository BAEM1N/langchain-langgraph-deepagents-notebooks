# -*- coding: utf-8 -*-
"""AI 에이전트 개발 기초 — 슬라이드 콘텐츠.

Portable editable source normalized on 2026-10-11 so the Python source itself
contains the migrated LangChain 1.4 MCP examples. Do not reintroduce runtime
patch functions that hide stale base snippets.
"""
BRAND = '© 주식회사 똑똑한청년들 · 배움 에이아이'
SLIDES = [{'type': 'cover',
  'eyebrow': 'LANGCHAIN TRACK',
  'title': 'AI 에이전트 개발 기초',
  'tagline': 'LangChain으로 에이전트 만들기',
  'credit': '주식회사 똑똑한청년들 · 배움 에이아이'},
 {'type': 'divider',
  'kicker': 'PART 01',
  'title': '오리엔테이션',
  'sub': '입문에서 만든 첫 에이전트를 기준점으로 삼고, LangChain v1의 모델·도구·메모리·운영 기능을 한 단계씩 확장합니다.'},
 {'type': 'flow',
  'meta': '01 / 오리엔테이션',
  'title': '이번 트랙은 첫 에이전트를 프로덕션 에이전트로 키우는 흐름입니다',
  'lead': '각 노트북은 새 프레임워크를 도입하기보다, 같은 LangChain 에이전트에 필요한 능력을 하나씩 붙입니다',
  'nodes': [{'h': 'MODEL', 'p': 'messages', 'note': '모델 호출·메시지 타입·토큰 사용량을 통일합니다.'},
            {'h': 'TOOLS', 'p': 'schemas', 'note': '도구 스키마와 구조화 출력을 정확하게 정의합니다.', 'hl': True},
            {'h': 'STATE', 'p': 'memory', 'note': '단기·장기 메모리와 스트리밍 상태를 관리합니다.'},
            {'h': 'CONTROL', 'p': 'middleware', 'note': '미들웨어·HITL·멀티에이전트로 실행 흐름을 통제합니다.'},
            {'h': 'RUN', 'p': 'production', 'note': '테스트·배포·MCP·프론트엔드·가드레일로 운영합니다.'}],
  'sum': 'LangChain 트랙의 핵심 질문은 <strong>에이전트가 무엇을 할 수 있나</strong>가 아니라 <strong>운영 가능한 에이전트를 어떻게 설계하나</strong>입니다.'},
 {'type': 'table',
  'meta': '01 / 오리엔테이션',
  'title': '02_langchain은 13개 노트북으로 에이전트 생명주기를 전부 훑습니다',
  'lead': '노트북 순서는 구현 편의가 아니라 <strong>운영 성숙도</strong> 순서입니다',
  'cols': [{'t': '구간', 'w': '24%'}, {'t': '노트북', 'w': '35%'}, {'t': '핵심 산출', 'accent': True}],
  'rows': [['기초 조립', '01~04 소개·Quickstart·모델·도구', '모델, 메시지, 도구, 구조화 출력을 갖춘 기본 에이전트'],
           ['상태와 제어', '05~07 메모리·미들웨어·HITL', '대화 상태, 런타임 컨텍스트, 사람 승인, 안전한 중단/재개'],
           ['복합 패턴', '08~09 멀티에이전트·워크플로·RAG', '서브에이전트, 핸드오프, 라우터, StateGraph, 검색 보강'],
           ['운영 표면', '10~13 프로덕션·MCP·프론트엔드·가드레일', '테스트, 배포, 도구 서버, 스트리밍 UI, PII/HITL/커스텀 가드레일']]},
 {'type': 'divider',
  'kicker': 'PART 02',
  'title': 'LangChain v1 기준점',
  'sub': 'LangChain v1은 create_agent()를 중심으로 모델·도구·상태·미들웨어를 한 실행 그래프에 묶습니다.',
  'lab': '02_langchain/01_introduction.ipynb'},
 {'type': 'figure',
  'meta': '02 / LangChain 소개',
  'title': 'LangChain은 단일 API가 아니라 세 레이어가 맞물린 실행 계층입니다',
  'lead': '노트북의 3계층 그림은 LangChain·LangGraph·Deep Agents가 왜 함께 언급되는지 설명합니다',
  'img_src': 'assets/diagrams/langchain_3layer.png',
  'cap': 'LangChain 3계층',
  'points': [{'h': 'LangChain',
              'p': "에이전트 생성의 기준 API입니다. <span class='mono'>create_agent</span>, <span class='mono'>@tool</span>, <span "
                   "class='mono'>ChatOpenAI</span>가 여기에 속합니다."},
             {'h': 'LangGraph', 'p': 'LangChain 에이전트의 내부 실행 엔진입니다. 상태 그래프·체크포인터·스트리밍이 이 계층에서 제공됩니다.'},
             {'h': 'Deep Agents', 'p': '사전 구축된 장기 작업 하네스입니다. 빠른 프로토타이핑에 적합하지만, 기초 인터페이스는 LangChain을 공유합니다.'},
             {'h': '선택 기준',
              'p': '기본 요구엔 LangChain이 더 간단한 진입점이고, 결정론적 워크플로와 에이전틱 동작을 함께 커스터마이징해야 하면 LangGraph를, 대화 압축·가상 '
                   '파일시스템·서브에이전트가 기본 포함된 배터리 포함형을 원하면 Deep Agents를 선택합니다.'}]},
 {'type': 'figure',
  'meta': '02 / LangChain 소개',
  'title': 'create_agent()의 기본 동작은 ReAct 루프입니다',
  'lead': '모델은 바로 답하지 않고, 필요하면 도구를 호출하고 결과를 관찰한 뒤 다시 판단합니다',
  'img_src': 'assets/diagrams/react_loop.png',
  'cap': 'Reasoning → Acting → Observation',
  'points': [{'h': 'Reasoning', 'p': '사용자 메시지를 보고 지금 답할지, 도구를 쓸지 모델이 판단합니다.'},
             {'h': 'Acting', 'p': '도구 호출이 필요하면 스키마에 맞춰 인자를 만들고 도구를 실행합니다.'},
             {'h': 'Observation',
              'p': "도구 결과가 <span class='mono'>ToolMessage</span>로 돌아오면 모델이 다음 행동이나 최종 답변을 결정합니다."}]},
 {'type': 'table',
  'meta': '02 / LangChain 소개',
  'title': 'v1의 기준 API는 create_agent, InMemorySaver, middleware입니다',
  'lead': '예전 v0.x의 여러 체인·메모리 객체보다, v1은 에이전트 중심 인터페이스로 수렴합니다',
  'cols': [{'t': '항목', 'w': '24%'}, {'t': 'v0.x 관성', 'w': '30%'}, {'t': 'v1 기준', 'accent': True}],
  'rows': [['에이전트 생성',
            "<span class='mono'>create_react_agent()</span> 등 여러 경로",
            "<span class='mono'>from langchain.agents import create_agent</span>"],
           ['실행 엔진', 'AgentExecutor 중심', '내부적으로 LangGraph 그래프로 실행'],
           ['메모리', 'ConversationBufferMemory 계열', "<span class='mono'>InMemorySaver</span> 같은 체크포인터"],
           ['확장 지점', '체인 바깥에서 로직 추가', "<span class='mono'>middleware=[...]</span>로 모델·도구·에이전트 훅 주입"]]},
 {'type': 'code-split',
  'meta': '02 / LangChain 소개',
  'title': '설치 확인은 네 가지 import 통과 여부로 시작합니다',
  'lead': '노트북은 실습 시작 전에 create_agent, tool, ChatOpenAI, InMemorySaver를 기준 모듈로 확인합니다',
  'points': [{'h': '에이전트', 'p': "<span class='mono'>create_agent</span>가 모든 실습의 기본 실행 단위입니다."},
             {'h': '도구', 'p': "<span class='mono'>@tool</span>은 함수명을 도구 이름으로, docstring을 도구 설명으로 씁니다."},
             {'h': '상태', 'p': "<span class='mono'>InMemorySaver</span>는 멀티턴 대화를 저장하는 첫 체크포인터입니다."}],
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          'from langchain_openai import ChatOpenAI\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'print("LangChain v1 핵심 모듈 import 성공")',
  'file': '01_introduction.ipynb',
  'note': '핵심 import 확인'},
 {'type': 'divider',
  'kicker': 'PART 03',
  'title': 'Quickstart — 첫 에이전트',
  'sub': '@tool 함수와 create_agent()를 연결하고, invoke·stream·thread_id·context를 한 번에 체험합니다.',
  'lab': '02_langchain/02_quickstart.ipynb'},
 {'type': 'code-split',
  'meta': '03 / Quickstart',
  'title': '함수에 @tool을 붙이면 모델이 호출할 수 있는 도구가 됩니다',
  'lead': 'docstring과 타입 힌트는 사람이 읽는 주석이 아니라 모델이 인자를 고르는 스키마입니다',
  'points': [{'h': '함수명', 'p': '기본 도구 이름이 됩니다. 짧고 동사형으로 둡니다.'},
             {'h': 'docstring', 'p': '모델이 도구의 용도를 이해하는 핵심 설명입니다.'},
             {'h': '타입 힌트', 'p': '도구 호출 인자를 정수·문자열 같은 명확한 타입으로 제한합니다.'}],
  'code': 'from langchain.tools import tool\n'
          '\n'
          '@tool\n'
          'def add(a: int, b: int) -> int:\n'
          '    """두 수를 더합니다."""\n'
          '    return a + b\n'
          '\n'
          '@tool\n'
          'def multiply(a: int, b: int) -> int:\n'
          '    """두 수를 곱합니다."""\n'
          '    return a * b',
  'file': '02_quickstart.ipynb',
  'note': '@tool 기본'},
 {'type': 'code-split',
  'meta': '03 / Quickstart',
  'title': 'create_agent()는 모델·도구·시스템 프롬프트를 하나의 그래프로 묶습니다',
  'lead': '생성된 객체는 내부적으로 LangGraph 그래프이며 invoke와 stream을 바로 제공합니다',
  'points': [{'h': 'model', 'p': "노트북 기준 기본 모델은 <span class='mono'>ChatOpenAI(model='gpt-5.4')</span>입니다."},
             {'h': 'tools', 'p': '도구 리스트는 에이전트가 선택 가능한 행동 공간입니다.'},
             {'h': 'system_prompt', 'p': '도구를 언제 어떻게 쓸지에 대한 운영 규칙입니다.'}],
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add, multiply],\n'
          '    system_prompt="당신은 수학 도우미입니다. 제공된 도구를 사용하여 계산하세요.",\n'
          ')\n'
          '\n'
          'result = agent.invoke({\n'
          '    "messages": [{"role": "user", "content": "12 * 8에 5를 더하세요."}]\n'
          '})\n'
          'print(result["messages"][-1].content)',
  'file': '02_quickstart.ipynb',
  'note': 'create_agent + invoke'},
 {'type': 'code-split',
  'meta': '03 / Quickstart',
  'title': "stream_mode='updates'는 에이전트의 단계별 움직임을 보여줍니다",
  'lead': '최종 답만 보는 invoke와 달리, stream은 모델 노드와 도구 노드의 업데이트를 순서대로 확인하게 해줍니다',
  'points': [{'h': '진행 표시', 'p': '도구 호출과 최종 응답을 실시간 로그처럼 보여줄 수 있습니다.'},
             {'h': '디버깅', 'p': '어느 노드에서 잘못된 인자가 만들어졌는지 확인하기 쉽습니다.'},
             {'h': 'UI 연결', 'p': '이후 프론트엔드 스트리밍의 기본 감각이 됩니다.'}],
  'code': 'for chunk in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "12 * 8을 계산한 다음 결과에 5를 더하세요."}]},\n'
          '    stream_mode="updates",\n'
          '):\n'
          '    for node_name, update in chunk.items():\n'
          '        print(f"--- {node_name} ---")\n'
          '        if "messages" in update:\n'
          '            print(update["messages"][-1].content)',
  'file': '02_quickstart.ipynb',
  'note': 'stream updates'},
 {'type': 'code-split',
  'meta': '03 / Quickstart',
  'title': '멀티턴 대화는 checkpointer와 thread_id가 함께 있어야 유지됩니다',
  'lead': '체크포인터는 상태를 저장하고, thread_id는 어떤 대화 세션을 이어갈지 지정합니다',
  'points': [{'h': 'checkpointer', 'p': "<span class='mono'>InMemorySaver()</span>가 에이전트 상태를 메모리에 보관합니다."},
             {'h': 'thread_id', 'p': '동일한 thread_id를 쓰면 이전 메시지를 이어받습니다.'},
             {'h': '격리', 'p': '다른 thread_id는 완전히 별도 대화로 취급됩니다.'}],
  'code': 'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'agent_with_memory = create_agent(\n'
          '    model=model,\n'
          '    tools=[add, multiply],\n'
          '    system_prompt="당신은 수학 도우미입니다.",\n'
          '    checkpointer=InMemorySaver(),\n'
          ')\n'
          '\n'
          'config = {"configurable": {"thread_id": "math-session-1"}}\n'
          'agent_with_memory.invoke({"messages": [{"role": "user", "content": "7 * 6은?"}]}, config=config)\n'
          'result = agent_with_memory.invoke({"messages": [{"role": "user", "content": "이전 결과에 10을 더하세요."}]}, '
          'config=config)',
  'file': '02_quickstart.ipynb',
  'note': 'InMemorySaver + thread_id'},
 {'type': 'code-split',
  'meta': '03 / Quickstart',
  'title': 'context_schema는 호출별 메타데이터를 메시지 이력과 분리합니다',
  'lead': '사용자 ID·locale·권한 같은 값은 messages에 섞지 말고 context로 넣는 편이 안전합니다',
  'points': [{'h': '상태와 분리', 'p': '사용자 메타데이터가 대화 히스토리를 오염시키지 않습니다.'},
             {'h': '타입 안정성', 'p': 'dataclass로 런타임 컨텍스트 모양을 고정합니다.'},
             {'h': '이름 규칙', 'p': '에이전트 name은 노트북처럼 snake_case가 트레이싱과 라우팅에 깔끔합니다.'}],
  'code': 'from dataclasses import dataclass\n'
          '\n'
          '@dataclass\n'
          'class Context:\n'
          '    user_id: str\n'
          '    locale: str = "ko-KR"\n'
          '\n'
          'ctx_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add, multiply],\n'
          '    system_prompt="사용자에 맞춰 답하세요.",\n'
          '    context_schema=Context,\n'
          '    name="research_assistant",\n'
          ')\n'
          '\n'
          'ctx_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "3 + 4는?"}]},\n'
          '    context=Context(user_id="u-42", locale="ko-KR"),\n'
          ')',
  'file': '02_quickstart.ipynb',
  'note': 'context_schema'},
 {'type': 'code-split',
  'meta': '03 / Quickstart',
  'title': 'Tavily 검색 도구를 붙이면 에이전트가 최신 정보에 직접 접근합니다',
  'lead': 'TAVILY_API_KEY가 있을 때만 실행되는 선택 실습으로, 웹 검색 결과를 도구 호출 흐름에 그대로 연결합니다',
  'points': [{'h': '검색 도구', 'p': "<span class='mono'>TavilySearch(max_results=3)</span>는 에이전트가 그대로 호출할 수 있는 검색 도구입니다."},
             {'h': '선택 실행', 'p': "<span class='mono'>TAVILY_API_KEY</span> 유무로 셀 실행을 분기해 키가 없어도 노트북이 끊기지 않습니다."},
             {'h': '조합', 'p': '검색 도구도 다른 도구와 동일하게 tools 리스트에 넣어 create_agent에 전달합니다.'}],
  'code': '# Tavily API 키가 있는 경우에만 실행\n'
          'if os.environ.get("TAVILY_API_KEY"):\n'
          '    from langchain_tavily import TavilySearch\n'
          '\n'
          '    search_tool = TavilySearch(max_results=3)\n'
          '\n'
          '    search_agent = create_agent(\n'
          '        model=model,\n'
          '        tools=[search_tool],\n'
          '        system_prompt="당신은 리서치 어시스턴트입니다. 웹 검색을 통해 질문에 답하세요.",\n'
          '    )\n'
          '\n'
          '    result = search_agent.invoke(\n'
          '        {"messages": [{"role": "user", "content": "LangChain의 최신 버전은 무엇인가요?"}]},\n'
          '        config=lf_config,\n'
          '    )\n'
          '    print("검색 에이전트 응답:")\n'
          '    print(result["messages"][-1].content)\n'
          'else:\n'
          '    print("TAVILY_API_KEY가 설정되지 않았습니다. 이 셀을 건너뜁니다.")',
  'file': '02_quickstart.ipynb',
  'note': 'TavilySearch 연동 (선택)'},
 {'type': 'divider',
  'kicker': 'PART 04',
  'title': '모델과 메시지',
  'sub': '프로바이더가 달라도 invoke·stream·batch와 메시지 타입을 일관되게 다루는 법을 익힙니다.',
  'lab': '02_langchain/03_models_and_messages.ipynb'},
 {'type': 'table',
  'meta': '04 / 모델과 메시지',
  'title': 'init_chat_model()은 프로바이더 문자열 하나로 모델 초기화를 통일합니다',
  'lead': 'OpenAI는 ChatOpenAI를 직접 써도 되고, 여러 프로바이더를 바꾸려면 init_chat_model이 편합니다',
  'cols': [{'t': '프로바이더', 'w': '22%'}, {'t': '모델 문자열', 'w': '34%'}, {'t': '필요 패키지', 'accent': True}],
  'rows': [['OpenAI',
            "<span class='mono'>openai:gpt-5.4</span>",
            "<span class='mono'>langchain-openai</span> + OPENAI_API_KEY"],
           ['Anthropic',
            "<span class='mono'>anthropic:claude-sonnet-4-6</span>",
            "<span class='mono'>langchain-anthropic</span> + ANTHROPIC_API_KEY"],
           ['Google',
            "<span class='mono'>google:gemini-2.5-flash-lite</span>",
            "<span class='mono'>langchain-google-genai</span> + GOOGLE_API_KEY"],
           ['Ollama', "<span class='mono'>ollama:llama3</span>", '로컬 실행 환경']]},
 {'type': 'table',
  'meta': '04 / 모델과 메시지',
  'title': '모델 호출은 invoke·stream·batch 세 패턴으로 나뉩니다',
  'lead': '같은 모델 객체라도 사용자가 기다리는 방식과 처리량 요구에 따라 호출법이 달라집니다',
  'cols': [{'t': '메서드', 'w': '22%'}, {'t': '반환', 'w': '28%'}, {'t': '언제 쓰나', 'accent': True}],
  'rows': [['invoke()', "<span class='mono'>AIMessage</span>", '단일 입력에 대한 완성 응답이 필요할 때'],
           ['stream()', "<span class='mono'>Iterator[AIMessageChunk]</span>", '채팅 UI처럼 토큰 단위 응답을 보여줄 때'],
           ['batch()', "<span class='mono'>List[AIMessage]</span>", '여러 입력을 병렬로 처리하고 max_concurrency를 걸 때']]},
 {'type': 'table',
  'meta': '04 / 모델과 메시지',
  'title': '메시지 타입은 대화의 역할과 도구 결과를 명확히 분리합니다',
  'lead': '문자열 하나만 넘기기보다 메시지 리스트를 쓰면 시스템 지시·사용자 입력·도구 결과를 안정적으로 재현할 수 있습니다',
  'cols': [{'t': '타입', 'w': '24%'}, {'t': '역할', 'w': '26%'}, {'t': '슬라이드에서 기억할 점', 'accent': True}],
  'rows': [['SystemMessage', '시스템 지시', '모델의 톤·정책·도구 사용 기준을 정합니다'],
           ['HumanMessage', '사용자 입력', '사용자가 방금 보낸 질문입니다'],
           ['AIMessage', '모델 응답', '텍스트뿐 아니라 tool_calls와 usage_metadata를 가질 수 있습니다'],
           ['ToolMessage', '도구 결과', '모든 tool_call에는 짝이 되는 ToolMessage가 필요합니다']]},
 {'type': 'code-split',
  'meta': '04 / 모델과 메시지',
  'title': '운영 모델은 출력 포맷·재시도·타임아웃을 초기화 시점에 고정합니다',
  'lead': 'content_blocks와 usage metadata를 표준화하면 멀티모달·툴콜·비용 추적 코드가 단순해집니다',
  'points': [{'h': 'output_version',
              'p': "<span class='mono'>output_version='v1'</span> 또는 <span class='mono'>LC_OUTPUT_VERSION=v1</span>로 "
                   '표준 직렬화를 켭니다.'},
             {'h': 'Usage callback',
              'p': "<span class='mono'>UsageMetadataCallbackHandler</span>로 호출 단위 토큰·캐시 통계를 모읍니다."},
             {'h': '회복력',
              'p': "<span class='mono'>max_retries</span>와 <span class='mono'>timeout</span>은 프로덕션 기본값입니다."}],
  'code': 'from langchain_openai import ChatOpenAI\n'
          'from langchain_core.callbacks import UsageMetadataCallbackHandler\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          '    output_version="v1",\n'
          '    max_retries=3,\n'
          '    timeout=30,\n'
          ')\n'
          'usage = UsageMetadataCallbackHandler()\n'
          'response = model.invoke("LangChain을 한 문장으로 설명해 주세요.", config={"callbacks": [usage]})\n'
          'print(response.content_blocks)\n'
          'print(usage.usage_metadata)',
  'file': '03_models_and_messages.ipynb',
  'note': '운영 모델 설정'},
 {'type': 'code-split',
  'meta': '04 / 모델과 메시지',
  'title': '텍스트와 이미지를 한 메시지에 함께 담을 수 있습니다',
  'lead': 'HumanMessage의 content에 텍스트·이미지 블록을 리스트로 나열하면 비전 모델이 두 입력을 동시에 해석합니다',
  'points': [{'h': '콘텐츠 블록',
              'p': "content를 리스트로 두고 <span class='mono'>type: text</span>, <span class='mono'>type: image_url</span> "
                   '블록을 나열합니다.'},
             {'h': '이미지 전달', 'p': "<span class='mono'>image_url</span>은 URL 또는 base64로 전달하며, 비전을 지원하는 모델에서만 동작합니다."},
             {'h': '표준 출력',
              'p': "<span class='mono'>output_version='v1'</span>을 지정하면 응답이 content_blocks로 표준화되어 텍스트·이미지·툴콜이 분리 "
                   '노출됩니다.'}],
  'code': 'from langchain.messages import HumanMessage\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'vision_model = ChatOpenAI(model="gpt-5.4", output_version="v1")\n'
          '\n'
          'multimodal_msg = HumanMessage(\n'
          '    content=[\n'
          '        {"type": "text", "text": "이 이미지에서 무엇이 보이나요?"},\n'
          '        {\n'
          '            "type": "image_url",\n'
          '            "image_url": {"url": '
          '"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Camponotus_flavomarginatus_ant.jpg/320px-Camponotus_flavomarginatus_ant.jpg"},\n'
          '        },\n'
          '    ]\n'
          ')\n'
          '\n'
          'response = vision_model.invoke([multimodal_msg])\n'
          'for block in response.content_blocks:\n'
          '    print(f"[{block[\'type\']}] {block}")',
  'file': '03_models_and_messages.ipynb',
  'note': '멀티모달 메시지 (이미지 입력)'},
 {'type': 'code-split',
  'meta': '04 / 모델과 메시지',
  'title': 'config 하나로 트레이스 식별과 동시 실행 상한을 함께 겁니다',
  'lead': 'config 파라미터는 콜백뿐 아니라 트레이싱 메타데이터, batch 동시성 제한까지 함께 전달합니다',
  'points': [{'h': 'run_name / tags',
              'p': "<span class='mono'>run_name</span>은 트레이스에서 이 호출을 식별하고, <span class='mono'>tags</span>는 필터링 가능한 라벨을 "
                   '붙입니다.'},
             {'h': 'metadata', 'p': "<span class='mono'>metadata</span>에 임의의 키-값 컨텍스트(실험명, 사용자 ID 등)를 실어 트레이스에 남깁니다."},
             {'h': 'max_concurrency',
              'p': "<span class='mono'>batch()</span> 호출에서 <span class='mono'>max_concurrency</span>로 동시 실행 상한을 정해 토큰 "
                   '폭주를 막습니다.'}],
  'code': 'runtime_cfg = {\n'
          '    "run_name": "intro-greeting",\n'
          '    "tags": ["demo", "ch03"],\n'
          '    "metadata": {"experiment": "v1_runtime_config"},\n'
          '    "max_concurrency": 5,\n'
          '}\n'
          '\n'
          '# 단일 호출 — run_name/tags/metadata가 트레이스에 노출됩니다.\n'
          'resp = model.invoke("한국어로 짧게 인사해 주세요.", config=runtime_cfg)\n'
          '\n'
          '# batch — max_concurrency로 동시 실행 상한을 정합니다.\n'
          'batched = model.batch(\n'
          '    [f"숫자 {i}을 한글로 적어 주세요." for i in range(1, 7)],\n'
          '    config=runtime_cfg,\n'
          ')',
  'file': '03_models_and_messages.ipynb',
  'note': 'Runtime Config'},
 {'type': 'dense',
  'meta': '04 / 모델과 메시지',
  'title': '프롬프트 캐싱은 긴 prefix를 반복 호출할 때 비용과 지연을 줄입니다',
  'lead': '노트북은 implicit caching과 explicit caching을 함께 설명합니다',
  'groups': [{'t': 'Implicit caching. 프로바이더가 동일 prefix를 자동 감지합니다',
              'kids': [{'t': 'OpenAI 통합은 provider별 캐시 옵션이 늘었습니다. 반복 prefix가 큰 호출은 <span '
                             "class='mono'>prompt_cache_options</span> 같은 설정을 함께 검토합니다"},
                       {'t': '코드 변경이 적어 빠르게 켤 수 있지만, 캐시 단위 제어는 프로바이더에 맡깁니다'}]},
             {'t': 'Explicit caching. 호출자가 캐시 단위를 명시합니다',
              'kids': [{'t': "Anthropic 계열은 <span class='mono'>prompt_cache_key</span>나 <span "
                             "class='mono'>cache_control</span> 블록으로 캐시 경계를 지정합니다"},
                       {'t': "캐시 hit 여부는 <span class='mono'>usage_metadata.input_token_details.cache_read</span> 같은 "
                             '필드로 추적합니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 05',
  'title': '도구와 구조화 출력',
  'sub': '함수에 @tool을 붙이고 Pydantic으로 입력 스키마를 정의한 뒤, 도구 실행 결과를 구조화된 출력으로 연결하는 흐름을 봅니다.',
  'lab': '02_langchain/04_tools_and_structured_output.ipynb'},
 {'type': 'code-split',
  'meta': '05 / 도구와 구조화 출력',
  'title': 'Pydantic args_schema는 복잡한 도구 입력을 모델에게 명확히 설명합니다',
  'lead': '단순 타입 힌트로 부족하면 Field 설명과 기본값을 도구 스키마에 포함합니다',
  'points': [{'h': 'Field 설명', 'p': '각 파라미터가 무엇인지 모델에게 전달합니다.'},
             {'h': '기본값', 'p': '모델이 매번 모든 인자를 채우지 않아도 안전한 값을 씁니다.'},
             {'h': '스키마 확인', 'p': "<span class='mono'>args_schema.model_json_schema()</span>로 모델에게 보이는 형태를 점검합니다."}],
  'code': 'from pydantic import BaseModel, Field\n'
          'from langchain.tools import tool\n'
          '\n'
          'class SearchQuery(BaseModel):\n'
          '    query: str = Field(description="검색 쿼리 문자열")\n'
          '    max_results: int = Field(default=5, description="반환할 최대 결과 수")\n'
          '    category: str = Field(default="all", description="all, tech, science, news")\n'
          '\n'
          '@tool(args_schema=SearchQuery)\n'
          'def search_database(query: str, max_results: int = 5, category: str = "all") -> str:\n'
          '    """고급 필터링 옵션으로 데이터베이스를 검색합니다."""\n'
          '    return f"{category}: {query} 결과 {max_results}개"',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'Pydantic 도구 스키마'},
 {'type': 'code-split',
  'meta': '05 / 도구와 구조화 출력',
  'title': 'ToolRuntime은 도구 안에서 현재 state와 실행 메타데이터를 꺼내는 통로입니다',
  'lead': '도구 인자로 받으면 안 되는 내부 정보는 ToolRuntime으로 주입받습니다',
  'points': [{'h': 'runtime.state', 'p': '현재 메시지 이력과 에이전트 상태를 읽습니다.'},
             {'h': 'execution_info', 'p': 'thread_id, run_id, attempt 같은 디버깅 키를 얻습니다.'},
             {'h': 'server_info', 'p': 'LangGraph Platform 같은 호스팅 환경에서는 assistant_id, user 정보가 들어올 수 있습니다.'}],
  'code': 'from langchain.tools import tool, ToolRuntime\n'
          '\n'
          '@tool\n'
          'def get_user_info(runtime: ToolRuntime) -> str:\n'
          '    """현재 대화에 대한 정보를 가져옵니다."""\n'
          '    messages = runtime.state["messages"]\n'
          '    info = getattr(runtime, "execution_info", None)\n'
          '    thread_id = getattr(info, "thread_id", "local") if info else "local"\n'
          '    return f"thread={thread_id}, messages={len(messages)}"',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'ToolRuntime'},
 {'type': 'code-split',
  'meta': '05 / 도구와 구조화 출력',
  'title': 'Command를 반환하는 도구는 ToolMessage를 함께 넣어야 합니다',
  'lead': '상태 업데이트만 하고 ToolMessage를 빠뜨리면 모델은 도구 응답을 못 받은 것으로 보고 같은 호출을 반복할 수 있습니다',
  'points': [{'h': 'Command.update', 'p': '메시지 밖의 state 필드를 갱신할 수 있습니다.'},
             {'h': 'ToolMessage', 'p': '도구 호출 ID와 짝을 맞춰 모델에게 실행 결과를 돌려줍니다.'},
             {'h': 'runtime.tool_call_id', 'p': '현재 tool_call과 ToolMessage를 연결하는 키입니다.'}],
  'code': 'from langgraph.types import Command\n'
          'from langchain.messages import ToolMessage\n'
          'from langchain.tools import tool, ToolRuntime\n'
          '\n'
          '@tool\n'
          'def remember_user_pref(theme: str, runtime: ToolRuntime) -> Command:\n'
          '    """사용자 테마 선호를 state에 기록합니다."""\n'
          '    return Command(update={\n'
          '        "user_theme": theme,\n'
          '        "messages": [ToolMessage(\n'
          '            content=f"테마를 {theme}(으)로 저장했습니다.",\n'
          '            tool_call_id=runtime.tool_call_id,\n'
          '        )],\n'
          '    })',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'Command + ToolMessage'},
 {'type': 'code-split',
  'meta': '05 / 도구와 구조화 출력',
  'title': '구조화 출력은 모델 직접 방식과 에이전트 response_format 방식이 있습니다',
  'lead': '모델만 쓸 때는 with_structured_output, 에이전트 최종 답을 강제할 때는 ToolStrategy나 ProviderStrategy를 씁니다',
  'points': [{'h': '직접 모델',
              'p': "<span class='mono'>model.with_structured_output(MySchema)</span>는 에이전트 없이 바로 스키마 객체를 돌려줍니다."},
             {'h': 'ToolStrategy', 'p': '도구 호출 메커니즘으로 구조화하므로 모든 모델에서 동작하고 안정적입니다.'},
             {'h': 'ProviderStrategy',
              'p': '지원 모델(OpenAI·Claude·Grok)의 네이티브 구조화 출력이라 더 빠르고 정확합니다. strict 옵션은 langchain>=1.2부터 지원됩니다.'}],
  'codes': [{'file': '04_tools_and_structured_output.ipynb',
             'note': 'ToolStrategy. 모든 모델',
             'code': 'from langchain.agents.structured_output import ToolStrategy\n'
                     'from dataclasses import dataclass\n'
                     '\n'
                     '@dataclass\n'
                     'class CalculationResult:\n'
                     '    expression: str\n'
                     '    result: float\n'
                     '\n'
                     'agent_structured = create_agent(model=model, tools=[calculate],\n'
                     '    response_format=ToolStrategy(CalculationResult))'},
            {'file': 'docs/langchain/09-structured-output.md',
             'note': 'ProviderStrategy. 네이티브 지원 모델',
             'code': 'from langchain.agents.structured_output import ProviderStrategy\n'
                     '\n'
                     'contact_info_schema = {\n'
                     '    "type": "object",\n'
                     '    "properties": {"name": {"type": "string"}, "email": {"type": "string"}},\n'
                     '    "required": ["name", "email"],\n'
                     '}\n'
                     '\n'
                     'agent = create_agent(model="gpt-5.4",\n'
                     '    response_format=ProviderStrategy(contact_info_schema))'}]},
 {'type': 'divider',
  'kicker': 'PART 06',
  'title': '메모리와 스트리밍',
  'sub': '대화를 저장하는 방법과 실행 상태를 실시간으로 보여주는 방법을 실제 운영 관점에서 구분합니다.',
  'lab': '02_langchain/05_memory_and_streaming.ipynb'},
 {'type': 'code-split',
  'meta': '06 / 메모리와 스트리밍',
  'title': '단기 메모리는 checkpointer가 저장하고 thread_id가 대화를 고릅니다',
  'lead': '같은 에이전트라도 thread_id가 다르면 서로 다른 대화로 격리됩니다',
  'points': [{'h': '대화 상태', 'p': '체크포인터는 메시지 히스토리와 실행 상태를 저장합니다.'},
             {'h': '세션 키', 'p': "<span class='mono'>configurable.thread_id</span>가 복원할 대화를 지정합니다."},
             {'h': '개발용', 'p': "<span class='mono'>InMemorySaver</span>는 프로세스가 꺼지면 사라지므로 실서비스는 영속 저장소가 필요합니다."}],
  'code': 'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[get_time],\n'
          '    system_prompt="대화 맥락을 기억하세요.",\n'
          '    checkpointer=InMemorySaver(),\n'
          ')\n'
          '\n'
          'config = {"configurable": {"thread_id": "session-1"}}\n'
          'agent.invoke({"messages": [{"role": "user", "content": "제 이름은 앨리스입니다."}]}, config=config)\n'
          'result = agent.invoke({"messages": [{"role": "user", "content": "제 이름이 뭔가요?"}]}, config=config)',
  'file': '05_memory_and_streaming.ipynb',
  'note': '단기 메모리'},
 {'type': 'table',
  'meta': '06 / 메모리와 스트리밍',
  'title': '단기 메모리와 장기 메모리는 저장 대상과 접근 방식이 다릅니다',
  'lead': '대화 이력은 checkpointer가 자동으로, 사용자 선호도는 store를 도구에서 명시적으로 다룹니다',
  'cols': [{'t': '구분', 'w': '24%'}, {'t': 'Checkpointer', 'w': '34%'}, {'t': 'Store', 'accent': True}],
  'rows': [['범위', "하나의 <span class='mono'>thread_id</span> 안", '여러 세션·여러 thread를 가로지름'],
           ['저장 대상', '메시지 히스토리와 그래프 상태', '사용자 선호도, 프로필, 학습 데이터'],
           ['접근 방식', '에이전트가 자동 복원', "도구가 <span class='mono'>runtime.store</span>로 명시 접근"],
           ['운영 권장', 'Postgres 체크포인터', "<span class='mono'>PostgresStore</span> + 사용자별 namespace"]]},
 {'type': 'code-split',
  'meta': '06 / 메모리와 스트리밍',
  'title': '장기 메모리는 namespace에 user_id를 넣어 사용자별로 격리합니다',
  'lead': 'store를 create_agent에 넘기지 않으면 도구 내부 runtime.store는 None이므로 도구가 실패합니다',
  'points': [{'h': 'namespace', 'p': '<span class=\'mono\'>("preferences", user_id)</span>처럼 튜플로 다층 격리를 만듭니다.'},
             {'h': 'context',
              'p': "사용자 ID는 메시지에서 파싱하지 말고 <span class='mono'>runtime.context</span>에서 받습니다. tool 인자로 넘기지 않는 이유는 LLM에 "
                   '노출되는 도구 시그니처를 깨끗하게 유지하고, 멀티테넌트 격리를 에이전트 작성자가 중앙에서 통제하기 위해서입니다.'},
             {'h': '영속화', 'p': "운영 환경에서는 <span class='mono'>langgraph-checkpoint-postgres</span> 계열 저장소를 검토합니다."}],
  'code': 'from dataclasses import dataclass\n'
          'from langgraph.store.memory import InMemoryStore\n'
          'from langchain.tools import tool, ToolRuntime\n'
          '\n'
          'store = InMemoryStore()\n'
          '\n'
          '@dataclass\n'
          'class Context:\n'
          '    user_id: str\n'
          '\n'
          '@tool\n'
          'def save_preference(key: str, value: str, runtime: ToolRuntime[Context]) -> str:\n'
          '    namespace = ("preferences", runtime.context.user_id)\n'
          '    runtime.store.put(namespace, key, {"value": value})\n'
          '    return f"저장 완료: {key}={value}"',
  'file': '05_memory_and_streaming.ipynb',
  'note': '장기 메모리'},
 {'type': 'code-split',
  'meta': '06 / 메모리와 스트리밍',
  'title': '긴 대화는 trim_messages를 before_model 미들웨어로 연결해 줄입니다',
  'lead': '대화를 무한히 누적하면 비용과 지연이 늘어나므로, 모델 호출 직전에 토큰 예산에 맞게 잘라냅니다',
  'points': [{'h': "strategy='last'", 'p': '최근 메시지를 우선 유지합니다.'},
             {'h': 'include_system', 'p': '시스템 메시지는 항상 보존합니다.'},
             {'h': 'request.override', 'p': '모델에 들어가는 메시지만 교체하고 원래 state 구조는 유지합니다.'}],
  'code': 'from langchain.messages import trim_messages\n'
          'from langchain.agents.middleware import before_model\n'
          '\n'
          'trimmer = trim_messages(\n'
          '    max_tokens=1000,\n'
          '    strategy="last",\n'
          '    token_counter=model,\n'
          '    include_system=True,\n'
          ')\n'
          '\n'
          '@before_model\n'
          'def trim_context(request):\n'
          '    trimmed = trimmer.invoke(request.state["messages"])\n'
          '    return request.override(messages=trimmed)',
  'file': '05_memory_and_streaming.ipynb',
  'note': '메시지 트리밍'},
 {'type': 'table',
  'meta': '06 / 메모리와 스트리밍',
  'title': 'stream_mode는 무엇을 실시간으로 보여줄지 결정합니다',
  'lead': '채팅 UI, 디버그 패널, 진행률 이벤트는 같은 스트리밍이라도 필요한 데이터가 다릅니다',
  'cols': [{'t': '모드', 'w': '22%'}, {'t': '보이는 것', 'w': '34%'}, {'t': '주 용도', 'accent': True}],
  'rows': [['values', '각 단계의 전체 상태', '디버깅과 상태 추적'],
           ['updates', '각 노드의 변경분', '에이전트 진행 상황 표시'],
           ['messages', '토큰 단위 메시지', '채팅 버블 렌더링'],
           ['custom', '도구·미들웨어가 직접 보낸 이벤트', '진행률, 중간 결과, 도메인 이벤트']]},
 {'type': 'dense',
  'meta': '06 / 메모리와 스트리밍',
  'title': 'v2 스트리밍은 GraphOutput과 특수 청크 규칙을 함께 이해해야 합니다',
  'lead': "노트북은 백엔드 표준 패턴으로 version='v2'와 여러 모드 동시 수신을 다룹니다",
  'groups': [{'t': 'GraphOutput. dict처럼 보지 말고 속성으로 접근합니다',
              'kids': [{'t': "<span class='mono'>result.value</span>에 최종 상태가 들어갑니다"},
                       {'t': "<span class='mono'>result.interrupts</span>에 HITL 중단 요청이 들어갑니다"}]},
             {'t': 'tool_calls 누적. 마지막 청크까지 기다립니다',
              'kids': [{'t': '토큰 스트리밍 중 tool call 인자는 부분 JSON으로 나뉘어 옵니다'},
                       {'t': "<span class='mono'>chunk_position == 'last'</span>가 보일 때 완전한 인자 형태라고 판단합니다"}]},
             {'t': 'custom mode. 도구가 진행률을 직접 흘립니다',
              'kids': [{'t': "도구 내부에서 <span class='mono'>get_stream_writer()</span>를 호출해 검색 시작·완료 같은 이벤트를 보냅니다"}]}]},
 {'type': 'divider',
  'kicker': 'PART 07',
  'title': '미들웨어 파이프라인',
  'sub': '모델 호출 전후, 모델 호출 래핑, 도구 호출 래핑, 동적 프롬프트를 한 구조로 이해합니다.',
  'lab': '02_langchain/06_middleware.ipynb'},
 {'type': 'figure',
  'meta': '07 / 미들웨어',
  'title': '미들웨어는 모델과 도구 사이에 운영 로직을 주입합니다',
  'lead': '입력 검증, 요약, 폴백, 캐싱, 로깅, 가드레일은 에이전트 본문보다 미들웨어로 분리하는 편이 좋습니다',
  'img_src': 'assets/diagrams/middleware_pipeline.png',
  'cap': 'middleware pipeline',
  'points': [{'h': 'before_model', 'p': '모델 호출 전에 메시지를 검증하거나 수정합니다.'},
             {'h': 'wrap_model_call', 'p': '모델 호출 자체를 감싸 재시도·폴백·캐싱을 구현합니다.'},
             {'h': 'wrap_tool_call', 'p': '도구 실행 전후에 권한·로깅·에러 처리를 넣습니다.'}]},
 {'type': 'table',
  'meta': '07 / 미들웨어',
  'title': '빌트인 미들웨어는 운영에서 반복되는 패턴을 바로 제공합니다',
  'lead': '직접 훅을 쓰기 전에 노트북의 기본 카탈로그부터 확인합니다',
  'cols': [{'t': '미들웨어', 'w': '34%'}, {'t': '용도', 'w': '34%'}, {'t': '트리거·특징', 'accent': True}],
  'rows': [['SummarizationMiddleware', '긴 대화 요약', "<span class='mono'>trigger=('messages', 10)</span>처럼 발동 조건 지정"],
           ['ModelFallbackMiddleware', '모델 장애 시 폴백', 'primary 실패 후 backup 모델 순차 호출'],
           ['ContextEditingMiddleware',
            '오래된 tool_use 제거',
            "<span class='mono'>trigger=('tokens', 100_000)</span>, keep 규칙"],
           ['AnthropicPromptCachingMiddleware / BedrockPromptCachingMiddleware',
            'Claude·Bedrock 캐싱 (프로바이더 전용)',
            '시스템 메시지와 도구 정의가 큰 경우 비용 절감']]},
 {'type': 'code-split',
  'meta': '07 / 미들웨어',
  'title': 'before_model과 after_model은 모델 호출 주변의 관측 지점입니다',
  'lead': '입력 로깅과 출력 로깅은 에이전트 도구 로직을 건드리지 않고도 붙일 수 있습니다',
  'points': [{'h': 'before_model', 'p': '모델에 전달될 메시지 개수, 입력 정책 위반을 확인합니다.'},
             {'h': 'after_model', 'p': '모델 응답 내용과 tool_calls를 기록하거나 후처리합니다.'},
             {'h': '조합', 'p': '여러 미들웨어를 리스트 순서대로 넣어 파이프라인을 만듭니다.'}],
  'codes': [{'file': 'before_model',
             'note': '입력 로깅',
             'code': 'from langchain.agents.middleware import before_model\n'
                     '\n'
                     '@before_model\n'
                     'def log_model_input(state, runtime):\n'
                     '    msg_count = len(state["messages"])\n'
                     '    print(f"모델 입력: {msg_count}개 메시지")'},
            {'file': 'after_model',
             'note': '출력 로깅',
             'code': 'from langchain.agents.middleware import after_model\n'
                     '\n'
                     '@after_model\n'
                     'def log_model_output(state, runtime):\n'
                     '    msg = state["messages"][-1]\n'
                     '    if getattr(msg, "tool_calls", None):\n'
                     '        print([tc["name"] for tc in msg.tool_calls])'}]},
 {'type': 'code-split',
  'meta': '07 / 미들웨어',
  'title': 'wrap_model_call은 request.override로 모델 요청을 안전하게 바꿉니다',
  'lead': 'ModelRequest를 직접 mutate하지 않고 새 요청을 만들어 handler에 넘기는 것이 노트북의 권장 패턴입니다',
  'points': [{'h': '변경 가능 필드', 'p': 'messages, tools, system_message, response_format을 override할 수 있습니다.'},
             {'h': '폴백과 제한', 'p': '비로그인 사용자의 도구를 제한하거나 모델 호출 재시도를 구현할 수 있습니다.'},
             {'h': '불변성', 'p': '원본 요청을 건드리지 않아 미들웨어 조합이 안전해집니다.'}],
  'code': 'from langchain.agents.middleware import wrap_model_call, ModelRequest, ModelResponse\n'
          '\n'
          '@wrap_model_call\n'
          'def restrict_tools_for_anonymous(request: ModelRequest, handler) -> ModelResponse:\n'
          '    user_id = request.runtime.context.get("user_id") if hasattr(request, "runtime") else None\n'
          '    if not user_id:\n'
          '        safe_tools = [t for t in request.tools if t.name == "search"]\n'
          '        return handler(request.override(\n'
          '            tools=safe_tools,\n'
          '            system_message="비로그인 사용자를 돕는 제한된 어시스턴트입니다.",\n'
          '        ))\n'
          '    return handler(request)',
  'file': '06_middleware.ipynb',
  'note': 'request.override'},
 {'type': 'code-split',
  'meta': '07 / 미들웨어',
  'title': 'wrap_tool_call은 handler 앞뒤로 도구 실행을 감쌉니다',
  'lead': 'wrap_model_call이 모델 호출을 감싸는 것과 동일한 패턴을 도구 실행에 적용해 타이밍·로깅·에러 처리를 끼워 넣습니다',
  'points': [{'h': 'ToolCallRequest',
              'p': "<span class='mono'>request.tool_call['name']</span>, <span "
                   "class='mono'>request.tool_call['args']</span>로 실행 대상 도구와 인자를 읽습니다."},
             {'h': 'handler 호출',
              'p': "<span class='mono'>handler(request)</span>를 호출해야 실제 도구가 실행되며, 호출 전후로 시간을 재면 도구별 성능을 측정할 수 있습니다."},
             {'h': '예외 처리', 'p': '도구 실행이 실패하면 예외를 잡아 로깅한 뒤 다시 던지거나, ToolMessage로 변환해 에이전트에 안전하게 알릴 수 있습니다.'}],
  'code': 'from langchain.agents.middleware import wrap_tool_call\n'
          'import time\n'
          '\n'
          '@wrap_tool_call\n'
          'def tool_timing_logger(request, handler):\n'
          '    """실행 시간을 측정하고 도구 입출력을 로깅합니다."""\n'
          '    tool_name = request.tool_call["name"]\n'
          '    start = time.perf_counter()\n'
          '    try:\n'
          '        result = handler(request)\n'
          '        elapsed = time.perf_counter() - start\n'
          '        print(f"[도구 완료] {tool_name} | {elapsed:.3f}s")\n'
          '        return result\n'
          '    except Exception as e:\n'
          '        elapsed = time.perf_counter() - start\n'
          '        print(f"[도구 실패] {tool_name} | {elapsed:.3f}s | {e}")\n'
          '        raise\n'
          '\n'
          'agent_tool_logged = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    middleware=[tool_timing_logger],\n'
          ')',
  'file': '06_middleware.ipynb',
  'note': 'handler(request) 전후 훅'},
 {'type': 'code-split',
  'meta': '07 / 미들웨어',
  'title': 'dynamic_prompt는 요청마다 시스템 프롬프트를 새로 만듭니다',
  'lead': '현재 시각, 사용자 역할, 테넌트 정책처럼 매 호출 달라지는 지침을 프롬프트에 반영합니다',
  'points': [{'h': '런타임 지침', 'p': '동일 에이전트라도 요청 컨텍스트에 따라 다른 시스템 메시지를 씁니다.'},
             {'h': 'A/B 테스트', 'p': '프롬프트 변형을 미들웨어 레벨에서 통제할 수 있습니다.'},
             {'h': '역할 전환', 'p': '후반의 핸드오프 패턴에서도 역할별 프롬프트 교체에 활용됩니다.'}],
  'code': 'from langchain.agents.middleware import dynamic_prompt\n'
          'from datetime import datetime\n'
          '\n'
          '@dynamic_prompt\n'
          'def add_datetime_context(request):\n'
          '    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")\n'
          '    return f"현재 날짜와 시간: {now}\n'
          '\n'
          '당신은 유용한 어시스턴트입니다."\n'
          '\n'
          'agent_dynamic = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    middleware=[add_datetime_context],\n'
          ')',
  'file': '06_middleware.ipynb',
  'note': 'dynamic_prompt'},
 {'type': 'code-split',
  'meta': '07 / 미들웨어',
  'title': 'wrap_tool_call은 상태 스키마가 필요한 정책과 분리해서 설계합니다',
  'lead': '도구 오류 처리만 할 때와 상태를 추가로 기록할 때의 계약이 다릅니다',
  'points': [{'h': '기본 wrapper', 'p': "단순 로깅·재시도·오류 변환은 기존 <span class='mono'>wrap_tool_call</span> 패턴을 유지합니다."},
             {'h': 'state_schema', 'p': '도구 호출 결과를 커스텀 상태 필드에 남길 때만 추가 state schema를 선언합니다.'},
             {'h': '검수 기준', 'p': '상태 업데이트가 필요한지 먼저 묻고, 필요 없으면 미들웨어를 가볍게 둡니다.'}],
  'code': 'from typing_extensions import TypedDict\n'
          'from langchain.agents.middleware import wrap_tool_call\n'
          '\n'
          'class AuditState(TypedDict):\n'
          '    tool_audit: list[str]\n'
          '\n'
          '@wrap_tool_call(state_schema=AuditState)\n'
          'def audit_tool(request, handler):\n'
          '    result = handler(request)\n'
          '    name = request.tool_call["name"]\n'
          '    return {"messages": [result], "tool_audit": [name]}',
  'file': '06_middleware.ipynb',
  'note': 'state_schema'},
 {'type': 'table',
  'meta': '03 / 모델·프로바이더',
  'title': '프로바이더 설정은 공통 모델 옵션과 벤더 전용 옵션을 분리합니다',
  'lead': 'OpenAI·Google 최신 옵션은 같은 create_agent 표면 안에서도 검증 위치가 다릅니다',
  'cols': [{'t': '항목', 'w': '28%'}, {'t': '어디에 둠', 'w': '34%'}, {'t': '수업 판단', 'accent': True}],
  'rows': [['prompt_cache_options', 'OpenAI 모델 초기화 또는 호출 설정', '긴 prefix 반복 호출에서 비용·지연을 확인'],
           ['Responses 계열 옵션', 'OpenAI provider 설정', '메시지 content 형식 회귀 테스트와 함께 확인'],
           ['reasoning_effort / thinking_config', 'Google provider 설정', '별칭과 실제 모델 지원 범위를 분리'],
           ['공통 옵션', 'temperature, timeout, max_tokens', 'provider 전용 옵션과 섞어 설명하지 않음']]},
 {'type': 'table',
  'meta': '12 / 프론트엔드',
  'title': 'Generative UI와 AG-UI는 코어 에이전트와 별도 통합 표면입니다',
  'lead': '기존 스트리밍 수업에는 개념 경계만 연결하고 React·서버 의존성은 통합 트랙에서 검증합니다',
  'cols': [{'t': '표면', 'w': '26%'}, {'t': '역할', 'w': '40%'}, {'t': '덱 반영', 'accent': True}],
  'rows': [['stream_events / useStream', '메시지·도구 호출·interrupt를 UI로 투영', '현재 프론트엔드 스트리밍 슬라이드에서 유지'],
           ['Generative UI', '모델 출력이 UI 컴포넌트 선택에 관여', 'React 실행환경이 필요하므로 별도 통합 항목'],
           ['AG-UI', '에이전트와 UI 사이의 이벤트 프로토콜', '코어 LangChain API 설명과 섞지 않음']]},
 {'type': 'dense',
  'meta': '07 / 미들웨어',
  'title': "가드레일 훅은 예외보다 jump_to='end'로 안전하게 끝내는 편이 좋습니다",
  'lead': '위험 입력을 감지했을 때 사용자에게 안내 메시지를 남기고 그래프를 종료할 수 있습니다',
  'groups': [{'t': '@hook_config(can_jump_to=[...])로 허용 점프 대상을 선언합니다',
              'kids': [{'t': "<span class='mono'>end</span>. 즉시 종료하고 안내 메시지를 남깁니다"},
                       {'t': "<span class='mono'>tools</span>. 도구 노드로 점프합니다"},
                       {'t': "<span class='mono'>model</span>. 모델 노드로 재진입합니다"}]},
             {'t': '비동기 환경에서는 a- 프리픽스 훅을 씁니다',
              'kids': [{'t': "<span class='mono'>abefore_model</span>, <span class='mono'>aafter_model</span>, <span "
                             "class='mono'>awrap_model_call</span>, <span class='mono'>adynamic_prompt</span>"}]}]},
 {'type': 'divider',
  'kicker': 'PART 08',
  'title': 'HITL과 런타임 컨텍스트',
  'sub': '위험한 도구 호출 앞에서 사람이 승인·거절할 수 있게 하는 HITL(Human-in-the-Loop) 패턴과, 도구에 실행 정보를 전달하는 ToolRuntime을 살펴봅니다.',
  'lab': '02_langchain/07_hitl_and_runtime.ipynb'},
 {'type': 'figure',
  'meta': '08 / HITL과 런타임',
  'title': 'HITL은 위험한 도구 호출 직전에 그래프를 멈춥니다',
  'lead': '이메일 전송·파일 삭제·결제처럼 되돌리기 어려운 행동은 모델 판단만으로 실행하지 않습니다',
  'img_src': 'assets/diagrams/hitl_flow.png',
  'cap': 'human-in-the-loop flow',
  'points': [{'h': '제안', 'p': '모델이 도구 호출과 인자를 만듭니다.'},
             {'h': '중단', 'p': 'HumanInTheLoopMiddleware가 interrupt를 발생시킵니다.'},
             {'h': '재개', 'p': "사람의 decision을 <span class='mono'>Command(resume=...)</span>로 넣어 실행을 이어갑니다."}]},
 {'type': 'code-split',
  'meta': '08 / HITL과 런타임',
  'title': 'HumanInTheLoopMiddleware는 checkpointer와 함께 써야 중단 후 재개됩니다',
  'lead': '중단 상태를 저장할 체크포인터가 없으면 승인 뒤 같은 지점에서 이어갈 수 없습니다',
  'points': [{'h': 'interrupt_on', 'p': '도구별 승인 필요 여부와 허용 decision을 지정합니다.'},
             {'h': 'checkpointer', 'p': "<span class='mono'>InMemorySaver</span>가 중단된 그래프 상태를 보관합니다."},
             {'h': 'thread_id', 'p': '재개할 때도 같은 thread_id를 사용해야 합니다.'}],
  'code': 'from langchain.agents.middleware import HumanInTheLoopMiddleware\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'hitl = HumanInTheLoopMiddleware(\n'
          '    interrupt_on={\n'
          '        "send_email": True,\n'
          '        "delete_file": True,\n'
          '    }\n'
          ')\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[send_email, delete_file],\n'
          '    middleware=[hitl],\n'
          '    checkpointer=InMemorySaver(),\n'
          ')',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'HITL setup'},
 {'type': 'table',
  'meta': '08 / HITL과 런타임',
  'title': 'Command(resume)의 decision은 approve·edit·reject·respond 네 가지입니다',
  'lead': 'decision 리스트 순서는 interrupt의 action_requests 순서와 맞아야 하고, edit로 인자를 바꿀 때는 보수적으로 수정해야 합니다입니다. 원래 인자를 크게 바꾸면 '
          '모델이 접근 방식을 재평가해 도구를 여러 번 실행할 수 있습니다',
  'cols': [{'t': 'decision', 'w': '24%'}, {'t': '의미', 'w': '34%'}, {'t': '결과', 'accent': True}],
  'rows': [['approve', '도구를 그대로 실행', '모델이 만든 인자를 승인합니다'],
           ['edit', '도구 인자를 수정 후 실행', '수신자·금액·파일명 같은 위험 인자를 고칩니다'],
           ['reject', '도구 실행을 거부', '거부 사유가 모델에게 전달됩니다'],
           ['respond', '사람이 직접 답변', '도구 대신 사람 답변이 ToolMessage로 전달됩니다']]},
 {'type': 'code-split',
  'meta': '08 / HITL과 런타임',
  'title': 'resume은 같은 config로 Command를 다시 invoke하는 두 단계 패턴입니다',
  'lead': '첫 invoke에서 interrupts를 확인하고, 두 번째 invoke에서 사람이 내린 결정을 넣습니다',
  'points': [{'h': '1단계', 'p': "도구 호출 제안에서 그래프가 멈추고 <span class='mono'>result.interrupts</span>가 생깁니다."},
             {'h': '2단계', 'p': "<span class='mono'>Command(resume={...})</span>를 같은 config로 넣어 재개합니다."},
             {'h': 'GraphOutput',
              'p': "v2 결과는 <span class='mono'>result.value</span>와 <span class='mono'>result.interrupts</span>로 봅니다."}],
  'code': 'from langgraph.types import Command\n'
          '\n'
          'config = {"configurable": {"thread_id": "hitl-demo"}}\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "팀에 이메일을 보내세요."}]},\n'
          '    config=config,\n'
          '    version="v2",\n'
          ')\n'
          'print(result.interrupts)\n'
          '\n'
          'result = agent.invoke(\n'
          '    Command(resume={"decisions": [{"type": "approve"}]}),\n'
          '    config=config,\n'
          '    version="v2",\n'
          ')',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'Command resume'},
 {'type': 'code-split',
  'meta': '08 / HITL과 런타임',
  'title': 'ToolRuntime[T]는 사용자 컨텍스트와 실행 메타데이터를 도구에 주입합니다',
  'lead': '권한 확인, 감사 로그, 멀티테넌트 분기는 도구 인자 대신 런타임 정보로 처리합니다',
  'points': [{'h': 'context_schema', 'p': '호출자가 넣는 사용자 컨텍스트 타입을 고정합니다.'},
             {'h': 'execution_info', 'p': 'thread_id, run_id, attempt를 로깅에 씁니다.'},
             {'h': 'server_info', 'p': '배포 환경에서는 assistant_id, graph_id, user를 권한 분리에 활용합니다.'}],
  'code': 'from dataclasses import dataclass\n'
          'from langchain.tools import tool, ToolRuntime\n'
          '\n'
          '@dataclass\n'
          'class UserContext:\n'
          '    user_id: str\n'
          '    role: str\n'
          '\n'
          '@tool\n'
          'def check_permissions(action: str, runtime: ToolRuntime[UserContext]) -> str:\n'
          '    ctx = runtime.context\n'
          '    info = runtime.execution_info\n'
          '    allowed = ctx.role == "admin" or action == "read"\n'
          '    return f"user={ctx.user_id}, thread={info.thread_id}, allowed={allowed}"',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'ToolRuntime context'},
 {'type': 'divider',
  'kicker': 'PART 09',
  'title': '멀티에이전트 패턴',
  'sub': '여러 에이전트를 두는 다섯 가지 방식 중 요구사항에 맞는 패턴을 고르고, 불필요한 오버헤드를 피하는 법을 봅니다.',
  'lab': '02_langchain/08_multi_agent.ipynb'},
 {'type': 'table',
  'meta': '09 / 멀티에이전트',
  'title': '멀티에이전트 패턴은 라우팅 주체와 상태 공유 방식이 다릅니다',
  'lead': '에이전트를 여러 개 만든다고 항상 좋아지는 것은 아닙니다. 단순 작업은 single agent가 기준입니다',
  'cols': [{'t': '패턴', 'w': '23%'}, {'t': '라우팅 주체', 'w': '28%'}, {'t': '적합한 상황', 'accent': True}],
  'rows': [['Subagents', '메인 에이전트', '독립 작업을 반복·병렬로 위임하고 결과만 취합'],
           ['Handoffs', '도구 호출·상태 전환', '대화 상태를 다음 역할로 넘기는 순차 멀티홉'],
           ['Skills', '단일 에이전트', '프롬프트를 바꿔 하나의 에이전트가 여러 역할 수행'],
           ['Router', '분류기', '입력을 도메인별 처리기로 결정론적 분배'],
           ['Custom', '개발자 정의', '다른 패턴으로 표현하기 어려운 복잡한 워크플로']]},
 {'type': 'figure',
  'meta': '09 / 멀티에이전트',
  'title': 'Subagents는 감독자가 전문 에이전트를 도구처럼 호출하는 패턴입니다',
  'lead': '서브에이전트의 내부 추론은 격리되고, 메인 에이전트는 최종 결과만 받아 컨텍스트를 아낍니다',
  'img_src': 'assets/diagrams/supervisor_subagents.png',
  'cap': 'supervisor + subagents',
  'points': [{'h': '격리', 'p': '각 subagent 호출은 독립 컨텍스트에서 실행됩니다.'},
             {'h': '반복 작업', 'p': '검색·분석을 여러 번 호출해 결과를 모으는 작업에 적합합니다.'},
             {'h': 'local history', 'p': "<span class='mono'>checkpointer=True</span>로 서브에이전트만의 히스토리를 유지할 수 있습니다."}]},
 {'type': 'dense',
  'meta': '09 / 멀티에이전트',
  'title': '서브에이전트가 많아지면 노출 방식도 설계해야 합니다',
  'lead': '도구 슬롯이 많아질수록 모델이 무엇을 호출해야 하는지 헷갈립니다',
  'groups': [{'t': '단일 dispatch 도구로 묶는 세 가지 방식',
              'kids': [{'t': 'System prompt 열거. 10개 미만일 때 단순합니다'},
                       {'t': 'Literal 인자 제약. 10~30개 규모에서 tool schema가 enum을 강제합니다'},
                       {'t': 'Tool-based discovery. 30개 이상이면 list_subagents와 describe_subagent로 동적 탐색합니다'}]},
             {'t': '장시간 서브 작업은 3-tool 패턴으로 비동기화합니다',
              'kids': [{'t': "<span class='mono'>start_job</span>. 작업 제출 후 job_id 반환"},
                       {'t': "<span class='mono'>check_status</span>. pending/running/done/failed 확인"},
                       {'t': "<span class='mono'>get_result</span>. 완료 결과 회수"}]}]},
 {'type': 'figure',
  'meta': '09 / 멀티에이전트',
  'title': 'Handoff는 결과 위임이 아니라 대화 상태 전환입니다',
  'lead': '고객지원처럼 사용자가 같은 대화에서 부서가 넘어간 느낌을 받아야 할 때 handoff를 씁니다',
  'img_src': 'assets/diagrams/handoffs_state_machine.png',
  'cap': 'handoff state machine',
  'points': [{'h': '상태 전달', 'p': '메시지 히스토리가 다음 역할로 전달됩니다.'},
             {'h': 'Command(goto)', 'p': '그래프 노드 간 전환을 명시할 수 있습니다.'},
             {'h': '단일 에이전트 대안',
              'p': "노트북은 <span class='mono'>wrap_model_call</span>로 role에 따라 프롬프트·도구를 교체하는 방식을 권장합니다."}]},
 {'type': 'figure',
  'meta': '09 / 멀티에이전트',
  'title': 'Router는 분류 후 Send로 여러 도메인에 fan-out(병렬 분산)할 때 강해집니다',
  'lead': '단일 분기만 한다면 일반 조건부 엣지와 큰 차이가 없습니다. 진짜 장점은 병렬 분배입니다',
  'img_src': 'assets/diagrams/router_fanout_fanin.png',
  'cap': 'router fan-out / fan-in',
  'points': [{'h': '분류', 'p': '입력을 math, code, general 같은 도메인으로 나눕니다.'},
             {'h': 'Send', 'p': '여러 노드에 동시에 payload를 보내 병렬 처리합니다.'},
             {'h': '취합', 'p': '도메인별 결과를 fan-in하여 최종 답변을 만듭니다.'}]},
 {'type': 'code-split',
  'meta': '09 / 멀티에이전트',
  'title': 'Skills는 에이전트를 그대로 두고 프롬프트만 갈아 끼웁니다',
  'lead': '별도 에이전트나 그래프 전환 없이, 도구 호출로 전문 지침을 그때그때 불러오는 점진적 공개 패턴입니다',
  'points': [{'h': '단일 에이전트', 'p': "<span class='mono'>skill_agent</span> 하나가 번역·요약·코딩 역할을 모두 처리합니다."},
             {'h': '점진적 공개', 'p': "스킬을 한꺼번에 시스템 프롬프트에 넣지 않고, <span class='mono'>load_skill</span> 호출 시점에만 지침을 노출합니다."},
             {'h': '프롬프트 교체', 'p': '역할 전환이 상태 전달(Handoffs)이나 분류(Router) 없이 도구 반환값 교체로 일어납니다.'}],
  'code': 'skills = {\n'
          '    "translator": "당신은 전문 번역가입니다. 언어 간 텍스트를 정확하게 번역하세요.",\n'
          '    "summarizer": "당신은 전문 요약가입니다. 긴 텍스트를 간결하게 요약하세요.",\n'
          '    "coder": "당신은 전문 프로그래머입니다. 깔끔하고 효율적인 코드를 작성하세요.",\n'
          '}\n'
          '\n'
          '@tool\n'
          'def load_skill(skill_name: str) -> str:\n'
          '    """전문 스킬을 로드합니다. 사용 가능한 스킬: translator, summarizer, coder."""\n'
          '    if skill_name in skills:\n'
          '        return f"스킬 로드 완료: {skill_name}. 지침: {skills[skill_name]}"\n'
          '    return f"알 수 없는 스킬: {skill_name}"\n'
          '\n'
          'skill_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[load_skill],\n'
          '    system_prompt="사용자의 요청을 처리하기 전에 적절한 스킬을 로드하세요.",\n'
          ')',
  'file': '08_multi_agent.ipynb',
  'note': 'load_skill로 프롬프트만 교체'},
 {'type': 'table',
  'meta': '09 / 멀티에이전트',
  'title': '멀티에이전트 선택 기준은 독립성·상태 전달·역할 전환입니다',
  'lead': '처음부터 복잡한 팀 구조로 가지 말고, 질문 세 개로 패턴을 좁힙니다',
  'cols': [{'t': '질문', 'w': '42%'}, {'t': 'YES', 'w': '26%'}, {'t': 'NO', 'accent': True}],
  'rows': [['에이전트가 독립적으로 작업 가능한가', 'Subagents', '상태 전달 필요성 확인'],
           ['대화 상태가 다음 역할로 넘어가야 하는가', 'Handoffs', 'Skills 또는 Router 검토'],
           ['하나의 에이전트가 프롬프트만 바꾸면 되는가', 'Skills', 'Custom StateGraph'],
           ['입력 분류 후 처리기로 보내면 충분한가', 'Router', '직접 워크플로 설계']]},
 {'type': 'divider',
  'kicker': 'PART 10',
  'title': '커스텀 워크플로와 RAG',
  'sub': 'StateGraph로 흐름을 직접 설계하는 법과, RAG(Retrieval-Augmented Generation, 검색 증강 생성)로 검색 결과를 답변에 반영하는 법을 연결합니다.',
  'lab': '02_langchain/09_custom_workflow_and_rag.ipynb'},
 {'type': 'figure',
  'meta': '10 / 워크플로와 RAG',
  'title': 'StateGraph는 노드·엣지·상태로 실행 흐름을 명시합니다',
  'lead': 'create_agent가 감춰 주던 흐름을 직접 그려야 할 때 LangGraph의 StateGraph를 사용합니다',
  'img_src': 'assets/diagrams/stategraph_structure.png',
  'cap': 'StateGraph structure',
  'points': [{'h': 'State', 'p': "노드들이 공유하는 데이터 구조입니다. 노트북은 <span class='mono'>TypedDict</span>로 정의합니다."},
             {'h': 'Node', 'p': '상태를 받아 일부 필드를 업데이트하는 함수입니다.'},
             {'h': 'Edge', 'p': '다음에 실행할 노드를 정하는 연결입니다.'}]},
 {'type': 'code-split',
  'meta': '10 / 워크플로와 RAG',
  'title': '기본 StateGraph는 상태 타입을 정하고 노드를 연결한 뒤 compile합니다',
  'lead': '노드는 전체 상태를 다시 만들지 않고 바뀐 필드만 dict로 반환합니다',
  'points': [{'h': 'TypedDict', 'p': '상태 키와 타입을 명시합니다.'},
             {'h': 'add_node', 'p': '처리 함수를 그래프 노드로 등록합니다.'},
             {'h': 'compile', 'p': '빠진 연결·도달 불가 노드 같은 구조 오류를 잡습니다.'}],
  'code': 'from typing import TypedDict\n'
          'from langgraph.graph import StateGraph, START, END\n'
          '\n'
          'class WorkflowState(TypedDict):\n'
          '    text: str\n'
          '    category: str\n'
          '    result: str\n'
          '\n'
          'def preprocess(state: WorkflowState) -> dict:\n'
          '    return {"text": state["text"].strip()}\n'
          '\n'
          'def analyze(state: WorkflowState) -> dict:\n'
          '    return {"result": f"분석 완료: {state[\'text\']}"}\n'
          '\n'
          'builder = StateGraph(WorkflowState)\n'
          'builder.add_node("preprocess", preprocess)\n'
          'builder.add_node("analyze", analyze)\n'
          'builder.add_edge(START, "preprocess")\n'
          'builder.add_edge("preprocess", "analyze")\n'
          'builder.add_edge("analyze", END)\n'
          'graph = builder.compile()',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'StateGraph 기본'},
 {'type': 'code-split',
  'meta': '10 / 워크플로와 RAG',
  'title': '조건부 엣지는 런타임 상태에 따라 다음 노드를 고릅니다',
  'lead': '입력 분류 후 math·language·general 핸들러로 나누는 패턴은 라우터의 기초입니다',
  'points': [{'h': 'classify', 'p': '상태에 category를 기록합니다.'},
             {'h': 'route', 'p': '상태를 보고 다음 노드 이름을 반환합니다.'},
             {'h': 'mapping', 'p': '반환값을 실제 노드에 매핑합니다.'}],
  'code': 'def route(state: RouterState) -> str:\n'
          '    return state["category"]\n'
          '\n'
          'builder.add_conditional_edges(\n'
          '    "classify",\n'
          '    route,\n'
          '    {\n'
          '        "math": "handle_math",\n'
          '        "language": "handle_language",\n'
          '        "general": "handle_general",\n'
          '    },\n'
          ')',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'conditional edges'},
 {'type': 'flow',
  'meta': '10 / 워크플로와 RAG',
  'title': '에이전트를 노드로 넣으면 리서치와 작성 파이프라인을 분리할 수 있습니다',
  'lead': '노트북의 research → writer 예제는 에이전트를 함수 노드처럼 연결하는 방법을 보여줍니다',
  'nodes': [{'h': 'USER', 'p': 'question', 'note': '사용자 질문이 MessagesState로 들어옵니다.'},
            {'h': 'RESEARCH', 'p': 'create_agent', 'note': '검색 도구를 가진 리서치 에이전트가 근거를 모읍니다.', 'hl': True},
            {'h': 'WRITER', 'p': 'create_agent', 'note': '작성 에이전트가 보고서 형태로 정리합니다.'},
            {'h': 'END', 'p': 'report', 'note': '최종 메시지를 응답으로 반환합니다.'}],
  'sum': 'RAG의 Rewrite → Retrieve → Agent 3노드 패턴도 같은 생각입니다. 검색 친화 질의로 바꾸고, 문서를 가져오고, 에이전트가 답합니다.'},
 {'type': 'table',
  'meta': '10 / 워크플로와 RAG',
  'title': 'RAG는 검색과 생성을 결합하지만 구현 방식은 세 가지입니다',
  'lead': '처음에는 2단계로 시작하고, 검색 판단이 필요해지면 에이전틱 RAG로 확장합니다',
  'cols': [{'t': '패턴', 'w': '26%'}, {'t': '흐름', 'w': '36%'}, {'t': '특징', 'accent': True}],
  'rows': [['기본 2단계', '검색 → 생성', '단순하고 빠르며 디버깅이 쉽습니다'],
           ['에이전틱 RAG', '에이전트가 검색 도구 반복 호출', '질문이 모호하거나 검색 전략이 달라질 때 유연합니다'],
           ['하이브리드', '키워드 + 시맨틱 검색', '정확도와 재현율을 함께 챙깁니다']]},
 {'type': 'code-split',
  'meta': '10 / 워크플로와 RAG',
  'title': '긴 문서는 chunk_size와 overlap으로 잘라 임베딩에 맞춥니다',
  'lead': 'RecursiveCharacterTextSplitter가 RAG 파이프라인의 첫 번째 실전 단계입니다',
  'points': [{'h': 'chunk_size',
              'p': "<span class='mono'>chunk_size</span>는 한 청크의 최대 문자 수로, 임베딩 모델의 컨텍스트 한도에 맞춰 조절합니다."},
             {'h': 'chunk_overlap',
              'p': "<span class='mono'>chunk_overlap</span>은 인접 청크가 겹치는 구간으로, 문장이 경계에서 끊겨도 맥락 손실을 줄입니다."},
             {'h': 'split_text', 'p': '문서별로 호출해 chunks 리스트에 누적하며, 이후 임베딩·검색의 입력 단위가 됩니다.'}],
  'code': 'from langchain_text_splitters import RecursiveCharacterTextSplitter\n'
          '\n'
          'text_splitter = RecursiveCharacterTextSplitter(\n'
          '    chunk_size=200,\n'
          '    chunk_overlap=50,\n'
          ')\n'
          '\n'
          'chunks = []\n'
          'for doc in documents:\n'
          '    chunks.extend(text_splitter.split_text(doc))\n'
          '\n'
          'print(f"원본 문서: {len(documents)}개, 분할 청크: {len(chunks)}개")',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'chunk_size=200, chunk_overlap=50'},
 {'type': 'code-split',
  'meta': '10 / 워크플로와 RAG',
  'title': '벡터 스토어 없이도 @tool 하나로 에이전트가 검색을 수행합니다',
  'lead': '단어 집합 교집합만으로 만든 simple_search를 retrieve_info 도구로 감싸 에이전트에 연결합니다',
  'points': [{'h': 'simple_search', 'p': '쿼리·문서를 소문자 단어 집합으로 바꿔 교집합 크기를 점수로 사용합니다. 임베딩이 없어도 동작합니다.'},
             {'h': '@tool retrieve_info', 'p': '검색 로직을 도구로 노출해 에이전트가 필요할 때 호출합니다.'},
             {'h': 'create_agent', 'p': 'system_prompt로 항상 retrieve_info 호출을 강제해 근거 없는 답변을 방지합니다.'}],
  'code': 'def simple_search(query: str, documents: list[str], top_k: int = 2) -> list[str]:\n'
          '    """간단한 키워드 기반 검색입니다."""\n'
          '    scores = []\n'
          '    query_words = set(query.lower().split())\n'
          '    for doc in documents:\n'
          '        doc_words = set(doc.lower().split())\n'
          '        score = len(query_words & doc_words)\n'
          '        scores.append((score, doc))\n'
          '    scores.sort(reverse=True)\n'
          '    return [doc for _, doc in scores[:top_k]]\n'
          '\n'
          '@tool\n'
          'def retrieve_info(query: str) -> str:\n'
          '    """지식 베이스에서 관련 정보를 검색합니다."""\n'
          '    results = simple_search(query, chunks, top_k=3)\n'
          '    return "\\n\\n".join(results)\n'
          '\n'
          'rag_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[retrieve_info],\n'
          '    system_prompt="항상 retrieve_info 도구를 사용하여 정보를 검색한 후 답변하세요.",\n'
          ')',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': '단어 교집합 점수로 top_k=3 문서 반환'},
 {'type': 'code-split',
  'meta': '10 / 워크플로와 RAG',
  'title': '임베딩과 FAISS를 연결하면 의미 기반 유사도 검색이 가능합니다',
  'lead': '키워드가 겹치지 않아도 의미가 비슷한 청크를 찾아내는 임베딩 모델 + 벡터 스토어 조합입니다',
  'points': [{'h': 'OpenAIEmbeddings', 'p': "<span class='mono'>text-embedding-3-small</span> 모델로 청크를 의미 벡터로 변환합니다."},
             {'h': 'FAISS.from_texts', 'p': '청크와 임베딩 함수를 받아 벡터 스토어를 즉시 생성합니다.'},
             {'h': 'similarity_search', 'p': '쿼리를 벡터로 바꿔 k=3 최근접 청크를 반환합니다. 단어 매칭이 아닌 의미 매칭입니다.'}],
  'code': 'from langchain_openai import OpenAIEmbeddings\n'
          'from langchain_community.vectorstores import FAISS\n'
          '\n'
          'embeddings = OpenAIEmbeddings(model="text-embedding-3-small")\n'
          'vectorstore = FAISS.from_texts(chunks, embeddings)\n'
          '\n'
          'results = vectorstore.similarity_search("LangChain agent patterns", k=3)\n'
          'for doc in results:\n'
          '    print(doc.page_content)',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'text-embedding-3-small + FAISS, k=3 유사도 검색'},
 {'type': 'table',
  'meta': '10 / 워크플로와 RAG',
  'title': 'LangChain RAG는 다섯 빌딩 블록으로 나누어 설계합니다',
  'lead': '노트북은 간단 검색과 FAISS 예제로 검색 보강의 구조를 먼저 익힙니다',
  'cols': [{'t': '블록', 'w': '26%'}, {'t': '대표 클래스', 'w': '34%'}, {'t': '역할', 'accent': True}],
  'rows': [['Document Loaders', 'PyPDFLoader, WebBaseLoader', '파일·웹·DB를 Document로 적재'],
           ['Text Splitters', 'RecursiveCharacterTextSplitter', '긴 문서를 청크로 분할'],
           ['Embedding Models', 'OpenAIEmbeddings', '텍스트를 의미 벡터로 변환'],
           ['Vector Stores', 'FAISS, Chroma, Pinecone', '임베딩 저장과 유사도 검색'],
           ['Retrievers', 'vectorstore.as_retriever()', '검색 인터페이스와 재순위·필터']]},
 {'type': 'divider',
  'kicker': 'PART 11',
  'title': '프로덕션 운영',
  'sub': '로컬 디버깅 도구부터 배포·평가·관측성까지, 에이전트를 운영에 올리기 위한 체크리스트를 정리합니다.',
  'lab': '02_langchain/10_production.ipynb'},
 {'type': 'table',
  'meta': '11 / 프로덕션',
  'title': '프로덕션 준비는 로컬 디버그에서 배포 후 관측성까지 이어집니다',
  'lead': '에이전트가 한 번 잘 답하는 것과 계속 운영되는 것은 다른 문제입니다',
  'cols': [{'t': '단계', 'w': '24%'}, {'t': '도구', 'w': '34%'}, {'t': '확인할 것', 'accent': True}],
  'rows': [['로컬 개발', 'LangSmith Studio + langgraph dev', '노드·도구 호출·상태를 시각적으로 디버깅'],
           ['테스트', 'GenericFakeChatModel, pytest', 'API 비용 없이 결정론적 흐름 검증'],
           ['평가', 'agentevals trajectory match', '도구 호출 순서와 포함 관계 검증'],
           ['배포', 'LangGraph Platform 또는 Docker', 'repo, branch, langgraph.json, env 지정'],
           ['관측성', 'LangSmith tracing', '토큰·비용·지연·에러·전체 trace 추적']]},
 {'type': 'code-split',
  'meta': '11 / 프로덕션',
  'title': 'langgraph.json은 로컬 Studio와 배포가 읽는 그래프 진입점입니다',
  'lead': '노트북은 langgraph dev 서버와 LangSmith Studio(로컬 디버깅용 시각화 UI)를 연결해 핫 리로드·스레드 재실행을 확인합니다',
  'points': [{'h': '그래프 경로', 'p': '어떤 파일의 어떤 객체가 실행 그래프인지 지정합니다.'},
             {'h': '로컬 서버', 'p': "<span class='mono'>langgraph dev</span>가 127.0.0.1:2024에서 서버를 띄웁니다."},
             {'h': 'Studio', 'p': 'Hosted Studio가 local baseUrl로 접속해 trace와 상태를 보여줍니다.'}],
  'code': '{\n  "dependencies": ["."],\n  "graphs": {\n    "agent": "./agent.py:agent"\n  },\n  "env": ".env"\n}',
  'file': 'langgraph.json',
  'note': 'Studio 진입점'},
 {'type': 'code-split',
  'meta': '11 / 프로덕션',
  'title': 'REST로 직접 호출할 때는 assistant_id·input·stream_mode를 페이로드에 담습니다',
  'lead': 'SDK 없이 curl만으로도 배포된 그래프를 그대로 스트리밍 호출할 수 있습니다',
  'points': [{'h': '엔드포인트', 'p': "<span class='mono'>POST /runs/stream</span>이 실행과 스트리밍을 함께 처리합니다."},
             {'h': '페이로드',
              'p': "<span class='mono'>assistant_id</span>, <span class='mono'>input</span>, <span "
                   "class='mono'>stream_mode</span> 세 필드가 핵심입니다."},
             {'h': '배포 인증', 'p': 'Platform deployment에서는 LangSmith API key를 헤더로 함께 보냅니다.'}],
  'code': 'curl -X POST http://127.0.0.1:2024/runs/stream \\\n'
          '  -H "Content-Type: application/json" \\\n'
          "  --data '{\n"
          '    "assistant_id": "agent",\n'
          '    "input": {"messages": [{"role": "user", "content": "안녕하세요"}]},\n'
          '    "stream_mode": "updates"\n'
          "  }'\n"
          '\n'
          '# Platform deployment에서는 LangSmith API key를 함께 보냅니다.\n'
          '#   -H "X-Api-Key: $LANGSMITH_API_KEY"',
  'file': '10_production.ipynb',
  'note': 'REST로 직접 호출'},
 {'type': 'code-split',
  'meta': '11 / 프로덕션',
  'title': 'GenericFakeChatModel은 API 호출 없이 에이전트 로직을 고정 테스트합니다',
  'lead': 'CI에서는 실제 모델의 변동성보다 도구 호출과 상태 전이가 의도대로 일어나는지가 먼저입니다',
  'points': [{'h': '결정론', 'p': '항상 같은 메시지를 내므로 테스트가 흔들리지 않습니다.'},
             {'h': '비용 0', 'p': '외부 API 호출 없이 빠르게 돌릴 수 있습니다.'},
             {'h': '로직 검증', 'p': '프롬프트 품질이 아니라 도구 호출 경로와 파싱을 봅니다.'}],
  'code': 'from langchain_core.language_models import GenericFakeChatModel\n'
          'from langchain.messages import AIMessage\n'
          '\n'
          'fake_model = GenericFakeChatModel(messages=iter([\n'
          '    AIMessage(content="서울"),\n'
          ']))\n'
          '\n'
          'test_agent = create_agent(\n'
          '    model=fake_model,\n'
          '    tools=[get_capital],\n'
          '    system_prompt="수도 질문에 답하세요.",\n'
          ')',
  'file': '10_production.ipynb',
  'note': 'fake model test'},
 {'type': 'table',
  'meta': '11 / 프로덕션',
  'title': 'trajectory 평가는 에이전트가 어떤 도구를 어떤 순서로 썼는지 검증합니다',
  'lead': '최종 답만 맞아도 위험한 도구를 잘못 썼다면 프로덕션 테스트는 실패해야 합니다',
  'cols': [{'t': '모드', 'w': '24%'}, {'t': '의미', 'w': '36%'}, {'t': '사용 장면', 'accent': True}],
  'rows': [['strict', '도구가 같은 순서로 호출되어야 함', '정확한 프로세스가 중요한 워크플로'],
           ['unordered', '도구 집합만 같으면 순서 무관', '병렬·순서 비민감 작업'],
           ['subset', '기대 경로가 실제 경로에 포함', '추가 탐색은 허용하지만 필수 행동은 검증'],
           ['superset', '실제 경로가 기대 경로를 포함', '최소 기준보다 더 많은 행동을 허용']]},
 {'type': 'dense',
  'meta': '11 / 프로덕션',
  'title': '프로덕션 체크리스트는 보안과 운영 항목을 코드와 같은 수준으로 봅니다',
  'lead': '테스트가 통과해도 키 관리·관측성·문서화가 없으면 운영 준비가 끝난 것이 아닙니다',
  'groups': [{'t': '출시 전',
              'kids': [{'t': '단위 테스트와 트라젝토리 평가를 자동화합니다'},
                       {'t': 'API 키와 env를 배포 환경에서 주입하고 코드에 남기지 않습니다'},
                       {'t': '입력 검증과 가드레일을 미들웨어로 분리합니다'}]},
             {'t': '출시 후',
              'kids': [{'t': 'LangSmith로 전체 실행 흐름, 토큰, 지연, 에러를 추적합니다'},
                       {'t': 'Agent Chat UI로 스트리밍·도구 호출·HITL을 수동 점검합니다'},
                       {'t': '장애 시 재현 가능한 thread와 trace를 남깁니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 12',
  'title': 'MCP 도구 연결',
  'sub': 'MCP가 서버·클라이언트로 어떻게 나뉘는지, 로컬(stdio)과 원격(streamable-http) 연결을 어떻게 고르는지 봅니다.',
  'lab': '02_langchain/11_mcp.ipynb'},
 {'type': 'table',
  'meta': '12 / MCP',
  'title': 'MCP는 서버·클라이언트·호스트가 역할을 나누는 도구 연결 규격입니다',
  'lead': '도구마다 전용 연결 코드를 만들지 않고, MCP 서버 한 번 구현으로 여러 호스트가 재사용합니다',
  'cols': [{'t': '구성 요소', 'w': '26%'}, {'t': '역할', 'w': '36%'}, {'t': 'LangChain에서 보는 형태', 'accent': True}],
  'rows': [['MCP 서버', 'Tools, Resources, Prompts를 노출', 'FastMCP 서버, 파일시스템 서버, DB 서버'],
           ['MCP 클라이언트',
            '서버에 연결해 도구와 리소스를 가져옴',
            "<span class='mono'>MCPAdapter</span> + <span class='mono'>list_tools()</span>"],
           ['호스트', 'LLM과 클라이언트를 관리', 'LangChain agent, IDE, 챗 UI'],
           ['Resources', '파일·DB 레코드 같은 데이터', 'LangChain Blob 객체로 변환']]},
 {'type': 'code-split',
  'meta': '12 / MCP',
  'title': 'stdio는 로컬 개발용, streamable-http는 원격 MCP 서버용입니다',
  'lead': '전송 방식은 서버가 어디에서 어떻게 떠 있는지에 따라 달라집니다',
  'points': [{'h': 'stdio', 'p': '로컬 서브프로세스로 서버를 실행해 표준 입출력으로 통신합니다.'},
             {'h': 'streamable-http', 'p': '원격 서버 URL과 인증 헤더를 가진 웹 기반 연결입니다.'},
             {'h': '인증', 'p': '정적 Bearer 헤더, 커스텀 httpx.Auth, MCP OAuth2 흐름을 상황별로 씁니다.'}],
  'codes': [{'file': 'stdio_config',
             'note': '로컬 서버',
             'code': 'import sys\n'
                     'stdio_config = {\n'
                     '    "math": {\n'
                     '        "transport": "stdio",\n'
                     '        "command": sys.executable,\n'
                     '        "args": ["/tmp/lc_mcp_math_server.py"],\n'
                     '    }\n'
                     '}'},
            {'file': 'http_config',
             'note': '원격 서버',
             'code': 'import os\n'
                     'http_config = {\n'
                     '    "weather": {\n'
                     '        "transport": "streamable_http",\n'
                     '        "url": "https://weather.example.com/mcp",\n'
                     '        "headers": {"Authorization": f"Bearer {os.environ[\'MCP_TOKEN\']}"},\n'
                     '    }\n'
                     '}'}]},
 {'type': 'code-split',
  'meta': '12 / MCP',
  'title': 'MCP 도구는 MCPAdapter 컨텍스트에서 list_tools()로 가져옵니다',
  'lead': 'LangChain 입장에서는 MCP 서버의 도구도 일반 Tool 리스트처럼 바인딩됩니다',
  'points': [{'h': '새 namespace',
              'p': "LangChain 1.4 기준 MCP는 <span class='mono'>langchain.mcp</span>의 beta API로 들어왔습니다."},
             {'h': '수명 주기', 'p': "<span class='mono'>async with MCPAdapter(...)</span> 안에서 연결을 열고 닫습니다."},
             {'h': '도구 발견',
              'p': "기존 <span class='mono'>get_tools()</span> 대신 <span class='mono'>list_tools()</span>를 호출합니다."}],
  'code': 'from langchain.mcp import MCPAdapter\n'
          '\n'
          'async def run_math_agent():\n'
          '    async with MCPAdapter(stdio_config) as adapter:\n'
          '        tools = await adapter.list_tools()\n'
          '        agent = create_agent(\n'
          '            model=model,\n'
          '            tools=tools,\n'
          '            system_prompt="MCP math 도구를 사용할 수 있습니다.",\n'
          '        )\n'
          '        return await agent.ainvoke({"messages": [{"role": "user", "content": "2와 3을 더해 주세요."}]})',
  'file': '11_mcp.ipynb',
  'note': 'MCP tools → agent'},
 {'type': 'code-split',
  'meta': '12 / MCP',
  'title': '원격 MCP 인증은 FastMCP Client나 transport에서 관리합니다',
  'lead': '원격 인증은 서버 설정 딕셔너리에 auth 객체를 끼우는 방식이 아니라 FastMCP Client가 소유합니다',
  'points': [{'h': '정적 토큰', 'p': '<span class=\'mono\'>Client(url, auth="Bearer ...")</span>로 토큰 수명과 연결을 한곳에 둡니다.'},
             {'h': 'OAuth',
              'p': '<span class=\'mono\'>Client(url, auth="oauth")</span>로 FastMCP가 OAuth 흐름과 저장소를 관리하게 합니다.'},
             {'h': '여러 서버',
              'p': "<span class='mono'>ClientGroup</span>으로 서버별 인증을 유지한 채 하나의 MCPAdapter target으로 넘깁니다."}],
  'code': '# FastMCP Client / ClientGroup 기반 인증 구성 예시(객체 생성만 수행)\n'
          'from fastmcp import Client, ClientGroup\n'
          '\n'
          'weather_client = Client(\n'
          '    "https://weather-mcp.example.com/mcp",\n'
          '    auth="Bearer ${WEATHER_MCP_TOKEN}",\n'
          ')\n'
          'calendar_client = Client("https://calendar.example.com/mcp", auth="oauth")\n'
          'auth_group = ClientGroup({"weather": weather_client, "calendar": calendar_client})\n'
          'print(type(auth_group).__name__, list(auth_group.clients))',
  'file': '11_mcp.ipynb',
  'note': 'cell 15'},
 {'type': 'code-split',
  'meta': '12 / MCP',
  'title': 'FastMCP 데코레이터 하나로 직접 MCP 서버를 만듭니다',
  'lead': '@mcp.tool()과 @mcp.resource()로 함수를 노출하면 그 서버는 MCPAdapter target으로 연결됩니다',
  'points': [{'h': '@mcp.tool()', 'p': '일반 함수를 그대로 MCP 도구로 등록합니다. 타입 힌트가 곧 스키마입니다.'},
             {'h': '@mcp.resource()', 'p': "<span class='mono'>config://app</span> 같은 URI로 정적·동적 리소스를 노출합니다."},
             {'h': '연결 흐름', 'p': '서버 스크립트를 MCPAdapter target에 등록 → list_tools() → create_agent(tools=...)입니다.'}],
  'code': 'from fastmcp import FastMCP\n'
          '\n'
          'mcp = FastMCP("my-tools")\n'
          '\n'
          '@mcp.tool()\n'
          'def add(a: int, b: int) -> int:\n'
          '    return a + b\n'
          '\n'
          '@mcp.resource("config://app")\n'
          'def get_config() -> str:\n'
          '    return \'{"version": "1.0"}\'\n'
          '\n'
          'if __name__ == "__main__":\n'
          '    mcp.run(transport="stdio")',
  'file': '11_mcp.ipynb',
  'note': 'FastMCP 커스텀 서버'},
 {'type': 'dense',
  'meta': '12 / MCP',
  'title': 'MCP 운영은 Elicitation과 LangGraph interrupt까지 함께 봐야 합니다',
  'lead': '연결만 되는 데서 끝나지 않고, 사용자 입력 요청과 도구 호출 정책을 설계해야 합니다',
  'groups': [{'t': 'MCPAdapter는 여러 서버를 한 구성으로 묶습니다',
              'kids': [{'t': 'MCPConfig의 mcpServers에 math, weather, database처럼 이름을 붙여 도구 출처를 구분합니다'},
                       {'t': 'async with MCPAdapter(target) 블록 안에서 연결 수명 주기와 도구 발견을 관리합니다'}]},
             {'t': 'Elicitation은 InputRequiredResult 기반 interrupt로 처리합니다',
              'kids': [{'t': "현대 MCP 서버가 반환하는 <span class='mono'>InputRequiredResult</span>가 LangGraph interrupt로 "
                             '노출됩니다'},
                       {'t': "<span class='mono'>payload.requests[0].key</span>를 읽고 <span "
                             "class='mono'>responses[key]</span>에 accept/decline/cancel answer object를 넣습니다"},
                       {'t': "legacy <span class='mono'>ctx.elicit(...)</span> 푸시 핸드셰이크는 이 수업의 재개 계약으로 설명하지 않습니다"}]},
             {'t': '도구 호출 정책은 LangChain middleware에서 처리합니다',
              'kids': [{'t': "MCP metadata를 확인해 로깅·차단·감사를 <span class='mono'>@wrap_tool_call</span> 표면에 둡니다"}]}]},
 {'type': 'divider',
  'kicker': 'PART 13',
  'title': '프론트엔드 스트리밍',
  'sub': '백엔드가 내보내는 여러 층의 스트림을 프런트엔드가 어떻게 받아서 채팅 UI로 보여주는지 구분합니다.',
  'lab': '02_langchain/12_frontend_streaming.ipynb'},
 {'type': 'table',
  'meta': '13 / 프론트엔드 스트리밍',
  'title': '스트리밍 API는 저수준 토큰에서 UI projection까지 층이 나뉩니다',
  'lead': 'UI가 필요한 것은 토큰뿐 아니라 도구 타임라인, 상태 스냅샷, 최종 출력입니다',
  'cols': [{'t': 'API', 'w': '30%'}, {'t': '보이는 것', 'w': '34%'}, {'t': '적합한 UI', 'accent': True}],
  'rows': [['.stream()', '토큰 또는 stream_mode별 청크', '간단한 콘솔·채팅 토큰 출력'],
           ['.astream_events()', 'on_chat_model_start/end, on_tool_start/end', '세밀한 이벤트 로그·디버그 타임라인'],
           ["stream_events(version='v3')", 'messages, tool_calls, values, output projection', 'Agent UI의 표준 데이터 모델'],
           ['useStream', 'React 훅의 messages, interrupt, error, submit', '브라우저 채팅 UI']]},
 {'type': 'code-split',
  'meta': '13 / 프론트엔드 스트리밍',
  'title': 'astream_events(version="v2")는 모델 호출의 시작·진행·종료를 구분합니다',
  'lead': '토큰만 필요하면 stream()으로 충분하지만, 모델 호출의 생애주기를 세밀히 추적할 때는 내부 이벤트를 그대로 받습니다',
  'points': [{'h': 'event 필드',
              'p': "<span class='mono'>event['event']</span> 문자열로 종류를 구분합니다. on_chat_model_start / "
                   'on_chat_model_stream / on_chat_model_end입니다.'},
             {'h': '토큰 추출',
              'p': "<span class='mono'>on_chat_model_stream</span>일 때만 event['data']['chunk'].content에 실제 토큰이 담깁니다."},
             {'h': '비동기 전용', 'p': "<span class='mono'>async for</span> 구조라 동기 stream()과 달리 async 함수 안에서만 소비할 수 있습니다."}],
  'code': 'async for event in model.astream_events(\n'
          '    "파이썬의 장점 2가지",\n'
          '    version="v2",\n'
          '):\n'
          '    kind = event["event"]\n'
          '    if kind == "on_chat_model_stream":\n'
          '        content = event["data"]["chunk"].content\n'
          '        if content:\n'
          '            print(content, end="", flush=True)\n'
          '    elif kind == "on_chat_model_start":\n'
          '        print("[모델 호출 시작]")\n'
          '    elif kind == "on_chat_model_end":\n'
          '        print("\\n[모델 호출 완료]")',
  'file': '12_frontend_streaming.ipynb',
  'note': 'astream_events v2'},
 {'type': 'code-split',
  'meta': '13 / 프론트엔드 스트리밍',
  'title': 'Event Streaming v3는 메시지·도구·상태를 projection으로 분리합니다',
  'lead': "LangChain 1.3+에서는 agent 실행 UI에 stream_events(version='v3')를 우선 검토합니다",
  'points': [{'h': 'messages', 'p': '채팅 버블로 렌더링할 모델 메시지와 token delta입니다.'},
             {'h': 'tool_calls', 'p': '도구 시작·출력·완료·오류를 타임라인으로 보여줍니다.'},
             {'h': 'output', 'p': '최종 state를 저장하거나 후처리합니다.'}],
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'def get_weather(city: str) -> str:\n'
          '    """도시 날씨를 조회합니다."""\n'
          '    return f"{city}: 맑음"\n'
          '\n'
          'agent = create_agent(model="openai:gpt-5.4", tools=[get_weather])\n'
          'stream = agent.stream_events(\n'
          '    {"messages": [{"role": "user", "content": "서울 날씨 알려줘"}]},\n'
          '    version="v3",\n'
          ')\n'
          '\n'
          'for message in stream.messages:\n'
          '    for token in message.text:\n'
          '        print(token, end="", flush=True)\n'
          'final_state = stream.output',
  'file': '12_frontend_streaming.ipynb',
  'note': 'Event Streaming v3'},
 {'type': 'table',
  'meta': '13 / 프론트엔드 스트리밍',
  'title': 'useStream은 스레드·재연결·중단·커스텀 이벤트를 한 훅으로 묶습니다',
  'lead': 'React UI는 서버 스트림을 직접 파싱하기보다 훅의 상태와 콜백으로 렌더링합니다',
  'cols': [{'t': '옵션·값', 'w': '30%'}, {'t': '역할', 'w': '34%'}, {'t': '운영 포인트', 'accent': True}],
  'rows': [['assistantId / apiUrl', '어떤 배포 그래프와 통신할지 지정', '로컬은 127.0.0.1:2024, 배포는 Deployment URL'],
           ['threadId / onThreadId', '대화를 이어갈 스레드 관리', 'URL 파라미터나 localStorage에 보관 가능'],
           ['reconnectOnMount', '새로고침 뒤 진행 중 스트림 재연결', '긴 실행 작업에서 사용자 경험 유지'],
           ['interrupt', 'HITL 중단 요청 표시', 'approve/edit/reject/respond UI로 연결'],
           ['onCustomEvent', '진행률·중간 결과 수신', '도구 내부 writer 이벤트와 매핑']]},
 {'type': 'code-split',
  'meta': '13 / 프론트엔드 스트리밍',
  'title': 'useStream 훅 하나로 메시지·로딩·에러 상태를 함께 관리합니다',
  'lead': '@langchain/langgraph-sdk/react의 useStream은 서버와의 스트리밍 연결, 메시지 누적, 로딩·에러 상태를 캡슐화합니다',
  'points': [{'h': '필수 연결 정보',
              'p': "<span class='mono'>assistantId</span>와 <span class='mono'>apiUrl</span>만 주면 즉시 연결됩니다."},
             {'h': 'submit()으로 전송',
              'p': "<span class='mono'>stream.submit({ messages: [...] })</span> 호출 한 번으로 사용자 메시지를 보냅니다."},
             {'h': '자동 상태 관리',
              'p': "<span class='mono'>stream.messages</span>, <span class='mono'>stream.isLoading</span>, <span "
                   "class='mono'>stream.error</span>를 그대로 렌더링하면 됩니다."}],
  'code': 'import { useStream } from "@langchain/langgraph-sdk/react";\n'
          '\n'
          'function Chat() {\n'
          '  const stream = useStream({\n'
          '    assistantId: "agent",\n'
          '    apiUrl: "http://localhost:2024",\n'
          '  });\n'
          '\n'
          '  const handleSubmit = (message) => {\n'
          '    stream.submit({ messages: [{ content: message, type: "human" }] });\n'
          '  };\n'
          '\n'
          '  return (\n'
          '    <div>\n'
          '      {stream.messages.map((m, i) => <div key={i}>{m.type}: {m.content}</div>)}\n'
          '      {stream.isLoading && <div>Loading...</div>}\n'
          '      {stream.error && <div>Error: {stream.error.message}</div>}\n'
          '    </div>\n'
          '  );\n'
          '}',
  'file': 'Chat.tsx',
  'note': 'useStream 실사용'},
 {'type': 'dense',
  'meta': '13 / 프론트엔드 스트리밍',
  'title': '브랜칭과 멀티에이전트 UI는 checkpoint와 langgraph_node 메타데이터가 핵심입니다',
  'lead': '사용자가 메시지를 고쳐 다른 경로를 만들거나, 여러 에이전트의 발화를 구분하려면 스트림 메타를 보존해야 합니다',
  'groups': [{'t': '브랜칭',
              'kids': [{'t': "메시지 메타데이터의 <span class='mono'>parent_checkpoint</span>를 submit 옵션에 넣으면 해당 시점에서 대체 경로를 "
                             '만듭니다'},
                       {'t': '사용자 메시지 편집과 AI 응답 재생성 모두 같은 checkpoint 패턴을 씁니다'}]},
             {'t': '멀티에이전트 스트리밍',
              'kids': [{'t': "메타데이터의 <span class='mono'>langgraph_node</span>로 researcher, writer, reviewer 같은 발화 출처를 "
                             '구분합니다'},
                       {'t': '노드별 라벨과 색상을 매핑하면 사용자가 어떤 에이전트가 말하는지 즉시 알 수 있습니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 14',
  'title': '가드레일',
  'sub': 'PII, HITL, before_agent, after_agent, 다층 방어를 마지막 운영 경계로 정리합니다.',
  'lab': '02_langchain/13_guardrails.ipynb'},
 {'type': 'table',
  'meta': '14 / 가드레일',
  'title': '가드레일은 결정론적 규칙과 모델 기반 검사를 조합합니다',
  'lead': '빠른 실패는 비용을 줄이고, 모델 기반 검사는 미묘한 위반을 보완합니다',
  'cols': [{'t': '접근', 'w': '24%'}, {'t': '방식', 'w': '34%'}, {'t': '주의점', 'accent': True}],
  'rows': [['결정론적', '정규식, 키워드, 명시 규칙', '빠르고 예측 가능하지만 미묘한 의미 위반을 놓칠 수 있습니다'],
           ['모델 기반', 'LLM·분류기로 의미 분석', '정교하지만 느리고 비용이 높습니다'],
           ['입력 가드레일', 'before_agent에서 요청 검증', '모델 호출 전 차단해 위험한 컨텍스트 유입을 막습니다'],
           ['출력 가드레일', 'after_agent에서 최종 응답 검증', '민감 정보와 품질 문제를 사용자에게 나가기 전에 잡습니다']]},
 {'type': 'code-split',
  'meta': '14 / 가드레일',
  'title': 'PIIMiddleware는 개인정보 유형별로 redact·mask·hash·block을 선택합니다',
  'lead': '입력, 출력, 도구 결과 중 어느 표면에 적용할지 apply_to_*를 명시해야 동작합니다',
  'points': [{'h': 'redact', 'p': '값을 [REDACTED_EMAIL]처럼 대체합니다.'},
             {'h': 'mask', 'p': '신용카드 마지막 4자리처럼 일부만 남깁니다.'},
             {'h': 'hash', 'p': '값을 결정론적 해시로 대체해 원본 없이도 동일성 비교가 가능합니다.'},
             {'h': 'block', 'p': 'API key 같은 값이 감지되면 예외로 차단합니다.'}],
  'code': 'from langchain.agents.middleware import PIIMiddleware\n'
          '\n'
          'agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[customer_service_tool, email_tool],\n'
          '    middleware=[\n'
          '        PIIMiddleware("email", strategy="redact", apply_to_input=True),\n'
          '        PIIMiddleware("credit_card", strategy="mask", apply_to_input=True),\n'
          '        PIIMiddleware("ip", strategy="hash", apply_to_input=True),\n'
          '        PIIMiddleware("api_key", detector=r"sk-[a-zA-Z0-9]{32}", strategy="block", apply_to_input=True),\n'
          '    ],\n'
          ')',
  'file': '13_guardrails.ipynb',
  'note': 'PII guardrail'},
 {'type': 'code-split',
  'meta': '14 / 가드레일',
  'title': '가드레일은 여러 미들웨어를 쌓아 다층 방어로 조합합니다',
  'lead': '빠른 결정론적 체크를 앞에, 느린 모델 기반 체크를 뒤에 배치해야 비용과 지연을 줄입니다',
  'points': [{'h': 'Layer 1~2', 'p': '키워드 필터와 PII 마스킹처럼 규칙 기반 가드레일을 입력 단계에 먼저 둡니다.'},
             {'h': 'Layer 3',
              'p': "이메일 전송처럼 민감한 도구 호출에는 <span class='mono'>HumanInTheLoopMiddleware</span>로 사람 승인을 끼워 넣습니다."},
             {'h': 'Layer 4', 'p': '모델 기반 안전성 검사는 가장 비싸므로 마지막 단계에 배치합니다(노트북에서 커스텀으로 정의).'}],
  'code': 'from langchain.agents.middleware import PIIMiddleware, HumanInTheLoopMiddleware\n'
          '\n'
          'agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[search_tool, send_email_tool],\n'
          '    middleware=[\n'
          '        # Layer 1: 결정론적 입력 필터 (노트북에서 커스텀 정의)\n'
          '        ContentFilterMiddleware(banned_keywords=["hack", "exploit"]),\n'
          '\n'
          '        # Layer 2: PII 보호 (입력 + 출력)\n'
          '        PIIMiddleware("email", strategy="redact", apply_to_input=True),\n'
          '        PIIMiddleware("email", strategy="redact", apply_to_output=True),\n'
          '\n'
          '        # Layer 3: 민감 도구 사람 승인\n'
          '        HumanInTheLoopMiddleware(interrupt_on={"send_email": True}),\n'
          '\n'
          '        # Layer 4: 모델 기반 안전성 검사 (노트북에서 커스텀 정의)\n'
          '        SafetyGuardrailMiddleware(),\n'
          '    ],\n'
          ')',
  'file': '13_guardrails.ipynb',
  'note': '다중 가드레일 조합 (다층 방어)'},
 {'type': 'code-split',
  'meta': '14 / 가드레일',
  'title': "커스텀 입력 가드레일은 before_agent에서 jump_to='end'로 안전하게 종료합니다",
  'lead': '금지 키워드를 발견했을 때 예외만 던지기보다 사용자에게 거절 메시지를 남기는 패턴이 운영에 적합합니다',
  'points': [{'h': 'before_agent', 'p': '에이전트 실행 시작 전 요청을 검사합니다.'},
             {'h': 'can_jump_to', 'p': '이 훅이 종료 노드로 점프할 수 있음을 선언합니다.'},
             {'h': 'graceful refusal', 'p': '사용자는 빈 에러가 아니라 정책 안내를 받습니다.'}],
  'code': 'from langchain.agents.middleware import before_agent, AgentState, hook_config\n'
          'from langgraph.runtime import Runtime\n'
          '\n'
          '@before_agent(can_jump_to=["end"])\n'
          'def content_filter(state: AgentState, runtime: Runtime):\n'
          '    banned = ["hack", "exploit", "malware"]\n'
          '    content = state["messages"][0].content.lower()\n'
          '    if any(keyword in content for keyword in banned):\n'
          '        return {\n'
          '            "messages": [{"role": "assistant", "content": "부적절한 요청입니다."}],\n'
          '            "jump_to": "end",\n'
          '        }\n'
          '    return None',
  'file': '13_guardrails.ipynb',
  'note': 'before_agent guardrail'},
 {'type': 'code-split',
  'meta': '14 / 가드레일',
  'title': '출력 가드레일은 after_agent에서 최종 응답을 검증하거나 수정합니다',
  'lead': '모델 기반 안전성 검사는 느리므로 결정론적 입력 차단 뒤 마지막 방어선으로 배치합니다',
  'points': [{'h': 'after_agent', 'p': '에이전트 실행 후 마지막 메시지를 검사합니다.'},
             {'h': 'safety_model', 'p': '가벼운 모델로 SAFE/UNSAFE 같은 판정을 받습니다.'},
             {'h': '다층 방어', 'p': 'ContentFilter → PII → HITL → Safety 순서처럼 빠른 검사를 앞에 둡니다.'}],
  'code': 'from langchain.agents.middleware import after_agent, AgentState, hook_config\n'
          'from langchain.chat_models import init_chat_model\n'
          '\n'
          'safety_model = init_chat_model("gpt-5.4-mini")\n'
          '\n'
          '@after_agent(can_jump_to=["end"])\n'
          'def safety_check(state: AgentState, runtime):\n'
          '    last = state["messages"][-1]\n'
          '    verdict = safety_model.invoke([{"role": "user", "content": f"SAFE or UNSAFE: {last.content}"}])\n'
          '    if "UNSAFE" in verdict.content:\n'
          '        last.content = "안전하지 않은 응답입니다. 다시 질문해주세요."\n'
          '    return None',
  'file': '13_guardrails.ipynb',
  'note': 'after_agent guardrail'},
 {'type': 'dense',
  'meta': '14 / 가드레일',
  'title': '프로덕션 가드레일은 빠른 실패와 친절한 거절을 함께 설계해야 합니다',
  'lead': '안전 장치 자체도 테스트·로깅·폴백 대상입니다',
  'groups': [{'t': '다층 방어',
              'kids': [{'t': '결정론적 입력 필터를 가장 앞에 두어 불필요한 모델 호출을 줄입니다'},
                       {'t': 'PII 미들웨어는 입력·출력·도구 결과 중 필요한 표면에만 명시적으로 적용합니다'},
                       {'t': '민감 도구는 HumanInTheLoopMiddleware로 승인 흐름을 둡니다'}]},
             {'t': '운영 품질',
              'kids': [{'t': '차단 이벤트는 LangSmith trace와 감사 로그에 남깁니다'},
                       {'t': '가드레일이 실패할 때의 기본 정책을 try/except와 폴백으로 정합니다'},
                       {'t': '도메인별 테스트 케이스를 GenericFakeChatModel과 함께 CI에 넣습니다'}]}]},
 {'type': 'divider',
  'kicker': 'REFERENCE',
  'title': '개념 근거와 LangChain v1 모델',
  'sub': 'LangChain v1 개념 설명은 공식 문서, ReAct 논문, MCP 공식 문서를 기준으로 보강합니다.'},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Reference / Agents',
  'title': 'create_agent()는 메시지, 모델 호출, 도구 호출을 반복하는 실행 루프입니다',
  'lead': 'LangChain 공식 문서는 create_agent를 모델·도구·시스템 프롬프트·미들웨어를 묶는 agent harness로 설명합니다. ReAct 논문은 reasoning과 acting의 '
          '교차 루프를 배경으로 제공합니다.',
  'img_src': 'assets/diagrams/svg_langchain_agent_loop.svg',
  'cap': 'create_agent runtime loop',
  'points': [{'h': 'Messages', 'p': 'System, Human, AI, Tool 메시지가 실행 문맥을 이룹니다.'},
             {'h': 'Model', 'p': '모델은 다음 답변 또는 tool call을 생성합니다.'},
             {'h': 'Tool result', 'p': '도구 결과는 ToolMessage로 돌아와 다음 모델 입력이 됩니다.'}]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Reference / Middleware',
  'title': '미들웨어는 agent loop 안의 고정 지점과 호출 주변을 제어합니다',
  'lead': 'LangChain 공식 문서는 node-style hook과 wrap-style hook을 구분합니다. 로깅, 동적 프롬프트, 재시도, 가드레일, HITL 같은 운영 정책을 여기에 둡니다.',
  'img_src': 'assets/diagrams/svg_langchain_middleware_hooks.svg',
  'cap': 'middleware hook points',
  'points': [{'h': 'Node-style', 'p': 'before_agent, before_model, after_model, after_agent에서 state를 갱신합니다.'},
             {'h': 'Wrap-style', 'p': 'wrap_model_call, wrap_tool_call로 각 호출을 감쌉니다.'},
             {'h': 'Policy', 'p': '정책은 앱 바깥이 아니라 agent 실행 흐름 안에서 적용됩니다.'}]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Reference / MCP',
  'title': 'MCP는 에이전트와 외부 도구 사이의 연결 방식을 표준화합니다',
  'lead': "LangChain 1.4 기준 MCP는 <span class='mono'>langchain.mcp.MCPAdapter</span>에서 연결 수명과 도구 변환을 관리합니다. 기존 adapter "
          '패키지의 단순 import 교체로 끝나지 않습니다.',
  'img_src': 'assets/diagrams/svg_langchain_mcp_bridge.svg',
  'cap': 'MCP client/server bridge',
  'points': [{'h': 'Client', 'p': '서버별 세션과 인증을 관리하고 도구 목록을 가져옵니다.'},
             {'h': 'Server', 'p': '도구, 리소스, 프롬프트를 표준 인터페이스로 노출합니다.'},
             {'h': 'Transport', 'p': '로컬은 stdio, 원격은 streamable-http를 주로 사용합니다.'}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Reference / LangChain',
  'title': 'LangChain 개념 보강 출처는 공식 문서와 논문을 기준으로 삼습니다',
  'lead': '덱의 개념 설명은 노트북 코드와 아래 신뢰 출처를 함께 반영합니다.',
  'cols': [{'t': '개념', 'w': '24%'}, {'t': '출처', 'w': '36%'}, {'t': '덱 반영', 'accent': True}],
  'rows': [['Agent loop', 'LangChain Agents official docs, ReAct paper', 'create_agent, tool call, ToolMessage 루프 설명'],
           ['Messages/Tools', 'LangChain Messages and Tools official docs', '메시지 타입, 도구 스키마, 도구 결과 설명'],
           ['Structured output',
            'LangChain Structured Output official docs',
            'response_format과 structured_response 설명'],
           ['Memory/Streaming',
            'LangChain Short-term Memory and Streaming docs',
            'checkpointer, thread_id, stream_mode 설명'],
           ['MCP',
            'Model Context Protocol official docs, LangChain MCP docs',
            'client/server, transport, authentication 설명']]},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '01_introduction.ipynb',
  'sub': '01_introduction.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/01_introduction.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 8',
  'code': '# 환경 설정\n'
          'import subprocess\n'
          'import importlib\n'
          '\n'
          'packages = {\n'
          '    "langchain": "langchain",\n'
          '    "langchain_openai": "langchain-openai",\n'
          '    "langchain_community": "langchain-community",\n'
          '    "langgraph": "langgraph",\n'
          '}\n'
          '\n'
          'print("=" * 50)\n'
          'print("LangChain v1 환경 확인")\n'
          'print("=" * 50)\n'
          '\n'
          'for module_name, package_name in packages.items():\n'
          '    try:\n'
          '        mod = importlib.import_module(module_name)\n'
          '        version = getattr(mod, "__version__", "installed")\n'
          '        print(f"\\u2713 {package_name}: {version}")\n'
          '    except ImportError:\n'
          '        print(f"\\u2717 {package_name}: 미설치 \\u2192 pip install {package_name}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 9',
  'code': '# API 키 확인\n'
          'from dotenv import load_dotenv\n'
          'import os\n'
          '\n'
          'load_dotenv(override=True)\n'
          '\n'
          'required_keys = ["OPENAI_API_KEY"]\n'
          'optional_keys = ["TAVILY_API_KEY", "LANGSMITH_API_KEY"]\n'
          '\n'
          'print("필수 API 키:")\n'
          'for key in required_keys:\n'
          '    status = "\\u2713 설정됨" if os.environ.get(key) else "\\u2717 미설정"\n'
          '    print(f"  {key}: {status}")\n'
          '\n'
          'print("\\n선택 API 키:")\n'
          'for key in optional_keys:\n'
          '    status = "\\u2713 설정됨" if os.environ.get(key) else "- 미설정 (선택)"\n'
          '    print(f"  {key}: {status}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 10',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 04',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 11',
  'code': '# LangChain v1 핵심 import 확인\n'
          'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          'from langchain_openai import ChatOpenAI\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'print("\\u2713 모든 핵심 모듈 임포트 성공")\n'
          'print("  - create_agent: LangChain v1 에이전트 생성")\n'
          'print("  - tool: 도구 데코레이터")\n'
          'print("  - ChatOpenAI: OpenAI 호환 모델")\n'
          'print("  - InMemorySaver: 메모리 체크포인터")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '02_quickstart.ipynb',
  'sub': '02_quickstart.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/02_quickstart.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 01',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 4',
  'code': '# uv 환경이라면 아래 한 줄로 충분합니다.\n'
          '# !uv add langchain deepagents langgraph langchain-openai\n'
          '\n'
          '# pip 환경이라면 다음을 씁니다.\n'
          '%pip install -q -U langchain deepagents langgraph langchain-openai'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 02',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 6',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          '\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          'print("✓ 모델 설정 완료:", model.model_name)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 7',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 04',
  'lead': '이 코드는 함수에 @tool을 붙여 모델이 호출할 수 있는 도구로 만드는 과정을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 9',
  'code': 'from langchain.tools import tool\n'
          '\n'
          '@tool\n'
          'def add(a: int, b: int) -> int:\n'
          '    """두 수를 더합니다."""\n'
          '    return a + b\n'
          '\n'
          '@tool\n'
          'def multiply(a: int, b: int) -> int:\n'
          '    """두 수를 곱합니다."""\n'
          '    return a * b\n'
          '\n'
          'print("도구 목록:")\n'
          'for t in [add, multiply]:\n'
          '    print(f"  - {t.name}: {t.description}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 05',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 11',
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add, multiply],\n'
          '    system_prompt="당신은 수학 도우미입니다. 제공된 도구를 사용하여 계산하세요.",\n'
          ')\n'
          'print("\\u2713 에이전트 생성 완료")\n'
          'print(f"  타입: {type(agent).__name__}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 06',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 13',
  'code': 'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "15 + 27은 얼마인가요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          '\n'
          '# 최종 응답 출력\n'
          'print("에이전트 응답:")\n'
          'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 07',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 14',
  'code': '# 전체 메시지 흐름 확인\n'
          'print("전체 메시지 흐름:")\n'
          'print("=" * 50)\n'
          'for msg in result["messages"]:\n'
          "    role = msg.type if hasattr(msg, 'type') else msg.get('role', 'unknown')\n"
          "    content = msg.content if hasattr(msg, 'content') else msg.get('content', '')\n"
          '    print(f"[{role}] {content[:200]}")\n'
          '    print("-" * 50)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 08',
  'lead': '이 코드는 LangChain/LangGraph 스트리밍 이벤트와 UI 연결 방식을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 16',
  'code': 'print("스트리밍 실행:")\n'
          'print("=" * 50)\n'
          '\n'
          'for chunk in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "12 * 8을 계산한 다음 결과에 5를 더하세요."}]},\n'
          '    stream_mode="updates",\n'
          '    config=lf_config,\n'
          '):\n'
          '    for node_name, update in chunk.items():\n'
          '        print(f"\\n--- {node_name} ---")\n'
          '        if "messages" in update:\n'
          '            for msg in update["messages"]:\n'
          "                content = msg.content if hasattr(msg, 'content') else str(msg)\n"
          '                if content:\n'
          '                    print(f"  {content[:300]}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 09 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 18',
  'code': 'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'checkpointer = InMemorySaver()\n'
          '\n'
          'agent_with_memory = create_agent(\n'
          '    model=model,\n'
          '    tools=[add, multiply],\n'
          '    system_prompt="당신은 수학 도우미입니다.",\n'
          '    checkpointer=checkpointer,\n'
          ')\n'
          '\n'
          'config = {"configurable": {"thread_id": "math-session-1"}}\n'
          '\n'
          '# 첫 번째 질문\n'
          'result1 = agent_with_memory.invoke(\n'
          '    {"messages": [{"role": "user", "content": "7 * 6은 얼마인가요?"}]},\n'
          '    config={**config, **lf_config},\n'
          ')\n'
          'print("첫 번째 응답:", result1["messages"][-1].content)\n'
          '\n'
          '# 이전 대화를 기억하는 두 번째 질문\n'
          'result2 = agent_with_memory.invoke('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 09 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 18',
  'code': '    {"messages": [{"role": "user", "content": "이전 결과에 10을 더하세요."}]},\n'
          '    config={**config, **lf_config},\n'
          ')\n'
          'print("두 번째 응답:", result2["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 10',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 20',
  'code': '# Tavily API 키가 있는 경우에만 실행\n'
          'if os.environ.get("TAVILY_API_KEY"):\n'
          '    from langchain_tavily import TavilySearch\n'
          '\n'
          '    search_tool = TavilySearch(max_results=3)\n'
          '\n'
          '    search_agent = create_agent(\n'
          '        model=model,\n'
          '        tools=[search_tool],\n'
          '        system_prompt="당신은 리서치 어시스턴트입니다. 웹 검색을 통해 질문에 답하세요.",\n'
          '    )\n'
          '\n'
          '    result = search_agent.invoke(\n'
          '        {"messages": [{"role": "user", "content": "LangChain의 최신 버전은 무엇인가요?"}]},\n'
          '        config=lf_config,\n'
          '    )\n'
          '    print("검색 에이전트 응답:")\n'
          '    print(result["messages"][-1].content)\n'
          'else:\n'
          '    print("\\u26a0 TAVILY_API_KEY가 설정되지 않았습니다. 이 셀을 건너뜁니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 11 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 22',
  'code': 'from dataclasses import dataclass\n'
          'from langchain.agents import create_agent\n'
          '\n'
          '\n'
          '@dataclass\n'
          'class Context:\n'
          '    """호출 시점마다 주입되는 사용자 컨텍스트."""\n'
          '    user_id: str\n'
          '    locale: str = "ko-KR"\n'
          '\n'
          '\n'
          'ctx_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add, multiply],\n'
          '    system_prompt="당신은 수학 도우미입니다. 사용자에 맞춰 답하세요.",\n'
          '    context_schema=Context,\n'
          '    name="research_assistant",  # snake_case 권장\n'
          ')\n'
          '\n'
          'result = ctx_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "3 + 4는?"}]},\n'
          '    context=Context(user_id="u-42", locale="ko-KR"),'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 02_quickstart',
  'title': '02_quickstart 코드 11 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '02_quickstart.ipynb',
  'note': 'cell 22',
  'code': '    config=lf_config,\n)\nprint("응답:", result["messages"][-1].content)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '03_models_and_messages.ipynb',
  'sub': '03_models_and_messages.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/03_models_and_messages.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 01',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 4',
  'code': 'import os\n'
          'from dotenv import load_dotenv\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'load_dotenv(override=True)\n'
          '\n'
          '# OpenAI를 통한 모델 초기화\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'print("모델 초기화 완료:", model.model_name)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_models_and_messages.ipynb',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 03',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 8',
  'code': 'from langchain.chat_models import init_chat_model\n'
          '\n'
          '# init_chat_model with OpenAI\n'
          'model_direct = init_chat_model(\n'
          '    model="openai:gpt-5.4",\n'
          '    temperature=0,\n'
          ')\n'
          '\n'
          'response = model_direct.invoke("안녕하세요! 2+2는 얼마인가요?", config=lf_config)\n'
          'print("모델 응답:", response.content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 04',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 10',
  'code': '# invoke: 단일 호출\n'
          'response = model.invoke("LangChain이 무엇인지 한 문장으로 설명해 주세요.", config=lf_config)\n'
          'print("invoke 결과:", response.content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 05',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 11',
  'code': '# stream: 토큰 단위 스트리밍\n'
          'print("stream 결과:", end=" ")\n'
          'for chunk in model.stream("1부터 5까지 세어 주세요.", config=lf_config):\n'
          '    print(chunk.content, end="", flush=True)\n'
          'print()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 06',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 12',
  'code': '# batch: 여러 입력 동시 처리\n'
          'responses = model.batch([\n'
          '    "Python이란 무엇인가요?",\n'
          '    "JavaScript란 무엇인가요?",\n'
          '    "Rust란 무엇인가요?",\n'
          '], config=lf_config)\n'
          'for i, resp in enumerate(responses):\n'
          '    print(f"응답 {i+1}: {resp.content[:100]}...")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 07',
  'lead': '이 코드는 LangChain 메시지 타입과 대화 문맥 표현을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 14',
  'code': 'from langchain.messages import SystemMessage, HumanMessage, AIMessage, ToolMessage\n'
          '\n'
          'messages = [\n'
          '    SystemMessage(content="당신은 번역 어시스턴트입니다. 한국어로 번역하세요."),\n'
          '    HumanMessage(content="안녕하세요, 잘 지내시나요?"),\n'
          ']\n'
          '\n'
          'response = model.invoke(messages, config=lf_config)\n'
          'print("번역 결과:", response.content)\n'
          'print(f"메시지 타입: {type(response).__name__}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 08',
  'lead': '이 코드는 LangChain 메시지 타입과 대화 문맥 표현을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 15',
  'code': '# 대화 이력 관리 — 여러 메시지 타입을 조합하여 대화 맥락을 구성합니다\n'
          'conversation = [\n'
          '    SystemMessage(content="당신은 수학 튜터입니다. 간결하게 답하세요."),\n'
          '    HumanMessage(content="소수란 무엇인가요?"),\n'
          '    AIMessage(content="소수는 1보다 큰 자연수로, 1과 자기 자신 이외의 양의 약수를 가지지 않는 수입니다."),\n'
          '    HumanMessage(content="5가지 예시를 알려주세요."),\n'
          ']\n'
          '\n'
          'response = model.invoke(conversation, config=lf_config)\n'
          'print("응답:", response.content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 09 (1/2)',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 17',
  'code': '# 멀티모달 메시지 구조 예시 (실행은 모델 지원 필요)\n'
          'from langchain.messages import HumanMessage\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          '# output_version="v1" — content_blocks 표준 직렬화 형식을 강제합니다.\n'
          'vision_model = ChatOpenAI(model="gpt-5.4", output_version="v1")\n'
          '\n'
          'multimodal_msg = HumanMessage(\n'
          '    content=[\n'
          '        {"type": "text", "text": "이 이미지에서 무엇이 보이나요?"},\n'
          '        {\n'
          '            "type": "image_url",\n'
          '            "image_url": {"url": '
          '"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Camponotus_flavomarginatus_ant.jpg/320px-Camponotus_flavomarginatus_ant.jpg"},\n'
          '        },\n'
          '    ]\n'
          ')\n'
          '\n'
          '# 멀티모달 지원 모델에서 실행\n'
          'try:\n'
          '    response = vision_model.invoke([multimodal_msg], config=lf_config)\n'
          '    # v1 출력은 content_blocks 로 표준화되어 텍스트/이미지/툴콜이 분리 노출됩니다.\n'
          '    for block in getattr(response, "content_blocks", []) or []:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 09 (2/2)',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 17',
  'code': '        print(f"[{block.get(\'type\')}] {block}")\n'
          '    print("\\n원본 content:", response.content[:200] if isinstance(response.content, str) else '
          'response.content)\n'
          'except Exception as e:\n'
          '    print(f"멀티모달 미지원 모델: {e}")\n'
          '    print("  -> 멀티모달은 GPT-5.4, Claude Sonnet 4.6 등 비전 모델에서 지원됩니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 10',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 19',
  'code': 'from langchain_core.callbacks import UsageMetadataCallbackHandler\n'
          '\n'
          'cb = UsageMetadataCallbackHandler()\n'
          '\n'
          '# 단일 모델 호출에 콜백 부착\n'
          '_ = model.invoke(\n'
          '    "LangChain v1을 한 줄로 소개해 주세요.",\n'
          '    config={"callbacks": [cb]},\n'
          ')\n'
          '\n'
          '# 동일 핸들러를 여러 호출에 재사용하면 누적 집계됩니다.\n'
          '_ = model.invoke(\n'
          '    "한 줄 더 추가해 주세요.",\n'
          '    config={"callbacks": [cb]},\n'
          ')\n'
          '\n'
          'print("누적 usage_metadata:")\n'
          'print(cb.usage_metadata)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 11',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 21',
  'code': 'runtime_cfg = {\n'
          '    "run_name": "intro-greeting",\n'
          '    "tags": ["demo", "ch03"],\n'
          '    "metadata": {"experiment": "v1_runtime_config"},\n'
          '    "max_concurrency": 5,\n'
          '}\n'
          '\n'
          '# 단일 호출 — run_name/tags/metadata가 트레이스에 노출됩니다.\n'
          'resp = model.invoke("한국어로 짧게 인사해 주세요.", config=runtime_cfg)\n'
          'print("응답:", resp.content)\n'
          '\n'
          '# batch — max_concurrency로 동시 실행 상한을 정합니다.\n'
          'batched = model.batch(\n'
          '    [f"숫자 {i}을 한글로 적어 주세요." for i in range(1, 7)],\n'
          '    config=runtime_cfg,\n'
          ')\n'
          'for i, r in enumerate(batched, start=1):\n'
          '    print(f"{i}: {r.content}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 12',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 23',
  'code': 'from langchain.chat_models import init_chat_model\n'
          '\n'
          '# 재시도 15회 + 호출당 120초 타임아웃 — 운영 환경에서 자주 쓰는 조합입니다.\n'
          'resilient_model = init_chat_model(\n'
          '    "gpt-5.4",\n'
          '    max_retries=15,\n'
          '    timeout=120,\n'
          ')\n'
          '\n'
          'resp = resilient_model.invoke("간단히 \'pong\'이라고만 답해 주세요.", config=lf_config)\n'
          'print("응답:", resp.content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 13',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 25',
  'code': 'import os\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          '# 방법 A — 환경 변수로 전역 적용\n'
          'os.environ["LC_OUTPUT_VERSION"] = "v1"\n'
          '\n'
          '# 방법 B — 모델 단위로 명시\n'
          'v1_model = ChatOpenAI(model="gpt-5.4", output_version="v1")\n'
          '\n'
          'resp = v1_model.invoke("LangChain v1을 한 문장으로 소개해 주세요.", config=lf_config)\n'
          '\n'
          'print("content_blocks (표준 직렬화):")\n'
          'for block in getattr(resp, "content_blocks", []) or []:\n'
          '    print(f"  - [{block.get(\'type\')}] {str(block)[:120]}")\n'
          '\n'
          'print("\\nresp.text() 헬퍼:", resp.text() if hasattr(resp, "text") else resp.content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 14 (1/2)',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 27',
  'code': '# Implicit caching — OpenAI 호출 한 번이면 토큰 사용량 메타데이터에 cache 정보가 함께 잡힙니다.\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'implicit_model = ChatOpenAI(model="gpt-5.4")\n'
          'long_system = "당신은 변호사 어시스턴트입니다. " * 50  # 길이가 있을수록 캐시 효과가 큼\n'
          '\n'
          'r1 = implicit_model.invoke(\n'
          '    [\n'
          '        {"role": "system", "content": long_system},\n'
          '        {"role": "user", "content": "근로계약서의 필수 기재사항을 알려 주세요."},\n'
          '    ],\n'
          '    config=lf_config,\n'
          ')\n'
          'r2 = implicit_model.invoke(\n'
          '    [\n'
          '        {"role": "system", "content": long_system},\n'
          '        {"role": "user", "content": "위 항목 중 위반 시 과태료가 부과되는 것은?"},\n'
          '    ],\n'
          '    config=lf_config,\n'
          ')\n'
          'print("1차 usage:", r1.usage_metadata)\n'
          'print("2차 usage:", r2.usage_metadata)  # cache_read 가 0보다 크면 implicit hit'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 03_models_and_messages',
  'title': '03_models_and_messages 코드 14 (2/2)',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '03_models_and_messages.ipynb',
  'note': 'cell 27',
  'code': '\n'
          '# Explicit caching — Anthropic 예시 (langchain-anthropic 필요)\n'
          '# from langchain_anthropic import ChatAnthropic\n'
          '# anthropic_model = ChatAnthropic(model="claude-sonnet-4-6")\n'
          '# anthropic_model.invoke(\n'
          '#     [\n'
          '#         {"role": "system", "content": long_system},\n'
          '#         {"role": "user", "content": "질문..."},\n'
          '#     ],\n'
          '#     model_kwargs={"prompt_cache_key": "lawyer-system-v1"},\n'
          '# )'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '04_tools_and_structured_output.ipynb',
  'sub': '04_tools_and_structured_output.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/04_tools_and_structured_output.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 01',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 4',
  'code': 'import os\n'
          'from dotenv import load_dotenv\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'load_dotenv(override=True)\n'
          '\n'
          '# OpenAI를 통한 모델 초기화\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'print("모델 초기화 완료:", model.model_name)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '04_tools_and_structured_output.ipynb',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 03',
  'lead': '이 코드는 함수에 @tool을 붙여 모델이 호출할 수 있는 도구로 만드는 과정을 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 7',
  'code': 'from langchain.tools import tool\n'
          '\n'
          '@tool\n'
          'def get_weather(city: str) -> str:\n'
          '    """도시의 현재 날씨를 조회합니다."""\n'
          '    weather_data = {\n'
          '        "Seoul": "맑음, 15\\u00b0C",\n'
          '        "Tokyo": "흐림, 12\\u00b0C",\n'
          '        "New York": "비, 8\\u00b0C",\n'
          '    }\n'
          '    return weather_data.get(city, f"날씨 데이터를 사용할 수 없습니다: {city}")\n'
          '\n'
          '# 도구의 스키마 확인\n'
          'print("도구 이름:", get_weather.name)\n'
          'print("도구 설명:", get_weather.description)\n'
          'print("입력 스키마:", get_weather.args_schema.model_json_schema())'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 04',
  'lead': '이 코드는 함수에 @tool을 붙여 모델이 호출할 수 있는 도구로 만드는 과정을 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 9',
  'code': 'from pydantic import BaseModel, Field\n'
          '\n'
          'class SearchQuery(BaseModel):\n'
          '    """데이터베이스 쿼리용 검색 파라미터입니다."""\n'
          '    query: str = Field(description="검색 쿼리 문자열")\n'
          '    max_results: int = Field(default=5, description="반환할 최대 결과 수")\n'
          '    category: str = Field(default="all", description="검색 카테고리: all, tech, science, news")\n'
          '\n'
          '@tool(args_schema=SearchQuery)\n'
          'def search_database(query: str, max_results: int = 5, category: str = "all") -> str:\n'
          '    """고급 필터링 옵션으로 데이터베이스를 검색합니다."""\n'
          '    return f"\'{category}\' 카테고리에서 \'{query}\'에 대한 {max_results}개의 결과를 찾았습니다"\n'
          '\n'
          'print("복합 스키마:", search_database.args_schema.model_json_schema())'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 05',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 11',
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[get_weather, search_database],\n'
          '    system_prompt="당신은 날씨와 검색 도구를 사용할 수 있는 어시스턴트입니다.",\n'
          ')\n'
          '\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "서울 날씨가 어떤가요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("에이전트 응답:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 06',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 13',
  'code': 'from langchain.tools import tool, ToolRuntime\n'
          '\n'
          '@tool\n'
          'def get_user_info(runtime: ToolRuntime) -> str:\n'
          '    """현재 대화에 대한 정보를 가져옵니다."""\n'
          '    messages = runtime.state["messages"]\n'
          '    return f"현재 대화에 {len(messages)}개의 메시지가 있습니다."\n'
          '\n'
          'agent_with_runtime = create_agent(\n'
          '    model=model,\n'
          '    tools=[get_user_info],\n'
          '    system_prompt="get_user_info 도구를 사용하여 대화 정보를 확인할 수 있습니다.",\n'
          ')\n'
          '\n'
          'result = agent_with_runtime.invoke(\n'
          '    {"messages": [{"role": "user", "content": "우리 대화에 메시지가 몇 개 있나요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("응답:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 07 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 15',
  'code': 'from langchain.tools import tool, ToolRuntime\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '\n'
          '@tool\n'
          'def debug_trace(runtime: ToolRuntime) -> str:\n'
          '    """현재 도구 호출의 실행 컨텍스트를 보고합니다."""\n'
          '    info = getattr(runtime, "execution_info", None)\n'
          '    if info is None:\n'
          '        return "execution_info를 지원하지 않는 버전입니다."\n'
          '    return (\n'
          '        f"thread_id={getattr(info, \'thread_id\', None)} | "\n'
          '        f"run_id={getattr(info, \'run_id\', None)} | "\n'
          '        f"node_attempt={getattr(info, \'node_attempt\', None)}"\n'
          '    )\n'
          '\n'
          '\n'
          'debug_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[debug_trace],\n'
          '    system_prompt="debug_trace 도구를 호출해 현재 실행 정보를 알려 주세요.",\n'
          '    checkpointer=InMemorySaver(),'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 07 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 15',
  'code': ')\n'
          '\n'
          'result = debug_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "지금 실행 정보를 보여 주세요."}]},\n'
          '    config={"configurable": {"thread_id": "exec-info-demo"}, **lf_config},\n'
          ')\n'
          'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 08 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 17',
  'code': '@tool\n'
          'def who_am_i(runtime: ToolRuntime) -> str:\n'
          '    """호스팅 환경의 어시스턴트·사용자 정보를 반환합니다."""\n'
          '    server = getattr(runtime, "server_info", None)\n'
          '    if server is None:\n'
          '        return "로컬 실행이라 server_info가 비어 있습니다 (LangGraph Platform 배포 시 자동 채워짐)."\n'
          '    return (\n'
          '        f"assistant_id={getattr(server, \'assistant_id\', None)} | "\n'
          '        f"user={getattr(server, \'user\', None)}"\n'
          '    )\n'
          '\n'
          '\n'
          'server_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[who_am_i],\n'
          '    system_prompt="who_am_i 도구로 어시스턴트와 사용자 정보를 보고하세요.",\n'
          ')\n'
          '\n'
          'result = server_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "지금 누가 누구를 위해 답하고 있나요?"}]},\n'
          '    config=lf_config,\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 08 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 17',
  'code': 'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 09 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 19',
  'code': 'from langchain.messages import ToolMessage\n'
          '\n'
          'try:\n'
          '    from langchain.tools import wrap_tool_call, ToolCallRequest\n'
          'except ImportError:\n'
          '    # 일부 빌드에서는 langchain.agents 하위로 노출됩니다.\n'
          '    from langchain.agents.tool_executor import wrap_tool_call, ToolCallRequest  # type: ignore\n'
          '\n'
          '\n'
          '@wrap_tool_call\n'
          'def safe_executor(request: ToolCallRequest, handler):\n'
          '    """도구 호출 전후로 로그를 남기고, 예외는 ToolMessage로 흡수합니다."""\n'
          '    print(f"[tool_call] {request.tool_call[\'name\']} args={request.tool_call.get(\'args\')}")\n'
          '    try:\n'
          '        result = handler(request)\n'
          '        print("[tool_call] ok")\n'
          '        return result\n'
          '    except Exception as exc:  # noqa: BLE001\n'
          '        print(f"[tool_call] failed: {exc}")\n'
          '        return ToolMessage(\n'
          '            content=f"도구 호출이 실패했습니다: {exc}. 다른 방식으로 답하세요.",\n'
          '            tool_call_id=request.tool_call["id"],'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 09 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 19',
  'code': '        )\n'
          '\n'
          '\n'
          '# 사용 예 — middleware/agent 옵션에 따라 전달 위치가 달라질 수 있습니다.\n'
          '# wrapped_agent = create_agent(\n'
          '#     model=model,\n'
          '#     tools=[get_weather],\n'
          '#     middleware=[safe_executor],\n'
          '# )\n'
          'print("safe_executor 정의 완료 — agent 생성 시 middleware로 등록하세요.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 10 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 21',
  'code': 'from langgraph.types import Command\n'
          'from langchain.messages import ToolMessage\n'
          'from langchain.tools import tool, ToolRuntime\n'
          '\n'
          '\n'
          '@tool\n'
          'def remember_user_pref(theme: str, runtime: ToolRuntime) -> Command:\n'
          '    """사용자 테마 선호를 state에 기록합니다 (Command + ToolMessage 동반 반환)."""\n'
          '    return Command(\n'
          '        update={\n'
          '            "user_theme": theme,\n'
          '            "messages": [\n'
          '                ToolMessage(\n'
          '                    content=f"테마를 \'{theme}\'(으)로 저장했습니다.",\n'
          '                    tool_call_id=runtime.tool_call_id,\n'
          '                )\n'
          '            ],\n'
          '        }\n'
          '    )\n'
          '\n'
          '\n'
          'pref_agent = create_agent('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 10 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 21',
  'code': '    model=model,\n'
          '    tools=[remember_user_pref],\n'
          '    system_prompt="사용자가 테마를 말하면 remember_user_pref 도구로 저장하세요.",\n'
          ')\n'
          '\n'
          'result = pref_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "다크 테마로 설정해 주세요."}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 11',
  'lead': '이 코드는 구조화 출력 스키마와 응답 검증 흐름을 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 23',
  'code': '# 방법 1: with_structured_output() -- 모델 직접 사용\n'
          'from pydantic import BaseModel\n'
          '\n'
          'class MovieReview(BaseModel):\n'
          '    """구조화된 영화 리뷰."""\n'
          '    title: str\n'
          '    rating: float\n'
          '    summary: str\n'
          '    recommended: bool\n'
          '\n'
          'structured_model = model.with_structured_output(MovieReview)\n'
          '\n'
          'review = structured_model.invoke("크리스토퍼 놀란 감독의 영화 \'인셉션\'을 리뷰해주세요.", config=lf_config)\n'
          'print(f"제목: {review.title}")\n'
          'print(f"평점: {review.rating}")\n'
          'print(f"요약: {review.summary}")\n'
          'print(f"추천: {\'예\' if review.recommended else \'아니오\'}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 12 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 25',
  'code': 'from langchain.agents.structured_output import ToolStrategy\n'
          'from dataclasses import dataclass\n'
          '\n'
          '@dataclass\n'
          'class CalculationResult:\n'
          '    """계산 결과."""\n'
          '    expression: str\n'
          '    result: float\n'
          '    explanation: str\n'
          '\n'
          '@tool\n'
          'def calculate(expression: str) -> str:\n'
          '    """수학 표현식을 계산합니다."""\n'
          '    try:\n'
          '        result = eval(expression)\n'
          '        return f"{expression} = {result}"\n'
          '    except Exception as e:\n'
          '        return f"오류: {e}"\n'
          '\n'
          'agent_structured = create_agent(\n'
          '    model=model,\n'
          '    tools=[calculate],'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 04_tools_and_structured_output',
  'title': '04_tools_and_structured_output 코드 12 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '04_tools_and_structured_output.ipynb',
  'note': 'cell 25',
  'code': '    system_prompt="당신은 수학 어시스턴트입니다. 항상 calculate 도구를 사용하세요.",\n'
          '    response_format=ToolStrategy(CalculationResult),\n'
          ')\n'
          '\n'
          'result = agent_structured.invoke(\n'
          '    {"messages": [{"role": "user", "content": "2의 10제곱은 얼마인가요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("구조화된 응답:", result.get("structured_response"))'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '05_memory_and_streaming.ipynb',
  'sub': '05_memory_and_streaming.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/05_memory_and_streaming.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 01',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'print("모델 준비 완료:", model.model_name)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_memory_and_streaming.ipynb',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 03 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 7',
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '@tool\n'
          'def get_time() -> str:\n'
          '    """현재 시간을 가져옵니다."""\n'
          '    from datetime import datetime\n'
          '    return datetime.now().strftime("%H:%M:%S")\n'
          '\n'
          'checkpointer = InMemorySaver()\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[get_time],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다. 대화 맥락을 기억하세요.",\n'
          '    checkpointer=checkpointer,\n'
          ')\n'
          '\n'
          'config = {"configurable": {"thread_id": "session-1"}}\n'
          '\n'
          '# 첫 번째 대화\n'
          'result1 = agent.invoke('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 03 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 7',
  'code': '    {"messages": [{"role": "user", "content": "제 이름은 앨리스입니다. 지금 몇 시인가요?"}]},\n'
          '    config={**config, **lf_config},\n'
          ')\n'
          'print("응답 1:", result1["messages"][-1].content)\n'
          '\n'
          '# 두 번째 대화 — 이전 대화를 기억합니다\n'
          'result2 = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "제 이름이 뭔가요?"}]},\n'
          '    config={**config, **lf_config},\n'
          ')\n'
          'print("응답 2:", result2["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 04',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 9',
  'code': 'config_b = {"configurable": {"thread_id": "session-2"}}\n'
          '\n'
          'result3 = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "제 이름을 아시나요?"}]},\n'
          '    config={**config_b, **lf_config},\n'
          ')\n'
          'print("다른 세션 응답:", result3["messages"][-1].content)\n'
          'print("→ 다른 thread_id이므로 이전 대화를 모릅니다")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 05 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 11',
  'code': 'from langchain.messages import trim_messages\n'
          '\n'
          '# 트리밍 함수 설정: 최근 N개 메시지만 유지\n'
          'trimmer = trim_messages(\n'
          '    max_tokens=1000,\n'
          '    strategy="last",\n'
          '    token_counter=model,\n'
          '    include_system=True,\n'
          '    allow_partial=False,\n'
          ')\n'
          '\n'
          '# 트리밍을 미들웨어로 적용하는 예시\n'
          'from langchain.agents.middleware import before_model\n'
          '\n'
          '@before_model\n'
          'def trim_context(request):\n'
          '    """토큰 예산에 맞게 메시지를 트리밍합니다."""\n'
          '    trimmed = trimmer.invoke(request.state["messages"], config=lf_config)\n'
          '    return request.override(messages=trimmed)\n'
          '\n'
          'agent_trimmed = create_agent(\n'
          '    model=model,'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 05 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 11',
  'code': '    tools=[get_time],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[trim_context],\n'
          '    checkpointer=InMemorySaver(),\n'
          ')\n'
          '\n'
          'print("메시지 트리밍 에이전트 생성 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 06 (1/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 13',
  'code': 'from dataclasses import dataclass\n'
          'from langgraph.store.memory import InMemoryStore\n'
          'from langchain.tools import tool, ToolRuntime\n'
          '\n'
          'store = InMemoryStore()\n'
          '\n'
          '\n'
          '@dataclass\n'
          'class Context:\n'
          '    """사용자별 메모리 네임스페이스를 결정하는 런타임 컨텍스트."""\n'
          '    user_id: str\n'
          '\n'
          '\n'
          '@tool\n'
          'def save_preference(key: str, value: str, runtime: ToolRuntime[Context]) -> str:\n'
          '    """사용자 선호도를 장기 메모리에 저장합니다."""\n'
          '    # ⚠️ store 가 에이전트에 전달되지 않으면 runtime.store 는 None — 도구 호출이 실패합니다.\n'
          '    namespace = ("preferences", runtime.context.user_id)\n'
          '    runtime.store.put(namespace, key, {"value": value})\n'
          '    return f"선호도 저장 완료: {key} = {value} (user={runtime.context.user_id})"\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 06 (2/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 13',
  'code': '@tool\n'
          'def get_preference(key: str, runtime: ToolRuntime[Context]) -> str:\n'
          '    """장기 메모리에서 사용자 선호도를 조회합니다."""\n'
          '    namespace = ("preferences", runtime.context.user_id)\n'
          '    result = runtime.store.get(namespace, key)\n'
          '    if result:\n'
          '        # value 는 Item 객체 — dict(...) 캐스트로 안전하게 직렬화 가능한 형태로 변환합니다.\n'
          '        value = dict(result.value).get("value", "찾을 수 없음")\n'
          '        return f"선호도 {key} = {value}"\n'
          '    return f"{key}에 대한 선호도를 찾을 수 없습니다"\n'
          '\n'
          '\n'
          'memory_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[save_preference, get_preference],\n'
          '    system_prompt="도구를 사용하여 사용자 선호를 저장하고 조회할 수 있습니다.",\n'
          '    context_schema=Context,\n'
          '    store=store,\n'
          '    checkpointer=InMemorySaver(),\n'
          ')\n'
          '\n'
          '# 선호도 저장 — user_id 가 namespace 의 일부가 되어 사용자별로 격리됩니다.'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 06 (3/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 13',
  'code': 'result = memory_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "제가 좋아하는 색은 파랑, 좋아하는 음식은 피자로 저장해 주세요."}]},\n'
          '    context=Context(user_id="alice"),\n'
          '    config={"configurable": {"thread_id": "memory-test"}, **lf_config},\n'
          ')\n'
          'print("저장:", result["messages"][-1].content)\n'
          '\n'
          '# 새 세션에서 같은 user_id 로 조회 — thread 가 바뀌어도 store 는 유지됩니다.\n'
          'result2 = memory_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "제가 좋아하는 색은 뭔가요?"}]},\n'
          '    context=Context(user_id="alice"),\n'
          '    config={"configurable": {"thread_id": "memory-test-2"}, **lf_config},\n'
          ')\n'
          'print("조회:", result2["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 07',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 16',
  'code': '# stream_mode="updates" — 각 노드의 업데이트\n'
          'print("=== stream_mode=\'updates\' ===")\n'
          'for chunk in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "지금 몇 시인가요?"}]},\n'
          '    config={**{"configurable": {"thread_id": "stream-1"}}, **lf_config},\n'
          '    stream_mode="updates",\n'
          '):\n'
          '    for node, update in chunk.items():\n'
          '        print(f"[{node}]", end=" ")\n'
          '        if "messages" in update:\n'
          '            for msg in update["messages"]:\n'
          "                content = msg.content if hasattr(msg, 'content') else str(msg)\n"
          '                if content:\n'
          '                    print(content[:200])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 08',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 17',
  'code': '# stream_mode="messages" — 토큰 단위 스트리밍\n'
          'print("=== stream_mode=\'messages\' ===")\n'
          'for msg, metadata in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "짧은 농담 하나 해주세요."}]},\n'
          '    config={**{"configurable": {"thread_id": "stream-2"}}, **lf_config},\n'
          '    stream_mode="messages",\n'
          '):\n'
          "    if hasattr(msg, 'content') and msg.content:\n"
          '        print(msg.content, end="", flush=True)\n'
          'print()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 09',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 18',
  'code': '# stream_mode="values" — 각 단계의 전체 상태 스냅샷\n'
          'print("=== stream_mode=\'values\' ===")\n'
          'for state_snapshot in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "지금 몇 시인가요?"}]},\n'
          '    config={**{"configurable": {"thread_id": "stream-3"}}, **lf_config},\n'
          '    stream_mode="values",\n'
          '):\n'
          '    msgs = state_snapshot["messages"]\n'
          '    last_msg = msgs[-1]\n'
          '    role = getattr(last_msg, "type", "unknown")\n'
          '    content = last_msg.content if hasattr(last_msg, "content") else str(last_msg)\n'
          '    tool_calls = getattr(last_msg, "tool_calls", None)\n'
          '    print(f"[전체 상태] 메시지 수: {len(msgs)} | 마지막 메시지 역할: {role}")\n'
          '    if content:\n'
          '        print(f"  내용: {content[:200]}")\n'
          '    if tool_calls:\n'
          '        print(f"  도구 호출: {[tc[\'name\'] for tc in tool_calls]}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 10',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 20',
  'code': '# version="v2" — invoke 는 GraphOutput 을 반환합니다.\n'
          '# 기존 dict 접근(result["messages"]) 대신 result.value["messages"] 로 접근하세요.\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "지금 몇 시인가요?"}]},\n'
          '    config={"configurable": {"thread_id": "v2-demo"}, **lf_config},\n'
          '    version="v2",\n'
          ')\n'
          '\n'
          'print("type:", type(result).__name__)         # GraphOutput\n'
          'print("value keys:", list(result.value.keys()))\n'
          'print("interrupts:", result.interrupts)       # HITL 없으면 빈 리스트\n'
          'print("마지막 메시지:", result.value["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 11',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 21',
  'code': '# stream(..., version="v2") — 각 청크에 type 필드가 포함됩니다.\n'
          '# updates / messages / values / custom 을 한 스트림에서 식별 가능합니다.\n'
          'for chunk in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "지금 몇 시인가요?"}]},\n'
          '    config={"configurable": {"thread_id": "v2-stream"}, **lf_config},\n'
          '    version="v2",\n'
          '):\n'
          '    ctype = chunk.get("type")\n'
          '    if ctype == "updates":\n'
          '        # 노드별 부분 업데이트\n'
          '        for node, update in chunk.get("data", {}).items():\n'
          '            print(f"[updates/{node}] keys={list(update.keys()) if isinstance(update, dict) else '
          'type(update).__name__}")\n'
          '    elif ctype == "messages":\n'
          '        # 토큰 단위 메시지 청크\n'
          '        msg, _meta = chunk["data"]\n'
          '        if hasattr(msg, "content") and msg.content:\n'
          '            print(f"[messages] {msg.content[:60]}")\n'
          '    elif ctype == "custom":\n'
          '        print(f"[custom] {chunk[\'data\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 12',
  'lead': '이 코드는 LangChain 메시지 타입과 대화 문맥 표현을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 23',
  'code': '# 토큰 청크를 누적하여 chunk_position == "last" 시점에 완성된 tool_calls 를 확인합니다.\n'
          'accumulated = None\n'
          'for msg, metadata in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "지금 몇 시인가요?"}]},\n'
          '    config={"configurable": {"thread_id": "tool-stream"}, **lf_config},\n'
          '    stream_mode="messages",\n'
          '):\n'
          '    # AIMessageChunk 는 + 연산자로 누적 가능 — 가장 안전한 방법입니다.\n'
          '    accumulated = msg if accumulated is None else accumulated + msg\n'
          '\n'
          '    if metadata.get("chunk_position") == "last":\n'
          '        # 이 시점에서 tool_calls 의 args 가 완전한 JSON 으로 보장됩니다.\n'
          '        if accumulated.tool_calls:\n'
          '            for tc in accumulated.tool_calls:\n'
          '                print(f"[tool_call 확정] {tc[\'name\']}({tc[\'args\']})")\n'
          '        if accumulated.content:\n'
          '            print(f"[최종 content] {accumulated.content[:200]}")\n'
          '        accumulated = None  # 다음 메시지를 위해 리셋'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 13',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 25',
  'code': '# content_blocks 기반 필터링 — reasoning 모델용 (Claude / o-series)\n'
          '# 일반 모델은 content_blocks 가 단일 text 블록 하나만 갖습니다.\n'
          'for msg, _meta in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "지금 몇 시인가요?"}]},\n'
          '    config={"configurable": {"thread_id": "blocks-demo"}, **lf_config},\n'
          '    stream_mode="messages",\n'
          '):\n'
          '    # content_blocks 는 모델/메시지 타입에 따라 없을 수 있습니다.\n'
          '    blocks = getattr(msg, "content_blocks", None) or []\n'
          '    for block in blocks:\n'
          '        btype = block.get("type") if isinstance(block, dict) else None\n'
          '        if btype == "reasoning":\n'
          '            # 사고 과정 — UI 에서는 접어두기 권장\n'
          '            text = block.get("reasoning", "")\n'
          '            if text:\n'
          '                print(f"[REASONING] {text[:80]}")\n'
          '        elif btype == "text":\n'
          '            text = block.get("text", "")\n'
          '            if text:\n'
          '                print(f"[TEXT] {text[:80]}", end="", flush=True)\n'
          'print()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 05_memory_and_streaming',
  'title': '05_memory_and_streaming 코드 14',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '05_memory_and_streaming.ipynb',
  'note': 'cell 27',
  'code': '# 멀티 모드 — updates 와 messages 를 한 스트림에서 받기\n'
          '# 인터럽트는 updates 청크 안의 "__interrupt__" 키로 도착합니다.\n'
          'for mode, data in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "지금 몇 시인가요?"}]},\n'
          '    config={"configurable": {"thread_id": "multimode"}, **lf_config},\n'
          '    stream_mode=["updates", "messages"],\n'
          '    # subgraphs=True,        # 서브그래프 청크까지 받고 싶다면 활성화\n'
          '):\n'
          '    if mode == "updates":\n'
          '        # HITL 인터럽트 캡처 — Command(resume=...) 로 재개할 때 단서가 됩니다.\n'
          '        if "__interrupt__" in data:\n'
          '            print(f"[INTERRUPT] {data[\'__interrupt__\']}")\n'
          '            continue\n'
          '        for node in data:\n'
          '            print(f"[{mode}/{node}]")\n'
          '    elif mode == "messages":\n'
          '        msg, _meta = data\n'
          '        if hasattr(msg, "content") and msg.content:\n'
          '            print(f"[{mode}] {msg.content[:40]}")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '06_middleware.ipynb',
  'sub': '06_middleware.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/06_middleware.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 01',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'print("모델 준비 완료:", model.model_name)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_middleware.ipynb',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 03 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 8',
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          '\n'
          '@tool\n'
          'def search(query: str) -> str:\n'
          '    """정보를 검색합니다."""\n'
          '    return f"\'{query}\'에 대한 검색 결과"\n'
          '\n'
          '# SummarizationMiddleware — 긴 대화를 자동 요약\n'
          'from langchain.agents.middleware import SummarizationMiddleware\n'
          '\n'
          'summarization = SummarizationMiddleware(\n'
          '    model=model,\n'
          '    trigger=("messages", 10),\n'
          ')\n'
          '\n'
          'agent_with_summary = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[summarization],\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 03 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 8',
  'code': 'print("SummarizationMiddleware 에이전트 생성 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 04',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 10',
  'code': '# Anthropic / Bedrock 프롬프트 캐싱 — 시스템 프롬프트가 크거나 도구가 많을 때 효과적\n'
          'from langchain.agents.middleware import (\n'
          '    AnthropicPromptCachingMiddleware,\n'
          '    BedrockPromptCachingMiddleware,\n'
          ')\n'
          '\n'
          '# Anthropic 직접 호출 (claude-sonnet-4-6 등)\n'
          'anthropic_cache = AnthropicPromptCachingMiddleware()\n'
          '# Bedrock 경유 호출\n'
          'bedrock_cache = BedrockPromptCachingMiddleware()\n'
          '\n'
          '# 예: Anthropic 모델 + 프롬프트 캐싱\n'
          '# from langchain_anthropic import ChatAnthropic\n'
          '# anthropic_model = ChatAnthropic(model="claude-sonnet-4-6")\n'
          '# agent_cached = create_agent(\n'
          '#     model=anthropic_model,\n'
          '#     tools=[search],\n'
          '#     system_prompt="...",\n'
          '#     middleware=[anthropic_cache],\n'
          '# )\n'
          '\n'
          'print("Anthropic/Bedrock 프롬프트 캐싱 미들웨어 생성 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 05',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 11',
  'code': '# ModelFallbackMiddleware — 첫 모델 호출이 실패하면 추가 모델로 순차 폴백\n'
          'from langchain.agents.middleware import ModelFallbackMiddleware\n'
          '\n'
          'primary = ChatOpenAI(model="gpt-5.4")\n'
          'backup_1 = ChatOpenAI(model="gpt-5-nano")\n'
          '# backup_2 = ChatAnthropic(model="claude-sonnet-4-6")  # 다른 프로바이더 폴백도 가능\n'
          '\n'
          'fallback = ModelFallbackMiddleware(primary, backup_1)\n'
          '\n'
          'agent_fallback = create_agent(\n'
          '    model=primary,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[fallback],\n'
          ')\n'
          'print("ModelFallbackMiddleware 에이전트 생성 완료 — primary 실패 시 backup_1 로 폴백")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 06',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 12',
  'code': '# ContextEditingMiddleware — 토큰 임계값 초과 시 오래된 tool_use 메시지를 자동 제거\n'
          '# trigger=("tokens", 100_000) 처럼 ContextSize 튜플로 시점을 결정합니다.\n'
          'from langchain.agents.middleware import ContextEditingMiddleware, ClearToolUsesEdit\n'
          '\n'
          'context_editor = ContextEditingMiddleware(\n'
          '    edits=[\n'
          '        ClearToolUsesEdit(\n'
          '            trigger=("tokens", 100_000),   # 100K 토큰 넘으면 발동\n'
          '            keep=("messages", 3),           # 가장 최근 3개 메시지의 tool_use 는 유지\n'
          '        ),\n'
          '    ],\n'
          ')\n'
          '\n'
          'agent_edited = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[context_editor],\n'
          ')\n'
          'print("ContextEditingMiddleware 에이전트 생성 완료")\n'
          'print("  → 100K 토큰 초과 시 최근 3개 외 오래된 tool_use 메시지를 자동 제거")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 07',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 14',
  'code': 'from langchain.agents.middleware import before_model\n'
          '\n'
          '@before_model\n'
          'def log_model_input(state, runtime):\n'
          '    """모델에 전송하기 전에 메시지를 로깅합니다."""\n'
          '    msg_count = len(state["messages"])\n'
          '    print(f"  모델 입력: {msg_count}개 메시지")\n'
          '\n'
          'agent_logged = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[log_model_input],\n'
          ')\n'
          '\n'
          'print("모델 호출 로깅 테스트:")\n'
          'result = agent_logged.invoke(\n'
          '    {"messages": [{"role": "user", "content": "Python 튜토리얼을 검색해 주세요"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("응답:", result["messages"][-1].content[:200])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 08 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 16',
  'code': 'from langchain.agents.middleware import after_model\n'
          '\n'
          '@after_model\n'
          'def log_model_output(state, runtime):\n'
          '    """모델 출력 생성 후 로깅합니다."""\n'
          '    msg = state["messages"][-1] if state["messages"] else None\n'
          "    if msg and hasattr(msg, 'content') and msg.content:\n"
          '        print(f"  모델 출력: {msg.content[:100]}...")\n'
          "    if msg and hasattr(msg, 'tool_calls') and msg.tool_calls:\n"
          '        print(f"  도구 호출: {[tc[\'name\'] for tc in msg.tool_calls]}")\n'
          '\n'
          'agent_full_log = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[log_model_input, log_model_output],\n'
          ')\n'
          '\n'
          'print("전체 로깅 테스트:")\n'
          'result = agent_full_log.invoke(\n'
          '    {"messages": [{"role": "user", "content": "LangChain v1 기능을 검색해 주세요"}]},\n'
          '    config=lf_config,'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 08 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 16',
  'code': ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 09 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 18',
  'code': 'from langchain.agents.middleware import (\n'
          '    wrap_model_call,\n'
          '    ModelRequest,\n'
          '    ModelResponse,\n'
          ')\n'
          'import time\n'
          '\n'
          '\n'
          '@wrap_model_call\n'
          'def retry_on_error(request: ModelRequest, handler) -> ModelResponse:\n'
          '    """실패 시 지수 백오프로 모델 호출을 재시도합니다.\n'
          '\n'
          '    - request: ModelRequest — messages / tools / system_message / response_format 보유\n'
          '    - handler: 다음 단계를 실행하는 콜러블 (request 를 받아 ModelResponse 반환)\n'
          '    """\n'
          '    max_retries = 2\n'
          '    for attempt in range(max_retries + 1):\n'
          '        try:\n'
          '            return handler(request)\n'
          '        except Exception as e:\n'
          '            if attempt < max_retries:\n'
          '                wait = 2 ** attempt'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 09 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 18',
  'code': '                print(f"  재시도 {attempt + 1}/{max_retries} ({wait}초 대기)")\n'
          '                time.sleep(wait)\n'
          '            else:\n'
          '                raise\n'
          '\n'
          'agent_retry = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[retry_on_error],\n'
          ')\n'
          'print("재시도 미들웨어 에이전트 생성 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 10',
  'lead': '이 코드는 미들웨어 훅과 운영 정책 삽입 지점을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 20',
  'code': '# request.override 로 시스템 메시지·도구 필터를 동적으로 조정\n'
          'from langchain.agents.middleware import wrap_model_call, ModelRequest, ModelResponse\n'
          '\n'
          '\n'
          '@wrap_model_call\n'
          'def restrict_tools_for_anonymous(request: ModelRequest, handler) -> ModelResponse:\n'
          '    """비로그인 사용자에게는 검색 도구만 허용하고 시스템 프롬프트도 교체합니다."""\n'
          '    user_id = request.runtime.context.get("user_id") if hasattr(request, "runtime") else None\n'
          '\n'
          '    if not user_id:\n'
          '        # 비로그인 — 도구 화이트리스트 적용 + 시스템 메시지 교체\n'
          '        safe_tools = [t for t in request.tools if t.name == "search"]\n'
          '        new_request = request.override(\n'
          '            tools=safe_tools,\n'
          '            system_message="당신은 비로그인 사용자를 돕는 제한된 어시스턴트입니다.",\n'
          '        )\n'
          '        return handler(new_request)\n'
          '\n'
          '    return handler(request)\n'
          '\n'
          '\n'
          'print("request.override 패턴 미들웨어 등록 준비 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 11',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 22',
  'code': 'from langchain.agents.middleware import dynamic_prompt\n'
          'from datetime import datetime\n'
          '\n'
          '@dynamic_prompt\n'
          'def add_datetime_context(request):\n'
          '    """시스템 프롬프트에 현재 날짜와 시간을 추가합니다."""\n'
          '    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")\n'
          '    return f"현재 날짜와 시간: {now}\\n\\n당신은 유용한 어시스턴트입니다."\n'
          '\n'
          'agent_dynamic = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    middleware=[add_datetime_context],\n'
          ')\n'
          '\n'
          'result = agent_dynamic.invoke(\n'
          '    {"messages": [{"role": "user", "content": "현재 날짜와 시간이 어떻게 되나요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("동적 프롬프트 응답:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 12 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 24',
  'code': 'from langchain.agents.middleware import wrap_tool_call\n'
          'import time\n'
          '\n'
          '@wrap_tool_call\n'
          'def tool_timing_logger(request, handler):\n'
          '    """실행 시간을 측정하고 도구 입출력을 로깅합니다."""\n'
          '    tool_name = request.tool_call["name"]\n'
          '    tool_args = request.tool_call["args"]\n'
          '    print(f"  [도구 시작] {tool_name} | 입력: {tool_args}")\n'
          '\n'
          '    start = time.perf_counter()\n'
          '    try:\n'
          '        result = handler(request)\n'
          '        elapsed = time.perf_counter() - start\n'
          '        print(f"  [도구 완료] {tool_name} | 소요 시간: {elapsed:.3f}s | 출력: {str(result)[:100]}")\n'
          '        return result\n'
          '    except Exception as e:\n'
          '        elapsed = time.perf_counter() - start\n'
          '        print(f"  [도구 실패] {tool_name} | 소요 시간: {elapsed:.3f}s | 에러: {e}")\n'
          '        raise\n'
          '\n'
          'agent_tool_logged = create_agent('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 12 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 24',
  'code': '    model=model,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다. 검색 도구를 사용하여 정보를 찾으세요.",\n'
          '    middleware=[tool_timing_logger],\n'
          ')\n'
          '\n'
          'print("도구 호출 타이밍/로깅 미들웨어 테스트:")\n'
          'result = agent_tool_logged.invoke(\n'
          '    {"messages": [{"role": "user", "content": "LangChain 미들웨어 문서를 검색해 주세요"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("\\n최종 응답:", result["messages"][-1].content[:200])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 13 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 26',
  'code': '# 키워드 기반 가드레일\n'
          '@before_model\n'
          'def keyword_guardrail(state, runtime):\n'
          '    """금지된 키워드가 포함된 요청을 차단합니다."""\n'
          '    prohibited = ["hack", "exploit", "malware"]\n'
          '    last_msg = state["messages"][-1]\n'
          "    content = last_msg.content if hasattr(last_msg, 'content') else str(last_msg)\n"
          '\n'
          '    for keyword in prohibited:\n'
          '        if keyword.lower() in content.lower():\n'
          '            raise ValueError(f"요청이 안전 정책에 의해 차단되었습니다.")\n'
          '\n'
          'agent_guarded = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[keyword_guardrail],\n'
          ')\n'
          '\n'
          '# 안전한 요청\n'
          'result = agent_guarded.invoke(\n'
          '    {"messages": [{"role": "user", "content": "Python 튜토리얼을 검색해 주세요"}]},'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 13 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 26',
  'code': '    config=lf_config,\n'
          ')\n'
          'print("안전한 요청:", result["messages"][-1].content[:100])\n'
          '\n'
          '# 차단되는 요청\n'
          'try:\n'
          '    result = agent_guarded.invoke(\n'
          '        {"messages": [{"role": "user", "content": "웹사이트 해킹 방법"}]}\n'
          '    )\n'
          'except ValueError as e:\n'
          '    print(f"차단된 요청: {e}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 14 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 28',
  'code': '# 위험한 키워드 감지 시 예외 대신 그래프를 "end" 로 안전하게 점프\n'
          'from langchain.agents.middleware import before_model, hook_config\n'
          'from langchain.messages import AIMessage\n'
          '\n'
          '\n'
          '@hook_config(can_jump_to=["end", "tools", "model"])\n'
          '@before_model\n'
          'def jumping_guardrail(state, runtime):\n'
          '    """금지된 키워드 감지 시 안전한 거절 메시지를 남기고 즉시 종료합니다."""\n'
          '    prohibited = ["hack", "exploit", "malware"]\n'
          '    last_msg = state["messages"][-1]\n'
          '    content = last_msg.content if hasattr(last_msg, "content") else str(last_msg)\n'
          '\n'
          '    for keyword in prohibited:\n'
          '        if keyword.lower() in content.lower():\n'
          '            # 메시지를 추가하면서 즉시 그래프를 종료합니다.\n'
          '            return {\n'
          '                "messages": [AIMessage(content="요청이 안전 정책에 의해 차단되었습니다.")],\n'
          '                "jump_to": "end",\n'
          '            }\n'
          '    # 정상 — 다음 단계로\n'
          '    return None'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 06_middleware',
  'title': '06_middleware 코드 14 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '06_middleware.ipynb',
  'note': 'cell 28',
  'code': '\n'
          '\n'
          'agent_jumping = create_agent(\n'
          '    model=model,\n'
          '    tools=[search],\n'
          '    system_prompt="당신은 유용한 어시스턴트입니다.",\n'
          '    middleware=[jumping_guardrail],\n'
          ')\n'
          '\n'
          'result = agent_jumping.invoke(\n'
          '    {"messages": [{"role": "user", "content": "웹사이트 해킹 방법 알려줘"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("차단 + 점프 결과:", result["messages"][-1].content)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '07_hitl_and_runtime.ipynb',
  'sub': '07_hitl_and_runtime.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/07_hitl_and_runtime.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 01',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          '# requires deepagents>=0.5.0 or langgraph>=1.1.5\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'print("모델 준비 완료:", model.model_name)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '07_hitl_and_runtime.ipynb',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 03 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 8',
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          'from langchain.agents.middleware import HumanInTheLoopMiddleware\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '@tool\n'
          'def send_email(to: str, subject: str, body: str) -> str:\n'
          '    """지정된 수신자에게 이메일을 보냅니다."""\n'
          '    return f"{to}에게 이메일 전송 완료: {subject}"\n'
          '\n'
          '@tool\n'
          'def delete_file(path: str) -> str:\n'
          '    """지정된 경로의 파일을 삭제합니다."""\n'
          '    return f"파일 삭제 완료: {path}"\n'
          '\n'
          '# 도구별로 허용 가능한 decision 목록을 dict 형식으로 지정합니다.\n'
          '# - approve : 그대로 실행\n'
          '# - edit    : 인자를 수정해서 실행\n'
          '# - reject  : 도구 실행 거부 (사유 전달)\n'
          '# - respond : 도구를 실행하지 않고 사람이 직접 응답\n'
          'hitl = HumanInTheLoopMiddleware(\n'
          '    interrupt_on={'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 03 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 8',
  'code': '        "send_email":  {"allowed_decisions": ["approve", "edit", "reject", "respond"]},\n'
          '        "delete_file": {"allowed_decisions": ["approve", "reject"]},  # 편집 없이 승인/거부만\n'
          '    },\n'
          ')\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[send_email, delete_file],\n'
          '    system_prompt="당신은 이메일을 보내고 파일을 관리할 수 있는 어시스턴트입니다.",\n'
          '    middleware=[hitl],\n'
          '    checkpointer=InMemorySaver(),\n'
          ')\n'
          '\n'
          'print("HITL 에이전트 생성 완료")\n'
          'print("  -> 도구 호출 시 사람의 승인을 위해 중단됩니다 (approve/edit/reject/respond)")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 04 (1/2)',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 10',
  'code': 'from langgraph.types import Command\n'
          '\n'
          'config = {"configurable": {"thread_id": "hitl-demo"}}\n'
          '\n'
          '# 1단계: 에이전트 실행 → 도구 호출에서 중단 (version="v2" 로 GraphOutput 반환)\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "bob@example.com에게 제목 \'인사\', 본문 \'안녕하세요 Bob!\' 이메일을 '
          '보내주세요"}]},\n'
          '    config={**config, **lf_config},\n'
          '    version="v2",\n'
          ')\n'
          '\n'
          '# GraphOutput — .value (현재 상태) 와 .interrupts (인터럽트 리스트) 로 접근합니다.\n'
          'print("interrupts:", result.interrupts)\n'
          'print("마지막 메시지:", result.value["messages"][-1])\n'
          'print("\\n도구 실행 전에 에이전트가 중단되었습니다 — Command(resume={\'decisions\':[...]}) 로 재개합니다.")\n'
          '\n'
          '# 2단계: 승인하여 계속 진행 — decisions 리스트의 dict 형식 사용\n'
          'try:\n'
          '    result = agent.invoke(\n'
          '        Command(resume={"decisions": [{"type": "approve"}]}),\n'
          '        config={**config, **lf_config},\n'
          '        version="v2",'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 04 (2/2)',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 10',
  'code': '    )\n'
          '    print("\\n승인 후 결과:", result.value["messages"][-1].content)\n'
          'except Exception as e:\n'
          '    print(f"\\n참고: HITL 데모는 인터랙티브 환경에서 가장 잘 동작합니다. ({e})")\n'
          '\n'
          '# 다른 decision 예시 (실행하지 않음 — 참고용):\n'
          '# Command(resume={"decisions": [{"type": "edit", "args": {"to": "alice@example.com", "subject": "인사", '
          '"body": "안녕!"}}]})\n'
          '# Command(resume={"decisions": [{"type": "reject", "message": "수신자 주소가 잘못되었습니다."}]})\n'
          '# Command(resume={"decisions": [{"type": "respond", "message": "이미 어제 보냈으니 건너뛰세요."}]})'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 05 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 12',
  'code': 'from langchain.tools import ToolRuntime\n'
          'from dataclasses import dataclass\n'
          '\n'
          '@dataclass\n'
          'class UserContext:\n'
          '    """사용자 정보가 포함된 런타임 컨텍스트."""\n'
          '    user_id: str\n'
          '    role: str\n'
          '\n'
          '@tool\n'
          'def get_user_profile(runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """현재 사용자의 프로필 정보를 가져옵니다."""\n'
          '    ctx = runtime.context\n'
          '    return f"사용자 ID: {ctx.user_id}, 역할: {ctx.role}"\n'
          '\n'
          '@tool\n'
          'def check_permissions(action: str, runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """현재 사용자가 작업에 대한 권한이 있는지 확인합니다."""\n'
          '    ctx = runtime.context\n'
          '    if ctx.role == "admin":\n'
          '        return f"사용자 {ctx.user_id}은(는) \'{action}\' 권한이 있습니다"\n'
          '    return f"사용자 {ctx.user_id}은(는) \'{action}\' 권한이 없습니다"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 05 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 12',
  'code': '\n'
          'agent_ctx = create_agent(\n'
          '    model=model,\n'
          '    tools=[get_user_profile, check_permissions],\n'
          '    system_prompt="사용자 프로필과 권한을 확인할 수 있습니다.",\n'
          '    context_schema=UserContext,\n'
          ')\n'
          '\n'
          'result = agent_ctx.invoke(\n'
          '    {"messages": [{"role": "user", "content": "제가 누구이고 파일을 삭제할 수 있나요?"}]},\n'
          '    context=UserContext(user_id="user-42", role="admin"),\n'
          '    config=lf_config,\n'
          '    version="v2",\n'
          ')\n'
          'print("결과:", result.value["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 06 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 14',
  'code': '# runtime.execution_info — thread_id / run_id / attempt 활용\n'
          '@tool\n'
          'def whoami_exec(runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """현재 실행의 thread/run/attempt 정보를 반환합니다."""\n'
          '    info = runtime.execution_info\n'
          '    return (\n'
          '        f"thread_id={info.thread_id} | "\n'
          '        f"run_id={info.run_id} | "\n'
          '        f"attempt={info.attempt}"\n'
          '    )\n'
          '\n'
          'agent_exec = create_agent(\n'
          '    model=model,\n'
          '    tools=[whoami_exec],\n'
          '    system_prompt="실행 정보를 조회할 수 있습니다.",\n'
          '    context_schema=UserContext,\n'
          '    checkpointer=InMemorySaver(),\n'
          ')\n'
          '\n'
          'result = agent_exec.invoke(\n'
          '    {"messages": [{"role": "user", "content": "현재 실행 메타데이터를 알려주세요."}]},\n'
          '    context=UserContext(user_id="user-42", role="admin"),'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 06 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 14',
  'code': '    config={"configurable": {"thread_id": "exec-info-demo"}, **lf_config},\n'
          '    version="v2",\n'
          ')\n'
          'print(result.value["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 07 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 16',
  'code': '# runtime.server_info — 배포 환경 메타데이터 (로컬에서는 빈/None 일 수 있음)\n'
          '@tool\n'
          'def whoami_server(runtime: ToolRuntime[UserContext]) -> str:\n'
          '    """호스트 서버 정보를 반환합니다 (LangGraph Platform 환경)."""\n'
          '    info = runtime.server_info\n'
          '    if info is None:\n'
          '        return "로컬 실행 — server_info 가 비어 있습니다."\n'
          '    return (\n'
          '        f"assistant_id={getattr(info, \'assistant_id\', None)} | "\n'
          '        f"graph_id={getattr(info, \'graph_id\', None)} | "\n'
          '        f"user={getattr(info, \'user\', None)}"\n'
          '    )\n'
          '\n'
          'agent_server = create_agent(\n'
          '    model=model,\n'
          '    tools=[whoami_server],\n'
          '    system_prompt="배포 서버 정보를 조회할 수 있습니다.",\n'
          '    context_schema=UserContext,\n'
          '    checkpointer=InMemorySaver(),\n'
          ')\n'
          '\n'
          'result = agent_server.invoke('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 07 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 16',
  'code': '    {"messages": [{"role": "user", "content": "어느 서버에서 실행 중인가요?"}]},\n'
          '    context=UserContext(user_id="user-42", role="admin"),\n'
          '    config={"configurable": {"thread_id": "server-info-demo"}, **lf_config},\n'
          '    version="v2",\n'
          ')\n'
          'print(result.value["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 08 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 18',
  'code': 'from langchain.agents.middleware import dynamic_prompt\n'
          '\n'
          '@tool\n'
          'def basic_search(query: str) -> str:\n'
          '    """기본 웹 검색을 수행합니다."""\n'
          '    return f"\'{query}\'에 대한 기본 검색 결과"\n'
          '\n'
          '@tool\n'
          'def advanced_analytics(query: str) -> str:\n'
          '    """고급 데이터 분석을 수행합니다."""\n'
          '    return f"\'{query}\'에 대한 분석 보고서"\n'
          '\n'
          '# 사용자 역할에 따라 다른 프롬프트와 도구 제공\n'
          '@dynamic_prompt\n'
          'def role_based_prompt(request):\n'
          '    """컨텍스트에 기반하여 프롬프트를 커스터마이즈합니다."""\n'
          '    return "당신은 전문 어시스턴트입니다. 사용자의 질문에 효율적으로 답변하세요."\n'
          '\n'
          'agent_ctx_eng = create_agent(\n'
          '    model=model,\n'
          '    tools=[basic_search, advanced_analytics],\n'
          '    middleware=[role_based_prompt],'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 08 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 18',
  'code': ')\n'
          '\n'
          'result = agent_ctx_eng.invoke(\n'
          '    {"messages": [{"role": "user", "content": "머신러닝 트렌드를 검색해 주세요"}]},\n'
          '    config=lf_config,\n'
          '    version="v2",\n'
          ')\n'
          'print("컨텍스트 엔지니어링 결과:", result.value["messages"][-1].content[:200])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 07_hitl_and_runtime',
  'title': '07_hitl_and_runtime 코드 09',
  'lead': '이 코드는 MCPAdapter로 로컬 FastMCP 서버의 도구를 가져와 에이전트에 연결합니다.',
  'file': '07_hitl_and_runtime.ipynb',
  'note': 'cell 19',
  'code': 'from pathlib import Path\n'
          'import asyncio, tempfile, sys\n'
          'from langchain.mcp import MCPAdapter\n'
          '\n'
          'server_path = Path(tempfile.gettempdir()) / "lc_mcp_echo_server.py"\n'
          "server_path.write_text('from fastmcp import FastMCP\n"
          'mcp = FastMCP("echo")\n'
          '@mcp.tool()\n'
          'def echo(text: str) -> str:\n'
          '    return f"Echo: {text}"\n'
          'if __name__ == "__main__":\n'
          '    mcp.run(transport="stdio")\')\n'
          '\n'
          'async def run_mcp_agent():\n'
          '    target = {"mcpServers": {"echo": {"command": sys.executable, "args": [str(server_path)]}}}\n'
          '    async with MCPAdapter(target) as adapter:\n'
          '        tools = await adapter.list_tools()\n'
          '        agent = create_agent(model=model, tools=tools, system_prompt="MCP 도구를 사용할 수 있습니다.")\n'
          '        return await agent.ainvoke(\n'
          '            {"messages": [{"role": "user", "content": "echo 도구로 \'안녕하세요\'를 반복해 주세요."}]},\n'
          '            config=lf_config,\n'
          '            version="v2",\n'
          '        )\n'
          '\n'
          'result = asyncio.run(run_mcp_agent())\n'
          'print(result.value["messages"][-1].content)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '08_multi_agent.ipynb',
  'sub': '08_multi_agent.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/08_multi_agent.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 01',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'print("모델 준비 완료:", model.model_name)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '08_multi_agent.ipynb',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 03 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 9',
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          '\n'
          '# 전문 도구 정의\n'
          '@tool\n'
          'def math_expert(question: str) -> str:\n'
          '    """수학 문제를 풀어줍니다. 수학적 계산이 필요할 때 사용하세요."""\n'
          '    # 실제로는 계산 로직이 들어갑니다\n'
          '    return f"수학 답변: \'{question}\'에 대한 답이 계산되었습니다."\n'
          '\n'
          '@tool\n'
          'def code_expert(question: str) -> str:\n'
          '    """프로그래밍 질문에 답합니다. 코딩 관련 질문에 사용하세요."""\n'
          '    return f"코드 답변: \'{question}\'에 대한 솔루션입니다"\n'
          '\n'
          '@tool\n'
          'def general_search(query: str) -> str:\n'
          '    """일반 정보를 검색합니다."""\n'
          '    return f"\'{query}\'에 대한 검색 결과"\n'
          '\n'
          '# 감독자(supervisor) 에이전트\n'
          'supervisor = create_agent('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 03 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 9',
  'code': '    model=model,\n'
          '    tools=[math_expert, code_expert, general_search],\n'
          '    system_prompt="""당신은 전문가에게 작업을 위임하는 감독 에이전트입니다:\n'
          '- 수학 문제는 math_expert를 사용하세요\n'
          '- 프로그래밍 질문은 code_expert를 사용하세요\n'
          '- 그 외에는 general_search를 사용하세요\n'
          '항상 가장 적절한 전문가에게 위임하세요.""",\n'
          ')\n'
          '\n'
          'result = supervisor.invoke(\n'
          '    {"messages": [{"role": "user", "content": "10의 팩토리얼은 얼마인가요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("서브에이전트 결과:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 04 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 11',
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          '\n'
          '# 서브에이전트의 도구 — 여러 번 호출되며 multi-turn 추론을 유발\n'
          '@tool\n'
          'def calc_step(expr: str) -> str:\n'
          '    """수식의 한 단계를 계산합니다 (예: \'3*4\', \'12+5\')."""\n'
          '    try:\n'
          '        return f"{eval(expr, {\'__builtins__\': {}}, {})}"\n'
          '    except Exception as e:\n'
          '        return f"err: {e}"\n'
          '\n'
          '# checkpointer=True → 서브에이전트만의 로컬 히스토리\n'
          'math_subagent = create_agent(\n'
          '    model=model,\n'
          '    tools=[calc_step],\n'
          '    system_prompt="복잡한 계산은 calc_step을 여러 번 나눠서 호출하세요. 마지막에 최종 답만 한 줄로 반환합니다.",\n'
          '    checkpointer=True,  # subagent-local history\n'
          '    name="math_subagent",\n'
          ')\n'
          '\n'
          '@tool'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 04 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 11',
  'code': 'def math_expert_v2(question: str) -> str:\n'
          '    """수학 문제를 서브에이전트에 위임합니다. 내부 추론은 외부에 노출되지 않습니다."""\n'
          '    # 서브에이전트만의 thread_id 부여\n'
          '    sub_cfg = {"configurable": {"thread_id": f"math-{hash(question) & 0xffff}"}}\n'
          '    sub_result = math_subagent.invoke(\n'
          '        {"messages": [{"role": "user", "content": question}]},\n'
          '        config=sub_cfg,\n'
          '    )\n'
          '    return sub_result["messages"][-1].content\n'
          '\n'
          'supervisor_v2 = create_agent(\n'
          '    model=model,\n'
          '    tools=[math_expert_v2],\n'
          '    system_prompt="수학 문제는 math_expert_v2에 위임하세요.",\n'
          ')\n'
          '\n'
          'result = supervisor_v2.invoke(\n'
          '    {"messages": [{"role": "user", "content": "(15 + 27) * 3 의 값은?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("최종 답:", result["messages"][-1].content)\n'
          'print("\\n메인 메시지 수 (서브 내부 turn 미노출):", len(result["messages"]))'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 05 (1/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 13',
  'code': 'from typing import Literal\n'
          '\n'
          '# 서브에이전트 레지스트리\n'
          'SUBAGENTS = {\n'
          '    "math": math_subagent,\n'
          '    "code": create_agent(model=model, tools=[], system_prompt="코딩 전문가입니다.", name="code"),\n'
          '    "search": create_agent(model=model, tools=[], system_prompt="검색 전문가입니다.", name="search"),\n'
          '}\n'
          '\n'
          '# (A) System prompt 열거 — 소규모\n'
          'SYSTEM_PROMPT_A = """다음 서브에이전트에 위임하세요:\n'
          '- math: 수학·계산\n'
          '- code: 프로그래밍\n'
          '- search: 일반 검색\n'
          '필요한 서브에이전트 이름과 함께 dispatch를 호출하세요."""\n'
          '\n'
          '# (B) Literal 인자 제약 — 중규모. 모델이 enum 밖의 이름을 못 만들도록 schema 단에서 차단\n'
          '@tool\n'
          'def dispatch(\n'
          '    subagent: Literal["math", "code", "search"],  # ← schema 레벨 enum\n'
          '    question: str,\n'
          ') -> str:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 05 (2/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 13',
  'code': '    """선택한 서브에이전트에게 질문을 위임합니다."""\n'
          '    agent = SUBAGENTS[subagent]\n'
          '    cfg = {"configurable": {"thread_id": f"{subagent}-{hash(question) & 0xffff}"}}\n'
          '    res = agent.invoke({"messages": [{"role": "user", "content": question}]}, config=cfg)\n'
          '    return res["messages"][-1].content\n'
          '\n'
          '# (C) Tool-based discovery — 대규모\n'
          '@tool\n'
          'def list_subagents() -> str:\n'
          '    """등록된 서브에이전트 목록을 반환합니다."""\n'
          '    return ", ".join(SUBAGENTS.keys())\n'
          '\n'
          '@tool\n'
          'def describe_subagent(name: str) -> str:\n'
          '    """특정 서브에이전트의 역할 설명을 반환합니다."""\n'
          '    descriptions = {"math": "수학 계산 전문가", "code": "코딩 전문가", "search": "일반 검색"}\n'
          '    return descriptions.get(name, "unknown")\n'
          '\n'
          '# 패턴 B 사용 예시\n'
          'dispatcher_b = create_agent(\n'
          '    model=model,\n'
          '    tools=[dispatch],  # 단일 dispatch tool, schema에 enum 박힘'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 05 (3/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 13',
  'code': '    system_prompt="질문을 적절한 서브에이전트에 위임하세요.",\n'
          ')\n'
          '\n'
          'result = dispatcher_b.invoke(\n'
          '    {"messages": [{"role": "user", "content": "12 * 9 는?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("패턴 B 결과:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 06 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 15',
  'code': 'from langchain.tools import tool, ToolRuntime\n'
          'from langchain.agents import AgentState\n'
          'from typing import Annotated\n'
          '\n'
          '\n'
          '# 부모 그래프의 커스텀 state — AgentState 확장\n'
          'class SupportState(AgentState):\n'
          '    user_id: str\n'
          '    tenant: str\n'
          '    audit_log: list[str]\n'
          '\n'
          '\n'
          '@tool\n'
          'def lookup_account(query: str, runtime: ToolRuntime[None, SupportState]) -> str:\n'
          '    """현재 사용자의 계정 정보를 조회합니다. 부모 state에서 user_id를 읽습니다."""\n'
          '    state = runtime.state\n'
          '    user_id = state.get("user_id", "unknown")\n'
          '    tenant = state.get("tenant", "default")\n'
          '    # 실제로는 DB 조회. 여기선 데모용.\n'
          '    result = f"[{tenant}] user={user_id} → 활성 계정, 마지막 로그인 2025-05-24"\n'
          '    return result\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 06 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 15',
  'code': '\n'
          '# state_schema에 SupportState를 명시 → ToolRuntime이 자동 주입\n'
          'support_agent_v2 = create_agent(\n'
          '    model=model,\n'
          '    tools=[lookup_account],\n'
          '    system_prompt="사용자 계정 문의에 lookup_account로 답하세요. user_id를 묻지 마세요(state에 이미 있음).",\n'
          '    state_schema=SupportState,\n'
          ')\n'
          '\n'
          'result = support_agent_v2.invoke(\n'
          '    {\n'
          '        "messages": [{"role": "user", "content": "내 계정 상태 알려줘"}],\n'
          '        "user_id": "u-42",\n'
          '        "tenant": "acme-corp",\n'
          '        "audit_log": [],\n'
          '    },\n'
          '    config=lf_config,\n'
          ')\n'
          'print("부모 state 주입 결과:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 07 (1/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 17',
  'code': 'import threading\n'
          'import uuid\n'
          'import time\n'
          '\n'
          '# 인메모리 잡 큐 — 실전에선 Redis/Celery 등\n'
          'JOBS: dict[str, dict] = {}\n'
          '\n'
          '\n'
          'def _background_worker(job_id: str, task: str):\n'
          '    """백그라운드 스레드에서 서브에이전트를 실행."""\n'
          '    JOBS[job_id]["status"] = "running"\n'
          '    try:\n'
          '        # 무거운 작업 시뮬레이션\n'
          '        time.sleep(0.5)\n'
          '        # 실제로는 서브에이전트 invoke\n'
          '        JOBS[job_id]["status"] = "done"\n'
          '        JOBS[job_id]["result"] = f"\'{task}\' 작업 완료: 분석 결과 23 페이지 생성"\n'
          '    except Exception as e:\n'
          '        JOBS[job_id]["status"] = "failed"\n'
          '        JOBS[job_id]["error"] = str(e)\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 07 (2/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 17',
  'code': '@tool\n'
          'def start_job(task: str) -> str:\n'
          '    """장시간 분석 작업을 시작합니다. 즉시 job_id를 반환합니다."""\n'
          '    job_id = uuid.uuid4().hex[:8]\n'
          '    JOBS[job_id] = {"status": "pending", "task": task}\n'
          '    threading.Thread(target=_background_worker, args=(job_id, task), daemon=True).start()\n'
          '    return f"started: job_id={job_id}"\n'
          '\n'
          '\n'
          '@tool\n'
          'def check_status(job_id: str) -> str:\n'
          '    """작업의 현재 상태를 폴링합니다."""\n'
          '    j = JOBS.get(job_id)\n'
          '    if not j:\n'
          '        return f"unknown job_id: {job_id}"\n'
          '    return j["status"]\n'
          '\n'
          '\n'
          '@tool\n'
          'def get_result(job_id: str) -> str:\n'
          '    """완료된 작업의 결과를 가져옵니다. 미완료 시 에러 안내."""\n'
          '    j = JOBS.get(job_id)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 07 (3/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 17',
  'code': '    if not j:\n'
          '        return f"unknown job_id: {job_id}"\n'
          '    if j["status"] != "done":\n'
          '        return f"not ready (status={j[\'status\']}). check_status로 다시 확인하세요."\n'
          '    return j["result"]\n'
          '\n'
          '\n'
          'async_dispatcher = create_agent(\n'
          '    model=model,\n'
          '    tools=[start_job, check_status, get_result],\n'
          '    system_prompt=(\n'
          '        "긴 분석 작업은 start_job으로 시작하고, check_status로 폴링한 뒤 "\n'
          '        "done이 되면 get_result로 결과를 가져오세요. 한 턴에 한두 번만 폴링하세요."\n'
          '    ),\n'
          ')\n'
          '\n'
          'result = async_dispatcher.invoke(\n'
          '    {"messages": [{"role": "user", "content": "Q1 매출 데이터 분석을 시작하고 결과를 알려줘."}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("비동기 결과:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 08 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 19',
  'code': 'from langgraph.types import Command\n'
          'from langchain_core.messages import ToolMessage\n'
          '\n'
          '\n'
          '@tool\n'
          'def record_finding(\n'
          '    finding: str,\n'
          '    runtime: ToolRuntime[None, SupportState],\n'
          ') -> Command:\n'
          '    """발견 사항을 부모 state의 audit_log에 누적합니다."""\n'
          '    existing = runtime.state.get("audit_log", [])\n'
          '    tool_call_id = runtime.tool_call_id  # ToolMessage 매칭용\n'
          '    return Command(\n'
          '        update={\n'
          '            "audit_log": existing + [finding],\n'
          '            # 부모 메시지에는 짧은 확인만 흘림\n'
          '            "messages": [\n'
          '                ToolMessage(\n'
          '                    content=f"기록됨: {finding[:30]}...",\n'
          '                    tool_call_id=tool_call_id,\n'
          '                )\n'
          '            ],'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 08 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 19',
  'code': '        }\n'
          '    )\n'
          '\n'
          '\n'
          'audit_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[record_finding],\n'
          '    system_prompt="중요한 발견은 record_finding으로 기록하세요.",\n'
          '    state_schema=SupportState,\n'
          ')\n'
          '\n'
          'result = audit_agent.invoke(\n'
          '    {\n'
          '        "messages": [{"role": "user", "content": "보안 점검 결과 두 건을 기록해줘: 1) 로그인 실패 다수 감지, 2) 미사용 관리자 계정 '
          '발견"}],\n'
          '        "user_id": "auditor-1",\n'
          '        "tenant": "acme",\n'
          '        "audit_log": [],\n'
          '    },\n'
          '    config=lf_config,\n'
          ')\n'
          'print("최종 audit_log:", result.get("audit_log"))\n'
          'print("최종 응답:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 09 (1/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 21',
  'code': 'from langgraph.types import Command\n'
          'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          '\n'
          '# 핸드오프를 위한 도구\n'
          '@tool\n'
          'def transfer_to_sales() -> Command:\n'
          '    """대화를 영업 부서로 전환합니다."""\n'
          '    return Command(goto="sales_agent", graph=Command.PARENT)\n'
          '\n'
          '@tool\n'
          'def transfer_to_support() -> Command:\n'
          '    """대화를 기술 지원 부서로 전환합니다."""\n'
          '    return Command(goto="support_agent", graph=Command.PARENT)\n'
          '\n'
          '@tool\n'
          'def resolve_query(answer: str) -> str:\n'
          '    """사용자에게 최종 답변을 제공합니다."""\n'
          '    return answer\n'
          '\n'
          '# 라우터 에이전트\n'
          'router_agent = create_agent(\n'
          '    model=model,'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 09 (2/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 21',
  'code': '    tools=[transfer_to_sales, transfer_to_support],\n'
          '    system_prompt="당신은 안내 데스크입니다. 고객을 적절한 부서로 안내하세요.",\n'
          '    name="router",\n'
          ')\n'
          '\n'
          '# 영업 에이전트\n'
          'sales_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[resolve_query],\n'
          '    system_prompt="당신은 영업 에이전트입니다. 가격 및 제품 문의를 도와주세요.",\n'
          '    name="sales_agent",\n'
          ')\n'
          '\n'
          '# 지원 에이전트\n'
          'support_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[resolve_query],\n'
          '    system_prompt="당신은 기술 지원 에이전트입니다. 기술적 문제를 도와주세요.",\n'
          '    name="support_agent",\n'
          ')\n'
          '\n'
          '# 핸드오프 그래프 구성'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 09 (3/3)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 21',
  'code': 'builder = StateGraph(MessagesState)\n'
          'builder.add_node(router_agent)\n'
          'builder.add_node(sales_agent)\n'
          'builder.add_node(support_agent)\n'
          'builder.add_edge(START, "router")\n'
          '\n'
          'graph = builder.compile()\n'
          '\n'
          'result = graph.invoke(\n'
          '    {"messages": [{"role": "user", "content": "엔터프라이즈 플랜 가격을 알고 싶습니다."}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("핸드오프 결과:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 10 (1/5)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 23',
  'code': 'from langchain.agents.middleware import wrap_model_call\n'
          'from langchain.agents import AgentState\n'
          'from langchain_core.messages import ToolMessage\n'
          '\n'
          '\n'
          '# role을 가진 state\n'
          'class HandoffState(AgentState):\n'
          '    role: str  # "router" / "sales" / "support"\n'
          '\n'
          '\n'
          '# 역할별 페르소나\n'
          'PERSONAS = {\n'
          '    "router": {\n'
          '        "system": "당신은 안내 데스크입니다. 문의 유형에 따라 transfer_to_sales/transfer_to_support를 호출하세요.",\n'
          '        "tool_names": ["transfer_to_sales", "transfer_to_support"],\n'
          '    },\n'
          '    "sales": {\n'
          '        "system": "당신은 영업 에이전트입니다. 가격·제품 문의에 답하세요.",\n'
          '        "tool_names": ["resolve_query"],\n'
          '    },\n'
          '    "support": {\n'
          '        "system": "당신은 기술 지원 에이전트입니다. 기술적 문제를 해결하세요.",'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 10 (2/5)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 23',
  'code': '        "tool_names": ["resolve_query"],\n'
          '    },\n'
          '}\n'
          '\n'
          '\n'
          '@tool\n'
          'def transfer_to_sales_v2(runtime: ToolRuntime[None, HandoffState]) -> Command:\n'
          '    """대화를 영업으로 전환합니다."""\n'
          '    return Command(\n'
          '        update={\n'
          '            "role": "sales",\n'
          '            "messages": [\n'
          '                ToolMessage(content="영업 부서로 전환합니다.", tool_call_id=runtime.tool_call_id)\n'
          '            ],\n'
          '        }\n'
          '    )\n'
          '\n'
          '\n'
          '@tool\n'
          'def transfer_to_support_v2(runtime: ToolRuntime[None, HandoffState]) -> Command:\n'
          '    """대화를 기술 지원으로 전환합니다."""\n'
          '    return Command('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 10 (3/5)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 23',
  'code': '        update={\n'
          '            "role": "support",\n'
          '            "messages": [\n'
          '                ToolMessage(content="기술 지원으로 전환합니다.", tool_call_id=runtime.tool_call_id)\n'
          '            ],\n'
          '        }\n'
          '    )\n'
          '\n'
          '\n'
          '@tool\n'
          'def resolve_query_v2(answer: str) -> str:\n'
          '    """사용자에게 최종 답변을 제공합니다."""\n'
          '    return answer\n'
          '\n'
          '\n'
          'ALL_TOOLS = {\n'
          '    "transfer_to_sales": transfer_to_sales_v2,\n'
          '    "transfer_to_support": transfer_to_support_v2,\n'
          '    "resolve_query": resolve_query_v2,\n'
          '}\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 10 (4/5)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 23',
  'code': '# 핵심: 매 모델 호출 직전, state.role에 맞춰 system_prompt와 tools를 교체\n'
          '@wrap_model_call\n'
          'def persona_router(request, handler):\n'
          '    role = request.state.get("role", "router")\n'
          '    persona = PERSONAS[role]\n'
          '    request = request.override(\n'
          '        system_prompt=persona["system"],\n'
          '        tools=[ALL_TOOLS[n] for n in persona["tool_names"]],\n'
          '    )\n'
          '    return handler(request)\n'
          '\n'
          '\n'
          'unified_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=list(ALL_TOOLS.values()),  # 모든 도구를 등록, 실제 노출은 미들웨어가 조정\n'
          '    middleware=[persona_router],\n'
          '    state_schema=HandoffState,\n'
          ')\n'
          '\n'
          'result = unified_agent.invoke(\n'
          '    {\n'
          '        "messages": [{"role": "user", "content": "엔터프라이즈 플랜 가격을 알고 싶습니다."}],'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 10 (5/5)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 23',
  'code': '        "role": "router",\n'
          '    },\n'
          '    config=lf_config,\n'
          ')\n'
          'print("최종 role:", result.get("role"))\n'
          'print("최종 응답:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 11 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 26',
  'code': '# 스킬 정의\n'
          'skills = {\n'
          '    "translator": "당신은 전문 번역가입니다. 언어 간 텍스트를 정확하게 번역하세요.",\n'
          '    "summarizer": "당신은 전문 요약가입니다. 긴 텍스트를 간결하게 요약하세요.",\n'
          '    "coder": "당신은 전문 프로그래머입니다. 깔끔하고 효율적인 코드를 작성하세요.",\n'
          '}\n'
          '\n'
          '@tool\n'
          'def load_skill(skill_name: str) -> str:\n'
          '    """전문 스킬을 로드합니다. 사용 가능한 스킬: translator, summarizer, coder."""\n'
          '    if skill_name in skills:\n'
          '        return f"스킬 로드 완료: {skill_name}. 지침: {skills[skill_name]}"\n'
          '    return f"알 수 없는 스킬: {skill_name}. 사용 가능: {list(skills.keys())}"\n'
          '\n'
          'skill_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[load_skill],\n'
          '    system_prompt="""당신은 전문 기술에 접근할 수 있는 다재다능한 어시스턴트입니다.\n'
          '사용자의 요청을 처리하기 전에 적절한 스킬을 로드하세요.""",\n'
          ')\n'
          '\n'
          'result = skill_agent.invoke('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 11 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 26',
  'code': '    {"messages": [{"role": "user", "content": "\'Hello World\'를 한국어와 일본어로 번역해 주세요."}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("스킬 패턴 결과:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 12 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 28',
  'code': 'from langgraph.types import Send\n'
          '\n'
          '@tool\n'
          'def classify_query(query: str) -> str:\n'
          '    """쿼리를 카테고리로 분류합니다: math, code, general."""\n'
          '    query_lower = query.lower()\n'
          '    if any(w in query_lower for w in ["calculate", "math", "sum", "multiply"]):\n'
          '        return "math"\n'
          '    elif any(w in query_lower for w in ["code", "program", "function", "python"]):\n'
          '        return "code"\n'
          '    return "general"\n'
          '\n'
          '# 라우터: 분류 결과에 따라 전문 에이전트로 전달\n'
          'router = create_agent(\n'
          '    model=model,\n'
          '    tools=[classify_query, math_expert, code_expert, general_search],\n'
          '    system_prompt="""당신은 라우팅 에이전트입니다. 먼저 쿼리를 분류한 다음 적절한 전문가에게 전달하세요:\n'
          '- 수학 쿼리 -> math_expert 사용\n'
          '- 코드 쿼리 -> code_expert 사용\n'
          '- 일반 쿼리 -> general_search 사용""",\n'
          ')\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 12 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 28',
  'code': 'result = router.invoke(\n'
          '    {"messages": [{"role": "user", "content": "리스트를 정렬하는 Python 함수를 작성해 주세요."}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("라우터 결과:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 13 (1/4)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 30',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.types import Command, Send\n'
          'from typing import TypedDict, Annotated\n'
          'import operator\n'
          '\n'
          '\n'
          'class FanOutState(TypedDict):\n'
          '    query: str\n'
          '    # 여러 도메인에서 비동기로 결과가 쌓이도록 reducer 사용\n'
          '    results: Annotated[list[str], operator.add]\n'
          '\n'
          '\n'
          'def classifier(state: FanOutState) -> Command:\n'
          '    """질문에서 도메인을 여러 개 뽑아 각 전문가 노드로 Send."""\n'
          '    q = state["query"].lower()\n'
          '    domains = []\n'
          '    if any(w in q for w in ["수학", "계산", "math", "+", "*"]):\n'
          '        domains.append({"agent": "math_node", "query": state["query"]})\n'
          '    if any(w in q for w in ["코드", "함수", "python", "code"]):\n'
          '        domains.append({"agent": "code_node", "query": state["query"]})\n'
          '    if not domains:\n'
          '        domains.append({"agent": "general_node", "query": state["query"]})'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 13 (2/4)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 30',
  'code': '\n'
          '    # 핵심: Send 리스트로 fan-out\n'
          '    return Command(\n'
          '        goto=[Send(c["agent"], {"query": c["query"]}) for c in domains]\n'
          '    )\n'
          '\n'
          '\n'
          'def math_node(state: dict) -> dict:\n'
          '    return {"results": [f"[math] {state[\'query\']} → 결과 계산됨"]}\n'
          '\n'
          '\n'
          'def code_node(state: dict) -> dict:\n'
          '    return {"results": [f"[code] {state[\'query\']} → 코드 스니펫 생성됨"]}\n'
          '\n'
          '\n'
          'def general_node(state: dict) -> dict:\n'
          '    return {"results": [f"[general] {state[\'query\']} → 일반 답변"]}\n'
          '\n'
          '\n'
          'def aggregator(state: FanOutState) -> dict:\n'
          '    return {"results": state["results"]}  # 그대로 통합\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 13 (3/4)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 30',
  'code': '\n'
          'builder = StateGraph(FanOutState)\n'
          'builder.add_node("classifier", classifier)\n'
          'builder.add_node("math_node", math_node)\n'
          'builder.add_node("code_node", code_node)\n'
          'builder.add_node("general_node", general_node)\n'
          'builder.add_node("aggregator", aggregator)\n'
          '\n'
          'builder.add_edge(START, "classifier")\n'
          '# classifier가 Command(goto=[Send(...), Send(...)])로 분배 → 동적 엣지\n'
          'builder.add_edge("math_node", "aggregator")\n'
          'builder.add_edge("code_node", "aggregator")\n'
          'builder.add_edge("general_node", "aggregator")\n'
          'builder.add_edge("aggregator", END)\n'
          '\n'
          'fanout_graph = builder.compile()\n'
          '\n'
          '# 수학 + 코드 두 도메인에 동시 fan-out되는 질문\n'
          'result = fanout_graph.invoke(\n'
          '    {"query": "리스트 합계를 계산하는 python 함수를 작성해줘", "results": []},\n'
          '    config=lf_config,\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 08_multi_agent',
  'title': '08_multi_agent 코드 13 (4/4)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '08_multi_agent.ipynb',
  'note': 'cell 30',
  'code': 'print("fan-out 결과:")\nfor r in result["results"]:\n    print(" -", r)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '09_custom_workflow_and_rag.ipynb',
  'sub': '09_custom_workflow_and_rag.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/09_custom_workflow_and_rag.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 01',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          '\n'
          'print("환경 준비 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 03 (1/3)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 7',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from typing import TypedDict\n'
          '\n'
          '\n'
          '# 상태 정의\n'
          'class WorkflowState(TypedDict):\n'
          '    input: str\n'
          '    processed: str\n'
          '    output: str\n'
          '\n'
          '\n'
          '# 노드 함수 정의\n'
          'def preprocess(state: WorkflowState) -> dict:\n'
          '    """\n'
          '    전처리: 입력 텍스트를 정리합니다.\n'
          '    """\n'
          '    return {\n'
          '        "processed": state["input"].strip().lower()\n'
          '    }\n'
          '\n'
          '\n'
          'def analyze(state: WorkflowState) -> dict:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 03 (2/3)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 7',
  'code': '    """\n'
          '    분석: 처리된 텍스트를 분석합니다.\n'
          '    """\n'
          '    text = state["processed"]\n'
          '    word_count = len(text.split())\n'
          '\n'
          '    return {\n'
          '        "output": f"분석 완료: \'{text}\'는 {word_count}단어입니다."\n'
          '    }\n'
          '\n'
          '\n'
          '# 그래프 구성\n'
          'builder = StateGraph(WorkflowState)\n'
          '\n'
          'builder.add_node("preprocess", preprocess)\n'
          'builder.add_node("analyze", analyze)\n'
          '\n'
          'builder.add_edge(START, "preprocess")\n'
          'builder.add_edge("preprocess", "analyze")\n'
          'builder.add_edge("analyze", END)\n'
          '\n'
          'graph = builder.compile()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 03 (3/3)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 7',
  'code': '\n'
          '\n'
          '# 실행\n'
          'result = graph.invoke(\n'
          '    {\n'
          '        "input": "  Hello World from LangGraph!  "\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print("입력:", result["input"])\n'
          'print("전처리:", result["processed"])\n'
          'print("출력:", result["output"])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 04 (1/3)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 9',
  'code': 'class RouterState(TypedDict):\n'
          '    input: str\n'
          '    category: str\n'
          '    output: str\n'
          '\n'
          'def classify(state: RouterState) -> dict:\n'
          '    """입력을 분류합니다."""\n'
          '    text = state["input"].lower()\n'
          '    if any(w in text for w in ["calculate", "math", "sum"]):\n'
          '        return {"category": "math"}\n'
          '    elif any(w in text for w in ["translate", "language"]):\n'
          '        return {"category": "language"}\n'
          '    return {"category": "general"}\n'
          '\n'
          'def handle_math(state: RouterState) -> dict:\n'
          '    return {"output": f"[수학 핸들러] 처리 중: {state[\'input\']}"}\n'
          '\n'
          'def handle_language(state: RouterState) -> dict:\n'
          '    return {"output": f"[언어 핸들러] 처리 중: {state[\'input\']}"}\n'
          '\n'
          'def handle_general(state: RouterState) -> dict:\n'
          '    return {"output": f"[일반 핸들러] 처리 중: {state[\'input\']}"}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 04 (2/3)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 9',
  'code': '\n'
          'def route(state: RouterState) -> str:\n'
          '    """분류 결과에 따라 라우팅"""\n'
          '    return state["category"]\n'
          '\n'
          'builder = StateGraph(RouterState)\n'
          'builder.add_node("classify", classify)\n'
          'builder.add_node("math", handle_math)\n'
          'builder.add_node("language", handle_language)\n'
          'builder.add_node("general", handle_general)\n'
          '\n'
          'builder.add_edge(START, "classify")\n'
          'builder.add_conditional_edges("classify", route, {\n'
          '    "math": "math",\n'
          '    "language": "language",\n'
          '    "general": "general",\n'
          '})\n'
          'builder.add_edge("math", END)\n'
          'builder.add_edge("language", END)\n'
          'builder.add_edge("general", END)\n'
          '\n'
          'graph = builder.compile()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 04 (3/3)',
  'lead': '이 코드는 StateGraph로 직접 워크플로를 조립하는 방식을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 9',
  'code': '\n'
          '# 테스트\n'
          'for query in ["2+2를 계산해줘", "hello를 한국어로 번역해줘", "AI란 무엇인가요?"]:\n'
          '    result = graph.invoke({"input": query}, config=lf_config)\n'
          '    print(f"  {query} → {result[\'output\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 05 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 11',
  'code': 'from langgraph.graph import MessagesState\n'
          '\n'
          '@tool\n'
          'def web_search(query: str) -> str:\n'
          '    """웹에서 정보를 검색합니다."""\n'
          '    return f"\'{query}\'에 대한 검색 결과"\n'
          '\n'
          '# 에이전트를 노드로 사용\n'
          'research_agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[web_search],\n'
          '    system_prompt="당신은 리서치 어시스턴트입니다. 정보를 검색하고 간결한 답변을 제공하세요.",\n'
          '    name="researcher",\n'
          ')\n'
          '\n'
          '@tool\n'
          'def format_report(content: str) -> str:\n'
          '    """콘텐츠를 구조화된 보고서 형식으로 변환합니다."""\n'
          '    return f"## 보고서\\n\\n{content}"\n'
          '\n'
          'writer_agent = create_agent(\n'
          '    model=model,'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 05 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 11',
  'code': '    tools=[format_report],\n'
          '    system_prompt="당신은 테크니컬 라이터입니다. 조사 결과를 깔끔한 보고서로 정리하세요.",\n'
          '    name="writer",\n'
          ')\n'
          '\n'
          '# 리서치 → 작성 파이프라인\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node(research_agent)\n'
          'builder.add_node(writer_agent)\n'
          'builder.add_edge(START, "researcher")\n'
          'builder.add_edge("researcher", "writer")\n'
          'builder.add_edge("writer", END)\n'
          '\n'
          'pipeline = builder.compile()\n'
          '\n'
          'result = pipeline.invoke(\n'
          '    {"messages": [{"role": "user", "content": "LangChain v1의 주요 기능을 조사해 주세요."}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("파이프라인 결과:", result["messages"][-1].content[:300])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 06 (1/2)',
  'lead': '이 코드는 미들웨어 훅과 운영 정책 삽입 지점을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 15',
  'code': 'from langchain_text_splitters import RecursiveCharacterTextSplitter\n'
          '\n'
          '# 샘플 문서\n'
          'documents = [\n'
          '    "LangChain is a framework for building applications with large language models. It provides tools for '
          'prompt engineering, memory management, and agent creation.",\n'
          '    "LangGraph is a low-level orchestration framework for building stateful agents. It uses a graph-based '
          'approach with nodes and edges.",\n'
          '    "Middleware in LangChain v1 allows you to intercept and modify agent behavior at every step. You can '
          'add logging, guardrails, and custom logic.",\n'
          '    "Multi-agent systems in LangChain support five patterns: subagents, handoffs, skills, router, and '
          'custom workflows.",\n'
          '    "RAG (Retrieval-Augmented Generation) combines information retrieval with text generation to provide '
          'grounded, factual responses.",\n'
          ']\n'
          '\n'
          '# 텍스트 분할\n'
          'text_splitter = RecursiveCharacterTextSplitter(\n'
          '    chunk_size=200,\n'
          '    chunk_overlap=50,\n'
          ')\n'
          '\n'
          'chunks = []\n'
          'for doc in documents:\n'
          '    chunks.extend(text_splitter.split_text(doc))\n'
          '\n'
          'print(f"원본 문서: {len(documents)}개")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 06 (2/2)',
  'lead': '이 코드는 미들웨어 훅과 운영 정책 삽입 지점을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 15',
  'code': 'print(f"분할 청크: {len(chunks)}개")\nfor i, chunk in enumerate(chunks):\n    print(f"  [{i}] {chunk[:80]}...")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 07 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 16',
  'code': '# 간단한 키워드 기반 검색 (벡터 스토어 없이)\n'
          'def simple_search(query: str, documents: list[str], top_k: int = 2) -> list[str]:\n'
          '    """간단한 키워드 기반 검색입니다."""\n'
          '    scores = []\n'
          '    query_words = set(query.lower().split())\n'
          '    for doc in documents:\n'
          '        doc_words = set(doc.lower().split())\n'
          '        score = len(query_words & doc_words)\n'
          '        scores.append((score, doc))\n'
          '    scores.sort(reverse=True)\n'
          '    return [doc for _, doc in scores[:top_k]]\n'
          '\n'
          '# RAG 도구\n'
          '@tool\n'
          'def retrieve_info(query: str) -> str:\n'
          '    """지식 베이스에서 관련 정보를 검색합니다."""\n'
          '    results = simple_search(query, chunks, top_k=3)\n'
          '    return "\\n\\n".join(results)\n'
          '\n'
          '# RAG 에이전트\n'
          'rag_agent = create_agent(\n'
          '    model=model,'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 07 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 16',
  'code': '    tools=[retrieve_info],\n'
          '    system_prompt="""당신은 지식이 풍부한 어시스턴트입니다. 항상 retrieve_info 도구를 사용하여 정보를 검색한 후 답변하세요.\n'
          '검색된 정보를 바탕으로 답변하세요.""",\n'
          ')\n'
          '\n'
          'result = rag_agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "LangChain의 멀티에이전트 패턴은 무엇인가요?"}]},\n'
          '    config=lf_config,\n'
          ')\n'
          'print("RAG 에이전트 결과:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 09_custom_workflow_and_rag',
  'title': '09_custom_workflow_and_rag 코드 08',
  'lead': '이 코드는 RAG 검색과 문서 근거 연결 방식을 보여줍니다.',
  'file': '09_custom_workflow_and_rag.ipynb',
  'note': 'cell 18',
  'code': 'from langchain_openai import OpenAIEmbeddings\n'
          'from langchain_community.vectorstores import FAISS\n'
          '\n'
          '# 임베딩 모델  생성\n'
          'embeddings = OpenAIEmbeddings(model="text-embedding-3-small")\n'
          '\n'
          '# 벡터 스토어 생성\n'
          'vectorstore = FAISS.from_texts(chunks, embeddings)\n'
          '\n'
          '# 검색\n'
          'results = vectorstore.similarity_search("LangChain agent patterns", k=3)\n'
          'for doc in results:\n'
          '    print(doc.page_content)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '10_production.ipynb',
  'sub': '10_production.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/10_production.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 01',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          '\n'
          'print("환경 준비 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 02 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) — LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제해 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_* 환경변수로 통일 (LangChain 1.x 기준)\n'
          '# LANGSMITH_TRACING=true 이면 LangChain SDK가 자동으로 트레이스를 보냅니다.\n'
          'os.environ.setdefault("LANGSMITH_TRACING", os.environ.get("LANGSMITH_TRACING", "false"))\n'
          'os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          'os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '\n'
          'if os.environ["LANGSMITH_TRACING"].lower() == "true":\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          'else:\n'
          '    print("LangSmith tracing OFF (LANGSMITH_TRACING=true 로 활성화)")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 02 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 5',
  'code': '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: invoke/stream/batch 호출 시 함께 전달\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 7',
  'code': '# langgraph.json 설정 예시\n'
          'import json\n'
          '\n'
          'langgraph_config = {\n'
          '    "dependencies": ["."],\n'
          '    "graphs": {\n'
          '        "agent": "./agent.py:agent"\n'
          '    },\n'
          '    "env": ".env"\n'
          '}\n'
          '\n'
          'print("langgraph.json 설정 예시:")\n'
          'print(json.dumps(langgraph_config, indent=2))\n'
          'print("\\n실행 방법:")\n'
          'print("  $ langgraph dev")\n'
          'print("  → http://localhost:2024 에서 Studio UI 접근")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 04 (1/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 9',
  'code': 'from langchain_core.language_models import GenericFakeChatModel\n'
          'from langchain.messages import AIMessage\n'
          'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          '\n'
          '@tool\n'
          'def get_capital(country: str) -> str:\n'
          '    """국가의 수도를 반환합니다."""\n'
          '    capitals = {"Korea": "Seoul", "Japan": "Tokyo", "France": "Paris"}\n'
          '    return capitals.get(country, "알 수 없음")\n'
          '\n'
          '# 가짜 모델로 결정론적 테스트\n'
          'fake_model = GenericFakeChatModel(\n'
          '    messages=iter([\n'
          '        AIMessage(content="대한민국의 수도는 서울입니다.")\n'
          '    ])\n'
          ')\n'
          '\n'
          '# 테스트 에이전트\n'
          'test_agent = create_agent(\n'
          '    model=fake_model,\n'
          '    tools=[get_capital],'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 04 (2/2)',
  'lead': '이 코드는 도구 정의와 create_agent 조립을 함께 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 9',
  'code': '    system_prompt="당신은 지리 전문가입니다.",\n'
          ')\n'
          '\n'
          'print("GenericFakeChatModel 테스트:")\n'
          'print("  → 결정론적 응답으로 에이전트 동작을 테스트합니다")\n'
          'print("  → CI/CD 파이프라인에서 API 호출 없이 테스트 가능")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 05 (1/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '10_production.ipynb',
  'note': 'cell 11',
  'code': '# 트라젝토리 테스트 예시\n'
          'def test_agent_trajectory():\n'
          '    """에이전트가 예상된 순서로 도구를 호출하는지 테스트합니다."""\n'
          '    result = test_agent.invoke(\n'
          '        {"messages": [{"role": "user", "content": "대한민국의 수도는 어디인가요?"}]}\n'
          '    )\n'
          '\n'
          '    messages = result["messages"]\n'
          '\n'
          '    # 검증: 메시지가 존재하는지\n'
          '    assert len(messages) > 0, "에이전트가 응답하지 않았습니다"\n'
          '\n'
          '    # 검증: 마지막 메시지가 AI 응답인지\n'
          '    last_msg = messages[-1]\n'
          '    assert hasattr(last_msg, \'content\'), "마지막 메시지에 content가 없습니다"\n'
          '\n'
          '    print("✓ 트라젝토리 테스트 통과")\n'
          '    print(f"  메시지 수: {len(messages)}")\n'
          '    print(f"  최종 응답: {last_msg.content[:100]}")\n'
          '\n'
          'try:\n'
          '    test_agent_trajectory()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 05 (2/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '10_production.ipynb',
  'note': 'cell 11',
  'code': 'except Exception as e:\n    print(f"테스트 참고: {e}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 06',
  'lead': '이 코드는 LangChain 메시지 타입과 대화 문맥 표현을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 12',
  'code': '# agentevals — 트라젝토리 결정론 매칭\n'
          '# 설치: %pip install -U agentevals\n'
          'from agentevals.trajectory.match import create_trajectory_match_evaluator\n'
          'from langchain_core.messages import HumanMessage, AIMessage, ToolMessage\n'
          '\n'
          '# 기대 트라젝토리: get_capital 도구가 한 번 호출되어야 함\n'
          'expected = [\n'
          '    HumanMessage(content="대한민국의 수도?"),\n'
          '    AIMessage(content="", tool_calls=[{"name": "get_capital", "args": {"country": "Korea"}, "id": "1"}]),\n'
          '    ToolMessage(content="Seoul", tool_call_id="1"),\n'
          '    AIMessage(content="서울입니다."),\n'
          ']\n'
          '\n'
          '# 실제 트라젝토리(에이전트 실행 결과를 그대로 전달)\n'
          'actual = expected  # 데모 — 실제로는 agent.invoke(...) 결과의 messages\n'
          '\n'
          'for mode in ("strict", "unordered", "subset", "superset"):\n'
          '    evaluator = create_trajectory_match_evaluator(trajectory_match_mode=mode)\n'
          '    result = evaluator(outputs=actual, reference_outputs=expected)\n'
          '    print(f"  [{mode:9s}] score={result[\'score\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 07 (1/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '10_production.ipynb',
  'note': 'cell 14',
  'code': 'print("Agent Chat UI 설정:")\n'
          'print("=" * 50)\n'
          'print("""\n'
          '# 1. Agent Chat UI 설치 — 정식 CLI\n'
          '$ npx create-agent-chat-app --project-name my-chat-ui\n'
          '\n'
          '# 또는 GitHub 레포를 직접 클론\n'
          '$ git clone https://github.com/langchain-ai/agent-chat-ui.git\n'
          '$ cd agent-chat-ui && npm install && npm run dev\n'
          '\n'
          '# 2. LangGraph 서버 시작\n'
          '$ langgraph dev\n'
          '#   → 로컬 dev 서버: http://127.0.0.1:2024\n'
          '\n'
          '# 3. Agent Chat UI 환경설정\n'
          '#   - Deployment URL: http://127.0.0.1:2024 (로컬) 또는 LangGraph Platform URL\n'
          '#   - Graph ID:       langgraph.json 의 graphs 키 (예: "agent")\n'
          '#   - LangSmith API Key: LangSmith 트레이싱을 같이 보고 싶을 때만\n'
          '""")\n'
          'print("주요 기능:")\n'
          'print("  - 실시간 스트리밍 채팅")\n'
          'print("  - 도구 호출 시각화")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 07 (2/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '10_production.ipynb',
  'note': 'cell 14',
  'code': 'print("  - 대화 분기(branching)")\nprint("  - Human-in-the-loop 승인")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 08',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '10_production.ipynb',
  'note': 'cell 16',
  'code': '%pip install -q langgraph-sdk'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 09 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 17',
  'code': 'print("배포 옵션:")\n'
          'print("=" * 50)\n'
          'print("""\n'
          '# 옵션 1 (권장) — LangGraph Platform\n'
          '#   1) 에이전트 코드를 GitHub repo 에 push\n'
          '#   2) https://smith.langchain.com/deployments → "+ New Deployment"\n'
          '#   3) repo · branch · langgraph.json 경로 · env 를 지정\n'
          '#   4) Deploy 클릭 → Deployment URL + Graph ID 발급\n'
          '#   (과거 안내되던 `langgraph deploy` CLI 한 줄 패턴은 더 이상 정식 경로가 아닙니다.)\n'
          '\n'
          '# 옵션 2 — 자체 Docker\n'
          '$ langgraph build -t my-agent\n'
          '$ docker run -p 2024:2024 my-agent\n'
          '\n'
          '# 옵션 3 (deprecated) — FastAPI/Flask 직접 래핑\n'
          '#   레거시 통합 용도로만 권장. Platform/SDK 가 제공하는 스레드 관리·체크포인트·\n'
          '#   스트리밍 프로토콜을 직접 구현해야 하므로 신규 코드에는 사용하지 마세요.\n'
          'from fastapi import FastAPI\n'
          '\n'
          'app = FastAPI()\n'
          '\n'
          '@app.post("/chat")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 09 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 17',
  'code': 'async def chat(message: str):\n'
          '    result = agent.invoke({"messages": [{"role": "user", "content": message}]})\n'
          '    return {"response": result["messages"][-1].content}\n'
          '""")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 10',
  'lead': '이 코드는 short-term memory를 checkpointer와 thread_id로 유지하는 방식을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 18',
  'code': '# langgraph-sdk 로 배포된 에이전트 스트리밍 호출 (Python)\n'
          '# 실제 실행하려면 위에서 langgraph dev 가 떠 있거나 Platform deployment URL 이 있어야 합니다.\n'
          "example = '''\n"
          'from langgraph_sdk import get_sync_client\n'
          '\n'
          'client = get_sync_client(url="http://127.0.0.1:2024")  # 로컬 dev 서버\n'
          '# Platform 의 경우: get_sync_client(url=DEPLOYMENT_URL, api_key=LANGSMITH_API_KEY)\n'
          '\n'
          'for chunk in client.runs.stream(\n'
          '    None,                       # thread_id — None 이면 새 스레드 생성\n'
          '    "agent",                    # Graph ID = langgraph.json 의 graphs 키\n'
          '    input={"messages": [{"role": "user", "content": "안녕하세요"}]},\n'
          '    stream_mode="updates",\n'
          '):\n'
          '    print(chunk)\n'
          "'''\n"
          'print(example)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 11',
  'lead': '이 코드는 LangChain/LangGraph 스트리밍 이벤트와 UI 연결 방식을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 19',
  'code': '# REST 로 직접 호출 — assistant_id + input + stream_mode 페이로드 형태\n'
          "rest_example = '''\n"
          'curl -X POST http://127.0.0.1:2024/runs/stream \\\\\n'
          '  -H "Content-Type: application/json" \\\\\n'
          "  --data '{\n"
          '    "assistant_id": "agent",\n'
          '    "input": {"messages": [{"role": "user", "content": "안녕하세요"}]},\n'
          '    "stream_mode": "updates"\n'
          "  }'\n"
          '\n'
          '# Platform deployment 에서는 LangSmith API key 를 함께 보냅니다.\n'
          '#   -H "X-Api-Key: $LANGSMITH_API_KEY"\n'
          "'''\n"
          'print(rest_example)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 12',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 21',
  'code': 'print("LangSmith 관측성 설정:")\n'
          'print("=" * 50)\n'
          'print("""\n'
          '# .env (LangChain 1.x 권장 변수명)\n'
          'LANGSMITH_TRACING=true              # 트레이싱 활성화 토글\n'
          'LANGSMITH_API_KEY=lsv2-...          # LangSmith API 키\n'
          'LANGSMITH_PROJECT=default           # 기본 프로젝트명 (생략 시 "default")\n'
          '\n'
          '# 설정 후 에이전트 실행 시 자동으로 트레이스가 기록됩니다.\n'
          '# https://smith.langchain.com 에서 다음을 확인할 수 있습니다:\n'
          '#   - 각 에이전트 호출의 전체 실행 흐름\n'
          '#   - 모델 입·출력, 도구 호출, 토큰 사용량\n'
          '#   - 지연 시간, 에러, 비용 추적\n'
          '""")\n'
          '\n'
          'import os\n'
          'tracing = os.environ.get("LANGSMITH_TRACING", "false")\n'
          'api_key = os.environ.get("LANGSMITH_API_KEY", "")\n'
          'project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          'print(f"현재 트레이싱 상태: {\'활성\' if tracing.lower() == \'true\' else \'비활성\'}")\n'
          'print(f"API 키 설정: {\'✓\' if api_key else \'✗ 미설정\'}")\n'
          'print(f"프로젝트: {project}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 13',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 22',
  'code': '# tracing_context — 코드 블록 단위로 트레이싱을 강제 ON/OFF\n'
          'import langsmith as ls\n'
          '\n'
          "example = '''\n"
          'import langsmith as ls\n'
          '\n'
          '# 환경변수가 꺼져 있어도 이 블록 안에서는 트레이싱이 켜집니다.\n'
          'with ls.tracing_context(enabled=True):\n'
          '    agent.invoke({"messages": [{"role": "user", "content": "안녕하세요"}]})\n'
          '\n'
          '# 반대로 민감 구간만 꺼두기\n'
          'with ls.tracing_context(enabled=False):\n'
          '    agent.invoke({"messages": [{"role": "user", "content": "PII 포함"}]})\n'
          "'''\n"
          'print(example)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 14',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '10_production.ipynb',
  'note': 'cell 23',
  'code': '# 트레이스에 태그·메타데이터 주입 — 대시보드에서 필터·검색 키로 사용\n'
          "example = '''\n"
          'agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "안녕하세요"}]},\n'
          '    config={\n'
          '        "tags": ["production", "v1.0"],\n'
          '        "metadata": {"user_id": "123", "session_id": "456"},\n'
          '    },\n'
          ')\n'
          "'''\n"
          'print(example)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '11_mcp.ipynb',
  'sub': '11_mcp.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/11_mcp.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 01',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'print("환경 준비 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 02 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) — LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제해 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_* 환경변수로 통일 (LangChain 1.x 기준)\n'
          'os.environ.setdefault("LANGSMITH_TRACING", os.environ.get("LANGSMITH_TRACING", "false"))\n'
          'os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          'os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '\n'
          'if os.environ["LANGSMITH_TRACING"].lower() == "true":\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          'else:\n'
          '    print("LangSmith tracing OFF (LANGSMITH_TRACING=true 로 활성화)")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 02 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 5',
  'code': '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 03',
  'lead': '이 코드는 LangChain 메시지 타입과 대화 문맥 표현을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 7',
  'code': '# MCP 베타 어댑터 설치 명령어\n'
          'print("MCP 베타 어댑터 설치:")\n'
          'print("  uv add langchain[mcp] mcp")\n'
          'print()\n'
          'print("주요 진입점:")\n'
          'print("  - from langchain.mcp import MCPAdapter")\n'
          'print("  - async with MCPAdapter(target) as adapter:")\n'
          'print("        tools = await adapter.list_tools()")\n'
          'print("  - target: URL, Path, FastMCP Client, ClientGroup, MCPConfig")\n'
          'print("  - MCPConfig: {\'mcpServers\': {\'name\': {\'command\': ..., \'args\': [...]}}}")\n'
          'print("주의: 도구 호출은 adapter context 안에서 수행해 연결 수명주기를 분명히 합니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 04',
  'lead': '이 코드는 MCP client/server와 LangChain 도구 연결 방식을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 9',
  'code': 'from pathlib import Path\n'
          'import json, tempfile, sys\n'
          'server_path = Path(tempfile.gettempdir()) / "lc_mcp_math_server.py"\n'
          'server_code = """from fastmcp import FastMCP\n'
          'mcp = FastMCP("math")\n'
          '@mcp.tool()\n'
          'def add(a: int, b: int) -> int:\n'
          '    return a + b\n'
          'if __name__ == "__main__":\n'
          '    mcp.run(transport="stdio")\n'
          '"""\n'
          'server_path.write_text(server_code)\n'
          'stdio_config = {"mcpServers": {"math": {"command": sys.executable, "args": [str(server_path)]}}}\n'
          'print("Stdio MCPConfig:")\n'
          'print(json.dumps(stdio_config, indent=2, ensure_ascii=False))\n'
          'print(f"\n'
          '서버 파일: {server_path}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 05',
  'lead': '이 코드는 MCP client/server와 LangChain 도구 연결 방식을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 11',
  'code': 'from langchain.mcp import MCPAdapter\n'
          '\n'
          'async with MCPAdapter(stdio_config) as adapter:\n'
          '    tools = await adapter.list_tools()\n'
          '    add_tool = next(t for t in tools if t.name.endswith("add"))\n'
          '    result = await add_tool.ainvoke({"a": 2, "b": 3})\n'
          'print([t.name for t in tools], result[0]["text"])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 06 (1/3)',
  'lead': '이 코드는 MCP client/server와 LangChain 도구 연결 방식을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 13',
  'code': '# HTTP/streamable-http 전송 설정 예시\n'
          'http_config = {\n'
          '    "mcpServers": {\n'
          '        "weather": {"url": "https://weather-mcp.example.com/mcp"}\n'
          '    }\n'
          '}\n'
          'import json\n'
          'print("HTTP MCPConfig:")\n'
          'print(json.dumps(http_config, indent=2, ensure_ascii=False))\n'
          'print("\n'
          '사용 패턴: async with MCPAdapter(http_config) -> await adapter.list_tools()")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 06 (2/3)',
  'lead': '이 코드는 현재 노트북의 MCP 인증·Elicitation 계약을 그대로 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 15',
  'code': '# FastMCP Client / ClientGroup 기반 인증 구성 예시(객체 생성만 수행)\n'
          'from fastmcp import Client, ClientGroup\n'
          '\n'
          'weather_client = Client(\n'
          '    "https://weather-mcp.example.com/mcp",\n'
          '    auth="Bearer ${WEATHER_MCP_TOKEN}",\n'
          ')\n'
          'calendar_client = Client("https://calendar.example.com/mcp", auth="oauth")\n'
          'auth_group = ClientGroup({"weather": weather_client, "calendar": calendar_client})\n'
          'print(type(auth_group).__name__, list(auth_group.clients))'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 06 (3/3)',
  'lead': '이 코드는 MCP client/server와 LangChain 도구 연결 방식을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 17',
  'code': 'from langchain.agents import create_agent\n'
          'from langchain.mcp import MCPAdapter\n'
          '\n'
          'async def run_math_agent():\n'
          '    async with MCPAdapter(stdio_config) as adapter:\n'
          '        tools = await adapter.list_tools()\n'
          '        agent = create_agent(model=model, tools=tools, system_prompt="MCP math 도구를 사용할 수 있습니다.")\n'
          '        return await agent.ainvoke({"messages": [{"role": "user", "content": "add 도구로 2와 3을 더해 주세요."}]}, '
          'config=lf_config)\n'
          '\n'
          'result = await run_math_agent()\n'
          'print(result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 07',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 19',
  'code': '# 다중 MCP 서버 설정 예시\n'
          'import json, sys\n'
          'multi_server_config = {"mcpServers": {\n'
          '    "math": {"command": sys.executable, "args": [str(server_path)]},\n'
          '    "weather": {"url": "https://weather-mcp.example.com/mcp"},\n'
          '    "database": {"command": "npx", "args": ["-y", "@modelcontextprotocol/server-postgres"], "env": '
          '{"DATABASE_URL": "postgresql://..."}},\n'
          '}}\n'
          'print("다중 MCPConfig:")\n'
          'print(json.dumps(multi_server_config, indent=2, ensure_ascii=False))\n'
          'print("도구 이름은 다중 서버에서 server_tool 형식으로 prefix 됩니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 08',
  'lead': '이 코드는 InputRequiredResult가 만든 interrupt payload를 requests[0].key 기반 answer object로 재개합니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 21',
  'code': '# Elicitation — interrupt payload의 requests[0].key로 재개한다\n'
          "elicit_example = '\\nfrom langgraph.types import Command\\nfirst = await agent.ainvoke(input_state, "
          'config=config, version="v2")\\npayload = first.interrupts[0].value; key = payload.requests[0].key\\nresume '
          '= {"responses": {key: {"action": "accept", "content": {"value": "사용자 입력"}}}}\\nfinal = await '
          'agent.ainvoke(Command(resume=resume), config=config, version="v2")\\n\'\n'
          'print(elicit_example)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 09',
  'lead': '이 코드는 MCP client/server와 LangChain 도구 연결 방식을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 23',
  'code': 'from collections.abc import Callable\n'
          'from langchain.agents.middleware import wrap_tool_call\n'
          'from langchain.messages import ToolMessage\n'
          'from langchain.tools.tool_node import ToolCallRequest\n'
          '\n'
          '@wrap_tool_call\n'
          'def log_mcp_calls(request: ToolCallRequest, handler: Callable[[ToolCallRequest], ToolMessage]) -> '
          'ToolMessage:\n'
          '    mcp_meta = (request.tool.metadata or {}).get("mcp")\n'
          '    if mcp_meta:\n'
          '        print(f"MCP tool call: {request.tool_call[\'name\']}")\n'
          '    return handler(request)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 10',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 24',
  'code': '# 도구 호출 정책은 LangChain middleware에서 처리한다\n'
          "middleware_note = '\\nfrom langchain.agents.middleware import wrap_tool_call\\n@wrap_tool_call\\ndef "
          'guard_mcp_tool(request, handler):\\n    if (request.tool.metadata or {}).get("mcp"):\\n        print(f"MCP '
          'policy check: {request.tool_call[\\\'name\\\']}")\\n    return handler(request)\\n\'\n'
          'print(middleware_note)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 11',
  'lead': '이 코드는 MCP client/server와 LangChain 도구 연결 방식을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 26',
  'code': '# Adapter context 안에서 도구 발견과 agent 호출을 함께 수행\n'
          "stateful_example = '\\nfrom langchain.mcp import MCPAdapter\\n\\nasync def "
          'run_with_adapter_lifetime():\\n    async with MCPAdapter(stdio_config) as adapter:\\n        tools = await '
          'adapter.list_tools()\\n        agent = create_agent(model=model, tools=tools)\\n        return await '
          'agent.ainvoke(\\n            {"messages": [{"role": "user", "content": "2와 3을 더하고 결과를 5와 '
          '곱해주세요."}]},\\n        )\\n\'\n'
          'print(stateful_example)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 12',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 28',
  'code': 'from pathlib import Path\n'
          'import tempfile, sys\n'
          'from langchain.agents import create_agent\n'
          'from langchain.mcp import MCPAdapter\n'
          '\n'
          'fastmcp_path = Path(tempfile.gettempdir()) / "lc_fastmcp_server.py"\n'
          "fastmcp_path.write_text('from fastmcp import FastMCP\n"
          'mcp = FastMCP("my-tools")\n'
          '@mcp.tool()\n'
          'def add(a: int, b: int) -> int:\n'
          '    return a + b\n'
          '@mcp.tool()\n'
          'def multiply(a: int, b: int) -> int:\n'
          '    return a * b\n'
          'if __name__ == "__main__":\n'
          '    mcp.run(transport="stdio")\')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 11_mcp',
  'title': '11_mcp 코드 13',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '11_mcp.ipynb',
  'note': 'cell 28',
  'code': 'async def run_custom_server():\n'
          '    target = {"mcpServers": {"my_tools": {"command": sys.executable, "args": [str(fastmcp_path)]}}}\n'
          '    async with MCPAdapter(target) as adapter:\n'
          '        agent = create_agent(model=model, tools=await adapter.list_tools(), system_prompt="곱셈 도구를 사용하세요.")\n'
          '        return await agent.ainvoke({"messages": [{"role": "user", "content": "multiply 도구로 6과 7을 곱해 '
          '주세요."}]}, config=lf_config)\n'
          'result = await run_custom_server(); print(result["messages"][-1].content)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '12_frontend_streaming.ipynb',
  'sub': '12_frontend_streaming.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/12_frontend_streaming.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 01',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'print("환경 준비 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 02 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) — LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제해 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_* 환경변수로 통일 (LangChain 1.x 기준)\n'
          'os.environ.setdefault("LANGSMITH_TRACING", os.environ.get("LANGSMITH_TRACING", "false"))\n'
          'os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          'os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '\n'
          'if os.environ["LANGSMITH_TRACING"].lower() == "true":\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          'else:\n'
          '    print("LangSmith tracing OFF (LANGSMITH_TRACING=true 로 활성화)")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 02 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 5',
  'code': '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 03',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 7',
  'code': '# .stream()으로 토큰 단위 스트리밍\n'
          'print("스트리밍 응답:")\n'
          'for chunk in model.stream(\n'
          '    "서울의 유명한 관광지 3곳을 알려주세요.",\n'
          '    config=lf_config,\n'
          '):\n'
          '    print(chunk.content, end="", flush=True)\n'
          'print()  # 줄바꿈'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 04',
  'lead': '이 코드는 LangChain/LangGraph 스트리밍 이벤트와 UI 연결 방식을 보여줍니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 9',
  'code': 'import asyncio\n'
          '\n'
          'async def stream_events_demo():\n'
          '    """astream_events()로 이벤트 스트리밍 예시"""\n'
          '    print("이벤트 스트리밍:")\n'
          '    print("-" * 40)\n'
          '    async for event in model.astream_events(\n'
          '        "파이썬의 장점 2가지",\n'
          '        version="v2",\n'
          '    ):\n'
          '        kind = event["event"]\n'
          '        if kind == "on_chat_model_stream":\n'
          '            content = event["data"]["chunk"].content\n'
          '            if content:\n'
          '                print(content, end="", flush=True)\n'
          '        elif kind == "on_chat_model_start":\n'
          '            print(f"[모델 호출 시작]")\n'
          '        elif kind == "on_chat_model_end":\n'
          '            print(f"\\n[모델 호출 완료]")\n'
          '\n'
          'await stream_events_demo()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 05 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 11',
  'code': '# Event Streaming v3 패턴 — 설치 버전이 낮아도 안전하게 읽을 수 있는 예시 출력\n'
          'from importlib.metadata import version\n'
          '\n'
          'print("설치된 langchain:", version("langchain"))\n'
          'print("필요 버전: langchain>=1.3.0")\n'
          '\n'
          "example = r'''\n"
          'from langchain.agents import create_agent\n'
          '\n'
          'def get_weather(city: str) -> str:\n'
          '    """도시 날씨를 조회합니다."""\n'
          '    return f"{city}: 맑음"\n'
          '\n'
          'agent = create_agent(model="openai:gpt-5.4", tools=[get_weather])\n'
          'stream = agent.stream_events(\n'
          '    {"messages": [{"role": "user", "content": "서울 날씨 알려줘"}]},\n'
          '    version="v3",\n'
          ')\n'
          '\n'
          'for message in stream.messages:\n'
          '    for token in message.text:\n'
          '        print(token, end="", flush=True)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 05 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 11',
  'code': "\nfinal_state = stream.output\n'''\nprint(example)"},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 06 (1/2)',
  'lead': '이 코드는 함수에 @tool을 붙여 모델이 호출할 수 있는 도구로 만드는 과정을 보여줍니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 17',
  'code': '# 커스텀 스트리밍 이벤트 — Python writer 패턴\n'
          'print("커스텀 스트리밍 이벤트 패턴 (Python 서버 측):")\n'
          'print("=" * 50)\n'
          'print("""\n'
          'from langchain.tools import tool\n'
          'from langchain.agents.types import ToolRuntime\n'
          '\n'
          '@tool\n'
          'async def analyze_data(\n'
          '    data_source: str, *, config: ToolRuntime\n'
          ') -> str:\n'
          '    \\"\\"\\"데이터를 분석합니다.\\"\\"\\"\n'
          '    if config.writer:\n'
          '        # 진행 상황을 클라이언트에 스트리밍\n'
          '        config.writer({\n'
          '            "type": "progress",\n'
          '            "message": "데이터 로딩 중...",\n'
          '            "progress": 25,\n'
          '        })\n'
          '        # ... 처리 ...\n'
          '        config.writer({\n'
          '            "type": "progress",'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 12_frontend_streaming',
  'title': '12_frontend_streaming 코드 06 (2/2)',
  'lead': '이 코드는 함수에 @tool을 붙여 모델이 호출할 수 있는 도구로 만드는 과정을 보여줍니다.',
  'file': '12_frontend_streaming.ipynb',
  'note': 'cell 17',
  'code': '            "message": "분석 완료!",\n'
          '            "progress": 100,\n'
          '        })\n'
          '    return \'{"result": "분석 완료"}\'\n'
          '""")\n'
          'print("클라이언트(React) 측: onCustomEvent 콜백으로 수신")\n'
          "print('  onCustomEvent: (data) => setProgress(data.progress)')"},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '13_guardrails.ipynb',
  'sub': '13_guardrails.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '02_langchain/13_guardrails.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 01',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'model = ChatOpenAI(\n'
          '    model="gpt-5.4",\n'
          ')\n'
          '\n'
          'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          '\n'
          'print("환경 준비 완료.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_guardrails.ipynb',
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
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 03 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 8',
  'code': '# PII 감지 미들웨어 설정 예시\n'
          'print("PII 감지 미들웨어 설정:")\n'
          'print("=" * 50)\n'
          'print("""\n'
          'from langchain.agents import create_agent\n'
          'from langchain.agents.middleware import PIIMiddleware\n'
          '\n'
          'agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[customer_service_tool, email_tool],\n'
          '    middleware=[\n'
          '        # 이메일 주소를 [REDACTED_EMAIL]로 대체\n'
          '        PIIMiddleware("email",\n'
          '            strategy="redact",\n'
          '            apply_to_input=True,\n'
          '            apply_to_output=False,         # default\n'
          '            apply_to_tool_results=False),  # default\n'
          '\n'
          '        # 신용카드 번호를 부분 마스킹 (****-****-****-1234)\n'
          '        PIIMiddleware("credit_card",\n'
          '            strategy="mask",\n'
          '            apply_to_input=True,'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 03 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 8',
  'code': '            apply_to_tool_results=False),  # default\n'
          '\n'
          '        # API 키 감지 시 차단 (커스텀 정규식)\n'
          '        PIIMiddleware("api_key",\n'
          '            detector=r"sk-[a-zA-Z0-9]{32}",\n'
          '            strategy="block",\n'
          '            apply_to_input=True,\n'
          '            apply_to_tool_results=False),  # default\n'
          '    ],\n'
          ')\n'
          '""")\n'
          'print("내장 PII 타입: email, credit_card, ip, mac_address, url")\n'
          'print("커스텀 감지: detector 파라미터에 정규식 또는 함수 전달")\n'
          'print()\n'
          'print("apply_to_* 파라미터 (기본값 False):")\n'
          'print("  - apply_to_input          사용자 메시지 검사")\n'
          'print("  - apply_to_output         LLM 최종 응답 검사")\n'
          'print("  - apply_to_tool_results   도구 반환값 검사")\n'
          'print("→ 최소 하나는 True로 명시해야 미들웨어가 동작합니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 04 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 10',
  'code': '# Human-in-the-Loop 가드레일 예시\n'
          'print("Human-in-the-Loop 가드레일:")\n'
          'print("=" * 50)\n'
          'print("""\n'
          'from langchain.agents import create_agent\n'
          'from langchain.agents.middleware import HumanInTheLoopMiddleware\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from langgraph.types import Command\n'
          '\n'
          'agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[search_tool, send_email_tool, delete_db_tool],\n'
          '    middleware=[\n'
          '        HumanInTheLoopMiddleware(\n'
          '            interrupt_on={\n'
          '                "send_email": True,       # 승인 필요\n'
          '                "delete_db": True,         # 승인 필요\n'
          '                "search": False,           # 자동 실행\n'
          '            }\n'
          '        ),\n'
          '    ],\n'
          '    checkpointer=InMemorySaver(),'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 04 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 10',
  'code': ')\n'
          '\n'
          'config = {"configurable": {"thread_id": "review-123"}}\n'
          '\n'
          '# 1단계: 에이전트 실행 → send_email에서 중단\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "팀에 이메일 보내"}]},\n'
          '    config=config,\n'
          ')\n'
          '# → 중단됨: send_email 실행 전 승인 대기\n'
          '\n'
          '# 2단계: 승인 후 재개\n'
          'result = agent.invoke(\n'
          '    Command(resume={"decisions": [{"type": "approve"}]}),\n'
          '    config=config,\n'
          ')\n'
          '""")\n'
          'print("핵심: checkpointer가 있어야 중단/재개가 가능합니다.")\n'
          'print("거부 시: {\\"type\\": \\"reject\\"}로 도구 실행을 막을 수 있습니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 05 (1/2)',
  'lead': '이 코드는 미들웨어 훅과 운영 정책 삽입 지점을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 12',
  'code': '# 커스텀 입력 가드레일 — ContentFilterMiddleware 클래스\n'
          'print("커스텀 입력 가드레일 (클래스 방식):")\n'
          'print("=" * 50)\n'
          'print("""\n'
          'from langchain.agents.middleware import (\n'
          '    AgentMiddleware, AgentState, hook_config\n'
          ')\n'
          'from langgraph.runtime import Runtime\n'
          'from typing import Any\n'
          '\n'
          'class ContentFilterMiddleware(AgentMiddleware):\n'
          '    \\"\\"\\"결정론적 가드레일: 금지 키워드가 포함된 요청을 차단합니다.\\"\\"\\"\n'
          '\n'
          '    def __init__(self, banned_keywords: list[str]):\n'
          '        super().__init__()\n'
          '        self.banned_keywords = [kw.lower() for kw in banned_keywords]\n'
          '\n'
          '    @hook_config(can_jump_to=["end"])\n'
          '    def before_agent(\n'
          '        self, state: AgentState, runtime: Runtime\n'
          '    ) -> dict[str, Any] | None:\n'
          '        if not state["messages"]:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 05 (2/2)',
  'lead': '이 코드는 미들웨어 훅과 운영 정책 삽입 지점을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 12',
  'code': '            return None\n'
          '\n'
          '        first_message = state["messages"][0]\n'
          '        if first_message.type != "human":\n'
          '            return None\n'
          '\n'
          '        content = first_message.content.lower()\n'
          '        for keyword in self.banned_keywords:\n'
          '            if keyword in content:\n'
          '                return {\n'
          '                    "messages": [{\n'
          '                        "role": "assistant",\n'
          '                        "content": "부적절한 내용이 포함되어 있습니다."\n'
          '                    }],\n'
          '                    "jump_to": "end"\n'
          '                }\n'
          '        return None\n'
          '""")\n'
          'print("핵심: jump_to=\'end\'로 에이전트 실행을 건너뛰고 즉시 응답합니다.")\n'
          'print("None을 반환하면 다음 단계(에이전트 실행)로 진행합니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 06 (1/3)',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 14',
  'code': '# 커스텀 출력 가드레일 — SafetyGuardrailMiddleware 클래스\n'
          'print("커스텀 출력 가드레일 (클래스 방식):")\n'
          'print("=" * 50)\n'
          'print("""\n'
          'from langchain.agents.middleware import (\n'
          '    AgentMiddleware, AgentState, hook_config\n'
          ')\n'
          'from langgraph.runtime import Runtime\n'
          'from langchain.messages import AIMessage\n'
          'from langchain.chat_models import init_chat_model\n'
          'from typing import Any\n'
          '\n'
          'class SafetyGuardrailMiddleware(AgentMiddleware):\n'
          '    \\"\\"\\"모델 기반 가드레일: LLM으로 응답 안전성을 평가합니다.\\"\\"\\"\n'
          '\n'
          '    def __init__(self):\n'
          '        super().__init__()\n'
          '        self.safety_model = init_chat_model("gpt-5.4-mini")\n'
          '\n'
          '    @hook_config(can_jump_to=["end"])\n'
          '    def after_agent(\n'
          '        self, state: AgentState, runtime: Runtime'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 06 (2/3)',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 14',
  'code': '    ) -> dict[str, Any] | None:\n'
          '        if not state["messages"]:\n'
          '            return None\n'
          '\n'
          '        last_message = state["messages"][-1]\n'
          '        if not isinstance(last_message, AIMessage):\n'
          '            return None\n'
          '\n'
          '        safety_prompt = f\\"\\"\\"Evaluate if this response is safe.\n'
          "        Respond with only 'SAFE' or 'UNSAFE'.\n"
          '\n'
          '        Response: {last_message.content}\\"\\"\\"\n'
          '\n'
          '        result = self.safety_model.invoke(\n'
          '            [{"role": "user", "content": safety_prompt}]\n'
          '        )\n'
          '\n'
          '        if "UNSAFE" in result.content:\n'
          '            last_message.content = (\n'
          '                "안전하지 않은 응답입니다. 다시 질문해주세요."\n'
          '            )\n'
          '        return None'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 06 (3/3)',
  'lead': '이 코드는 채팅 모델 초기화와 메시지 호출 방식을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 14',
  'code': '""")\nprint("핵심: 별도의 경량 모델(gpt-5.4-mini)로 안전성을 평가합니다.")\nprint("UNSAFE 판정 시 응답 내용을 안전한 메시지로 교체합니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 07 (1/3)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 16',
  'code': '# 데코레이터 방식 가드레일\n'
          'print("데코레이터 방식 가드레일:")\n'
          'print("=" * 50)\n'
          'print("""\n'
          'from langchain.agents.middleware import (\n'
          '    before_agent, after_agent, AgentState, hook_config\n'
          ')\n'
          'from langgraph.runtime import Runtime\n'
          'from typing import Any\n'
          '\n'
          'banned_keywords = ["hack", "exploit", "malware"]\n'
          '\n'
          '# 입력 가드레일 — 데코레이터\n'
          '@before_agent(can_jump_to=["end"])\n'
          'def content_filter(\n'
          '    state: AgentState, runtime: Runtime\n'
          ') -> dict[str, Any] | None:\n'
          '    \\"\\"\\"금지 키워드를 차단합니다.\\"\\"\\"\n'
          '    if not state["messages"]:\n'
          '        return None\n'
          '    content = state["messages"][0].content.lower()\n'
          '    for kw in banned_keywords:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 07 (2/3)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 16',
  'code': '        if kw in content:\n'
          '            return {\n'
          '                "messages": [{"role": "assistant",\n'
          '                    "content": "부적절한 요청입니다."}],\n'
          '                "jump_to": "end"\n'
          '            }\n'
          '    return None\n'
          '\n'
          '# 출력 가드레일 — 데코레이터\n'
          '@after_agent(can_jump_to=["end"])\n'
          'def safety_check(\n'
          '    state: AgentState, runtime: Runtime\n'
          ') -> dict[str, Any] | None:\n'
          '    \\"\\"\\"응답에 민감한 내용이 없는지 확인합니다.\\"\\"\\"\n'
          '    last = state["messages"][-1]\n'
          "    if hasattr(last, 'content') and '비밀번호' in last.content:\n"
          '        last.content = "민감한 정보가 포함된 응답입니다."\n'
          '    return None\n'
          '\n'
          '# 에이전트에 적용\n'
          'agent = create_agent(\n'
          '    model="gpt-5.4",'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 07 (3/3)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 16',
  'code': '    tools=[search_tool],\n'
          '    middleware=[content_filter, safety_check],\n'
          ')\n'
          '""")\n'
          'print("데코레이터 방식은 간단한 가드레일에 적합합니다.")\n'
          'print("복잡한 로직(상태 관리, 초기화 등)은 클래스 방식을 사용하세요.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 08 (1/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 18',
  'code': '# 다중 가드레일 조합\n'
          'print("다중 가드레일 조합 (다층 방어):")\n'
          'print("=" * 50)\n'
          'print("""\n'
          'from langchain.agents import create_agent\n'
          'from langchain.agents.middleware import (\n'
          '    PIIMiddleware, HumanInTheLoopMiddleware\n'
          ')\n'
          '\n'
          'agent = create_agent(\n'
          '    model="gpt-5.4",\n'
          '    tools=[search_tool, send_email_tool],\n'
          '    middleware=[\n'
          '        # Layer 1: 결정론적 입력 필터\n'
          '        ContentFilterMiddleware(\n'
          '            banned_keywords=["hack", "exploit"]\n'
          '        ),\n'
          '\n'
          '        # Layer 2: PII 보호 (입력 + 출력)\n'
          '        PIIMiddleware("email",\n'
          '            strategy="redact", apply_to_input=True),\n'
          '        PIIMiddleware("email",'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 기초',
  'meta': 'Code / 13_guardrails',
  'title': '13_guardrails 코드 08 (2/2)',
  'lead': '이 코드는 LangChain create_agent 구성과 실행 호출을 보여줍니다.',
  'file': '13_guardrails.ipynb',
  'note': 'cell 18',
  'code': '            strategy="redact", apply_to_output=True),\n'
          '\n'
          '        # Layer 3: 민감 도구 사람 승인\n'
          '        HumanInTheLoopMiddleware(\n'
          '            interrupt_on={"send_email": True}\n'
          '        ),\n'
          '\n'
          '        # Layer 4: 모델 기반 안전성 검사\n'
          '        SafetyGuardrailMiddleware(),\n'
          '    ],\n'
          ')\n'
          '""")\n'
          'print("실행 순서:")\n'
          'print("  입력 → [ContentFilter] → [PII 입력] → 에이전트 실행")\n'
          'print("       → [HITL 승인] → [PII 출력] → [Safety] → 응답")\n'
          'print()\n'
          'print("팁: 빠른 결정론적 가드레일을 앞에, 느린 모델 기반을 뒤에 배치")'},
 {'type': 'closing',
  'kicker': 'CLOSING',
  'title': 'LangChain은 빠른 조립 도구가 아니라 운영 가능한 에이전트 인터페이스입니다',
  'sub': 'create_agent에서 시작해 메시지·도구·메모리·미들웨어·HITL·MCP·UI·가드레일까지 연결하면, 다음 LangGraph 트랙에서 직접 그래프를 설계할 준비가 끝납니다.'}]
