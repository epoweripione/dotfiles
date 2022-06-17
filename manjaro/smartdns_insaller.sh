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

# https://blog.dnomd343.top/dns-server/
colorEcho "${BLUE}Installing ${FUCHSIA}smartdns${BLUE}..."
yay --noconfirm --needed -S dnslookup-bin smartdns smartdns-china-list-git

# sudo sed -i -e "s/[#]*[ ]*cache-persist.*/cache-persist yes/" \
#             -e "s|[#]*[ ]*cache-file.*|cache-file /tmp/smartdns.cache|" \
#             -e "s/[#]*[ ]*prefetch-domain.*/prefetch-domain yes/"\
#     "/etc/smartdns/smartdns.conf"

sudo tee "/etc/smartdns/smartdns_server.conf" >/dev/null <<-'EOF'
server-tls      1.0.0.1
server-https    https://dns.alidns.com/dns-query
server-https    https://doh.pub/dns-query
server-https    https://dns.pub/dns-query
server          1.0.0.1
server          8.8.8.8

server          223.5.5.5                               -group china -exclude-default-group
server          223.6.6.6                               -group china -exclude-default-group
server          119.29.29.29                            -group china -exclude-default-group
server          119.28.28.28                            -group china -exclude-default-group
server          117.50.10.10                            -group china -exclude-default-group
server          114.114.114.114                         -group china -exclude-default-group
server          114.114.115.115                         -group china -exclude-default-group

server          1.1.1.1                                 -group world -exclude-default-group
server          8.8.4.4                                 -group world -exclude-default-group
server          9.9.9.9                                 -group world -exclude-default-group
server-tls      1.1.1.1                                 -group world -exclude-default-group
server-tls      dns.google                              -group world -exclude-default-group
server-https    https://dns.google/dns-query            -group world -exclude-default-group
server-https    https://dns.cloudflare.com/dns-query    -group world -exclude-default-group

conf-file       /etc/smartdns/accelerated-domains.china.smartdns.conf
conf-file       /etc/smartdns/apple.china.smartdns.conf
conf-file       /etc/smartdns/google.china.smartdns.conf
EOF

if ! sudo grep -q "^conf-file /etc/smartdns/smartdns_server.conf" "/etc/smartdns/smartdns.conf" 2>/dev/null; then
    echo -e "\nconf-file /etc/smartdns/smartdns_server.conf" \
        | sudo tee -a "/etc/smartdns/smartdns.conf" >/dev/null
fi

# Disable overwriting of /etc/resolv.conf by NM
sudo rm "/etc/resolv.conf" && sudo touch "/etc/resolv.conf"
echo -e '[main]\ndns=none' \
    | sudo tee "/etc/NetworkManager/conf.d/disableresolv.conf" >/dev/null

# FallbackDNS
sudo mkdir -p "/etc/systemd/resolved.conf.d"
sudo tee "/etc/systemd/resolved.conf.d/fallback_dns.conf" >/dev/null <<-'EOF'
[Resolve]
DNS=127.0.0.1
FallbackDNS=223.5.5.5 119.29.29.29 117.50.10.10 114.114.114.114
DNSStubListener=no
EOF

# Disable dnsmasq DNS Server
if [[ $(systemctl is-enabled dnsmasq 2>/dev/null) ]]; then
    sudo sed -i "s/[#]*[ ]*port=.*/port=0/" "/etc/dnsmasq.conf"
    sudo systemctl restart dnsmasq
else
    if pgrep -f "dnsmasq" >/dev/null 2>&1; then
        sudo pkill -f "dnsmasq"
    fi
fi

echo 'nameserver 127.0.0.1' | sudo tee "/etc/resolv.conf" >/dev/null

# Enable SmartDNS
sudo systemctl enable smartdns && sudo systemctl start smartdns

# Restart network
colorEcho "${BLUE}Restarting ${FUCHSIA}Network${BLUE}..."
[[ $(systemctl is-enabled network 2>/dev/null) ]] && sudo systemctl restart NetworkManager
[[ $(systemctl is-enabled networking 2>/dev/null) ]] && sudo systemctl restart NetworkManager
[[ $(systemctl is-enabled NetworkManager 2>/dev/null) ]] && sudo systemctl restart NetworkManager

sudo systemctl restart systemd-resolved
sudo systemctl restart systemd-networkd

sleep 3

## test dns status
# resolvectl status
# sudo tail -f /var/log/smartdns.log
# nslookup -querytype=ptr smartdns 127.0.0.1
# dig -querytype=ptr google.com @127.0.0.1


cd "${CURRENT_DIR}" || exit
