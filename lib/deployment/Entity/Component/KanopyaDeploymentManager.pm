#    Copyright © 2014 Hedera Technology SAS
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

KanopyaDeploymentManager is the native deployment component of Kanopya.
It implement the deployment interface by using other any given export and disk drivers,
and other Kanopya components like dchpd and tfptd to achieve deploymement of nodes.
It deploy diskless or on local disk nodes, install and configure the requested components. 

@since    2014-Apr-9
@instance hash
@self     $self

=end classdoc
=cut

package Entity::Component::KanopyaDeploymentManager;
use base Entity::Component;
use base Manager::DeploymentManager;

use strict;
use warnings;

use TryCatch;
use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


use constant ATTR_DEF => {
    kanopya_executor_id => {
        label        => 'Workflow manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
    dhcp_component_id => {
        label        => 'Dhcp manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
    tftp_component_id => {
        label        => 'Tftp manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
     => {
        label        => 'Operating system manager',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^[0-9\.]*$',
        is_mandatory => 1,
        is_editable  => 0,
    },
};


=pod
=begin classdoc

@constructor

Override the parent contructor to check the category of the component parameters

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'kanopya_executor', 'dhcp_component',
                                       'tftp_component', 'system_component' ]);

    my @wrongs;
    if (scalar(grep { $_->category_name eq 'Dhcpserver' }
               $args{dhcp_component}->component_type->component_categories) <= 0) {
        push @wrongs, $args{dhcp_component};
    }
    if (scalar(grep { $_->category_name eq 'Tftpserver' }
               $args{tftp_component}->component_type->component_categories) <= 0) {
        push @wrongs, $args{tftp_component};
    }
    if (scalar(grep { $_->category_name eq 'System' }
               $args{system_component}->component_type->component_categories) <= 0) {
        push @wrongs, $args{system_component};
    }
    if (scalar(@wrongs)) {
        throw Kanopya::Exception::Internal::WrongType(
              error => "Wrong category for component(s): " .
                       join(',', map { $_->component_type_component_name } @wrongs)
          )
    }

    return $class->SUPER::new(%args);
}


=pod
=begin classdoc

Use the executor to run the operation AddCluster.

@param node the node to deploy
@param systemimage the systemiage to use to deploy the node
@param boot_mode, the boot mode for the deplyoment

@optional hypervisor the hypervisor to use for virtuals nodes
@optional kernel_id force the kernel to use
@optional workflow in which to embed the deployment operation

=end classdoc
=cut

sub deployNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node', 'systemimage', 'boot_mode' ],
                         optional => { 'hypervisor' => undef, 'kernel_id' => undef, 'workflow' => undef });

    $args{context}->{deployment_manager} = $self;
    return $self->kanopya_executor->enqueue(
               type     => 'DeployNode',
               workflow => $args{workflow},
               params => {
                   context => {
                       deployment_manager => $self,
                       node               => $args{node},
                       systemimage        => $args{systemimage},
                   },
                   boot_mode => $args{boot_mode},
                   kernel_id => $args{kernel_id},
               }
           );
}


=pod
=begin classdoc

Use the executor to run the operation ReleaseNode.

@param node the node to deploy

@optional workflow in which to embed the deployment operation

=end classdoc
=cut

sub releaseNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node' ],
                         optional => { 'workflow' => undef });

    $args{context}->{deployment_manager} = $self;
    return $self->kanopya_executor->enqueue(
               type     => 'ReleaseNode',
               workflow => $args{workflow},
               params   => %args
           );
}

1;
