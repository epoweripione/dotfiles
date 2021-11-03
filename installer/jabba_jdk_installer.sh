#!/usr/bin/env bash

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


# jabba & JDK
## Install jabba
colorEcho "${BLUE}Installing ${FUCHSIA}jabba${BLUE}..."
if [[ ! -d "$HOME/.jabba" ]]; then
    curl -fsSL https://github.com/shyiko/jabba/raw/master/install.sh | bash && \
        source "$HOME/.jabba/jabba.sh" && \
        sed -i "/jabba.sh/d" ~/.zshrc
fi

if [[ -d "$HOME/.jabba" ]]; then
    if type 'jabba' 2>/dev/null | grep -q 'function'; then
        :
    else
        [[ -s "$HOME/.jabba/jabba.sh" ]] && source "$HOME/.jabba/jabba.sh"
    fi
fi

## OpenJDK
colorEcho "${BLUE}Installing ${FUCHSIA}JDK${BLUE}..."
# apt install -y default-jdk default-jre
# jabba install openjdk@1.11.0-2 && jabba alias default openjdk@1.11.0-2
jabba install zulu@1.8 && jabba alias default zulu@1.8
jabba install zulu@1.11.0-5
# jabba install zulu@1.13.0-1


## How do I switch java globally?
## Windows(in powershell as administrator)
# jabba use zulu@1.11
## modify global PATH & JAVA_HOME
# $envRegKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
# $envPath=$envRegKey.GetValue('Path', $null, "DoNotExpandEnvironmentNames").replace('%JAVA_HOME%\bin;', '')
# [Environment]::SetEnvironmentVariable('JAVA_HOME', "$(jabba which $(jabba current))", 'Machine')
# [Environment]::SetEnvironmentVariable('PATH', "%JAVA_HOME%\bin;$envPath", 'Machine')

## Linux
# jabba use zulu@1.11
# sudo update-alternatives --install /usr/bin/java java ${JAVA_HOME%*/}/bin/java 20000
# sudo update-alternatives --install /usr/bin/javac javac ${JAVA_HOME%*/}/bin/javac 20000

## To switch between multiple GLOBAL alternatives use:
# sudo update-alternatives --config java


## Oracle jdk 8
## http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
# colorEcho "${BLUE}Installing ${FUCHSIA}Oracle JDK 8${BLUE}..."
# mkdir -p /usr/lib/jvm && cd /usr/lib/jvm && \
#     wget --no-cookies \
#         --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#         https://download.oracle.com/otn/java/jdk/8u212-b10/59066701cf1a433da9770636fbc4c9aa/jdk-8u212-linux-x64.tar.gz && \
#     tar -xzf jdk-8u181-linux-x64.tar.gz && \
#     ln -s /usr/lib/jvm/jdk1.8.0_181/ /usr/lib/jvm/oracle-jdk8 && \
#     rm -f jdk-8u181-linux-x64.tar.gz

## Oracle jdk 11
## https://www.oracle.com/technetwork/java/javase/downloads/jdk11-downloads-5066655.html
# colorEcho "${BLUE}Installing ${FUCHSIA}Oracle JDK 11${BLUE}..."
# mkdir -p /usr/lib/jvm && cd /usr/lib/jvm && \
#     wget --no-cookies \
#         --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#         https://download.oracle.com/otn/java/jdk/11.0.3+12/37f5e150db5247ab9333b11c1dddcd30/jdk-11.0.3_linux-x64_bin.tar.gz && \
#     tar -xzf jdk-11_linux-x64_bin.tar.gz && \
#     ln -s /usr/lib/jvm/jdk-11/ /usr/lib/jvm/oracle-jdk11 && \
#     rm -f jdk-11_linux-x64_bin.tar.gz

# ## Install new JDK alternatives
# update-alternatives --install /usr/bin/java java /usr/lib/jvm/oracle-jdk11/bin/java 100
# update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/oracle-jdk11/bin/javac 100
# update-alternatives --install /usr/bin/java java /usr/lib/jvm/oracle-jdk8/bin/java 200
# update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/oracle-jdk8/bin/javac 200

# ## Remove the existing alternatives
# # update-alternatives --remove java /usr/lib/jvm/oracle-jdk11/bin/java
# # update-alternatives --remove javac /usr/lib/jvm/oracle-jdk11/bin/javac
# # update-alternatives --remove java /usr/lib/jvm/oracle-jdk8/bin/java
# # update-alternatives --remove javac /usr/lib/jvm/oracle-jdk8/bin/javac

# ## Change the default Java versions using the update-alternatives system:
# # update-alternatives --config java
# # update-alternatives --config javac


if [[ -x "$(command -v java)" ]]; then
    if [[ -z "$JAVA_HOME" ]]; then
        JAVA_HOME=$(readlink -f "$(which java)" | sed "s:/jre/bin/java::" | sed "s:/bin/java::")
        export JAVA_HOME
        if [[ -d "$JAVA_HOME/jre" ]]; then
            export JRE_HOME=$JAVA_HOME/jre
        fi
        export CLASSPATH=$JAVA_HOME/lib
        export PATH=$PATH:$JAVA_HOME/bin
    else
        if [[ -z "$CLASSPATH" ]]; then
            export CLASSPATH=$JAVA_HOME/lib
        fi
    fi
fi


cd "${CURRENT_DIR}" || exit