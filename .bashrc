# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
[ -r ~/.sh_debug ] && ~/.sh_debug .bashrc 
[ -z "$PS1" ] && return     # If not running interactively, don't do anything
[ -r ~/.shrc ] && . ~/.shrc # common rc file

HISTCONTROL=ignoreboth
HISTIGNORE="&:[ ]*:exit" # ignore duplicates, space, exit
HISTSIZE=30000
SAVEHIST=30000

shopt -s histverify   # review history expansion
shopt -s histappend   # append to the history file, don't overwrite it
shopt -s checkwinsize # update LINES and COLUMNS after each command

PS1="\[$p_chr$p_u\]\u\[$p_n\]@\[$p_h\]\h\[$p_n\]:\[$p_w\]\w\[$p_n\] \$ "
# PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

# If this is an xterm or rxvt set the title to user@host:dir
case "$TERM" in
  xterm*|rxvt*) PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1";;
esac

# it might be enabled in /etc/bash.bashrc if /etc/profile sources it
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  . /etc/bash_completion
fi
