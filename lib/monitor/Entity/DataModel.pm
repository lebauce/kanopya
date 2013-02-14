#    Copyright © 2013 Hedera Technology SAS
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

package Entity::DataModel;

use base 'Entity';

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;
use List::Util;
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    combination_id => {
        pattern => '^\d+$',
        is_mandatory => 1,
        is_extended => 0
    },
    node_id => {
        pattern => '^\d+$',
        is_mandatory => 0,
        is_extended => 0
    },
    param_preset_id => {
        pattern => '^\d+$',
        is_mandatory => 0,
        is_extended => 0
    },
    start_time => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
    end_time => {
        pattern => '^.*$',
        is_mandatory => 0,
        is_extended => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my $class = shift;
    my %args = @_;

    if (defined $args{combination_id}) {
        my $combination = Entity->get(id => $args{combination_id});

        # DataModel of a NodemetricCombination needs a related node
        if ($combination->isa('Entity::Combination::NodemetricCombination')) {
            if (! defined $args{node_id}) {
                $errmsg = "A nodemetric combination datamodel needs a node_id argument";
                throw Kanopya::Exception(error => $errmsg);
            }
        }
        elsif ($combination->isa('Entity::Combination::ClustermetricCombination')) {
            $log->info('Ignoring node_id in the data model of a clustermetric combination');
            $args{node_id} = undef;
        }
    }
    my $self = $class->SUPER::new(%args);
    return $self;
}

sub computeRSquared {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args, required => ['data', 'data_model']);

    # Compute the coefficient of determination according to its formal definition
    my $data_avg = List::Util::sum(@{$args{data}}) / @{$args{data}};
    my $SSerr = List::Util::sum( List::MoreUtils::pairwise {($a - $b)**2} @{$args{data}}, @{$args{data_model}});
    my $SStot = List::Util::sum( map {($_ - $data_avg)**2} @{$args{data}} );

    return (1 - $SSerr / $SStot);
}

sub configure {
    throw Kanopya::Exception(error => 'Method not implemented');
}

sub predict {
    throw Kanopya::Exception(error => 'Method not implemented');
}

sub getRSquared {
    throw Kanopya::Exception(error => 'Method not implemented');
}

1;
