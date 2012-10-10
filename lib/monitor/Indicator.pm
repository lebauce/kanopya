#    Copyright © 2012 Hedera Technology SAS
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
package Indicator;

use strict;
use warnings;
use base 'BaseDB';
use Data::Dumper;
require 'ScomIndicator.pm';
require 'Clustermetric.pm';

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    indicator_id               =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    indicator_name             =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    indicator_oid             =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    indicator_min              =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    indicator_max              =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    indicator_color            =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    indicatorset_id            =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    indicator_unit         =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'toString'  => {
            'description' => 'toString',
            'perm_holder' => 'entity'
        },
        'getDependencies' => {
            'description' => 'return dependencies tree for this object',
            'perm_holder' => 'entity',
        },
    };
}

sub toString {
    my $self = shift;

    return $self->indicatorset->indicatorset_name . '/' . $self->indicator_name;
}

sub getDependencies {
    my $self = shift;
    my %dependencies;

    my @related_scom_indicators = ScomIndicator->search(
                                                     hash => {
                                                         indicator_oid => $self->indicator_oid,
                                                     }
                                                 );

    # Service
    for my $indicator (@related_scom_indicators) {

        # Node related hierarchy

        #TODO : Compaptibility with KIM service_provider_name (with function getName) !
        # Variables used more than once
        my $service_provider      = $indicator->service_provider;
        my $service_provider_name = $service_provider->externalcluster_name;
        my $indicator_id          = $indicator->getId;

        my @dependent_clustermetric = Clustermetric->search(
                                                         hash => {
                                                             clustermetric_indicator_id => $indicator_id,
                                                         }
                                                     );
        for my $clustermetric (@dependent_clustermetric){
            $dependencies{$service_provider_name}->{'Service scope'}
                                                 ->{$clustermetric->clustermetric_label} = $clustermetric->getDependencies;
        }

        # Service related hierarchy

        my @dependent_nodemetric_combination = NodemetricCombination->search(
                                                                          hash => {
                                                                              nodemetric_combination_service_provider_id => $service_provider->getId
                                                                          }
                                                                      );


        my $id = $self->getId;
        LOOP:
        for my $nm_combi (@dependent_nodemetric_combination) {
            my @scom_indicator_ids = $nm_combi->getDependantIndicatorIds();
            for my $nm_indicator_id (@scom_indicator_ids) {
                if ($indicator_id == $nm_indicator_id) {
                    $dependencies{$service_provider_name}->{'Node scope'}
                                                 ->{$nm_combi->nodemetric_combination_label} = $nm_combi->getDependencies;
                    next LOOP;
                }
            }
        }
    }
    return \%dependencies;
}

sub delete {
    my $self = shift;
    my @related_scom_indicators = ScomIndicator->search(
                                                     hash => {
                                                         indicator_oid => $self->indicator_oid,
                                                     }
                                                 );

    # Service
    while (@related_scom_indicators) {
        my $indicator = pop @related_scom_indicators;
        # Node related hierarchy

        my $indicator_id          = $indicator->getId;
        my @dependent_clustermetric = Clustermetric->search(
                                                         hash => {
                                                             clustermetric_indicator_id => $indicator_id,
                                                         }
                                                     );
        while (@dependent_clustermetric) {
            (pop @dependent_clustermetric)->delete();
        }

        # Service related hierarchy

        my @dependent_nodemetric_combination = NodemetricCombination->search(
                                                                          hash => {
                                                                              nodemetric_combination_service_provider_id => $indicator->service_provider->getId
                                                                          }
                                                                      );


        my $id = $self->getId;
        LOOP:
        while (@dependent_nodemetric_combination) {
            my $nm_combi  = pop @dependent_nodemetric_combination;
            my @scom_indicator_ids = $nm_combi->getDependantIndicatorIds();
            for my $nm_indicator_id (@scom_indicator_ids) {
                if ($indicator_id == $nm_indicator_id) {
                    $nm_combi->delete();
                    next LOOP;
                }
            }
        }
        $indicator->delete();
    }
    return $self->SUPER::delete();
}

1;
