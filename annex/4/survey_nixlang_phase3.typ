// Misma llave que `in-thesis` en utilities.typ.
#let in-thesis = state("in-thesis", false)

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


// Formato de la hoja impresa. Dentro de la tesis (annex/annex.typ) se omite y el título
// lo pone el encabezado del anexo.
#show: doc => context if in-thesis.get() { doc } else [
  #set text(lang: "es", size: 11pt)
  #set page(paper: "a4", number-align: center, numbering: none)
  #set par(justify: true)

  #align(center)[= Tu experiencia en NixLang]

  #doc
]

Gracias por tu tiempo. Con tu ayuda, nos gustaría examinar como usuarios perciben la usabilidad de _NixLang_.

No te detengas demasiado en las combinaciones de palabras y realiza tu evaluación de forma espontánea. Puede que algunas combinaciones no te parezcan del todo adecuadas para el producto. Sin embargo, te pedimos que des tu opinión de todos modos.

Recuerda que no hay respuestas correctas ni incorrectas; lo que cuenta es tu opinión personal.

*¿Cómo calificarias la experiencia de usuario de NixLang?*

#linkert(pairs: (
    ("Bueno", "Malo"),
  ),
  grades: 7
)

*¿Qué tan bien NixLang respondió a tus necesidades?*

#linkert(pairs: (
    ("Para nada", "Completamente"),
  ),
  grades: 7
)

*Con la ayuda de los pares de palabras marca cual considerarias seria la descripción para NixLang.*
#linkert(pairs: (
    ("Malo", "Bueno"), // SAD_GENERAL
    ("Feo", "Bonito"), // SAD_GENERAL
    ("Confuso", "Estructurado"), // SAD_PRACTICAL
    ("Practico", "Impráctico"), // SAD_PRACTICAL
    ("Impredecible", "Predecible"), // SAD_PRACTICAL
    ("Simple", "Complicado"), // SAD_PRACTICAL
    ("Antipático", "Cautivador"), // SAD_HEDONIC
    ("Elegante", "Tosco"), // SAD_HEDONIC
    ("Barato", "Prémium"), // SAD_HEDONIC
    ("Creativo", "No Imaginativo"), // SAD_HEDONIC
    ("Recomendable", "No recomendable"), // DEXI_GENERAL
    ("Eficiente", "Ineficiente"), // DEXI_P
    ("Flexible", "Rígido"), // DEXI_P
    ("Facil de aprender", "Díficil de aprender"), // DEXI_P
    ("Limitado", "Extensivo"), // DEXI_P
    ("Desinformativo", "Informativo"), // DEXI_P
    ("Motivador", "Desmotivador"), // DEXI_H
    ("Genera respeto", "Genera desconfianza"), // DEXI_H
    ("Agradable", "Desagradable"), // DEXI_H
    ("Promueve la creatividad", "Suprime la creatividad"), // DEXI_H
    ("Envolvente", "Aburrido"), // DEXI_H
    ("Me acerca a otros", "Me aleja de otros"), // DEXI_H
  ),
  grades: 7
)

*¿Algún comentario adicional que quieras destacar sobre tu experiencia usando NixLang? (Opcional)*