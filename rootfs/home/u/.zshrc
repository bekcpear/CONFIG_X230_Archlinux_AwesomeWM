# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
bindkey -v
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

PROMPT=" %B%F{11}%~%f %(?.%F{239}>%f%F{248}>%f>.%F{124}>%f%F{160}>%f%F{196}>%f) %b"
RPROMPT="%(?..%F{196}%? %f)%F{238}%*%f"

export GOPATH=~/go
export PATH=$PATH:~/go/bin
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/u/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
