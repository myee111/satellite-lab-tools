#!/bin/bash
set -e

CONFIG_FILE="/etc/sysconfig/set-hostname"
STAMP_FILE="/var/lib/set-hostname/.done"
GCP_GUEST_CFG_DIR="/etc/default/instance_configs.cfg.d"
GCP_GUEST_CFG="${GCP_GUEST_CFG_DIR}/10-disable-hostname.cfg"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config file $CONFIG_FILE not found"
    exit 1
fi

. "$CONFIG_FILE"

if [ -z "$HOSTNAME" ]; then
    echo "Error: HOSTNAME is not set in $CONFIG_FILE"
    exit 1
fi

CURRENT_HOSTNAME=$(hostname -f 2>/dev/null || hostname)

if [ -f "$STAMP_FILE" ] && [ "$CURRENT_HOSTNAME" = "$HOSTNAME" ]; then
    echo "Hostname is already set to $HOSTNAME, nothing to do"
    exit 0
fi

echo "Setting hostname to $HOSTNAME (was $CURRENT_HOSTNAME)"

# Disable GCP guest agent hostname management
if [ -d /etc/default ] || systemctl list-unit-files google-guest-agent.service &>/dev/null; then
    mkdir -p "$GCP_GUEST_CFG_DIR"
    cat > "$GCP_GUEST_CFG" <<'EOF'
[Unstable]
set_hostname = false
EOF
    echo "Disabled GCP guest agent hostname management"
    if systemctl is-active --quiet google-guest-agent; then
        systemctl restart google-guest-agent
    fi
fi

hostnamectl set-hostname "$HOSTNAME"

MACHINE_IP=$(hostname -I | awk '{print $1}')
SHORT_NAME="${HOSTNAME%%.*}"

if [ -n "$MACHINE_IP" ]; then
    cp /etc/hosts /etc/hosts.bak
    if ! grep -q "^${MACHINE_IP}.*${HOSTNAME}" /etc/hosts; then
        sed -i "/^${MACHINE_IP}/d" /etc/hosts
        echo "${MACHINE_IP} ${HOSTNAME} ${SHORT_NAME}" >> /etc/hosts
    fi
fi

mkdir -p "$(dirname "$STAMP_FILE")"
touch "$STAMP_FILE"

echo "Hostname set to $HOSTNAME, /etc/hosts updated"
