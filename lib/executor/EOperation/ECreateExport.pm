#    Copyright © 2009-2012 Hedera Technology SAS
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

EOperation::ECreateExport - Operation class implementing component installation on systemimage

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut

package EOperation::ECreateExport;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::ServiceProvider;
use Entity::Container;
use EFactory;

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

    $log->info("Operation preparation");

    General::checkParams(args => \%args, required => [ "internal_cluster" ]);

    # Get Operation parameters
    my $params = $self->_getOperation()->getParams();

    # Test operation paramaters
    eval {
        General::checkParams(args     => $params,
                             required => [ "export_manager_id", "container_id" ]);
    };
    if($@) {
        $errmsg = "Operation::ECreateExport needs storage_provider_id, ".
                  "component_id and container_id parameters";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Instanciate the export manager for export creation from params
    eval {
        $self->{_objs}->{eexport_manager}
            = EFactory::newEEntity(data => Entity->get(id => $params->{export_manager_id}));
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }

    # Check state of the storage_provider
    my $storage_provider = $self->{_objs}->{eexport_manager}->_getEntity->getServiceProvider;
    my ($state, $timestamp) = $storage_provider->getState();
    if ($state ne 'up'){
        $errmsg = "ServiceProvider has to be up !";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }

    # Instanciate container
    $self->{_objs}->{container} = Entity::Container->get(id => $params->{container_id});

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{executor});
    $self->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                              ip_destination => $storage_provider->getMasterNodeIp());

    $self->{params} = $params;
}

sub execute{
    my $self = shift;

    $self->{_objs}->{eexport_manager}->createExport(container   => $self->{_objs}->{container},
                                                    export_name => $self->{params}->{export_name},
                                                    erollback   => $self->{erollback},
                                                    econtext    => $self->{econtext},
                                                    %{$self->{params}});
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
