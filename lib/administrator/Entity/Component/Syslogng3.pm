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
    if ($confindb) {
        # Get entries
        my $entry_rs = $confindb->syslogng3_entries;
        while (my $entry_row = $entry_rs->next) {
            my $param_rs = $entry_row->syslogng3_entry_params;
            my @params = ();
            while (my $param_row = $param_rs->next) {
                push @params, { content => $param_row->get_column('syslogng3_entry_param_content') };
            }
            push @entries, { type => $entry_row->get_column('syslogng3_entry_type'),
                             name => $entry_row->get_column('syslogng3_entry_name'),
                             params => \@params };
        }
        
        # Get logs
        my $log_rs = $confindb->syslogng3_logs;
        while (my $log_row = $log_rs->next) {
            my $log_param_rs = $log_row->syslogng3_log_params;
            my @log_params = ();
            while (my $log_param_row = $log_param_rs->next) {
                 push @log_params, {
                     type => $log_param_row->get_column('syslogng3_log_param_entrytype'),
                     name => $log_param_row->get_column('syslogng3_log_param_entryname')
                 };
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


sub insertDefaultExtendedConfiguration {
    my $self = shift;
    my %args = @_;

    # Retrieve admin ip
    my $kanopya = $self->service_provider->getKanopyaCluster();
    my $syslog  = $kanopya->getComponent(name => "Syslogng", version => "3");

    # If no kanopya syslogng nodes found, this component has just
    # been installed on the kanopya cluster, the configuration
    # will be updated at the fisrt node of the kanopya cluster registration.
    my @nodes = $syslog->component_nodes;
    if (scalar @nodes) {
        my $fqdn = $syslog->getMasterNode->fqdn();

        # Conf to send all node logs to admin
        $self->{_dbix}->syslogng3_logs->populate([
            { syslogng3_log_params => [
                { syslogng3_log_param_entrytype => "source",
                  syslogng3_log_param_entryname => "s_all_local" },
                { syslogng3_log_param_entrytype => "destination",
                  syslogng3_log_param_entryname => "d_kanopya_admin" },
            ]}
        ]);

        $self->{_dbix}->syslogng3_entries->populate([
            { syslogng3_entry_name   => 's_all_local',
              syslogng3_entry_type   => 'source',
              syslogng3_entry_params => [
                  { syslogng3_entry_param_content => 'internal()' },
                  { syslogng3_entry_param_content => 'unix-stream("/dev/log")' },
                  # Kernel logs: this conf doesn't work for current version of syslog-ng
                  #{ syslogng3_entry_param_content => 'file("/proc/kmsg" program_override("kernel"))' },
              ]},
            { syslogng3_entry_name   => 'd_kanopya_admin',
              syslogng3_entry_type   => 'destination',
              syslogng3_entry_params => [
                  { syslogng3_entry_param_content => "udp('$fqdn')" }
              ]},
        ]);
    }
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

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return "class { 'kanopya::syslogng': }\n";
}

1;
