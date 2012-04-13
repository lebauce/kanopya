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
package Action;
use strict;
use warnings;
use ActionParameter;
use ActionType;
use Data::Dumper;
use base 'BaseDB';

# logger
#use Log::Log4perl "get_logger";
#my $log = get_logger("monitor");

use constant ATTR_DEF => {
    action_service_provider_id      =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    action_name                     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    action_action_type_id           =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0}
};



sub getAttrDef { return ATTR_DEF; }

sub getParams {
    my ($self) = @_;
    my %params;
    my @params_insts = ActionParameter->search(
        hash => {
            action_parameter_action_id => $self->getAttr('name' => 'action_id')
        }
    );
    foreach my $param_inst (@params_insts){
        $params{$param_inst->getAttr(name => 'action_parameter_name')} = $param_inst->getAttr(name => 'action_parameter_value');
    }
     
    return \%params;
};

sub setParams {
    my ($self,%args) = @_;
	
	while (my ($action_name, $action_value) = each(%args)) {
		my $action_parameter = ActionParameter->find(
			hash => {
				action_parameter_action_id => $self->getAttr('name' => 'action_id'),
				action_parameter_name => $action_name,
			}
        );
        $action_parameter->setAttr(name => 'action_parameter_value', value=>$action_value);
        $action_parameter->save();
	}    
};

sub createNewActionType{
    my (%args) = @_;
    
    General::checkParams(args => \%args, required => ['action_type_name','action_type_parameter_names']);
    
    my $action_type = ActionType->new(
        action_type_name             => $args{action_type_name},
        action_type_parameter_names => $args{action_type_parameter_names},
    );
    return $action_type;
}

sub removeActionType{
    my (%args) = @_;
    General::checkParams(args => \%args, required => ['action_type_id']);
    my $action_type = ActionType->get('id' => $args{action_type_id});
    $action_type->delete();
}
1;