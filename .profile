# .profile - Bourne Shell startup script for login shells
[ -r ~/.sh_debug ] && ~/.sh_debug .profile

expath () { # Usage: vappend PATH dir1 dir2 ...
  local dir f acc dup nex val 
  case "$1" in
    -f) f=1; shift ;;
    -b)      shift ;;
  esac
  local var=$1; shift; eval val=\$$var
  for dir in "$@"; do # checks directory existence in fs and in the path
    [ $f ] && check=":$acc:" || check=":$val:$acc:"
    case "$check" in *:$dir:*) dup=$dup${dup:+:}$dir; continue; esac
    [ -d $dir ] && acc=$acc${acc:+:}$dir || nex=$nex${nex:+:}$dir 
  done
  [ "$dup" -a "$debug" ] && $debug expath: $var dups $dup
  [ "$nex" -a "$debug" ] && $debug expath: $var nonexistent $nex
  [ -z "$acc" ] && return
  [ $f ] && export $var=$acc${val:+:}$val || export $var=$val${val:+:}$acc
}

umask 027
export COMPUTE=:0 PAGER='less -R' LESS=-i EDITOR=vim BLOCKSIZE=K
export JAVA_HOME=/usr/lib/jvm/java-6-sun
expath -f PATH ~/bin ~/.local/bin
expath PATH ~/bin/gsutil ~/google_appengine /usr/local/cuda/bin
expath PATH /sbin /bin /usr/sbin /usr/bin /usr/local/sbin /usr/local/bin /usr/games
expath PATH $JAVA_HOME/bin
expath LD_LIBRARY_PATH /usr/local/cuda/lib64 /usr/local/cuda/lib
# expath PYTHONPATH ~/bin/gsutil/boto 
expath GOPATH ~/tmp/go
expath PATH /usr/local/go/bin ~/tmp/go/bin
expath PYLEARN2_DATA_PATH ~/pylearn2/data

# export PATH=$(awk '{ gsub("~", HOME); print }' ORS=: HOME=$HOME <<EOT
# ~/bin
# $HOME/.local/bin
# /usr/sbin:/usr/bin
# /sbin:/bin
# /bin:/usr/local/sbin:/usr/local/sbin
# ~/bin/gsutil
# ~/google_appengine
# /usr/local/go/bin
# /usr/local/cuda/bin
# /usr/games
# /usr/local/jvm/java-6-sun/bin
# EOT
# )

# export PYTHONPATH=$PYTHONPATH:$HOME/gsutil/boto
# export PATH=$HOME/bin:$HOME/.local/bin:$HOME/bin/gsutil:/usr/local/cuda/bin:/usr/local/go/bin:$PATH:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/games:$JAVA_HOME/bin
# bash and zsh expand ~s in path, but dash doesn't
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/lib
# export PYTHONPATH=$PYTHONPATH:$HOME/gsutil/boto
# export GOPATH=$HOME/tmp/go
# export PYLEARN2_DATA_PATH=$HOME/pylearn2/data

# set ENV to a file invoked each time sh is started for interactive use
export ENV=$HOME/.shrc
# bash reads .bashrc for a shell that is both interactive and non-login
# so need to explicitly source it here for interactive login shells
case "$-" in
*i*) [ -n "$BASH" -a -f ~/.bashrc ] && . ~/.bashrc ;;
esac

return 0
export SPEECHD_PORT=6561
