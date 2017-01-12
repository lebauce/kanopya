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

    my $updated;
    if ($args{manager_type} eq 'HostManager') {
        $updated = $self->checkHostManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'DiskManager') {
        $updated = $self->checkDiskManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'ExportManager') {
        $updated = $self->checkExportManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'StorageManager') {
        $updated = $self->checkStorageManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'NetworkManager') {
        $updated = $self->checkNetworkManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'CollectorManager') {
        $updated = $self->checkCollectorManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'WorkflowManager') {
        $updated = $self->checkWorkflowManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'NotificationManager') {
        $updated = $self->checkNotificationManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'DeploymentManager') {
        $updated = $self->checkDeploymentManagerParams(%{ $args{manager_params} });
    }

    if (ref($updated) eq "HASH") {
        # The params has been updated/completed by the manager
        return $updated;
    }
    else {
        # Else return the original ones
        return $args{manager_params};
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

1;
