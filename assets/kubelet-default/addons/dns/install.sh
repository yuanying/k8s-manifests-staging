#!/bin/bash

set -eu
export LC_ALL=C
ROOT=$(dirname "${BASH_SOURCE}")

# mkdir -p /etc/systemd/resolved.conf.d/
#
# cat <<EOF > /etc/systemd/resolved.conf.d/cluster.local.conf
# [Resolve]
# DNS=192.168.0.1
# Domains=default.svc.cluster.local svc.cluster.local cluster.local
# EOF
rm -f /etc/systemd/resolved.conf.d/cluster.local.conf

systemctl restart systemd-resolved

cat << EOF > /etc/systemd/network/10-porka-dummy.netdev
[NetDev]
Name=porka-dummy01
Kind=dummy
EOF

systemctl restart systemd-networkd

cat <<EOF > /etc/systemd/system/cluster-dns.service
[Unit]
Description=Setup cluster.local DNS
After=systemd-resolved.service
Requires=systemd-resolved.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=resolvectl dns porka-dummy01 10.254.0.10
ExecStart=resolvectl domain porka-dummy01 default.svc.cluster.local svc.cluster.local cluster.local

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart cluster-dns.service
