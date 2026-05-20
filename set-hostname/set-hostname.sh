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

MACHINE_IP=$(hostname -I | awk '{print $1}')
SHORT_NAME="${HOSTNAME%%.*}"

cp /etc/hosts /etc/hosts.bak
if [ -n "$MACHINE_IP" ]; then
    sed -i "/${MACHINE_IP}.*# Added by Google$/d" /etc/hosts
fi

CURRENT_HOSTNAME=$(hostname -f 2>/dev/null || hostname)

if [ "$CURRENT_HOSTNAME" = "$HOSTNAME" ] && grep -q "$HOSTNAME" /etc/hosts; then
    echo "Hostname is already set to $HOSTNAME"
    exit 0
fi

echo "Setting hostname to $HOSTNAME (was $CURRENT_HOSTNAME)"
hostnamectl set-hostname "$HOSTNAME"

if [ -n "$MACHINE_IP" ]; then
    if ! grep -q "^${MACHINE_IP}.*${HOSTNAME}" /etc/hosts; then
        sed -i "s/^${MACHINE_IP}.*/${MACHINE_IP} ${HOSTNAME} ${SHORT_NAME}/" /etc/hosts
        if ! grep -q "^${MACHINE_IP}" /etc/hosts; then
            echo "${MACHINE_IP} ${HOSTNAME} ${SHORT_NAME}" >> /etc/hosts
        fi
    fi
fi

echo "Hostname set to $HOSTNAME, /etc/hosts updated"
