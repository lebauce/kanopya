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

Anomaly detection algorithm implementation

=end classdoc

=cut

package AnomalyDetection;

use strict;
use warnings;


=pod
=begin classdoc

Compute an anomaly detection score. A score close to 0 means no anomaly detected.

=end classdoc
=cut

sub detect {
    throw Kanopya::Exceptions::NotImplemented();
}

1;
