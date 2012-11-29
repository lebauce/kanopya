# Syslogng3.pm - Syslog-ng component
#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 4 sept 2010

=head1 NAME

<Entity::Component::Syslogng3> <Syslogng component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Syslogng3> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Syslogng3>;

my $component_instance_id = 2; # component instance id

Entity::Component::Syslogng3->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Syslogng3->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Syslogng3 is class allowing to instantiate a Syslogng component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Syslogng3;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Config;
use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getConf {
    my $self = shift;

    my $conf = {};

    my @logs = ();
    my @entries = ();
    my $confindb = $self->{_dbix};
    if($confindb) {
        # Get entries
           my $entry_rs = $confindb->syslogng3_entries;
           while (my $entry_row = $entry_rs->next){
               my $param_rs = $entry_row->syslogng3_entry_params;
            my @params = ();
            while (my $param_row = $param_rs->next) {
                push @params, {
                                'content' => $param_row->get_column('syslogng3_entry_param_content') } ;
            }
            push @entries, { 
                                type => $entry_row->get_column('syslogng3_entry_type'),
                                name => $entry_row->get_column('syslogng3_entry_name'),
                                params => \@params };
           }
        
           # Get logs
           my $log_rs = $confindb->syslogng3_logs;
           while (my $log_row = $log_rs->next){
               my $log_param_rs = $log_row->syslogng3_log_params;
               my @log_params = ();
               while (my $log_param_row = $log_param_rs->next){
                push @log_params, { 
                                    type => $log_param_row->get_column('syslogng3_log_param_entrytype'),
                                    name => $log_param_row->get_column('syslogng3_log_param_entryname') };
               
               }
               push @logs, { params => \@log_params };
       }
    
    }

    $conf->{entries} = \@entries;
    $conf->{logs} = \@logs;
    return $conf;
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    # delete old conf
    my $conf = $args{conf};
    my $conf_row = $self->{_dbix};
    $conf_row->syslogng3_entries->delete_all;
    $conf_row->syslogng3_logs->delete_all;
    
    # Store entries
    foreach my $entry (@{ $conf->{entries} }) {
        my $entry_row = $conf_row->syslogng3_entries->create( { syslogng3_entry_name => $entry->{name},
                                                                syslogng3_entry_type => $entry->{type} } );
            foreach my $param (@{ $entry->{params} }) {
                $entry_row->syslogng3_entry_params->create( { syslogng3_entry_param_content => $param->{content} } );
            }    
    } 
    
    # Store logs
    foreach my $log ( @{ $conf->{logs} }) {
        my $log_row = $conf_row->syslogng3_logs->create( {} );
        foreach my $param (@{ $log->{log_params} }) {
            $log_row->syslogng3_log_params->create( { syslogng3_log_param_entrytype => $param->{type},
                                                      syslogng3_log_param_entryname => $param->{name} });
        }
    }
    
}

sub getNetConf {
    # TODO return depending on conf
    #return { 514 => ['udp'] };
}

=head2 insertDefaultConfiguration
	
	Class : Public
	
	Desc : The default syslog-ng configuration for a node is to send all logs to kanopya admin 
	
	
=cut

sub insertDefaultExtendedConfiguration {
    my $self = shift;
    my %args = @_;
    
    # Retrieve admin ip
    my $config = Kanopya::Config::get('executor');
    my $kanopya_cluster = Entity->get(id => $config->{cluster}->{executor});
    my $admin_ip = $kanopya_cluster->getMasterNodeIp();

    # Conf to send all node logs to admin
    $self->{_dbix}->syslogng3_logs->populate([ 
		{ syslogng3_log_params => [
                { syslogng3_log_param_entrytype => "source",
                  syslogng3_log_param_entryname => "s_all_local"
                },
                { syslogng3_log_param_entrytype => "destination",
                  syslogng3_log_param_entryname => "d_kanopya_admin"
                },
            ],
        }
     ]);
     
     $self->{_dbix}->syslogng3_entries->populate([  
		{ syslogng3_entry_name => 's_all_local',
		  syslogng3_entry_type => 'source',
		  syslogng3_entry_params => [
				{ syslogng3_entry_param_content => 'internal()' },
				{ syslogng3_entry_param_content => 'unix-stream("/dev/log")' },
				
				# Kernel logs: this conf doesn't work for current version of syslog-ng
				#{ syslogng3_entry_param_content => 'file("/proc/kmsg" program_override("kernel"))' },
			]
		},
		{
			syslogng3_entry_name => 'd_kanopya_admin',
			syslogng3_entry_type => 'destination',
			syslogng3_entry_params => [{
				  syslogng3_entry_param_content => "udp('$admin_ip')",
			}]
		},
	]);
}


sub getKanopyaAdmLogDirectories {
    my $self = shift;
    
    #TODO retrieve log dirs from conf (= param of driver file in destination used)
    return ("/var/log/kanopya/"     # default log dir for kanopya services
           );
}

sub getKanopyaNodesLogDirectories {
    my $self = shift;

    return ("/var/log/kanopya_nodes/");
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

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
