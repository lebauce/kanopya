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
package Entity::Component::Webserver::Apache2;
use base "Entity::Component::Webserver";
use strict;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;



# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}



sub addVirtualhost {}

sub getVirtualhostConf{
	my $self = shift;

	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Component::Webserver::Apache2->getVirtualhostConf must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my $virtualhost_rs = $self->{_dbix}->apache2s->first->apache2_virtualhosts;
	my @tab_virtualhosts = ();
	while (my $virtualhost_row = $virtualhost_rs->next){
		my %virtualhost = $virtualhost_row->get_columns();
		push @tab_virtualhosts, \%virtualhost;
	}
	return \@tab_virtualhosts;
}

sub getGeneralConf{
	my $self = shift;

	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Component::Webserver::Apache2->getGeneralConf must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my %apache2_conf = $self->{_dbix}->apache2s->first->get_columns();
	$log->debug("Apache2 conf return is : " . Dumper(%apache2_conf));
	return \%apache2_conf;
}

# provide structured configuration data for component edition in ui

sub getConf {
	my $self = shift;
	my $apache2_conf = {
		apache2_id => undef,
		apache2_loglevel => undef,
		apache2_serverroot => undef,
		apache2_ports => undef,
		apache2_sslports => undef,
		apache2_phpsession_dir => undef,
		apache2_virtualhost => [
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
	if($lineindb) {
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
			$apache2_conf->{apache2_virtualhost}[$index]->{apache2_virtualhost_id} = $virtualhost{apache2_virtualhost_id};
			$apache2_conf->{apache2_virtualhost}[$index]->{apache2_virtualhost_servername} = $virtualhost{apache2_virtualhost_servername};
			$apache2_conf->{apache2_virtualhost}[$index]->{apache2_virtualhost_sslenable} = $virtualhost{apache2_virtualhost_sslenable};
			$apache2_conf->{apache2_virtualhost}[$index]->{apache2_virtualhost_serveradmin} = $virtualhost{apache2_virtualhost_serveradmin};
			$apache2_conf->{apache2_virtualhost}[$index]->{apache2_virtualhost_documentroot} = $virtualhost{apache2_virtualhost_documentroot};
			$apache2_conf->{apache2_virtualhost}[$index]->{apache2_virtualhost_log} = $virtualhost{apache2_virtualhost_log};
			$apache2_conf->{apache2_virtualhost}[$index]->{apache2_virtualhost_errorlog} = $virtualhost{apache2_virtualhost_errorlog};
			
			$index += 1;
		}
		
	}

	return $apache2_conf;
}



sub setConf {
	my $self = shift;
	my ($conf) = @_;
	if(not $conf->{apache2_id}) {
		# new configuration -> insert
		return 'insert conf'
	} else {
		# old configuration -> update
		return 'update conf';
	}	
	
	
}

1;
