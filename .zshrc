# ____  __.________________________.___.___.___.___    ________________________________    _____  .___ _______      _____  .____     
#|    |/ _|   \______   \_   _____/|   |   |   |   |     \__    ___/\_   _____/\______   \  /     \ |   |\      \    /  _  \ |    |    
#|      < |   ||       _/|    __)_ |   |   |   |   |       |    |    |    __)_  |       _/ /  \ /  \|   |/   |   \  /  /_\  \|    |    
#|    |  \|   ||    |   \|        \|   |   |   |   |       |    |    |        \ |    |   \/    Y    \   /    |    \/    |    \    |___ 
#|____|__ \___||____|_  /_______  /|___|___|___|___|       |____|   /_______  / |____|_  /\____|__  /___\____|__  /\____|__  /_______ \
#        \/           \/        \/                                        \/         \/         \/            \/         \/        \/


# ---- variables ----
EXECUTE_INIT_SCRIPT=false

# ---- oh-my-posh ----
if [[ "$TERM_PROGRAM" != "Terminal.app" ]]; then
  eval "$(oh-my-posh init zsh --config ~/.poshthemes/themes/multiverse-neon.omp.json)"
fi

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ---- aliases ----
alias forcesign="sudo xattr -rd com.apple.quarantine"
eval $(thefuck --alias)
alias run-java='cd "$(pwd)" && /usr/bin/env /Users/matejstastny/.sdkman/candidates/java/21.0.4-tem/bin/java -ea -XX:+ShowCodeDetailsInExceptionMessages -cp "/Users/matejstastny/Library/Application Support/Code/User/workspaceStorage/f9f79369a38b7cefb62b63bf2877366d/redhat.java/jdt_ws/lan_8dd94e11/bin"'
alias launch4j='java -jar "/Applications/launch4j/launch4j.jar"'

# ---- Ani-cli ----
function anime() {
  if [[ -z "$1" ]]; then
    ani-cli
  else
    case "$1" in
      -l)
        cat ~/.config/ani-cli/latest.txt
        ;;
      -lset)
        if [[ -z "$2" ]]; then
          echo "No text provided"
        else
          echo "$2" > ~/.config/ani-cli/latest.txt
          echo "Latest: $2"
        fi
        ;;
      -help)
        echo "'-l' - print the last watched anime"
        echo "'-lset' - set the latest watched anime"
        ;;
      *)
        echo "Invalid command, use -help"
        ;;
    esac
  fi
}

# ---- FZF -----
#
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

source ~/fzf-git.sh/fzf-git.sh

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# ---- Bat -----
BAT_THEME="Catppuccin Mocha"

# ---- Eza (better ls) -----

alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"
alias cd="z"

# ---- tmux ----
# zshrc updates
if [[ -n "$TMUX" && -z "$ZSHRC_SOURCED" ]]; then
    export ZSHRC_SOURCED=1
    source ~/.zshrc
fi

alias :qa!='echo "not a nvim window :3"'

# Update tmux status bar whenever the directory changes
chpwd() {
	if [[ -n "$TMUX" ]]; then
		tmux refresh-client -S
	fi
}


# Function to create and set up the tmux 'main' session
setup_tmux_main() {
	if [[ "$EXECUTE_INIT_SCRIPT" == true ]]; then
		tmux send-keys -t main ':qa!' Enter
		sleep 0.05
		tmux send-keys -t main '~/.scripts/terminal-init.sh' Enter
	fi
  tmux attach -t main
}

# ---- EXECUTE COMMANDS ----
setup_tmux_main

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

