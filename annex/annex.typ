#import "../utilities.typ" : cb, linkert, answer-box, choice_item, code_block, in-thesis

// Los anexos de 3/ y 4/ son documentos independientes: aquí omiten su formato de hoja
// impresa y su título, y sus `=` quedan como `===` bajo el encabezado que los contiene.
#in-thesis.update(true)
#let embed(path) = { set heading(offset: 2); include path }

== Soluciones existentes a Nixlang <Appendix1>

#figure(
  table(
  columns: (25pt, 1fr, 1fr, 1fr, 1fr),
  table.header[][*Problema*][*Soluciones \ existentes*][*Limitaciones*][*Propuesta*],
  [@Courts2013], 
  [Necesidad de aprender un lenguaje exclusivo de Nix],
  [Uso de lenguajes de propósito general (e.g., Guile en Guix)],
  [Lenguajes poco adoptados mantienen la barrera de entrada @stackoverflowMostPopularTechnologies],
  [Adoptar un lenguaje ampliamente conocido],
  
  [@gagarinFourMonthsNix], 
  [Escasez de documentación y ejemplos],
  [Reescritura de la documentación en un lugar centralizado],
  [Alto costo de mantenimiento y dependencia de aprobación ],
  [Que la estructura del código en sí permite su documentación como el tipado estático],
  
  [@caddetNixNickel \ @hufschmittCurrentStatePtyx],
  [Dependencia de funciones de la librería estándar con muchos parámetros no documentados.],
  [Extensiones al lenguaje para tipado estático],
  [Alta complejidad de implementación],
  [Delegar el tipado a herramientas externas maduras],
  
  [@Schwaighofer2026],
  [Alta complejidad general del ecosistema],
  [Generación de código con Inteligencia Artificial],
  [No aborda causas estructurales; depende de datos de entrenamiento],
  [Evitar soluciones basadas en generación automática],
  stroke: 0.5pt + black, 
),
caption: "Una tabla comparativa sobre algunas de las soluciones propuestas por la comunidad de Nix que buscan mejorar la experiencia en Nixlang de forma directa o indirecta, incluyendo sus limitaciones y una propuesta derivada.")

== Interés en Neovim <Appendix2>

Con datos extraídos de Google Trends para la búsqueda “Neovim - Programa” en su modo clásico, se obtuvieron series históricas correspondientes a los últimos años. Los datos utilizados se muestran en @googleNeovimInterestTrends.

#figure(
image("1/indice de interes de Neovim en el tiempo.png", width: 74%),
caption: [Índice de interés de búsqueda de Neovim en Google entre 2014 y 2026. Se observa un aumento a finales de 2021, aproximadamente seis meses después de la introducción del soporte para Lua @NeovimNews112021.]
)

== Número de dependencias de Firefox <Appendix5>
Con datos extraidos de Github del repositorio de `mozilla-firefox/firefox` para el commit `ac91bfcce1bf3240e2dce40f47c372e76bc4f26c` se descargaron las dependencias detectadas por Github en formato SBOM (estándar SPDX 2.3) en la sección de "Grafo de Dependencias", revelando una total de 22,732 dependencias. Los datos utilizados se encuentran en `2/mozilla-firefox_dependencies.json`.

Del archivo SBOM se extrajeron 21,295 paquetes y 37,926 relaciones de dependencia directa (`DEPENDS_ON`)#footnote[La diferencia con las 22,732 dependencias reportadas por la interfaz de Github se debe a que, según indica el propio archivo, la versión exacta de algunos paquetes no pudo ser resuelta.], que se usaron para construir un grafo de dependencias. Los dependencias son mostradas en la @figure3.

== Consentimientos Informados

=== Plantilla Fase 1
#embed("3/informed_consent_phase1.typ")

=== Plantilla Fase 3
#embed("4/informed_consent_phase3.typ")

== Cuestionarios Fase 1 <Appenddix3>

=== Formulario de Programación Natural
#embed("3/natural_programming_test_phase1.typ")

== Cuestionarios Fase 2 <Appendix4>

=== Cuestionario de comprensión cognitiva de NixLang
#embed("4/questionary_nixlang_phase3.typ")

=== Cuestionario de comprensión cognitiva de Nixty
#embed("4/questionary_nixty_phase3.typ")

=== Encuesta de Satisfacción
#embed("4/survey_nixty_phase3.typ")
