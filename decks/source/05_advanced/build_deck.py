#!/usr/bin/env python3
"""build_deck.py — Deep Navy HTML 덱 렌더러 (AI 에이전트 개발 고급).

콘텐츠(SLIDES)는 전부 손으로 명시 작성. 이 스크립트는 그것을 template-navy.css
규약의 <section>들로 렌더할 뿐(자동 패턴 생성 아님). 코드 블록은 가벼운 파이썬
구문 하이라이터로 토큰 컬러(.kw/.fn/.str/.num/.cmt)를 입힌다.

content/05_advanced_content.py 의 SLIDES 를 읽어 05_advanced.html 생성.
"""
import html as _html
import re
from pathlib import Path

HERE = Path(__file__).parent

PY_KW = {
    "from", "import", "def", "class", "return", "if", "else", "elif", "for",
    "while", "with", "as", "in", "not", "and", "or", "is", "None", "True",
    "False", "lambda", "try", "except", "finally", "raise", "yield", "await",
    "async", "int", "str", "float", "bool", "dict", "list",
}


def highlight_py(code: str) -> str:
    """아주 가벼운 파이썬 하이라이터. 토큰을 <span class>로 감싼다."""
    out = []
    i = 0
    n = len(code)
    token_re = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
    while i < n:
        c = code[i]
        # 주석
        if c == "#":
            j = code.find("\n", i)
            j = n if j == -1 else j
            out.append(f'<span class="cmt">{_html.escape(code[i:j])}</span>')
            i = j
            continue
        # 문자열 (""" ... """  /  " ... "  /  ' ... ')
        if code.startswith('"""', i) or code.startswith("'''", i):
            q = code[i:i + 3]
            j = code.find(q, i + 3)
            j = n if j == -1 else j + 3
            out.append(f'<span class="str">{_html.escape(code[i:j])}</span>')
            i = j
            continue
        if c in '"\'':
            j = i + 1
            while j < n and code[j] != c:
                if code[j] == "\\":
                    j += 1
                j += 1
            j = min(j + 1, n)
            out.append(f'<span class="str">{_html.escape(code[i:j])}</span>')
            i = j
            continue
        # 숫자
        if c.isdigit():
            m = re.match(r"\d+\.?\d*", code[i:])
            out.append(f'<span class="num">{m.group()}</span>')
            i += m.end()
            continue
        # 식별자/키워드
        m = token_re.match(code, i)
        if m:
            word = m.group()
            end = m.end()
            nxt = code[end] if end < n else ""
            if word in PY_KW:
                out.append(f'<span class="kw">{word}</span>')
            elif nxt == "(" or (word and word[0].isupper()):
                out.append(f'<span class="fn">{word}</span>')
            else:
                out.append(_html.escape(word))
            i = end
            continue
        out.append(_html.escape(c))
        i += 1
    return "".join(out)


def esc(s: str) -> str:
    return _html.escape(s, quote=False)


# ── 레이아웃 렌더러 ──────────────────────────────────────────
def _head(course, meta, title, lead=None):
    h = ['<header class="s-head">',
         f'<div class="s-eyebrow"><span class="s-course">{esc(course)}</span><span class="s-meta">{esc(meta)}</span></div>',
         '<div class="s-rule"></div>',
         f'<h2 class="s-title">{title}</h2>']
    if lead:
        h.append(f'<p class="s-lead">{lead}</p>')
    h.append('</header>')
    return "\n".join(h)


def _foot(brand, num, total):
    return f'<footer class="s-foot"><span>{esc(brand)}</span><span>{num:02d} / {total}</span></footer>'


def render(slide, idx, total, brand):
    t = slide["type"]
    course = slide.get("course", "AI 에이전트 개발 고급")
    meta = slide.get("meta", "")
    if t == "cover":
        meta_html = ""
        if slide.get("credit"):
            meta_html = f'<div class="cover-meta"><div class="row"><span>{esc(slide["credit"])}</span></div></div>'
        elif slide.get("meta_rows"):
            rows = "".join(f'<span><span class="k">{esc(k)}:</span> {esc(v)}</span>' for k, v in slide["meta_rows"])
            meta_html = f'<div class="cover-meta"><div class="rule"></div><div class="row">{rows}</div></div>'
        return f'''<section class="cover" data-label="표지">
  <img class="cover-bg dark" src="assets/cover-bg.png" alt="" />
  <img class="cover-bg light" src="assets/cover-bg-light.png" alt="" />
  <div class="cover-eyebrow">{esc(slide["eyebrow"])}</div>
  <div class="cover-main"><h1>{slide["title"]}</h1><div class="tagline">{esc(slide["tagline"])}</div></div>
  {meta_html}
</section>'''
    if t == "divider":
        sub = f'<p class="div-sub">{esc(slide["sub"])}</p>' if slide.get("sub") else ""
        lab = f'<div class="div-lab">실습 · <span class="mono">{esc(slide["lab"])}</span></div>' if slide.get("lab") else ""
        return f'''<section class="divider" data-label="섹션 구분">
  <div class="div-kicker">{esc(slide["kicker"])}</div>
  <h2 class="div-title">{esc(slide["title"])}</h2>{sub}{lab}
</section>'''
    if t == "closing":
        return f'''<section class="divider" data-label="마무리">
  <div class="div-kicker">{esc(slide.get("kicker","CLOSING"))}</div>
  <h2 class="div-title">{esc(slide["title"])}</h2>
  <p class="div-sub">{esc(slide["sub"])}</p>
</section>'''

    body = ""
    if t == "cards":
        n = len(slide["cards"])
        cls = f"cards c{n}" if n <= 3 else "cards c2"
        cards = "".join(
            f'<div class="card"><h3>{esc(c["h"])}</h3><p>{c["p"]}</p>'
            + (f'<div class="mono">{esc(c["m"])}</div>' if c.get("m") else "")
            + '</div>' for c in slide["cards"])
        body = f'<div class="{cls}">{cards}</div>'
    elif t == "table":
        ths = "".join(f'<th{(" class=\"accent\"" if h.get("accent") else "")}{(f" style=\"width:{h["w"]}\"" if h.get("w") else "")}>{h["t"]}</th>' for h in slide["cols"])
        rows = ""
        for r in slide["rows"]:
            tds = "".join((f'<td class="k">{esc(c)}</td>' if j == 0 else f'<td>{c}</td>') for j, c in enumerate(r))
            rows += f'<tr>{tds}</tr>'
        body = f'<div class="tbl-wrap"><table class="tbl"><thead><tr>{ths}</tr></thead><tbody>{rows}</tbody></table></div>'
    elif t == "code-split":
        pts = "".join(f'<div class="point"><h4>{esc(p["h"])}</h4><p>{p["p"]}</p></div>' for p in slide["points"])

        def _panel(fileN, note, codeS):
            return (f'<div class="code-panel"><div class="code-file">'
                    f'<span class="tab">{esc(fileN)}</span><span>{esc(note)}</span></div>'
                    f'<div class="code-body"><pre>{highlight_py(codeS)}</pre></div></div>')

        if slide.get("codes"):
            panels = "".join(_panel(c.get("file", "code.py"), c.get("note", ""), c["code"]) for c in slide["codes"])
            right = f'<div class="code-stack">{panels}</div>'
        else:
            right = _panel(slide.get("file", "code.py"), slide.get("note", ""), slide["code"])
        body = f'<div class="code-split"><div class="explain">{pts}</div>{right}</div>'
    elif t == "code-only":
        code = highlight_py(slide["code"])
        return f'''<section data-label="실습 (코드)">
{_head(course, meta, slide["title"], slide.get("lead"))}
<div class="s-body code-tall"><div class="code-only"><div class="code-panel">
  <div class="code-file"><span class="tab">{esc(slide.get("file","code.py"))}</span><span>{esc(slide.get("note",""))}</span></div>
  <div class="code-body"><pre>{code}</pre></div></div></div></div>
{_foot(brand, idx, total)}
</section>'''
    elif t == "statement":
        note = f'<p class="note">{slide["note"]}</p>' if slide.get("note") else ""
        body = f'<div class="statement"><p class="big">{slide["big"]}</p>{note}</div>'
    elif t == "dense":
        def render_items(items):
            lis = ""
            for it in items:
                mk = it.get("mk", "")
                kids = render_items(it["kids"]) if it.get("kids") else ""
                lis += f'<li><span class="mk">{mk}</span>{it["t"]}{kids}</li>'
            return f'<ul class="blist">{lis}</ul>' if items and items[0].get("top") else (f'<ul>{lis}</ul>' if lis else "")
        # 상단 그룹은 blist, 하위는 일반 ul
        def render_top(groups):
            lis = ""
            for g in groups:
                kids = render_sub(g.get("kids", []))
                lis += f'<li><span class="mk"></span>{g["t"]}{kids}</li>'
            return f'<ul class="blist">{lis}</ul>'
        def render_sub(items):
            if not items:
                return ""
            lis = ""
            for it in items:
                mk = it.get("mk", "–")
                kids = render_sub(it.get("kids", []))
                lis += f'<li><span class="mk">{mk}</span>{it["t"]}{kids}</li>'
            return f'<ul>{lis}</ul>'
        body = f'<div class="dense">{render_top(slide["groups"])}</div>'
    elif t == "flow":
        nodes = ""
        for k, fn in enumerate(slide["nodes"]):
            hl = " hl" if fn.get("hl") else ""
            nodes += f'<div class="fnode{hl}"><h4>{esc(fn["h"])}</h4><p>{esc(fn["p"])}</p></div>'
            if k < len(slide["nodes"]) - 1:
                nodes += '<div class="flink"></div>'
        notes = "".join(f'<div class="fn-note"><div class="fn-k">{esc(fn["h"])}</div><p>{fn.get("note","")}</p></div>' for fn in slide["nodes"])
        summ = f'<p class="flow-sum">{slide["sum"]}</p>' if slide.get("sum") else ""
        body = f'<div class="flow">{nodes}</div><div class="flow-notes">{notes}</div>{summ}'
    elif t == "figure":
        pts = "".join(f'<div class="point"><h4>{esc(p["h"])}</h4><p>{p["p"]}</p></div>' for p in slide["points"])
        if slide.get("img_src"):
            fig_inner = f'<div class="fig-img has-img"><img src="{esc(slide["img_src"])}" alt=""></div>'
        else:
            fig_inner = f'<div class="fig-img">{esc(slide.get("img","이미지"))}</div>'
        cap = (f'<div class="fig-cap"><span>{esc(slide.get("cap",""))}</span><span>{esc(slide.get("src",""))}</span></div>'
               if (slide.get("cap") or slide.get("src")) else "")
        body = f'<div class="figure-split"><div class="fig">{fig_inner}{cap}</div><div class="fig-exp">{pts}</div></div>'
    elif t == "diagram":
        cap = f'<div class="dgm-cap">{esc(slide.get("cap",""))}</div>' if slide.get("cap") else ""
        body = f'<div class="diagram-full"><img src="{esc(slide["img_src"])}" alt="">{cap}</div>'
    elif t == "layers":
        rows = ""
        for L in slide["layers"]:
            tag = f'<span class="ltag">{esc(L["tag"])}</span>' if L.get("tag") else ""
            mono = f'<div class="lmono">{esc(L["mono"])}</div>' if L.get("mono") else ""
            rows += (f'<div class="layer"><div class="lname">{esc(L["name"])}{tag}</div>'
                     f'<div class="ldesc">{L["desc"]}</div>{mono}</div>')
        body = f'<div class="layers">{rows}</div>'

    center = " center" if t in ("table", "dense", "flow") else ""
    return f'''<section data-label="{esc(slide.get("label","콘텐츠"))}">
{_head(course, meta, slide["title"], slide.get("lead"))}
<div class="s-body{center}">{body}</div>
{_foot(brand, idx, total)}
</section>'''


def build(slides, brand, out_path):
    total = sum(1 for s in slides if s["type"] not in ("cover", "divider", "closing"))
    # 본문 슬라이드만 번호 매김
    sections = []
    speeches = []
    n = 0
    for s in slides:
        if s["type"] in ("cover", "divider", "closing"):
            sec = render(s, 0, total, brand)
        else:
            n += 1
            sec = render(s, n, total, brand)
        speech = s.get("speech", "")
        speeches.append(speech)
        if speech:
            attr = _html.escape(speech, quote=True)
            sec = sec.replace("<section ", f'<section data-speaker-notes="{attr}" ', 1)
        sections.append(sec)
    import json as _json
    (Path(out_path).parent / "_render").mkdir(exist_ok=True)
    (Path(out_path).parent / "_render" / "speeches.json").write_text(
        _json.dumps(speeches, ensure_ascii=False, indent=0), encoding="utf-8")
    head = '''<!doctype html><html lang="ko"><head><meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>AI 에이전트 개발 고급</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css" />
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet" />
<link rel="stylesheet" href="template-navy.css" />
<style>
.code-body pre{margin:0;font-family:var(--font-mono);font-size:19px;line-height:1.55;color:var(--c-base);white-space:pre-wrap;overflow-wrap:anywhere;overflow:hidden;}
.code-tall .code-body pre{font-size:16px;line-height:1.42;white-space:pre-wrap;overflow-wrap:anywhere;}
.code-body .kw{color:var(--c-kw);} .code-body .fn{color:var(--c-fn);}
.code-body .str{color:var(--c-str);} .code-body .num{color:var(--c-num);} .code-body .cmt{color:var(--c-cmt);font-style:italic;}
.code-stack{display:flex;flex-direction:column;gap:26px;flex:1;min-width:0;}
.code-stack .code-panel{flex:none;}
.code-stack .code-body{padding:22px 32px;}
.layers{display:flex;flex-direction:column;gap:18px;margin-top:10px;}
.layer{display:flex;align-items:center;gap:34px;background:var(--panel);border:1px solid var(--line);border-left:4px solid var(--accent);border-radius:8px;padding:30px 38px;}
.layer .lname{font-size:31px;font-weight:750;color:var(--ink);min-width:240px;display:flex;flex-direction:column;gap:7px;}
.layer .lname .ltag{font-size:16px;font-weight:500;color:var(--accent);letter-spacing:0.02em;}
.layer .ldesc{flex:1;font-size:23px;color:var(--sub);line-height:1.45;}
.layer .lmono{font-family:var(--font-mono);font-size:19px;color:var(--faint);white-space:nowrap;}
.s-body.center{justify-content:center;}
.fig-img.has-img{background:#ffffff;border-radius:8px;padding:22px;}
.fig-img.has-img img{max-width:100%;max-height:100%;object-fit:contain;}
.diagram-full{flex:1;min-height:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;}
.diagram-full img{max-width:90%;max-height:600px;object-fit:contain;background:#ffffff;border-radius:10px;padding:26px;}
.diagram-full .dgm-cap{font-family:var(--font-mono);font-size:18px;color:var(--sub);}
.div-lab{margin:34px 0 0;font-size:21px;color:var(--faint);}
.div-lab .mono{font-family:var(--font-mono);color:var(--accent);}
</style></head><body>
<deck-stage width="1920" height="1080">
'''
    tail = '''
</deck-stage>
<script src="deck-stage.js"></script>
</body></html>'''
    Path(out_path).write_text(head + "\n".join(sections) + tail, encoding="utf-8")
    print(f"✅ {out_path} — {len(slides)}슬라이드 (본문 {total})")


if __name__ == "__main__":
    import importlib.util
    spec = importlib.util.spec_from_file_location("content", HERE / "content" / "05_advanced_content.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    # 스피커노트(speech) 병합 — content/05_advanced_speech.py 의 SPEECH 리스트(슬라이드 순서)
    speech_path = HERE / "content" / "05_advanced_speech.py"
    if speech_path.exists():
        sp_spec = importlib.util.spec_from_file_location("speech", speech_path)
        sp = importlib.util.module_from_spec(sp_spec)
        sp_spec.loader.exec_module(sp)
        for i, s in enumerate(mod.SLIDES):
            if i < len(sp.SPEECH) and sp.SPEECH[i]:
                s["speech"] = sp.SPEECH[i]
    build(mod.SLIDES, mod.BRAND, HERE / "05_advanced.html")
