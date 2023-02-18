#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

# ShellCheck: a static analysis tool for shell scripts
# https://github.com/koalaman/shellcheck
[[ ! -x "$(command -v shellcheck)" && -x "$(command -v rtx)" ]] && rtx global shellcheck@latest
[[ ! -x "$(command -v shellcheck)" && "$(command -v asdf)" ]] && asdf_App_Install shellcheck

## Usage:
# find . -type f \( -name '*.sh' -o -name '*.bash' \) \
#     | xargs shellcheck --source-path="$HOME/.dotfiles:$HOME/.oh-my-zsh/custom" \
#         --external-sources \
#         --exclude=SC1071,SC1090,SC1091,SC1094,SC2001,SC2002,SC2012,SC2015,SC2016,SC2034,SC2119,SC2120,SC2126,SC2129,SC2142,SC2145,SC2219
#         --exclude=SC2207

## https://github.com/koalaman/shellcheck/wiki/SC1071
# ShellCheck only supports sh/bash/dash/ksh scripts. Sorry!

## https://github.com/koalaman/shellcheck/wiki/SC1090
# Can't follow non-constant source. Use a directive to specify location.

## https://github.com/koalaman/shellcheck/wiki/SC1091
# Problematic code: source somefile
# Reasons include: file not found, no permissions, not included on the command line, not allowing shellcheck to follow files with -x, etc.

## https://github.com/koalaman/shellcheck/wiki/SC1094
# Parsing of sourced file failed. Ignoring it.

## https://github.com/koalaman/shellcheck/wiki/SC2001
# See if you can use ${variable//search/replace} instead

## https://github.com/koalaman/shellcheck/wiki/SC2002
# Useless cat. Consider 'cmd < file | ..' or 'cmd file | ..' instead.

## https://github.com/koalaman/shellcheck/wiki/SC2012
# Use find instead of ls to better handle non-alphanumeric filenames.

## https://github.com/koalaman/shellcheck/wiki/SC2015
# Note that A && B || C is not if-then-else. C may run when A is true.

## https://github.com/koalaman/shellcheck/wiki/SC2016
# Expressions don't expand in single quotes, use double quotes for that.

## https://github.com/koalaman/shellcheck/wiki/SC2034
# foo appears unused. Verify it or export it.

## https://github.com/koalaman/shellcheck/wiki/SC2119
# Use foo "$@" if function's $1 should mean script's $1.

## https://github.com/koalaman/shellcheck/wiki/SC2120
# foo references arguments, but none are ever passed.

## https://github.com/koalaman/shellcheck/wiki/SC2126
# Consider using grep -c instead of grep | wc

## https://github.com/koalaman/shellcheck/wiki/SC2129
# Consider using { cmd1; cmd2; } >> file instead of individual redirects.

## https://github.com/koalaman/shellcheck/wiki/SC2142
# Aliases can't use positional parameters. Use a function.

## https://github.com/koalaman/shellcheck/wiki/SC2145
# Argument mixes string and array. Use * or separate argument.

## https://github.com/koalaman/shellcheck/wiki/SC2219
# Instead of let expr, prefer (( expr )) .

## https://github.com/koalaman/shellcheck/wiki/SC2207
# Prefer mapfile or read -a to split command output (or quote to avoid splitting).
