#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)


if [[ ! -x "$(command -v php)" ]]; then
    echo "php is not installed! Please install php first!"
    exit 0
fi

if [[ ! -x "$(command -v php-config)" ]]; then
    echo "php-config is not installed! Please install php-config first!"
    exit 0
fi

if [[ ! -x "$(command -v pecl)" ]]; then
    echo "pear is not installed! Please install pear first!"
    exit 0
fi

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

### fix PHP Fatal error: Cannot use result of built-in function in write context in /usr/share/php/Archive/Tar.php on line 639
### https://www.dotkernel.com/php-troubleshooting/fix-installing-pear-packages-with-php-7-2/
sed -i 's/& func_get_args/func_get_args/' /usr/share/php/Archive/Tar.php # && pear install Archive_Tar
### fix Warning: Invalid argument supplied for foreach() in Command.php on line 249
sed -i 's/exec $PHP -C -n -q/exec $PHP -C -q/' /usr/bin/pecl

## Find PHP extension_dir
## php -ini | grep extension_dir
PHP_VERSION=$(php --version | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
PHP_EXT_DIR=$(php-config --extension-dir)
PHP_INI_DIR=$(php --ini | grep "Scan for additional .ini files in" | cut -d':' -f2 | cut -d' ' -f2 | head -n1)

## pecl install imagick memcached mongodb oauth xdebug
## use proxy: curl -v --socks5-hostname 127.0.0.1:55880
apt install -y libmagickwand-dev libmemcached-dev zlib1g-dev --no-install-recommends && \
    mkdir -p "${WORKDIR}/pecl_downloads" && \
    cd "${WORKDIR}/pecl_downloads" && \
    : && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/imagick -o imagick.tgz && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/memcached -o memcached.tgz && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/mongodb -o mongodb.tgz && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/oauth -o oauth.tgz && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/redis -o redis.tgz && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/xdebug -o xdebug.tgz && \
    : && \
    printf "\n" | pecl install --force imagick.tgz && \
    printf "\n" | pecl install --force memcached.tgz && \
    printf "\n" | pecl install --force mongodb.tgz && \
    printf "\n" | pecl install --force oauth.tgz && \
    printf "\n" | pecl install --force redis.tgz && \
    printf "\n" | pecl install --force xdebug.tgz && \
    : && \
    echo 'extension=imagick.so' > "$PHP_INI_DIR/90-imagick.ini" && \
    echo 'extension=memcached.so' > "$PHP_INI_DIR/90-memcached.ini" && \
    echo 'extension=mongodb.so' > "$PHP_INI_DIR/90-mongodb.ini" && \
    echo 'extension=oauth.so' > "$PHP_INI_DIR/90-oauth.ini" && \
    echo 'extension=redis.so' > "$PHP_INI_DIR/90-redis.ini" && \
    echo 'zend_extension=xdebug.so' > "$PHP_INI_DIR/90-xdebug.ini"

## psr、swoole
apt install -y libpq-dev nghttp2 libnghttp2-dev --no-install-recommends && \
    mkdir -p "${WORKDIR}/pecl_downloads" && \
    cd "${WORKDIR}/pecl_downloads" && \
    : && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/psr -o psr.tgz && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/swoole -o swoole.tgz && \
    : && \
    printf "\n" | pecl install --force psr.tgz && \
    printf "\n" | pecl install --force swoole.tgz && \
    : && \
    echo 'extension=psr.so' > "$PHP_INI_DIR/50-psr.ini" && \
    echo 'extension=swoole.so' > "$PHP_INI_DIR/90-swoole.ini"

## swoole swoole_postgresql
## https://github.com/swoole/ext-postgresql
# mkdir -p "${WORKDIR}/pecl_downloads" && \
#     cd "${WORKDIR}" && \
#     : && \
#     curl "${CURL_DOWNLOAD_OPTS[@]}" -o ./pecl_downloads/ext-postgresql.tar.gz "https://github.com/swoole/ext-postgresql/archive/master.tar.gz" && \
#     tar zxvf ./pecl_downloads/ext-postgresql.tar.gz && \
#     mv ext-postgresql* ext-postgresql && cd ext-postgresql && \
#     phpize && \
#     ./configure >/dev/null && \
#     make >/dev/null && make install >/dev/null && \
#     echo 'extension=swoole_postgresql.so' > "$PHP_INI_DIR/90-swoole_postgresql.ini"

## Phalcon
## https://github.com/phalcon/cphalcon
apt install -y "php${PHP_VERSION}-dev" libpcre3-dev gcc make re2c --no-install-recommends && \
    mkdir -p "${WORKDIR}/pecl_downloads" && \
    cd "${WORKDIR}" && \
    : && \
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o ./pecl_downloads/cphalcon.tar.gz "https://github.com/phalcon/cphalcon/archive/master.tar.gz" && \
    tar zxvf ./pecl_downloads/cphalcon.tar.gz && \
    mv cphalcon* cphalcon && cd cphalcon/build && \
    ./install --phpize "/usr/bin/phpize${PHP_VERSION}" --php-config "/usr/bin/php-config${PHP_VERSION}" && \
    echo 'extension=phalcon.so' > "$PHP_INI_DIR/90-phalcon.ini"

## PDFlib
## https://www.pdflib.com/download/pdflib-product-family/
PDFlib_REMOTE_VER="9.2.0"
PDFlib_CURRENT_VER=$(php --ri pdflib | grep "Binary-Version" | cut -d'>' -f2 | cut -d' ' -f2)
PDFlib_BIN_VER=$(echo "${PHP_VERSION}0" | cut -c 1,3-)
if [[ "$PDFlib_CURRENT_VER" != "$PDFlib_REMOTE_VER" ]]; then
    cd "${WORKDIR}" && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -o pdflib.tar.gz "https://www.pdflib.com/binaries/PDFlib/920/PDFlib-9.2.0-Linux-x86_64-php.tar.gz" && \
        tar -xvf pdflib.tar.gz && \
        mv PDFlib-* pdflib

    if [[ -d "${WORKDIR}/pdflib/bind/php/php-${PDFlib_BIN_VER}-nts" ]]; then
        cp "${WORKDIR}/pdflib/bind/php/php-${PDFlib_BIN_VER}-nts/php_pdflib.so" "$PHP_EXT_DIR" && \
        echo 'extension=php_pdflib.so' > "$PHP_INI_DIR/90-pdflib.ini"
    fi
fi

## How to install OCI8
## https://gist.github.com/hewerthomn/81eea2935051eb2500941a9309bca703

## Download the Oracle Instant Client and SDK from Oracle website. (Need to login in Oracle page)
## http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
## or download from
## https://github.com/bumpx/oracle-instantclient

## How to use sqlplus
## sqlplus scott/tiger@//myhost.example.com:1521/myservice
## sqlplus system/\"sYs-p@ssw0rd\"@//debian:1521/ORCLCDB

## fix error: ORA-65096: invalid common user or role name
## select con_id,dbid,NAME,OPEN_MODE from v$pdbs;
## alter pluggable database ORCLPDB1 open;
## alter session set container=ORCLPDB1;
## select sys_context('USERENV','CON_NAME') from dual;

## fix error: ORA-01950: no privileges on tablespace 'USERS'
## use QUOTA when create user
## CREATE USER test IDENTIFIED BY test DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
## or
## ALTER USER test QUOTA UNLIMITED ON USERS;

## Check sqlplus LANGUAGE
## SELECT USERENV('LANGUAGE') FROM DUAL;
## export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"

# echo -e "SET HEAD OFF;\nSELECT USERENV('LANGUAGE') FROM DUAL;\nexit;" > sqlplus_query_nls_lang.sql && \
#     sqlplus -S system/\"sYs-p@ssw0rd\"@//debian:1521/ORCLCDB @sqlplus_query_nls_lang.sql > NLS_LANG && \
#     while IFS= read -r line; do if [[ -n "$line" ]]; then export "NLS_LANG=$line"; fi; done < NLS_LANG

## fix arrow keys are not functional in sqlplus
apt install -y rlwrap && alias sqlplus="rlwrap sqlplus"

if ls /etc/ld.so.conf.d/oracle-instantclient* >/dev/null 2>&1; then
    ORACLE_INSTANT_EXIST="yes"
else
    ORACLE_INSTANT_EXIST="no"
fi

ORACLE_INSTANT_CLIENT="19c"

if [[ "$ORACLE_INSTANT_EXIST" == "no" && "$ORACLE_INSTANT_CLIENT" == "21c" ]]; then
    mkdir -p /opt/oracle && cd /opt/oracle && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sdk-linux.x64-21.1.0.0.0.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sqlplus-linux.x64-21.1.0.0.0.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-tools-linux.x64-21.1.0.0.0.zip && \
        : && \
        unzip instantclient-basic-linux.x64-21.1.0.0.0.zip && \
        unzip instantclient-sdk-linux.x64-21.1.0.0.0.zip && \
        unzip instantclient-sqlplus-linux.x64-21.1.0.0.0.zip && \
        unzip instantclient-tools-linux.x64-21.1.0.0.0.zip && \
        : && \
        echo /opt/oracle/instantclient_21_1 > /etc/ld.so.conf.d/oracle-instantclient21.1 && \
        : && \
        ldconfig && \
        : && \
        rm -rf /opt/oracle/*.zip
elif [[ "$ORACLE_INSTANT_EXIST" == "no" && "$ORACLE_INSTANT_CLIENT" == "19c" ]]; then
    mkdir -p /opt/oracle && cd /opt/oracle && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-basic-linux.x64-19.10.0.0.0dbru.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-sdk-linux.x64-19.10.0.0.0dbru.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-sqlplus-linux.x64-19.10.0.0.0dbru.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-tools-linux.x64-19.10.0.0.0dbru.zip && \
        : && \
        unzip instantclient-basic-linux.x64-19.10.0.0.0dbru.zip && \
        unzip instantclient-sdk-linux.x64-19.10.0.0.0dbru.zip && \
        unzip instantclient-sqlplus-linux.x64-19.10.0.0.0dbru.zip && \
        unzip instantclient-tools-linux.x64-19.10.0.0.0dbru.zip && \
        : && \
        echo /opt/oracle/instantclient_19_10 > /etc/ld.so.conf.d/oracle-instantclient19.10 && \
        : && \
        ldconfig && \
        : && \
        rm -rf /opt/oracle/*.zip
elif [[ "$ORACLE_INSTANT_EXIST" == "no" && "$ORACLE_INSTANT_CLIENT" == "18c" ]]; then
    mkdir -p /opt/oracle && cd /opt/oracle && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/185000/instantclient-basic-linux.x64-18.5.0.0.0dbru.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/185000/instantclient-sdk-linux.x64-18.5.0.0.0dbru.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/185000/instantclient-sqlplus-linux.x64-18.5.0.0.0dbru.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://download.oracle.com/otn_software/linux/instantclient/185000/instantclient-tools-linux.x64-18.5.0.0.0dbru.zip && \
        : && \
        unzip instantclient-basic-linux.x64-18.5.0.0.0dbru.zip && \
        unzip instantclient-sdk-linux.x64-18.5.0.0.0dbru.zip && \
        unzip instantclient-sqlplus-linux.x64-18.5.0.0.0dbru.zip && \
        unzip instantclient-tools-linux.x64-18.5.0.0.0dbru.zip && \
        : && \
        echo /opt/oracle/instantclient_18_5 > /etc/ld.so.conf.d/oracle-instantclient18.5 && \
        : && \
        ldconfig && \
        : && \
        rm -rf /opt/oracle/*.zip
elif [[ "$ORACLE_INSTANT_EXIST" == "no" && "$ORACLE_INSTANT_CLIENT" == "12c" ]]; then
    mkdir -p /opt/oracle && cd /opt/oracle && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://github.com/epoweripione/oracle-instantclient/raw/master/instantclient-basic-linux.x64-12.2.0.1.0.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://github.com/epoweripione/oracle-instantclient/raw/master/instantclient-sdk-linux.x64-12.2.0.1.0.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://github.com/epoweripione/oracle-instantclient/raw/master/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip && \
        curl "${CURL_DOWNLOAD_OPTS[@]}" -O https://github.com/epoweripione/oracle-instantclient/raw/master/instantclient-tools-linux.x64-12.2.0.1.0.zip && \
        : && \
        unzip instantclient-basic-linux.x64-12.2.0.1.0.zip && \
        unzip instantclient-sdk-linux.x64-12.2.0.1.0.zip && \
        unzip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip && \
        unzip instantclient-tools-linux.x64-12.2.0.1.0.zip && \
        : && \
        ln -s /opt/oracle/instantclient_12_2/libclntsh.so.12.1 /opt/oracle/instantclient_12_2/libclntsh.so && \
        ln -s /opt/oracle/instantclient_12_2/libocci.so.12.1 /opt/oracle/instantclient_12_2/libocci.so && \
        echo /opt/oracle/instantclient_12_2 > /etc/ld.so.conf.d/oracle-instantclient12.2 && \
        : && \
        ldconfig && \
        : && \
        rm -rf /opt/oracle/*.zip
fi

# Oracle Instant Client
if [[ -d "/opt/oracle/instantclient_21_1" ]]; then
    export ORACLE_HOME="/opt/oracle/instantclient_21_1"
elif [[ -d "/opt/oracle/instantclient_19_10" ]]; then
    export ORACLE_HOME="/opt/oracle/instantclient_19_10"
elif [[ -d "/opt/oracle/instantclient_18_5" ]]; then
    export ORACLE_HOME="/opt/oracle/instantclient_18_5"
elif [[ -d "/opt/oracle/instantclient_18_3" ]]; then
    export ORACLE_HOME="/opt/oracle/instantclient_18_3"
elif [[ -d "/opt/oracle/instantclient_12_2" ]]; then
    export ORACLE_HOME="/opt/oracle/instantclient_12_2"
fi

# if [[ -d "/opt/oracle/instantclient_18_3" ]]; then
#     export ORACLE_HOME="/opt/oracle/instantclient_18_3"
# elif [[ -d "/opt/oracle/instantclient_12_2" ]]; then
#     export ORACLE_HOME="/opt/oracle/instantclient_12_2"
# fi

# if [[ -n "$ORACLE_HOME" ]]; then
#     if [[ -z "$LD_LIBRARY_PATH" ]]; then
#         export LD_LIBRARY_PATH=$ORACLE_HOME
#     else
#         export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME
#     fi

#     export PATH=$PATH:$ORACLE_HOME

#     if [[ -x "$(command -v rlwrap)" ]]; then
#         alias sqlplus="rlwrap sqlplus"
#         alias rman="rlwrap rman"
#         alias asmcmd="rlwrap asmcmd"
#         alias ggsci="rlwrap ggsci"
#     fi
# fi

# oci8
if ls /etc/ld.so.conf.d/oracle-instantclient* >/dev/null 2>&1; then
    if [[ ! -s "$PHP_INI_DIR/90-oci8.ini" ]]; then
        apt install -y build-essential libaio1 --no-install-recommends && \
            mkdir -p "${WORKDIR}/pecl_downloads" && \
            cd "${WORKDIR}/pecl_downloads" && \
            : && \
            curl "${CURL_DOWNLOAD_OPTS[@]}" http://pecl.php.net/get/oci8 -o oci8.tgz && \
            printf "instantclient,%s\n" "$ORACLE_HOME" | pecl install --force oci8.tgz && \
            echo 'extension=oci8.so' > "$PHP_INI_DIR/90-oci8.ini"
    fi
fi

## How to check php extensions which shared libraries depends on
## ldd $PHP_EXT_DIR/oci8.so

cd "${CURRENT_DIR}" || exit
