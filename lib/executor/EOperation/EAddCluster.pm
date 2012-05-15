# EAddCluster.pm - Operation class implementing Cluster creation operation

#    Copyright © 2009-2012 Hedera Technology SAS
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

=head1 NAME

EEntity::Operation::EAddHost - Operation class implementing Host creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Host creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut

package EOperation::EAddCluster;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;

use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;
use Entity::Gp;
use Entity;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    # Check if all required params group are defined
    General::checkParams(args     => $self->{params},
                         required => [ "cluster_params", "disk_manager_params", "host_manager_params" ]);

    # Check required params within cluster params
    General::checkParams(args     => $self->{params}->{cluster_params},
                         required => [ "cluster_name", "disk_manager_id", "host_manager_id",
                                       "cluster_boot_policy", "cluster_si_shared" ]);

    if (defined $self->{params}->{cluster_params}->{kernel_id} and
        not $self->{params}->{cluster_params}->{kernel_id}) {
        delete $self->{params}->{cluster_params}->{kernel_id};
    }
    if (defined $self->{params}->{cluster_params}->{collector_manager_id} and
        not $self->{params}->{cluster_params}->{collector_manager_id}) {
        delete $self->{params}->{cluster_params}->{collector_manager_id};
    }

    # Instanciate the disk manager to get the export manager according to the boot policy.
    my $disk_manager;
    eval {
        $disk_manager = Entity->get(id => $self->{params}->{cluster_params}->{disk_manager_id});
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }

    my $export_manager = $disk_manager->getExportManagerFromBootPolicy(
                             boot_policy => $self->{params}->{cluster_params}->{cluster_boot_policy}
                         );

    $self->{params}->{cluster_params}->{export_manager_id} = $export_manager->getAttr(name => 'entity_id');

    # Cluster creation
    eval {
        my $cluster = Entity::ServiceProvider::Inside::Cluster->new(%{$self->{params}->{cluster_params}});
        $self->{context}->{cluster} = EFactory::newEEntity(data => $cluster);
    };
    if($@) {
        $errmsg = "EOperation::EAddCluster->prepare : Cluster instanciation failed because : " . $@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Store managers paramaters for this cluster.
    for my $manager ('host_manager', 'disk_manager', 'export_manager', 'collector_manager') {
        my $manager_params = $self->{params}->{$manager . '_params'};
        if ($manager_params) {
            for my $param_name (keys %{$manager_params}) {
                $self->{context}->{cluster}->addManagerParameter(
                    manager_type => $manager,
                    name         => $param_name,
                    value        => $manager_params->{$param_name},
                );
            }
        }
    }

    # Get export manager parameter related to si shared value.
    my $readonly_param = $export_manager->getReadOnlyParameter(
                             readonly => $self->{params}->{cluster_params}->{cluster_si_shared}
                         );

    if ($readonly_param) {
        $self->{context}->{cluster}->_getEntity->addManagerParameter(
            manager_type => 'export_manager',
            name         => $readonly_param->{name},
            value        => $readonly_param->{value}
        );
    }
}

sub execute {
    my $self = shift;

    $self->{context}->{cluster}->create(erollback => $self->{erollback});

    $log->info("Cluster <" . $self->{context}->{cluster}->getAttr(name => "cluster_name") . "> is now added");
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

Kanopya Copyright (C) 2009-2012 Hedera Technology.

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
