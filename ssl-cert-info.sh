#!/usr/bin/env bash

## Shell script to check SSL certificate info like expiration date and subject.
## From https://gist.github.com/stevenringo/2fe5000d8091f800aee4bb5ed1e800a6
## Taken from http://giantdorks.org/alain/shell-script-to-check-ssl-certificate-info-like-expiration-date-and-subject/

usage()
{
cat <<EOF
Usage: $(basename "$0") [options]

This shell script is a simple wrapper around the openssl binary. It uses
s_client to get certificate information from remote hosts, or x509 for local
certificate files. It can parse out some of the openssl output or just dump all
of it as text.

Options:

    --all-info  Print all output, including boring things like Modulus and 
                Exponent.

    --alt       Print Subject Alternative Names. These will be typically be 
                additional hostnames that the certificate is valid for.

    --cn        Print commonName from Subject. This is typically the host for 
                which the certificate was issued.

    --debug     Print additional info that might be helpful when debugging this
                script.

    --end       Print certificate expiration date. For additional functionality
                related to certificate expiration, take a look at this script:
                "http://prefetch.net/code/ssl-cert-check".

    --dates     Print start and end dates of when the certificate is valid.

    --file      Use a local certificate file for input.

    --help      Print this help message.

    --host      Fetch the certificate from this remote host.

    --name      Specify a specific domain name (Virtual Host) along with the
                request. This value will be used as the '-servername' in the 
                s_client command. This is for TLS SNI (Server Name Indication).

    --issuer    Print the certificate issuer.

    --most-info Print almost everything. Skip boring things like Modulus and
                Exponent.

    --option    Pass any openssl option through to openssl to get its raw
                output.

    --port      Use this port when conneting to remote host. If ommitted, port
                defaults to 443.

    --subject   Print the certificate Subject -- typically address and org name.

    Examples:

    1. Print a list of all hostnames that the certificate used by amazon.com 
        is valid for.

        $(basename "$0") --host amazon.com --alt
        DNS:uedata.amazon.com
        DNS:amazon.com
        DNS:amzn.com
        DNS:www.amzn.com
        DNS:www.amazon.com

    2. Print issuer of certificate used by smtp.gmail.com. Fetch certficate info
        over port 465.

        $(basename "$0") --host smtp.gmail.com --port 465 --issuer
        issuer= 
            countryName               = US
            organizationName          = Google Inc
            commonName                = Google Internet Authority G2

    3. Print valid dates for the certificate, using a local file as the source of 
        certificate data. Dates are formatted using the date command and display
        time in your local timezone instead of GMT.

        $(basename "$0") --file /path/to/file.crt --dates
        valid from: 2014-02-04 16:00:00 PST
        valid till: 2017-02-04 15:59:59 PST


    4. Print certificate serial number. This script doesn't have a special option
        to parse out the serial number, so will use the generic --option flag to
        pass '-serial' through to openssl.

        $(basename "$0") --host gmail.com --option -serial
        serial=4BF004B4DDC9C2F8
EOF
}

if ! [ -x "$(type -P openssl)" ]; then
    echo "ERROR: script requires openssl"
    echo "For Debian and friends, get it with 'apt-get install openssl'"
    exit 1
fi

while [ "$1" ]; do
    case "$1" in
            --file)
                shift
                crt="$1"
                source="local"
                ;;
            --host)
                shift
                host="$1"
                source="remote"
                ;;
            --port)
                shift
                port="$1"
                ;;
            --name)
                shift
                servername="-servername $1"
                ;;
            --all-info)
                opt="-text"
                ;;
            --alt)
                FormatOutput() {
                    grep -A1 "Subject Alternative Name:" | tail -n1 |
                    tr -d ' ' | tr ',' '\n'
                }
                ;;
            --cn)
                opt="-subject -nameopt multiline"
                FormatOutput() {
                    awk '/commonName/ {print$NF}'
                }
                ;;
            --dates)
                opt="-dates"
                FormatOutput() {
                    dates=$(cat -)
                    start=$(grep Before <<<"$dates" | cut -d= -f2-)
                    end=$(grep After <<<"$dates" | cut -d= -f2-)
                    echo "valid from: $(date -d "$start" '+%F %T %Z')"
                    echo "valid till: $(date -d "$end" '+%F %T %Z')"
                }
                ;;
            --end)
                opt="-enddate"
                FormatOutput() {
                    read -r end
                    end=$(cut -d= -f2- <<<"$end")
                    date -d "$end" '+%F %T %Z'
                }
                ;;
            --issuer)
                opt="-issuer -nameopt multiline"
                ;;
            --most-info)
                opt="-text -certopt no_header,no_version,no_serial,no_signame,no_pubkey,no_sigdump,no_aux"
                ;;
            --option)
                shift
                opt="$1"
                ;;
            --subject)
                opt="-subject -nameopt multiline"
                ;;
            --help)
                usage
                exit 0
                ;;
            --debug)
                DEBUG="yes"
                ;;
            *)
                echo "$(basename "$0"): invalid option $1" >&2
                echo "see --help for usage"
                exit 1
                ;;
    esac
    shift
done

CheckLocalCert() {
    openssl x509 -in "$crt" -noout "$opt"
}

CheckRemoteCert() {
    # shellcheck disable=SC2086
    echo |
    openssl s_client $servername -connect "$host:$port" 2>/dev/null |
    openssl x509 -noout "$opt"
}

if [ -z "$(type -t FormatOutput)" ]; then
    FormatOutput() { cat; }
fi

if [ -z "$opt" ]; then
    opt="-text -certopt no_header,no_version,no_serial,no_signame,no_pubkey,no_sigdump,no_aux"
fi

if [ -z "$source" ]; then
    echo "ERROR: missing certificate source."
    echo "Provide one via '--file' or '--host' arguments."
    echo "See '--help' for examples."
    exit 1
fi

if [ "$source" == "local" ]; then
    [ -n "$DEBUG" ] && echo "DEBUG: certificate source is local file"
    if [ -z "$crt" ]; then
        echo "ERROR: missing certificate file"
        exit 1
    fi
    [ -n "$DEBUG" ] && echo
    CheckLocalCert | FormatOutput
fi

if [ "$source" == "remote" ]; then
    [ -n "$DEBUG" ] && echo "DEBUG: certificate source is remote host"
    if [ -z "$host" ]; then
        echo "ERROR: missing remote host value."
        echo "Provide one via '--host' argument"
        exit 1
    fi
    if [ -z "$port" ]; then
        [ -n "$DEBUG" ] && echo "DEBUG: defaulting to 443 for port."
        port="443"
    fi
    [ -n "$DEBUG" ] && echo
    CheckRemoteCert | FormatOutput
fi
