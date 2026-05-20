#!/bin/bash
set -e

TOTAL_STEPS=7
CONFIG_FILE="/etc/sysconfig/bootstrap-satellite"
NO_REBOOT=false

for arg in "$@"; do
    case "$arg" in
        --no-reboot) NO_REBOOT=true ;;
    esac
done

log() {
    local msg="[step $1/$TOTAL_STEPS] $2"
    echo "[bootstrap-satellite] $msg"
    logger -t bootstrap-satellite "$msg"
}

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: this script must be run as root"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config file $CONFIG_FILE not found"
    exit 1
fi

. "$CONFIG_FILE"

# Step 1: Disable all repos and enable required ones
log 1 "Configuring subscription-manager repositories"
if ! command -v subscription-manager &>/dev/null; then
    echo "Error: subscription-manager is not installed"
    exit 1
fi
subscription-manager repos --disable='*'
for repo in "${SATELLITE_REPOS[@]}"; do
    subscription-manager repos --enable="$repo"
done

# Step 2: Open firewall ports
log 2 "Opening firewall ports"
if ! command -v firewall-cmd &>/dev/null; then
    echo "Error: firewall-cmd is not installed"
    exit 1
fi
for port in "${FIREWALL_PORTS[@]}"; do
    firewall-cmd --add-port="$port"
done

# Step 3: Open firewall services
log 3 "Opening firewall services"
for service in "${FIREWALL_SERVICES[@]}"; do
    firewall-cmd --add-service="$service"
done

# Step 4: Persist firewall rules
log 4 "Persisting firewall rules"
firewall-cmd --runtime-to-permanent

# Step 5: Update and upgrade system
log 5 "Updating and upgrading system packages"
dnf update -y
dnf upgrade -y

# Step 6: Install rhel-system-roles
log 6 "Installing rhel-system-roles"
dnf install -y rhel-system-roles

# Step 7: Reboot
if [ "$NO_REBOOT" = true ]; then
    log 7 "Skipping reboot (--no-reboot flag set)"
    echo "Bootstrap complete. Reboot the system manually when ready."
else
    log 7 "Rebooting in 5 seconds (Ctrl+C to cancel)"
    sleep 5
    reboot
fi
