# Iptables1.pm - Iptables1 component
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 4 sept 2010

=head1 NAME

<Entity::Component::Iptables1> <Iptables1 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Iptables1> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Iptables1>;

my $component_instance_id = 2; # component instance id

Entity::Component::Iptables1->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Iptables1->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Iptables1 is class allowing to instantiate a Iptables1 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Iptables1;
use base "Entity::Component";

use strict;
use warnings;

#use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }

sub getConf {
    my $self = shift;
    my $conf = $self->getSecureRule();
    $conf->{iptables1_components}= $self->getComponentInstance();
    #$log->debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" . Dumper $conf);
    return $conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;
   #$log->debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" . Dumper $conf);
    my $iptables1_components= $self->{_dbix}->iptables1_sec_rule->iptables1_components;
    $iptables1_components->delete();
    my $components = $conf->{iptables1_components};
    my $conf1={};
    foreach my $rule ('iptables1_sec_rule_syn_flood','iptables1_sec_rule_scan_furtif','iptables1_sec_rule_ping_death','iptables1_sec_rule_anti_spoofing'){
        $conf1->{$rule}=$conf->{$rule};    
    }         
    $self->{_dbix}->iptables1_sec_rule->update($conf1);

        #create new rule component
        BOUCLE:
        foreach    my $component (@$components) {
            if ($component->{iptables1_component_cible} == 0 ) {
                next BOUCLE;
            }
            {
             $iptables1_components->create($component); 
            } 
        }              
}

sub getNetConf {
    #TODO return { port => [protocol] }
}

sub insertDefaultConfiguration {
    my $self = shift;
    my %args = @_;
    my $iptables1_sec_rule_conf = { 
        iptables1_sec_rule_syn_flood => 1,
        iptables1_sec_rule_scan_furtif => 0,
        iptables1_sec_rule_ping_death => 0,
        iptables1_sec_rule_anti_spoofing => 1,
#        iptables1_components => [
#        {
#             iptables1_component_cible => 1 
#        }
#        ]
    };
    $self->{_dbix}->create_related('iptables1_sec_rule',$iptables1_sec_rule_conf);
    #$self->{_dbix}->iptables1_sec_rule->create($iptables1_sec_rule_conf);
}

sub getSecureRule {
  my $self = shift;
    my %iptables_sec_rule = $self->{_dbix}->iptables1_sec_rule->get_columns(); 
    return \%iptables_sec_rule;     
}

sub getIptables1Component{
    my $self = shift;
    my @iptables1_components =();
    my $components_rs = $self->{_dbix}->iptables1_sec_rule->iptables1_components;
    while(my $component_instance = $components_rs->next) {
       push( @iptables1_components, $component_instance->get_column('iptables1_component_instance_id')); 
    }
    $log->debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" . Dumper \@iptables1_components);
   return \@iptables1_components;
}

sub getComponentInstance{
   my $self = shift;
   #my $var;
   my $cluster_id = $self->{_dbix}->get_column('cluster_id');
   my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);
   my $components = $cluster->getComponents(category => "all");  
   my $data_components = [];
    foreach my $element (values %$components) {
        my $netconf = $element->getNetConf();
        if(!defined($netconf)){
            next;
        }
       push @$data_components, {
                iptables1_component_instance_id => $element->{_dbix}->get_column('component_instance_id'),
	            component_name =>  $element->{_dbix}->component->get_column('component_name'),
	            component_checked => 0  
        }
    }                 
    my $iptables_components= $self->getIptables1Component();
    my $data=[];
    foreach my $component_instance (@$data_components){
            foreach my $iptables_component (@$iptables_components) {
	              if ($component_instance->{iptables1_component_instance_id} == $iptables_component){
	                  $component_instance->{component_checked} = 1;
	              }
	          
	        } 
	   push @$data, $component_instance ;
    }
return $data;     
}

sub getClusterIp{
    my  $self=shift;
    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => 1);
    my $clusteradmadresse = $cluster->getMasterNodeIp();
    return $clusteradmadresse;
   
}
1;

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.
=cut
