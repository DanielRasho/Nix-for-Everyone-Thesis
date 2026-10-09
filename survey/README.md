# Nixty survey

Web survey for the thesis usability study comparing Nix and Nixty.
Go API (`server/`), React SPA (`client/`), Postgres (`db/`).

## Requirements

- [Nix](https://nixos.org/download) with flakes enabled
- Docker, with the daemon running

## Run

```sh
nix develop          # shell with every tool (go, sqlc, moon, process-compose, node, pnpm)
process-compose up   # db + server + client + integration tests
```

- App: http://localhost:3000 · API: http://localhost:3003
- Stopping process-compose **deletes the database**, so every run starts clean.

## Admin login

Development: user **`admin`**, password **`admin-dev-password`**.

They come from `ADMIN_USERNAME` / `ADMIN_PASSWORD` in `server/.env` (and in
`compose.yml` for the Docker build). The account is created, or its password
updated, every time the server starts, so to change it edit the variables and
restart. In production they come from `.env.prod`.

From the admin panel you create participants (username + survey order). Their
password is shown **only once**; use "regenerate password" if it gets lost.
"Exportar CSV" downloads every answer with its time; "Exportar código" downloads
the code answers (free_code) as a zip, one folder per participant and one file
per question (`<username>/<questionId>.nix`).

## Edit the questions

Questions live in `server/content/` (YAML, one file per part):

| File | Content |
|---|---|
| `background.yaml` | Asked once per participant, before the surveys |
| `nix.yaml`, `nixty.yaml` | Tasks of each survey (the file name is the survey id) |
| `feedback.yaml` | Final questionnaire, appended to every survey |

```yaml
- id: PA1-1                # unique in the file, no dots
  kind: choice_code        # info | choice_code | choice_text | free_code | free_text | likert
  prompt: Escoge el código correcto.   # Markdown
  code: |                  # optional: reference code (starter code for free_code)
    let x = 1; in x
  options:                 # choice_code / choice_text only, exactly one correct
    - id: a
      correct: true
      code: |              # choice_code uses `code`, choice_text uses `text`
        { a = 1; }
    - id: b
      code: |
        { a = 1 }

- id: experience
  kind: likert
  scale: 7                 # 5 or 7
  prompt: ¿Cómo calificarías {tool}?   # {tool} = the survey's `tool` field
  items:
    - { id: rating, left: Malo, right: Bueno }
```

- Saving a file reloads the server. If something is wrong (typo in a field, no
  correct option, duplicated id…) the server refuses to start and logs why.
  `moon run server:test-unit` checks the files without starting anything.
- **Never change or delete an `id` once participants have started**: answers point to them.
- Quote option texts that start with a backtick: ``text: "`[ 2 ]`"``.
- In a survey file, `{codespace}` is replaced by its `codespace` link (e.g.
  `[Abrir Codespace]({codespace})`); the server refuses to start if `codespace` is empty.

## Codespaces

The `free_code` tasks (PE9-PE11) are solved in GitHub Codespaces, from the public repo
[`DanielRasho/Thesis-survey`](https://github.com/DanielRasho/Thesis-survey) (local clone:
`~/Documents/thesis-survey`). Everything about it lives there: the devcontainers, the
answer key of the tasks (kept out of git, the repo is public) and the check that builds every
starter and solution. This repo only holds each survey's `codespace` link.

## Other commands

| Command | What |
|---|---|
| `moon run server:test` | Integration tests (needs the server running) |
| `moon run server:test-unit` | Go unit tests + content validation |
| `moon run server:gen` | Regenerate the DB code after editing `server/db/queries.sql` |
| `moon run client:build` | Production build of the client |

## Deploy

```sh
export REGISTRY=docker.io/<user> TAG=latest
moon run server:docker-push client:docker-push db:docker-push   # build + push images

# on the host (variables listed at the top of compose-prod.yml)
docker compose -f compose-prod.yml --env-file .env.prod up -d
```
