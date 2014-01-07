#    Copyright © 2011-2013 Hedera Technology SAS
#
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

=pod
=begin classdoc

The service listen to Openstack notification.info topic and synchronize
Kanopya DB w.r.t. the <event type> of received messages.

Manage following event types :
- compute.instance.create.end
- compute.instance.delete.end
- compute.instance.rebuild.end
- compute.instance.resize.confirm.end

see <https://wiki.openstack.org/wiki/NotificationSystem> for notification system documentation

@since    2013-December-13
@instance hash
@self     $self

=end classdoc
=cut

package OpenstackSync;
use base Daemon::MessageQueuing;

use strict;
use warnings;

use Entity::Component::Virtualization::NovaController;

use TryCatch;

use Log::Log4perl "get_logger";
use Log::Log4perl::Layout;
use Log::Log4perl::Appender;

my $log = get_logger("");


# Map function to call w.r.t event type received
my $functionTable = {
    'compute.instance.create.end'         => 'computeInstanceCreateEnd',
    'compute.instance.delete.end'         => 'computeInstanceDeleteEnd',
    'compute.instance.rebuild.end'        => 'computeInstanceRebuildEnd',
    'compute.instance.resize.confirm.end' => 'computeInstanceResizeConfirmEnd',
};


=pod
=begin classdoc

@constructor

Override the parent constructor to register existing nova controllers.

@param nova_controller the nova controller instance.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, optional => { "duration" => undef });

    my $self = $class->SUPER::new(confkey => 'openstack-sync', %args);

    # Browse the nova controllers managed by this KanopyaOpenStackSync.
    if ($self->_component->isa('Entity::Component::KanopyaOpenstackSync')) {
        for my $nc ($self->_component->nova_controllers) {
            $self->registerOpenstackSyncCallback(cbname          => 'novacontroller-' . $nc->id,
                                                 nova_controller => $nc);
        }
        $log->info("OpenstackSync callbacks have been registered...");
    }

    return $self;
}


=pod
=begin classdoc

Register a callback definition from a nova controller instance to wait
messages on its notification queue.

@param nova_controller the nova controller instance.

=end classdoc
=cut

sub registerOpenstackSyncCallback {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cbname', 'nova_controller' ]);

    if (! defined $self->_callbacks->{$args{cbname}}) {
        my $amqp     = $args{nova_controller}->amqp;
        my $ip       = $amqp->getMasterNode->adminIp;
        my $port     = $amqp->getNetConf->{amqp}->{port};
        my $user     = 'nova-' . $args{nova_controller}->id;
        my $password = 'nova';
        my $vhost    = 'openstack-' . $args{nova_controller}->id;

        my $config = {
            ip       => $ip,
            port     => $port,
            user     => $user,
            password => $password,
            vhost    => $vhost,
        };

        my $nova_contoller = $args{nova_controller};
        my $callback = sub {
            my ($self, %cbargs) = @_;
            $self->novaNotificationAnalyser(%cbargs, host_manager => $nova_contoller);
        };

        $self->registerCallback(
            config    => $config,
            cbname    => $args{cbname},
            callback  => $callback,
            exchange  => 'nova',
            queue     => 'notifications.info',
            type      => 'topic',
            duration  => 0,
            declare   => 0,
        );
    }
    else {
        throw Kanopya::Exception::Daemon(
                  error => "Nova controller <" . $args{nova_controller}->id . "> already registred, skip."
              );
    }
}


=pod
=begin classdoc

Override the inherited method to handle custom messages on the control queue.
Here we want to register callbacks at runtime to dynamically start consuming
messages. We are detecting messages as custom if they contains a nova_controller_id
naed param.

@param cbname the name of the callback definition to control
@param control the control type (spawn|kill)

@optional instances the number of instance to control

=end classdoc
=cut

sub controlDaemon {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cbname', 'control', 'nova_controller_id', 'ack_cb' ],
                         optional => { 'instances' => 1 });

    # Handle custom control messages.
    # Register a callback for the given nova controller for consuming messageson its notification queue.
    if (defined $args{nova_controller_id} && $args{control} eq 'spawn') {
        my $nc = Entity::Component::Virtualization::NovaController->get(id => $args{nova_controller_id});
        $self->registerOpenstackSyncCallback(cbname => $args{cbname}, nova_controller => $nc);
    }

    # Finally handle the message as a regular control message
    my $ack = $self->SUPER::controlDaemon(cbname => $args{cbname}, control => $args{control});

    # Unregister the corresponding callback if control code is 'kill'
    if (defined $args{nova_controller_id} && $args{control} eq 'kill') {
        delete $self->_callbacks->{$args{cbname}};
    }

    return $ack;
}


=pod
=begin classdoc

Called when a notification message is received.
Analyse @param <event_type> and call corresponding method

@param host_manager HostManager instance related to the received message

=end classdoc
=cut

sub novaNotificationAnalyser {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'host_manager' ],
                         optional => { 'event_type' => undef });

    $log->info("New message received related to nove controller <" . $args{host_manager}->id . ">");

    if (! defined $args{event_type}) {
        $log->info("Event type not defined in message. Skip.");
        return 1;
    }

    if (defined $functionTable->{$args{event_type}}) {
        my $method = $functionTable->{$args{event_type}};
        $self->$method(%args);
    }
    else {
        $log->info("Unmanaged event type <$args{event_type}>. Skip.");
    }

    return 1;
}


=pod
=begin classdoc

Manage message <compute.instance.create.end>.

Create a new Entity::Host::VirtualMachine::OpenstackVm instance in Kanopya DB
and its corresponding node with following information :
- instance_id            as openstack_vm_uuid
- memory_mb              as host_ram
- vcpus                  as host_core
- "hostname-instance_id" as node_hostname

Create ethX ifaces linked to different "fixed_ips" with :
- address      as ip_addr
- undef (null) as pool_id

Create a Cluster named "UnmanagedVirtualMachines-nova_id" to register the new vms.
Cluster is linked to the user linked to the nova cluster.
Cluster is set to "Generic Service" template.

@param host_manager HostManager instance related to the received message

=end classdoc
=cut

sub computeInstanceCreateEnd {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_manager', 'payload' ]);

    $log->info("Handle event <compute.instance.create.end>, instance id <$args{payload}->{instance_id}>");

    # If the VM has been created by Kanopya, it is up to the Executor process
    # to register the new node. So the registration is skipped.
    try {
        Entity::Host::VirtualMachine::OpenstackVm->find(
            hash => { openstack_vm_uuid => $args{payload}->{instance_id} }
        );
        my $message = "Vm <" . $args{payload}->{instance_id}
                      . "> has already been created by Kanopya. Skip.";
        $log->info($message);
        return 1;
    }

    my @ip_infos = @{$args{payload}->{fixed_ips}};

    my $host = $args{host_manager}->createVirtualHost(
                   ram    => $args{payload}->{memory_mb} << 20, #convert mb into b
                   core   => $args{payload}->{vcpus},
                   ifaces => scalar (@ip_infos)
                );

    my @ifaces = $host->ifaces;

    for my $iface (@ifaces) {
        Ip->new(ip_addr  => (pop @ip_infos)->{address},
                iface_id => $iface->id);
    }

    my $hypervisor = Entity::Host::Hypervisor::OpenstackHypervisor->find(
                         hash => {'node.node_hostname' => $args{payload}->{host}},
                     );

    $host = $args{host_manager}->promoteVm(
                host          => $host,
                vm_uuid       => $args{payload}->{instance_id},
                hypervisor_id => $hypervisor->id,
            );

    my $cluster_name_prefix = 'UnmanagedVirtualMachines';
    my $cluster_name = $cluster_name_prefix . $args{host_manager}->id;
    my $cluster;

    try {
        $cluster = Entity::ServiceProvider::Cluster->find(
                       hash => {cluster_name => $cluster_name},
                   );
    }
    catch ( Kanopya::Exception::Internal::NotFound $err) {
        # Create cluster if not already created
        my $generic_service = Entity::ServiceTemplate->find(
                                  hash => { service_name => "Generic service" },
                              );

        $cluster = Entity::ServiceProvider::Cluster->new(
                       cluster_name          => $cluster_name,
                       cluster_min_node      => 1,
                       cluster_max_node      => 1,
                       cluster_priority      => 500,
                       cluster_si_persistent => 1,
                       cluster_domainname    => 'my.domain',
                       cluster_nameserver1   => '127.0.0.1',
                       cluster_nameserver2   => '127.0.0.1',
                       user_id               => $args{host_manager}->service_provider->user_id,
                       service_template_id   => $generic_service->id,
                   );
    }

    # Use instance_id instead of name because Openstack allows vms with same node hostname
    my $node_hostname = $args{payload}->{hostname} . '-' . $args{payload}->{instance_id};

    my $node = $cluster->registerNode(
                   hostname => $node_hostname,
                   number   => $cluster->getNewNodeNumber(),
                   host     => $host,
               );

    $log->info("A new host <" . $host->id . "> and node <" . $node->id .
               "> has been registered in Kanopya DB");
}


=pod
=begin classdoc

Manage message <compute.instance.delete.end>.

Delete corresponding Node instance and Host instance in Kanopya DB.

=end classdoc
=cut

sub computeInstanceDeleteEnd {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_manager', 'payload' ]);

    $log->info("Handle event <compute.instance.delete.end>, instance id <$args{payload}->{instance_id}>");

    my $host;
    # Check if the host has not been already deleted
    try {
        $host = Entity::Host::VirtualMachine::OpenstackVm->find(
                   hash => {openstack_vm_uuid => $args{payload}->{instance_id}}
                );
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        # This case may appear when cancelling addnode workflow
        $log->info("Vm <$args{payload}->{instance_id}> unknown in Kanopya DB. Skip.");
        return 1;
    }

    # Detect the case where node deletion is due to Kanopya Executor
    my $node_state = ($host->getNodeState())[0];
    if ($node_state eq "goingout") {
        $log->info("Vm <$args{payload}->{instance_id}> deleted by Kanopya Executor. Skip.");
        return 1;
    }

    my $node = $host->node;
    $node->service_provider->unregisterNode(node => $node);
    $host->delete();

    $log->info("Vm <$args{payload}->{instance_id}> has been removed from Kanopya DB");
}


=pod
=begin classdoc

Manage message <compute.instance.rebuild.end>.

The vm has been rebuilt. Update new information in Kanopya DB.

=end classdoc
=cut

sub computeInstanceRebuildEnd {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_manager', 'payload' ]);

    $log->info("Handle event <compute.instance.rebuild.end>, instance id <$args{payload}->{instance_id}>");

    my $host = Entity::Host::VirtualMachine::OpenstackVm->find(
                   hash => {openstack_vm_uuid => $args{payload}->{instance_id}}
               );
    my $hypervisor = Entity::Host::Hypervisor::OpenstackHypervisor->find(
                         hash => {'node.node_hostname' => $args{payload}->{host}},
                     );

    # Update information that could have been modified during rebuild
    $host->hypervisor_id($hypervisor->id);

    $log->info("Host <" . $host->id . "> with uuid <$args{payload}->{instance_id}" . 
               "> has been rebuilt and updated in Kanopya DB");
}

=pod
=begin classdoc

Manage message <compute.instance.resize.confirm.end>.

Warning: This method is untested in real infrastructure.

=end classdoc
=cut

sub computeInstanceResizeConfirmEnd {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_manager', 'payload' ]);

    $log->info("Handle event <compute.instance.resize.confirm.end>, " .
               "instance id <$args{payload}->{instance_id}>");

    my $host = Entity::Host::VirtualMachine::OpenstackVm->find(
                   hash => {openstack_vm_uuid => $args{payload}->{instance_id}}
               );
    my $hypervisor = Entity::Host::Hypervisor::OpenstackHypervisor->find(
                         hash => {'node.node_hostname' => $args{payload}->{host}},
                     );

    # Update information that could have been modified during rebuild
    $host->hypervisor_id($hypervisor->id);
    $host->host_ram($args{payload}->{memory_mb} << 20); #convert mb into b
    $host->host_core($args{payload}->{vcpus});

    $log->info("Host <" . $host->id . "> with uuid <$args{payload}->{instance_id}> has been resized");
}

1;
