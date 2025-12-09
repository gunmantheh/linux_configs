# Repository Guidelines

## Project Structure & Module Organization
- Root holds the dotfiles: `.zshrc` (shell), `.tmux.conf` (tmux), `.vimrc` (Vim), `.yaourtrc` (yaourt), and `.config/lf/lfrc` (lf). Treat them as the source of truth for prompt, keymaps, and tooling.
- Layout matches GNU Stow expectations; keep paths stable so symlinks keep working when linked into `$HOME`.
- Keep tool-specific changes near related blocks (tmux keys together, lf commands together) to keep diffs readable.

## Build, Test, and Development Commands
- Reload Zsh after edits: `source ~/.zshrc` or start a new shell; quick syntax check with `zsh -n ~/.zshrc`.
- Refresh tmux without restarting sessions: `tmux source-file ~/.tmux.conf`.
- Smoke-test Vim startup: `vim -u ~/.vimrc +q`.
- Check lf mappings in a running session: `lf -remote "send $id source ~/.config/lf/lfrc"`; then try `f` (fzf open) and `Ctrl-F` (fzf jump).

## Coding Style & Naming Conventions
- Use spaces for indentation and mirror surrounding formatting; avoid mixing tabs.
- Favor clear alias names (`alias ls="eza -ll"`) and short comments only where behavior is non-obvious.
- Keep keybindings consistent with the existing vi-oriented style and prefix overrides; document surprises.
- Prefer POSIX-friendly shell snippets and guard machine-specific paths with conditionals when possible.

## Testing Guidelines
- After edits, open a new terminal and tmux session to confirm prompt, bindings, and plugins load cleanly.
- Validate fuzzy-find flows (fzf, zoxide, atuin) by running a few lookups; ensure previews still render.
- Re-source configs twice to confirm idempotency (no duplicated PATH entries or repeated bindings).

## Commit & Pull Request Guidelines
- Use short, imperative commit messages (`Add lf fzf jump`, `Refine tmux pane resize`) consistent with existing history.
- Scope changes per tool and mention what you tested (sourced shell, reloaded tmux, opened Vim, exercised lf).
- Reference issues or rationale in the PR description; add screenshots or terminal recordings only when visual changes are involved.

## Security & Configuration Tips
- Never commit secrets or host-specific credentials; keep overrides in local, ignored files.
- When adding plugins or binaries, prefer package-managed installs and note required env vars near the top of the relevant config.
