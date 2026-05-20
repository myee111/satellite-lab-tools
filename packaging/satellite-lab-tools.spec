Name:           satellite-lab-tools
Version:        2.1
Release:        1%{?dist}
Summary:        Automation tools for Red Hat Satellite lab environments
License:        MIT
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Requires:       bash
Requires:       systemd
Requires:       subscription-manager
Requires:       firewalld
Obsoletes:      set-hostname < 2.0
Obsoletes:      bootstrap-satellite < 2.0
Provides:       set-hostname = %{version}-%{release}
Provides:       bootstrap-satellite = %{version}-%{release}

%description
Automation tools for preparing RHEL 9 VMs as Red Hat Satellite lab
environments. Includes a systemd service for persistent hostname
configuration and a one-shot bootstrap script for repository, firewall,
and package setup.

%prep
%setup -q

%install
install -D -m 0755 set-hostname.sh %{buildroot}/opt/satellite-lab-tools/bin/set-hostname.sh
install -D -m 0755 bootstrap-satellite.sh %{buildroot}/opt/satellite-lab-tools/bin/bootstrap-satellite.sh
install -D -m 0644 set-hostname.conf %{buildroot}/etc/sysconfig/set-hostname
install -D -m 0644 bootstrap-satellite.conf %{buildroot}/etc/sysconfig/bootstrap-satellite
install -D -m 0644 set-hostname.service %{buildroot}/etc/systemd/system/set-hostname.service

%files
/opt/satellite-lab-tools/bin/set-hostname.sh
/opt/satellite-lab-tools/bin/bootstrap-satellite.sh
%config(noreplace) /etc/sysconfig/set-hostname
%config(noreplace) /etc/sysconfig/bootstrap-satellite
/etc/systemd/system/set-hostname.service

%post
systemctl daemon-reload

%preun
if [ $1 -eq 0 ]; then
    systemctl disable --now set-hostname.service 2>/dev/null || :
fi

%postun
systemctl daemon-reload
