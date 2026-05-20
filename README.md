# satellite-lab-tools

Automation tools for Red Hat Satellite lab environments. Includes a persistent hostname service and a one-shot bootstrap script, packaged as a single RPM.

## Prerequisites

- RHEL 9 (or compatible) VM
- System registered with `subscription-manager`
- `firewalld` installed and running

## Quick Start

Download the RPM and copy it to the VM:

```bash
curl -LO https://github.com/myee111/satellite-lab-tools/releases/download/v2.0/satellite-lab-tools-2.0-1.el9.noarch.rpm

gcloud compute scp satellite-lab-tools-2.0-1.el9.noarch.rpm \
  sat-6-19-ga:~/ \
  --zone us-central1-a --project tmm-instruqt-11-26-2021
```

Install the RPM:

```bash
gcloud compute ssh --zone "us-central1-a" "sat-6-19-ga" \
  --project "tmm-instruqt-11-26-2021" \
  -- sudo dnf install -y ~/satellite-lab-tools-2.0-1.el9.noarch.rpm
```

Configure the hostname, then run the bootstrap:

```bash
gcloud compute ssh --zone "us-central1-a" "sat-6-19-ga" \
  --project "tmm-instruqt-11-26-2021" \
  -- "sudo sed -i 's/^HOSTNAME=.*/HOSTNAME=satellite.lab/' /etc/sysconfig/set-hostname && sudo systemctl enable --now set-hostname.service"

gcloud compute ssh --zone "us-central1-a" "sat-6-19-ga" \
  --project "tmm-instruqt-11-26-2021" \
  -- sudo /opt/satellite-lab-tools/bin/bootstrap-satellite.sh
```

The VM will configure repos, open firewall ports, update packages, and reboot. After reboot it is ready for Satellite installation.

---

## set-hostname

A systemd service that sets the system hostname and updates `/etc/hosts` on every boot.

### Configuration

Edit `/etc/sysconfig/set-hostname` with the desired hostname:

```
HOSTNAME=satellite.lab
```

Then enable the service:

```bash
sudo systemctl enable --now set-hostname.service
```

### What It Does

On each boot, the service:

1. Reads the desired hostname from `/etc/sysconfig/set-hostname`
2. Removes any GCP-added `/etc/hosts` entry that interferes with FQDN resolution
3. Compares `hostname -f` to the configured hostname
4. If they differ, runs `hostnamectl set-hostname` and updates `/etc/hosts`
5. If they match, exits without changes

The `/etc/hosts` update maps the machine's primary IP to the configured hostname. Existing entries (localhost, metadata, etc.) are preserved.

---

## bootstrap-satellite

A one-shot script that prepares a freshly installed RHEL 9 VM for Red Hat Satellite installation.

### Configuration

Edit `/etc/sysconfig/bootstrap-satellite` to adjust the Satellite version, repositories, or firewall rules:

```bash
SATELLITE_VERSION="6.19"

SATELLITE_REPOS=(
    "rhel-9-for-x86_64-baseos-rpms"
    "rhel-9-for-x86_64-appstream-rpms"
    "satellite-${SATELLITE_VERSION}-for-rhel-9-x86_64-rpms"
    "satellite-maintenance-${SATELLITE_VERSION}-for-rhel-9-x86_64-rpms"
)

FIREWALL_PORTS=(
    "8000/tcp"
    "9090/tcp"
)

FIREWALL_SERVICES=(
    "dns"
    "dhcp"
    "tftp"
    "http"
    "https"
    "puppetmaster"
)
```

### Usage

Run directly on the VM:

```bash
sudo /opt/satellite-lab-tools/bin/bootstrap-satellite.sh
```

Run without the final reboot:

```bash
sudo /opt/satellite-lab-tools/bin/bootstrap-satellite.sh --no-reboot
```

Run remotely via gcloud SSH:

```bash
gcloud compute ssh --zone "us-central1-a" "sat-6-19-ga" \
  --project "tmm-instruqt-11-26-2021" \
  -- sudo /opt/satellite-lab-tools/bin/bootstrap-satellite.sh
```

### What It Does

1. Disables all subscription-manager repositories
2. Enables the required RHEL 9 and Satellite repositories
3. Opens firewall ports (8000/tcp, 9090/tcp)
4. Opens firewall services (dns, dhcp, tftp, http, https, puppetmaster)
5. Persists firewall rules
6. Runs `dnf update` and `dnf upgrade`
7. Reboots the system (unless `--no-reboot` is passed)

---

## Installed Files

| File | Purpose |
|------|---------|
| `/opt/satellite-lab-tools/bin/set-hostname.sh` | Hostname script |
| `/opt/satellite-lab-tools/bin/bootstrap-satellite.sh` | Bootstrap script |
| `/etc/sysconfig/set-hostname` | Hostname configuration (preserved on upgrade) |
| `/etc/sysconfig/bootstrap-satellite` | Bootstrap configuration (preserved on upgrade) |
| `/etc/systemd/system/set-hostname.service` | Systemd unit |

## Uninstall

```bash
sudo dnf remove satellite-lab-tools
```

This disables the set-hostname service and removes all installed files. Configuration files at `/etc/sysconfig/` are preserved if they were modified.

---

## Building the RPM

Requires `rpm-build`:

```bash
sudo dnf install -y rpm-build
mkdir -p ~/rpmbuild/{SPECS,SOURCES,BUILD,RPMS,SRPMS}
```

Create the source tarball and build:

```bash
mkdir satellite-lab-tools-2.0
cp set-hostname/set-hostname.sh set-hostname/set-hostname.conf set-hostname/set-hostname.service satellite-lab-tools-2.0/
cp bootstrap-satellite/bootstrap-satellite.sh bootstrap-satellite/bootstrap-satellite.conf satellite-lab-tools-2.0/
tar czf ~/rpmbuild/SOURCES/satellite-lab-tools-2.0.tar.gz satellite-lab-tools-2.0
rm -rf satellite-lab-tools-2.0

cp packaging/satellite-lab-tools.spec ~/rpmbuild/SPECS/
rpmbuild -bb ~/rpmbuild/SPECS/satellite-lab-tools.spec
```

Output: `~/rpmbuild/RPMS/noarch/satellite-lab-tools-2.0-1.el9.noarch.rpm`
