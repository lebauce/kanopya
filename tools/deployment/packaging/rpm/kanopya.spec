Name:           kanopya
Version:        1.8	
Release:        1%{?dist}
Summary:        Kanopya is a Cloud Managment Platform

License:        GPLv2
URL:            http://www.kanopya.org
Source0:        kanopya-1.8.tar.gz
Source1:        deployment_solver.jar
BuildArch:      noarch

Requires:       kanopya-common kanopya-executor kanopya-front
Requires:       kanopya-monitor kanopya-state-manager
Requires:       kanopya-rules-engine kanopya-cli

Requires:       rsync wget

%description
Kanopya is a software developed by Hedera Technology for every company
looking for an easy to use and efficient private cloud manager.


%package cli
Summary: Kanopya command line
Group: Development/Tools
Requires: python-requests

%description cli
Kanopya command line


%package collector
Summary: Kanopya collector
Group: Development/Tools
Requires: kanopya-common

%description collector
Kanopya collector


%package common
Summary: Kanopya common files
Group: Development/Tools
Requires: MariaDB-client net-snmp-perl
Requires: perl-Test-Simple
Requires: perl-Net-OpenSSH
Requires: perl-Parse-BooleanLogic
Requires: perl-Statistics-Descriptive
Requires: perl-DBIx-Class-IntrospectableM2M
Requires: perl-DateTime-Format-HTTP
Requires: perl-DateTime-Set
Requires: perl-Net-SNMP
Requires: perl-Net-SSH-Perl
Requires: perl-Authen-SASL
Requires: perl-Hash-Merge
Requires: perl-AnyEvent
Requires: perl-Date-Simple
Requires: perl-DateTime-Set
Requires: perl-DateTime-Format-HTTP
Requires: perl-DateTime-Format-Strptime
Requires: perl-TryCatch
Requires: perl-Statistics-R
Requires: perl-Statistics-LineFit
Requires: perl-Sys-Hostname-FQDN
Requires: perl-AnyEvent-Subprocess
Requires: perl-IO-Compress
Requires: perl-Exception-Class
Requires: perl-NetAddr-IP
Requires: perl-Log-Log4perl
Requires: perl-RRDTool-OO
Requires: perl-Text-CSV
Requires: perl-String-Random
Requires: perl-DBD-MySQL
Requires: perl-Net-RabbitMQ
Requires: perl-XML-LibXML
Requires: perl-Net-SMTP-SSL
Requires: perl-LDAP
Requires: perl-Set-IntervalTree
Requires: perl-File-Pid
Requires: redhat-lsb-core

Provides: perl(VMware::VICommon)
Provides: perl(VMware::VILib)
Provides: perl(VMware::VIMRuntime)

%description common
Kanopya common files


%package executor
Summary: Kanopya executor
Group: Development/Tools
Requires: kanopya-common
Requires: uuid curl syslog-ng
Requires: nfs-utils ntp
Requires: iscsi-initiator-utils
Requires: bzip2 wol
Requires: java7
Requires: libguestfs-tools-c qemu-img qemu-kvm
Requires: nmap

%description executor
Kanopya executor


%package front
Summary: Kanopya Web frontend
Group: Development/Tools
Requires: kanopya-common
Requires: perl-Dancer
Requires: perl-Plack
Requires: perl-Starman
Requires: perl-Dancer-Plugin-EscapeHTML
Requires: perl-Dancer-Plugin-FormValidator
Requires: perl-Dancer-Plugin-REST

%description front
Kanopya Web frontend


%package monitor
Summary: Kanopya monitor
Group: Development/Tools
Requires: kanopya-common
Requires: net-snmp rrdtool

%description monitor
Kanopya monitor


%package state-manager
Summary: Kanopya state manager
Group: Development/Tools
Requires: kanopya-common

%description state-manager
Kanopya state manager


%package rules-engine
Summary: Kanopya rules engine
Group: Development/Tools
Requires: kanopya-common
Requires: R-devel

%description rules-engine
Kanopya rules engine


%prep
%setup -q


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/kanopya/lib

# Common
mkdir -p $RPM_BUILD_ROOT/opt/kanopya/conf
cp -R templates $RPM_BUILD_ROOT/opt/kanopya/
cp -R lib/administrator lib/common lib/external lib/component $RPM_BUILD_ROOT/opt/kanopya/lib

mkdir -p $RPM_BUILD_ROOT/opt/kanopya/scripts
cp -R scripts/database scripts/install scripts/R $RPM_BUILD_ROOT/opt/kanopya/scripts

mkdir -p $RPM_BUILD_ROOT/opt/kanopya/tools/deployment_solver
cp %{SOURCE1} $RPM_BUILD_ROOT/opt/kanopya/tools/deployment_solver

# Executor
cp -R lib/executor $RPM_BUILD_ROOT/opt/kanopya/lib

# Front
cp -R ui $RPM_BUILD_ROOT/opt/kanopya/

# Init scripts
mkdir -p $RPM_BUILD_ROOT/etc/init.d/
cp -R scripts/init/* $RPM_BUILD_ROOT/etc/init.d/

# Executables
mkdir -p $RPM_BUILD_ROOT/opt/kanopya/sbin
cp sbin/kanopya-{executor,aggregator,collector,rulesengine,state-manager} $RPM_BUILD_ROOT/opt/kanopya/sbin

# Monitor
cp -R lib/monitor $RPM_BUILD_ROOT/opt/kanopya/lib

# Rules engine
cp -R lib/orchestrator $RPM_BUILD_ROOT/opt/kanopya/lib

# Remove useless scripts that break the dependency checking
rm -rf $RPM_BUILD_ROOT/opt/kanopya/lib/common/MessageQueuing/RabbitFoot*
rm -rf $RPM_BUILD_ROOT/opt/kanopya/lib/common/MessageQueuing/Qpid*
rm $RPM_BUILD_ROOT/opt/kanopya/lib/common/Kanopya/EventLogAppender.pm
rm $RPM_BUILD_ROOT/opt/kanopya/lib/common/Kanopya/Tools/KioExport.pm

%files
%doc LICENCE README

%files cli
/opt/kanopya/ui/CmdLine

%files common
%dir /opt/kanopya/conf
/opt/kanopya/lib/administrator
/opt/kanopya/lib/common
/opt/kanopya/lib/component
/opt/kanopya/lib/external
/opt/kanopya/scripts
/opt/kanopya/templates
/opt/kanopya/tools/deployment_solver/deployment_solver.jar

%files executor
/etc/init.d/kanopya-executor
/opt/kanopya/lib/executor
/opt/kanopya/sbin/kanopya-executor

%files front
/etc/init.d/kanopya-front
/opt/kanopya/ui/Frontend

%files monitor
/etc/init.d/kanopya-collector
/etc/init.d/kanopya-aggregator
/opt/kanopya/sbin/kanopya-aggregator
/opt/kanopya/sbin/kanopya-collector
/opt/kanopya/lib/monitor

%files state-manager
/etc/init.d/kanopya-state-manager
/opt/kanopya/sbin/kanopya-state-manager

%files rules-engine
/etc/init.d/kanopya-rulesengine
/opt/kanopya/lib/orchestrator
/opt/kanopya/sbin/kanopya-rulesengine


%changelog
* Mon Sep 23 2013 Sylvain Baubeau <sylvain.baubeau@hederatech.com> - 1.8-1
- Initial release
