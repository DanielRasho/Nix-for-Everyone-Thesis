
// Los anexos de annex/3 y annex/4 también se compilan como documentos independientes.
// annex/annex.typ lo pone en true para que omitan su formato de hoja impresa y su título.
#let in-thesis = state("in-thesis", false)

#let answer-box(height: 3cm, label: "") = {
  if label != "" { text(weight: "bold")[#label]; v(0.2cm) }
  rect(width: 100%, height: height, stroke: 0pt)
}

#let cb(label) = {
  box(width: 0.45cm, height: 0.45cm, stroke: 0.7pt + black, radius: 1pt)
  h(0.4cm)
  label + "    "
}

#let linkert(
  pairs: (), 
  grades : 7) = {
  
  let columns = (auto,) + (1fr,) * grades + (auto,)
  
  let rows = ()
  
  for pair in pairs {
    let (left, right) = pair
    rows.push(table.cell()[#left])
    for i in range(grades) {
      rows.push(table.cell(align: center)[#box(width: 0.45cm, height: 0.45cm, stroke: 0.7pt + black, radius: 1pt)
])
    }
    rows.push(table.cell()[#right])
  }

  table(
    stroke: none,
    columns: columns,
    align: center,
    fill: (x, y) => if calc.odd(y) { luma(245) } else { white },
    ..rows
    )
}

#let code_block(content: "") = {
    block(
      fill: luma(97%),
      inset: 12pt,
      radius: 4pt,
    )[
      #content
    ]
}

#let choice_item(
  label : "a", 
  content : "") = {
  grid(
    columns: (auto, 1fr),
    column-gutter: 1em,
    [*#label*],
  )[
    #code_block(content : [#content])
  ]
};
