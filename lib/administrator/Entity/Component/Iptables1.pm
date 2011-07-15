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

=head2 new
B<Class>   : Public
B<Desc>    : This method allows to create a new instance of Firewall component and concretly Iptables1.
B<args>    : 
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component::Iptables1 from parameters.
B<Comment>  : Like all component, instantiate it creates a new empty component instance.
        You have to populate it with dedicated methods.
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
    
=cut

sub new {
    my $class = shift;
    my %args = @_;

    # We create a new DBIx containing new entity
    my $self = $class->SUPER::new( %args);
    return $self;

}

sub getConf {
    my $self = shift;

    my $conf = $self->getSecureRule();
    $conf->{iptables1_sec_rule_syn_flood } = $conf->{iptables1_sec_rule_syn_flood};
    $conf->{iptables1_sec_rule_scan_furtif} = $conf->{iptables1_sec_rule_scan_furtif};
    $conf->{iptables1_sec_rule_ping_mort} = $conf->{iptables1_sec_rule_ping_mort};
    $conf->{iptables1_sec_rule_anti_spoofing } = $conf->{iptables1_sec_rule_anti_spoofing};
   
    return $conf;
}

sub getSecureRule {
  my $self = shift;
    my %iptables_sec_rule = $self->{_dbix}->iptables1_sec_rule->get_columns(); 
    return \%iptables_sec_rule;     
}
sub getSecureComponenet{
    my $self = shift;
    my $component = $self->{_dbix}->iptables1_component->first; 
    my $iptables1_component={};
    $iptables1_component->{component_instance_id}= $component-> get_column('component_instance_id');
    $iptables1_component->{iptables1_component_cible}= $component-> get_column('iptables1_component_cible');
    
    return $iptables1_component;      
}






sub setConf {
    my $self = shift;
    my ($conf) = @_;
      
    $self->{_dbix}->iptables1_sec_rule->update($conf);
    $self->{_dbix}->iptables1_component->update($conf);
}

sub getNetConf {

    #TODO return { port => [protocol] }
 
}

sub insertDefaultConfiguration {
    my $self = shift;
    my %args = @_;
    my $iptables1_sec_rule_conf = { 
        iptables1_sec_rule_syn_flood =>0,
        iptables1_sec_rule_scan_furtif =>0,
        iptables1_sec_rule_ping_mort =>1,
        iptables1_sec_rule_anti_spoofing => 1
    };
     $self->{_dbix}->create_related('iptables1_sec_rule', $iptables1_sec_rule_conf);
   

}

sub getSecureTableConf{
    my $self = shift;
    my %args = @_;
    my $secure = {};
    $self->{_dbix}->iptables1_sec_rule
       
}




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

1;
