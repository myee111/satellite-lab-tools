Name:           set-hostname
Version:        1.0
Release:        1%{?dist}
Summary:        Set system hostname from configuration file
License:        MIT
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Requires:       systemd
Requires:       bash

%description
A systemd service that sets the system hostname and updates /etc/hosts
from a configuration file at /etc/sysconfig/set-hostname on every boot.

%prep
%setup -q

%install
install -D -m 0755 set-hostname.sh %{buildroot}/usr/local/bin/set-hostname.sh
install -D -m 0644 set-hostname.conf %{buildroot}/etc/sysconfig/set-hostname
install -D -m 0644 set-hostname.service %{buildroot}/etc/systemd/system/set-hostname.service

%files
/usr/local/bin/set-hostname.sh
%config(noreplace) /etc/sysconfig/set-hostname
/etc/systemd/system/set-hostname.service

%post
systemctl daemon-reload

%preun
if [ $1 -eq 0 ]; then
    systemctl disable --now set-hostname.service 2>/dev/null || :
fi

%postun
systemctl daemon-reload
