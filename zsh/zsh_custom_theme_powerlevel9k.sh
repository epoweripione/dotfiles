#!/usr/bin/env zsh

# Custom theme configuration
OS_TYPE=$(uname)

# powerlevel9k theme settings
# fonts https://github.com/bhilburn/powerlevel9k/wiki/Install-Instructions#step-2-install-a-powerline-font
# POWERLEVEL9K_COLOR_SCHEME='light'
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'

# prompt
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context dir vcs)
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon ssh root_indicator context time dir vcs background_jobs command_execution_time status)

POWERLEVEL9K_DISABLE_RPROMPT=false
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs time ssh root_indicator custom_prompt_timer command_execution_time)

POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR="\uE0B4"
POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR="" # "%F{$(( DEFAULT_BACKGROUND - 2 ))}|%f"
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR="\uE0B6"
POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR="" # "%F{$(( DEFAULT_BACKGROUND - 2 ))}|%f"

POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=false

POWERLEVEL9K_STATUS_VERBOSE=true
POWERLEVEL9K_STATUS_CROSS=true
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

# POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="%F{cyan}\u256D\u2500%f"
# POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{014}\u2570%F{cyan}\uF460%F{073}\uF460%F{109}\uF460%f "
# POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="╭─%f"
# POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="╰─%F{008}\uF460 %f"
# POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
# POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{008}> %f"

# POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="╭─%f"
# POWERLEVEL9K_MULTILINE_SECOND_PROMPT_PREFIX="❱ "
# POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="╰─\u27A4 "
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="\uF178 "

# user
POWERLEVEL9K_ALWAYS_SHOW_USER=true
POWERLEVEL9K_USER_ICON="\uF415" # 
POWERLEVEL9K_ROOT_ICON="\u26A1" # ⚡
POWERLEVEL9K_SUDO_ICON="\uF09C" # 

# vcs
POWERLEVEL9K_HIDE_BRANCH_ICON=false
POWERLEVEL9K_SHOW_CHANGESET=true
POWERLEVEL9K_CHANGESET_HASH_LENGTH=6
POWERLEVEL9K_VCS_SHOW_SUBMODULE_DIRTY=true
POWERLEVEL9K_VCS_HIDE_TAGS=false

if [[ $OS_TYPE =~ "MSYS_NT" || $OS_TYPE =~ "MINGW" || $OS_TYPE =~ "CYGWIN_NT" ]]; then
  ZLE_RPROMPT_INDENT=6
  POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-remotebranch)
else
  POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-aheadbehind git-stash git-remotebranch git-tagname)
fi
POWERLEVEL9K_VCS_HG_HOOKS=(vcs-detect-changes)
POWERLEVEL9K_VCS_SVN_HOOKS=(vcs-detect-changes svn-detect-changes)
POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND=red


# custom command
zsh_powerlevel9k_prompt_timer_preexec() {
  prompt_timer=$SECONDS
  export ZSH_PROMPT_TIME="$prompt_timer"
}

zsh_powerlevel9k_prompt_timer() {
  if [[ -n "$ZSH_PROMPT_TIME" ]]; then
    prompt_timer_show=$((SECONDS - ZSH_PROMPT_TIME))
    echo -n "%F{yellow1}\uF252 ${prompt_timer_show}%{%f%}"
  fi
  unset prompt_timer
}

preexec_functions+=(zsh_powerlevel9k_prompt_timer_preexec)


# add custom command options
POWERLEVEL9K_CUSTOM_PROMPT_TIMER="zsh_powerlevel9k_prompt_timer"
POWERLEVEL9K_CUSTOM_PROMPT_TIMER_BACKGROUND="magenta"
POWERLEVEL9K_CUSTOM_PROMPT_TIMER_FOREGROUND="yellow1"
