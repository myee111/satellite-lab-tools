Name:           satellite-lab-tools
Version:        2.1
Release:        1%{?dist}
Summary:        Automation tools for Red Hat Satellite lab environments
License:        MIT
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Requires:       bash
Requires:       subscription-manager
Requires:       firewalld
Obsoletes:      bootstrap-satellite < 2.0
Provides:       bootstrap-satellite = %{version}-%{release}

%description
Automation tools for preparing RHEL 9 VMs as Red Hat Satellite lab
environments. Includes a one-shot bootstrap script for repository,
firewall, and package setup.

%prep
%setup -q

%install
install -D -m 0755 bootstrap-satellite.sh %{buildroot}/opt/satellite-lab-tools/bin/bootstrap-satellite.sh
install -D -m 0644 bootstrap-satellite.conf %{buildroot}/etc/sysconfig/bootstrap-satellite

%files
/opt/satellite-lab-tools/bin/bootstrap-satellite.sh
%config(noreplace) /etc/sysconfig/bootstrap-satellite
