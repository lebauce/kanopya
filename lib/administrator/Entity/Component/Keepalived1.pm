# Keepalived1.pm -Keepalive (load balancer) component (Adminstrator side)
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
# Created 22 august 2010
=head1 NAME

<Entity::Component::Keepalived1> <Keepalived component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Keepalived1> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Keepalived1>;

my $component_instance_id = 2; # component instance id

Entity::Component::Keepalived1->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Keepalived1->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Keepalived1 is class allowing to instantiate an Keepalived component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut
package Entity::Component::Keepalived1;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    notification_email_from => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    notification_email      => {
    
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    daemon_method           => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    smtp_connect_timeout    => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    smtp_server             => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    lvs_id                  => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    },
    iface                   => {
        pattern         => '^.*$',
        is_mandatory    => 0,
        is_extended     => 0,
        is_editable     => 0
    }
};
sub getAttrDef { return ATTR_DEF; }

=head2 getVirtualservers
    
    Desc : return virtualservers list .
        
    return : array ref containing hasf ref virtualservers 

=cut

sub getVirtualservers {
    my $self = shift;
        
    my $virtualserver_rs = $self->{_dbix}->keepalived1_virtualservers->search();
    my $result = [];
    while(my $vs = $virtualserver_rs->next) {
        my $hashvs = {};
        $hashvs->{virtualserver_id} = $vs->get_column('virtualserver_id');
        $hashvs->{virtualserver_ip} = $vs->get_column('virtualserver_ip');
        $hashvs->{virtualserver_port} = $vs->get_column('virtualserver_port');
        $hashvs->{virtualserver_lbalgo} = $vs->get_column('virtualserver_lbalgo');
        $hashvs->{virtualserver_lbkind} = $vs->get_column('virtualserver_lbkind');
        push @$result, $hashvs;
    }
    $log->debug("returning ".scalar @$result." virtualservers");
    return $result;
}

=head2 getRealserverId  

    Desc : This method return realserver id given a virtualserver_id and a realserver_ip
    args: virtualserver_id, realserver_ip
        
    return : realserver_id

=cut

sub getRealserverId {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['realserver_ip',
                                                      'virtualserver_id']);
    
    my $virtualserver = $self->{_dbix}->keepalived1_virtualservers->find($args{virtualserver_id});
    $log->debug("Virtualserver found with id <$args{virtualserver_id}>");
    my $realserver = $virtualserver->keepalived1_realservers->search({ realserver_ip => $args{realserver_ip} })->single;
    $log->debug("Realserver found with ip <$args{realserver_ip}>");
    $log->debug("Returning realserver_id <".$realserver->get_column('realserver_id').">");
    return $realserver->get_column('realserver_id');
}

=head2 addVirtualserver
    
    Desc : This method add a new virtual server entry into keepalived configuration.
    args: virtualserver_ip, virtualserver_port, virtualserver_lbkind, virtualserver_lbalgo
        
    return : virtualserver_id added

=cut

sub addVirtualserver {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['virtualserver_ip',
                                                      'virtualserver_port',
                                                      'virtualserver_lbkind',
                                                      'virtualserver_lbalgo']);
    
    my $virtualserver_rs = $self->{_dbix}->keepalived1_virtualservers;
    my $row = $virtualserver_rs->create(\%args);
    $log->info("New virtualserver added with ip $args{virtualserver_ip} and port $args{virtualserver_port}");
    return $row->get_column("virtualserver_id");
}

=head2 addRealserver
    
    Desc : This function add a new real server associated a virtualserver.
    args: virtualserver_id, realserver_ip, realserver_port,realserver_checkport , 
        realserver_checktimeout, realserver_weight 
    
    return :  realserver_id

=cut

sub addRealserver {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['virtualserver_id',
                                                      'realserver_ip',
                                                      'realserver_port',
                                                      'realserver_checkport',
                                                      'realserver_checktimeout',
                                                      'realserver_weight']);
    
    $log->debug("New real server try to be added on virtualserver_id <$args{virtualserver_id}>");
    my $realserver_rs = $self->{_dbix}->keepalived1_virtualservers->find($args{virtualserver_id})->keepalived1_realservers;

    my $row = $realserver_rs->create(\%args);
    $log->info("New real server <$args{realserver_ip}> <$args{realserver_port}> added");
    return $row->get_column('realserver_id');
}

=head2 removeVirtualserver
    
    Desc : This function a delete virtual server and all real servers associated.
    args: virtualserver_id
        
    return : ?

=cut

sub removeVirtualserver {
    my $self = shift;
    my %args  = @_;
    
    General::checkParams(args => \%args, required => ['virtualserver_id']);
    
    $log->debug("Trying to delete virtualserver with id <$args{virtualserver_id}>");
    return $self->{_dbix}->keepalived1_virtualservers->find($args{virtualserver_id})->delete;
}

=head2 removeRealserver
    
    Desc : This function remove a real server from a virtualserver.
    args: virtualserver_id, realserver_id
        
    return : 

=cut

sub removeRealserver {
    my $self = shift;
    my %args  = @_;
    
    General::checkParams(args => \%args, required => ['virtualserver_id',
                                                      'realserver_id']);
    
    $log->debug("Trying to delete realserver with id <$args{realserver_id}>");
    return $self->{_dbix}->keepalived1_virtualservers->find($args{virtualserver_id})->keepalived1_realservers->find($args{realserver_id})->delete;
}

sub setRealServerWeightToZero {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, require => ['realserver_id',
                                                    'virtualserver_id']);
    
    $log->debug("Setting realserver <$args{realserver_id}> weight to 0");
    my $virtualServer   = $self->{_dbix}->keepalived1_virtualservers->find($args{virtualserver_id});
    my $realServer      = $virtualServer->keepalived1_realservers->find($args{realserver_id});
    $realServer->set_column(realserver_weight => 0);
    $realServer->update();
}

=head2 getConf
    
    Desc : This function return the whole configuration to passed to the ui template.
    return : hash ref 

=cut

sub getConf {
    my $self = shift;
    my $row = $self->{_dbix};
    my $keepalived1_conf = {
        keepalived_id          => $row->get_column('keepalived_id'),
        daemon_method           => $row->get_column('daemon_method'),
        notification_email      => $row->get_column('notification_email'),
        notification_email_from => $row->get_column('notification_email_from'),
        smtp_server             => $row->get_column('smtp_server'),
        smtp_connect_timeout    => $row->get_column('smtp_connect_timeout'),
    };
    
    return $keepalived1_conf;
}

=head2 setConf
    
    Desc : This function save the whole configuration sended by the ui
    return : hash ref 

=cut

sub setConf {
    my $self = shift;
    my ($conf) = @_;
    if(not $conf->{keepalived_id}) {
         # new configuration -> create    
         $self->{_dbix}->create($conf);
         
         
    } else {
        # old configuration -> update
         $self->{_dbix}->update($conf);
    }
}

# return a data structure to pass to the template processor for ipvsadm file
sub getTemplateDataIpvsadm {
    my $self = shift;
    my $data = {};
    my $keepalived = $self->{_dbix};
    $data->{daemon_method} = $keepalived->get_column('daemon_method');
    $data->{iface} = $keepalived->get_column('iface');
    return $data;      
}

# return a data structure to pass to the template processor for keepalived.conf file 
sub getTemplateDataKeepalived {
    my $self = shift;
    my $data = {};
    my $keepalived = $self->{_dbix};
    $data->{notification_email} = $keepalived->get_column('notification_email');
    $data->{notification_email_from} = $keepalived->get_column('notification_email_from');
    $data->{smtp_server} = $keepalived->get_column('smtp_server');
    $data->{smtp_connect_timeout} = $keepalived->get_column('smtp_connect_timeout');
    $data->{lvs_id} = $keepalived->get_column('lvs_id');
    $data->{virtualservers} = [];
    my $virtualservers = $keepalived->keepalived1_virtualservers;
    
    while (my $vs = $virtualservers->next) {
        my $record = {};
        $record->{ip} = $vs->get_column('virtualserver_ip');
        $record->{port} = $vs->get_column('virtualserver_port');
        $record->{lb_algo} = $vs->get_column('virtualserver_lbalgo');
        $record->{lb_kind} = $vs->get_column('virtualserver_lbkind');
            
        $record->{realservers} = [];
        
        my $realservers = $vs->keepalived1_realservers->search();
        while(my $rs = $realservers->next) {
            push @{$record->{realservers}}, { 
                ip => $rs->get_column('realserver_ip'),
                port => $rs->get_column('realserver_port'),
                weight => $rs->get_column('realserver_weight'),
                check_port => $rs->get_column('realserver_checkport'),
                check_timeout => $rs->get_column('realserver_checktimeout'),
            }; 
        }
        push @{$data->{virtualservers}}, $record;
    }
    return $data;      
}

sub getBaseConfiguration {
    return {
        daemon_method           => 'both',
        iface                   => 'eth0',
        notification_email      => 'admin@mycluster.com',
        notification_email_from => 'keepalived@mycluster.com',
        smtp_server             => '127.0.0.1',
        smtp_connect_timeout    => 30,
        lvs_id                  => 'MAIN_LVS' 
    };
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
