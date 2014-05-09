#    Copyright © 2011-2013 Hedera Technology SAS
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

Base class to implement a Collector component.

A collector is a tool retrieving monitoring data (indicators) from nodes.
Using this manager we can:

- configure what is collected
- request collected values

=end classdoc
=cut

package Manager::CollectorManager;
use base "Manager";

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use General;
use Entity::CollectorIndicator;
use Entity::Indicator;

my $log = get_logger("");

sub methods {
    return {
        getIndicators => {
            description => 'get indicators',
        }
    },
}

sub createCollectorIndicators {
    my ($self,%args) = @_;
    General::checkParams(args => \%args, required => ['indicator_sets']);

    my @indicators = ();

    for my $indicator_set (@{$args{indicator_sets}}) {
        @indicators = ( @indicators,
                        Entity::Indicator->search (
                            hash => {
                                indicatorset_id => $indicator_set-> id,
                            }
                        )
                      );
    }

    for my $indicator (@indicators) {
        Entity::CollectorIndicator->new(
            indicator_id => $indicator->id,
            collector_manager_id =>  $self->id,
        );
    }

    return;
}


sub getIndicators {
    my $self = shift;

    my @collector_indicators = $self->collector_indicators;
    my @indicators = map {$_->indicator} @collector_indicators;
    return \@indicators;
}


sub getIndicator {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['id']);

    my $collector_indicator = CollectorIndicator->get(id => $args{id});
    return $collector_indicator->indicator;
}

sub checkCollectorManagerParams {}


sub retrieveData {}


sub collectIndicator {}


sub getCollectorType { }


=pod
=begin classdoc

Remove linked collector indicators

=end classdoc
=cut

sub removeCollectorIndicators {
    my $self = shift;

    my @collector_indicators = $self->collector_indicators;
    while (@collector_indicators) {
        (pop @collector_indicators)->remove();
    }

    return;
}


1;
