# mini-boilerplate-ts

Minimal boilerplate: a Docker devcontainer with Node 24, pnpm, git, the GitHub
CLI and Claude Code, using zsh + oh-my-zsh (the `agnoster` prompt) as the
default shell. The goal is to confine the agent to a container, so the host
machine only exposes the project directory.

## Requirements (on the host)

- Docker
- VS Code + the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
  extension (or `npx @devcontainers/cli up --workspace-folder .`)
- A [Nerd Font](https://www.nerdfonts.com/) installed on the host (e.g.
  MesloLGS NF): the `agnoster` prompt draws its separators with Powerline
  glyphs, which any other font renders as boxes. The font is picked in
  `devcontainer.json` (`terminal.integrated.fontFamily`) but resolved by VS Code
  on your machine, so nothing in the image can supply it.

## Getting started

1. `gh repo create my-project --template ahafidi/mini-boilerplate-ts --private --clone`
   (requires this repo to be marked as a template in its GitHub settings —
   otherwise plain `gh repo fork` or `git clone` does the job)
2. Open the folder in VS Code → **Reopen in Container**
3. In the container terminal:
   ```sh
   claude           # once, persisted in a volume
   ```
   `gh auth login` fires on its own when the first terminal opens, as long as no
   token is present (`Ctrl-C` to skip). The mechanism lives in
   `.devcontainer/gh-auth-prompt.zsh`: it cannot go in `postCreateCommand`,
   which has no interactive terminal — `gh` would wait there on input that never
   comes and stall container creation.

Later rebuilds do not ask again: the tokens live in named volumes. HTTPS pushes
go through `gh`, wired at the system level in the Dockerfile (a durable
equivalent of `gh auth setup-git`).

The pnpm store, on the other hand, is not in a volume: it stays in the project
(`.pnpm-store/`, git-ignored). pnpm requires the store and `node_modules` to
share a filesystem to create hard links, which a Docker volume cannot do against
a project mounted over virtiofs.

## What is confined and what is not

| Isolated from the container       | Reachable from the container               |
| --------------------------------- | ------------------------------------------ |
| Host filesystem outside workspace | The whole workspace, `.env` files included |
| Host SSH keys and credentials     | The `gh` token and Claude Code credentials |
| Host processes and daemons        | All outbound network (no firewall)         |

The network is open: that is the trade-off chosen here for simplicity. An
allowlist `init-firewall.sh` remains possible later (see below).

## The TypeScript project

```sh
pnpm install
pnpm start        # node src/main.ts
pnpm check        # typecheck + lint + format + tests
```

The toolchain is all native binaries:

| Role       | Tool                     | Command          |
| ---------- | ------------------------ | ---------------- |
| Types      | `typescript` 7 (Go port) | `pnpm typecheck` |
| Lint       | `oxlint` (Rust)          | `pnpm lint`      |
| Formatting | `oxfmt` (Rust)           | `pnpm fmt`       |
| Tests      | `vitest`                 | `pnpm test`      |

Three things you would not guess:

- **No build step.** Node 24 strips types on the fly, so `node src/main.ts` is
  enough. In exchange `tsconfig.json` enables `erasableSyntaxOnly` (no `enum`,
  no `namespace`) and relative imports carry the real extension: `./Greeter.ts`.
- **`typescript` and `oxlint-tsgolint` move together.** The latter provides
  type-aware linting and tracks the former's version (`7.0.2` ↔ `7.0.2001`):
  updating them separately puts them out of sync.
- **`tsgo` no longer exists under that name.** The Go port ships as stable in
  `typescript@7`, under the `tsc` command. The `@typescript/native-preview`
  package, which exposes `tsgo`, stayed on a preview build.

Type-aware linting catches forgotten `Promise`s, but **not** forgotten
`Effect`s: an `Effect` is not a thenable, and left bare it simply does nothing.

## Options to enable later

- **Outbound firewall**: an `init-firewall.sh` script + `runArgs` with
  `NET_ADMIN` and `NET_RAW`, essential if you want to run
  `claude --dangerously-skip-permissions` against untrusted code.
- **Per-repo isolation**: suffix the volumes' `source=` with `-${devcontainerId}`
  so each project gets its own credentials.
- **Organization policy**: `/etc/claude-code/managed-settings.json` copied in
  from the Dockerfile.

Reference: <https://code.claude.com/docs/en/devcontainer>

## License

MIT — see [LICENSE](LICENSE).
