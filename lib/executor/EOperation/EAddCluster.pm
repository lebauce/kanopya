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
    General::checkParams(args => $self->{params}, required => [ "cluster_params", "managers" ]);

    # Check required params within cluster params
    General::checkParams(args     => $self->{params}->{cluster_params},
                         required => [ "cluster_name", "cluster_si_shared", "cluster_si_persistent",
                                       "cluster_min_node", "cluster_max_node", "cluster_priority" ]);

    # Check required params within managers
    General::checkParams(args     => $self->{params}->{managers},
                         required => [ "host_manager", "disk_manager" ]);

    if (defined $self->{params}->{cluster_params}->{kernel_id} and
        not $self->{params}->{cluster_params}->{kernel_id}) {
        delete $self->{params}->{cluster_params}->{kernel_id};
    }

    # Check the boot policy or the export manager
    if (not ($self->{params}->{cluster_params}->{cluster_boot_policy} xor
             $self->{params}->{managers}->{export_manager}->{manager_id})) {
        throw Kanopya::Exception::Internal::WrongValue(
                  error => "Can not specify boot_policy and export_manager_id at the same time."
              );
    }

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
}

sub execute {
    my $self = shift;

    $self->{context}->{cluster}->create(managers   => $self->{params}->{managers},
                                        components => $self->{params}->{components},
                                        interfaces => $self->{params}->{interfaces},
                                        erollback  => $self->{erollback});

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
