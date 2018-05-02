[ -r ~/.sh_debug ] && ~/.sh_debug .zshrc 

# common to all shells
[ -r ~/.shrc ] && . ~/.shrc # common rc file

# umask 0027 # in .profile
# stty -ixon # disable Ctrl-S/Ctrl-Q, is it the default?
# [ "$TERM" = "dumb" ] || export TERM=xterm-256color
# path=(~/bin ~/.local/bin /usr/local/cuda/bin /usr/local/go/bin ~/android/android-sdk-linux_86 ~/bin/gsutil ~/google_appengine $JAVA_HOME/bin $path)
# should path be exported?
# export LUA_INIT=@$HOME/bin/init.lua # only for interactive use => aliases

# specific to zsh

HISTFILE=~/.histfile
HISTSIZE=30000
SAVEHIST=30000
fpath=(~/.zsh $fpath)

setopt auto_list list_ambiguous list_packed
#setopt correct complete_aliases complete_in_word alwaystoend
setopt auto_param_keys auto_param_slash
setopt auto_cd equals
setopt hash_cmds hash_dirs
setopt hist_ignore_space hist_ignore_dups hist_find_no_dups
setopt append_history # share_history
setopt extended_glob # enables ^x x~y x# x##
setopt extended_history

bindkey -e
bindkey " " magic-space # history expansion on space
bindkey '\eH' run-help
bindkey '\e[A' up-line-or-search
bindkey '\e[B' down-line-or-search
bindkey '\e[5~' history-beginning-search-backward
bindkey '\e[6~' history-beginning-search-forward
# make home, end, and del work in archlinux and freebsd
bindkey '\eOH' beginning-of-line
bindkey '\eOF' end-of-line
bindkey '\e[3~' delete-char
# make home, end work in console
bindkey '\e[1~' beginning-of-line
bindkey '\e[4~' end-of-line
#bindkey -M menuselect '^o' accept-and-infer-next-history # doesn't work for some reason

zstyle :compinstall filename ~/.zshrc
zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select=5
zstyle ':completion:*' urls ~/.zsh/urls
autoload -Uz compinit
compinit

autoload zmv
alias zmv='noglob zmv -v'
alias zcp='noglob zmv -vC'

if [ "$TERM" = "dumb" ]; then
  unset zle_bracketed_paste # stop adding \33[?2004h after prompt
else
  if [ -n "$LS_COLORS" ]; then
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
  fi

  autoload edit-command-line
  zle -N edit-command-line
  bindkey '^Xe' edit-command-line

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
  local prompt_chroot="${debian_chroot:+($debian_chroot)}"
 
  # PROMPT="$prompt_host:$prompt_cwd %# "
  PROMPT="$prompt_chroot$prompt_user%B@%b$prompt_host:$prompt_cwd %# "
  RPROMPT="$prompt_ecode$prompt_time"

  case "$TERM" in
      xterm*|rxvt*) precmd () {print -Pn "\e]0;%n@%m: %~\a"} ;;
  esac

  WATCH=all

  [ -r ~/bin/z.sh ] && source ~/bin/z.sh && HOME=$(readlink -f $HOME)
  [ -r /etc/zsh_command_not_found ] && source /etc/zsh_command_not_found
  source /usr/share/doc/pkgfile/command-not-found.zsh 2>/dev/null # arch
fi

[ -r ~/.zshrc.local ] && source ~/.zshrc.local
