// Misma llave que `in-thesis` en utilities.typ.
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

// Formato de la hoja impresa. Dentro de la tesis (annex/annex.typ) se omite y el título
// lo pone el encabezado del anexo.
#show: doc => context if in-thesis.get() { doc } else [
  #set text(lang: "es", size: 9pt)
  #set page(paper: "a4", number-align: center, numbering: none, margin: 1.2cm)
  #set par(justify: true)
  #show raw: set text(fill: rgb("#438cb6"))
  #show heading.where(level: 2): it => underline()[#it]

  #align(center)[= Usabilidad en lenguajes de programación]

  #linebreak()
  #doc
]

== Instrucciones
Esta actividad forma parte de una investigación sobre cómo las personas expresan ideas de configuración y automatización de forma espontánea, antes de aprender un lenguaje formal.

No existe una respuesta correcta ni incorrecta. Lo que nos interesa es cómo tú lo pensarías naturalmente.

*¿En qué consiste?*

*Se te presentará una serie de problemas que debe resolver un Manejador De Paquetes ficticio. Tu tarea es inventar, en el momento, la sintaxis o notación que usarías para resolverlos*. Puedes usar:

- texto libre o pseudocódigo
- diagramas, flechas o dibujos
- anotaciones al margen explicando tu razonamiento
- cualquier combinación de lo anterior

No es necesario que la sintaxis pertenezca a ningún lenguaje real, ni que sea consistente entre problemas. Exprésate con espontaneidad — *si cambias de idea a mitad, tacha y sigue. Esos cambios también nos interesan.*

*Antes de comenzar*: Resuelve los problemas en orden y no leas el siguiente hasta haber terminado el actual. No hay límite de tiempo, pero intenta no pensarlo demasiado — la primera idea que tengas suele ser la más valiosa para esta investigación.

#linebreak()

== Información del Participante
#linebreak()

1. *Cual es tu edad*: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
2. *En que semestre de la universidad te encuentras (indica número)*: \_\_\_\_\

3.*Tienes experiencia utilizando manejadores de paquetes (ej: pacman, npm, pip, apt...)*

#cb[Si] #cb[No]

4.*Haz empaquetado algun aplicación de _software_ (librería o aplicación) para su consumo por otros usuarios *

#cb[Si] #cb[No]

5. *¿Cuáles de estos lenguajes te sientes cómodo para realizar un proyecto?* 
#cb[Bash] #cb[C] #cb[Elixir] #cb[Java] #cb[Javascript]

#cb[Typescript] #cb[Python] #cb[Lisp]

\

== Contexto

Un paquete de _software_ es un conjunto de programas, archivos e instrucciones pensados para ser distribuidos e instalados en otros sistemas. Por ejemplo, un editor de texto, o una librería como NumPy.

Un manejador de paquetes es el programa encargado de instalar, actualizar, configurar y eliminar paquetes en un sistema. Una de sus responsabilidades más importantes es gestionar las dependencias: un paquete raramente funciona solo — casi siempre requiere que otros paquetes estén instalados previamente y configurados de una manera específica, generando una grafo de paquetes de dependencias como en la  @diagram1.

#figure(image("./diagram1.svg", width: 50%), caption: [Dependencias ficticias de `VS Code` y `Discord`; ambos tienen una dependencia compartida en `Electron`, a su vez estas dependencias dependen de otras.])<diagram1>

*El manejador de paquetes que tú vas a crear funciona de manera diferente a los tradicionales*. En lugar de ejecutar un comando como `instalar paquete-X`, *tú describes lo que quieres en un archivo de configuración*, y el manejador de paquetes se encarga de llevarlo a cabo. Esto significa que toda la información sobre qué instalar, cómo construirlo y de qué depende queda registrada explícitamente en ese archivo.

Para describir un paquete en este sistema, necesitas especificar al menos:

- *De dónde obtenerlo* — la URL o repositorio desde donde se descarga su código fuente o ejecutables.
- *Sus dependencias* — otros paquetes que deben estar presentes para que este funcione.
- *Cómo construirlo* — los pasos necesarios para compilarlo o instalarlo una vez descargado.

- *Para qué arquitectura construirlo* — los paquetes se compilan para un tipo de procesador específico, como x86_64 (la mayoría de computadores de escritorio) o arm (dispositivos móviles y algunos computadores modernos). Un paquete compilado para una arquitectura no funcionará en otra.

Puedes imaginar cada paquete como una receta de cocina: tiene ingredientes (dependencias) que obtienes de algúna tienda (fuentes), se prepara en una cocina específica (arquitectura), y sigue una serie de pasos (instrucciones de instalación) que van desde preparar los ingredientes hasta tener el plato listo para servir.


#figure(image("./diagram2.png", width: 50%), caption: [Los diferentes componentes a tomar en cuanta para describir un paquete de _software_])<diagram2>

== Sección 1 - Manejo de paquetes externos
Tú manejador de paquetes instala todo dentro de un entorno aislado: cada proyecto tiene su propio espacio con sus propias herramientas, sin interferir con el resto del sistema, similar a un contenedor.

1. Estas empezando un nuevo proyecto y quieres que todo tu equipo usen las mismas herramientas, tu manejador de paquetes puede hacerlo por ti. Sin embargo, primero tienes que indicar de que fuente obtenerlos. Escribe la sintaxis para indicar que `fuente1` proviene de `github.com/example/repo`, `fuente2` de `librerias.com/search` y fuente de un archivo ZIP en `./home/user/hello`. 

2. Antes de indicar que paquetes deseas instalar tienes que indicar para que arquitecturas de computadora debe ser disponible en la sintaxis, sabes que tus compañeros usan `x86-64-linux` y `arm64-macos`.

3. Con la configuración previa, escribe la sintaxis para indicar que quieres instalar 
- `node-v1.0` de `fuente1`
- `reactjs-v2.1` y `tailwindcss-v3.0` de `fuente2`
- `vitejs-v1.0` de `fuente3`.

4. Necesitas actualizar `node` de `v1.0` a `v2.0`. Escribe cómo modificarías la declaración anterior.

5. Decidiste que `vitejs-v1.0` ya no es necesario. Escribe cómo lo eliminarías de la configuración.

6. Un colaborador externo necesita su propio conjunto de herramientas: `node v2.0` y `vitest v3.0` pero no quieres reescribir toda la lógica de nuevo para este miembro ¿Cómo escribirías el código para *reutilizar* lo que ya tienes y definir este  `ambiente de desarollo`?


== Sección 2 - Manejo de paquetes externos
Ahora eres tú quien crea un paquete para que otros lo usen. Tienes una aplicación llamada `mi-app` en `github.com/yo/mi-app` que quieres distribuir.

Construir un paquete ocurre en fases, por ahora trabaja con dos:

- *build* — compilar el código fuente del programa
- *install* — copiar el programa compilado en las carpetas especificas al sistema para que pueda ser usado (`C:/Program Files` en Windows o `/usr/bin` en Linux).

1. Escribe la sintaxis para declarar este paquete: su nombre, versión `1.0` de dónde descargarlo y las arquitecturas en donde es soportado.


2. Tu aplicación necesita `node-v2.0` y `reactjs-v2.1` para funcionar. Escribe cómo agregarías esas dependencias a la declaración anterior, recuerda que también tienes que indicar de dónde obtenerlas.


3. Escribe la sintaxis para describir la fase *build* de `mi-app`: compilar el código ejecutando `npm run build`.


4. Escribe la sintaxis para describir la fase *install*: copiar el resultado de la compilación al sistema ejecutando `npm run install`.


5. Ahora, en `x86-64-linux` necesitas `openssl-v1` pero en `arm64-macos` necesitas `openssl-v2`. ¿Cómo expresarías que una dependencia cambia según la arquitectura?


6. Como generalizarías tus ideas anteriores para que pudieras definir varios paquetes en un archivo sin tener que repetir tanto código.

