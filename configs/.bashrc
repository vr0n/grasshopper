# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=20000
HISTFILESIZE=20000
shopt -s checkwinsize

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
	xterm-color|*-256color|screen) color_prompt=yes;;
    screen) color_prompt=yes;;
esac

force_color_prompt=yes
color_prompt=yes

if [ "$color_prompt" = yes ]; then
    		#PS1='${debian_chroot:+($debian_chroot)}\[\033[00;32m\][\[\033[01;31m\]\u\[\033[00;32m\]@\[\033[01;31m\]\h\[\033[00;32m\]]\[\033[00;32m\][\[\033[01;34m\]\w\[\033[00m\]\[\033[00;32m\]]\n\[\033[01;32m\]>>\[\033[00m\] '
    		PS1="\[$(tput setaf 130)\][\[$(tput setaf 34)\]\u\[$(tput setaf 40)\]@\[$(tput setaf 46)\]\h\[$(tput setaf 130)\]][\[$(tput setaf 154)\]\w\[$(tput setaf 130)\]]\n>>\[$(tput sgr0)\] "
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# TAKE THE BELOW ADVICE... EVENTUALLY
# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

#figlet -f $(/usr/bin/ls /usr/share/figlet/ | sort -R | head -n 1) $(whoami) | lolcat

function ex()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   unzstd $1    ;;      
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

UNAME_OS="$(uname)"
UNAME_DISTRO="$(uname -v)"

if [ "$UNAME_OS" == "Linux" ]; then
	alias ls="ls -lAh --color=auto"
elif [ "$UNAME_OS" == "OpenBSD" ]; then
	alias ls="colorls -lah -G"
fi

# package manager commands
if [[ "$UNAME_DISTRO" == *"Debian"* ]] || [[ "$UNAME_DISTRO" == *"Ubuntu"* ]]; then
  alias grab="apt-get install -y"
  alias purge="apt purge -y"
  alias remove="apt autoremove -y"
  alias update="apt update -y"
  alias upgrade="apt upgrade -y"
elif [[ "$UNAME_DISTRO" == *"Arch"* ]]; then
  alias grab="pacman -Syu"
  alias purge="echo 'update this...'"
  alias remove="echo 'update this...'"
  alias update="pacman -Syu"
  alias upgrade="pacman -Syu"
fi

alias l="ls"
alias ..="cd .."
alias cp="cp -i"
alias df="df -h"
alias mv="mv -i"
alias p="upower --dump | grep 'percentage\|state' | sort | uniq"
alias rm="printf 'stop using rm... use tp/tl/te instead...\n'; false"
alias search="apt search"
alias talist="~/.config/talist/src/talist"
alias te="trash-empty"
alias tl="trash-list"
alias tp="trash-put"
alias when="history | grep"
alias vim="nvim"
alias binwalk="binwalk --run-as=root"

alias aarch64="qemu-aarch64-static -L /usr/aarch64-linux-gnu/"

# golang
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin/

# batcat special case
if type batcat 1>/dev/null 2>/dev/null; then
  alias cat="batcat"
fi
