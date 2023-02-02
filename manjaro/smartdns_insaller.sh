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

# [SmartDNS](https://github.com/pymumu/smartdns)
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
server-https    https://dns.alidns.com/dns-query        -group china -exclude-default-group
server-https    https://doh.pub/dns-query               -group china -exclude-default-group
server-https    https://dns.pub/dns-query               -group china -exclude-default-group

server          1.0.0.1                                 -group world -exclude-default-group
server          1.1.1.1                                 -group world -exclude-default-group
server          8.8.8.8                                 -group world -exclude-default-group
server          8.8.4.4                                 -group world -exclude-default-group
server          9.9.9.9                                 -group world -exclude-default-group
server-tls      1.0.0.1                                 -group world -exclude-default-group
server-tls      1.1.1.1                                 -group world -exclude-default-group
server-tls      dns.google                              -group world -exclude-default-group
server-https    https://dns.google/dns-query            -group world -exclude-default-group
server-https    https://dns.cloudflare.com/dns-query    -group world -exclude-default-group

# conf-file       /etc/smartdns/accelerated-domains.china.smartdns.conf
# conf-file       /etc/smartdns/apple.china.smartdns.conf
# conf-file       /etc/smartdns/google.china.smartdns.conf
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

## Disable dnsmasq DNS Server
# if systemctl is-enabled dnsmasq >/dev/null 2>&1; then
#     sudo sed -i "s/[#]*[ ]*port=.*/port=0/" "/etc/dnsmasq.conf"
#     sudo systemctl restart dnsmasq
# else
#     if pgrep -f "dnsmasq" >/dev/null 2>&1; then
#         sudo pkill -f "dnsmasq"
#     fi
# fi

# Default DNS Server: 127.0.0.1#53
echo 'nameserver 127.0.0.1' | sudo tee "/etc/resolv.conf" >/dev/null

# [ChinaDNS-NG: Protect yourself against DNS poisoning in China](https://github.com/zfl9/chinadns-ng)
# dnsmasq:53->ChinaDNS:65353->China->SmartDNS:65355
#                           ->World->SmartDNS:65356
# DNS list
[[ -d "$HOME/chinadns-ng" ]] && cd "$HOME/chinadns-ng" && git reset --hard
Git_Clone_Update_Branch "zfl9/chinadns-ng" "$HOME/chinadns-ng"
if [[ -d "$HOME/chinadns-ng" ]]; then
    cd "$HOME/chinadns-ng" && \
        ./update-gfwlist.sh && ./update-chnlist.sh && ./update-chnroute.sh && ./update-chnroute6.sh

    sudo mkdir -p "/opt/chinadns-ng" && \
        sudo cp -f "$HOME/chinadns-ng/"*.txt "/opt/chinadns-ng" && \
        sudo cp -f "$HOME/chinadns-ng/"*.ipset "/opt/chinadns-ng" && \
        sudo cp -f "$HOME/chinadns-ng/chnlist.txt" "/opt/chinadns-ng/chinalist.txt"

    sed '1d' "/opt/chinadns-ng/chnroute.ipset" | awk '{print $3}' | sudo tee "/opt/chinadns-ng/chnroute.txt" >/dev/null
    sed '1d' "/opt/chinadns-ng/chnroute6.ipset" | awk '{print $3}' | sudo tee "/opt/chinadns-ng/chnroute6.txt" >/dev/null
fi

## ipset
colorEcho "${BLUE}Installing ${FUCHSIA}ipset${BLUE}..."
sudo pacman --noconfirm --needed -S ipset
# sudo ipset list -n
# sudo ipset list | grep ': '
# sudo ipset list

if [[ -s "/opt/chinadns-ng/chnroute.ipset" ]]; then
    sudo ipset -F chnroute 2>/dev/null
    sudo ipset -F chnroute6 2>/dev/null

    (sudo ipset -R -exist) <"/opt/chinadns-ng/chnroute.ipset"
    (sudo ipset -R -exist) <"/opt/chinadns-ng/chnroute6.ipset"
fi

yay --noconfirm --needed -S aur/chinadns-ng-git
if [[ -x "$(command -v chinadns-ng)" ]]; then
    CHINADNS_ARGS="--bind-port 65353 --china-dns 127.0.0.1#65355 --trust-dns 127.0.0.1#65356" && \
        CHINADNS_ARGS="${CHINADNS_ARGS} --gfwlist-file /opt/chinadns-ng/gfwlist.txt" && \
        CHINADNS_ARGS="${CHINADNS_ARGS} --chnlist-file /opt/chinadns-ng/chnlist.txt" && \
        CHINADNS_ARGS="${CHINADNS_ARGS} --verbose"

    if ! systemctl is-enabled "chinadnsng" >/dev/null 2>&1; then
        Install_systemd_Service "chinadnsng" "$(which chinadns-ng) ${CHINADNS_ARGS}" "root" "/opt/chinadns-ng"
    fi
fi

# Enable SmartDNS
# sudo tail -f /var/log/smartdns/smartdns.log
if ! sudo grep -q "^bind [::]:65355 -group china" "/etc/smartdns/smartdns.conf" 2>/dev/null; then
    sudo sed -i "s/^bind.*/bind [::]:65355 -group china/" "/etc/smartdns/smartdns.conf"
    sudo sed -i "/^bind/a\bind [::]:65356 -group world -no-speed-check" "/etc/smartdns/smartdns.conf"
fi
sudo systemctl enable smartdns
sudo systemctl restart smartdns

# Enable ChinaDNS-NG
sudo systemctl enable chinadnsng
sudo systemctl restart chinadnsng

# Enable dnsmasq
if ! sudo grep -q "^server=127.0.0.1#65353" "/etc/dnsmasq.conf" 2>/dev/null; then
    echo -e "\nno-resolv\nno-poll\nserver=127.0.0.1#65353" | sudo tee -a "/etc/dnsmasq.conf" >/dev/null
fi
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

# Restart network
colorEcho "${BLUE}Restarting ${FUCHSIA}Network${BLUE}..."
systemctl is-enabled network >/dev/null 2>&1 && sudo systemctl restart NetworkManager
systemctl is-enabled networking >/dev/null 2>&1 && sudo systemctl restart NetworkManager
systemctl is-enabled NetworkManager >/dev/null 2>&1 && sudo systemctl restart NetworkManager

sudo systemctl restart systemd-resolved
sudo systemctl restart systemd-networkd

sleep 3

## test dns status
# resolvectl status
# sudo tail -f /var/log/smartdns.log
# nslookup -querytype=ptr smartdns 127.0.0.1
# dig -querytype=ptr google.com @127.0.0.1


## Windows 11 DoH support
## https://docs.microsoft.com/zh-cn/windows-server/networking/dns/doh-client-support
# Add-DnsClientDohServerAddress -ServerAddress '<resolver-IP-address>' -DohTemplate '<resolver-DoH-template>' -AllowFallbackToUdp $False -AutoUpgrade $True
# Add-DnsClientDohServerAddress -ServerAddress '223.5.5.5' -DohTemplate 'https://dns.alidns.com/dns-query' -AllowFallbackToUdp $True -AutoUpgrade $True

# nslookup dns.ipv6dns.com 240C::6666
# Add-DnsClientDohServerAddress -ServerAddress '2408:873c:10:1::149' -DohTemplate 'https://dns.ipv6dns.com/dns-query' -AllowFallbackToUdp $False -AutoUpgrade $False
# Add-DnsClientDohServerAddress -ServerAddress '122.194.14.149' -DohTemplate 'https://dns.ipv6dns.com/dns-query' -AllowFallbackToUdp $False -AutoUpgrade $False

# Get-DNSClientDohServerAddress


cd "${CURRENT_DIR}" || exit
