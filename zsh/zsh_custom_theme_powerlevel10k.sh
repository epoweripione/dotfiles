#!/usr/bin/env zsh

# https://github.com/romkatv/powerlevel10k
function set_zle_rprompt_indent() {
  local OS_TYPE OS_INFO_WSL

  OS_TYPE=$(uname)
  OS_INFO_WSL=$(uname -r)
  # MSYS, MINGW, CYGWIN
  if [[ $OS_TYPE =~ "MSYS_NT" || $OS_TYPE =~ "MINGW" || $OS_TYPE =~ "CYGWIN_NT" ]]; then
    ZLE_RPROMPT_INDENT=6
  fi

  # WSL
  # [[ "${OS_INFO_WSL}" =~ "Microsoft" ]] && ZLE_RPROMPT_INDENT=6
}

set_zle_rprompt_indent

# POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'