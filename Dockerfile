# Official Dev Containers base image: Debian 13 + Node 24 + git + a non-root
# `node` user already set up (sudo available).
# Node 24 = LTS, active until 2026-10-20, supported until 2028-04-30.
# This image has no `lts` tag: the major is pinned by hand. Dependabot (the
# `docker` ecosystem) opens a PR when the next one ships.
FROM mcr.microsoft.com/devcontainers/typescript-node:24

# The named volumes declared in devcontainer.json mount onto these paths. We
# create them here, owned by `node`, otherwise Docker creates them on the fly
# with root as owner and writes fail.
RUN mkdir -p /home/node/.claude \
             /home/node/.config/gh \
             /home/node/.local/bin \
 && chown -R node:node /home/node

# zsh and oh-my-zsh already ship with the base image; the only thing that needs
# root here is making zsh the login shell for `node`. The theme and the plugins
# come further down, once we have dropped to that user — see "prompt: agnoster".
# VS Code opens its terminals through its own profile: see
# `terminal.integrated.defaultProfile.linux` in devcontainer.json.
RUN chsh -s /usr/bin/zsh node

# GitHub credentials delegated to `gh`, at the system level rather than in
# ~/.gitconfig: the latter lives on the overlay (lost on rebuild) and VS Code
# overwrites it with the host's. Equivalent to `gh auth setup-git`, made durable.
# `gh` is installed by the Feature AFTER this Dockerfile: only its presence at
# runtime matters, not at build time.
RUN git config --system credential."https://github.com".helper "!gh auth git-credential"

# Both installers below write into $HOME and do not require root. As root, the
# binaries would land in /root/.local, out of reach.
USER node
ENV HOME=/home/node
# `pnpm setup` puts the executables (pnpm, pnpx, pnx, pn) in $PNPM_HOME/bin, not
# directly in $PNPM_HOME — hence the `/bin` in PATH.
ENV PNPM_HOME=/home/node/.local/share/pnpm
ENV PATH=/home/node/.local/bin:$PNPM_HOME/bin:$PATH

# --- prompt: agnoster + the zsh-users trio ------------------------------------
# The base image already ships zsh 5.9, oh-my-zsh and `agnoster.zsh-theme`; only
# the three plugins are missing. Cloned by hand rather than through
# deluan/zsh-in-docker, whose last step is `zshrc_template > ~/.zshrc` — an
# overwrite, not an append: it would wipe the pnpm block and the gh-auth line
# both added below.
#
# The tags are pinned, and they are the one thing here Dependabot cannot watch:
# no ecosystem reads a `git clone` in a Dockerfile. Bump them by hand.
# `--depth 1` on the tag: the history is dead weight inside the image. Expect one
# `refs/tags/0.8.0 ... is not a commit!` line in the build log — git says that of
# an annotated tag in a shallow clone; the checkout is correct regardless.
RUN for p in zsh-autosuggestions@v0.7.1 \
             zsh-completions@0.36.0 \
             zsh-syntax-highlighting@0.8.0; do \
      git clone --depth 1 --branch "${p#*@}" \
        "https://github.com/zsh-users/${p%@*}" \
        "$HOME/.oh-my-zsh/custom/plugins/${p%@*}"; \
    done

# `zsh-syntax-highlighting` must stay LAST in `plugins=()`: it wraps the ZLE
# widgets the others install. `git` is kept — it is what the base image had.
#
# `zsh-completions` is deliberately NOT in that list. oh-my-zsh.sh:92 puts
# `$ZSH_CUSTOM/plugins/<name>` on `fpath` before its `compinit` (line 127), but
# that repo keeps its completion functions one level down in `src/`, which its
# plugin file only adds at line 204 — after compinit has already run. Listing it
# would be a silent no-op; the `fpath+=` below, injected before oh-my-zsh.sh is
# sourced, is what actually works. `$fpath` is part of the zcompdump cache key
# (oh-my-zsh.sh:115), so the dump regenerates on its own.
#
# DEFAULT_USER suppresses agnoster's leading `node@<hash>` segment, which in a
# container only ever shows a throwaway hostname. agnoster reads it on every
# prompt (agnoster.zsh-theme:167), so appending after the source line is fine.
RUN sed -i \
      -e 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' \
      -e 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' \
      -e '/^source \$ZSH\/oh-my-zsh\.sh/i fpath+=("$ZSH/custom/plugins/zsh-completions/src")' \
      "$HOME/.zshrc" \
 && echo 'DEFAULT_USER="node"' >> "$HOME/.zshrc"

# --- pnpm, official installer -------------------------------------------------
# Corepack is being removed from Node distributions: it can no longer serve as a
# stable foundation. The official script drops in a standalone binary.
# `pnpm setup` reads $SHELL to pick which rc file to edit; inside a `RUN` it is
# empty, hence the explicit SHELL. The `ENV PATH` above stays the source of
# truth — the line appended to .zshrc is only a safety net.
# To pin a version: prefix with `PNPM_VERSION=x.y.z`.
RUN curl -fsSL https://get.pnpm.io/install.sh | env SHELL=/usr/bin/zsh sh - \
 && pnpm --version

# --- Claude Code, native installer --------------------------------------------
# `bash -s stable` follows the stable channel, about a week behind the default
# channel and without the releases carrying major regressions. Here `bash` names
# the script's interpreter, not the user's shell.
# To pin an exact version: `bash -s 2.1.34`.
# The trailing `claude --version` fails the build on an incomplete install,
# rather than deferring the problem to the first terminal.
RUN curl -fsSL https://claude.ai/install.sh | bash -s stable \
 && claude --version

# --- `gh auth login` prompt on the first terminal ------------------------------
# The details and the reasoning live in the file itself. In short: this prompt
# cannot live in postCreateCommand, which has no TTY.
COPY --chown=node:node .devcontainer/gh-auth-prompt.zsh /home/node/.gh-auth-prompt.zsh
RUN echo '[[ -f "$HOME/.gh-auth-prompt.zsh" ]] && source "$HOME/.gh-auth-prompt.zsh"' \
      >> /home/node/.zshrc

# The Features (github-cli) install as root after this Dockerfile.
USER root
