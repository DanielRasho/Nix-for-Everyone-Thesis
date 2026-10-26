// Misma llave que `in-thesis` en utilities.typ.
#let in-thesis = state("in-thesis", false)

#set heading(numbering: none)

// Formato de la hoja impresa. Dentro de la tesis (annex/annex.typ) se omite y el título
// lo pone el encabezado del anexo.
#show: doc => context if in-thesis.get() { doc } else [
  #set page(
    paper: "us-letter",
    margin: 1.2cm
  )

  #set text(size: 8.5pt, lang: "es")
  #set par(justify: true, leading: 0.5em, spacing: 0.8em)

  #show heading.where(level: 2): it => {
    v(0.25em)
    text(size: 8.5pt, weight: "bold", it.body)
    v(0.1em)
  }

  // ---------- Encabezado ----------
  #align(center)[
      #text(size: 10pt, weight: "bold")[Consentimiento Informado - Fase 1]
  ]

  #v(0.3em)

  #doc
]

#let campo(label) = text(style: "italic")[#label]

#grid(
  columns: (auto, 1fr),
  row-gutter: 0.35em,
  column-gutter: 0.6em,
  [*PROYECTO:*], [#campo[Nix para todos: Impacto del uso de un lenguaje de propósito general en la usabilidad de Nix]],
  [*Investigador:*], [#campo[Daniel Alfredo Rayo Roldán - ray22933\@uvg.edu.gt]],
  [*Supervisor:*], [#campo[Gabriel Brolo Tobar - gbrolo\@uvg.edu.gt]],
)


// ---------- 1. Introducción ----------
== 1. Introducción

Gracias por considerar participar en nuestro estudio. Este formulario de consentimiento
informado tiene como objetivo proporcionarle información importante sobre el propósito, los
procedimientos y los posibles riesgos y beneficios de participar en este estudio. Por favor, lea
cuidadosamente este documento antes de aceptar participar. Si tiene alguna pregunta, no
dude en preguntar al investigador.

== 2. Propósito del Estudio

El propósito de este estudio es recopilar información sobre *la experiencia de uso en lenguajes de programación*.

La información obtenida en este estudio se utilizará para *comprender las necesidades y puntos de mejorar que tienen los lenguajes de configuración para administración de paquetes de _software_*.

== 3. Procedimientos del Estudio

Si decide participar en este estudio, se le pedirá que *proporcione información sobre su experiencia general en desarrollo de software y administración de paquetes*.

El procedimiento tomará aproximadamente *2 hora y 30 minutos* para completarse y hará preguntas sobre *sobre como aprendes lenguajes de programación*.

La toma de muestra implicará *ver unos tutoriales de lenguajes de programación, para luego llenar un cuestionario donde se pone a prueba lo aprendido, seguido con una encuesta sobre tu experiencia general usando las herramientas propuestas, se grabarán tu voz e interacciones en pantalla durante el proceso. Frases dichas por el usuario pueden ser citadas de forma textual, tras previa anomización*.

== 4. Posibles Riesgos y Beneficios

El estudio conlleva riesgos mínimos que constan de poder experimentar molestia o fatiga mental durante la realización de las actividades; en dado caso, el participante puede solicitar descansos o retirarse en cualquier momento sin consecuencia alguna. 

No se espera que la participación en este estudio genere un beneficio personal directo para el participante. Sin embargo, *los resultados podrán contribuir a generar conocimiento sobre el desarrollo de lenguajes de programación y los métodos para evaluar su usabilidad.*

== 5. Confidencialidad y Protección de Datos

Toda la información recopilada durante este estudio será tratada de forma confidencial. Los datos serán inicialmente identificados mediante un código asignado a cada participante y se almacenarán en *una computadora protegida por contraseña, con acceso restringido al investigador Daniel Rayo*. Una vez finalizada la recolección de datos y eliminada la tabla de correspondencia, la información utilizada para el análisis y la presentación de resultados será anonimizada.

Las grabaciones de voz y pantalla se conservarán durante un máximo de *cuatro semanas* después de finalizada la recolección de datos y serán eliminadas al concluir ese período. Las transcripciones anonimizadas se conservarán durante *16 semanas* y serán almacenadas en la misma computadora. La eliminación de todos los archivos será realizada por el investigador Daniel Rayo al finalizar los períodos de conservación correspondientes.

== 6. Participación Voluntaria

La participación en este estudio es voluntaria. Tiene el derecho a tomar pauses o negarse a participar o de
retirarse del estudio en cualquier momento sin penalización o pérdida de beneficios a los que
tiene derecho de otra manera.

== 7. Compensación

#v(0.3em)

Su participación en este estudio será compensada con un caramelo al terminar la actividad.


== 8. Información de Contacto

Si tiene alguna pregunta o inquietud sobre este estudio, puedes comunicarse a los siguientes personas:

- *Preguntas Relacionadas al Estudio:* Daniel Alfredo Rayo Roldán - ray22933\@uvg.edu.gt\
- *Contacto del investigador principal:* Daniel Alfredo Rayo Roldán ray22933\@uvg.edu.gt\
- *Preguntas sobre sus derechos como participantes:* Carlos Gabriel Escobar Polanco - cgescobarp\@uvg.edu.gt\

== 9. Reconocimiento

He leído y entiendo la información anterior sobre el estudio. He tenido la oportunidad de hacer
preguntas y he recibido respuestas satisfactorias. Al aceptar participar en este estudio, doy
libremente mi consentimiento informado para participar en el estudio.

#v(2em)

#grid(
  columns: (1fr,),
  row-gutter: 1.8em,
  [
    Nombre del participante: #box(width: 1fr, line(length: 50%, stroke: 0.5pt))
  ],
  [
    Firma: #box(width: 1fr, line(length: 50%, stroke: 0.5pt))
  ],
  [
    Fecha: #box(width: 1fr, line(length: 50%, stroke: 0.5pt))
  ],
)
