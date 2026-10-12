#set text(lang: "es")

#set page(
  paper: "a4",
  number-align: center,
  numbering: none,
  margin: 1.2cm
)

#set text(
  size: 9pt,
)

#set par(
  justify: true
)

#show raw: set text(fill: rgb("#438cb6"))

#align(center)[= Guía de Entrevistador \ Estudio de Pensar-en-alto]


== Introducción

_Leer en voz alta al participante:_

#block(
  fill: luma(230),
  inset: 12pt,
  radius: 4pt,
)[
  Gracias por participar. Esta sesión nos ayuda a entender cómo las personas aprenden y razonan con un nuevo lenguaje de programación.

  Lo que harás es resolver una serie de pasos para construir un archivo de configuración en Nix. No es un examen --- no hay respuestas correctas o incorrectas, nos interesa tu proceso.

  Lo más importante es que hables en voz alta mientras trabajas. Queremos escuchar lo que piensas en cada momento: lo que estás leyendo, lo que esperas que pase, cuando algo no tiene sentido, o cuando crees haber encontrado la solución.

  Tu voz y pantalla serán grabadas durante toda la sesión.

  ¿Tienes alguna pregunta antes de comenzar?
]

== Recursos disponibles

_Entregar al participante los siguientes enlaces:_

- #link("https://nix.dev")[nix.dev]
- #link("https://search.nixos.org/packages")[search.nixos.org/packages]
- #link("https://wiki.nixos.org/wiki/Flakes")[wiki.nixos.org/wiki/Flakes]
- #link("https://noogle.dev")[noogle.dev]

_Leer al participante:_

#block(
  fill: luma(230),
  inset: 12pt,
  radius: 4pt,
)[
  Puedes consultar estos recursos o buscar en internet libremente. No se permite el uso Inteligencia Artificial como ChatGPT o similares durante la sesión.
]

== Durante la sesión

- No ofrecer pistas ni confirmar si el participante va bien
- Si el participante guarda silencio por más de 15 segundos, preguntar: _"¿Qué estás pensando ahora?"_
- Tomar nota de momentos de confusión, bloqueos o sorpresa

== Al finalizar

- Detener la grabación
- Agradecer al participante
- Abrir espacio para preguntas o comentarios

== Actividades
\

1. Crear un archivo `flake.nix` con los campos `description`, `inputs` y `outputs`. Hazlo de tal manera que puedas correr `nix flake show` sin errores.
\

2. Agrega `nixpkgs` como `input` apuntando a `github:NixOS/nixpkgs/release-26.05`.
\

3. Has que `outputs` sea una función que reciba los parámetros `self` y `nixpkgs` y retorne un _attribute set_ con una llave `version` y valor `nixpkgs.lib.version`. Verifica que corre sin errores con `nix eval .#version`
\

4. Modifica tu función `outputs` para que declaré una variable `pkgs` que guarde los resultados de importar `nixpkgs` configurado para `x84_64-linux`.
\

5. Quieres crear un entorno de desarollo (`devShell`) para la arquitectura `x84_64-linux`. Utiliza la función `pkgs.mkShell` para construirla, basta con que especifiques el atributo `name`. Entra a ella con el comando `nix develop`.
\

6. Agrega aplicaciones `jp` y `tree` a tu entorno de desarrollo. Verifica que estan disponibles dentro del entorno. 
\

7. Quisieras que este mismo entorno de desarrollo estuviera disponible para otras arquitecturas, pero no quieres repetir la configuración para cada una. ¿Cómo lo resolverías?