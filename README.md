# satellite-lab-tools

Automation tools for Red Hat Satellite lab environments.

## set-hostname

A systemd service that sets the system hostname and updates `/etc/hosts` on every boot.

### Quick Install

```bash
curl -LO https://github.com/myee111/satellite-lab-tools/releases/download/v1.0/set-hostname-1.0-1.el9.noarch.rpm
sudo dnf install -y ./set-hostname-1.0-1.el9.noarch.rpm
```

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
2. Compares it to the current hostname
3. If they differ, runs `hostnamectl set-hostname` and updates `/etc/hosts`
4. If they match, exits without changes

The `/etc/hosts` update removes any GCP-added hostname entry and maps the machine's primary IP to the configured hostname. Existing entries (localhost, metadata, etc.) are preserved.

### Installed Files

| File | Purpose |
|------|---------|
| `/usr/local/bin/set-hostname.sh` | Main script |
| `/etc/sysconfig/set-hostname` | Hostname configuration (preserved on upgrade) |
| `/etc/systemd/system/set-hostname.service` | Systemd unit |

### Uninstall

```bash
sudo dnf remove set-hostname
```

This disables the service and removes all installed files. The hostname configuration at `/etc/sysconfig/set-hostname` is preserved if it was modified.

### Building the RPM

Requires `rpm-build`:

```bash
sudo dnf install -y rpm-build
mkdir -p ~/rpmbuild/{SPECS,SOURCES,BUILD,RPMS,SRPMS}

# Create source tarball
mkdir set-hostname-1.0
cp set-hostname.sh set-hostname.conf set-hostname.service set-hostname-1.0/
tar czf ~/rpmbuild/SOURCES/set-hostname-1.0.tar.gz set-hostname-1.0
rm -rf set-hostname-1.0

# Build
cp set-hostname.spec ~/rpmbuild/SPECS/
rpmbuild -bb ~/rpmbuild/SPECS/set-hostname.spec
```

The RPM will be at `~/rpmbuild/RPMS/noarch/set-hostname-1.0-1.el9.noarch.rpm`.

### Requirements

- RHEL 9 (or compatible)
- systemd
- bash
