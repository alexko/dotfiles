#!/usr/bin/env zsh

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
bindkey " " magic-space # history expansion on space
stty -ixon # disable Ctrl-S/Ctrl-Q
path=(~/bin /usr/local/cuda/bin ~/android/android-sdk-linux_86 ~/bin/gsutil $JAVA_HOME/bin $path)
fpath=(~/.zsh $fpath)
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/alkos/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select=5
#bindkey -M menuselect '^o' accept-and-infer-next-history # doesn't work for some reason
zstyle ':completion:*' urls ~/.zshrc/urls

setopt auto_list list_ambiguous list_packed
#setopt correct complete_aliases complete_in_word alwaystoend
setopt auto_param_keys auto_param_slash
setopt auto_cd equals
setopt hash_cmds hash_dirs
setopt hist_ignore_space hist_ignore_dups hist_find_no_dups
setopt append_history # share_history
setopt extended_glob # enables ^x x~y x# x##
setopt extended_history

if [ "$TERM" != "dumb" ]; then
  export TERM=xterm-256color
  if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors)"
    alias ls='ls -F --color=auto'
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
  fi
  if [ -x /usr/bin/lesspipe ]; then
    eval "$(lesspipe)" # http://www.cyberciti.biz/tips/less-is-more-the-hidden-treasure-of-less-command.html
  fi

  autoload colors zsh/terminfo
  colors
  for color in red green blue yellow magenta cyan white; do
    eval c_$color='%{$fg[$color]%}'
    eval c_l$color='%{$terminfo[bold]$fg[$color]%}'
  done
  c_none="%{$terminfo[sgr0]%}"

  local prompt_user="%(!.$c_lred.$c_lgreen)%n$c_none"
  local prompt_host="%(!.$c_lred.$c_lgreen)%m$c_none"
  local prompt_host="$c_lyellow%m$c_none"
  local prompt_cwd="$c_lwhite%40<..<%~%<<$c_none"
  local prompt_time="$c_blue%*$c_none"
  local prompt_ecode="%(?..$c_lred%?$c_none )"
 
#  PROMPT="$prompt_host:$prompt_cwd %# "
  PROMPT="$prompt_user%B@%b$prompt_host:$prompt_cwd %# "
  RPROMPT="$prompt_ecode$prompt_time"
# Make right Alt key to work as Meta
  # xmodmap -e "keysym ISO_Level3_Shift = Meta_R"
  xmodmap -e "keycode 92 = Meta_R"
fi

export LUA_INIT=@$HOME/bin/init.lua
export PAGER=less
export EDITOR=vim
export JAVA_HOME=/usr/lib/jvm/java-6-sun
#export PATH=$PATH:/usr/local/cuda/bin:$JAVA_HOME/bin:$HOME/android/android-sdk-linux_86:$HOME/bin/gsutil
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/lib
export PYTHONPATH=$PYTHONPATH:$HOME/gsutil/boto
export alexko=1329486
unset http_proxy

# aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias g=grep
alias m=less
#alias m=make
alias e='emacs -nw'
ec () emacsclient -c "$@"
ec_remember () emacsclient -e '(remember-other-frame)'
ec_start () emacs --daemon
ec_stop () {
  emacsclient --eval "(progn (setq kill-emacs-hook 'nil) (kill-emacs))";
  rm -f ~/.emacs.desktop.lock
}
alias xml=xmlstarlet
alias adb="/home/alkos/android/android-sdk-linux_86/tools/adb -d"
function dupscreen { screen bash -c "cd \"$PWD\" && exec $SHELL --login" }
alias ,d=dupscreen
alias mk_cm='for h in face dev sun alex1; do ssh -MNf $h; done'
alias rm_cm='pkill -f "ssh -MNf"'
alias relcom='f=(~/.zsh/*(.)); unfunction $f:t; autoload -U ~/.zsh/*(:t)'

umask 0066

[ -r ~/.zshrc.local ] && source ~/.zshrc.local
[ -x /usr/bin/calendar ] && /usr/bin/calendar

