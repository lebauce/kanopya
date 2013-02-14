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

package DataModelSelector;

use warnings;
use strict;
use Data::Dumper;
use BaseDB;

# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

my @model_classes = ('Entity::DataModel::LinearRegression',
                     'Entity::DataModel::LogarithmicRegression'
                    );

sub selectDataModel {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['combination', 'start_time', 'end_time'],
                         optional => { 'node_id' => undef });

    my %data = $args{combination}->computeValues(start_time => $args{start_time},
                                                 stop_time  => $args{end_time},
                                                 node_id    => $args{node_id});

    my @models;
    my @RSquareds;

    # Configure all DataModels available
    for my $data_model_class (@model_classes) {

        BaseDB::requireClass($data_model_class);

        my $model = $data_model_class->new(
                        node_id        => $args{node_id},
                        combination_id => $args{combination}->id,
                    );

        $model->configure(data       => \%data,
                          start_time => $args{start_time},
                          end_time   => $args{end_time});

        push @models, $model;
        push @RSquareds, $model->getRSquared();
        $log->info("$data_model_class -> R = ".($model->getRSquared())."\n");
    }

    my $max_model    = shift @models;
    my $max_RSquared = shift @RSquareds;

    # Choose the DataModem with maximal RSquared, delete all the others
    while (my $current_model = shift @models) {

        my $current_RSquare = shift @RSquareds;

        if ($current_RSquare > $max_RSquared) {
             $max_RSquared = $current_RSquare;
             $max_model->delete();
             $max_model = $current_model;
        }
        else {
            $current_model->delete();
        }
    }
    $log->info('Best model id '.($max_model->id));
    return $max_model;
}

1;
