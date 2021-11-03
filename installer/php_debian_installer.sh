#!/usr/bin/env bash

if [[ $UID -ne 0 ]]; then
    echo "Please run this script as root user!"
    exit 0
fi

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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

## add php repository
if [[ ! -e /etc/apt/sources.list.d/php.list ]]; then
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://mirror.xtom.com.hk/sury/php/apt.gpg
    echo "deb https://mirror.xtom.com.hk/sury/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
fi

colorEcho "${BLUE}Updating ${FUCHSIA}repositories${BLUE}..."
apt update


## Install dev packages
colorEcho "${BLUE}Installing ${FUCHSIA}dev packages${BLUE}..."
apt install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev libicu-dev \
    libxml2-dev libxslt-dev libbz2-dev libpspell-dev aspell-en \
    libcurl3 libcurl4-openssl-dev libssl-dev libc-client-dev libkrb5-dev \
    libpcre3 libpcre3-dev libmagickwand-dev libmemcached-dev zlib1g-dev \
    libgirepository1.0-dev libpq-dev nghttp2 libnghttp2-dev --no-install-recommends


## PHP
PHP_VERSION=${1:-7.4}

if [[ -x "$(command -v php)" ]]; then
    PHP_VERSION_OLD=$(php --version | head -n 1 | cut -d " " -f 2 | cut -c 1-3)
    if [[ "$PHP_VERSION" != "$PHP_VERSION_OLD" ]]; then
        colorEcho "${BLUE}Removing installed php ${PHP_VERSION_OLD}..."
        apt remove -y --purge "php${PHP_VERSION_OLD}*" && apt autoremove -y
        # rm -rf /usr/lib/php/${PHP_VERSION_OLD} /usr/include/php/${PHP_VERSION_OLD} /etc/php/${PHP_VERSION_OLD}
    fi
fi

colorEcho "${BLUE}Installing ${FUCHSIA}PHP ${YELLOW}${PHP_VERSION}${BLUE}..."
apt install -y pkg-config "php${PHP_VERSION}" "php${PHP_VERSION}-fpm" "php${PHP_VERSION}-curl" "php${PHP_VERSION}-dev" \
    "php${PHP_VERSION}-gd" "php${PHP_VERSION}-mbstring" "php${PHP_VERSION}-mysql" "php${PHP_VERSION}-pgsql" \
    "php${PHP_VERSION}-sqlite3" "php${PHP_VERSION}-xml" "php${PHP_VERSION}-xsl" "php${PHP_VERSION}-zip"


## opcache
{ \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'opcache.file_cache=/tmp'; \
} > "/etc/php/${PHP_VERSION}/cli/conf.d/opcache-recommended.ini"

# remove PHP version from the X-Powered-By HTTP header
# test: curl -I -H "Accept-Encoding: gzip, deflate" https://www.yourdomain.com
echo 'expose_php = off' > "/etc/php/${PHP_VERSION}/cli/conf.d/hide-header-version.ini"


## Install composer
colorEcho "${BLUE}Installing ${FUCHSIA}composer${BLUE}..."
export COMPOSER_ALLOW_SUPERUSER=1 && \
    export COMPOSER_HOME=/usr/local/share/composer && \
    mkdir -p /usr/local/share/composer && \
    wget https://dl.laravel-china.org/composer.phar -O /usr/local/bin/composer && \
    chmod a+x /usr/local/bin/composer

### Packagist mirror
# composer config -g repo.packagist composer https://packagist.laravel-china.org
composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

### Install composer packages
colorEcho "${BLUE}Installing ${FUCHSIA}composer packages${BLUE}..."
composer g require "hirak/prestissimo" && \
    composer g require friendsofphp/php-cs-fixer && \
    composer g require --dev phpunit/phpunit ^8 && \
    composer g require psy/psysh:@stable

colorEcho "${BLUE}Downloading ${FUCHSIA}psysh chinese php_manual${BLUE}..."
mkdir -p "$HOME/.local/share/psysh/" && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" "http://psysh.org/manual/zh/php_manual.sqlite" -o "$HOME/php_manual.sqlite" && \
    mv -f "$HOME/php_manual.sqlite" "$HOME/.local/share/psysh/php_manual.sqlite"


## pear & pecl
if [[ -x "$(command -v pecl)" ]]; then
    colorEcho "${BLUE}Fix for pecl..."
    pecl update-channels && rm -rf /tmp/pear "$HOME/.pearrc"

    ### fix PHP Fatal error: Cannot use result of built-in function in write context in /usr/share/php/Archive/Tar.php on line 639
    ### https://www.dotkernel.com/php-troubleshooting/fix-installing-pear-packages-with-php-7-2/
    sed -i 's/& func_get_args/func_get_args/' /usr/share/php/Archive/Tar.php # && pear install Archive_Tar

    ### fix Warning: Invalid argument supplied for foreach() in Command.php on line 249
    sed -i 's/exec $PHP -C -n -q/exec $PHP -C -q/' /usr/bin/pecl
fi