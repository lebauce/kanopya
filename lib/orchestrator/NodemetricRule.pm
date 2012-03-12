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
package NodemetricRule;

use strict;
use warnings;
use base 'BaseDB';
use Data::Dumper;
use NodemetricCondition;
use Entity::ServiceProvider::Outside::Externalcluster;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("orchestrator");

use constant ATTR_DEF => {
    nodemetric_rule_id        =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    nodemetric_rule_label     =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_formula   =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_last_eval =>  {pattern       => '^(0|1)$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_timestamp =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_state     =>  {pattern       => '(enabled|disabled|disabled_temp)$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_action_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_service_provider_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }


sub toString{
    my $self = shift;
    my $formula = $self->getAttr(name => 'nodemetric_rule_formula');
    my @array = split(/(id\d+)/,$formula);
    for my $element (@array) {
        
        if( $element =~ m/id(\d+)/)
        {
            $element = NodemetricCondition->get('id'=>substr($element,2))->toString();
        }
     }
     return "@array";
};

#C/P of homonym method in AggregateRulePackage 
sub getDependantConditionIds {
    my $self = shift;
    my $formula = $self->getAttr(name => 'nodemetric_rule_formula');
    my @array = split(/(id\d+)/,$formula);
    
    my @conditionIds;
    
    for my $element (@array) {
        if( $element =~ m/id\d+/)
        {
            push @conditionIds, substr($element,2);
        }
    }
    return @conditionIds;
}

sub evalOnOneNode{
    my $self = shift;
    my %args = @_;
    
    my $monitored_values_for_one_node = $args{monitored_values_for_one_node};
    
    my $formula = $self->getAttr(name => 'nodemetric_rule_formula');

    #Split nodemetric_rule id from $formula
    my @array = split(/(id\d+)/,$formula);
    
    #replace each id by its evaluation
    for my $element (@array) {
        
        if( $element =~ m/id(\d+)/){
            $element = NodemetricCondition->get('id'=>substr($element,2))
                                          ->evalOnOneNode(
                                            'monitored_values_for_one_node' => $monitored_values_for_one_node
                                          );
            if(not defined $element){
                return undef;
            }
           
        }
    }
    my $res = undef;
    my $arrayString = '$res = '."@array"; 
    
    print $arrayString."\n";
    #Evaluate the logic formula
    eval $arrayString;
    my $store = ($res)?1:0;
    return $res;
};

sub isVerifiedForANode{
    my $self = shift;
    my %args = @_;
    
    my $externalcluster_id  = $args{externalcluster_id};
    my $externalnode_id     = $args{externalnode_id};
    
    my $row = $self->{_dbix}
        ->verified_noderules
        ->find({
            verified_noderule_externalnode_id    => $externalnode_id,
        });
    if(defined $row){
        return 1;
    }else{
        return 0;
    }
    
};

sub deleteVerifiedRule  {
    my $self = shift;
    my %args = @_;
    
    my $hostname   = $args{hostname};
    my $cluster_id = $args{cluster_id};

    # GET THE EXTERNAL NODE ID    
    # note : externalcluster_name is UNIQUE !
    
    my $extcluster = Entity::ServiceProvider::Outside::Externalcluster->get('id' => $cluster_id);
    
    my $extnodes = $extcluster->getNodes();
    
    my $externalnode_id;
    
    foreach my $extnode (@$extnodes) {
        if($extnode->{hostname} eq $hostname) {
            $externalnode_id = $extnode->{id};
        }
    }
    
    if(not defined $externalnode_id){
        die assert("UNKOWN node $hostname in cluster $cluster_id");
    }else{
        print "** try to delete $externalnode_id **\n";
            my $verified_rule_dbix = 
                    $self->{_dbix}
                ->verified_noderules
                ->find({
                    verified_noderule_externalnode_id    => $externalnode_id,
                });
            if(defined $verified_rule_dbix){
                print "** delete $externalnode_id **\n";
                $verified_rule_dbix->delete();
            } else {
                print "** not here $externalnode_id **\n";

            }
    }
}

sub setVerifiedRule{
    my $self = shift;
    my %args = @_;
    
    my $hostname   = $args{hostname};
    my $cluster_id = $args{cluster_id};

    # GET THE EXTERNAL NODE ID    
    # note : externalcluster_name is UNIQUE !
    
    my $extcluster = Entity::ServiceProvider::Outside::Externalcluster->get('id' => $cluster_id);
    
    my $extnodes = $extcluster->getNodes();
    
    my $externalnode_id;
    
    foreach my $extnode (@$extnodes) {
        if($extnode->{hostname} eq $hostname) {
            $externalnode_id = $extnode->{id};
        }
    }
    
    if(not defined $externalnode_id){
        die assert("UNKOWN node $hostname in cluster $cluster_id");
    }else{
        print "** $externalnode_id **\n";
        $self->{_dbix}
                ->verified_noderules
                ->update_or_create({
                    verified_noderule_externalnode_id    => $externalnode_id,
                });
    }
}



1;
