#!/usr/bin/env bash

## mount snapshots if failed
# sudo mount -a
# findmnt -nt btrfs
# findmnt -nt btrfs --output TARGET

## cron
# (sudo crontab -l 2>/dev/null || true; echo "@reboot mount -a") | sudo crontab -

# [make a systemd service as the last service on boot](https://superuser.com/questions/544399/how-do-you-make-a-systemd-service-as-the-last-service-on-boot)
sudo tee "/etc/systemd/system/custom.target" >/dev/null <<-EOF
[Unit]
Description=Custom Target
Requires=multi-user.target
After=multi-user.target
AllowIsolate=yes
EOF

custom_wants="/etc/systemd/system/custom.target.wants"
sudo mkdir -p "${custom_wants}"

service_name="RemountAllBtrfsSubvolumn"
service_file="/etc/systemd/system/${service_name}.service"

sudo tee "${service_file}" >/dev/null <<-EOF
[Unit]
Description=${service_name}
After=multi-user.target

[Service]
Type=simple
ExecStart=mount -a

[Install]
WantedBy=custom.target
EOF

sudo ln -s "${service_file}" "${custom_wants}/${service_name}.service"

sudo systemctl daemon-reload
sudo systemctl set-default custom.target

# systemctl isolate custom.target
