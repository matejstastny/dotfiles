# ____  __.________________________.___.___.___.___    ________________________________    _____  .___ _______      _____  .____     
#|    |/ _|   \______   \_   _____/|   |   |   |   |     \__    ___/\_   _____/\______   \  /     \ |   |\      \    /  _  \ |    |    
#|      < |   ||       _/|    __)_ |   |   |   |   |       |    |    |    __)_  |       _/ /  \ /  \|   |/   |   \  /  /_\  \|    |    
#|    |  \|   ||    |   \|        \|   |   |   |   |       |    |    |        \ |    |   \/    Y    \   /    |    \/    |    \    |___ 
#|____|__ \___||____|_  /_______  /|___|___|___|___|       |____|   /_______  / |____|_  /\____|__  /___\____|__  /\____|__  /_______ \
#        \/           \/        \/                                        \/         \/         \/            \/         \/        \/

# ---- Variables ----
export APPDATA="$HOME/Library/Application Support"
export SDKMAN_DIR="$HOME/.sdkman"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# ---- Initialization ----
EXECUTE_INIT_SCRIPT=false

# ---- Shell prompt setup ----
#eval "$(oh-my-posh init zsh --config $HOME/.poshthemes/zash.omp.json)"
eval "$(starship init zsh)"

# ---- Zsh Plugins ----
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ---- Aliases ----
eval $(thefuck --alias)
alias forcesign="sudo xattr -rd com.apple.quarantine"
alias java8="sdk default java 8.0.432-amzn"
alias java21="sdk default java 21.0.5-tem"
alias ip="ifconfig | grep 'inet ' | awk '/inet / {print \$2}' | grep -Ev '^(127\.|::)'"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias cd="z"
alias n="clear && echo && command fastfetch"

# ---- Ani-cli Helper Function ----
function anime() {
  if [[ -z "$1" ]]; then
    ani-cli
  else
    case "$1" in
      -l) cat $HOME/.config/ani-cli/latest.txt ;;
      -lset) [[ -n "$2" ]] && echo "$2" > $HOME/.config/ani-cli/latest.txt && echo "Latest: $2" || echo "No text provided" ;;
      -help) echo "'-l' - print the last watched anime\n'-lset' - set the latest watched anime" ;;
      *) echo "Invalid command, use -help" ;;
    esac
  fi
}

# ---- FZF (Fuzzy Finder) ----
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_comprun() {
  local command=$1
  shift
  case "$command" in
    cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'" "$@" ;;
    ssh) fzf --preview 'dig {}' "$@" ;;
    *) fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# ---- Bat (Better Cat) ----
export BAT_THEME="Catppuccin Mocha"

# ---- Tmux attach method ----
tmux_attach_to_main() {
  if [[ "$TERM_PROGRAM" =~ (iTerm\.app|kitty|alacritty|WezTerm) ]]; then
    tmux attach -t main
  fi
}

# ---- Zoxide (Better cd) ----
eval "$(zoxide init zsh)"

# ---- ZSH-highlighting ----
ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=blue,underline
ZSH_HIGHLIGHT_STYLES[precommand]=fg=blue,underline
ZSH_HIGHLIGHT_STYLES[arg0]=fg=blue

# ---- SDKMAN Initialization ----
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# ---- Final Commands ----
tmux_attach_to_main

