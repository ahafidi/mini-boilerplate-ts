# Project context

<!-- Loaded automatically by Claude Code when a session starts. -->
<!-- Fill this in on every fork of this boilerplate. -->

## Stack

- Strict TypeScript, Node 24, pnpm
- Effect (`effect`) for orchestration, error handling and effects

## Conventions

- No thrown exceptions: domain errors are `Data.TaggedError`s surfaced through
  `Effect`'s error channel.
- Dependencies go through `Context.Tag` / `Layer`, never a direct import of an
  implementation in the domain layer.

## Commands

```sh
pnpm install
pnpm typecheck
pnpm test
```
