# Apache2.pm Apache 2 web server component (Adminstrator side)
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 24 july 2010
=head1 NAME

<Entity::Component::WebServer::Apache2> <Apache 2 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::WebServer::Apache2> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::WebServer::Apache2>;

my $component_instance_id = 2; # component instance id

Entity::Component::WebServer::Apache2->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::WebServer::Apache2->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::WebServer::Apache2 is class allowing to instantiate an apache2 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Webserver::Apache2;
use base "Entity::Component::Webserver";

use strict;
use warnings;

use Kanopya::Exceptions;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

=head2 get
B<Class>   : Public
B<Desc>    : This method allows to get an existing apache2 component.
B<args>    : 
    B<component_instance_id> : I<Int> : identify component instance 
B<Return>  : a new Entity::Component::Webserver::Apache2 from Kanopya Database
B<Comment>  : To modify configuration use concrete class dedicated method
B<throws>  : 
    B<Mcs::Exception::Internal::IncorrectParam> When missing mandatory parameters
	
=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Component::Webserver::Apache2->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args);
   return $self;
}

=head2 new
B<Class>   : Public
B<Desc>    : This method allows to create a new instance of Webserver component.
          This is an abstract class, DO NOT instantiate it.
B<args>    : 
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component::Webserver::Apache2 from parameters.
B<Comment>  : Like all component, instantiate it creates a new empty component instance.
        You have to populate it with dedicated methods.
B<throws>  : 
    B<Mcs::Exception::Internal::IncorrectParam> When missing mandatory parameters
	
=cut

sub new {
	my $class = shift;
    my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id})||
		(! exists $args{component_id} or ! defined $args{component_id})){ 
		$errmsg = "Entity::Component::Webserver::Apache2->new need a cluster_id and a component_id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# We create a new DBIx containing new entity
	my $self = $class->SUPER::new( %args);

    return $self;

}

=head2 addVirtualhost
B<Class>   : Public
B<Desc>    : This method allows to add a new virtualhost to component instance configuration.
B<args>    : 
    B<apache2_virtualhost_servername> : I<String> : Virtualhost server name
    B<apache2_virtualhost_sslenable> : I<int> : 1 activat SSL, 0 disable it.
    B<apache2_virtualhost_serveradmin> : I<String> : Virtualhost admin email.
    B<apache2_virtualhost_documentroot> : I<String> : directory hosting virtualhost root document.
    B<apache2_virtualhost_log> : I<String> : file path for access log.
    B<apache2_virtualhost_errorlog> : I<String> : file path for error log.
    
B<Return>  : None
B<Comment>  : None
B<throws>  : 
    B<Mcs::Exception::Internal::IncorrectParam> When missing mandatory parameters
	
=cut

sub addVirtualhost {
    #TODO AddVirtualhost
}

=head2 getVirtualhost
B<Class>   : Public
B<Desc>    : This method allows to get a existing virtualhosts.
B<args>    : None
B<Return>  : hash ref table containing all virtualhost, hash ref are composed by :
    B<apache2_virtualhost_servername> : I<String> : Virtualhost server name
    B<apache2_virtualhost_sslenable> : I<int> : 1 activat SSL, 0 disable it.
    B<apache2_virtualhost_serveradmin> : I<String> : Virtualhost admin email.
    B<apache2_virtualhost_documentroot> : I<String> : directory hosting virtualhost root document.
    B<apache2_virtualhost_log> : I<String> : file path for access log.
    B<apache2_virtualhost_errorlog> : I<String> : file path for error log.
B<Comment>  : None
B<throws>  : 
    B<Kanopya::Exception> When apache2 component instance is not already saved in db
	
=cut

sub getVirtualhostConf{
	my $self = shift;

	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Component::Webserver::Apache2->getVirtualhostConf must be called on an already save instance";
		$log->error($errmsg);
		throw Kanopya::Exception(error => $errmsg);
	}
	my $virtualhost_rs = $self->{_dbix}->apache2s->first->apache2_virtualhosts;
	my @tab_virtualhosts = ();
	while (my $virtualhost_row = $virtualhost_rs->next){
		my %virtualhost = $virtualhost_row->get_columns();
		push @tab_virtualhosts, \%virtualhost;
	}
	return \@tab_virtualhosts;
}

=head2 getGeneralConf
B<Class>   : Public
B<Desc>    : This method allows to get a apache2 general conf.
B<args>    : None
B<Return>  : hash ref containing apache 2 general conf, hash is composed by :
    B<apache2_loglevel> : I<String> : Apache 2 general log level 
        (debug, info, notice, warn, error, crit,  alert, emerg)
    B<apache2_serverroot> : I<String> : directory hosting apache2 root document.
    B<apache2_ports> : I<int> : Apache 2 port HTTP number
    B<apache2_phpsession_dir> : I<String> : directory containing php sessions.
    B<apache2_sslports> : I<Int> : fApache 2 port SSL number.
B<Comment>  : None
B<throws>  : 
    B<Kanopya::Exception> When apache2 component instance is not already saved in db
	
=cut

sub getGeneralConf{
	my $self = shift;

	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Component::Webserver::Apache2->getGeneralConf must be called on an already save instance";
		$log->error($errmsg);
		throw Kanopya::Exception(error => $errmsg);
	}
	my %apache2_conf = $self->{_dbix}->apache2s->first->get_columns();
	$log->debug("Apache2 conf return is : " . Dumper(%apache2_conf));
	return \%apache2_conf;
}

=head2 getConf
B<Class>   : Public
B<Desc>    : This method allows to get a structured image of apache2 configuration.
B<args>    : None
B<Return>  : hash ref containing apache 2 global conf, hash is composed by :
    B<apache2_loglevel> : I<String> : Apache 2 general log level 
        (debug, info, notice, warn, error, crit,  alert, emerg)
    B<apache2_serverroot> : I<String> : directory hosting apache2 root document.
    B<apache2_ports> : I<int> : Apache 2 port HTTP number
    B<apache2_phpsession_dir> : I<String> : directory containing php sessions.
    B<apache2_sslports> : I<Int> : Apache 2 port SSL number.
    B<apache2_virtualhosts> : I<Table of hash ref> : Containing virtualhost, composed by :
        B<apache2_virtualhost_servername> : I<String> : Virtualhost server name
        B<apache2_virtualhost_sslenable> : I<int> : 1 activat SSL, 0 disable it.
        B<apache2_virtualhost_serveradmin> : I<String> : Virtualhost admin email.
        B<apache2_virtualhost_documentroot> : I<String> : directory hosting virtualhost root document.
        B<apache2_virtualhost_log> : I<String> : file path for access log.
        B<apache2_virtualhost_errorlog> : I<String> : file path for error log.
B<Comment>  : None
B<throws>  : None
	
=cut
sub getConf {
	my $self = shift;
	my $apache2_conf = {
		apache2_id => undef,
		apache2_loglevel => undef,
		apache2_serverroot => undef,
		apache2_ports => undef,
		apache2_sslports => undef,
		apache2_phpsession_dir => undef,
		apache2_virtualhosts => [
			{ apache2_virtualhost_id => undef,
			  apache2_virtualhost_servername => undef,
			  apache2_virtualhost_sslenable => undef,
			  apache2_virtualhost_serveradmin => undef,
			  apache2_virtualhost_documentroot => undef,
			  apache2_virtualhost_log => undef,
			  apache2_virtualhost_errorlog => undef,
			},
		]
	};
	
	my $lineindb = $self->{_dbix}->apache2s->first;
	if(defined $lineindb) {
		my %dbconf = $lineindb->get_columns();
		$apache2_conf->{apache2_id} = $dbconf{apache2_id};
		$apache2_conf->{apache2_serverroot} = $dbconf{apache2_serverroot};
		$apache2_conf->{apache2_loglevel} = $dbconf{apache2_loglevel};
		$apache2_conf->{apache2_ports} = $dbconf{apache2_ports};
		$apache2_conf->{apache2_sslports} = $dbconf{apache2_sslports};
		$apache2_conf->{apache2_phpsession_dir} = $dbconf{apache2_phpsession_dir};
		
		my $virtualhost_rs = $lineindb->apache2_virtualhosts;
		my $index = 0;
		while (my $virtualhost_row = $virtualhost_rs->next){
			my %virtualhost = $virtualhost_row->get_columns();
			$apache2_conf->{apache2_virtualhosts}[$index]->{apache2_virtualhost_id} = $virtualhost{apache2_virtualhost_id};
			$apache2_conf->{apache2_virtualhosts}[$index]->{apache2_virtualhost_servername} = $virtualhost{apache2_virtualhost_servername};
			$apache2_conf->{apache2_virtualhosts}[$index]->{apache2_virtualhost_sslenable} = $virtualhost{apache2_virtualhost_sslenable};
			$apache2_conf->{apache2_virtualhosts}[$index]->{apache2_virtualhost_serveradmin} = $virtualhost{apache2_virtualhost_serveradmin};
			$apache2_conf->{apache2_virtualhosts}[$index]->{apache2_virtualhost_documentroot} = $virtualhost{apache2_virtualhost_documentroot};
			$apache2_conf->{apache2_virtualhosts}[$index]->{apache2_virtualhost_log} = $virtualhost{apache2_virtualhost_log};
			$apache2_conf->{apache2_virtualhosts}[$index]->{apache2_virtualhost_errorlog} = $virtualhost{apache2_virtualhost_errorlog};
			
			$index += 1;
		}
		$log->debug("APACHE2 configuration exists in db: ".Dumper $apache2_conf);
		
	}

	return $apache2_conf;
}

=head2 setConf
B<Class>   : Public
B<Desc>    : This method allows to set a complete apache2 configuration from structured image.
B<args>    : hash ref containing apache 2 global conf, hash is composed by :
    B<apache2_loglevel> : I<String> : Apache 2 general log level 
        (debug, info, notice, warn, error, crit,  alert, emerg)
    B<apache2_serverroot> : I<String> : directory hosting apache2 root document.
    B<apache2_ports> : I<int> : Apache 2 port HTTP number
    B<apache2_phpsession_dir> : I<String> : directory containing php sessions.
    B<apache2_sslports> : I<Int> : Apache 2 port SSL number.
    B<apache2_virtualhosts> : I<Table of hash ref> : Containing virtualhost, composed by :
        B<apache2_virtualhost_servername> : I<String> : Virtualhost server name
        B<apache2_virtualhost_sslenable> : I<int> : 1 activat SSL, 0 disable it.
        B<apache2_virtualhost_serveradmin> : I<String> : Virtualhost admin email.
        B<apache2_virtualhost_documentroot> : I<String> : directory hosting virtualhost root document.
        B<apache2_virtualhost_log> : I<String> : file path for access log.
        B<apache2_virtualhost_errorlog> : I<String> : file path for error log.
B<Return>  : None
B<Comment>  : None
B<throws>  : None

=cut

sub setConf {
	my $self = shift;
	my ($conf) = @_;
	
	$log->debug("APACHE2 configuration to save in db: ".Dumper $conf);
	my $virtualhosts = $conf->{apache2_virtualhosts};
	delete $conf->{apache2_virtualhosts};
	
	if(not $conf->{apache2_id}) {
		# new configuration -> create	
		my $row = $self->{_dbix}->apache2s->create($conf);
		$self->{_dbix}->apache2s->clear_cache();
		foreach my $vh (@$virtualhosts) {
			$vh->{apache2_virtualhost_id} = undef;
			$self->{_dbix}->apache2s->first()->apache2_virtualhosts->create($vh);
		}
		
	} else {
		# old configuration -> update
		 $self->{_dbix}->apache2s->update($conf);
		 my $virtualhosts_indb = $self->{_dbix}->apache2s->first()->apache2_virtualhosts;
		 while(my $vhost_indb = $virtualhosts_indb->next) {
		 	my $found = 0;
		 	my $vhost_data;
		 	foreach	my $vhost_to_update (@$virtualhosts) {
		 		if($vhost_to_update->{apache2_virtualhost_id} == $vhost_indb->get_column('apache2_virtualhost_id')) {
		 			$found = 1;
		 			$vhost_data = $vhost_to_update;
		 			last;
		 		}
		 	}
		 	if($found) {
		 		$vhost_indb->update($vhost_data);
		 	} else {
		 		$vhost_indb->delete();
		 	}
		 }
		
	}	
}

sub getNetConf{
    return {80=>'tcp'};
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

Exceptions are thrown when apache2 component instance is not already saved in db
Exception : Kanopya::Exception 

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
