# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

# Characters
# SEGMENT_SEPARATOR="\ue0b0" # 
SEGMENT_SEPARATOR="\ue0b4" # 
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    print -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ -n "$SSH_CLIENT" ]]; then
    prompt_segment magenta white "%{$fg_bold[white]%(!.%{%F{white}%}.)%}$USER@%m%{$fg_no_bold[white]%}"
  else
    prompt_segment yellow magenta "%{$fg_bold[magenta]%(!.%{%F{magenta}%}.)%}@$USER%{$fg_no_bold[magenta]%}"
  fi
}

# Battery Level
prompt_battery() {
  HEART='♥ '

  if [[ $(uname) == "Darwin" ]] ; then

    function battery_is_charging() {
      [ $(ioreg -rc AppleSmartBattery | grep -c '^.*"ExternalConnected"\ =\ No') -eq 1 ]
    }

    function battery_pct() {
      local smart_battery_status="$(ioreg -rc "AppleSmartBattery")"
      typeset -F maxcapacity=$(echo $smart_battery_status | grep '^.*"MaxCapacity"\ =\ ' | sed -e 's/^.*"MaxCapacity"\ =\ //')
      typeset -F currentcapacity=$(echo $smart_battery_status | grep '^.*"CurrentCapacity"\ =\ ' | sed -e 's/^.*CurrentCapacity"\ =\ //')
      integer i=$(((currentcapacity/maxcapacity) * 100))
      echo $i
    }

    function battery_pct_remaining() {
      if battery_is_charging ; then
        battery_pct
      else
        echo "External Power"
      fi
    }

    function battery_time_remaining() {
      local smart_battery_status="$(ioreg -rc "AppleSmartBattery")"
      if [[ $(echo $smart_battery_status | grep -c '^.*"ExternalConnected"\ =\ No') -eq 1 ]] ; then
        timeremaining=$(echo $smart_battery_status | grep '^.*"AvgTimeToEmpty"\ =\ ' | sed -e 's/^.*"AvgTimeToEmpty"\ =\ //')
        if [ $timeremaining -gt 720 ] ; then
          echo "::"
        else
          echo "~$((timeremaining / 60)):$((timeremaining % 60))"
        fi
      fi
    }

    b=$(battery_pct_remaining)
    if [[ $(ioreg -rc AppleSmartBattery | grep -c '^.*"ExternalConnected"\ =\ No') -eq 1 ]] ; then
      if [ $b -gt 50 ] ; then
        prompt_segment green white
      elif [ $b -gt 20 ] ; then
        prompt_segment yellow white
      else
        prompt_segment red white
      fi
      echo -n "%{$fg_bold[white]%}$HEART$(battery_pct_remaining)%%%{$fg_no_bold[white]%}"
    fi
  fi

  if [[ $(uname) == "Linux" && -d /sys/module/battery ]] ; then

    function battery_is_charging() {
      ! [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]]
    }

    function battery_pct() {
      if (( $+commands[acpi] )) ; then
        echo "$(acpi | cut -f2 -d ',' | tr -cd '[:digit:]')"
      fi
    }

    function battery_pct_remaining() {
      if [ ! $(battery_is_charging) ] ; then
        battery_pct
      else
        echo "External Power"
      fi
    }

    function battery_time_remaining() {
      if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
        echo $(acpi | cut -f3 -d ',')
      fi
    }

    b=$(battery_pct_remaining)
    if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
      if [ $b -gt 40 ] ; then
        prompt_segment green white
      elif [ $b -gt 20 ] ; then
        prompt_segment yellow white
      else
        prompt_segment red white
      fi
      echo -n "%{$fg_bold[white]%}$HEART$(battery_pct_remaining)%%%{$fg_no_bold[white]%}"
    fi

  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
#«»±˖˗‑‐‒ ━ ✚‐↔←↑↓→↭⇎⇔⋆━◂▸◄►◆☀★☗☊✔✖❮❯⚑⚙
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR="$BRANCH"
  }
  local ref dirty mode repo_path clean has_upstream
  local modified untracked added deleted tagged stashed
  local ready_commit git_status bgclr fgclr
  local commits_diff commits_ahead commits_behind has_diverged to_push to_pull

  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    git_status=$(git status --porcelain 2> /dev/null)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      clean=''
      bgclr='yellow'
      fgclr='magenta'
    else
      clean=' ✔'
      bgclr='green'
      fgclr='white'
    fi

    local upstream=$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)
    if [[ -n "${upstream}" && "${upstream}" != "@{upstream}" ]]; then has_upstream=true; fi

    local current_commit_hash=$(git rev-parse HEAD 2> /dev/null)

    local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
    # if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files◆"; fi
    if [[ $number_of_untracked_files -gt 0 ]]; then untracked=" $number_of_untracked_files☀"; fi

    local number_added=$(\grep -c "^A" <<< "${git_status}")
    if [[ $number_added -gt 0 ]]; then added=" $number_added✚"; fi

    local number_modified=$(\grep -c "^.M" <<< "${git_status}")
    if [[ $number_modified -gt 0 ]]; then
      modified=" $number_modified●"
      bgclr='red'
      fgclr='white'
    fi

    local number_added_modified=$(\grep -c "^M" <<< "${git_status}")
    local number_added_renamed=$(\grep -c "^R" <<< "${git_status}")
    if [[ $number_modified -gt 0 && $number_added_modified -gt 0 ]]; then
      modified="$modified$((number_added_modified+number_added_renamed))±"
    elif [[ $number_added_modified -gt 0 ]]; then
      modified=" ●$((number_added_modified+number_added_renamed))±"
    fi

    local number_deleted=$(\grep -c "^.D" <<< "${git_status}")
    if [[ $number_deleted -gt 0 ]]; then
      deleted=" $number_deleted‒"
      bgclr='red'
      fgclr='white'
    fi

    local number_added_deleted=$(\grep -c "^D" <<< "${git_status}")
    if [[ $number_deleted -gt 0 && $number_added_deleted -gt 0 ]]; then
      deleted="$deleted$number_added_deleted±"
    elif [[ $number_added_deleted -gt 0 ]]; then
      deleted=" ‒$number_added_deleted±"
    fi

    local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then tagged=" ☗$tag_at_current_commit "; fi

    local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l)"
    if [[ $number_of_stashes -gt 0 ]]; then
      stashed=" ${number_of_stashes##*(  )}⚙"
      bgclr='magenta'
      fgclr='white'
    fi

    if [[ $number_added -gt 0 || $number_added_modified -gt 0 || $number_added_deleted -gt 0 ]]; then ready_commit=' ⚑'; fi

    local upstream_prompt=''
    if [[ $has_upstream == true ]]; then
      commits_diff="$(git log --pretty=oneline --topo-order --left-right ${current_commit_hash}...${upstream} 2> /dev/null)"
      commits_ahead=$(\grep -c "^<" <<< "$commits_diff")
      commits_behind=$(\grep -c "^>" <<< "$commits_diff")
      upstream_prompt="$(git rev-parse --symbolic-full-name --abbrev-ref @{upstream} 2> /dev/null)"
      upstream_prompt=$(sed -e 's/\/.*$/ ☊ /g' <<< "$upstream_prompt")
    fi

    has_diverged=false
    if [[ $commits_ahead -gt 0 && $commits_behind -gt 0 ]]; then has_diverged=true; fi
    if [[ $has_diverged == false && $commits_ahead -gt 0 ]]; then
      if [[ $bgclr == 'red' || $bgclr == 'magenta' ]]; then
        to_push=" $fg_bold[white]↑$commits_ahead$fg_bold[$fgclr]"
      else
        to_push=" $fg_bold[black]↑$commits_ahead$fg_bold[$fgclr]"
      fi
    fi
    if [[ $has_diverged == false && $commits_behind -gt 0 ]]; then to_pull=" $fg_bold[magenta]↓$commits_behind$fg_bold[$fgclr]"; fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    prompt_segment $bgclr $fgclr

    print -n "%{$fg_bold[$fgclr]%}${ref/refs\/heads\//$PL_BRANCH_CHAR $upstream_prompt}${mode}$to_push$to_pull$clean$tagged$stashed$untracked$modified$deleted$added$ready_commit%{$fg_no_bold[$fgclr]%}"
  fi
}

prompt_hg() {
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green black
      fi
      print -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green black
      fi
      print -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment cyan white "%{$fg_bold[white]%}%~%{$fg_no_bold[white]%}"
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

prompt_time() {
  prompt_segment blue white "%{$fg_bold[white]%}%D{%a %e %b - %H:%M}%{$fg_no_bold[white]%}"
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}


get_os_icon() {
    case $(uname) in
        Darwin)
            OS_ICON=$'\uF179'
            ;;
        MSYS_NT-* | MINGW* | CYGWIN_NT-*)
            OS_ICON=$'\uF17A'
            ;;
        FreeBSD | OpenBSD | DragonFly)
            OS_ICON=$'\uF30C'
            ;;
        Linux)
            local os_release_id="$(grep -E '^ID=([a-zA-Z]*)' /etc/os-release | cut -d '=' -f 2)"
            case "$os_release_id" in
                *arch*)
                    OS_ICON=$'\uF303'
                    ;;
                *debian*)
                    OS_ICON=$'\uF306'
                    ;;
                *ubuntu*)
                    OS_ICON=$'\uF31B'
                    ;;
                *elementary*)
                    OS_ICON=$'\uF309'
                    ;;
                *fedora*)
                    OS_ICON=$'\uF30A'
                    ;;
                *coreos*)
                    OS_ICON=$'\uF305'
                    ;;
                *gentoo*)
                    OS_ICON=$'\uF30D'
                    ;;
                *mageia*)
                    OS_ICON=$'\uF310'
                    ;;
                *centos*)
                    OS_ICON=$'\uF304'
                    ;;
                *opensuse* | *tumbleweed*)
                    OS_ICON=$'\uF314'
                    ;;
                *sabayon*)
                    OS_ICON=$'\uF317'
                    ;;
                *slackware*)
                    OS_ICON=$'\uF319'
                    ;;
                *linuxmint*)
                    OS_ICON=$'\uF30E'
                    ;;
                *alpine*)
                    OS_ICON=$'\uF300'
                    ;;
                *aosc*)
                    OS_ICON=$'\uF301'
                    ;;
                *nixos*)
                    OS_ICON=$'\uF313'
                    ;;
                *devuan*)
                    OS_ICON=$'\uF307'
                    ;;
                *manjaro*)
                    OS_ICON=$'\uF312'
                    ;;
                    *)
                    OS_ICON=$'\uF17C'
                    ;;
            esac

            # Check if we're running on Android
            case $(uname -o 2>/dev/null) in
                Android)
                    OS_ICON=$'\uF17B'
                    ;;
            esac
            ;;
        SunOS)
            OS_ICON=$'\uF185'
            ;;
        *)
            OS_ICON=''
            ;;
    esac

    local os_wsl=$(uname -r)
    if [[ "$os_wsl" =~ "Microsoft" ]]; then
        OS_ICON=$'\uF17A'
    fi
}

prompt_time_only() {
  # prompt_segment white black "%{$fg_bold[white]%}%D{%y-%m-%d %H:%M}%{$fg_no_bold[white]%}"
  # DATE_ICON $'\uF073'   TIME_ICON $'\uF017' 
  prompt_segment white black "\uF017 %D{%H:%M}"
}

prompt_user_host() {
  # if [[ -n "$SSH_CLIENT" ]]; then
  #   prompt_segment magenta default "%{$fg_bold[green]%}$USER%{$fg_no_bold[white]%}@%{$fg_bold[yellow]%}%m%{$fg_no_bold[green]%}"
  # else
  #   if [[ $UID -eq 0 ]]; then
  #     prompt_segment red default "%{$fg_bold[green]%}$USER%{$fg_no_bold[white]%}@%{$fg_bold[yellow]%}%m%{$fg_no_bold[green]%}"
  #   else
  #     prompt_segment cyan default "%{$fg_bold[green]%}$USER%{$fg_no_bold[white]%}@%{$fg_bold[yellow]%}%m%{$fg_no_bold[green]%}"
  #   fi
  # fi
  local visual_user_icon

  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    visual_user_icon="%F{white}\uF489%f " # SSH_ICON 
  fi

  if [[ $(print -P "%#") == '#' ]]; then
    visual_user_icon+="%F{red}\u26A1%f " # ROOT_ICON $'\u26A1' ⚡ $'\uE614' 
  else
    local os_msys=$(uname)
    if [[ "$os_msys" =~ "MSYS_NT" || "$os_msys" =~ "MINGW" || "$os_msys" =~ "CYGWIN_NT" ]]; then
      visual_user_icon+="%F{yellow}\uF415%f " # USER_ICON 
    else
      if sudo -n true 2>/dev/null; then
        visual_user_icon+="%F{red}\uF09C%f " # SUDO_ICON 
      else
        visual_user_icon+="%F{yellow}\uF415%f " # USER_ICON 
      fi
    fi
  fi
  
  if [[ -n "$USER" ]]; then
    prompt_segment cyan default "${visual_user_icon}%F{yellow}%B$USER%f%b%F{white}@%f%F{green}%B%m%f%b"
  elif [[ -n "$USERNAME" ]]; then
    prompt_segment cyan default "${visual_user_icon}%F{yellow}%B$USERNAME%f%b%F{white}@%f%F{green}%B%m%f%b"
  fi
}

prompt_dir_blue() {
  typeset -AH dir_states
  dir_states=(
    "DEFAULT"         $'\uF115' # 
    "HOME"            $'\uF015' # 
    "HOME_SUBFOLDER"  $'\uF07C' # 
    "NOT_WRITABLE"    $'\UF023' # 
    "ETC"             $'\uF013' # 
  )
  local state_path="$(print -P '%~')"
  local current_state="DEFAULT"
  if [[ $state_path == '/etc'* ]]; then
    current_state='ETC'
  elif [[ ! -w "$PWD" ]]; then
    current_state="NOT_WRITABLE"
  elif [[ $state_path == '~' ]]; then
    current_state="HOME"
  elif [[ $state_path == '~'* ]]; then
    current_state="HOME_SUBFOLDER"
  fi
  prompt_segment blue white "${dir_states[$current_state]} %~"
}

prompt_status_exitcode() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘:$RETVAL"
  # [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  if [[ -n "$symbols" ]]; then
    prompt_segment black default "$symbols"
  # else
  #   prompt_segment black default " "
  fi
}

prompt_indicator() {
  #                       ❯           ❮         ➤        ➜        ᐅ
  # $'\uE0B0' $'\uE602' $'\u276F' $'\u276E' $'\u27A4' $'\u279C' $'\u1405'
  local indicator
  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    indicator="%{%F{magenta}%}\uE602"
  else
    if [[ $UID -eq 0 ]]; then
      indicator="%{%F{red}%}\uE602"
    else
      indicator="%{%F{yellow}%}\uE602"
    fi
  fi
  prompt_segment default default "$indicator"
}

prompt_prompt_timer_preexec() {
  command_preexec_timer=${command_preexec_timer:-$SECONDS}
  prompt_preexec_timer=$SECONDS
  export ZSH_PROMPT_TIME_PREEXEC="$prompt_preexec_timer"
  export ZSH_COMMAND_EXECUTION_TIME=""
  export ZSH_PROMPT_TIME=""
}

prompt_prompt_timer_precmd() {
  if [[ $command_preexec_timer ]]; then
    export ZSH_COMMAND_EXECUTION_TIME="$((SECONDS - command_preexec_timer))"
    unset command_preexec_timer
  fi
}

prompt_prompt_timer() {
  local time_duration prompt_command_msg prompt_prompt_msg prompt_msg

  if [[ -n "$ZSH_COMMAND_EXECUTION_TIME" ]]; then
    if [[ -n "$TTY" ]] && [[ $ZSH_COMMAND_EXECUTION_TIME -ge ${AGNOSTERZAK_COMMAND_EXECUTION_TIME_THRESHOLD:-3} ]]; then
      ZSH_COMMAND_TIME="$ZSH_COMMAND_EXECUTION_TIME"
    fi
  fi

  if [[ -n "$ZSH_PROMPT_TIME_PREEXEC" ]]; then
    if [[ -n "$ZSH_COMMAND_EXECUTION_TIME" ]]; then
      time_duration=$((SECONDS - ZSH_PROMPT_TIME_PREEXEC - ZSH_COMMAND_EXECUTION_TIME))
    else
      time_duration=$((SECONDS - ZSH_PROMPT_TIME_PREEXEC))
    fi

    if [[ -n "$TTY" ]] && [[ $time_duration -ge ${AGNOSTERZAK_PROMPT_TIME_THRESHOLD:-5} ]]; then
      ZSH_PROMPT_TIME="$time_duration"
    fi
  fi

  if [[ $prompt_preexec_timer ]]; then
    unset prompt_preexec_timer
  fi

  if [[ "$AGNOSTERZAK_PROMPT_TIME" == true ]] && [[ -n "$ZSH_PROMPT_TIME" ]]; then
    # prompt_prompt_msg=$(printf '%dh:%02dm:%02ds\n' $((ZSH_PROMPT_TIME/3600)) $((ZSH_PROMPT_TIME%3600/60)) $((ZSH_PROMPT_TIME%60)))
    prompt_prompt_msg="${ZSH_PROMPT_TIME}s"
  fi

  if [[ "$AGNOSTERZAK_COMMAND_EXECUTION_TIME" == true ]] && [[ -n "$ZSH_COMMAND_TIME" ]]; then
    prompt_command_msg=$(printf '%dh:%02dm:%02ds\n' $((ZSH_COMMAND_TIME/3600)) $((ZSH_COMMAND_TIME%3600/60)) $((ZSH_COMMAND_TIME%60)))
  fi

  if [[ -n "$prompt_prompt_msg" ]]; then
    if [[ -n "$prompt_command_msg" ]]; then
      prompt_msg="\uF252${prompt_command_msg} \uF120${prompt_prompt_msg}"
    else
      prompt_msg="\uF120${prompt_prompt_msg}"
    fi
  elif [[ -n "$prompt_command_msg" ]]; then
    prompt_msg="\uF252${prompt_command_msg}"
  fi

  # $'\uF252'   $'\uF120' 
  if [[ -n "$prompt_msg" ]]; then
    prompt_segment black yellow "${prompt_msg}"
  fi
}

prompt_os_icon() {
  get_os_icon
  prompt_segment black yellow "$OS_ICON"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  print -n "\n"
  prompt_os_icon
  prompt_battery
  prompt_time_only
  prompt_user_host
  prompt_virtualenv
  prompt_dir_blue
  prompt_git
  prompt_hg
  prompt_status_exitcode
  prompt_prompt_timer
  prompt_end
  CURRENT_BG='NONE'
  print -n "\n"
  prompt_indicator
  CURRENT_BG=''
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '

# PROMPT2
if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
  PROMPT2='%{$fg[magenta]%}❯%{$reset_color%} '
else
  if [[ $UID -eq 0 ]]; then
    PROMPT2='%{$fg[red]%}❯%{$reset_color%} '
  else
    PROMPT2='%{$fg[yellow]%}❯%{$reset_color%} '
  fi
fi

precmd_functions+=(prompt_prompt_timer_precmd)
preexec_functions+=(prompt_prompt_timer_preexec)


## It currently shows:
# Battery Life (in case of the laptop is not charging)
# Timestamp
# Current directory
# Git status
# User & Host status

## Battery status                   Color
# more than 39%                     green
# less than 40% and more than 19%   yellow
# less than 20%                     red

### Git
## Color States
# Background Color & Foreground Color		Meaning
# green & white     git-clean	Absolutely clean state
# magenta & white   git-stash	There are stashed files
# yellow & magenta  git-untracked	There are new untracked files
# red & white       git-modified	There are modified or deleted files but unstaged

## Icon	Meaning
# ✔	clean directory
# ☀	new untracked files preceeded by their number
# ✚	added files from the new untracked ones preceeded by their number
# ‒	deleted files preceeded by their number
# ●	modified files preceeded by their number
# ±	added files from the modifies or delete ones preceeded by their number
# ⚑	ready to commit
# ⚙	sets of stashed files preceeded by their number
# ☊	branch has a stream, preceeded by his remote name
# ↑	commits ahead on the current branch comparing to remote, preceeded by their number
# ↓	commits behind on the current branch comparing to remote, preceeded by their number
# <B>	bisect state on the current branch
# >M<	Merge state on the current branch
# >R>	Rebase state on the current branch