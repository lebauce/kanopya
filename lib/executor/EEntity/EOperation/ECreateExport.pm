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

package EEntity::EOperation::ECreateExport;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::ServiceProvider;
use Entity::Container;
use EFactory;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;
our $VERSION = '1.00';


=head2 prepare

=cut

sub prepare {    
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "export_manager", "container" ]);

    General::checkParams(args => $self->{params}, required => [ "manager_params" ]);

    # Check state of the storage_provider
    my $storage_provider = $self->{context}->{export_manager}->service_provider;
    my ($state, $timestamp) = $storage_provider->getState();
    if ($state ne 'up'){
        $errmsg = "ServiceProvider has to be up !";
        $log->error($errmsg);
        throw Kanopya::Exception::Execution(error => $errmsg);
    }
}

sub execute {
    my $self = shift;

    $self->{context}->{export_manager}->createExport(container => $self->{context}->{container},
                                                     erollback => $self->{erollback},
                                                     %{$self->{params}->{manager_params}});
}

1;
