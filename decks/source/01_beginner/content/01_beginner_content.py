# -*- coding: utf-8 -*-
"""01_beginner — 슬라이드 콘텐츠.

Portable editable source normalized on 2026-10-11 so SLIDES is literal final content.
Do not reintroduce runtime overlay functions that hide stale base snippets.
"""
BRAND = '© 주식회사 똑똑한청년들 · 배움 에이아이'
SLIDES = [{'type': 'cover',
  'eyebrow': 'BEGINNER TRACK',
  'title': 'AI 에이전트 개발',
  'tagline': 'LangChain · LangGraph · Deep Agents 미리보기',
  'credit': '주식회사 똑똑한청년들 · 배움 에이아이'},
 {'type': 'divider',
  'kicker': 'PART 01',
  'title': '오리엔테이션',
  'sub': '세 프레임워크가 어떻게 한 계열로 쌓이는지, 이 과정이 어디로 향하는지 먼저 살펴봅니다.'},
 {'type': 'layers',
  'meta': '01 / 오리엔테이션',
  'title': '세 프레임워크는 경쟁이 아니라 한 계열',
  'lead': '위로 갈수록 더 많은 것이 내장되고, 각 층은 <strong>아래 층을 그대로 사용</strong>합니다',
  'layers': [{'name': 'Deep Agents',
              'tag': '올인원 하네스',
              'desc': '파일·서브에이전트·백엔드를 묶는 장기 작업 하네스입니다. 계획 도구는 필요할 때 TodoListMiddleware로 명시합니다.',
              'mono': 'create_deep_agent()'},
             {'name': 'LangGraph',
              'tag': '오케스트레이션',
              'desc': '상태·노드·엣지로 흐름을 직접 설계 — 분기·반복·중단과 재개까지 제어합니다.',
              'mono': 'StateGraph → compile()'},
             {'name': 'LangChain',
              'tag': '인터페이스 레이어 (베이스)',
              'desc': '100+ LLM 프로바이더와 도구를 잇는 토대. 위 두 층이 이 인터페이스를 공유합니다.',
              'mono': 'create_agent()'}]},
 {'type': 'flow',
  'meta': '01 / 오리엔테이션',
  'title': '과정 로드맵 — 노트북 하나씩 쌓아 올립니다',
  'lead': '각 단계는 앞 단계를 이어받고, 마지막에는 직접 만든 에이전트가 손에 남습니다',
  'nodes': [{'h': 'LLM', 'p': '메시지·스트리밍', 'note': '에이전트의 재료인 LLM을 메시지 단위로 다룹니다.'},
            {'h': 'AGENT', 'p': 'LangChain', 'note': '도구를 붙여 스스로 판단하는 에이전트를 만듭니다.', 'hl': True},
            {'h': 'GRAPH', 'p': 'LangGraph', 'note': '흐름을 직접 그려 정밀하게 제어합니다.'},
            {'h': 'DEEP', 'p': '올인원', 'note': '파일·서브에이전트가 붙은 하네스를 쓰고, 긴 작업에는 계획 미들웨어를 추가합니다.'},
            {'h': 'BUILD', 'p': '미니 프로젝트', 'note': '검색과 요약 리서치 에이전트로 종합합니다.'}],
  'sum': '환경 설정에서 출발해 LLM · LangChain · 메모리 · LangGraph · Deep Agents · 비교를 거쳐 미니 프로젝트로 마무리합니다.'},
 {'type': 'statement',
  'meta': '01 / 오리엔테이션',
  'title': '이 과정에서 직접 만드는 것',
  'big': '질문을 주면 <em>웹을 검색하고 한국어로 요약</em>하는 리서치 에이전트를, 마지막 장에서 직접 완성합니다.',
  'note': '입문이지만 개념만 훑고 끝나지 않습니다. 실제로 동작하는 에이전트 한 개가 남습니다. <span class="mono">Deep Agents + Tavily</span>'},
 {'type': 'divider',
  'kicker': 'PART 02',
  'title': '환경 설정',
  'lab': '01_beginner/00_setup.ipynb',
  'sub': '키를 넣고 모델을 띄워 첫 응답을 받아 봅니다. 여기서 만든 환경을 과정 내내 그대로 재사용합니다.'},
 {'type': 'statement',
  'meta': '02 / 환경 설정',
  'title': '에이전트란 무엇인가',
  'big': '에이전트는 LLM이 <em>어떤 도구를 어떤 순서로 쓸지 스스로 판단</em>하고, 실행하고, 결과를 관찰해 작업이 끝날 때까지 반복하는 시스템입니다.',
  'note': '단발 프롬프트-응답과 다른 까닭은, 모델이 행동을 직접 <span class="mono">추론(reason)</span>하고 <span class="mono">실행(act)</span>하기 '
          '때문입니다.'},
 {'type': 'code-split',
  'meta': '02 / 환경 설정',
  'title': '키 발급과 환경 변수 로드',
  'points': [{'h': '필수: OPENAI_API_KEY', 'p': 'LLM 호출에 쓰입니다. <span class="mono">platform.openai.com</span>에서 발급합니다.'},
             {'h': '선택: TAVILY_API_KEY',
              'p': '웹 검색 도구에 쓰이며, 마지막 미니 프로젝트에서만 필요합니다. <span class="mono">tavily.com</span>.'},
             {'h': '.env로 관리합니다',
              'p': '키는 <span class="mono">.env</span>에 두고 <span class="mono">.gitignore</span>에 포함해 절대 커밋하지 않습니다.'}],
  'codes': [{'file': '.env', 'note': '키 보관', 'code': 'OPENAI_API_KEY=sk-...\nTAVILY_API_KEY=tvly-...   # 선택'},
            {'file': '키 로드',
             'note': 'load_dotenv',
             'code': 'from dotenv import load_dotenv\n'
                     'import os\n'
                     '\n'
                     'load_dotenv(override=True)\n'
                     'assert os.environ.get("OPENAI_API_KEY"), \\\n'
                     '    "OPENAI_API_KEY가 설정되지 않았습니다!"'}]},
 {'type': 'code-split',
  'meta': '02 / 환경 설정',
  'title': 'ChatModel로 LLM을 정의합니다',
  'points': [{'h': 'ChatOpenAI', 'p': 'OpenAI 모델을 감싸는 LangChain 챗 모델 클래스입니다. temperature·max_retries 같은 인자를 직접 제어합니다.'},
             {'h': '이 model을 재사용합니다', 'p': '여기서 만든 객체를 이후 모든 노트북에서 그대로 가져다 씁니다.'},
             {'h': 'init_chat_model', 'p': '이름에서 프로바이더를 자동 감지하는 팩토리입니다. 런타임에 모델을 바꿔 끼울 때 편리합니다.'}],
  'codes': [{'file': 'ChatOpenAI',
             'note': '프로바이더 클래스 직접',
             'code': 'from langchain_openai import ChatOpenAI\n'
                     '\n'
                     'model = ChatOpenAI(model="gpt-4.1")\n'
                     'response = model.invoke("안녕하세요!")\n'
                     'print(response.content)'},
            {'file': 'init_chat_model',
             'note': '프로바이더 자동 감지',
             'code': 'from langchain.chat_models import init_chat_model\n'
                     '\n'
                     '# 이름만으로 감지 (또는 "openai:gpt-4.1")\n'
                     'model = init_chat_model("gpt-4.1")'}]},
 {'type': 'dense',
  'meta': '02 / 환경 설정',
  'title': 'model.invoke()는 문자열이 아니라 AIMessage를 돌려줍니다',
  'lead': '응답 객체 안에는 텍스트뿐 아니라 <strong>토큰 사용량과 메타데이터</strong>가 함께 담겨 있습니다',
  'groups': [{'t': '<strong>AIMessage의 주요 속성</strong>입니다',
              'kids': [{'t': '<span class="mono">.content</span> — 모델이 생성한 텍스트 응답입니다'},
                       {'t': '<span class="mono">.usage_metadata</span> — 토큰 수입니다 (input / output / total)'},
                       {'t': '<span class="mono">.response_metadata</span> — 모델 버전·종료 사유 같은 프로바이더 메타입니다'},
                       {'t': '<span class="mono">.tool_calls</span> — 모델이 요청한 도구 호출이 있을 때 담깁니다'}]},
             {'t': '<strong>모델 초기화는 두 가지 방식</strong>이 있습니다',
              'kids': [{'t': '<span class="mono">ChatOpenAI(...)</span> — 프로바이더 클래스를 직접 씁니다. temperature·max_retries '
                             '같은 고유 인자를 제어할 수 있어 이 과정에서 사용합니다'},
                       {'t': '<span class="mono">init_chat_model("...")</span> — 이름에서 프로바이더를 자동 감지하므로 런타임 전환에 '
                             '유용합니다'}]}]},
 {'type': 'table',
  'meta': '02 / 환경 설정',
  'title': '관측성 — 어디서 실패했고 토큰은 얼마나 썼나',
  'lead': '에이전트는 여러 단계를 거치므로 <strong>트레이싱</strong>이 사실상 필수입니다',
  'cols': [{'t': '도구', 'w': '22%'}, {'t': '연동', 'w': '32%'}, {'t': '특징', 'accent': True}],
  'rows': [['LangSmith', '<span class="mono">LANGSMITH_TRACING=true</span>', 'LangChain 1차 지원, 코드 수정 없이 자동 계측'],
           ['Langfuse', '<span class="mono">CallbackHandler</span>를 config로', '오픈소스·셀프호스트, 비용·평가·프롬프트 관리'],
           ['OpenTelemetry', 'OTel 콜렉터로 라우팅', '벤더 중립 — Datadog·Grafana·Jaeger로 전송'],
           ['Traceloop', 'OpenLLMetry SDK', 'OpenTelemetry 기반 자동 계측, 한 줄 초기화'],
           ['Arize Phoenix', '로컬·셀프호스트', '오픈소스, 트레이싱과 평가를 함께']]},
 {'type': 'divider',
  'kicker': 'PART 03',
  'title': 'LLM 기초',
  'lab': '01_beginner/01_llm_basics.ipynb',
  'sub': '현대 LLM은 메시지 시퀀스를 입력으로 받습니다. 이 메시지 시스템 위에 모든 에이전트가 세워집니다.'},
 {'type': 'table',
  'meta': '03 / LLM 기초',
  'title': 'LangChain 메시지 타입 — System · Human · AI · Tool',
  'lead': 'LLM은 문자열이 아니라 <strong>메시지 리스트</strong>를 입력으로 받습니다',
  'cols': [{'t': '역할', 'w': '14%'}, {'t': '클래스', 'w': '26%', 'accent': True}, {'t': '설명'}],
  'rows': [['system', '<span class="mono">SystemMessage</span>', '행동 지침·페르소나·톤·규칙을 정해 초기 동작을 결정합니다'],
           ['human', '<span class="mono">HumanMessage</span>', '사용자 입력입니다. 텍스트뿐 아니라 이미지·오디오·문서도 다룹니다'],
           ['ai', '<span class="mono">AIMessage</span>', '모델 응답입니다. tool_calls·usage_metadata가 함께 담깁니다'],
           ['tool',
            '<span class="mono">ToolMessage</span>',
            '도구 실행 결과를 모델에 돌려줍니다. tool_call_id로 매칭하며 artifact도 담을 수 있습니다'],
           ['스트림', '<span class="mono">AIMessageChunk</span>', '스트리밍 중 생성되는 조각으로, + 연산으로 합쳐져 최종 AIMessage가 됩니다']]},
 {'type': 'code-split',
  'meta': '03 / LLM 기초',
  'file': 'messages.py',
  'note': 'langchain v1',
  'title': '시스템 메시지가 모델의 성격을 결정합니다',
  'points': [{'h': '가장 강력한 다이얼입니다',
              'p': '같은 질문이라도 <span class="mono">SystemMessage</span>를 바꾸면 톤과 관점이 완전히 달라집니다. 프롬프트 엔지니어링의 핵심입니다.'},
             {'h': 'import 경로', 'p': 'LangChain v1에서는 <span class="mono">langchain.messages</span>에서 가져옵니다.'},
             {'h': '형식은 세 가지입니다', 'p': '문자열·메시지 객체·딕셔너리 모두 같은 결과를 냅니다. 딕셔너리는 OpenAI 코드를 옮겨올 때 편리합니다.'}],
  'code': 'from langchain.messages import SystemMessage, HumanMessage\n'
          '\n'
          'messages = [\n'
          '    SystemMessage(content="당신은 유용한 어시스턴트입니다."),\n'
          '    HumanMessage(content="Python이란 무엇인가요?"),\n'
          ']\n'
          'response = model.invoke(messages)\n'
          '\n'
          '# 딕셔너리 형식 — 결과는 동일\n'
          'model.invoke([\n'
          '    {"role": "system", "content": "한국어로 답하세요."},\n'
          '    {"role": "user", "content": "LangChain이란?"},\n'
          '])'},
 {'type': 'code-split',
  'meta': '03 / LLM 기초',
  'file': 'stream.py',
  'note': '응답성 vs 처리량',
  'title': '호출은 세 가지 — invoke · stream · batch',
  'points': [{'h': 'invoke', 'p': '동기 호출로, 전체 응답을 한 번에 받습니다.'},
             {'h': 'stream',
              'p': '토큰이 생성되는 대로 <span class="mono">AIMessageChunk</span>를 순차로 받습니다. 단일 요청의 응답성을 높여 줍니다.'},
             {'h': 'batch', 'p': '여러 입력을 <strong>병렬</strong>로 처리합니다. 루프로 invoke를 반복할 때보다 훨씬 빠릅니다.'}],
  'code': '# 스트리밍 — 토큰 단위 실시간 출력\n'
          'for chunk in model.stream("우주에 대한 사실 2가지?"):\n'
          '    print(chunk.content, end="", flush=True)\n'
          '\n'
          '# 배치 — 여러 질문을 병렬로\n'
          'model.batch(["2+2는?", "3*5는?"])'},
 {'type': 'divider',
  'kicker': 'PART 04',
  'title': '첫 에이전트 — LangChain',
  'lab': '01_beginner/02_langchain_basics.ipynb',
  'sub': 'create_agent() 한 줄로 ReAct 루프를 도는 에이전트를 만듭니다. 도구는 @tool로 정의합니다.'},
 {'type': 'figure',
  'meta': '04 / 첫 에이전트',
  'title': 'ReAct 루프 — 생각하고 행동하기를 반복합니다',
  'lead': '모델이 도구 호출이 필요한지 판단하고, 실행 결과를 다시 받아 이어 갑니다',
  'img_src': 'assets/diagrams/react_loop.png',
  'cap': 'ReAct loop',
  'points': [{'h': '판단', 'p': '사용자 입력을 받아, 도구를 호출할지 바로 답할지 모델이 추론합니다.'},
             {'h': '도구 실행', 'p': '필요하면 tool_calls를 프레임워크가 실행해 <span class="mono">ToolMessage</span>를 만듭니다.'},
             {'h': '관찰·반복', 'p': '결과를 보고 다시 판단하며, 텍스트로 답하거나 최대 횟수에 도달할 때까지 반복합니다.'}]},
 {'type': 'code-split',
  'meta': '04 / 첫 에이전트',
  'file': 'tools.py',
  'note': '@tool',
  'title': '도구 만들기 — docstring이 가장 중요합니다',
  'points': [{'h': '@tool 데코레이터', 'p': '일반 함수를 에이전트 도구로 바꿔 줍니다. <span class="mono">langchain.tools</span>에서 가져옵니다.'},
             {'h': '타입 힌트가 스키마입니다', 'p': '인자 타입이 입력 스키마를 정의합니다. <span class="mono">Literal</span>로 허용 값을 제한합니다.'},
             {'h': 'docstring이 설명입니다',
              'p': '모델은 docstring을 읽고 <strong>언제 이 도구를 쓸지</strong> 판단합니다. 동료에게 설명하듯 명확히 적습니다.'}],
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
          '    return a * b'},
 {'type': 'code-split',
  'meta': '04 / 첫 에이전트',
  'file': 'first_agent.py',
  'note': 'create_agent',
  'title': 'create_agent — 모델·도구·프롬프트를 묶습니다',
  'points': [{'h': '구성요소는 셋입니다', 'p': '모델(판단)·도구(행동)·시스템 프롬프트(지침)입니다. 프롬프트가 구체적일수록 유용합니다.'},
             {'h': '입력과 출력',
              'p': '입력은 <span class="mono">messages</span> 리스트이고, 답은 <span '
                   'class="mono">result["messages"][-1].content</span>에서 꺼냅니다.'},
             {'h': '예약어에 주의합니다',
              'p': '<span class="mono">config</span>·<span class="mono">runtime</span>은 내부 예약어라 도구 인자 이름으로 쓰지 않습니다.'}],
  'code': 'from langchain.agents import create_agent\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model,\n'
          '    tools=[add, multiply],\n'
          '    system_prompt="당신은 수학 도우미입니다.",\n'
          ')\n'
          'result = agent.invoke(\n'
          '    {"messages": [{"role": "user", "content": "15 + 27은?"}]}\n'
          ')\n'
          'print(result["messages"][-1].content)'},
 {'type': 'divider',
  'kicker': 'PART 05',
  'title': '멀티턴 메모리',
  'lab': '01_beginner/03_langchain_memory.ipynb',
  'sub': '기본 에이전트는 매 호출마다 모든 것을 잊습니다. 체크포인터로 대화를 기억하게 만듭니다.'},
 {'type': 'statement',
  'meta': '05 / 메모리',
  'title': '메모리 없는 에이전트의 한계',
  'big': '“내 이름은 철수야” 다음에 “내 이름이 뭐야?”라고 물으면 <em>답하지 못합니다.</em>',
  'note': '<span class="mono">invoke()</span>는 입력을 처리해 돌려준 뒤 아무것도 보존하지 않기 때문입니다. 매번 새 대화로 취급합니다.'},
 {'type': 'code-split',
  'meta': '05 / 메모리',
  'file': 'memory.py',
  'note': 'InMemorySaver',
  'title': 'checkpointer와 thread_id로 대화를 기억합니다',
  'points': [{'h': 'InMemorySaver',
              'p': '메시지 히스토리를 포함한 그래프 전체 상태를 저장하는 체크포인터입니다. <span class="mono">langgraph.checkpoint.memory</span>에서 '
                   '가져옵니다.'},
             {'h': 'thread_id의 의미', 'p': '같은 <span class="mono">thread_id</span>는 연속된 대화이고, 다른 값은 완전히 별개의 대화입니다.'},
             {'h': '동작 방식', 'p': '호출하면 이전 상태를 불러오고, 새 메시지를 더하고, 실행한 뒤, 상태를 다시 저장합니다.'}],
  'code': 'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'agent = create_agent(\n'
          '    model=model, tools=[add],\n'
          '    checkpointer=InMemorySaver(),\n'
          ')\n'
          'config = {"configurable": {"thread_id": "session-1"}}\n'
          '\n'
          'agent.invoke({"messages": [{"role": "user",\n'
          '    "content": "7 + 8은?"}]}, config=config)\n'
          'agent.invoke({"messages": [{"role": "user",\n'
          '    "content": "그 결과에 2를 곱하세요."}]}, config=config)'},
 {'type': 'dense',
  'meta': '05 / 메모리',
  'title': '단기에서 영속으로, 그리고 긴 대화 관리',
  'lead': 'InMemorySaver는 프로세스가 끝나면 사라지므로, 프로덕션에서는 영속 체크포인터를 씁니다',
  'groups': [{'t': '<strong>영속 체크포인터</strong> — API는 같고 한 줄만 교체하면 됩니다',
              'kids': [{'t': '<span class="mono">PostgresSaver(connection_string)</span> — PostgreSQL에 저장합니다'},
                       {'t': '<span class="mono">SqliteSaver</span> — SQLite에 저장합니다. 이전 체크포인트를 재생하는 타임 트래블도 가능합니다'}]},
             {'t': '<strong>긴 대화 관리 전략</strong> — 유한한 컨텍스트 윈도우에 대응합니다',
              'kids': [{'t': '트리밍 — 최근 N개 메시지만 남깁니다. 단순하지만 초기 맥락을 잃습니다'},
                       {'t': '요약 — 오래된 메시지를 하나의 요약으로 압축합니다. 핵심은 지키면서 토큰을 아낍니다'},
                       {'t': '삭제 — 중간 도구 호출처럼 노이즈가 되는 메시지를 제거합니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 06',
  'title': 'LangGraph 워크플로',
  'lab': '01_beginner/04_langgraph_basics.ipynb',
  'sub': 'create_agent가 감춘 흐름을 직접 그립니다. 분기·반복·중단과 재개가 필요할 때 그래프로 모델링합니다.'},
 {'type': 'statement',
  'meta': '06 / LangGraph',
  'title': '왜 create_agent를 넘어가나',
  'big': '실제 앱에는 <em>조건 분기 · 병렬 실행 · 인간 승인 · 오류 복구</em>가 필요합니다. 단순 ReAct 루프만으로는 부족합니다.',
  'note': 'LangGraph는 이를 <strong>방향 그래프</strong>로 모델링합니다. 노드는 처리 단계, 엣지는 흐름이며, 중단과 재개가 가능한 내구적 실행을 얻습니다.'},
 {'type': 'figure',
  'meta': '06 / LangGraph',
  'title': '구성요소는 셋 — 상태 · 노드 · 엣지',
  'lead': '<strong>노드는 무엇을 하고, 엣지는 다음에 어디로 갈지를 정합니다</strong>',
  'img_src': 'assets/diagrams/stategraph_structure.png',
  'cap': 'StateGraph 구조',
  'points': [{'h': 'State', 'p': '노드들이 공유하는 데이터 구조(TypedDict)로, 현재 스냅샷을 담습니다.'},
             {'h': 'Node', 'p': '상태를 받아 업데이트를 돌려주는 함수 — 실제 작업을 수행합니다.'},
             {'h': 'Edge', 'p': '다음 노드를 결정해 흐름을 지시하며, 조건부 분기도 가능합니다.'}]},
 {'type': 'code-split',
  'meta': '06 / LangGraph',
  'file': 'graph.py',
  'note': 'StateGraph',
  'title': '기본 흐름 — 정의에서 실행까지 다섯 단계',
  'points': [{'h': '다섯 단계입니다',
              'p': '<span class="mono">StateGraph → add_node → add_edge → compile → invoke</span> 순서입니다.'},
             {'h': '반드시 compile()', 'p': '컴파일할 때 도달할 수 없는 노드나 누락된 엣지 같은 구조적 오류를 검증합니다.'},
             {'h': '업데이트만 돌려줍니다', 'p': '노드는 전체 상태가 아니라 <strong>변경된 키만</strong> 담은 dict를 반환합니다.'}],
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from typing import TypedDict\n'
          '\n'
          'class State(TypedDict):\n'
          '    text: str\n'
          '    word_count: int\n'
          '\n'
          'def count_words(state: State) -> dict:\n'
          '    return {"word_count": len(state["text"].split())}\n'
          '\n'
          'builder = StateGraph(State)\n'
          'builder.add_node("counter", count_words)\n'
          'builder.add_edge(START, "counter")\n'
          'builder.add_edge("counter", END)\n'
          'graph = builder.compile()'},
 {'type': 'code-split',
  'meta': '06 / LangGraph',
  'file': 'llm_node.py',
  'note': 'MessagesState',
  'title': 'LLM을 노드로 — MessagesState와 리듀서',
  'points': [{'h': 'MessagesState',
              'p': '<span class="mono">messages</span> 단일 키와 <span class="mono">add_messages</span> 리듀서가 내장된 사전 정의 '
                   '상태입니다.'},
             {'h': 'add_messages 리듀서', 'p': '메시지 ID를 추적해 중복 없이 누적하고, JSON을 Message 객체로 자동 역직렬화합니다.'},
             {'h': '노드의 정체', 'p': '상태를 받아 업데이트를 돌려주는 일반 함수입니다. LangGraph가 RunnableLambda로 변환합니다.'}],
  'code': 'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          'from langchain.messages import HumanMessage\n'
          '\n'
          'def chatbot(state: MessagesState) -> dict:\n'
          '    return {"messages": [model.invoke(state["messages"])]}\n'
          '\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node("chatbot", chatbot)\n'
          'builder.add_edge(START, "chatbot")\n'
          'builder.add_edge("chatbot", END)\n'
          'graph = builder.compile()\n'
          '\n'
          'graph.invoke({"messages": [HumanMessage(content="2+2는?")]})'},
 {'type': 'divider',
  'kicker': 'PART 07',
  'title': 'Deep Agents 올인원',
  'lab': '01_beginner/05_deep_agents_basics.ipynb',
  'sub': 'LangGraph 위에 파일·서브에이전트·백엔드를 얹은 장기 작업 하네스입니다. 계획은 필요할 때 TodoListMiddleware로 추가합니다.'},
 {'type': 'diagram',
  'meta': '07 / Deep Agents',
  'title': '하네스의 기본 기능과 선택 미들웨어',
  'lead': 'Deep Agents 0.7 기준으로 파일·백엔드·서브에이전트는 하네스의 중심이고, todo 계획은 <span class="mono">TodoListMiddleware</span>를 붙여 '
          '활성화합니다',
  'img_src': 'assets/diagrams/deepagents_architecture.png',
  'cap': 'Deep Agent 내부 구조 · LangGraph 실행 엔진 위에 구축'},
 {'type': 'code-split',
  'meta': '07 / Deep Agents',
  'file': 'deep_agent.py',
  'note': 'deepagents',
  'title': 'create_deep_agent — 도구는 순수 함수로 넘깁니다',
  'points': [{'h': '한 줄로 만듭니다',
              'p': '모델만 넘기면 LangGraph <span class="mono">CompiledStateGraph</span>가 만들어집니다. 긴 작업 계획은 <span '
                   'class="mono">TodoListMiddleware()</span>를 추가합니다.'},
             {'h': '@tool이 필요 없습니다',
              'p': 'Deep Agents는 <strong>순수 함수</strong>를 그대로 도구로 받습니다. docstring과 타입 힌트가 스키마가 됩니다. LangChain은 @tool이 '
                   '필요했습니다.'},
             {'h': '대체가 아니라 추가입니다', 'p': '<span class="mono">tools</span>는 빌트인 도구에 더해집니다. 커스텀 도구와 빌트인 도구를 함께 씁니다.'}],
  'code': 'from deepagents import create_deep_agent\n'
          'from langchain.agents.middleware import TodoListMiddleware\n'
          '\n'
          'def greet(name: str) -> str:\n'
          '    """이름으로 인사합니다."""\n'
          '    return f"안녕하세요, {name}님!"\n'
          '\n'
          'agent = create_deep_agent(\n'
          '    model=model,\n'
          '    tools=[greet],\n'
          '    middleware=[TodoListMiddleware()],\n'
          '    system_prompt="자기소개를 하면 greet 도구를 사용하세요.",\n'
          ')\n'
          'agent.invoke({"messages": [{"role": "user",\n'
          '    "content": "제 이름은 앨리스입니다."}]})'},
 {'type': 'divider',
  'kicker': 'PART 08',
  'title': '세 프레임워크 비교',
  'lab': '01_beginner/06_comparison.ipynb',
  'sub': '지금 내 문제에 필요한 것이 빠른 시작인지, 정밀한 제어인지, 작업형 하네스인지로 고릅니다.'},
 {'type': 'table',
  'meta': '08 / 비교',
  'title': '프레임워크 특성 한눈 비교',
  'lead': '추상화 수준은 앞에서 봤으니, 여기선 <strong>실무 특성</strong>으로 가릅니다',
  'cols': [{'t': '항목', 'w': '20%'},
           {'t': 'LangChain', 'accent': True},
           {'t': 'LangGraph', 'accent': True},
           {'t': 'Deep Agents', 'accent': True}],
  'rows': [['모델 지원', '모델 무관 (100+)', 'LangChain 공유', 'LangChain 공유'],
           ['상태 관리', '메모리 기반', '체크포인터 · 타임트래블', 'LangGraph 체크포인터'],
           ['샌드박스', '기본 없음', '기본 없음', '샌드박스 실행 지원'],
           ['관측성', 'LangSmith 연동', 'LangSmith 네이티브', 'LangSmith 지원'],
           ['라이선스', 'MIT', 'MIT', 'MIT']]},
 {'type': 'dense',
  'meta': '08 / 비교',
  'title': '이럴 때 씁니다 — 의사결정 기준',
  'lead': '먼저 물어볼 것은 <strong>“어디까지 직접 제어하고 싶은가”</strong>입니다',
  'groups': [{'t': '<strong>LangChain</strong> — 빠른 시작과 단순한 도구 호출에 적합합니다',
              'kids': [{'t': '주문 조회와 FAQ 챗봇 같은 단순 워크플로라면 20줄 미만으로 끝납니다'},
                       {'t': '상태 전이·병렬·조건부 그래프가 핵심이라면 과합니다', 'mk': '✕'}]},
             {'t': '<strong>LangGraph</strong> — 세밀한 제어와 장기 실행에 강합니다',
              'kids': [{'t': '분류 → 라우팅 → 검토 → 인간 승인처럼 분기와 HITL이 있는 파이프라인에 맞습니다'},
                       {'t': '단순 ReAct 루프만 필요하다면 과합니다', 'mk': '✕'}]},
             {'t': '<strong>Deep Agents</strong> — 파일·서브에이전트·장기 작업 하네스가 필요할 때 씁니다',
              'kids': [{'t': '웹 검색·문서 읽기·노트 작성·보고서처럼 중간 산출물이 필요한 자율 작업에 어울립니다'},
                       {'t': '짧고 단순한 도구 호출이라면 과합니다', 'mk': '✕'}]}]},
 {'type': 'code-only',
  'meta': '08 / 비교',
  'file': 'three_ways.py',
  'note': '같은 질문 "3+4?"',
  'title': '같은 질문, 세 가지 방식',
  'lead': '코드량과 제어 범위의 차이가 한눈에 보입니다. 배타적 선택이 아니라 작업에 맞춰 고르고 섞습니다',
  'code': '# LangChain — 한 줄로 에이전트\n'
          'from langchain.agents import create_agent\n'
          'agent = create_agent(model=model, tools=[add])\n'
          'agent.invoke({"messages": [{"role": "user", "content": "3+4?"}]})\n'
          '\n'
          '# LangGraph — 흐름을 직접 그린다\n'
          'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          'def chatbot(state):\n'
          '    return {"messages": [model.invoke(state["messages"])]}\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node("chat", chatbot)\n'
          'builder.add_edge(START, "chat"); builder.add_edge("chat", END)\n'
          'graph = builder.compile()\n'
          'graph.invoke({"messages": [{"role": "user", "content": "3+4?"}]})\n'
          '\n'
          '# Deep Agents — 장기 작업 하네스\n'
          'from deepagents import create_deep_agent\n'
          'agent = create_deep_agent(model=model)\n'
          'agent.invoke({"messages": [{"role": "user", "content": "3+4?"}]})'},
 {'type': 'divider',
  'kicker': 'PART 09',
  'title': '미니 프로젝트',
  'lab': '01_beginner/07_mini_project.ipynb',
  'sub': '앞의 여덟 파트를 종합해 웹 검색과 한국어 요약을 수행하는 리서치 에이전트를 만듭니다.'},
 {'type': 'code-split',
  'meta': '09 / 미니 프로젝트',
  'file': 'search_tool.py',
  'note': 'Tavily',
  'title': '검색 도구 정의 — Tavily',
  'points': [{'h': 'docstring과 타입 힌트', 'p': '에이전트가 언제 어떻게 쓸지 판단하는 근거입니다. Args 설명까지 적으면 인자를 정확히 채웁니다.'},
             {'h': 'Literal로 제한합니다', 'p': '<span class="mono">topic</span>처럼 허용 값을 타입으로 강제하고, 합리적인 기본값을 둡니다.'},
             {'h': 'import',
              'p': '<span class="mono">from tavily import TavilyClient</span>로 가져오며, 키는 tavily.com에서 무료로 발급합니다.'}],
  'code': 'from typing import Literal\n'
          'from tavily import TavilyClient\n'
          '\n'
          'tavily = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])\n'
          '\n'
          'def internet_search(\n'
          '    query: str,\n'
          '    max_results: int = 3,\n'
          '    topic: Literal["general", "news"] = "general",\n'
          ') -> dict:\n'
          '    """인터넷에서 정보를 검색합니다.\n'
          '\n'
          '    Args:\n'
          '        query: 검색 쿼리\n'
          '        max_results: 최대 결과 수\n'
          '        topic: 검색 주제 카테고리\n'
          '    """\n'
          '    return tavily.search(query, max_results=max_results, topic=topic)'},
 {'type': 'code-split',
  'meta': '09 / 미니 프로젝트',
  'file': 'research_agent.py',
  'note': 'Deep Agents',
  'title': 'Deep Agents 리서치 에이전트',
  'points': [{'h': '검색 도구와 프롬프트만',
              'p': '검색 도구와 지침을 넘기고, 긴 리서치처럼 단계 관리가 필요하면 <span class="mono">TodoListMiddleware</span>를 함께 붙입니다.'},
             {'h': '프롬프트가 행동을 좌우합니다', 'p': '“3개 핵심 포인트로 정리”처럼 출력 형식을 구체화하면 결과가 한결 일관됩니다.'},
             {'h': '트레이드오프', 'p': '더 철저하지만 토큰을 더 씁니다. 단순한 질문이라면 LangChain이 더 빠르고 저렴합니다.'}],
  'code': 'from deepagents import create_deep_agent\n'
          'from langchain.agents.middleware import TodoListMiddleware\n'
          '\n'
          'research_agent = create_deep_agent(\n'
          '    model=model,\n'
          '    tools=[internet_search],\n'
          '    middleware=[TodoListMiddleware()],\n'
          '    system_prompt=(\n'
          '        "당신은 전문 리서처입니다. "\n'
          '        "웹을 검색한 후 결과를 한국어로 요약하세요."\n'
          '    ),\n'
          ')\n'
          '\n'
          '# 스트리밍으로 도구 호출 → 요약 과정을 관찰\n'
          'for chunk in research_agent.stream(\n'
          '    {"messages": [{"role": "user",\n'
          '        "content": "LangChain v1의 주요 변경사항을 요약해 주세요."}]},\n'
          '    stream_mode="updates",\n'
          '):\n'
          '    print(chunk)'},
 {'type': 'dense',
  'meta': '09 / 미니 프로젝트',
  'title': 'LangChain 버전과 비교, 그리고 다음 단계',
  'lead': '같은 검색을 <span class="mono">@tool</span>과 <span class="mono">create_agent</span>로도 만들어 성격 차이를 봅니다',
  'groups': [{'t': '<strong>두 방식의 차이</strong>입니다',
              'kids': [{'t': 'LangChain은 검색을 호출한 뒤 바로 요약합니다. 계획이나 파일 관리는 없습니다'},
                       {'t': 'Deep Agents는 파일 작업과 서브에이전트 경계를 제공하고, todo 계획은 명시한 미들웨어가 담당합니다'}]},
             {'t': '<strong>입문을 정리하면</strong> — LLM → 도구 → 에이전트 → 워크플로 → 올인원 → 직접 만든 리서치 에이전트로 이어졌습니다'},
             {'t': '<strong>다음은 중급</strong>입니다 — 미들웨어 · MCP · HITL · RAG · 멀티에이전트를 다룹니다'}]},
 {'type': 'closing',
  'kicker': 'CLOSING',
  'title': '작은 조각들이 하나로 이어졌습니다',
  'sub': 'LLM 한 번의 호출에서 출발해 스스로 검색하고 요약하는 에이전트까지, 같은 인터페이스 위에서 쌓아 올렸습니다.'}]
