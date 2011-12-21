#!/usr/bin/perl -w

use strict;
use warnings;
use XML::Simple;

use Kanopya::Exceptions;
use Executor;
use Administrator;
use Entity::Systemimage;
use Entity::Distribution;
use Entity::Cluster;
use Entity::Component::Lvm2;
use General;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/test.log', layout=>'%F %L %p %m%n'});

my $conf = XMLin("/opt/kanopya/conf/executor.conf");
General::checkParams(args=>$conf->{user}, required=>["name","password"]);

########################## Here insert information on distribution inserted ##############
my $dist_conf = {dist_name      => "debian",
	       dist_version   => 6,
	       dist_desc      => "SI d openNebula",
	       root_size      => "2G",
	       filesystem     => "ext3"};

my $adm = Administrator::authenticate(login => $conf->{user}->{name},
				      password => $conf->{user}->{password});


my $nas = Entity::Cluster->get(id => $conf->{cluster}->{nas});
my $lvm2 = $nas->getComponent(name=>"Lvm", version=>"2");
my $vg_id = $lvm2->getMainVg()->{vgid};

# insert root disk on lvm
my $root_id = $lvm2->lvCreate(lvm2_lv_name       => "root_" . $dist_conf->{dist_name} .
			                            "_" . $dist_conf->{dist_version},
			      lvm2_lv_size       => $dist_conf->{root_size},
			      lvm2_lv_filesystem => $dist_conf->{filesystem},
			      lvm2_vg_id         => $vg_id);

# insert etc disk on lvm
my $etc_id = $lvm2->lvCreate(lvm2_lv_name       => "etc_" . $dist_conf->{dist_name}.
			                           "_" . $dist_conf->{dist_version},
			     lvm2_lv_size       => "52M",
			     lvm2_lv_filesystem => $dist_conf->{filesystem},
			     lvm2_vg_id         => $vg_id);


my $distribution = Entity::Distribution->new(distribution_name      => $dist_conf->{dist_name},
					    distribution_desc      => $dist_conf->{dist_desc},
					    distribution_version => $dist_conf->{dist_version},
					    etc_device_id         => $etc_id,
					    root_device_id        => $root_id);
$distribution->save();
$distribution->updateProvidedComponents();
