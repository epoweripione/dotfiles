# Clean, simple, compatible and meaningful.
# Tested on Linux, Unix and Windows under ANSI colors.
# It is recommended to use with a dark background.
# Colors: black, red, green, yellow, *blue, magenta, cyan, and white.
#
# Mar 2013 Yad Smood

() {
  SEGMENT_SEPARATOR=$'\ue0b0'
}

# am i root
if [[ $USER == "root" ]]; then
  CARETCOLOR="red"
else
  CARETCOLOR="magenta"
fi

# VCS
YS_VCS_PROMPT_PREFIX1="%{$fg[white]%}%{$fg_bold[cyan]%}"
YS_VCS_PROMPT_PREFIX2="%{$reset_color%}%{$fg_bold[blue]%}"

# YS_VCS_PROMPT_PREFIX1=""
# YS_VCS_PROMPT_PREFIX2=""

YS_VCS_PROMPT_SUFFIX="%{$fg[white]%}%{$reset_color%}"
# YS_VCS_PROMPT_SUFFIX=""

YS_VCS_PROMPT_DIRTY=" %{$fg[red]%}✗"
YS_VCS_PROMPT_CLEAN=" %{$fg[green]%}✔"

# Git info
ZSH_THEME_GIT_PROMPT_PREFIX="${YS_VCS_PROMPT_PREFIX1}${YS_VCS_PROMPT_PREFIX2}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$YS_VCS_PROMPT_SUFFIX"

ZSH_THEME_GIT_PROMPT_DIRTY="$YS_VCS_PROMPT_DIRTY"
ZSH_THEME_GIT_PROMPT_CLEAN="$YS_VCS_PROMPT_CLEAN"

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚ "
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[magenta]%}⚑ "
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✖ "
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[blue]%}▴ "
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[cyan]%}§ "
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[white]%}◒ "

ZSH_THEME_GIT_PROMPT_SHA_BEFORE="%{$reset_color%}%{$fg_bold[red]%}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER="%{$reset_color%}"

# ZSH_THEME_GIT_PROMPT_SHA_BEFORE=""
# ZSH_THEME_GIT_PROMPT_SHA_AFTER=""

# Colors vary depending on time lapsed.
ZSH_THEME_GIT_TIME_SINCE_COMMIT_SHORT="%{$fg[green]%}"
ZSH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM="%{$fg[yellow]%}"
ZSH_THEME_GIT_TIME_SINCE_COMMIT_LONG="%{$fg[red]%}"
ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL="%{$fg[white]%}"


# Git info
local git_info='$(my_git_prompt_info)'
my_git_prompt_info() {
    local ref git_pompt

    # git_pompt="$(agnoster_fast_git_prompt_info)" || return
    git_pompt="$(agnoster_fast_git_prompt_info)"

    if [ -z "$git_pompt" ]; then
      echo -n "%{$fg[blue]$bg[black]%}$SEGMENT_SEPARATOR%{$reset_color%}"
    else
      # echo -n "%{$fg[blue]$bg[yellow]%}$SEGMENT_SEPARATOR%{$reset_color%}"
      # echo -n "%{$bg[yellow]%}%{$fg_bold[black]%} ${git_pompt} %{$reset_color%}"
      # echo -n "%{$fg[yellow]$bg[black]%}$SEGMENT_SEPARATOR%{$reset_color%}"
      echo -n "%{$fg[blue]%}$SEGMENT_SEPARATOR%{$reset_color%}"
      echo -n " ${git_pompt} %{$reset_color%}"
    fi
}


ys_git_prompt_info() {
	(( $+commands[git] )) || return
	ref="$(git symbolic-ref HEAD 2> /dev/null)" || return
	echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(git_prompt_short_sha)$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}


agnoster_fast_git_prompt_info() {
	(( $+commands[git] )) || return
	local PL_BRANCH_CHAR=$'\ue0a0'         # 
	ref="$(git symbolic-ref HEAD 2> /dev/null)" || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)" || return
	# echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref/refs\/heads\//$PL_BRANCH_CHAR}$(git_prompt_short_sha)$(parse_git_dirty) $(git_prompt_status)$ZSH_THEME_GIT_PROMPT_SUFFIX"
	echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref/refs\/heads\//$PL_BRANCH_CHAR } $(git_prompt_short_sha) $(git_prompt_status)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}


# Git: branch/detached head, dirty status
agnoster_git_prompt_info() {
  (( $+commands[git] )) || return
  local PL_BRANCH_CHAR=$'\ue0a0'         # 
  local ref dirty mode repo_path
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    # echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
    echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref/refs\/heads\//$PL_BRANCH_CHAR}$(git_prompt_short_sha)$(parse_git_dirty)${vcs_info_msg_0_%% }${mode}$ZSH_THEME_GIT_PROMPT_SUFFIX"
  fi
}


# HG info
local hg_info='$(ys_hg_prompt_info)'
ys_hg_prompt_info() {
	# make sure this is a hg dir
	if [ -d '.hg' ]; then
		echo -n "${YS_VCS_PROMPT_PREFIX1}hg${YS_VCS_PROMPT_PREFIX2}"
		echo -n $(hg branch 2>/dev/null)
		if [ -n "$(hg status 2>/dev/null)" ]; then
			echo -n "$YS_VCS_PROMPT_DIRTY"
		else
			echo -n "$YS_VCS_PROMPT_CLEAN"
		fi
		echo -n "$YS_VCS_PROMPT_SUFFIX"
	fi
}


# Determine the time since last commit. If branch is clean,
# use a neutral color, otherwise colors will vary according to time.
function _git_time_since_commit() {
  (( $+commands[git] )) || return
  # Only proceed if there is actually a commit.
  if git log -1 > /dev/null 2>&1; then
    # Get the last commit.
    last_commit=$(git log --pretty=format:'%at' -1 2> /dev/null)
    now=$(date +%s)
    seconds_since_last_commit=$((now-last_commit))

    # Totals
    minutes=$((seconds_since_last_commit / 60))
    hours=$((seconds_since_last_commit/3600))

    # Sub-hours and sub-minutes
    days=$((seconds_since_last_commit / 86400))
    sub_hours=$((hours % 24))
    sub_minutes=$((minutes % 60))

    if [ $hours -gt 24 ]; then
      commit_age="${days}d"
    elif [ $minutes -gt 60 ]; then
      commit_age="${sub_hours}h${sub_minutes}m"
    else
      commit_age="${minutes}m"
    fi

    color=$ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL
    echo "$color$commit_age%{$reset_color%}"
  fi
}


# Current working directory
local dir_info='$(prompt_dir)'

prompt_dir() {
    echo -n "%{$fg[black]$bg[blue]%}$SEGMENT_SEPARATOR%{$reset_color%}"
    echo -n "%{$fg_bold[white]$bg[blue]%} %~ %{$reset_color%}"
    #  echo -n "%{$fg[blue]$bg[black]%}$SEGMENT_SEPARATOR%{$reset_color%}"
}


local exit_code="%(?,,C:%{$fg[red]%}%?%{$reset_color%})"

# Prompt format:
#
# PRIVILEGES USER @ MACHINE in DIRECTORY on git:BRANCH STATE [TIME] C:LAST_EXIT_CODE
# $ COMMAND
#
# For example:
#
# % ys @ ys-mbp in ~/.oh-my-zsh on git:master x [21:47:42] C:0
# $
PROMPT="
%(#,%{$bg[yellow]%}%{$fg[black]%}%n%{$reset_color%},%{$fg[cyan]%}%n)\
%{$fg[white]%}@\
%{$fg[green]%}%m \
${dir_info}\
${hg_info}\
${git_info}\
%{$fg[white]%} $exit_code
%{$terminfo[bold]$fg[$CARETCOLOR]%}⚡ %{$reset_color%}"
