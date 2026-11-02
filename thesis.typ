// ==============================================================================
// Plantilla para Trabajos de Graduación IE-MT 2019v3 -- réplica en Typst
// Traducido desde la plantilla LaTeX original (z-main.tex y archivos anexos)
// Autor original de la plantilla: MSc. Miguel Zea
// ==============================================================================
// Este archivo único reúne el contenido que originalmente estaba repartido en
// los archivos .tex (0-datos_estudiante, 1-opciones_adicionales, a-prefacio,
// b-resumen, c-abstract, d-introduccion, ..., o-glosario). Cada sección se
// marca con un comentario equivalente al nombre del archivo .tex original.

// ------------------------------------------------------------------------------
// 0-datos_estudiante.tex -- Datos del estudiante y del trabajo de graduación
// ------------------------------------------------------------------------------
#let nombreestudiante = "Daniel Alfredo Rayo Roldán"
#let uvgcarne = "22933"
#let uvgfacultad = "Ingeniería"
#let uvgcarrera = "Ingeniería en Ciencias de la Computación y Tecnologías de la Información"

#let titulotesis = "Nix para todos: Impacto del uso de un lenguaje de propósito general en la usabilidad de Nix"
#let anoentrega = "2026"
#let nombreasesor = "Ing. Gabriel Brolo Tobar"

#let nombreprimerex = "Dr. Gabriel Antonio Barrientos Rodriguez"
#let nombresegundoex = "Ing. Luis Pedro Montenegro"
#let anoaprobacion = "2026"

#let imagenportada = "media/template/portadacit.jpg"

// ------------------------------------------------------------------------------
// 1-opciones_adicionales.tex -- Capítulos incluidos (todas las secciones se
// incluyen por defecto, igual que en la plantilla original)
// ------------------------------------------------------------------------------

// 
// ============ METHODS

#let cite-range(first, ..middle, last) = {
  cite(label(first))
  for c in middle.pos() {
    box(width: 0pt, text(fill: white, cite(label(c))))
  }
  text("\u{2013}")
  cite(label(last))
}

// ==============================
// METHODS
// ==============================
#import "utilities.typ"

// ------------------------------------------------------------------------------
// Definiciones generales de la plantilla
// ------------------------------------------------------------------------------
#let uvg-green = rgb("#114734")

#set document(title: titulotesis, author: nombreestudiante)
#set page(paper: "us-letter", margin: (top: 1in, left: 1.5in, right: 1in, bottom: 1in))
#set text(lang: "es", size: 11pt)
#set par(justify: true, leading: 0.65em, spacing: 1.2em)

// Numeración de encabezados: capítulo.sección.subsección
#set heading(numbering: "1.1")

// Cuadros (tablas): en español "es" (no "es-MX") la plantilla original usa
// "Cuadro" en vez de "Tabla" para los captions.
#show figure.where(kind: table): set figure(supplement: "Cuadro")
#show figure.where(kind: table): set figure.caption(position: top)

// Estilo de encabezados de capítulo (equivalente a \usepackage[Sonny]{fncychap})
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(1em)
  if it.numbering != none {
    block(text(size: 13pt, tracking: 2pt, fill: uvg-green)[
      CAPÍTULO #counter(heading).display("1")
    ])
    v(0.3em)
  }
  text(size: 20pt, weight: "bold")[#it.body]
  v(0.3em)
  line(length: 100%, stroke: 0.6pt + uvg-green)
  v(1em)
}
// Número del encabezado (p. ej. "2.1") seguido del título, si tiene numeración
#let heading-number(it) = if it.numbering != none {
  counter(heading).display(it.numbering)
  h(0.6em)
}
#show heading.where(level: 2): it => {
  v(0.8em)
  text(size: 14pt, weight: "bold")[#heading-number(it)#it.body]
  v(0.4em)
}
#show heading.where(level: 3): it => {
  v(0.6em)
  text(size: 12pt, weight: "bold", style: "italic")[#heading-number(it)#it.body]
  v(0.3em)
}

// Formato de párrafo por defecto (\defaultparformat en la plantilla original:
// espaciado entre párrafos en vez de sangría)
#set par(first-line-indent: 0pt)

// Salto de página en blanco (equivalente a \blankpage), no se usa en la
// versión digital pero se deja disponible.
#let blankpage() = {
  pagebreak()
  [ ]
  pagebreak()
}

// Glosario manual (Typst no trae un paquete de glosarios como
// \usepackage{glossaries}; se simula con un diccionario + funciones gls/Gls).
#let glossary = (
  latex: (name: "latex", desc: "Es un lenguaje de marcado adecuado especialmente para la creación de documentos científicos"),
  formula: (name: "fórmula", desc: "Una expresión matemática"),
)
#let gls(key) = glossary.at(key).name
#let Gls(key) = {
  let n = glossary.at(key).name
  upper(n.slice(0, 1)) + n.slice(1)
}

// ==============================================================================
// PORTADA
// ==============================================================================
#page(
  fill: uvg-green,
  margin: (left: 3cm, right: 3cm, top: 1in, bottom: 0in),
  numbering: none,
)[
  #set text(fill: white)
  #line(length: 100%, stroke: 0.6pt + white)
  #v(0.1in)
  #text(size: 26pt, weight: "bold")[#titulotesis]
  #v(0.3em)
  #line(length: 100%, stroke: 0.6pt + white)
  #v(0.3em)
  #text(size: 18pt)[#nombreestudiante]

  #v(1fr)
  #box(width: 100%, height: 13.25cm)[
    #box(width: 100%, height: 100%, clip: true)[
      #image(imagenportada, height: 13.25cm, width: 100%, fit: "cover")
    ]
    // Logo institucional con fondo (fondologo_grande.png), esquina inferior derecha
    #place(bottom + right, dx: -1cm, dy: -0.2cm)[
      #image("media/template/fondologo_grande.png", height: 1.15in)
    ]
    // TODO: logoUVGblanco.eps -- Typst no soporta el formato EPS de forma
    // nativa. Convierta el archivo a PNG o SVG (por ejemplo con
    // `inkscape plantilla/logoUVGblanco.eps --export-type=svg` o
    // `pdftocairo`/`magick`) y luego descomente e inserte:
    #place(bottom + right, dx: -1.6cm, dy: -0.8cm)[
      #image("media/template/logoUVGblanco.svg", height: 0.55in)
    ]
  ]
]

// ==============================================================================
// CARÁTULA
// ==============================================================================
#page(numbering: none)[
  #align(center)[
    #text(size: 18pt)[UNIVERSIDAD DEL VALLE DE GUATEMALA] \
    #text(size: 18pt)[Facultad de #uvgfacultad]
  ]
  #v(0.75cm)

  #align(center)[
    // TODO: escudoUVGnegro.eps -- Typst no soporta EPS de forma nativa.
    // Convierta el archivo a PNG o SVG y descomente la siguiente línea:
    #image("media/template/escudoUVGnegro.svg", height: 5.5cm)
    #v(5.5cm)
  ]
  #v(0.5in)

  #align(center)[
    #text(size: 15pt, weight: "bold")[#titulotesis]
    #v(1fr)
    #text(size: 13pt)[
      Modalidad de trabajo profesional presentado por #nombreestudiante para optar al
      grado académico de Licenciado en #uvgcarrera
    ]
    #v(1fr)
    #text(size: 12pt)[Guatemala,]
    #v(1em)
    #text(size: 12pt)[#anoentrega]
  ]
]

// ==============================================================================
// HOJA DE FIRMAS
// ==============================================================================
#page(numbering: none)[
  #v(0.5in)
  #text(size: 13pt)[Vo.Bo.:]
  #v(1cm)
  #align(center)[
    #line(length: 4in, stroke: 0.5pt)
    #nombreasesor
  ]
  #v(1in)

  #text(size: 13pt)[Tribunal Examinador:]
  #v(1cm)
  #align(center)[
    #line(length: 4in, stroke: 0.5pt)
    #nombreasesor
    #v(1in)
    #line(length: 4in, stroke: 0.5pt)
    #nombreprimerex
  ]
  #v(1in)

  Fecha de aprobación: Guatemala, #box(width: 0.5in, line(length: 100%, stroke: 0.5pt))
  de #box(width: 1in, line(length: 100%, stroke: 0.5pt)) de #anoaprobacion.
]

// ==============================================================================
// CONTENIDO DEL TRABAJO -- numeración romana para las primeras páginas
// ==============================================================================
#set page(numbering: "i")
#counter(page).update(1)

// ------------------------------------------------------------------------------
// a-prefacio.tex -- AGRADECIMIENTOS
// ------------------------------------------------------------------------------
#heading(level: 1, numbering: none, outlined: true)[Reconocimientos]

Pendientes

// ------------------------------------------------------------------------------
// b-resumen.tex -- RESUMEN
// ------------------------------------------------------------------------------
#heading(level: 1, numbering: none, outlined: true)[Resumen]

El problema de llevar _software_ de una computadora a otra y que siga funcionando (proceso conocido como Despliegue de _Software_) es un yugo con el que las Ciencias de Computación no han dado una solución definitiva, esencialmente porque para que una pieza de _software_ funcione correctamente no solamente depende del código fuente en el que esta escrita, sino del contexto que le rodea (_hardware_, sistema operativo, dependencias, etc.), bajo ese contexto surgen Nix como un manejador de paquetes y sistema de construcción #footnote[Sistemas que automatizan la ejecución de tareas repetitivas, usualmente para crear artefactos de _software_ que pueden ser desplegados] que utiliza un enfoque inspirado en la pureza funcional, donde cada paquete define explícitamente el contexto en el que espera ser construido y ejecutado. Este enfoque a demostrado poder crear más de 700 mil artefactos binariamente idénticos en diferentes computadoras y contar con unos de los repositorio de paquetes más grande a fecha de este documento. La idea evolucionó al punto de definir el estado casi completo de un sistema operativo mediante un solo archivo de configuración.

Sin embargo, a pesar de sus capacidades prometedoras, Nix no ha gozado de la misma adopción que otras herramientas que abordan los mismos problemas de reproducibilidad como Docker, Conda o VirtualEnv u otros manejadores de paquetes. Las causas de acuerdo a la comunidad son varias: Documentación compleja, errores crípticos, o un lenguaje de programación difícil de dominar; muchos de ellos no siendo problemas técnicos sino de experiencia de uso, y que cae en el rango de estudio del "DX" (Experiencia de Desarrollo por sus siglas en inglés). Este trabajó se enfoca en verificar si proveer una nueva forma de interactuar con Nix a través de un lenguaje de propósito general como Typescript, puede reducir la barrera de entrada para nuevos usuarios y por ende mejorar su DX.

// ------------------------------------------------------------------------------
// c-abstract.tex -- ABSTRACT
// ------------------------------------------------------------------------------
#heading(level: 1, numbering: none, outlined: true)[Abstract]

The problem of moving _software_ from one computer to another and having it keep working (a process known as _software_ Deployment) is a burden that Computer Science has not yet found a definitive solution to, essentially because for a piece of _software_ to work correctly it depends not only on the source code in which it is written, but also on the surrounding context (hardware, operating system, dependencies, etc.). It is in this context that Nix emerges as a package manager and build system #footnote[Systems that automate the execution of repetitive tasks, usually to create _software_ artifacts that can be deployed.] that uses an approach inspired by functional purity, where each package explicitly defines the context in which it expects to be built and run. This approach has demonstrated the ability to create more than 700,000 binarily identical artifacts on different computers and boasts one of the largest package repositories as of the writing of this document. The idea evolved to the point of being able to define the nearly complete state of an operating system through a single configuration file.

However, despite its promising capabilities, Nix has not enjoyed the same adoption as other tools that address the same reproducibility problems, such as Docker, Conda, VirtualEnv, or other package managers. According to the community, the causes are several: complex documentation, cryptic errors, or a programming language that is difficult to master; many of these are not technical problems but rather user-experience ones, falling within the scope of "DX" (Developer Experience) studies. This work focuses on verifying whether providing a new way of interacting with Nix through a general-purpose language such as TypeScript can lower the barrier to entry for new users and thereby improve its DX.

// ------------------------------------------------------------------------------
// ÍNDICE GENERAL
// ------------------------------------------------------------------------------
#pagebreak()
#heading(level: 1, numbering: none, outlined: true)[Índice]
#outline(title: none, indent: auto)

// ------------------------------------------------------------------------------
// LISTADO DE FIGURAS
// ------------------------------------------------------------------------------
#pagebreak()
#heading(level: 1, numbering: none, outlined: true)[Lista de figuras]
#outline(title: none, target: figure.where(kind: image))

// ------------------------------------------------------------------------------
// LISTADO DE CUADROS
// ------------------------------------------------------------------------------
#pagebreak()
#heading(level: 1, numbering: none, outlined: true)[Lista de cuadros]
#outline(title: none, target: figure.where(kind: table))


// ==============================================================================
// A partir de aquí inicia la numeración arábiga y el conteo de capítulos
// ==============================================================================
#set page(numbering: "1")
#counter(page).update(1)
#counter(heading).update(0)

// ------------------------------------------------------------------------------
// d-introduccion.tex -- INTRODUCCIÓN
// ------------------------------------------------------------------------------
= Introducción

El distribuir _software_ de las cocinas de los ingenieros a las mesas de los usuarios finales no ha sido una tarea sencilla  @mantylaSoftwareDeploymentActivities2011, los artefactos de _software_ se comportan igual a las plantas exóticas cuando son trasplantadas a un hábitat diferente al que están acostumbradas: se marchitan @Dolstra2006. Como las plantas, el _software_ "crece y evoluciona" en el _hardware_, sistema operativo y librerías específicas, de la computadora del ingeniero, pero en el momento que esos artefactos son llevados a los ecosistemas extraños, que son los dispositivos de los usuarios finales, el que funcione o no se vuelve una apuesta ante la que no se tiene control... o si? @Dolstra2006.

El problema anteriormente descrito, es el sujeto de estudio del campo de "Manejo de Configuración de _Software_" (o CSM por sus siglas en ingles), donde se reconoce que la ejecución correcta de _software_ no solamente depende de su código fuente, sino del contexto que le rodea @Dolstra2006. Con los años se ha desarrollado una familia de _software_, llamada *manejadores de paquetes* responsable de modificar el entorno global de las computadoras objetivo para conseguir las condiciones ideales para cada aplicación. Al día de hoy se han convertido en una familia tan variada que se han vuelto una característica diferenciadora en las diferentes distribuciones de Linux o lenguajes de programación @Gibb2026. Una corriente opuesta es la *virtualización*, que consiste en empaquetar las aplicaciones junto a los entornos completos que necesitan y ejecutarlas de forma aislada, soluciones de este tipo son muy usadas en servicios de la nube @PDFInfrastructureCode.

Sin embargo, como se ilustra en la @figura1, los manejadores de paquetes lidian con el problema que intentar satisfacer a varias aplicaciones en un entorno global puede llevar a conflictos irresolubles: cuando `FOO` y `BAR` dependen de versiones distintas de Node, el entorno global obliga a elegir una sola versión compatible (Node v23.8). La virtualización elimina ese conflicto permitiendo que cada aplicación lleve su propia versión en entornos separados, pero a cambio puede duplicar dependencias compartidas como Clang 19.2 @Zwinger2026, incrementando el consumo de almacenamiento en varios casos @zhaoEndtoendHighperformanceDeduplication2024a.

#figure(image("media/figures/Figure1.svg"), caption: [
  Dependencias de dos programas ficticios `FOO` y `BAR` en manejadores de paquetes vs. virtualización.
])<figura1>

_La unión hace la fuerza_, dando origen en 2003 a Nix como una tercera alternativa que fusiona ideas de ambas corrientes partiendo de la idea que: Usar los mismos ingredientes y pasos debería producir el mismo resultado sin importar la computadora. Nix garantiza lo primero mediante identificadores (ID) únicos en un entorno aislado (_Nix Store_) que, como se ve en la @figura2, permiten la coexistencia de versiones distintas del mismo paquete y la reutilización de dependencias compartidas, resolviendo los problema previos de `FOO` y `BAR`; y lo segundo mediante entornos aislados que aseguran la reproducibilidad @Dolstra2006. La elegancia de Nix reside en cómo construye estos identificadores y entornos aislados.

#figure(image("media/figures/Figure2.svg", width: 70%), caption: [
  Manejo de paquetes en Nix con identificadores únicos permite coexistencia y reutilización de paquetes.
])<figura2>

Fue esta enfoque centrado en seguir recetas explícitas que permitió a Nix conseguir una serie de hitos importantes al contar con unos de los repositorios de paquetes generales más grandes de Linux @marakasovRepositoryStatistics, de los cuales 700 mil han demostrado poder replicarse de forma binariamente idéntica en diferentes computadoras @Malka2025. Aconteció que mucha de las ideas podían generalizarse hasta al punto de reproducir casi por completo un sistema operativo, dando origen a la distribución NixOS @Dolstra2008.

A pesar de ello , Nix ha gozado de una adopción bastante reducida en comparación a las otras herramientas discutidas @stackoverflowMostPopularTechnologies ¿Cuál es entonces su talón de Aquiles? Tal parece que no son necesariamente problemas técnicos, sino de experiencia de uso; en encuestas hechas en el foro oficial, la comunidad resaltaba problemas importantes con la documentación, errores crípticos y un _Domain Specific Language_ (DSL) difícil de dominar #cite-range( "2022NixSurvey2022" ,"2025CommunitySurvey","NixCommunitySurvey2023"); además, en otra encuesta, se estimó que los usuarios perciben requerir un tiempo de 5 años para dominar la herramienta a pesar que la mayoría lo usa a diario. Llevando a un raro caso donde a pesar que la comunidad le encanta la idea detrás de Nix @NixCommunitySurvey2024  sus problemas de usabilidad son tan severos que podrían estar impidiendo su uso, lo que concuerda con observaciones de otros estudio en herramientas son situaciones similares @goodwinFunctionalityUsability1987.

El concepto que los desarrolladores también son usuarios dio origen al campo de estudio de Experiencia de Desarrollo (o DX por sus siglas en inglés), donde el estudio sobre como los desarrolladores perciben sus herramientas ha sido un tema frecuente @Razzaq2024 sobre el que ya se han desarrollado algunos instrumentos como DEXI para evaluar dichas dimensiones@Kuusinen2016. Y dado el trayecto de intentos por mejorar la DX en Nix #cite-range("caddetNixNickel", "gagarinFourMonthsNix", "hufschmittCurrentStatePtyx", "fricklerhandwerk2022") el presente trabajo, busca ser una aplicación de las técnicas aprendidas en el campo de DX, en conjunto con el diseño de lenguajes, para evaluar si un Lenguaje de Propósito Específico Embebido (eDSL por sus siglas en inglés) en Typescript @Typescript podría ayudar a reducir la barra de entrada para nuevos desarrolladores en la herramienta.

// ------------------------------------------------------------------------------
// f-justificacion.tex -- JUSTIFICACIÓN
// ------------------------------------------------------------------------------
= Justificación

Con el crecimiento del mercado de los servicios de infraestructura como código @grandviewresearchInfrastructureCodeMarket, se ha aprendido que el poder definir el estado de sistemas completos a través de código, trae ventajas importantes en velocidad de desarrollo, escalabilidad y costos @pandyaIntroductionInfrastructureCode2022. La misma idea también se ha aplicado a entornos de desarrollo @ghanbariUsingDevelopmentEnvironment2026 o flujos de despliegue continuo @wesselGitHubActionsImpact2023; todo lo anterior sugiere que herramientas que permiten definir entidades o procesos de forma declarativa pueden facilitar el ciclo de desarrollo de _software_. En el manejo de paquetes, el panorama es fragmentado: habiendo alternativas por lenguaje, o indirectas como Docker @Zwinger2026; y una solución declarativa de propósito general no es de el todo clara. Nix lleva años intentando llenar ese espacio — y las cifras sugieren que esta haciendo algo bien: al tener uno de los repositorios de paquetes más grandes de Linux, con 115 mil paquetes @marakasovRepositoryStatistics un crecimiento del 264% en número de mantenedores en los últimos seis años @gg-solutionsLinuxSilentTech2026.

Por medio de su lenguaje de configuración, Nix permite describir: la construcción, instalación y composición de paquetes de _software_ @Dolstra2006, habilidad que se ha mostrado aplicable en configuración de ambientes de Computación de Alto Rendimiento @guilloteauPainlessTranspositionReproducible2022 @Gomez2020, sistemas operativos @Thiberg2025 despliege de _software_ @VanDerBurg2014, orquestación de servicios @FloxKubernetesUncontained o entornos de desarrollo @replitReplitHowWe2021. 

No obstante, a pesar de su versatilidad, Nix presenta una barrera de entrada considerable. Reportes sugieren una curva de aprendizaje pronunciada @NixCommunitySurvey2024, atribuida en parte a la complejidad de su lenguaje de configuración (Nixlang) para ciertos usuarios @fricklerhandwerk2022, aspecto que también su creador ha identificado como susceptible de mejora @Dolstra2018. Estas dificultades podrían estar incidiendo en su adopción relativamente limitada frente a herramientas como Docker @stackoverflowMostPopularTechnologies.

Nixlang es la principal interfaz para interactuar con el ecosistema Nix, es un lenguaje de dominio específico (DSL por sus siglas en inglés) diseñado  directamente para expresar los constructos de la herramienta, y es, en gran medida, responsable de la flexibilidad que la caracteriza @NixdevDocumentation. Sin embargo, esta misma especialización introduce complejidades que afectan su accesibilidad y usabilidad @Dolstra2018. Como respuesta, la comunidad ha explorado diversas estrategias para mitigar estas limitaciones, como : extensiones al lenguaje, con la incorporación de tipado estático —esfuerzos que han sido abandonados debido a su complejidad técnica— @caddetNixNickel @hufschmittCurrentStatePtyx; agentes de inteligencia artificial para generar configuraciones, aún sin validación empírica sólida en términos de usabilidad @Schwaighofer2026; y, en un enfoque más radical, la sustitución del lenguaje por Guile, un lenguaje de propósito general @Courts2013, aunque tampoco es un lenguaje muy conocido @stackoverflowMostPopularTechnologies, sabiendo que pertenece a la familia de Lisp @IntroductionGuileReference.

Con base en las propuestas anteriores se hizo un análisis comparativo (véase @Appendix1), donde se observa que las soluciones existentes tienden a introducir nuevas fuentes de complejidad o dependen de factores externos, sin abordar las causas estructurales de la fricción en Nix; esto sugiere que un posible buen enfoque consistiría en interactuar con Nix usando un lenguaje ampliamente conocido, y Typescript encaja muy bien en ese molde dada su popularidad @stackoverflowMostPopularTechnologies y similitud sintáctica con Nixlang, siendo descrito en ocasiones como "JSON con funciones" (siendo JSON una notación usada en Typescript) @NixdevDocumentation.

El uso de lenguajes de propósito general para expresar dominios específicos —conocido como lenguaje de propósito específico embebido (eDSL) @vandeursenDomainspecificLanguagesAnnotated2000— no es un enfoque novedoso y ha demostrado ser efectivo en contextos similares. Un caso ilustrativo es Neovim, que en 2021 introdujo un eDSL en Lua como alternativa a Vimscript @NeovimNews112021, lo cual coincidió con un incremento notable en su interés (véase @Appendix2). En el ecosistema de Nix, existe también una propuesta de eDSL en JavaScript ; no obstante, se trata de un proyecto sin actividad reciente, limitado a un subconjunto de funcionalidades —principalmente la creación de paquetes— y sin evidencia empírica que respalde mejoras en la experiencia de desarrollo @burgNiJSInternalDSL2026.

En este contexto, persiste la ausencia de una propuesta que combine un eDSL basado en un lenguaje ampliamente adoptado, con cobertura funcional mas amplia de Nixlang y validación empírica de mejoras en la experiencia de desarrollo.

// ------------------------------------------------------------------------------
// g-objetivos.tex -- OBJETIVOS
// ------------------------------------------------------------------------------
= Objetivos

== Objetivo general
Evaluar si un eDSL en TypeScript reduce la barrera de entrada a Nix —referente funcional y declarativo en gestión de paquetes, limitado por su curva de aprendizaje— frente a Nixlang, mediante tiempo de completación de tareas y experiencia de usuario.

== Objetivos específicos
1. Identificar los principales puntos de dolor cognitivos que presenta el lenguaje de Nix, para fundamentar el diseño de un eDSL, mediante sesiones de pensar-en-alto y "Programación Natural" con estudiantes de Ciencias de la Computación que no hayan utilizado Nix previamente.
2. Desarrollar un eDSL en TypeScript que sirva de prototipo funcional para la evaluación comparativa, capaz de generar archivos de configuración en Nixlang, cubriendo al menos las funcionalidades de la librería estándar, verificado con una batería de pruebas.
3. Comparar Nixlang frente al eDSL desarrollado, para determinar si la familiaridad con Typescript reduce la carga cognitiva de adopción mediante un cuestionario estructurado, y el uso de Short AttrakDiff 2 y DEXI aplicados a estudiantes de Ciencias de la Computación sin experiencia previa, con análisis de diferencia estadística.

// ------------------------------------------------------------------------------
// i-marco_teorico.tex -- MARCO TEÓRICO
// ------------------------------------------------------------------------------
= Marco teórico

Las siguientes secciones presentarán el panorama actual sobre el despliegue y manejo de paquetes de _software_, los problemas de los modelos existentes y la forma en que Nix resuelve algunos de ellos. Posteriormente se discutirán los problemas de usabilidad en Nix y los intentos previos por resolverlos; nos enfocaremos en su lenguaje _Nixlang_, explicando su naturaleza y cómo se diferencia de otros lenguajes. Se concluirá con un resumen de la literatura sobre estudios de usabilidad en lenguajes de programación.

== Despliegue de _software_

La mayoría de los programas se desarrollan pensando en que serán ejecutados en sistemas distintos al que los vio nacer. El conjunto de actividades orientadas a llevar un artefacto de _software_ desde el entorno de desarrollo hasta las computadoras del usuario final, y a garantizar su correcto funcionamiento a lo largo de todo su ciclo de vida —instalación, actualización, configuración y eventual desinstalación—, constituye el campo de interés del despliegue de _software_ @mantylaSoftwareDeploymentActivities2011 @Dolstra2006. Contrario a la percepción común de que desplegar un programa se reduce a "copiar archivos", Mäntylä y Vanhanen @mantylaSoftwareDeploymentActivities2011 documentan, a partir de un estudio de caso en cuatro empresas, que se trata de un proceso multifacético que involucra la interacción con el cliente, la integración con sistemas externos y la configuración del entorno de ejecución; complejidad que se acentúa cuando el producto depende de un modelo de datos particular o de una integración estrecha con otros sistemas.

Esta noción amplia de despliegue está estrechamente vinculada con el campo del Manejo de Configuración de _Software_ (SCM, por sus siglas en inglés), disciplina orientada a preservar la integridad de un producto a lo largo de su evolución mediante la identificación, el control y la auditoría de los cambios realizados sobre sus componentes @bersoffSoftwareConfigurationManagement1978. Dolstra @Dolstra2006 formaliza la relación entre ambos campos al señalar que la ejecución correcta de un artefacto de _software_ no depende únicamente de su código fuente, sino del contexto que lo rodea —_hardware_, sistema operativo, bibliotecas y demás dependencias—; desplegar un programa consiste, entonces, en reconstruir fielmente dicho contexto en cada entorno de destino.

Para lidiar con esta dependencia del contexto han surgido distintas familias de herramientas, cada una centrada en una faceta particular del problema: los manejadores de paquetes, que automatizan la instalación y resolución de dependencias dentro de un entorno compartido; las herramientas de virtualización y contenedores, que empaquetan la aplicación junto con su entorno de ejecución para aislarla del resto del sistema @Sobieraj2024 @Lingayat2018; los sistemas de construcción (_build systems_), que transforman el código fuente en artefactos ejecutables de forma reproducible; y las herramientas de gestión de configuración, orientadas al aprovisionamiento y mantenimiento de servidores completos @Zwinger2026. Estas categorías no son mutuamente excluyentes, sino solo interactuan en diferentes fases con las mismas unidades de contenido: el paquete de _software_.

== Paquetes de _software_

#quote[Uno de los principios fundamentales de la ingeniería de _software_ es promover la reutilización sobre la reimplementación de soluciones existentes.] @jaimeAnalysisEvolutionDependencies Pueden encontrarse indicios de esta práctica desde los primeros programas aritméticos de 1947 @goldstainPlanningCodingProblems1947, y hoy en día ha evolucionado hasta el punto en que buena parte de las herramientas usadas por desarrolladores de _software_ dependen, en mayor o menor medida, de piezas de código desarrolladas por terceros, como React, Vue.js o Scikit-learn @jaimeAnalysisEvolutionDependencies.

A este conjunto de código fuente, binarios y otros archivos reutilizables se le conoce como librerías, dependencias o paquetes @mensSoftwareEcosystemsTooling2023, y constituyen un método eficaz para reducir el tiempo de desarrollo y permitir a los desarrolladores enfocarse en el producto final. Además, se percibe que el código de los paquetes es de mejor calidad, probablemente porque gran parte de ellos es de código abierto, es decir, revisado y modificado por múltiples desarrolladores @societyGuideSoftwareEngineering2026.

El uso de código de terceros se ha convertido en una práctica extendida: en 2026, la compañía Black Duck @blackduck2026OSSRAReport —que ofrece herramientas para evaluar la seguridad de paquetes de código abierto en proyectos de _software_— realizó un estudio sobre 2,843 proyectos de distintas industrias, en el que encontró que el 98% de ellos utilizaba paquetes de código abierto, con un promedio de 1,180 paquetes por proyecto; ambas cifras superiores a las reportadas en un estudio previo de 2025. Este crecimiento no se limita al uso de bibliotecas, sino también a su cantidad dentro de cada proyecto: un ejemplo es el navegador Mozilla Firefox, cuyo árbol de dependencias supera los 2,000 paquetes (@Appendix5), complejidad que se ilustra en la @figure3, donde cada punto representa un paquete coloreado por ecosistema: `npm` en azul, `cargo` en naranja, `pypi` en verde y otros en gris; el punto negro central es el propio repositorio de Firefox. A simple vista se puede intuir que mantenerlos manualmente no resultaría divertido para ningún desarrollador.

#figure(
  image("./media/figures/Figure3.png", width: 85%),
  caption: [Grafo completo de dependencias de Firefox (21,295 paquetes, 37,926 relaciones `DEPENDS_ON`).]
)<figure3>

La @figure3 revela una característica esencial de los paquetes, y es que estos, a su vez, pueden depender de otros paquetes; formando un _grafo de dependencias de software_, donde paquetes son conectados por vértices dirigidos que simbolizan relaciones "depende de" @kikasStructureEvolutionPackage2017. Es esta estructura de datos la que muchos manejadores de paquetes utilizan para saber qué instalar y en qué orden @Gibb2026, como se discutirá en la @manejadores_de_paquetes. Esta misma estructura, además, permite clasificar los diferentes tipos de paquetes.

=== Clasificación de paquetes

Los paquetes se pueden clasificar según su relación con el paquete principal (la aplicación que el usuario desea usar) @Gibb2026:

- *Directas*: Paquetes que el paquete principal declara explícitamente que necesita.
- *Indirectas*: Paquetes que son, a su vez, dependencias de las dependencias directas, sin ser requeridos por el paquete principal.
- *Opcionales*: Paquetes que el autor sugiere tener instalados, pero cuya ausencia no compromete la funcionalidad principal de la aplicación.

En la @figure4 se puede observar un grafo de dependencias que ejemplifica las tres categorías, cada punto representa un paquete: dependencias directas en amarillo, indirectas en azul y opcionales en rojo.

#figure(
  image("media/figures/Figure4.svg", width: 60%),
  caption: [Grafo de dependencias de `tu aplicación`.]
)<figure4>

Una segunda clasificación de los paquetes atiende a la forma en que son referenciados por la aplicación objetivo @Dolstra2006. Esta distinción surge de la naturaleza misma de la ejecución de programas: para que un programa se ejecute, su código fuente debe traducirse a instrucciones binarias que el procesador pueda interpretar, proceso que incluye una fase de enlazado o _linking_, en la cual se resuelven las referencias que el programa hace a funciones y variables definidas en otros paquetes @beazleyStorySharedLibraries2001. Esta fase es especialmente visible en lenguajes como `C`, aunque el _linking_ también está presente en otros lenguajes compilados e interpretados; en estos últimos, sin embargo, la resolución ocurre en tiempo de ejecución, a cargo del intérprete, en lugar de quedar fijada de antemano en el ejecutable. Según el momento en que ocurre esta resolución, los paquetes que actúan como bibliotecas se clasifican en estáticos o dinámicos.

==== Librerías estáticas

La opción más sencilla para que un ejecutable tenga acceso a las funcionalidades de una librería es copiar  el contenido de la librería en el código fuente, a las librerías que son referenciadas de esta forma se les conoce como *estáticas*, debido a que una vez referenciadas, su código no cambia a menos que se compile nuevamente @roucariesStaticLinkingPitfalls2025. 

En el caso de `C`, el proceso se hace evidente al traducir cada archivo fuente en un archivo objeto (_object file_ `.o`), estos artefactos cuentan dentro de sí con una tabla de símbolos de librerías externas pendiente por resolver. Es necesario resolver estos simbolos para producir el ejecutable, y es en este punto donde se copian los contenidos de las librerías estáticas @beazleyStorySharedLibraries2001.

El _linker_ toma el ejecutable en construcción, identifica los símbolos que aún no están definidos y copia dentro del binario final únicamente las definiciones que son mencionadas en el código fuente @usenixassociation1986SummerUSENIX1986. El resultado es un ejecutable autocontenido, que no depende de que la biblioteca esté presente en la computadora donde se ejecuta @beazleyStorySharedLibraries2001.

Esta característica trae ventajas y desventajas. Viendo lo positivo, *produce binarios portables y con un comportamiento predecible*, ya que no existe la posibilidad de que, se utilice código diferente al probado por el desarrollador y evita la sobrecarga de resolver símbolos cada vez que el programa se ejecuta @beazleyStorySharedLibraries2001. Esta característica los hace sencillos de distribuir, porque su instalación se límita a copiar los ejecutables en la computadora destino #footnote[En realidad el proceso, puede involucrar otras actividad como la configuración de variables de entorno y creación de archivos de configuración, pero pueden considerarse triviales comparado a la resolución de dependencias @Dolstra2006].

Por otro lado, cada ejecutable que usa la misma biblioteca contiene su propia copia del código, lo que incrementa el tamaño en disco y el consumo de memoria cuando varios programas la usan simultáneamente @usenixassociation1986SummerUSENIX1986; también obliga a recompilar y redistribuir cada ejecutable ante cualquier actualización o corrección de la biblioteca, incluidos parches de seguridad @beazleyStorySharedLibraries2001.

==== Librerías dinámicas
Cómo respuesta a los pesados binarios del enlazado estático ¿Qué tal si en vez de copiar el código solo indicamos en que archivo encontrarlo? Así muchos ejecutables podrían "compartir" las funcionalidades de la librería sin duplicarla, hemos descubierto el *enlazado dinámico* @usenixassociation1986SummerUSENIX1986.

Las *bibliotecas dinámicas* (o compartidas, _shared libraries_; `.so` en Unix, `.dll` en Windows, `.dylib` en macOS) posponen la resolución de símbolos hasta la ejecución o, incluso, hasta la primera vez que la función es invocada (_lazy binding_) @beazleyStorySharedLibraries2001. En lugar de copiar el código de la biblioteca dentro de cada ejecutable, el binario final solo almacena una referencia a ella; es el cargador dinámico del sistema operativo (_dynamic loader_) quien, al iniciar el programa, localiza la biblioteca en el sistema, la mapea en el espacio de memoria del proceso y completa las referencias pendientes mediante tablas de relocalización y código independiente de posición (_Position Independent Code_, PIC) @beazleyStorySharedLibraries2001.

Esta solución ofrece ciertos beneficios: El sistema operativo puede mantener una única copia de la biblioteca en memoria física y compartirla entre todos los procesos que la usan, reduciendo el consumo de RAM y el tamaño de los ejecutables en disco; además, una biblioteca puede corregirse o actualizarse sin necesidad de recompilar las aplicaciones que la consumen, siempre que se preserve su interfaz @roucariesStaticLinkingPitfalls2025. 

Esta misma flexibilidad introduce el problema opuesto al de las bibliotecas estáticas: la aplicación depende de que, la computadora donde se ejecute, exista una versión de la biblioteca compatible con la que se usó al compilarla, situación que puede derivar en conflictos cuando distintas aplicaciones del mismo sistema requieren versiones incompatibles entre sí @roucariesStaticLinkingPitfalls2025, como se ilustró previamente en la @figura1.

Las clasificaciones desarrolladas no son las únicas: distintos ecosistemas introducen conceptos adicionales, como los paquetes _peer_ que introduce `npm` @Gibb2026.

== Manejadores de paquetes al rescate <manejadores_de_paquetes>

De las secciones anteriores debió quedar claro que instalar una aplicación junto con sus dependencias no es un problema trivial. Ante el auge en la disponibilidad y uso de paquetes descrito previamente, también ha surgido una plétora de herramientas orientadas a administrar la creciente complejidad derivada del tamaño de los proyectos.

=== Evolución y Taxonomía de los Modelos Existentes
A partir de mediados de la década de los 2000, se produjo lo que se ha descrito como una "explosión cámbrica" de soluciones , donde prácticamente cada sistema operativo y lenguaje de programación desarrolló su propio manejador de paquetes @Gibb2026; con el tiempo se fueron diferenciando bajo tres ejes principales:

1.  *Por el tipo de artefacto*
    -   *Manejadores binarios:* Descargan binarios precompilados de servidores centrales y los ubican en rutas específicas del sistema. Su ventaja es la velocidad, pero dependen de que el binario haya sido construido para una arquitectura y versión de sistema operativo exacta @Zwinger2026, ejemplos incluyen: `APT`, `RPM`, `Pacman`.
    -   *Manejadores basados en fuentes:* Copian el código fuente y producen los binarios localmente @Zwinger2026. Esto permite una personalización extrema y optimización para el hardware, pero a costa de tiempos de despliegue significativamente mayores @Dolstra2006, ejemplos incluyen `BSD Ports` o `Portage`.

2.  *Por el alcance del ecosistema*
    -   *Manejadores de sistema:* Administran el sistema operativo completo (p. ej., DNF para Red Hat, APT para Debian). Tienden a ser más conservadores, priorizando un conjunto de paquetes coordinado y coherente, lo que a menudo causa que las versiones de las librerías se retrasen respecto a las últimas novedades @Gibb2026.
    -   *Manejadores de lenguaje:* Distribuyen librerías para desarrolladores de lenguajes específicos (p. ej., pip para Python, Cargo para Rust, npm para JavaScript). Priorizan la frescura de las versiones, pero suelen ignorar las dependencias externas del sistema (como drivers o librerías de C), asumiendo que estas ya están presentes @Gibb2026.

3.  *Por la resolución de dependencias:* Dependiendo del tipo de algoritmo utilizado para resolver las dependencias necesarias, a menudo utilizando algoritmos _SAT solvers_ para encontrar las versiones compatible, un proceso que es inherentemente NP-completo. Manajadores como Nix evaden este problema permitiendo solo una versión válida @Dolstra2006.

=== El Problema de Fondo: El Paradigma Imperativo
A pesar de su utilidad, los modelos tradicionales comparten un defecto estructural: operan bajo un *paradigma de despliegue imperativo* . En este modelo, las acciones de instalación o actualización se realizan "en el lugar" (_in-place_), modificando destructivamente el estado del sistema operativo @Courts2013. Esta mutación del entorno global conlleva problemas críticos que limitan la fiabilidad del _software_:

-   *Conflictos de dependencias ("Dependency Hell"):* Al intentar satisfacer a múltiples aplicaciones en un entorno global único, surge el problema del "diamante de dependencias". Si la aplicación A requiere la versión 1.0 de una librería y la aplicación B requiere la 2.0, el sistema se ve forzado a elegir una sola, rompiendo potencialmente la otra aplicación @Zwinger2026.
-   *Falta de Reproducibilidad:* Debido a que el proceso de construcción suele tener acceso a todo el _software_ instalado en la máquina (entradas no declaradas), es común que un paquete se compile correctamente en una computadora pero falle en otra debido a sutiles diferencias en el entorno @Courts2013.
-   *Actualizaciones destructivas y falta de reversión:* Dado que las actualizaciones sobrescriben archivos existentes, si un proceso falla a mitad de camino o la nueva versión es inestable, el sistema puede quedar en un estado inconsistente. No suele haber una forma sencilla de realizar un *rollback* atómico al estado anterior @Dolstra2006.
-   *Fragmentación de herramientas:* Los proyectos multilingües modernos se ven obligados a coordinar múltiples manejadores de paquetes _ad-hoc_ (p. ej., usar Cargo, pip y APT simultáneamente), lo que oculta vulnerabilidades de seguridad y dificulta el despliegue portátil @Gibb2026.

== La Virtualización es la solución... o no
En paralelo al nacimiento y evolución de los manejadores de paquetes, en otra rama crecía una alternativa: la virtualización. Esta nació para compartir los recursos de hardware de una misma máquina entre varios usuarios @kozirisFiftyYearsEvolution2015, pero con la llegada de la Nube demostró ser un medio ideal para desplegar software de forma reproducible @Sobieraj2024.

Docker fue la herramienta que popularizó la virtualización como forma de empaquetar (o "contenerizar") aplicaciones. Su idea es sencilla: en vez de simular una computadora entera, los contenedores se ejecutan directamente sobre el sistema anfitrión, y es el propio kernel el que le da a cada proceso la ilusión de estar solo en su propia computadora. Para ello se apoya en dos mecanismos de Linux: los _namespaces_, que restringen lo que un proceso puede ver (procesos, sistema de archivos, red y usuarios), y los _cgroups_, que restringen cuánto puede usar (CPU, memoria, disco) @Sobieraj2024. Por eso un contenedor arranca mucho más rápido que una máquina virtual @Lingayat2018.

Esta virtualización ligera dio paso a un nuevo modelo de empaquetado: distribuir la aplicación junto con el ambiente completo en el que debe ejecutarse, llamandolos \"contenedores\". Para no duplicar ese ambiente Docker introduce el concepto de \"imagenes\" como sistemas de archivos por capas, donde cada capa representa un cambio en el sistema de archivos de tal manera que si dos contenedores realizan los mismos cambios , esa capa se puede compartir entre varios contenedores @UnderstandingImageLayers.

Una capa solo se reutiliza si es idéntica, y como cada una se construye sobre las anteriores, modificar una instrucción invalida esa capa y todas las siguientes. Así, dos imágenes que instalan la misma librería sobre bases distintas terminan guardando copias separadas de los mismos archivos, lo que en la práctica llena los registros de imágenes de datos duplicados @zhaoEndtoendHighperformanceDeduplication2024a. De igual forma, aunque los contenedores son más ligeros que una máquina virtual, siguen teniendo un costo de rendimiento frente a la ejecución nativa @Giallorenzo2021, que se agrava en Windows y macOS, donde Docker necesita una máquina virtual de Linux para funcionar @Sobieraj2024.

== Nix como solución
La disyuntiva tradicional obligaba a elegir entre manejadores que arriesgan conflictos en el entorno global o soluciones de virtualización (contenedores) que evitan conflictos duplicando entornos completos a costa de almacenamiento y memoria, como se ve en la @figura1 con `Programa 1` y `Programa 2` dependiendo de `FOO`. 

#figure(image("media/figures/Figure5.svg", width: 90%), caption: [
  Peores casos de resolución de dependencias en a) los modelos de manejadores de paquetes y b) virtualización.
])<figura5>

En este contexto surge *Nix*, que propone una tercera vía: un *modelo de despliegue puramente funcional*, construir un paquete debería ser como una función pura: dados las mismas entradas debería devolver siempre las mismas salidas. Lo logra al fusionar la eficiencia de los manejadores de paquetes con el aislamiento de la virtualización,  @Dolstra2006.


=== Como lo soluciona

Nix resuelve ambos problemas de manejadores de paquetes y virtualización a la vez mediante el mismo mecanismo: *los hashes*, si cada paquete recibiera un nombre único tener dos versiones de una librería sería posible porque a ojos de la computadora son 2 programas diferentes; también se eliminaría el problema de la duplicación, porque los identificadores únicos permiten saber si 2 paquetes dependen de la misma exacta dependencia, y compartirla. Esos nombres únicos son hashes que nix agrega como prefijos a todo recurso, así que ejecutable en vez de llamarse `firefox` se llamaría `wkgaavd2hzy9kmw0z30a8yxw796nfhx5-firefox` @Dolstra2006.

Sin embargo, los hashes solo son fiables si el sistema asegura que sean reproducibles, es decir dado siempre el mismo paquete e instrucciones se le asigne el mismo hash, sin importar en la computadora donde es ejecutado. Es ahí donde para nix cobra sentido adoptar un modelo funcional, porque busca resolver un problema muy parecido con las funciones puras. El resto de esta sección detalla los mecanismos que hacen esto posible, así como el lenguaje mediante el cual se describen.

=== Implementación
Para permitir resolver las falencias de los manejadores de paquetes y la virtualización, el modelo de Nix , propuesto por Dolstra @Dolstra2006, introduce sus propios componentes que son resumidos en la @figura6: Todo empieza con un archivo en *Nixlang*, al ser evaluado se produce una archivo de *derivacion* `.drv` con las instrucciones exactas de como construir lo que solicita el usuario para un sistema especifico.

La derivación es guardada en un espació común conocido como la *Nix Store*, nix solo interactua con cosas presentes en la Nix Store para reducir efectos inesperados, así que si no cuenta con un recurso, primero lo descarga y coloca aquí. Es en este proceso donde al recurso se le asigna el *hash* mencionado anteriormente.
  
Una vez se cuentan con los recursos necesarios, nix construye el paquete en ambientes aislados por medio de una virtualización ligera para asegurar la reproducibilidad. Todo lo anterior mencionado es orquestado por el *Nix Daemon.*

#figure(image("media/figures/Figure6.svg", width: 100%), caption: [
  Diagrama simplificado de los componentes principales de Nix.
])<figura6>

Como se puede ver, todos los mecanismos de nix estan orientados a una misma meta: maximizar la reproducibilidad, porque al seguir los mismos pasos bajo el mismo ambiente y condiciones, debe llevar al mismo resultado. La secciones de abajo buscan explicar un poco mejor como cada parte lo logra.

==== Derivaciones
Para construir un paquete, es necesario una receta detallada de como construirlo, a esas recetas nix les llama *derivaciones*. En concreto una derivación es un archivo `.drv` con una específicación detallada para construir un paquete en un sistema especifico (arquitectura y sistema operativo); especificando mediente que programa se debe construir (_builder_), con que argumentos y variables de entorno y de que otras derivaciones depende, así es, las dependencias son representadas por derivaciones, no paquetes, de esta manera si no se cuenta con el paquete pero si con las derivación se puede construir localmente @Dolstra2006.

Estas recetas se puede ver como funciones puras (@figura7), *los parámetros* son todas las cosas que nuestro paquete necesita para construirse y correrse, *el cuerpo* contiene las instrucciones en `bash` para construir el paquete, y la *salida* es el paquete junto con el hash único que lo identifica y que discutiremos como se computa a continuación.

#figure(image("media/figures/Figure7.svg", width: 70%), caption: [
  Comparación visual de las derivaciones con las funciones puras.
])<figura7>

==== Hashes
Considerando que el modelo de nix trabaja alrededor de derivaciones, y que cada derivación es como una función pura, produciendo la misma salida dados los mismos parámetros, computar un identificador único para cada paquete es relativamente sencillo: basta con hacer un hash criptográfico de la combinación de todos los parámetros utilizados : código fuente, dependencias, banderas de compilación y el propio script de construcción @Dolstra2006. Como el hash depende exclusivamente de esos insumos, dos construcciones con los mismos insumos producen exactamente el mismo hash y, por tanto, el mismo paquete, sin importar en qué máquina se ejecuten; esta propiedad es la que permite sustituir binarios ya construidos entre computadoras distintas, y ha sido validada empíricamente reconstruyendo más de 700 mil paquetes de Nixpkgs con tasas de reproducibilidad binaria de entre 69% y 91% @Malka2025. 

Modificar cualquier insumo —incluida una dependencia transitiva— cambia, el hash resultante y con él el paquete, de modo que la noción de versionado semántico no existe realmente en nix, pudiendo existir varios `node-22` por usar parámetros ligeramente diferentes.

==== Ambientes aislados
Nix ejecuta cada construcción dentro de un ambiente aislado que restringe el sistema de archivos visible a únicamente las rutas del store declaradas como insumos, y deshabilita el acceso a la red salvo que la derivación lo declare explícitamente @Dolstra2006. Esta forma de virtualización, más ligera que la de una máquina o un contenedor completo, impide que dependencias no declaradas del sistema anfitrión —una biblioteca instalada globalmente, una variable de entorno, un archivo de configuración— se filtren silenciosamente en el resultado de la construcción, condición necesaria para que el hash calculado sea reproducible en cualquier otra máquina @Dolstra2006 @Malka2025.

==== Nix Store
Incluso si todos los componentes anteriores producen paquetes reproducibles, nada evita que un usuario o proceso los sobreescriba sin actualizar el hash, llevando a un estado ilegal donde el hash ya no es el identificador de los contenidos a los que acompaña. Para evitar manipulación externa, cualquier recurso con el que nix interactua es copiado en un directorio de solo lectura llamado la *Nix Store*. Cualquier contenido dentro de la Nix Store es inmutable y cualquier inserción o eliminación se hace por medio de solicitudes al *Nix Daemon* @Dolstra2006. 

Es aquí donde el hash descrito antes es usado, al ser el prefijo del nombre de cualquier archivo y carpeta dentro de la store, identificando de forma unequivoca su contenido (@figura6) lo que permite que Nix trate al sistema operativo completo, en el caso de NixOS, como una colección de artefactos versionados dentro de esta misma estructura @Dolstra2008.


==== Nixlang

Nixlang es, en última instancia, un medio declarativo para describir y componer derivaciones: cualquier expresión Nix se evalúa hasta producir una o más derivaciones, que Nix evalua para obtener las rutas de salida correspondientes en el store @Dolstra2006. Es un lenguaje de dominio específico funcional y de evaluación perezosa, con tipado dinámico y una sintaxis descrita en ocasiones como JSON con funciones @NixdevDocumentation. Estos dos últimos rasgos —el paradigma funcional y la evaluación perezosa— emergen, como respuesta al diseño funcional de las derivaciones.

En la actualidad se ha popularizado el uso de los Flakes @2025CommunitySurvey, una formato estructurado para escribir con NixLang que ofrecen ventajas al agregar más salvaguardas para preservar el determinismo @NixdevDocumentation.

Antes de examinar cómo estas propiedades inciden en la usabilidad de Nixlang, conviene precisar qué significan en términos de teoría de lenguajes de programación.

== Fundamentos de lenguajes de programación

Esta sección introduce tres nociones de diseño de lenguajes —el contraste entre paradigma imperativo y funcional, la evaluación perezosa y la noción de lenguaje de dominio específico— que sirven de base conceptual para analizar tanto Nixlang como el eDSL propuesto en este trabajo.

=== Imperativo vs. funcional

// TODO:
En un lenguaje imperativo, un programa es una secuencia de instrucciones que modifican explícitamente el estado de la máquina —variables, registros, archivos— mediante asignaciones y efectos secundarios; es el modelo que siguen la mayoría de los lenguajes de propósito general (`C`, Python, JavaScript) y el que, según Dolstra @Dolstra2008, comparten los manejadores de paquetes y las herramientas de gestión de configuración tradicionales, cuyas actualizaciones sobrescriben destructivamente el estado del sistema. En un lenguaje funcional, en cambio, un programa se construye componiendo funciones matemáticas puras sobre valores inmutables: dada la misma entrada, una función siempre produce la misma salida, sin alterar ningún estado externo, propiedad conocida como transparencia referencial @Hudak1989. Es precisamente esta noción, trasladada del diseño de lenguajes al despliegue de _software_, la que origina el modelo de Nix descrito en la sección anterior: una derivación se comporta como una función pura, es por ello que el lenguaje para describirlas sigue esa misma disciplina.

=== Laziness

La evaluación perezosa (_lazy evaluation_) pospone el cómputo de una expresión hasta el momento en que su valor es efectivamente requerido, en contraste con la evaluación estricta (_eager_), que calcula cada expresión tan pronto como es posible @Hudak1989. Nixlang hereda esta propiedad de su linaje funcional: un atributo dentro de un archivo de configuración puede referenciar a otro definido más adelante, o incluso a sí mismo de forma indirecta, sin provocar un ciclo infinito, siempre que exista un punto fijo que Nix pueda resolver perezosamente @Dolstra2006. Esta característica habilita patrones extendidos en el ecosistema, como los _overlays_ que modifican paquetes ya definidos, pero también introduce un modelo mental —la ausencia de un orden de evaluación explícito— ajeno a la mayoría de los lenguajes imperativos con los que suelen familiarizarse primero los nuevos usuarios.

=== DSL & eDSL

Un *lenguaje de dominio específico* (DSL, por sus siglas en inglés) es un lenguaje diseñado para un dominio de aplicación particular que, a cambio de renunciar a la generalidad de un lenguaje de propósito general (GPL), ofrece en teoría mayor expresividad y facilidad de uso dentro de ese dominio @Mernik2005 @vandeursenDomainspecificLanguagesAnnotated2000; Nixlang, orientado exclusivamente a describir derivaciones, es un ejemplo de ello. Un *lenguaje de dominio específico embebido* (eDSL, por sus siglas enn inglés) persigue el mismo objetivo, pero en lugar de implementarse desde cero reutiliza la sintaxis, el analizador y el ecosistema de herramientas de un lenguaje anfitrión de propósito general @berzakEmbeddedDomainSpecific. GNU Guix ilustra este enfoque dentro del propio linaje de Nix: en vez de un lenguaje propio, describe sus paquetes mediante un eDSL sobre Scheme, heredando así el resto del lenguaje anfitrión sin comprometer la expresividad del dominio @Courts2013.

La promesa de un DSL o eDSL —mayor expresividad y facilidad de uso— es, sin embargo, una afirmación empírica y no una garantía de diseño; determinar si se cumple requiere instrumentos capaces de medir la usabilidad de un lenguaje, tema que se desarrolla en la siguiente sección.

== Usabilidad en lenguajes de programación

=== Cómo se mide en la actualidad

La usabilidad de un lenguaje de programación no se demuestra por argumento de diseño, sino que se mide: la funcionalidad de una herramienta no garantiza que sea utilizable, ni siquiera que llegue a usarse @goodwinFunctionalityUsability1987. Bajo la premisa de que los programadores son, ante todo, usuarios de sus herramientas @Myers2016a, la literatura adapta métodos propios de la interacción humano-computadora para evaluarlos empíricamente: experimentos controlados que comparan directamente el efecto de una característica del lenguaje sobre tareas de mantenimiento o comprensión, como el de Hanenberg et al. @hanenbergEmpiricalStudyImpact2013 sobre tipado estático; estudios de programación natural, que documentan cómo personas sin experiencia previa expresan intuitivamente una solución antes de aprender la sintaxis de un lenguaje @paneStudyingLanguageStructure2001 @panePDFMoreNatural2006; el protocolo de pensar en voz alta, que expone el razonamiento del usuario mientras resuelve una tarea @PDFThinkAloud; y marcos analíticos como las Dimensiones Cognitivas de las Notaciones, que descomponen un lenguaje en atributos evaluables y comparables entre sí @PDFCognitiveDimensions @mernikPDFComparisonXAML2009. A estos métodos centrados en la tarea se suma el campo de la Experiencia de Desarrollo (DX), que incorpora instrumentos de experiencia de usuario —como DEXI @Kuusinen2016— para capturar también la dimensión subjetiva de usar una herramienta, no solo su desempeño medible.

=== Los proyectos de código abierto ignoran estos aspectos

Esta caja de herramientas empíricas, sin embargo, rara vez se aplica dentro de los proyectos de código abierto. Nichols et al. @Nichols2001, en un estudio de usabilidad sobre un proyecto de _sofware_ de código abierto (OSS, por sus siglas en inglés), documentan que el propio proceso de desarrollo voluntariado de proyectos OSS tiende a relegar la usabilidad frente a la funcionalidad. Dos décadas después, Llerena et al. @Llerena2025 encuentran el mismo patrón: de tres proyectos OSS estudiados, ninguno adoptaba sistemáticamente técnicas de evaluación de usabilidad, obstaculizados en buena medida por la escasa participación de usuarios finales en el proceso. Leroux @Leroux2019 atribuye parte de esta brecha a una cuestión de poder dentro de las comunidades OSS: quienes practican la usabilidad rara vez tienen la autoridad —o el mandato— para imponer cambios sobre el diseño técnico del proyecto. Nix, desarrollado y mantenido bajo este mismo modelo, no es la excepción: los problemas de documentación, errores y curva de aprendizaje han estado presente a lo largo de encuestas de comunidada a lo largo de los últimos años   #cite-range( "2022NixSurvey2022", "2025CommunitySurvey", "NixCommunitySurvey2023", "NixCommunitySurvey2024") con la ausencia de una práctica sistemática de evaluación de usabilidad, más que con una limitación inherente al enfoque puramente funcional.

=== Metodología para medir la usabilidad en lenguajes

Comparar la usabilidad de dos lenguajes exige combinar más de uno de estos métodos: una fase exploratoria y cualitativa, que identifique los problemas específicos de un lenguaje antes de proponer una alternativa, mediante pensar en voz alta y programación natural @PDFThinkAloud @paneStudyingLanguageStructure2001; y una fase comparativa y cuantitativa, que contraste el lenguaje original contra la alternativa propuesta bajo condiciones controladas. Para esta última, Mernik et al. han adaptado el marco de Dimensiones Cognitivas específicamente a la comparación de lenguajes y notaciones @mernikPDFComparisonXAML2009, mientras que el marco Usa-DSL extiende esa misma lógica al caso particular de los DSL @Poltronieri2018; ambos se complementan con instrumentos de experiencia de usuario y de desarrollo —AttrakDiff @PDFNeedsAffect, DEXI @Kuusinen2016— para capturar la dimensión subjetiva que las métricas de desempeño, por sí solas, no reflejan. Esta combinación de métodos es la que se aplica en la metodología de este trabajo.

= Metodología

La investigación se dividió en tres fases ejecutadas de forma secuencial, con el
objetivo de desarrollar y evaluar un lenguaje de dominio específico embebido
(eDSL, por sus siglas en inglés) en TypeScript como alternativa al lenguaje de
configuración original de Nix (en adelante, Nixlang), @figura10 sintetiza lo ya dicho.

#figure(image("media/figures/Figure10.svg", width: 100%), caption: [
  Diagrama de las fases que comprende la metodología.
])<figura10>

== Confidencialidad
Todas las fases que involucraron participantes humanos se sometieron a un proceso ético con las siguientes características:
- *Participación voluntaria*: La participación fue completamente voluntaria. Los
  participantes podían retirarse en cualquier momento sin consecuencia alguna.
- *Mayoría de edad*: Todos los participantes debían ser mayores de 18 años.
- *Riesgos*: La participación conllevó riesgos mínimos. Los participantes podían
  experimentar leve fatiga cognitiva o incomodidad al verbalizar su razonamiento
  durante las tareas. Para minimizarlos, las sesiones tuvieron una duración acotada
  y el participante podía solicitar pausas en cualquier momento.
- *Anonimización:* Los datos recolectados fueron disociados de la identidad de los participantes mediante el uso de códigos de identificación internos. Ningún dato publicado o analizado contiene información que permita identificar a los participantes. Las transcripciones de los fragmentos verbales citados en el análisis fueron igualmente anonimizadas.
- *Responsable del resguardo de datos*: El autor principal de este estudio.
- *Compensación*: Como agradecimiento por su tiempo, los participantes recibieron
  una compensación simbólica en forma de un caramelo al finalizar la sesión. Esta
  compensación no condicionó la participación ni sus respuestas.
Antes de empezar, todos los participantes leyeron y firmaron un
*Consentimiento Informado* (plantilla en @Appenddix3) en el cual el equipo investigador se comprometió a
cumplir los puntos anteriores.

=== Reclutamiento de Participantes
El reclutamiento se realizó mediante visitas a las aulas de estudiantes de quinto año. El investigador presentó el estudio e invitó a participar de forma voluntaria. Los investigadores no tenían relación docente ni de autoridad con los participantes. La participación o no participación no afectó las calificaciones, evaluaciones, situación académica, relación con docentes ni el acceso a servicios o beneficios institucionales.


=== Codificación de participantes

A cada participante se le asignó un código con el formato `PXX` (por ejemplo, P01, P02 o P03), el cual fue utilizado para identificar toda la información recolectada durante el estudio. Se mantuvo una tabla de correspondencia entre los códigos y la identidad de los participantes, accesible únicamente al investigador, la cual sería eliminada de forma permanente una vez finalizada la recolección de datos de la Fase 3.

=== Almacenamiento y Eliminación de Datos

Toda la información recopilada durante este estudio fue tratada de forma confidencial. Los datos fueron inicialmente identificados mediante un código asignado a cada participante en una tabla de correspondencia con su identidad y *se almacenaron en una computadora protegida por contraseña, con acceso restringido al investigador; la tabla sería eliminada al finalizar la recolección de datos en la fase 3*.

En la fase 1, las grabaciones de voz, pantalla y sus transcripciones serán almacenadas en la computadora mencionada. En la fase 2, las respuestas de los cuestionarios fueron almacenadas temporalmente en un servidor de Amazon Web Services (AWS) y posteriormente transferidas a la computadora del investigador. Dado que los cuestionarios no recopilaban información que permitiera identificar a los participantes, el almacenamiento temporal de las respuestas no representó un riesgo significativo para su privacidad. Una vez finalizada la recolección de datos se eliminaría la tabla de correspondencia y la información utilizada para el análisis y la presentación de resultados sería anonimizada.

Todas las grabaciones, independientemente de la fase del estudio o de la plataforma en la que se almacenaron, se conservarían durante un máximo de *cuatro semanas* después de finalizada la recolección de datos y serían eliminadas al concluir ese período. La información anonimizada, incluidas las transcripciones y los datos derivados del proceso de recolección, se conservaría durante *16 semanas* para su análisis. La eliminación de todos los archivos quedó a cargo del investigador al finalizar los períodos de conservación correspondientes.

=== Medidas de Privacidad durante las grabaciones

Durante la fase 1 de investigación, se grabaron la pantalla y las voces de los participantes durante la actividad, para evitar la captura accidental de información personal los participantes trabajaron en una computadora entregada por el investigador con las aplicaciones necesarias para el ejercicio, y solo podían acceder a internet desde sesiones en modo incógnito y sin permiso para acceder a cuentas personales.

En la fase 2, los participantes accedieron al cuestionario web mediante un usuario y contraseña asignados por el investigador. 

\
== Fase 1: Investigación preliminar <phase1>
El propósito de la primera fase fue identificar los puntos de dolor que tiene Nixlang, como base para construir una solución que los redujera, a través de un estudio cualitativo exploratorio.

=== Población y muestra

Se seleccionaron estudiantes de Ciencias de la Computación de entre 18 y 24 años con experiencia limitada o nula en Nix y en el empaquetado de aplicaciones. Esta población fue elegida porque, según la encuesta más reciente de la comunidad Nix , representa el segundo grupo de usuarios más numeroso por edad (29.8%)@NixCommunitySurvey2024. Además, su perfil principiante permitió evaluar las barreras de aprendizaje y los desafíos de usabilidad de Nixlang durante las etapas iniciales de adopción.

Se usó una muestra de N=10 participantes, fundamentada en dos precedentes: un estudio pensar-en-alto sobre la experiencia de incorporación en Nix @fricklerhandwerk2022, que empleó la misma metodología con usuarios principiantes y produjo hallazgos relevantes sobre usabilidad de documentación, y un estudio de programación natural @paneStudyingLanguageStructure2001 que utilizó N = 14 para examinar cómo usuarios sin experiencia previa abordan tareas de programación; otro meta estudio sugiere N=10 para investigaciones de este tipo (saturación de relevancia en evaluaciones de usabilidad) @wutichSampleSizes102024. Dado el carácter exploratorio y cualitativo de esta fase, dicho tamaño muestral se consideró apropiado, sin pretensiones de generalización estadística.

=== Instrumentos
Durante esta fase se usaron tres instrumentos para recopilar cual es la intuición natural de como un lenguaje para manejo de paquetes debería ser, seguido de su experiencia con NixLang:

- *Formulario de perfil*: Recogió datos sobre la experiencia previa del
  participante con herramientas de gestión de paquetes y lenguajes de
  programación, así como su edad y semestre cursado.
- *Formulario de programación natural*: Disponible en la @Appenddix3, presentó al participante una serie de
  problemas relacionados con el dominio del empaquetado de aplicaciones,
  solicitándole que describiera con sus propias palabras un algoritmo para
  resolverlos. Se basó en la técnica de Programación Natural
  @panePDFMoreNatural2006, y se entregó de forma impresa junto con hojas en
  blanco para que el participante respondiera libremente.
- *Guía de actividades de pensar en alto*: Disponible en la @Appenddix3, Conjunto de tareas a resolver con
  Nixlang, siguiendo el protocolo de pensar en alto @PDFThinkAloud.

=== Procedimiento

Antes de iniciar la sesión, el participante leyó y firmó el consentimiento
informado y completó el formulario de perfil.

A continuación, se entregó el formulario de programación natural de forma
impresa. Esta actividad se realizó antes de presentar cualquier material sobre
Nixlang, con el propósito de capturar la intuición natural del participante sin
sesgo previo de exposición al lenguaje.

Por último, se inició la sesión de pensar en alto utilizando una computadora
provista por el investigador. El participante verbalizó su proceso de
pensamiento mientras resolvía las tareas propuestas en Nixlang. Durante esta
sesión se grabaron la pantalla y el audio, previa autorización explícita en el
consentimiento informado. Si el usuario necesitaba información de Nix, podía buscarla en internet, siempre que no utilizara asistentes de Inteligencia Artificial.

=== Análisis de datos

Los datos recolectados se analizaron con los siguientes objetivos: caracterizar el
perfil de los participantes, identificar patrones en sus respuestas de
programación natural, y categorizar los puntos de dolor cognitivos observados
durante las sesiones de pensar en alto. 

Las respuestas dadas para la encuesta de programacion natural fueron procesadas para crear archivos de código ficticio que contuvieran las características compartidas por cada participante, esto homogenizaba las respuestas y facilitaba la comparación de caracteristicas entre participantes.

Para las entrevistas los usuarios se analizaron las grabaciones y anotaron los puntos de dolor mencionados.Los fragmentos verbales más representativos fueron citados de forma textual en el análisis, con previa
anonimización. Los hallazgos de esta fase orientaron el diseño del eDSL en la
Fase 2.

\
== Fase 2: Desarrollo del eDSL
Antes de definir el enfoque, se revisaron los proyectos con los que la comunidad ha buscado mejorar la usabilidad de Nixlang (véase @Appendix1). La revisión mostró que estas soluciones tienden a introducir nuevas fuentes de complejidad o a depender de factores externos, sin atender las causas estructurales de la fricción del lenguaje. Por ello, se optó por interactuar con Nix desde un lenguaje tipado y ampliamente conocido: TypeScript. Se eligió por su popularidad @stackoverflowMostPopularTechnologies y por su cercanía sintáctica con Nixlang, al que la documentación oficial describe como "JSON con funciones" @NixdevDocumentation.

El resultado fue *Nixty* @rayoNixtyGenerateNix2026 un eDSL cuya interfaz se diseñó para atender directamente los puntos de dolor identificados en la Fase 1 y que cubre la gran mayoría las funcionalidades de la biblioteca estándar de Nix (_builtins_, por su nombre en inglés), junto con una batería de pruebas. Para facilitar su instalación durante la Fase 3, Nixty se publicó en el registro de `npm` bajo la licencia MIT @MITLicense. Esta fase no involucró participantes humanos.

\
== Fase 3: Evaluación comparativa
La Fase 3 adoptó un estudio cuantitativo basado en la ingeniería de _software_ empírica
propuesto por @mernikPDFComparisonXAML2009, adaptado al contexto de
comparación entre un DSL (Nixlang) y un eDSL (Nixty) en TypeScript. La fase se estructuró en dos partes: una evaluación de comprensión cognitiva mediante un cuestionario estructurado, y una evaluación de experiencia de desarrollo mediante instrumentos de Experiencia de Usuario.


=== Población y muestra

Se reclutaron participantes con el mismo perfil que la Fase 1 (@phase1): estudiantes de Ciencias de la Computación con escasa o nula experiencia en Nix. Se permitió la participación de sujetos que hubiesen tomado parte en la Fase 1, considerando que el diseño de la solución se baso en sus respuestas. Ambas fases fueron separadas por un período de 3 meses y las fueron fueron diseñadas de forma independiente, minimizando así posibles efectos de aprendizaje directo de Nix.

Se usó una muestra de N = 20, obtenida mediante un análisis de potencia realizado en G*Power @GPower para diseños intra-sujetos comparando medias, asumiendo un tamaño de efecto grande (dz = 0.8, α = 0.05, potencia = 0.90), el cual arrojó un mínimo de 19 participantes, redondeado a 20. Los resultados deben interpretarse en consecuencia y replicarse en trabajos futuros con muestras de mayor tamaño.

=== Instrumentos

Se usaron 4 instrumentos combinados para recopilar información sobre los participantes, exponerlos a NixLang y Nixty (el eDSL desarrollado) y saber su experiencia de uso con ambas herramientas.

- *Formulario de perfil*: Incluyó una autoevaluación del nivel general de programación, experiencia en TypeScript y
  familiaridad previa con DSLs.
- *Manuales de Nixlang y eDSL*: Presenta el contexto general (
  empaquetado de aplicaciones y Nix), seguido de la sintaxis de Nixlang y Nixty, con ejemplos
  representativos, una copia se puede encontrar en @rayoNixEveryoneRepository en `survey_phase3/manuals`.
- *Cuestionarios de comprensión cognitiva*: Disponible en la @Appendix4, fue un instrumento estructurado con
  19 preguntas por lenguaje: 16 de selección múltiple y 3 de programación libre, que evaluaron el uso de Nixlang y Nixty en tres categorías de entendimiento de programación @mernikPDFComparisonXAML2009:

  - *Aprendizaje (6 preguntas)*: Selección de declaraciones sintácticamente correctas y
    programas válidos para un resultado dado.
  - *Percepción (10 preguntas)*: Identificación de constructos del lenguaje y
    significados correctos de programas.
  - *Evolución (3 preguntas)*: Preguntas de tipo ensayo donde se solicitó al
    participante expandir, eliminar o modificar la funcionalidad de código
    existente.
  
  A su vez en la sección de *Aprendizaje* y *Percepción* las preguntas se presentaron en pares de dificultad, que evaluaban el mismo concepto pero en dificultad fácil y díficil, dando origen a la notación `PP5-1` (fácil) y `PP5-2` (díficil) donde el último número representaba su difícultad.

- *Encuesta de Satisfacción*: Disponible en la @Appendix4 Instrumento para medir la experiencia de los usuarios, fusionó 3 pruebas estandarizadas: OUX (Evaluación general de experiencia de usuario) @Kuusinen2016, AttrakDiff-2 corto @PDFNeedsAffect y DEXI (Índice de Experiencia de Desarrollo) @Kuusinen2016.




=== Diseño experimental

Se empleó un diseño intra-sujetos en el que cada participante interactuó con ambas herramientas: Nixlang y el eDSL desarrollado. El orden de presentación fue contrabalanceado, de modo que la mitad de los participantes comenzó con Nixlang y la otra mitad con el eDSL, con el fin de controlar posibles efectos de orden. Cada herramienta fue evaluada en una sesión independiente a travez de una versión web de los formularios (código fuente en @rayoNixEveryoneRepository), pudiendo realizarse en días distintos, con el fin de adaptarse a la disponibilidad de los participantes. Se le permitio a los participantes saltar las preguntas díficiles.

=== Procedimiento

Al inicio de cada sesión, el participante firmó el consentimiento informado si era su primera sesión, o confirmó su continuidad si era la segunda, y completó el formulario de perfil correspondiente. A continuación, se le presentó el tutorial de la herramienta asignada para esa sesión. Una vez revisado el material, el participante respondió el cuestionario de comprensión cognitiva. Inmediatamente al finalizar, completó la encuesta de satisfacción evaluando su experiencia con dicha herramienta. Este procedimiento se repitió de forma idéntica en la sesión correspondiente a la segunda herramienta, que el participante puede iniciar inmediatamente.

=== Métricas y análisis de datos

De esta tercera fase se buscó recopilar 2 categorías de métricas: de rendimiento de los usuarios en cada herramienta (obtenido con el cuestionario de Comprensión Cognitiva), y su experiencia de desarrollo (obtenido de la encuesta de satisfacción).

==== Rendimiento

Las preguntas de selección múltiple se calificaron como correctas o incorrectas con 1 y 0, respectivamente. Los ejercicios de programación libre de Evolución fueron calificados por el investigador con el mismo criterio binario. Con ello se calculó la tasa de éxito de cada participante en cada categoría: Aprendizaje ($P_1$–$P_3$), Percepción ($P_4$–$P_8$) y Evolución ($P_9$–$P_(11)$) @mernikPDFComparisonXAML2009.

Además, cada pregunta se relacionó con las 13 Dimensiones Cognitivas @PDFCognitiveDimensions:

- *Cercanía de mapeo*: los lenguajes deben ser específicos para la tarea.
- *Viscosidad*: las revisiones deben ser sencillas.
- *Dependencias ocultas*: las consecuencias de los cambios deben ser claras.
- *Operaciones mentales difíciles*: no se permite nada enigmático.
- *Anticipación impuesta*: sin compromisos prematuros.
- *Notación secundaria*: permitir incluir información adicional.
- *Visibilidad*: los recorridos de búsqueda deben ser cortos.
- *Consistencia*: no se deben romper las expectativas del usuario.
- *Difusión*: el lenguaje no debe ser demasiado verboso.
- *Propensión a errores*: la notación debe detectar las equivocaciones para evitar errores.
- *Evaluación progresiva*: obtener retroalimentación inmediata.
- *Expresividad de rol*: ver claramente las relaciones entre los componentes.
- *Gradiente de abstracción*: los lenguajes deben permitir distintos niveles de abstracción.

Las relaciones entre preguntas y dimensiones (@cuadro1) son las mismas que usaron Mernik et al. @mernikPDFComparisonXAML2009, ya que el cuestionario tiene los mismos tipos de preguntas, en el mismo orden, pero adaptadas al campo de NixLang y Nixty.

#figure(
  caption: [Dimensiones Cognitivas relacionadas a cada pregunta @mernikPDFComparisonXAML2009. `1` indica que están relacionadas y `0` que no.],
  table(
    columns: 12,
    inset: (x: 4pt, y: 3pt),
    align: (left,) + (center,) * 11,
    table.header(
      [*Dimensión*], [*P1*], [*P2*], [*P3*], [*P4*], [*P5*], [*P6*], [*P7*], [*P8*], [*P9*], [*P10*], [*P11*],
    ),
    [Cercanía de mapeo],             [1], [1], [1], [1], [1], [1], [1], [1], [1], [1], [1],
    [Viscosidad],                    [0], [0], [0], [0], [0], [0], [0], [0], [1], [1], [1],
    [Dependencias ocultas],          [0], [0], [1], [1], [1], [1], [0], [1], [0], [1], [0],
    [Operaciones mentales difíciles], [0], [1], [1], [1], [1], [1], [1], [1], [0], [0], [0],
    [Anticipación impuesta],         [0], [0], [0], [0], [0], [0], [0], [0], [1], [0], [1],
    [Notación secundaria],           [0], [0], [0], [0], [0], [0], [0], [1], [0], [0], [0],
    [Visibilidad],                   [0], [0], [1], [1], [1], [1], [1], [1], [0], [0], [0],
    [Consistencia],                  [0], [0], [0], [0], [0], [1], [1], [0], [0], [0], [0],
    [Difusión],                      [1], [1], [1], [1], [1], [1], [1], [1], [1], [1], [1],
    [Propensión a errores],          [1], [1], [1], [1], [1], [1], [1], [1], [1], [1], [1],
    [Evaluación progresiva],         [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0],
    [Expresividad de rol],           [0], [1], [1], [1], [1], [1], [1], [1], [1], [1], [1],
    [Gradiente de abstracción],      [0], [0], [1], [1], [1], [1], [1], [1], [0], [0], [0],
  ),
)<cuadro1>

El puntaje de cada dimensión $i$ ($D_i$) se calculó con la fórmula de Mernik et al. @mernikPDFComparisonXAML2009:

  $ D_i = sum_(j=1)^(11) Q_(i j) dot frac(S_j, C_j) $

Donde $Q_(i j)$ indica si la dimensión $i$ está relacionada con la pregunta $j$ (@cuadro1), $C_j$ es el número de dimensiones relacionadas con la pregunta $j$ y $S_j$ es 1 si el participante respondió correctamente la pregunta $j$ y 0 si no. A diferencia de Mernik et al., que usaron como $S_j$ la tasa de éxito de todo el grupo, $D_i$ se calculó para cada participante y sesión, para poder compararlo estadísticamente entre herramientas. Cada $D_i$ se expresó como porcentaje de su máximo, $sum_j Q_(i j) \/ C_j$.

==== Experiencia de desarrollo

La encuesta de satisfacción se compuso de tres preguntas: la evaluación general de la experiencia de usuario (OUX), qué tan bien la herramienta respondió a las necesidades del participante (NFS) @Kuusinen2016, y de 22 pares de palabras antónimas: 10 de la versión corta de AttrakDiff 2 (SAD-2) @PDFNeedsAffect y 12 de DEXI @Kuusinen2016. Todos los ítems usaron una escala de 7 puntos, y cada par pertenece a una categoría General, Pragmática o Hedónica según el modelo hedónico-pragmático de la experiencia de usuario @hassenzahlPDFInterplayBeauty2026 (@cuadro2). El puntaje de cada categoría es el promedio de sus ítems.

#figure(
  caption: [Ítems de la encuesta de satisfacción en el orden en que se presentaron, con su par original @Kuusinen2016],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (auto, auto, 1fr, 1fr),
    inset: (x: 4pt, y: 3pt),
    align: left + horizon,
    table.header(
      [*Instrumento*], [*Categoría*], [*Ítem (izquierda – derecha)*], [*Original*],
    ),
    [OUX], [—], [Bueno – Malo ], [_Bad – Good_],
    [NFS], [—], [Para nada – Completamente], [_Not at all – Completely_],
    table.cell(rowspan: 10)[SAD-2],
    table.cell(rowspan: 2)[General],
    [Malo – Bueno], [_Bad – Good_],
    [Feo – Bonito], [_Ugly – Beautiful_],
    table.cell(rowspan: 4)[Pragmática],
    [Confuso – Estructurado], [_Confusing – Structured_],
    [Práctico – Impráctico ], [_Practical – Impractical_],
    [Impredecible – Predecible], [_Unpredictable – Predictable_],
    [Simple – Complicado ], [_Simple – Complicated_],
    table.cell(rowspan: 4)[Hedónica],
    [Antipático – Cautivador], [_Dull – Captivating_],
    [Elegante – Tosco ], [_Stylish – Tacky_],
    [Barato – Prémium], [_Cheap – Premium_],
    [Creativo – No imaginativo ], [_Creative – Unimaginative_],
    table.cell(rowspan: 12)[DEXI],
    [General], [Recomendable – No recomendable ], [_Recommendable – Not recommendable_],
    table.cell(rowspan: 5)[Pragmática],
    [Eficiente – Ineficiente ], [_Efficient – Inefficient_],
    [Flexible – Rígido ], [_Flexible – Inflexible_],
    [Fácil de aprender – Difícil de aprender ], [_Easy to learn – Difficult to learn_],
    [Limitado – Extensivo], [_Limited – Extensive_],
    [Desinformativo – Informativo], [_Uninformative – Informative_],
    table.cell(rowspan: 6)[Hedónica],
    [Motivador – Desmotivador ], [_Motivating – Discouraging_],
    [Genera respeto – Genera desconfianza ], [_Increases respect – Decreases respect_],
    [Agradable – Desagradable ], [_Enjoyable – Unenjoyable_],
    [Promueve la creatividad – Suprime la creatividad ], [_Promotes creativity – Suppresses creativity_],
    [Envolvente – Aburrido ], [_Engaging – Uninvolving_],
    [Me acerca a otros – Me aleja de otros ], [_Brings me closer to others – Separates me from others_],
  )
  },
)<cuadro2>

  ==== Análisis estadístico
Como cada participante usó ambas herramientas en una de dos secuencias (Nixlang → Nixty o Nixty → Nixlang), las métricas se compararon con la prueba de Mann-Whitney-Wilcoxon para diseños cruzados 2 × 2 @koch328NoteUse1972 con el fin de eliminar efectos de orden o de habilidad. El puntaje de un participante en la primera sesión $Y_1$ se compone de su habilidad $h$, del efecto $T$ de la herramienta usada en esa sesión y, en la segunda sesión $Y_2$, se agrega el efecto de orden $o$ (mejores resultados en el segundo intento por práctica, o peores por cansancio):

$ Y_1 = h + T_1, quad Y_2 = h + T_2 + o $

Para remover la habilidad de cada participante se calculó la diferencia entre su primera y su segunda sesión:

$ d = Y_1 - Y_2 = T_1 - T_2 - o $

Siendo $Delta = T_"Nixty" - T_"Nixlang"$ la ventaja de Nixty sobre Nixlang, $d$ toma un valor distinto en cada secuencia:

$ d_"Nixty → Nixlang" = Delta - o, quad d_"Nixlang → Nixty" = -Delta - o $

Suponiendo que el efecto del orden es el mismo en ambas secuencias, al restarlas este se elimina y queda solo la diferencia entre herramientas:

$ d_"Nixty → Nixlang" - d_"Nixlang → Nixty" = (Delta - o) - (-Delta - o) = 2 Delta $

Si ambas herramientas rinden igual ($Delta = 0$), $d$ solo refleja el orden y se distribuye igual en las dos secuencias. Por ello, la prueba compara la distribución de $d$ entre las dos secuencias y, a diferencia de Kuusinen @Kuusinen2016, que comparó a los participantes que calificaron OUX como bueno o malo, los grupos comparados fueron las secuencias.

Para cada métrica se probó la hipótesis nula de que la distribución de $d$ es la misma en ambas secuencias, de forma bilateral y con α = 0.05. Se compararon la tasa de éxito de cada categoría, el puntaje de cada dimensión cognitiva, OUX, NFS y el puntaje de cada calidad de SAD-2 y DEXI; los pares de palabras se compararon individualmente como análisis exploratorio. Para pruebas de hipótesis que verificaban variables relacionadas (entendimiento de programación, dimensiones cognitivas, categorías de SAD-2 y DEXI), los valores _p_ se ajustaron con la corrección de Holm.

Junto al valor _p_ se reportó el tamaño de efecto. El factor 2 de la diferencia entre secuencias no afecta la prueba ni el tamaño de efecto, porque ambos dependen solo del orden de los $d$. El tamaño de efecto fue la correlación biserial de rangos:

$ r_g = frac(2 U, n_1 n_2) - 1 $

donde $U$ es el estadístico de Mann-Whitney de la secuencia Nixty → Nixlang, es decir, el número de pares en que su $d$ supera al de Nixlang → Nixty (en caso de empate, se suma la mitad del puntaje a cada $U$). $r_g$ va de −1 a 1, donde 0 indica que no hay diferencia entre las secuencias, y es positivo cuando Nixty obtuvo mejores resultados. Su magnitud se interpretó con los rangos de @fielperesEffectSizesNonparametric: pequeño si $|r_g| >= 0.11$, mediano si $|r_g| >= 0.28$ y grande si $|r_g| >= 0.43$.

#pagebreak()

= Resultados
Por facilidad de lectura los resultados estan divididos por cada fase de la metodología.

== Fase 1
Se cuenta con las respuestas de 10 participantes, 10 de ellos responden el cuestionario de Programación Natural; y solo 2 de ellos la prueba de pensar-en-alto . Sobre sus perfiles, el 100% indican tener experiencia en manejadores de paquetes, más solo el 60% mencionan tener experiencia empaquetando una aplicación para su consumo por otros usuarios; sobre lenguajes la gran mayoría muestra cómodidad en el uso de lenguajes de alto nivel imperativos interpretados y no tipados como Python, y Javascript , seguido de lenguajes de alto nivel tipados y compilados, y terminando con lenguajes de bajo nivel (@cuadro3).

#figure(
  caption: [Lenguajes de programación que los participantes indican estar cómodos para realizar un proyecto.],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon, right + horizon, right + horizon),
    table.header(
      [*Lenguajes*], [*Porcentaje (%)*],
    ),
    [Python], [90.0],
    [Javascript], [60.0],
    [Java], [40.0],
    [Typescript], [40.0],
    [Bash], [20.0],
    [C], [10.0],
    [Sin respuesta], [10.0],
  )
  },
)<cuadro3>

En el cuestionario de programación natural se observan las siguientes tendencias:

- *Fuentes como variables o módulos*: la mitad de los participantes declara las fuentes (los registros de donde se descargan los paquetes) como variables, `fuente = "https://github.com/nixos/nixpkgs"`; la otra mitad, como módulos importados, `import "https://github.com/nixos/nixpkgs"`.

- *Verbos como palabras clave*: todos los participantes usan verbos como `install`, `update` o `delete` como palabras clave para dar instrucciones al manejador de paquetes, por ejemplo `install(fuente, ["A", "B"])`.

- *JSON para definir paquetes*: 9 de los 10 participantes definen los paquetes con objetos JSON:

#utilities.code_block(
  content: [ ```javascript
  {name : "hello", version: 3, dependencies : ["A", "B"]}
  ```]
)
El participante restante propone definir el paquete mediante una función para permitir cambios con parámetros.

- *Perfiles con condicionales*: la mitad de los participantes usa condicionales (`if`, `switch`) o etiquetas (`section`) para dar a cada perfil, como desarrollador o control de calidad, su propio entorno de desarrollo:

#utilities.code_block(
content: [
```nix
if ( args.user = "colaborador" ) then [ fuente.node ] 
else (fuente1.node@1.03)
```
])
Otros tres participantes proponen un archivo de configuración distinto para cada perfil.

- *Paquetes y entornos de desarrollo como entidades distintas*: todos los participantes tratan los paquetes y los entornos de desarrollo como entidades diferentes, cada una con sus propios atributos. Lo que discrepa con la realidad de Nix donde ambas son derivaciones.

En las sesiones de pensar en alto, los dos participantes, sin experiencia previa con Nix, deben crear un _flake_ desde cero. Tras 1 hora y 30 minutos solo llegan a la actividad 3 de la guía (de 7), y se identifican tres puntos de dolor:

- *Relación entre `inputs` y `outputs`*: no comprenden que lo declarado en `inputs` se recibe como parámetros de la función `outputs`.
- *Sintaxis de funciones*: confunden la definición de una función con un objeto; les toma 30 minutos entender que `outputs` es una función.
- *Parámetro `self`*: no comprenden su propósito dentro de `outputs`.
- *Mensajes de error*: Los participantes no logran comprender los mensajes de error por compilación.

== Fase 2
A partir de las observaciones de la Fase 1 se desarrolla Nixty @rayoNixtyGenerateNix2026, un eDSL en TypeScript que traduce las definiciones del usuario a Flakes de Nix @NixdevDocumentation. Esta sección describe primero el diseño de su interfaz y después su implementación.

=== Diseño

La preferencia de los participantes por lenguajes de alto nivel interpretados (@cuadro3) refuerza la elección de TypeScript como lenguaje anfitrión. Esta elección evita, además, reimplementar buena parte de la biblioteca estándar de Nix, cuyas funciones son en su mayoría utilidades para manipular cadenas, listas y conjuntos de atributos que TypeScript ya ofrece de forma nativa.

Los hallazgos de la Fase 1 se traducen en una interfaz de pocos bloques que se componen entre sí (@figura9). Todo parte de un `Path`, que indica dónde vive un recurso: en el proyecto, en la computadora o en internet. Si el recurso es código por construir, se envuelve en un `Source`; si representa código Nix ya escrito, en una `Expresion`. Con ellos se crean los tres tipos de derivación que escribe el usuario —`Package`, `DevShell` y `Command`—, y una `Definition` final agrupa lo que ofrece el proyecto; es este último objeto el que Nixty interpreta. Limitar la interfaz a pocos bloques reduce los conceptos por aprender, sin perder la versatilidad necesaria para cubrir la mayoría de las expresiones de un Flake.

#figure(image("media/figures/Figure9.svg", width: 70%), caption: [
  Bloques de la interfaz de Nixty y cómo se componen hasta formar una `Definition`.
])<figura9>

A continuación se resumen las principales decisiones de diseño y la ventaja de cada una.

*Fuentes como variables*

En un Flake, las fuentes se declaran en `inputs` y llegan como parámetros de la función `outputs`, junto con `self`: justo la relación que los participantes de la Fase 1 no logran comprender. En Nixty, una fuente es una variable más —tal como la declara la mitad de los participantes— y se usa directamente donde se necesita. El compilador deduce las entradas del Flake a partir de las variables que efectivamente se usan, por lo que el usuario no escribe la función `outputs` ni necesita `self`.

#utilities.code_block(content: [
```nix
# Nixlang: la fuente llega como parámetro de outputs
inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
outputs = { self, nixpkgs }: { ... };
```
```ts
// Nixty: la fuente es una variable
const NIX_PKGS = new Nixpkgs({ tag: "nixos-25.05" })
```])

*Sistemas como una lista de constantes*

En Nixlang, el sistema es una cadena dentro de la ruta de cada salida (`packages.x86_64-linux.hello`), y soportar varios sistemas obliga a repetir la definición o a recurrir a funciones auxiliares. Nixty expone los sistemas como constantes de `System`: cada salida declara la lista de sistemas que soporta y describe su contenido una sola vez, en una función que recibe el sistema y que el compilador llama una vez por cada uno. Así, el editor autocompleta los sistemas válidos y un nombre mal escrito se detecta antes de generar el Flake.

#utilities.code_block(content: [
```ts
import { System } from "nixty-lib"
const SYSTEMS = [System.x86_64Linux, System.aarch64Darwin]
```])

*Paquetes y entornos de desarrollo son objetos separados*

Aunque en Nix ambos son derivaciones, todos los participantes los conciben como entidades distintas. Nixty respeta esa intuición con un objeto para cada caso —`Package`, `DevShell` y `Command`—, cada uno con solo las opciones que le corresponden y escrito como un objeto similar a JSON, la notación que usan 9 de los 10 participantes. Las dependencias se agrupan según el momento en que se usan (`atBuild`, `atRuntime`, `atTest`) en lugar de los nombres internos de Nix, como `nativeBuildInputs`. Además, un entorno puede extender a otro con `extends`, lo que permite reutilizar expresiones.

#utilities.code_block(
content:[```ts
// Paquete
const hello = new Package({
    name: "hello",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: SRC,
        deps: { atRuntime: NIX_PKGS.getPackages(["figlet"], system) },
        phases: (out) => ({ install: nix`npm install` }),
    }),
})

// Entorno de desarrollo
const dev = new DevShell({
    name: "dev",
    systems: SYSTEMS,
    packages: (system) => [hello.getDerivation(system), ...NIX_PKGS.getPackages(["shellcheck"], system)],
    onEnter: `echo "Try: hello Ana"`,
})

// Perfil de control de calidad: una copia de `dev` con una variable más
const qa = new DevShell({ name: "qa", extends: dev, env: { CI: "true" } })
```])

*Sistema de tipos previniendo errores tempranos*

Ante la dificultad para interpretar los mensajes de error de Nix, Nixty traslada la mayor parte de la validación a TypeScript. Cada concepto tiene su propio tipo, de modo que usar uno en lugar de otro es un error que el editor señala mientras se escribe y que `nixty generate` vuelve a verificar antes de generar el Flake. Los errores aparecen así antes de que Nix evalúe el código, junto a la línea que los causa y con los mensajes de TypeScript. Lo que los tipos no alcanzan a expresar se verifica al ejecutar el evaluar el Flake.

*Las expresiones como método de compatibilidad con código Nixlang*

Ninguna interfaz puede cubrir todo lo que ofrece Nix, por lo que `Expresion` sirve de puente: importa código Nix desde un `Path` —un archivo `.nix`, otro Flake o Nixpkgs— y permite usarlo un valor, ya sea accediendo a sus atributos (`expr.name`), a los elementos de una lista (`expr[0]`) o llamándolo como función (`expr(a, b)`). `Nixpkgs` y `Flake` son expresiones con métodos para los usos más comunes, como `getPackages`. Así, el usuario reutiliza el ecosistema existente en lugar de reescribirlo, a cambio de que TypeScript no pueda verificar su contenido.

#utilities.code_block(content: [
```nix
# nix/saludo.nix
nombre: "Hola, ${nombre}!"
```
```ts
const saludo = new Expresion(Path.fetchInternalPath("nix/saludo.nix"))
const dev = new DevShell({
    // ...
    env: { SALUDO: nix`${saludo("Ana")}` },  // "Hola, Ana!"
})
```])

*Diseño reminiscente de un Flake*

  La `Definition` conserva la estructura de un Flake para reducir la fricción de quienes ya los utilizan. La correspondencia también puede funcionar sentido inverso, pues quien aprende Nixty puede traducir sus conocimientos a la sintaxis de los Flakes.

#utilities.code_block(content: [
```ts
export default new Definition({
    description: "Mi proyecto",  // description
    nixpkgs: NIX_PKGS,           // inputs.nixpkgs
    packages: [hello],           // packages.<sistema>.hello
    devShells: [dev, qa],        // devShells.<sistema>.dev y .qa
    commands: [lint],            // apps.<sistema>.lint
})
```])

=== Implementación

En la práctica, Nixty se sitúa como una nueva capa de abstracción en la cadena de Nix (@figura8): el usuario describe su proyecto con la interfaz de Nixty, que genera de forma implícita un Flake en Nixlang, y luego usa la interfaz de comandos de Nixty para solicitar al Nix Daemon que construya e instale lo descrito.

#figure(image("media/figures/Figure8.svg", width: 90%), caption: [
  Nixty como capa de abstracción sobre Nix: genera el código Nixlang que el Nix Daemon evalúa para guardar los paquetes en la Nix Store.
])<figura8>

Nixty se distribuye como un único paquete que contiene tanto la biblioteca que importa el usuario como la interfaz de comandos que la interpreta. El usuario escribe un archivo `nixty.ts` que exporta una `Definition`, y el comando `nixty generate` lo traduce a un `flake.nix`. Los objetos del @figura9 se traducen a nodos que representan constructos de Nixlang,  formando un grafo sintáctico. A partir de ese grafo, la transpilación ocurre en cuatro fases:

+ *Expansión*: prepara una versión de la configuración para cada sistema declarado, por ejemplo Linux y macOS.
+ *Recorrido*: revisa la configuración en busca de errores y averigua qué fuentes se usan realmente; las que no se usan se descartan.
+ *Nombramiento*: da un nombre único a cada fuente y a cada elemento que se usa más de una vez, para que Nix lo prepare una sola vez y lo reutilice.
+ *Emisión*: traduce todo a Nixlang y lo guarda en el archivo `flake.nix`.

El resultado es un `flake.nix` convencional, que puede leerse, versionarse y usarse con Nix aun sin tener Nixty instalado. Para el resto del ciclo, la interfaz de comandos ofrece verbos que regeneran el Flake y delegan cada tarea al comando de Nix equivalente (@cuadro-cli). Esto retoma la preferencia de los participantes de la Fase 1 por expresar las acciones como verbos.

#figure(
  caption: [Comandos de Nixty y el comando de Nix que ejecutan],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: left + horizon,
    table.header(
      [*Nixty*], [*Nix*],
    ),
    [`nixty develop dev`], [`nix develop .#devShells.<sistema>.dev`],
    [`nixty build hello`], [`nix build .#packages.<sistema>.hello`],
    [`nixty run hello`], [`nix run .#packages.<sistema>.hello`],
    [`nixty command lint`], [`nix run .#apps.<sistema>.lint`],
    [`nixty update`], [`nix flake update`],
  )
  },
)<cuadro-cli>

== Fase 3
Se cuenta con las respuestas de 20 participantes, 6 de ellos asistieron también en la Fase 1. Sus perfiles revelan ser usuarios familiarizados con el manejo de paquetes, experiencia media-avanzada en Typescript (@cuadro-experiencia), y poca experiencia en Nixlang; sus respuestas no mostraron una clara tendencia en su conocimiento de lenguajes funcionales.

#figure(
  caption: [Nivel de experiencia autorreportado por los participantes de la Fase 3, como porcentaje de participantes (escala 1–5)],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon,) + (right + horizon,) * 5,
    table.header(
      [*Experiencia en*], [*1 \ (Muy poca)*], [*2*], [*3*], [*4*], [*5 \ (Muy avanzada)*],
    ),
    [Manejo de paquetes], [0.0], [15.0], [25.0], [45.0], [15.0],
    [TypeScript], [5.0], [5.0], [35.0], [40.0], [15.0],
    [Nixlang], [65.0], [20.0], [15.0], [0.0], [0.0],
    [Lenguajes funcionales], [30.0], [10.0], [25.0], [30.0], [5.0],
  )
  },
)<cuadro-experiencia>

Los participantes tomaron más tiempo en promedio en completar el cuestionario de Nixty (41.7 minutos), que Nixlang (34.4 minutos) y sus indices de acierto mostrado en el @cuadro-preguntas no dista mucho entre herramientas, pero eso se determinará con las pruebas estadísticas.

#figure(
  caption: [Tasa de éxito por pregunta con cada herramienta; la diferencia se expresa en puntos porcentuales (pp)],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon, center + horizon, left + horizon) + (right + horizon,) * 3,
    table.header(
      [*Categoría*], [*Pregunta*], [*ID*], [*Nixlang \ (%)*], [*Nixty \ (%)*], [*Nixty − \ Nixlang (pp)*],
    ),
    table.cell(rowspan: 3)[Aprendizaje],
    [$P_1$], [PA1-1], [70.0], [60.0], [−10.0],
    [$P_2$], [PA2-1], [55.0], [60.0], [5.0],
    [$P_3$], [PA3-1], [90.0], [95.0], [5.0],
    table.cell(rowspan: 5)[Percepción],
    [$P_4$], [PP4-1], [55.0], [60.0], [5.0],
    [$P_5$], [PP5-1], [35.0], [60.0], [25.0],
    [$P_6$], [PP6-1], [45.0], [35.0], [−10.0],
    [$P_7$], [PP7-1], [75.0], [70.0], [−5.0],
    [$P_8$], [PP8-1], [70.0], [90.0], [20.0],
    table.cell(rowspan: 3)[Evolución],
    [$P_9$], [PE9-1], [75.0], [100.0], [25.0],
    [$P_10$], [PE10-1], [90.0], [95.0], [5.0],
    [$P_11$], [PE11-1], [75.0], [70.0], [−5.0],
    table.cell(colspan: 3)[*Total*], [*66.8*], [*72.3*], [*5.5*],
  )
  },
)<cuadro-preguntas>

Las siguientes secciones comparten los resultados obtenidos. Los cálculos, más no los datos, se encuentran en @rayoNixEveryoneRepository en `analysis/`.

=== Rendimiento
Las variantes difíciles de $P_1$–$P_8$ son opcionales, de las 320 presentadas (8 por herramienta a cada participante), se responde el 28.8 % : el 27.5 % con Nixlang y el 30.0 % con Nixty . Por ello se excluyen del análisis, y con cada herramienta se usan 11 preguntas: la variante fácil de $P_1$–$P_8$ y $P_9$–$P_11$. Se trabaja haciendo pruebas estadísticas con Mann-Whitney-Wilcoxon @koch328NoteUse1972 (prueba bilateral, α = 0.05) usando las siguientes hipotesis:

*$H_0$* = La distribución de la diferencia entre las secuencias $d_"Nixlang → Nixty"$ y $d_"Nixty → Nixlang"$ para la variable $X$, *es la misma*. (El rendimiento en ambas herramientas es el mismo).

*$H_a$* = La distribución de la diferencia entre las secuencias $d_"Nixlang → Nixty"$ y $d_"Nixty → Nixlang"$ para la variable $X$, *es diferente* (El rendimiento en ambas herramientas es el mismo).

Donde $X$ es la variable evaluada. Cuando se aplica la corrección de Holm, la decisión se toma con _p_ Holm. Las columnas Nixlang y Nixty son el promedio de los 20 participantes con cada herramienta.

Nixty no muestra ninguna diferencia estadística contra Nixlang en ninguna de las categorías de entendimiento de programación (@cuadro4), más si un tamaño de efecto medio ($r_g >= 0.28$) en Aprendizaje y Evolución, indicando que la tasa de exito fue medianamente mayor en Nixty.


#figure(
  caption: [Prueba de Mann-Whitney-Wilcoxon de la tasa de éxito por categoría de entendimiento de programación],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (1fr, auto, auto, auto, auto, auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon,) + (right + horizon,) * 5 + (center + horizon,),
    table.header(
      [*Categoría*], [*Nixlang \ (%)*], [*Nixty \ (%)*], [*$r_g$*], [*_p_*], [*_p_ \ Holm*], [*Se rechaza \ H₀*],
    ),
    [Aprendizaje], [71.7], [71.7], [0.10], [0.719], [0.721], [No],
    [Percepción], [56.0], [63.0], [0.31], [0.240], [0.721], [No],
    [Evolución], [80.0], [88.3], [0.30], [0.247], [0.721], [No],
  )
  },
)<cuadro4>

Tampoco se encontra una diferencia estadística entre ninguna de las dimensiones cognitivas (@cuadro5). Pero se observa un tamaño de efecto grande ($r_g >= 0.28$) en Dependencias Ocultas, y medio en otras 6 dimensiones, indicando que los participantes tuvieron un mejor rendimiento en esas dimensiones con Nixty; por otro lado se muestra un efecto pequeño negativo en la Consistencia de Nixty. Evaluación progresiva no se incluye por no relacionarse con ninguna pregunta, y las dimensiones relacionadas con las mismas preguntas, que obtienen el mismo puntaje, se agrupan en una fila en el @cuadro5.

#figure(
  caption: [Prueba de Mann-Whitney-Wilcoxon del puntaje de cada dimensión cognitiva, como porcentaje de su máximo],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (1fr, auto, auto, auto, auto, auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon,) + (right + horizon,) * 5 + (center + horizon,),
    table.header(
      [*Dimensión*], [*Nixlang \ (%)*], [*Nixty \ (%)*], [*$r_g$*], [*_p_*], [*_p_ \ Holm*], [*Se rechaza \ H₀*]
    ),
    [Cercanía de mapeo / Difusión / Propensión a errores], [67.8], [71.6], [0.14 - pequeño], [0.623], [1.000], [No],
    [Viscosidad], [80.0], [88.3], [0.30 - medio], [0.247], [1.000], [No],
    [Dependencias ocultas], [65.8], [74.1], [0.43 - grande], [0.111], [0.997], [No],
    [Operaciones mentales difíciles], [60.3], [66.7], [0.20 - pequeño], [0.470], [1.000], [No],
    [Anticipación impuesta], [75.0], [85.0], [0.30 - medio], [0.232], [1.000], [No],
    [Notación secundaria], [70.0], [90.0], [0.32 - medio], [0.182], [1.000], [No],
    [Visibilidad / Gradiente de abstracción], [61.8], [68.6], [0.40 - medio], [0.137], [1.000], [No],
    [Consistencia], [60.9], [53.5], [−0.14 - pequeño], [0.605], [1.000], [No],
    [Expresividad de rol], [67.3], [74.3], [0.39 - medio], [0.150], [1.000], [No],
  )
  },
)<cuadro5>

=== Experiencia de desarrollo
El @cuadro-oux-nfs muestra que la Experiencia de Usuario General (OUX, por sus siglas en inglés) difiere significativamente entre herramientas, con $r_g$ = 0.65 y _p_ = 0.014, mientras que en el Puntaje de Cumplimiento de Necesidades (NFS, por sus siglas en inglés) la diferencia no es significativa. En el análisis por cualidad del @cuadro-calidades se rechaza H₀ en dos casos: la cualidad General de SAD-2, con $r_g$ = 0.75 y _p_ Holm = 0.014, y la Pragmática de DEXI, con $r_g$ = 0.75 y _p_ Holm = 0.015. 

Enfoncandose en el tamaño de efecto, Nixty presenta un tamaño grande en todas las cualidades de ambos cuestionarios, excepto en el aspecto Hedónico de SAD-2, significando que los usuarios puntuaron la mayoría de estos aspectos de Nixty de forma considerablemente superior a NixLang. Un comportamiento parecido se puede ver en los puntajes de palabras por separado en @cuadro-pares-sad2 y @cuadro-pares-dexi.

#figure(
  caption: [Prueba de Mann-Whitney-Wilcoxon de OUX y NFS (escala 1–7), sin corrección de Holm por ser una prueba por instrumento],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (1fr, auto, auto, auto, auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon,) + (right + horizon,) * 4 + (center + horizon,),
    table.header(
      [*Instrumento*], [*Nixlang*], [*Nixty*], [*$r_g$*], [*_p_*], [*Se rechaza \ H₀*],
    ),
    [OUX], [4.45], [5.85], [0.65], [0.014], [Sí],
    [NFS], [4.85], [5.10], [0.12], [0.667], [No],
  )
  },
)<cuadro-oux-nfs>

#figure(
  caption: [Prueba de Mann-Whitney-Wilcoxon del puntaje de cada cualidad de SAD-2 y DEXI (escala 1–7), con corrección de Holm sobre las tres calidades de cada instrumento],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (1fr, auto, auto, auto, auto, auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon,) + (right + horizon,) * 5 + (center + horizon,),
    table.header(
      [*Cualidad*], [*Nixlang*], [*Nixty*], [*$r_g$*], [*_p_*], [*_p_ \ Holm*], [*Se rechaza \ H₀*],
    ),
    table.cell(colspan: 7)[*SAD-2*],
    [General], [4.70], [5.90], [0.75], [0.005], [0.014], [Sí],
    [Pragmática], [4.28], [5.18], [0.55], [0.041], [0.081], [No],
    [Hedónica], [4.39], [4.81], [0.38], [0.160], [0.160], [No],
    table.cell(colspan: 7)[*DEXI*],
    [General], [4.55], [6.00], [0.57], [0.031], [0.062], [No],
    [Pragmática], [4.52], [5.28], [0.75], [0.005], [0.015], [Sí],
    [Hedónica], [4.70], [5.24], [0.51], [0.058], [0.062], [No],
  )
  },
)<cuadro-calidades>

Por pares de palabras, seis pares de SAD-2 pasan la prueba $p$ sin corregir, pero ninguno sobrevive después de la corrección de Holm (@cuadro-pares-sad2). En DEXI, solo el par Difícil de aprender – Fácil de aprender rechaza H₀ ($r_g$ = 0.86, _p_ Holm = 0.014) (@cuadro-pares-dexi). 

#figure(
  caption: [Puntaje promedio por par de palabras de SAD-2 (escala 1–7, 7 es el polo positivo) y prueba de Mann-Whitney-Wilcoxon por par, con corrección de Holm sobre los 10 pares.],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (auto, 1fr, auto, auto, auto, auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon, left + horizon) + (right + horizon,) * 5,
    table.header(
      [*Cualidad*], [*Par (negativo – positivo)*], [*Nixlang*], [*Nixty*], [*$r_g$*], [*_p_*], [*_p_ \ Holm*],
    ),
    table.cell(rowspan: 2)[General],
    [Malo – Bueno], [5.00], [5.95], [0.72], [0.006], [0.058],
    [Feo – Bonito], [4.40], [5.85], [0.66], [0.013], [0.120],
    table.cell(rowspan: 4)[Pragmática],
    [Confuso – Estructurado], [4.35], [5.60], [0.64], [0.016], [0.125],
    [Impráctico – Práctico], [4.20], [4.50], [0.10], [0.731], [1.000],
    [Impredecible – Predecible], [4.85], [5.85], [0.63], [0.017], [0.125],
    [Complicado – Simple], [3.70], [4.75], [0.53], [0.048], [0.240],
    table.cell(rowspan: 4)[Hedónica],
    [Antipático – Cautivador], [4.10], [4.95], [0.61], [0.020], [0.125],
    [Tosco – Elegante], [4.60], [5.25], [0.37], [0.157], [0.629],
    [Barato – Prémium], [4.35], [4.40], [−0.10], [0.700], [1.000],
    [No imaginativo – Creativo], [4.50], [4.65], [0.04], [0.908], [1.000],
  )
  },
)<cuadro-pares-sad2>

#figure(
  caption: [Puntaje promedio por par de palabras de DEXI (escala 1–7, 7 es el polo positivo) y prueba de Mann-Whitney-Wilcoxon por par, con corrección de Holm sobre los 12 pares.],
  {
  set par(justify: false)
  set text(hyphenate: false)
  table(
    columns: (auto, 1fr, auto, auto, auto, auto, auto),
    inset: (x: 4pt, y: 3pt),
    align: (left + horizon, left + horizon) + (right + horizon,) * 5,
    table.header(
      [*Calidad*], [*Par (negativo – positivo)*], [*Nixlang*], [*Nixty*], [*$r_g$*], [*_p_*], [*_p_ \ Holm*],
    ),
    [General], [No recomendable – Recomendable], [4.55], [6.00], [0.57], [0.031], [0.343],
    table.cell(rowspan: 5)[Pragmática],
    [Ineficiente – Eficiente], [5.55], [5.55], [−0.10], [0.714], [1.000],
    [Rígido – Flexible], [4.55], [5.15], [0.24], [0.366], [1.000],
    [Difícil de aprender – Fácil de aprender], [3.25], [5.40], [0.86], [0.001], [0.014],
    [Limitado – Extensivo], [4.60], [5.15], [0.48], [0.066], [0.661],
    [Desinformativo – Informativo], [4.65], [5.15], [0.37], [0.152], [0.913],
    table.cell(rowspan: 6)[Hedónica],
    [Desmotivador – Motivador], [4.00], [5.30], [0.44], [0.095], [0.762],
    [Genera desconfianza – Genera respeto], [5.50], [5.15], [−0.22], [0.403], [1.000],
    [Desagradable – Agradable], [4.75], [5.60], [0.42], [0.114], [0.797],
    [Suprime la creatividad – Promueve la creatividad], [4.90], [5.30], [0.36], [0.172], [0.913],
    [Aburrido – Envolvente], [4.10], [4.90], [0.46], [0.081], [0.729],
    [Me aleja de otros – Me acerca a otros], [4.95], [5.20], [0.22], [0.351], [1.000],
  )
  },
)<cuadro-pares-dexi>


= Discusión

= Conclusiones

= Recomendaciones

#heading(level: 1, numbering: none, outlined: true)[Bibliografía]
#bibliography("ref.bib", title: none, style: "ieee")

= Anexos
#[
  #set heading(supplement: [Anexo])
  #include "annex/annex.typ"
]

#pagebreak(weak: true)
#heading(level: 1, numbering: none, outlined: true)[Glosario]

// Typst no incluye un paquete de glosarios equivalente a \usepackage{glossaries};
// esta sección lista manualmente las entradas definidas en el diccionario
// `glossary` de arriba, ordenadas alfabéticamente por término.
#for key in glossary.keys().sorted(key: k => glossary.at(k).name) [
  #strong[#glossary.at(key).name] #h(0.5em) --- #glossary.at(key).desc
  #v(0.5em)
]
