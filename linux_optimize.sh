#!/usr/bin/env bash

## Clear Systemd Journal Logs
# du -sh /var/log/journal/
# journalctl --disk-usage

# rotate journal files
sudo journalctl --rotate

## Clear journal log older than x days
# sudo journalctl --vacuum-time=2d

## Restrict number of log files
# sudo journalctl --vacuum-files=5

# Restrict logs to a certain size
sudo journalctl --vacuum-size=1G


## sysctl.conf
# https://klaver.it/linux/sysctl.conf
# https://wsgzao.github.io/post/sysctl/
SYSCTL_FILE="/etc/sysctl.conf"
if ! sudo test -f "${SYSCTL_FILE}"; then
    sudo test -d "/etc/sysctl.d/" && SYSCTL_FILE="/etc/sysctl.d/99-sysctl.conf"
fi

if ! sudo grep -q "# turn on bbr" "${SYSCTL_FILE}" 2>/dev/null; then
    sudo tee -a "${SYSCTL_FILE}" >/dev/null <<-'EOF'

# for high-latency network
# net.ipv4.tcp_congestion_control = hybla

# disable ipv6
# net.ipv6.conf.all.disable_ipv6 = 1

# turn on bbr
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3

# Avoid falling back to slow start after a connection goes idle
# keeps our cwnd large with the keep alive connections
net.ipv4.tcp_slow_start_after_idle = 0

# max open files
fs.file-max = 1024000
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096

# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
# net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65535
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

# forward ipv4
net.ipv4.ip_forward = 1
EOF
fi

# limits.conf
if ! sudo grep -q "\*               soft    nofile           512000" /etc/security/limits.conf 2>/dev/null; then
    sudo tee -a /etc/security/limits.conf >/dev/null <<-'EOF'

*               soft    nofile           512000
*               hard    nofile          1024000
EOF
fi

if ! sudo grep -q "session required pam_limits.so" /etc/pam.d/common-session 2>/dev/null; then
    sudo tee -a /etc/pam.d/common-session >/dev/null <<-'EOF'

session required pam_limits.so
EOF
fi

if ! sudo grep -q "ulimit -SHn 1024000" /etc/profile 2>/dev/null; then
    sudo tee -a /etc/profile >/dev/null <<-'EOF'

ulimit -SHn 1024000
EOF
fi

# ulimit -n

sudo sysctl -p 2>/dev/null

if systemctl is-enabled systemd-sysctl >/dev/null 2>&1; then
    sudo systemctl restart systemd-sysctl
fi

echo -n "Reboot now?[Y/n]:"
read -r IS_REBOOT
[[ -z "${IS_REBOOT}" ]] && IS_REBOOT="Y"
[[ "${IS_REBOOT}" == "y" || "${IS_REBOOT}" == "Y" ]] && sudo reboot
