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
package ActionType;
use strict;
use warnings;
use ActionTypeParameter;
use base 'BaseDB';

use constant ATTR_DEF => {
    action_type_name           =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
};



sub getAttrDef { return ATTR_DEF; }

sub new {
    my ($class, %args) = @_;
    
    General::checkParams(args => \%args, required => ['action_type_name','action_type_parameter_names']);
    
    my $self = $class->SUPER::new(
        action_type_name => $args{action_type_name},
    );
    
    my $action_type_parameter_names = $args{action_type_parameter_names};
    
    my $my_id = $self->getAttr('name' => 'action_type_id');
    
    foreach my $action_type_parameter_name (@$action_type_parameter_names){
        ActionTypeParameter->new(
            action_type_parameter_action_type_id => $my_id,
            action_type_parameter_name           => $action_type_parameter_name,
        );
    }
    
    return $self;
}
1;