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

=head1 NAME

EOperation::ECreateDisk - Operation class implementing disk creation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::ECreateDisk;
use base "EOperation";

use strict;
use warnings;

use EFactory;
use Kanopya::Exceptions;

use Entity::ServiceProvider;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

our $VERSION = '1.00';


=head2 prepare

    $op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    $self->{_objs} = {};
    $self->{executor} = {};

    $log->info("Operation preparation");

    # Check if internal_cluster exists
    General::checkParams(args => \%args, required => ["internal_cluster"]);

    # Get Operation parameters
    my $params = $self->_getOperation()->getParams();

    General::checkParams(args     => $params,
                         required => [ "storage_provider_id", "disk_manager_id",
                                       "name", "size", "filesystem" ]);

    $self->{params} = $params;

    # Instanciate the storage provider from params
    $self->{_objs}->{storage_provider}
        = Entity::ServiceProvider->get(id => $params->{storage_provider_id});

    # Instanciate the disk manager for disk creation from params
    my $disk_manager = $self->{_objs}->{storage_provider}->getManager(
                           id => $params->{disk_manager_id}
                       );

    $self->{_objs}->{edisk_manager} = EFactory::newEEntity(data => $disk_manager);

    # Check service provider state
    my ($state, $timestamp) = $self->{_objs}->{storage_provider}->getState();
    if ($state ne 'up'){
        $errmsg = "Service provider has to be up !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    # Instanciate executor Cluster
    $self->{executor} = Entity::ServiceProvider->get(
                            id => $args{internal_cluster}->{executor}
                        );

    my $exec_ip = $self->{executor}->getMasterNodeIp();
    my $masternode_ip = $self->{_objs}->{storage_provider}->getMasterNodeIp();

    eval {
        $self->{econtext} = EFactory::newEContext(ip_source      => $exec_ip,
                                                  ip_destination => $masternode_ip);
    };
    if($@) {
        $log->info("$@");
        $self->{econtext} = {};
    }
}

sub execute {
    my $self = shift;

    my $container = $self->{_objs}->{edisk_manager}->createDisk(
                        name       => $self->{params}->{name},
                        size       => $self->{params}->{size},
                        filesystem => $self->{params}->{filesystem},
                        econtext   => $self->{econtext},
                        erollback  => $self->{erollback},
                        %{ $self->{params} }
                    );

    $log->info("New container <" . $container->getAttr(name => 'container_name') . "> created");
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
