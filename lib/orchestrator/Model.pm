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
# Interface for a model that predict quality of service of and internet service

package Model;

use strict;
use warnings;
use Kanopya::Exceptions;


=head2 calculate
    
    Class : Public virtual (must be implemented by child)
    
    Desc :     Interface for calculating the quality of the Internet service
             (e.g. performance, availability, cost, etc.)
             according to underlying system configuration, workload characteristics and workload amount
    
    Args :
    
    Return :
    
=cut

sub calculate {
    my $self = shift;
    throw Kanopya::Exception::Internal(error => "Model interface method not implemented by " . ref $self);
}


1;