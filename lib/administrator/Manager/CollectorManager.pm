# CollectorManager.pm - Object class of Collector Manager included in Administrator

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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 20 april 2012

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
            description => 'create a new cluster',
            perm_holder => 'entity',
            purpose     => 'internal',
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

=head2 getIndicators

    Desc: Retrieve a list of indicators available

=cut

sub getIndicators {
    my $self = shift;
    my @collector_indicators = $self->collector_indicators;
    my @indicators = map {$_->indicator} @collector_indicators;
    return \@indicators;
}

=head2 getIndicator

    Desc: Return the indicator with the specified id
    Args: indicator id
    Return an indicator instance

=cut

sub getIndicator {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['id']);
    my $collector_indicator = CollectorIndicator->get(id => $args{id});
    return $collector_indicator->indicator;
}

sub checkCollectorManagerParams {
}

=head2

    Desc: Call kanopya native monitoring API to retrieve indicators data
    return \%monitored_values;

=cut

sub retrieveData {
}

=head2 collectIndicator

    Desc: Ensure the specified indicator is collected

=cut

sub collectIndicator {
}

=head2

    Desc: Return an information string about the collector manager

=cut

sub getCollectorType { }

1;
