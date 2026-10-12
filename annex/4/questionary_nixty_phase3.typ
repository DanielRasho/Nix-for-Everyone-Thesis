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

#let codespace = "https://codespaces.new/DanielRasho/Thesis-codespaces?quickstart=1&devcontainer_path=.devcontainer/nixty/devcontainer.json"

#show link: underline

// Formato de la hoja impresa. Dentro de la tesis (annex/annex.typ) se omite y el título
// lo pone el encabezado del anexo.
#show: doc => context if in-thesis.get() { doc } else [
  #set text(lang: "es", size: 11pt)
  #set page(paper: "a4", number-align: center, numbering: none)
  #set par(justify: true)

  #align(center)[= Prueba de Usabilidad en Lenguajes de Programación]
  \
  #doc
]
*Marca en una escala del 1 al 5 tu nivel de experiencia en cada uno de los siguientes temas.*

_Manejo de Paquetes_
#linkert(pairs: (
    ("Muy poca", "Muy avanzada"),
  ),
  grades: 5
)

_TypeScript_
#linkert(pairs: (
    ("Muy poca", "Muy avanzada"),
  ),
  grades: 5
)

_NixLang_
#linkert(pairs: (
    ("Muy poca", "Muy avanzada"),
  ),
  grades: 5
)

_Lenguajes Funcionales_
#linkert(pairs: (
    ("Muy poca", "Muy avanzada"),
  ),
  grades: 5
)

== Instrucciones

Se te presentaran una serie de ejercicios para poner a prueba tu aprendizaje en *Nixty*.

Durante la prueba puedes consultar el contenido de aprendizaje dado por el investigador, como buscar por internet, más *no se permite el uso de asistentes de inteligencia artificial*.


*PA1-1*. Escoge el código correcto (Sin errores sintácticos).

#choice_item(label: "a)", content: [
```ts
import { Definition, DevShell, Nixpkgs, System } from "nixty-lib"

const NIX_PKGS = new Nixpkgs({ tag: "nixos-unstable" })

const dev = new DevShell({
    name: "default"
    systems: [System.x86_64Linux]
    packages: (system) => NIX_PKGS.getPackages(
      ["python3", "git"], system)
    onEnter: `echo "Welcome to the dev shell"`
})
```
])

#choice_item(label: "b)", content: [
```ts
import { Definition, DevShell, Nixpkgs, System } from "nixty-lib"

const NIX_PKGS := new Nixpkgs({ tag := "nixos-unstable" })

const dev = new DevShell({
    name: "default",
    systems := [System.x86_64Linux],
    packages: (system) => NIX_PKGS.getPackages(
      ["python3" "git"], system),
    onEnter := "echo Welcome to the dev shell",
})
```
])

#choice_item(label: "c)", content: [
```ts
import { Definition, DevShell, Nixpkgs, System }

const NIX_PKGS = new Nixpkgs({ tag: "nixos-unstable" })

const dev = new DevShell({
    name: "default",
    systems: [System.x86_64Linux],
    packages: (system) => NIX_PKGS.getPackages(
      ["python3", "git"], ${system}),
    onEnter: `echo "Welcome to the dev shell"`,
})
```
])

#choice_item(label: "d)", content: [
CORRECTA
```ts
import { Definition, DevShell, Nixpkgs, System } from "nixty-lib"

const NIX_PKGS = new Nixpkgs({ tag: "nixos-unstable" })

const dev = new DevShell({
    name: "default",
    systems: [System.x86_64Linux],
    packages: (system) => NIX_PKGS.getPackages(
      ["python3", "git"], system),
    onEnter: `echo "Welcome to the dev shell"`,
})
```
])

#choice_item(label: "e)", content: [
```ts
get { Definition, DevShell, Nixpkgs, System } from "nixty-lib"

const NIX_PKGS = new Nixpkgs({ tag: "nixos-unstable" })

const dev = new DevShell
    name: "default"
    systems: [System.x86_64Linux]
    packages: (system) => NIX_PKGS.getPackages(
      ["python3", "git"], system)
    onEnter: `echo "Welcome to the dev shell"`,
})
```
])

*PA1-2*. _(Opcional)_ Escoge el código correcto (Sin errores sintácticos).

#choice_item(label: "a)", content: [
```ts
// more code...
const greet = new Package({
    name: "greet"
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchFromGithub({
            owner: "example",
            repo: "greet",
            tag: "v1.0.0",
        })),
        deps: {},
        phases: (out) => ({
            build: nix`
                gcc -O2 -o greet main.c
            `,
            install: nix`
                mkdir -p ${out}/bin
                cp greet ${out}/bin/greet
            `,
        }),
    }),
})
// more code...
```
])

#choice_item(label: "b)", content: [
CORRECTA
```ts
// more code...
const greet = new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchFromGithub({
            owner: "example",
            repo: "greet",
            tag: "v1.0.0",
        })),
        deps: {
            atBuild: NIX_PKGS.getPackages(["gcc"], system),
        },
        phases: (out) => ({
            build: nix`
                gcc -O2 -o greet main.c
            `,
            install: nix`
                mkdir -p ${out}/bin
                cp greet ${out}/bin/greet
            `,
        }),
    }),
})
// more code...
```
])

#choice_item(label: "c)", content: [
```ts
// more code...
const greet := new Package({
    name := "greet",
    systems := SYSTEMS,
    definition := (system) => ({
        version := "1.0.0",
        src := new Source(Path.fetchFromGithub(
            owner = "example",
            repo = "greet",
            tag = "v1.0.0")),
        deps := {},
        phases := (out) => ({
            build := "gcc -O2 -o greet main.c",
            install := "mkdir -p $out/bin; cp greet $out/bin/greet",
        }),
    }),
})
// more code...
```
])

#choice_item(label: "d)", content: [
```ts
// more code...
const greet = new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0"
        src: new Source(Path.fetchFromGithub({
            owner = "example";
            repo = "greet";
            tag = "v1.0.0";
        }))
        deps: {},
        phases: (out) => ({
            build: nix`
                gcc -O2 -o greet main.c
            `,
            install: nix`
                mkdir -p ${out}/bin
                cp greet ${out}/bin/greet
            `,
        }),
    }),
})
// more code...
```
])

#choice_item(label: "e)", content: [
```ts
// more code...
const greet = new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchFromGithub({
            owner: "example";
            repo: "greet";
            tag: "v1.0.0";
        })),
        deps: {},
        phases: (out) => ({
            build: nix`
                gcc -O2 -o greet main.c
            `,
            install: nix`
                mkdir -p ${out}/bin
                cp greet ${out}/bin/greet
            `,
        }),
    }),
})
// more code...
```
])

*PA2-1*. Selecciona el trozo de código que *NO* tiene sentido.

#choice_item(label: "a)", content: [
```ts
//  ...
const dev = new DevShell({
    name: "default",
    systems: SYSTEMS,
    packages: (system) => NIX_PKGS.getPackages(["python3"], system),
    onEnter: `echo "Welcome to the dev shell"`,
})
//  ...
```
])

#choice_item(label: "b)", content: [
```ts
//  ...
const dev = new DevShell({
    name: "default",
    systems: SYSTEMS,
    packages: (system) => NIX_PKGS.getPackages(["python3", "git"], system),
    onEnter: ["echo", "Welcome to the dev shell"].join(" "),
})
//  ...
```
])

#choice_item(label: "c)", content: [
CORRECTA
```ts
//  ...
const SYSTEMS = NIX_PKGS.getPackages(["git"], System.x86_64Linux)
const dev = new DevShell({
    name: "default",
    systems: SYSTEMS,
    packages: (system) => NIX_PKGS.getPackages(["python3", "git"], system),
})
//  ...
```
])

#choice_item(label: "d)", content: [
```ts
//  ...
const dev = new DevShell({
    name: "default",
    systems: SYSTEMS,
    packages: (system) => NIX_PKGS.getPackages(["python3", "git", "nodejs"], system),
    onEnter: `echo "Welcome to the dev shell"`,
})
//  ...
```
])

#choice_item(label: "e)", content: [
```ts
//  ...
const dev = new DevShell({
    name: "default",
    systems: SYSTEMS,
    packages: (system) => NIX_PKGS.getPackages(["python3", "git"], system),
    onEnter: `echo "Welcome to the dev shell"`,
})
//  ...
```
])

*PA2-2*. _(Opcional)_ Selecciona el trozo de código que *SI* tiene sentido.

#choice_item(label: "a)", content: [
CORRECTA
```ts
//  ...
new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchFromGithub(
          { owner: "example", repo: "greet", tag: "v1.0.0" })),
        deps: { atBuild: NIX_PKGS.getPackages(["gcc"], system) },
        phases: (out) => ({
            build: nix`gcc -O2 -o greet main.c`,
            install: nix`mkdir -p ${out}/bin; cp greet ${out}/bin/greet`,
        }),
    }),
})
//  ...
```
])

#choice_item(label: "b)", content: [
```ts
//  ...
new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchFromGithub(
          { owner: "example", repo: "greet", tag: "v1.0.0" })),
        deps: { atBuild: NIX_PKGS.getPackages(["gcc"], system)[0] },
        phases: (out) => ({
            build: nix`gcc -O2 -o greet main.c`,
            install: nix`mkdir -p ${out}/bin; cp greet ${out}/bin/greet`,
        }),
    }),
})
//  ...
```
])

#choice_item(label: "c)", content: [
```ts
//  ...
new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchFromGithub(
          { owner: "example", repo: "greet", tag: "v1.0.0" })),
        deps: { atBuild: NIX_PKGS.getPackages(["gcc"], system) },
        phases: (out) => ({
            build: nix`gcc -O2 -o greet main.c`,
            install: out,
        }),
    }),
})
//  ...
```
])

#choice_item(label: "d)", content: [
```ts
//  ...
new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: "main.c",
        deps: { atBuild: NIX_PKGS.getPackages(["gcc"], system) },
        phases: (out) => ({
            build: nix`gcc -O2 -o greet main.c`,
            install: nix`mkdir -p ${out}/bin; cp greet ${out}/bin/greet`,
        }),
    }),
})
//  ...
```
])

#choice_item(label: "e)", content: [
```ts
//  ...
new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(
          Path.fetchFromGithub({owner: "example", repo: "greet", tag: "v1.0.0",})
        ),
        deps: {},
        phases: (out) => ({
            build: nix`gcc -O2 -o greet main.c`,
            install: nix`mkdir -p ${out}/bin; cp greet ${out}/bin/greet`,
            build: nix`make`,
        }),
    }),
})
//  ...
```
])

*PA3-1*. Selecciona el programa correcto con el resultado solicitado.

_"Dado `x = 10`, seleciona el programa donde `respuesta` evalúa a \"grande\"."_

#choice_item(label: "a)", content: [
CORRECTA
```ts
const x = 10
let respuesta

if (x < 5) respuesta = "pequeño"
else if (x < 10) respuesta = "mediano"
else respuesta = "grande"
```
])

#choice_item(label: "b)", content: [
```ts
const x = 10
let respuesta

if (x < 5) respuesta = "pequeño"
else if (x <= 10) respuesta = "mediano"
else respuesta = "grande"
```
])

#choice_item(label: "c)", content: [
```ts
const x = 10
let respuesta

if (x > 10) respuesta = "grande"
else if (x > 5) respuesta = "mediano"
else respuesta = "pequeño"
```
])

#choice_item(label: "d)", content: [
```ts
const x = 10
let respuesta

if (x < 5) respuesta = "manzanas"
else if (x < 10) respuesta = "peras"
else respuesta = "bananos"
```
])

#choice_item(label: "e)", content: [
```ts
const x = 10
let respuesta

if (x < 5) respuesta = "pequeño"
else if (x < 10) respuesta = "mediano"
```
])

*PA3-2*. _(Opcional)_ Selecciona el programa correcto con el resultado solicitado.

_"Un programa de Nixty que produzca una *DevShell* para linux 🐧, y construya un paquete para macos 🍎 (Darwin)."_

#choice_item(label: "a)", content: [
```ts
export default new Definition({
    //... more code
    nixpkgs: new Nixpkgs({ tag: "nixos-unstable" }),
    commands: [
        new DevShell({
            name: "default",
            systems: [System.x86_64Darwin],
            //... more code
        }),
    ],
    commands: [
        new Package({
            name: "default",
            systems: [System.x86_64Linux],
            //... more code
        }),
    ],
})
```
])

#choice_item(label: "b)", content: [
```ts
export default new Definition({
    //... more code
    nixpkgs: new Nixpkgs({ tag: "nixos-unstable" }),
    systems: [System.x86_64Linux],
    devShells: [
        new DevShell({
            name: "default",
            //... more code
        }),
    ],
    packages: [
        new Package({
            name: "default",
            //... more code
        }),
    ],
})
```
])

#choice_item(label: "c)", content: [
CORRECTA
```ts
export default new Definition({
    //... more code
    nixpkgs: new Nixpkgs({ tag: "nixos-unstable" }),
    devShells: [
        new DevShell({
            name: "default",
            systems: [System.x86_64Linux],
            //... more code
        }),
    ],
    packages: [
        new Package({
            name: "default",
            systems: [System.x86_64Darwin],
            //... more code
        }),
    ],
})
```
])

#choice_item(label: "d)", content: [
```ts
export default new Definition({
    //... more code
    nixpkgs: new Nixpkgs({ tag: "nixos-unstable" }),
    devShells: [
        new DevShell({
            name: "default",
            systems: [System.x86_64Linux],
            //... more code
        }),
    ],
    packages: [
        new Package({
            name: "default",
            systems: [System.x86_64Linux],
            //... more code
        }),
    ],
})
```
])

#choice_item(label: "e)", content: [
```ts
export default new Definition({
    //... more code
    nixpkgs: new Nixpkgs({ tag: "nixos-unstable" }),
    packages: [
        new Package({
            name: "default",
            systems: [System.x86_64Darwin],
            //... more code
        }),
    ],
})
```
])

*PP4-1*. Selecciona el valor final de `[ f, a ]` tras ser evaluado.

#code_block(content: [
```ts
const f = (x: number) => x + 1
const a = 1

const result = [f, a]
```
])

*a)* `[ [Function: f], 1 ]` (CORRECTA)\
*b)* `[ 2 ]`\
*c)* `2`\
*d)* `[ [Function: f] ]`\
*e)* Error de evaluación\

*PP4-2*. _(Opcional)_ Selecciona el resultado correcto para cuando se corre `nixty build greet` con el programa dado:

#code_block(content: [
```ts
const greet = new Package({
    name: "greet",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchFromGithub({
            owner: "example", repo: "greet", tag: "v1.0.0",
        })),
        deps: {
            atBuild: NIX_PKGS.getPackages(["gcc"], system),
        },
        phases: (out) => ({
            build: nix`gcc -O2 -o greet main.c`,
            install: nix`
                mkdir -p ${out}/bin
                cp greet ${out}/bin/greet
            `,
        }),
    }),
})
```
])

*a)* Nix compila usando el código fuente del directorio de trabajo actual en lugar de GitHub, ya que `fetchFromGithub` solo se usa con fines de documentación.\
*b)* Nix obtiene el código fuente de GitHub en el tag fijado (`v1.0.0`), y compila `main.c` con `gcc` y genera `bin/greet`. (CORRECTA)\
*c)* Nix crea un entorno de desarrollo (dev shell) con `gcc` disponible.\
*d)* Nix obtiene el código fuente, pero como no se proporcionó ningún hash, descarga siempre la versión más reciente del repositorio, ignorando el tag, y se ejecuta correctamente sin mostrar ningún error.\
*e)* Nix compila el programa correctamente, pero el binario resultante se llama main, no greet, porque ese es el nombre del archivo fuente (`main.c`).\

*PP5-1*. Identifica cuantas variables son accesibles desde el bloque señalado en el comentario:

#code_block(content: [
```ts
const outputs = (name: string) => {
    const a = "A"
    const b = "B"
    return {
        a: () => { const c = "C"; return d },
        b: () => {
            const c = "D"
            return {
                // <= HERE
            }
        },
    }
}
```
])

*a)* 6\
*b)* 7\
*c)* 8\
*d)* 5\
*e)* 4 (CORRECTA)\

*PP5-2*. _(Opcional)_ En base a la estructura del siguiente código que puedes decir de los tipos de `x, y, z, a`:

#code_block(content: [
```ts
( x: Function, y: number, z: number ) => x(y).a(z)
```
])

*a)* `x` es una función | `y` es un número | `z` es un objeto | `a` es una función.\
*b)* `x` es una función | `y` es un número | `z` es un número | `a` es una función. (CORRECTA)\
*c)* `x` es un objeto | `y` es una función | `z` es un número | `a` es un tipo cualquiera.\
*d)* `x` es una función | `y` es un objeto | `z` es un número | `a` es una función.\
*e)* `x` es una función | `y` es un número | `z` es un número | `a` es un objeto.\

*PP6-1*. Selecciona el programa que evalué una expresión equivalente a:

#code_block(content: [
```ts
{
    name: "api",
    port: "8080",
    server: {
        routes: [["GET", "/users"], ["POST", "/login"]],
        database: {
            engine: "sqlite",
            file: "data/app.db",
        },
    },
}
```
])

#choice_item(label: "a)", content: [
```ts
const server = {
    routes: [["GET", "/users"], ["POST", "/login"]],
}

const result = {
    name: "api",
    port: "8080",
    server: { ...server, database: { engine: "sqlite" } },
}
```
])

#choice_item(label: "b)", content: [
```ts
const settings = {
    routes: [["GET", "/users"], ["POST", "/login"]],
    database: {
        engine: "sqlite",
        file: "data/app.db",
    },
}

const result = {
    name: "api",
    port: "8080",
    server: { settings },
}
```
])

#choice_item(label: "c)", content: [
CORRECTA
```ts
const db = {
    engine: "sqlite",
    file: "data/app.db",
}
const { engine, file } = db

const result = {
    name: "api",
    port: "8080",
    server: {
        routes: [["GET", "/users"], ["POST", "/login"]],
        database: { engine, file },
    },
}
```
])

#choice_item(label: "d)", content: [
```ts
const result = {
    name: "api",
    port: "8080",
    server: {
        routes: [["GET", "/users"], ["POST", "/login"]],
        database: {
            engine: Path.fetchExternalPath("/sqlite"),
            file: Path.fetchInternalPath("data/app.db"),
        },
    },
}
```
])

#choice_item(label: "e)", content: [
```ts
const users = ["GET", "/users"]
const login = ["POST", "/login"]

const result = {
    name: "api",
    port: "8080",
    server: {
        routes: [...users, ...login],
        database: {
            engine: "sqlite",
            file: "data/app.db",
        },
    },
}
```
])

*PP6-2*. _(Opcional)_ Selecciona el programa que evalúa a una expresión equivalente a:

#code_block(content: [
```ts
{ A: "BLUE", B: "LARGE", C: "MONO" }
```
])

#choice_item(label: "a)", content: [
```ts
const defaults = { A: "BLUE", B: "MEDIUM" }
const user = { B: "LARGE", C: "MONO" }

const result = { ...user, ...defaults }
```
])

#choice_item(label: "b)", content: [
CORRECTA
```ts
const defaults = { A: "BLUE", B: "MEDIUM" }
const user = { B: "LARGE", C: "MONO" }

const result = { ...defaults, ...user }
```
])

#choice_item(label: "c)", content: [
```ts
const defaults = { A: "BLUE", B: "MEDIUM" }
const user = { B: "LARGE", C: "MONO" }

const result = { ...defaults, user }
```
])

#choice_item(label: "d)", content: [
```ts
const defaults = { A: "BLUE", B: "MEDIUM" }
const user = { B: "LARGE", C: "MONO" }

const result = { {}, {}, B: user.B }
```
])

#choice_item(label: "e)", content: [
```ts
const defaults = { A: "BLUE", B: "MEDIUM" }
const user = { B: "LARGE", C: "MONO" }

const result = { ...defaults, ...user, B: "MEDIUM" }
```
])

*PP7-1*. En qué orden crees que se van a evaluar las diferentes variables de este programa de Typescript.

El `&` significa que se evaluan a la vez en el mismo paso.

#code_block(content: [
```ts
const a = 1
const b = a + 2
const c = b * 3
```
])

*a)* c #sym.arrow.r b #sym.arrow.r a\
*b)* a #sym.arrow.r b #sym.arrow.r c (CORRECTA)\
*c)* c & b #sym.arrow.r a\
*d)* a & b & c\
*e)* c & a #sym.arrow.r b\

*PP7-2*. _(Opcional)_ Indica cual será el resultado de evaluar el siguiente programa, *recuerda que TypeScript evalúa de forma estricta (_eager_)*.

#code_block(content: [
```ts
const averages = [10 / 0, 0 / 0, -5 / 0]
// Este cálculo tarda muchísimo
let total = 0
for (let n = 0; n < 5_000_000_000_000; n++) total += n

const message = averages.length > 2
    ? "listo!"
    : total
```
])

*a)* Evalúa a `"listo!"`.\
*b)* Falla por división por cero.\
*c)* Falla por variable indefinida.\
*d)* Evalúa a `"listo!"`, pero porque TypeScript elimina automáticamente la rama else no usada.\
*e)* Tarda mucho en responder, porque TypeScript calcula `total`. (CORRECTA)\

*PP8-1*. Indica cual será el resultado de la siguiente operación.

#code_block(content: [
```ts
const prices = [10, 20, 30]
const stock = [
    ["pan", 5],
    ["leche", 3],
]

const result = {
    // map aplica una función a cada elemento de una lista,
    // devolviendo una nueva lista con los resultados
    prices: prices.map((p) => p + 5),

    // Object.fromEntries convierte una lista de pares [clave, valor]
    // en un objeto, usando el primer elemento como clave y el segundo como valor
    stock: Object.fromEntries(stock),
}
```
])

#choice_item(label: "a)", content: [
```ts
{
    prices: [10, 20, 30],
    stock: [["pan", 5], ["leche", 3]],
}
```
])

#choice_item(label: "b)", content: [
```ts
{
    prices: [15, 25, 35],
    stock: [5, 3],
}
```
])

#choice_item(label: "c)", content: [
```ts
{
    prices: 60,
    stock: { pan: 5, leche: 3 },
}
```
])

#choice_item(label: "d)", content: [
CORRECTA
```ts
{
    prices: [15, 25, 35],
    stock: { pan: 5, leche: 3 },
}
```
])

#choice_item(label: "e)", content: [
```ts
{
    prices: [15, 25, 35],
    stock: ["leche", 3],
}
```
])

*PP8-2*. _(Opcional)_ Indica cual será el resultado de la siguiente operación. Recuerda que:
- `map`: aplica una función a cada elemento de una lista, devolviendo una nueva lista con los resultados
- `Object.fromEntries`: convierte una lista de pares `[clave, valor]` en un objeto, usando el primer elemento como clave y el segundo como valor

#code_block(content: [
```ts
function createInventory ( items: string[] ) : Object {
    return Object.fromEntries(
        items.map( item => [ item, 100 ])
    )
}

createInventory(["banana", "apple"])
```
])

#choice_item(label: "a)", content: [
```ts
TypeError: Iterator value banana is not an entry object
```
])

#choice_item(label: "b)", content: [
CORRECTA
```ts
{ banana: 100, apple: 100 }
```
])

#choice_item(label: "c)", content: [
```ts
[
    ["banana", 100],
    ["apple", 100],
]
```
])

#choice_item(label: "d)", content: [
```ts
{ banana: undefined, apple: undefined }
```
])

#choice_item(label: "e)", content: [
```ts
["apple", 100]
```
])

== Respuestas Libres

*En esta sección editaras `weathercli` un programa ya empaquetado en Nixty*. En cada ejercicio deberás modificar el código siguiendo las instrucciones.

*Se te proporcionará un entorno de desarrollo en línea (Codespaces)* con todas las herramientas necesarias, asi que no necesitas instalar nada en tu computadora.

Abre ahora el entorno: #link(codespace)[Abrir Codespace]#footnote[#link(codespace)]. Tarda unos minutos en iniciar; déjalo abierto en otra pestaña.

Para cada ejercicio:

1. Lee la instrucción.
2. Modifica el código proporcionado.
3. Guarda el archivo (`Ctrl+S`) y verifica que la solución funcione desde una terminal del Codespace (menú _Terminal → New Terminal_). *Cada ejercicio indica qué comando usar y qué resultado esperar*.
4. Cuando estés conforme con tu respuesta, copia el código solicitado y pégalo en el cuestionario.
5. No cierres el editor, lo usarás en cada ejercicio.

*Los ejercicios son independientes entre sí. Si no logras resolver uno, puedes continuar con el siguiente.*
\
\
\
*PE9-1*. Abre *Codespaces* (link abajo), trabajaras en `nixty.ts`. Reemplaza el contenido con el *Código inicial*.

*Contexto*\
Has empaquetado *`weathercli`* un script que consulta el clima de una ciudad. Actualmente el paquete solo está disponible para la plataforma `x86_64-linux`.

*Instrucciones*\
Modifica el archivo `nixty.ts` para que también soporte los siguientes sistemas:

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

*Cómo probarlo*\
Ejecuta `nixty generate` y luego `nix flake show`. Bajo `packages` deben aparecer los 4 sistemas (los que no son el del Codespace aparecen como `omitted`, eso es normal):

#code_block(content: [
```
└───packages
    ├───aarch64-darwin
    │   └───weathercli omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   └───weathercli omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   └───weathercli omitted (use '--all-systems' to show)
    └───x86_64-linux
        └───weathercli: package 'weathercli-1.0.0'
```
])

Luego ejecuta `nixty run weathercli`: el programa debe seguir funcionando y mostrar el clima de Tokyo:

#code_block(content: [
```
https://wttr.in/Tokyo?m&format=%l:+%c+%t
Tokyo: ☀️  +23°C
```
])

Cuando termines, copia todo el contenido de `nixty.ts` y pégalo abajo.

*❓ Pista*: Los sistemas se indican con los valores de `System`, por ejemplo `System.aarch64Linux`, en el atributo `systems` del paquete.

#link(codespace)[Abrir Codespace]

*Código inicial*

#code_block(content: [
```ts
import { Definition, Nixpkgs, Package, Path, Source, System, nix } from "nixty-lib"

const SYSTEMS = [System.x86_64Linux]

const NIX_PKGS = new Nixpkgs({ tag: "nixos-unstable" })

const DefaultConfig = (system: System) =>
    NIX_PKGS.getExpresion("writeText", system)(
        "weathercli-config.json",
        JSON.stringify({
            city: "Tokyo",
            units: "metric",
            format: "compact",
        }),
    )

// PACKAGES
// ===========
// Paquete WeatherCLI
const weathercli = new Package({
    name: "weathercli",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchInternalPath(".")),
        deps: {
            atRuntime: NIX_PKGS.getPackages(["curl", "jq"], system),
        },
        phases: (out) => ({
            install: nix`
                mkdir -p ${out}/bin ${out}/share/weathercli
                install -m755 weathercli.sh ${out}/bin/weathercli
                install -m644 ${DefaultConfig(system)} ${out}/share/weathercli/config.json
            `,
            postFixup: nix`
                wrapProgram ${out}/bin/weathercli \
                    --set-default WEATHERCLI_CONFIG ${out}/share/weathercli/config.json
            `,
        }),
    }),
})

export default new Definition({
    description: "weathercli — reporte del clima en la terminal",
    nixpkgs: NIX_PKGS,
    packages: [weathercli],
})
```
])

*PE10-1*. *Antes de empezar, reemplaza todo el contenido de `nixty.ts` con el código inicial de abajo.*

*Contexto*\
`weathercli` utiliza un archivo de configuración llamado `weathercli-config.json` para indicar la ciudad a consultar. Sin embargo, el programa *también funciona si ese archivo no existe*.

Actualmente ese archivo es creado por Nixty.

*Instrucciones*\
Modifica el código para que Nixty deje de generar el archivo de configuración.

*Cómo probarlo*\
Ejecuta `nixty run weathercli`. Debería mostrar una ciudad diferente a Roma:

#code_block(content: [
```
https://wttr.in/?m&format=%l:+%c+%t
Ashburn, Virginia, US: ☀️  +18°C
```
])

Cuando termines, copia todo el contenido de `nixty.ts` y pégalo abajo.

*❓ Pista*: Busca la parte del código donde se crea o escribe el archivo `weathercli-config.json` y los lugares donde son usadas.

#link(codespace)[Abrir Codespace]

*Código inicial*

#code_block(content: [
```ts
import { Definition, Licenses, Nixpkgs, Package, Path, Source, System, nix } from "nixty-lib"

const SYSTEMS = [System.x86_64Linux, System.aarch64Linux, System.x86_64Darwin, System.aarch64Darwin]

const NIX_PKGS = new Nixpkgs({ tag: "nixos-unstable" })

// Genera el archivo de configuración por defecto como JSON,
// a partir de un objeto de TypeScript.
const DefaultConfig = (system: System) =>
    NIX_PKGS.getExpresion("writeText", system)(
        "weathercli-config.json",
        JSON.stringify({
            city: "Roma",
            units: "metric",
            format: "compact",
        }),
    )

// PACKAGES
// ==========
// Paquete WeatherCLI
const weathercli = new Package({
    name: "weathercli",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchInternalPath(".")),
        deps: {
            atRuntime: NIX_PKGS.getPackages(["curl", "jq"], system),
        },
        phases: (out) => ({
            install: nix`
                mkdir -p ${out}/bin ${out}/share/weathercli
                install -m755 weathercli.sh ${out}/bin/weathercli
                install -m644 ${DefaultConfig(system)} ${out}/share/weathercli/config.json
            `,
            postFixup: nix`
                wrapProgram ${out}/bin/weathercli \
                    --set-default WEATHERCLI_CONFIG ${out}/share/weathercli/config.json
            `,
        }),
        metadata: {
            description: "Reporte del clima en la terminal, configurable vía un archivo JSON",
            mainProgram: "weathercli",
            license: Licenses.MIT,
        },
    }),
})

export default new Definition({
    description: "weathercli — reporte del clima en la terminal",
    nixpkgs: NIX_PKGS,
    packages: [weathercli],
})
```
])

*PE11-1*. *Antes de empezar, reemplaza todo el contenido de `nixty.ts` con el código inicial de abajo.*

*Contexto*\
`weathercli` ya está correctamente empaquetado. Ahora quieres crear una `DevShell` donde ese paquete esté disponible.

*Instrucciones*\
Modifica el código para crear una `DevShell` llamada `dev` que incluya el paquete `weathercli`.

*Cómo probarlo*\
Ejecuta `nixty develop dev` para entrar a la `DevShell`, dentro de ella, ejecuta `weathercli`. Debe mostrar el clima de Roma:

#code_block(content: [
```
https://wttr.in/Roma?m&format=%l:+%c+%t
Roma: ☀️  +23°C
```
])

Sal del entorno con `exit`.

Cuando termines, copia todo el contenido de `nixty.ts` y pégalo abajo.

*❓ Pista:* Puedes acceder al paquete de `weathercli` mediante el método `getDerivation`, por ejemplo: `weathercli.getDerivation(System.x86_64Linux)`. Y crear una DevShell con `new DevShell`.

#link(codespace)[Abrir Codespace]

*Código inicial*

#code_block(content: [
```ts
import { Definition, Licenses, Nixpkgs, Package, Path, Source, System, nix } from "nixty-lib"

const SYSTEMS = [System.x86_64Linux, System.aarch64Linux, System.x86_64Darwin, System.aarch64Darwin]

const NIX_PKGS = new Nixpkgs({ tag: "nixos-unstable" })

// Genera el archivo de configuración por defecto como JSON,
// a partir de un objeto de TypeScript.
const DefaultConfig = (system: System) =>
    NIX_PKGS.getExpresion("writeText", system)(
        "weathercli-config.json",
        JSON.stringify({
            city: "Roma",
            units: "metric",
            format: "compact",
        }),
    )

// PACKAGES
// ===========
// WeatherCLI package
const weathercli = new Package({
    name: "weathercli",
    systems: SYSTEMS,
    definition: (system) => ({
        version: "1.0.0",
        src: new Source(Path.fetchInternalPath(".")),
        deps: {
            atRuntime: NIX_PKGS.getPackages(["curl", "jq"], system),
        },
        phases: (out) => ({
            install: nix`
                mkdir -p ${out}/bin ${out}/share/weathercli
                install -m755 weathercli.sh ${out}/bin/weathercli
                install -m644 ${DefaultConfig(system)} ${out}/share/weathercli/config.json
            `,
            postFixup: nix`
                wrapProgram ${out}/bin/weathercli \
                    --set-default WEATHERCLI_CONFIG ${out}/share/weathercli/config.json
            `,
        }),
        metadata: {
            description: "Reporte del clima en la terminal, configurable vía un archivo JSON",
            mainProgram: "weathercli",
            license: Licenses.MIT,
        },
    }),
})

// DEVSHELLS
// ===========
// escribe aqui...

export default new Definition({
    description: "weathercli — reporte del clima en la terminal",
    nixpkgs: NIX_PKGS,
    packages: [weathercli],
})
```
])
