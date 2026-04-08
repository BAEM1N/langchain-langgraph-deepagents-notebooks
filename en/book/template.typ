// template.typ — BAEUM.AI clean white book template
#import "metadata.typ": *

// ─── Page Setup ───────────────────────────────────────────────
#let book-setup(body) = {
  set document(
    title: book-full-title,
    author: book-author,
  )

  set page(
    paper: "a4",
    margin: (top: 28mm, bottom: 32mm, inside: 28mm, outside: 22mm),
    header: context {
      let page-num = counter(page).get().first()
      if page-num > 4 {
        set text(size: 8pt, fill: luma(160), font: font-body)
        let elems = query(heading.where(level: 1).before(here()))
        if elems.len() > 0 {
          let current-heading = elems.last().body
          if calc.odd(page-num) {
            h(1fr)
            text(tracking: 0.5pt, upper(current-heading))
          } else {
            text(tracking: 0.5pt, upper(book-title))
            h(1fr)
          }
        }
        v(-2pt)
        line(length: 100%, stroke: 0.3pt + luma(230))
      }
    },
    footer: context {
      let page-num = counter(page).get().first()
      if page-num > 4 {
        set text(size: 8.5pt, fill: luma(150), font: font-body)
        if calc.odd(page-num) {
          h(1fr)
          str(page-num)
        } else {
          str(page-num)
          h(1fr)
        }
      }
    },
  )

  // ─── Typography ─────────────────────────────────────────────
  set text(
    font: font-body,
    size: 10pt,
    weight: "regular",
    lang: "en",
    fill: rgb("#1a1a1a"),
  )
  set par(leading: 0.78em, first-line-indent: 0pt, spacing: 1.2em)
  set heading(numbering: none)
  set list(indent: 1em, body-indent: 0.5em, marker: text(fill: luma(100))[--])
  set enum(indent: 1em, body-indent: 0.5em)

  // ─── Heading Styles ─────────────────────────────────────────
  // Level 1: Part titles + Chapter titles (both hidden, rendered by part-page/chapter)
  show heading.where(level: 1): it => {
    hide[#it]
  }

  // Level 2: Main section (== Title)
  show heading.where(level: 2): it => {
    v(18pt)
    block(below: 8pt)[
      #text(size: 13.5pt, weight: "bold", fill: color-secondary, tracking: 0.2pt)[#it.body]
      #v(3pt)
      #line(length: 30pt, stroke: 1.5pt + luma(200))
    ]
  }

  // Level 3: Subsection (=== Title)
  show heading.where(level: 3): it => {
    v(12pt)
    block(below: 6pt)[
      #text(size: 12pt, weight: "bold", fill: color-secondary.lighten(15%))[#it.body]
    ]
  }

  // Level 4: Minor heading (==== Title)
  show heading.where(level: 4): it => {
    v(8pt)
    block(below: 4pt)[
      #text(size: 10.5pt, weight: "bold", fill: luma(60))[#it.body]
    ]
  }

  // ─── Inline Code ──────────────────────────────────────────
  show raw.where(block: false): it => {
    box(
      fill: rgb("#F5F5F5"),
      inset: (x: 4pt, y: 0pt),
      outset: (y: 3pt),
      radius: 2pt,
    )[#text(font: font-code, size: 0.85em, fill: rgb("#37474F"))[#it]]
  }

  // ─── Link styling ────────────────────────────────────────
  show link: it => {
    text(fill: color-primary-dark)[#it]
  }

  // ─── Table styling ───────────────────────────────────────
  set table(
    stroke: none,
  )
  show table: set align(center)
  show figure: set align(center)

  body
}

// ─── Learning Objectives Header (not a heading, excluded from TOC) ──
#let learning-header() = {
  v(18pt)
  block(below: 8pt)[
    #text(size: 13.5pt, weight: "bold", fill: color-secondary, tracking: 0.2pt)[Learning Objectives]
    #v(3pt)
    #line(length: 30pt, stroke: 1.5pt + luma(200))
  ]
}

// ─── Chapter Heading ──────────────────────────────────────────
#let chapter(number, title, subtitle: none) = {
  pagebreak(weak: true)

  // Hidden heading for TOC entry
  heading(level: 1)[#{str(number) + ". " + title}]

  v(6pt)

  // Visual chapter number + title
  grid(
    columns: (auto, 1fr),
    column-gutter: 14pt,
    align: (right + bottom, left + bottom),
    text(
      size: 48pt,
      weight: "bold",
      fill: luma(220),
      font: font-body,
    )[#if number < 10 [0#number] else [#number]],
    {
      text(size: 22pt, weight: "bold", fill: color-secondary, tracking: 0.3pt)[#title]
      if subtitle != none {
        v(2pt)
        text(size: 11pt, fill: luma(130), style: "italic")[#subtitle]
      }
    },
  )
  v(8pt)
  line(length: 100%, stroke: 0.5pt + luma(220))
  v(16pt)
}

// ─── Part Page ────────────────────────────────────────────────
#let part-page(number, title, subtitle: none, chapters: none) = {
  pagebreak(weak: true)
  page(
    header: none,
    footer: none,
    fill: color-part-bg,
    margin: (top: 28mm, bottom: 32mm, inside: 28mm, outside: 22mm),
  )[
    #v(1fr)
    #align(center)[
      #text(size: 11pt, fill: luma(160), tracking: 6pt, weight: "medium", font: font-body)[PART]
      #v(10pt)
      #text(size: 56pt, weight: "bold", fill: color-primary-dark, font: font-body)[#numbering("I", number)]
      #v(16pt)
      #line(length: 40pt, stroke: 1.5pt + luma(200))
      #v(16pt)
      #text(size: 26pt, weight: "bold", fill: color-secondary, font: font-body)[#title]
      #if subtitle != none {
        v(10pt)
        text(size: 13pt, fill: luma(120), style: "italic", font: font-body)[#subtitle]
      }
      #if chapters != none {
        v(20pt)
        text(size: 9pt, fill: luma(140), tracking: 1.2pt, weight: "medium")[What You Will Learn in This Part]
        v(8pt)
        block(
          width: 78%,
          fill: white,
          stroke: 0.5pt + luma(225),
          inset: (left: 14pt, right: 14pt, top: 12pt, bottom: 12pt),
          radius: 4pt,
        )[
          #set text(size: 9.2pt, fill: luma(55))
          #set par(leading: 0.65em)
          #for chapter in chapters [
            - #chapter
            #v(2pt)
          ]
        ]
      }
    ]
    #v(1fr)
  ]
}

// ─── Code Block ───────────────────────────────────────────────
#let code-block(code) = {
  v(4pt)
  block(
    width: 100%,
    fill: rgb("#FAFAFA"),
    stroke: (
      left: 3pt + color-primary,
      top: 0.5pt + luma(230),
      right: 0.5pt + luma(230),
      bottom: 0.5pt + luma(230),
    ),
    inset: (left: 12pt, right: 10pt, top: 8pt, bottom: 8pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
    breakable: true,
    clip: true,
  )[
    #set text(font: font-code, size: 8.5pt, fill: rgb("#1e1e1e"))
    #set par(leading: 0.55em)
    #code
  ]
  v(3pt)
}

// ─── Output Block ─────────────────────────────────────────────
#let output-block(content) = {
  v(1pt)
  block(
    width: 100%,
    fill: rgb("#FAFAFA"),
    stroke: (
      left: 3pt + color-accent,
      top: 0.5pt + luma(230),
      right: 0.5pt + luma(230),
      bottom: 0.5pt + luma(230),
    ),
    inset: (left: 12pt, right: 10pt, top: 6pt, bottom: 6pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
    breakable: true,
    clip: true,
  )[
    #set text(font: font-code, size: 8pt, fill: luma(80))
    #set par(leading: 0.5em)
    #content
  ]
  v(4pt)
}

// ─── Admonition Boxes ─────────────────────────────────────────
#let _admonition(icon, label, accent, body) = {
  v(6pt)
  block(
    width: 100%,
    stroke: (left: 3pt + accent),
    fill: rgb("#FAFAFA"),
    inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
    breakable: true,
  )[
    #text(weight: "bold", fill: accent, size: 9pt, tracking: 0.5pt)[#icon #upper(label)]
    #v(4pt)
    #set text(size: 9.5pt)
    #body
  ]
  v(6pt)
}

#let tip-box(body) = _admonition(
  sym.arrow.r.filled, "Tip", color-primary-dark, body
)
#let note-box(body) = _admonition(
  sym.circle.filled.small, "Note", luma(120), body
)
#let warning-box(body) = _admonition(
  sym.excl, "Warning", color-accent, body
)

// ─── Chapter Start Boxes ────────────────────────────────────
#let chapter-question-box(body) = {
  v(8pt)
  block(
    width: 100%,
    fill: rgb("#FAFAFA"),
    stroke: (left: 3pt + color-secondary),
    inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
    breakable: true,
  )[
    #text(weight: "bold", fill: color-secondary, size: 9pt, tracking: 0.5pt)[
      Key Question
    ]
    #v(4pt)
    #set text(size: 9.5pt)
    #body
  ]
  v(6pt)
}

#let chapter-key-points(items) = {
  v(6pt)
  block(
    width: 100%,
    fill: rgb("#FAFAFA"),
    stroke: (left: 3pt + color-primary),
    inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
    breakable: true,
  )[
    #text(weight: "bold", fill: color-primary-dark, size: 9pt, tracking: 0.5pt)[
      Key Takeaways at a Glance
    ]
    #v(4pt)
    #set text(size: 9.5pt)
    #for item in items [
      - #item
    ]
  ]
  v(6pt)
}

#let diagram-guide-box(body) = {
  v(4pt)
  block(
    width: 100%,
    fill: rgb("#FAFAFA"),
    stroke: (left: 3pt + luma(190)),
    inset: (left: 14pt, right: 12pt, top: 8pt, bottom: 8pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
    breakable: true,
  )[
    #text(weight: "bold", fill: luma(110), size: 8.8pt, tracking: 0.5pt)[
      How to Read This Diagram
    ]
    #v(4pt)
    #set text(size: 9.2pt, fill: luma(60))
    #body
  ]
  v(6pt)
}

// ─── Chapter Summary Section ─────────────────────────────────
#let chapter-summary-header() = {
  v(16pt)
  block(width: 100%)[
    #line(length: 100%, stroke: 0.5pt + luma(220))
    #v(10pt)
    #text(size: 12pt, weight: "bold", fill: color-secondary, tracking: 0.3pt)[Summary]
    #v(4pt)
  ]
}

// ─── Next Step Box ───────────────────────────────────────────
#let next-step-box(body) = {
  v(10pt)
  block(
    width: 100%,
    fill: rgb("#FAFAFA"),
    stroke: (left: 3pt + color-primary),
    inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
  )[
    #text(weight: "bold", fill: color-primary-dark, size: 9pt, tracking: 0.5pt)[
      #sym.arrow.r.double NEXT STEP
    ]
    #v(4pt)
    #set text(size: 9.5pt)
    #body
  ]
  v(6pt)
}

// ─── References Box ─────────────────────────────────────────
#let references-box(body) = {
  v(4pt)
  block(
    width: 100%,
    fill: rgb("#FAFAFA"),
    stroke: (left: 3pt + luma(200)),
    inset: (left: 14pt, right: 12pt, top: 8pt, bottom: 8pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
  )[
    #text(weight: "bold", fill: luma(120), size: 8.5pt, tracking: 0.5pt)[
      REFERENCES
    ]
    #v(4pt)
    #set text(size: 8.5pt, fill: luma(100))
    #body
  ]
  v(6pt)
}

// ─── Chapter End Decoration ─────────────────────────────────
#let chapter-end() = {
  v(6pt)
}

// ─── Diagram ──────────────────────────────────────────────────
#let diagram(path, caption: none, width: 85%) = {
  v(10pt)
  align(center)[
    #figure(
      image(path, width: width),
      caption: if caption != none { text(size: 9pt)[#caption] },
    )
  ]
  v(10pt)
}

// ─── Summary Table ────────────────────────────────────────────
#let summary-table(headers, ..rows) = {
  v(10pt)
  block(width: 100%)[
    #set text(size: 9pt)
    #table(
      columns: headers.len(),
      align: left,
      fill: (_, row) => if row == 0 { color-secondary } else if calc.odd(row) { rgb("#FAFAFA") } else { white },
      stroke: 0.5pt + luma(230),
      inset: 8pt,
      ..headers.map(h => text(weight: "bold", fill: white)[#h]),
      ..rows.pos().flatten(),
    )
  ]
  v(10pt)
}

// ─── Learning Objectives ──────────────────────────────────────
#let learning-objectives(..items) = {
  v(8pt)
  block(
    width: 100%,
    fill: rgb("#FAFAFA"),
    stroke: (left: 3pt + color-primary),
    inset: (left: 14pt, right: 12pt, top: 10pt, bottom: 10pt),
    radius: (top-right: 3pt, bottom-right: 3pt),
  )[
    #text(weight: "bold", fill: color-primary-dark, size: 10pt, tracking: 0.5pt)[
      LEARNING OBJECTIVES
    ]
    #v(6pt)
    #set text(size: 9.5pt)
    #for item in items.pos() {
      grid(
        columns: (14pt, 1fr),
        gutter: 0pt,
        text(fill: color-primary-dark)[#sym.arrow.r],
        item,
      )
      v(3pt)
    }
  ]
  v(10pt)
}
