#!/bin/bash
set -e

CONFIG_FILE="/etc/sysconfig/set-hostname"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config file $CONFIG_FILE not found"
    exit 1
fi

. "$CONFIG_FILE"

if [ -z "$HOSTNAME" ]; then
    echo "Error: HOSTNAME is not set in $CONFIG_FILE"
    exit 1
fi

CURRENT_HOSTNAME=$(hostname)
MACHINE_IP=$(hostname -I | awk '{print $1}')
SHORT_NAME="${HOSTNAME%%.*}"

if [ "$CURRENT_HOSTNAME" = "$HOSTNAME" ] && grep -q "$HOSTNAME" /etc/hosts; then
    echo "Hostname is already set to $HOSTNAME"
    exit 0
fi

echo "Setting hostname to $HOSTNAME (was $CURRENT_HOSTNAME)"
hostnamectl set-hostname "$HOSTNAME"

cp /etc/hosts /etc/hosts.bak

if grep -q "^127\.0\.0\.1" /etc/hosts; then
    sed -i "s/^127\.0\.0\.1.*/127.0.0.1   localhost localhost.localdomain $HOSTNAME $SHORT_NAME/" /etc/hosts
else
    echo "127.0.0.1   localhost localhost.localdomain $HOSTNAME $SHORT_NAME" >> /etc/hosts
fi

if [ -n "$MACHINE_IP" ]; then
    sed -i "/^${MACHINE_IP}[[:space:]]/d" /etc/hosts
    echo "$MACHINE_IP $HOSTNAME $SHORT_NAME" >> /etc/hosts
fi

echo "Hostname set to $HOSTNAME, /etc/hosts updated"
