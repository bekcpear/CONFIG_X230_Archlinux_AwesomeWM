# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000
bindkey -v
KEYTIMEOUT=1
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/u/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

autoload -Uz add-zsh-hook
function xterm_title_precmd () {
  print -Pn '\e]0;%n@%m:%1~\a'
}
function xterm_title_preexec () {
  print -Pn "\e]0;%#> ${(p)1} | %n@%m:%1~\a"
}
add-zsh-hook -Uz precmd xterm_title_precmd
add-zsh-hook -Uz preexec xterm_title_preexec

PROMPT=" %B%F{11}%~%f %(?.%F{238}>%f%F{244}>%f%F{250}>%f.%F{124}>%f%F{160}>%f%F{196}>%f) %b"
RPROMPT="%(?..%F{196}%? %f)%F{238}%*%f"

export GOPATH=~/go
export PATH=$PATH:~/go/bin:~/s/yubico-piv-tool/bin

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/ykman

#alias yd="~/cc/ydcv.sh"
alias yd="ydcv"
alias pb="/home/u/cc/vimcnpaste.sh"

export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpg-connect-agent updatestartuptty /bye > /dev/null

