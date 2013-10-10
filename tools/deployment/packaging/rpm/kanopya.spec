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
Requires:       kanopya-monitor kanopya-state-manager kanopya-rules-engine

%description
Kanopya is a software developed by Hedera Technology for every company
looking for an easy to use and efficient private cloud manager.


%package collector
Summary: Kanopya collector
Group: Development/Tools

%description collector
Kanopya collector


%package common
Summary: Kanopya common files
Group: Development/Tools

Provides: perl(VMware::VICommon)
Provides: perl(VMware::VILib)
Provides: perl(VMware::VIMRuntime)

%description common
Kanopya common files


%package executor
Summary: Kanopya executor
Group: Development/Tools

%description executor
Kanopya executor


%package front
Summary: Kanopya Web frontend
Group: Development/Tools

%description front
Kanopya Web frontend


%package monitor
Summary: Kanopya monitor
Group: Development/Tools

%description monitor
Kanopya monitor


%package state-manager
Summary: Kanopya state manager
Group: Development/Tools

%description state-manager
Kanopya state manager


%package rules-engine
Summary: Kanopya rules engine
Group: Development/Tools

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

%files front
/etc/init.d/kanopya-front
/opt/kanopya/ui

%files monitor
/etc/init.d/kanopya-collector
/etc/init.d/kanopya-aggregator
/opt/kanopya/lib/monitor

%files state-manager
/etc/init.d/kanopya-state-manager

%files rules-engine
/etc/init.d/kanopya-rulesengine
/opt/kanopya/lib/orchestrator


%changelog
* Mon Sep 23 2013 Sylvain Baubeau <sylvain.baubeau@hederatech.com> - 1.8-1
- Initial release

