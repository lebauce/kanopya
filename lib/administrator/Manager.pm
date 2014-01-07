# Copyright © 2012-2013 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

A component is called manager by the others service providers that 
the one on which it is installed.

=end classdoc
=cut

package Manager;

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub methods {
    return {
        # TODO(methods): Remove this method from the api once we can use virtual attrs on managers
        getManagerParamsDef => {
            description => 'get the manager parameters definition',
        }
    };
}

=pod
=begin classdoc

@constructor

Dummy constructor to use the manager stand alone.

=end classdoc
=cut

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;
    return $self;
}


=pod
=begin classdoc

Check required paramaters in function of the type of the manager.

=end classdoc
=cut

sub checkManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "manager_type" ]);

    $args{manager_params} = $args{manager_params} ? $args{manager_params} : {};

    if ($args{manager_type} eq 'HostManager') {
        return $self->checkHostManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'DiskManager') {
        return $self->checkDiskManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'ExportManager') {
        return $self->checkExportManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'CollectorManager') {
        return $self->checkCollectorManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'WorkflowManager') {
        return $self->checkWorkflowManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'NotificationManager') {
        return $self->checkNotificationManagerParams(%{ $args{manager_params} });
    }
}


=pod
=begin classdoc

@return the definition of the required params of the manager.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;
    return {};
}


=pod
=begin classdoc

Try to increase the number of current consumers of the manager.
Concrete managers could override this method and raise an exceptions
if the manager has reach the maximum of simultaneous users.

=end classdoc
=cut

sub increaseConsumers {
    my ($self, %args) = @_;

    # Use the following block to raise exception in concrete implementation of increaseConsumers.
    #throw Kanopya::Exception::Execution::InvalidState(
    #          error => "The xxxx manager has reach the maximum amount of consumers"
    #      );
}


=pod
=begin classdoc

Decrease the number of current consumers of the manager.

=end classdoc
=cut

sub decreaseConsumers {
    my ($self, %args) = @_;
}

1;
