# GitHub authentication prompt, played on the first interactive terminal.
#
# Why here and not in postCreateCommand: a devcontainer's lifecycle hooks have
# no interactive terminal. `gh auth login` there waits on input that never
# arrives — without even printing its prompt — and stalls container creation. A
# VS Code terminal, by contrast, is a real TTY.
#
# The test looks at hosts.yml rather than `gh auth status`, which queries the
# GitHub API: we want shell startup to be instant and to work offline.
#
# The marker in /tmp survives a stop/start but disappears on rebuild: if you
# skip with Ctrl-C, later terminals stay quiet until the next rebuild.
#
# The guard checks the TTY rather than `[[ -o interactive ]]`: VS Code probes
# the environment at startup with `zsh -lic`, so an interactive shell, but wired
# to pipes. It used to clear the guard, drop the marker, and drown the prompt in
# a stream nobody ever sees — after which the real terminal stayed silent.
# `-t 0` and `-t 1` rule out that probe without ruling out your terminal.

[[ -t 0 && -t 1 ]]                          || return 0
[[ -f /tmp/.gh-login-prompted ]]            && return 0
[[ -s "${HOME}/.config/gh/hosts.yml" ]]     && return 0
command -v gh >/dev/null 2>&1               || return 0

: > /tmp/.gh-login-prompted

print -P "%F{yellow}GitHub CLI is not authenticated.%f Starting \`gh auth login\`…"
print -P "%F{242}Ctrl-C to skip — the prompt returns on the next rebuild.%f"
gh auth login --hostname github.com --git-protocol https
