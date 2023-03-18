#!/usr/bin/env bash

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

App_Installer_Reset

## Install Software Development Kits for the JVM such as Java, Groovy, Scala, Kotlin and Ceylon. Ant, Gradle, Grails, Maven, SBT, Spark, Spring Boot, Vert.x and many others also supported.
## https://sdkman.io/
## To get a listing of available Candidates: sdk list
## To see what is currently in use for all Candidates: sdk current
colorEcho "${BLUE}Installing ${FUCHSIA}sdkman${BLUE}..."
if [[ ! -d "$HOME/.sdkman" ]]; then
    curl -fsSL "https://get.sdkman.io" | bash
fi

if [[ "$(command -v sdk)" ]]; then
    colorEcho "${BLUE}Installing ${FUCHSIA}maven gradle kotlin ${BLUE}using sdkman..."
    sdk install maven && sdk install gradle && sdk install kotlin
fi
