#!/bin/bash

set -eu
export LC_ALL=C
ROOT=$(dirname "${BASH_SOURCE}")

cat << EOF > /etc/systemd/network/10-porka-dummy.netdev
[NetDev]
Name=porka-dummy01
Kind=dummy
EOF

cat << EOF > /etc/systemd/network/20-porka-dummy.network
[Match]
Name=porka-dummy01

[Network]
Address=10.253.0.1/24
EOF

systemctl restart systemd-networkd

cat <<EOF > /etc/systemd/system/cluster-dns.service
[Unit]
Description=Setup unstable.cluster DNS
After=systemd-resolved.service
Requires=systemd-resolved.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=resolvectl revert porka-dummy01
ExecStart=resolvectl dns porka-dummy01 10.253.0.10
ExecStart=resolvectl domain porka-dummy01 default.svc.unstable.cluster svc.unstable.cluster unstable.cluster

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart cluster-dns.service
