#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EOperation::EAddHost;
use base "EEntity::EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;
use Template;

use Entity;
use Entity::Host;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Kernel;
use Entity::Hostmodel;
use Entity::Processormodel;
use Entity::Gp;
use ERollback;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "host_manager" ]);

    # Restore the list of ifaces
    if (defined $self->{params}->{ifaces}) {
        my @ifaces;
        for my $iface (keys %{$self->{params}->{ifaces}}) {
            push @ifaces, $self->{params}->{ifaces}->{$iface};
        }
        $self->{params}->{ifaces} = \@ifaces;
    }
    
    if (defined $self->{params}->{harddisks}) {
        my @harddisks;
        for my $hd (keys %{$self->{params}->{harddisks}}) {
            push @harddisks, $self->{params}->{harddisks}->{$hd};
        }
        $self->{params}->{harddisks} = \@harddisks;
    }
}

sub execute {
    my $self = shift;

    my $host = $self->{context}->{host_manager}->createHost(%{$self->{params}}, erollback => $self->{erollback});

    $log->info("Host <" . $host->getAttr(name => "entity_id") . "> is now created");
}

1;
