# ECluster.pm - Abstract class of EClusters object

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
# Created 14 july 2010

=head1 NAME

ECluster - execution class of cluster entities

=head1 SYNOPSIS



=head1 DESCRIPTION

ECluster is the execution class of cluster entities

=head1 METHODS

=cut
package EEntity::EServiceProvider::EInside::ECluster;
use base 'EEntity';

use strict;
use warnings;

use Entity;
use General;
use EFactory;
use Entity::InterfaceRole;

use Template;
use String::Random;
use IO::Socket;
use Net::Ping;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

sub create {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext"]);

    # Create cluster directory
    my $command = "mkdir -p /clusters/" . $self->_getEntity()->getAttr(name =>"cluster_name");
    $args{econtext}->execute(command => $command);
    $log->debug("Execution : mkdir -p /clusters/" . $self->_getEntity()->getAttr(name => "cluster_name"));

    # set initial state to down
    $self->_getEntity()->setAttr(name => 'cluster_state', value => 'down:'.time);
    
    # Save the new cluster in db
    $log->debug("trying to update the new cluster previouly created");
    $self->_getEntity()->save();

    # automatically add System|Monitoragent|Logger components
    foreach my $compclass (qw/Entity::Component::Mounttable1
                              Entity::Component::Syslogng3
                              Entity::Component::Snmpd5/) {
        my $location = General::getLocFromClass(entityclass => $compclass);
        eval { require $location; };
        $log->debug("trying to add $compclass to cluster");
        my $comp = $compclass->new();
        $comp->insertDefaultConfiguration();
        $self->_getEntity()->addComponent(component => $comp);
        $log->info("$compclass automatically added");
    }

    # Automatically add the admin interface
    my $adminrole = Entity::InterfaceRole->find(hash => { interface_role_name => 'admin' });
    my $kanopya   = Entity::ServiceProvider::Inside::Cluster->find(hash => { cluster_name => 'Kanopya' });
    my $interface = Entity::Interface->find(
                         hash => { service_provider_id => $kanopya->getAttr(name => 'entity_id'),
                                   interface_role_id   => $adminrole->getAttr(name => 'entity_id') }
                     );

    $self->_getEntity->addNetworkInterface(
        interface_role => $adminrole,
        networks       => $interface->getNetworks
    );
}

sub addNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext"]);

    my $host_manager = Entity->get(id => $self->_getEntity->getAttr(name => 'host_manager_id'));
    my $host_manager_params = $self->_getEntity->getManagerParameters(manager_type => 'host_manager');

    # Add the number of required ifaces to paramaters.
    my @interfaces = $self->_getEntity->getNetworkInterfaces;
    $host_manager_params->{ifaces} = scalar(@interfaces);

    my $ehost_manager = EFactory::newEEntity(data => $host_manager);
    my $host = $ehost_manager->getFreeHost(%$host_manager_params);

    $log->debug("Host manager <" . $self->_getEntity->getAttr(name => 'host_manager_id') .
                "> returned free host " . $host->getAttr(name => 'host_id'));

    return $host;
}

sub generateResolvConf {
    my ($self, %args) = @_;
    General::checkParams(args => \%args,
                         required => ['econtext', 'etc_path' ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    my @nameservers = ();

    for my $attr ('cluster_nameserver1','cluster_nameserver2') {
        push @nameservers, {
            ipaddress => $self->_getEntity()->getAttr(name => $attr)
        };
    }

    my $vars = {
        domainname => $self->_getEntity()->getAttr(name => 'cluster_domainname'),
        nameservers => \@nameservers,
    };


    my $template = Template->new(General::getTemplateConfiguration());
    my $input = "resolv.conf.tt";

    $template->process($input, $vars, "/tmp/".$tmpfile) or die $template->error(), "\n";
    $args{econtext}->send(
        src  => "/tmp/$tmpfile",
        dest => "$args{etc_path}/resolv.conf"
    );
    unlink "/tmp/$tmpfile";
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
