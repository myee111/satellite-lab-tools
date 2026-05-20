Name:           bootstrap-satellite
Version:        1.1
Release:        1%{?dist}
Summary:        Prepare RHEL 9 for Red Hat Satellite installation
License:        MIT
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Requires:       bash
Requires:       set-hostname
Requires:       subscription-manager
Requires:       firewalld

%description
A one-shot script that prepares a freshly installed RHEL 9 VM for
Red Hat Satellite installation. It installs the set-hostname tool,
configures subscription-manager repositories, opens required firewall
ports, and updates the system.

%prep
%setup -q

%install
install -D -m 0755 bootstrap-satellite.sh %{buildroot}/opt/satellite-lab-tools/bin/bootstrap-satellite.sh
install -D -m 0644 bootstrap-satellite.conf %{buildroot}/etc/sysconfig/bootstrap-satellite

%files
/opt/satellite-lab-tools/bin/bootstrap-satellite.sh
%config(noreplace) /etc/sysconfig/bootstrap-satellite
