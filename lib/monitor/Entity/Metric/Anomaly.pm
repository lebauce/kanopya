#    Copyright © 2014 Hedera Technology SAS
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


=pod

=begin classdoc

Anomaly is a metric related to another metric.
It corresponds to the related metric anomaly score computation

=end classdoc

=cut

package Entity::Metric::Anomaly;
use base Entity::Metric;
use AnomalyDetection;

use constant ATTR_DEF => {
    related_metric_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

Anomaly is a metric stored in rrd.
The (key,value) (store,'rrd') is added to the args

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;
    $args{store} = 'rrd';
    return $class->SUPER::new(%args);
}


=pod
=begin classdoc

Label on an anomaly

@return string label

=end classdoc
=cut

sub label {
    my $self = shift;
    return 'Anomalies of ' . $self->related_metric->label;
}


=pod
=begin classdoc

Compute an anomaly score w.r.t. given values

@param values Array of values

@return float anomaly score

=end classdoc
=cut

sub computeAnomaly {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['values']);
    return AnomalyDetection->detect(values => $args{values});
}

1;
