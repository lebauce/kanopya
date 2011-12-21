# HostSelector.pm - Select better fit host according to context, constraints and choice policy

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

package DecisionMaker::HostSelector;

use strict;
use warnings;
use Kanopya::Exceptions;
use General;

=head2 getHost
    
    Class : Public
    
    Desc :  Select and return the more suitable host according to constraints
     
    Args :  type :  array ref of host type ordered by preference
                    type can be 'phys' or 'virt'
            core : min number of desired core
            ram  : min amount of desired ram
            
    Return : Entity::Host
    
=cut

sub getHost {
    my $self = shift;
    my %args = @_;
    
    print "GETHOST\n";
}

1;