HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_reduce_blanks
setopt inc_append_history

# Homebrew supplies system dependencies on Apple Silicon. Repository-managed
# release binaries are placed ahead of it below.
if [[ "$OSTYPE" == darwin* ]] && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

[ -r "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

# Prefer binaries installed by install_packages.sh over OS and Homebrew copies.
# The unique path array prevents duplicates when this file is sourced repeatedly.
typeset -U path PATH
path=("$HOME/.local/bin" $path)

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"

if [ -d "$ZSH_PLUGINS/pure" ]; then
  fpath+=("$ZSH_PLUGINS/pure")
  autoload -U promptinit && promptinit
  prompt pure
fi

[ -r "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"

if command -v fzf >/dev/null; then
  source <(fzf --zsh)
else
  [ -r /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -r /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
fi

bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Local overrides may modify PATH; enforce repository-installed binaries last.
path=("$HOME/.local/bin" $path)

tnew() {
    local name
    name=$(basename "$PWD")

    tmux new-session -d -s "$name" -c "$PWD"
}

# This plugin must be sourced after all widgets and key bindings are defined.
[ -r "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
