#    Copyright © 2010-2013 Hedera Technology SAS
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

package EEntity::EOperation::ERemoveSystemimage;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use EEntity;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;
use Entity::Systemimage;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;
    my %args = @_;
    $self->SUPER::check();
    
    General::checkParams(args => $self->{context}, required => [ "systemimage" ]);
}


sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    # Check if systemimage is not active
    # TODO: The following code is useless as we do not change any state within prepare.
    if ($self->{context}->{systemimage}->active) {
        $errmsg = "Systemimage <" . $self->{context}->{systemimage}->id . "> is active";
        throw Kanopya::Exception::Execution::InvalidState(error => $errmsg);
    }
}

sub execute{
    my $self = shift;
    $self->SUPER::execute();

    $self->{context}->{systemimage}->remove();
}

1;
