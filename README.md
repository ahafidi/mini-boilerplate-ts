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

1. Create your own copy — this repo is a GitHub template:

   ```sh
   gh repo create my-project --template ahafidi/mini-boilerplate-ts --private --clone
   ```

   A plain `gh repo fork` or `git clone` does the job just as well.

2. Open the folder in VS Code → **Reopen in Container**.

3. In the container terminal:

   ```sh
   pnpm install     # dependencies, plus the git hooks via the `prepare` script
   claude           # sign in once, then persisted in a volume
   ```

Nothing installs the dependencies for you: `postCreateCommand` only checks that
the toolchain is present. `pnpm install` is the step that both fills
`node_modules` and wires lefthook into `.git/hooks` — skip it and the commit
hooks stay silent.

`gh auth login` fires on its own when the first terminal opens, as long as no
token is present (`Ctrl-C` to skip). It lives in
`.devcontainer/gh-auth-prompt.zsh` rather than in `postCreateCommand`, which has
no interactive terminal — `gh` would wait there on input that never comes and
stall container creation.

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

The network is open: that is the trade-off chosen here for simplicity.

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

## Branch protection

GitHub cannot read a ruleset from a file in the repository — there is no
`.github/` equivalent of `dependabot.yml` for this. So
`.github/rulesets/main.json` is the source of truth, and applying it is a manual
step on each repo created from this template:

```sh
gh api repos/OWNER/REPO/rulesets --method POST --input .github/rulesets/main.json
```

It requires the `check` and `commitlint` jobs to pass on the default branch, and
refuses merge commits, deletion and force-pushes. `strict_required_status_checks_policy`
is on, so a pull request must also be up to date with the base branch before it
can merge — Dependabot rebases its own branches for this, but a stale PR of your
own needs the **Update branch** button and a fresh CI run. Repository admins bypass all
of it, so a solo owner keeps pushing straight to `main` — the rules bite on
Dependabot and on anyone else.

Which merge buttons a pull request offers is a repository setting rather than a
rule, so it sits outside that file and takes a second call:

```sh
gh api repos/OWNER/REPO --method PATCH \
  -F allow_merge_commit=false -F allow_squash_merge=true -F allow_rebase_merge=true \
  -f squash_merge_commit_title=PR_TITLE
```

Squash and rebase both produce linear history, which is what
`required_linear_history` above enforces; the merge-commit button is the one it
would reject.

`squash_merge_commit_title=PR_TITLE` is what makes a squashed commit's subject
the pull request title, and the `Lint pull request title` step in `ci.yml` is
what keeps that title conventional — otherwise the squashed commit reaches
`main` before anything checks it. The body stays `COMMIT_MESSAGES`: those
messages already passed commitlint, whereas a free-form PR body would trip its
100-character line limit.

## License

MIT — see [LICENSE](LICENSE).
