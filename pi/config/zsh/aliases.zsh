alias c='clear'
alias n='clear && fastfetch'
alias sr='source ~/.zshrc && echo "shell reloaded"'
alias path='echo $PATH | tr ":" "\n"'
alias ports='netstat -tulpn 2>/dev/null'
alias lip="ip -4 -o addr show scope global | awk '{print \$2, \$4}'"

# alpine
alias up='doas apk update && doas apk upgrade'
alias add='doas apk add'
alias del='doas apk del'
alias search='apk search'
alias svc='doas rc-service'
alias svcs='rc-status'

# eza
alias ls='echo && eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias lsa='echo && eza --color=always --long --git --icons=always'
alias lsaa='echo && eza --color=always --long --git --icons=always -a'
alias lst='echo && eza --color=always --tree --git --no-filesize --icons=always --no-time --no-user --no-permissions'

# git
alias gs='git status -sb'
alias ga='git add'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'

alias cat='bat -pp'
alias grep='rg'
alias top='btop'
alias v='nvim'
alias q='tmux detach'
alias qa='tmux kill-server'

# pi
alias temp='moon temp'
alias throttle='moon throttle'
