#!/bin/bash
# Gestion de l'environnement GIT

ERROR="\033[31m[FAILED]\033[00m ->"
WARN="\033[01m\033[05m[.WARN.]\033[00m ->"
INFO="[.INFO.] ->"
OK="\033[32m[..OK..]\033[00m ->"


#######################################
# Positionnement de certains parametres utiles
#######################################
function set_gitconfig {
  param=$1
  value=$2

  git config --get $param > /dev/null || git config $param "$value"
}

#######################################
# Test de certains parametres
#######################################
function test_gitconfig {
  param=$1

  git config --get $param > /dev/null || {
    echo -e "$WARN Missing parameter $param for git config"
    echo -e "$INFO Type : git config $param <value>"
  }
}

#######################################
# Set environnement bash for better git
# inspiration : http://vvv.tobiassjosten.net/bash/dynamic-prompt-with-git-and-ansi-colors/
#######################################
function set_gitenv {

  # Configure colors, if available.
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    c_reset='\[\e[0m\]'
    c_user='\[\e[1;33m\]'
    c_user=
    c_path='\[\e[0;33m\]'
    c_git_clean='\[\e[0;37m\]'
    c_git_staged='\[\e[0;32m\]'
    c_git_unstaged='\[\e[0;31m\]'
    c_git_untracked='\[\e[0;33m\]'
  else
    c_reset=
    c_user=
    c_path=
    c_git_clean=
    c_git_staged=
    c_git_unstaged=
    c_git_untracked=
  fi

  # Function to assemble the Git parsingart of our prompt.
  git_prompt ()
  {
    GIT_DIR=`git rev-parse --git-dir 2>/dev/null`
    if [ -z "$GIT_DIR" ]; then
      return 0
    fi
    GIT_HEAD=`cat $GIT_DIR/HEAD`
    GIT_BRANCH=${GIT_HEAD##*refs/heads/}
    if [ ${#GIT_BRANCH} -eq 40 ]; then
      GIT_BRANCH="(no branch)"
    fi
    STATUS=`git status --porcelain`
    if [ -z "$STATUS" ]; then
      git_color="${c_git_clean}"
    else
      echo "$STATUS" | grep '^ [A-Z]' >/dev/null
      if [ $? -eq 0 ]; then
        git_color="${c_git_unstaged}"
      else
        echo "$STATUS" | grep '^[A-Z]' >/dev/null
        if [ $? -eq 0 ]; then
          git_color="${c_git_staged}"
        else
          git_color="${c_git_untracked}"
        fi
      fi
    fi
    echo "($git_color$GIT_BRANCH${c_reset})"
  }

  if [ $UID -eq 0 ]; then
    u_prompt=\#
  else
    u_prompt=\$
  fi

  # Thy holy prompt.
  PROMPT_COMMAND='PS1="[${c_user}\u${c_reset}@${c_user}\h${c_reset} ${c_path}\W${c_reset}]$(git_prompt)${u_prompt} "'

  # Git completion
  . /etc/bash_completion.d/git

}

#######################################
# Init de la config de git
#######################################
function init_git {

  # Set git options
  # log
  set_gitconfig log.date default
  set_gitconfig log.decorate true

  # color 
  set_gitconfig color.ui auto

  # alias
  set_gitconfig alias.logg "log --graph --oneline"

  # name (si pas encore defini)
  test_gitconfig user.name
  test_gitconfig user.email

}


#######################################
# Usage
#######################################
function usage {
  echo "Usage : . $0 [--setenv]"
  echo "        $0 [--init]"

  # pas de exit si sourced
  if [ $BASH_SOURCE == $0 ]
  then
    exit 1
  fi
}

#######################################
# Main
#######################################

ACTION=$1
shift
[ -z "$ACTION" ] && ACTION=none


if [ $ACTION = "--init" ]
then
  init_git
  echo -e "$OK Git environnement initialized"
  exit
fi

if [ $ACTION = "--setenv" ]
then
  if [ $BASH_SOURCE == $0 ]
  then
    echo -e "$ERROR Please execute this script as sourced"
    exit 1
  fi
  set_gitenv
  echo -e "$OK Git environnement set"
  return
fi

usage

