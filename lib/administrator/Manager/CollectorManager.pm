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
use Indicator;

my $log = get_logger("administrator");

=head2 checkManagerParams

=cut

sub checkCollectorManagerParams {
}

=head2

    Desc: Call kanopya native monitoring API to retrieve indicators data 
    return \%monitored_values;

=cut

sub retrieveData {
}

=head2 getIndicators

    Desc: call collector manager to retrieve indicators available for the service provider
    return \@indicators;
        
=cut

sub getIndicators {
}

=head2 getIndicator

    Desc: Return the indicator with the specified id
    Return an indicator instance

=cut

sub getIndicator {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['id']);

    return Indicator->get(id => $args{id});
}

=head2

    Desc: Return an information string about the component 

=cut

sub getCollectorType { }

1;
