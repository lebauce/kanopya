# EAddMotherboard.pm - Operation class implementing Motherboard creation operation

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
# Created 14 july 2010

=head1 NAME

EEntity::Operation::EAddMotherboard - Operation class implementing Motherboard creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EAddMotherboard;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;
use Template;
use Log::Log4perl "get_logger";
use Data::Dumper;

use Entity::Motherboard;
use Entity::Cluster;
use Entity::Kernel;
use Entity::Motherboardmodel;
use Entity::Processormodel;
use Entity::Powersupplycard;
use Entity::Gp;
use ERollback;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

    my $op = EEntity::EOperation::EAddMotherboard->new();

EEntity::Operation::EAddMotherboard->new creates a new AddMotheboard operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

    $op->_init() is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;

    return;
}

sub checkOp{
    my $self = shift;
    my %args = @_;
    
   # check if kernel_id exist
    $log->debug("checking kernel existence with id <$args{params}->{kernel_id}>");
    eval {
          Entity::Kernel->get(id => $self->{_objs}->{motherboard}->getAttr(name=>'kernel_id'));
        };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddMotherboard->prepare : Wrong kernel_id attribute detected <". $self->{_objs}->{motherboard}->getAttr(name=>'kernel_id') .">\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    
    # check if motherboard_model_id exist
    $log->debug("checking motherboard model existence with id <".$self->{_objs}->{motherboard}->getAttr(name=>'motherboardmodel_id').">");
    eval {
          Entity::Motherboardmodel->get(id => $self->{_objs}->{motherboard}->getAttr(name=>'motherboardmodel_id'));
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddMotherboard->prepare : Wrong motherboardmodel_id attribute detected <". $self->{_objs}->{motherboard}->getAttr(name=>'motherboardmodel_id') .">\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    
    # check if processor_model_id exist
    $log->debug("checking processor model existence with id <".$self->{_objs}->{motherboard}->getAttr(name=>'processormodel_id').">");
    eval {
         Entity::Processormodel->get(id => $self->{_objs}->{motherboard}->getAttr(name=>'processormodel_id'));
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddMotherboard->prepare : Wrong processormodel_id attribute detected <". $self->{_objs}->{motherboard}->getAttr(name=>'processormodel_id') .">\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    
    # check mac address unicity
    $log->debug("checking unicity of mac address <".$self->{_objs}->{motherboard}->getAttr(name=>'motherboard_mac_address'). ">");
    if (defined Entity::Motherboard->getMotherboard(hash => {motherboard_mac_address => $self->{_objs}->{motherboard}->getAttr(name=>'motherboard_mac_address')})){
        $errmsg = "Operation::AddMotherboard->new : motherboard_mac_address ". $self->{_objs}->{motherboard}->getAttr(name=>'motherboard_mac_address') ." already exist";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    if (defined $self->{_objs}->{powersupplyport_number}){
    # Check power supply
    # Search if there is a power supply defined
        if ($self->{_objs}->{powersupplycard}->isPortUsed(powersupplyport_number => $self->{_objs}->{powersupplyport_number})){
            $errmsg = "Operation::AddMotherboard->new : This power supply port is already recorded!";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    }
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => ["internal_cluster"]);
    
    $log->debug("After Eoperation prepare and before get Administrator singleton");
    my $adm = Administrator->new();
    my $params = $self->_getOperation()->getParams();

    $self->{_objs} = {};
    $self->{nas} = {};
    $self->{executor} = {};
    
    # First review params 
    ## Put in lowcase mac address
    $params->{motherboard_mac_address} = lc($params->{motherboard_mac_address});
    ## When powersupply is used, we save value in Operation to use %$params to instantiate motherboard
    if ((exists $params->{powersupplycard_id} && defined $params->{powersupplycard_id})&&
        ( exists $params->{powersupplyport_number} && defined $params->{powersupplyport_number})){
        $log->debug("powersupplyport_number <$params->{powersupplyport_number}> powersupplycard_id <$params->{powersupplycard_id}>");
        $self->{_objs}->{powersupplyport_number} = $params->{powersupplyport_number};
        eval {
          $self->{_objs}->{powersupplycard} = Entity::Powersupplycard->get(id => $params->{powersupplycard_id});
        };
        if($@) {
           my $err = $@;
           $errmsg = "EOperation::EAddMotherboard->prepare : Wrong powersupplycard_id attribute detected <$params->{powersupplycard_id}>\n" . $err;
           $log->error($errmsg);
           throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
        $log->debug("Power supply card instanciated with id $params->{powersupplycard_id}");
        # We delete the motherboard_powersupply_id entry to create properly in execute
    }
    if (defined $params->{powersupplycard_id}){delete $params->{powersupplycard_id};}
    if (defined $params->{powersupplyport_number}){delete $params->{powersupplyport_number};}

    # Instanciate new Motherboard Entity
#    $log->debug("checking motherboard validity with params" . Dumper %$params);
    eval {
        $self->{_objs}->{motherboard} = Entity::Motherboard->new(%$params);
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddMotherboard->prepare : Wrong motherboard attributes detected\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation EAddMotherboard failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    ## Instanciate Clusters
    # Instanciate nas Cluster 
    $self->{nas}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{nas});
    # Instanciate executor Cluster
    $self->{executor}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{executor});
    
    ## Get Internal IP
    # Get Internal Ip address of Master node of cluster Executor
    my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
    # Get Internal Ip address of Master node of cluster nas
    my $nas_ip = $self->{nas}->{obj}->getMasterNodeIp();
        
    ## Instanciate context 
    # Get context for nas
    $self->{nas}->{econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $nas_ip);
    
    ## Instanciate Component needed (here LVM and ISCSITARGET on nas cluster)
    # Instanciate Cluster Storage component.
    my $tmp = $self->{nas}->{obj}->getComponent(name       => "Lvm",
                                                version    => "2");
    $log->debug("Value return by getcomponent ". ref($tmp));
    $self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
    $log->debug("Load Lvm component version 2, it ref is " . ref($self->{_objs}->{component_storage}));
    # Instanciate Cluster Export component.
    $self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
                                                                                      version=> "1"));
    $log->debug("Load Iscsitarget component version 1, it ref is " . ref($self->{_objs}->{component_export}));
    
}

sub execute{
    my $self = shift;

    my $adm = Administrator->new();
    #TODO Reflechir ou positionne-t-on nos prises de decisions arbitraires (taille d un disque etc, filesystem, ...) dans les objet en question ou dans les operations qui les utilisent
    my $etc_id = $self->{_objs}->{component_storage}->createDisk(name       => $self->{_objs}->{motherboard}->getEtcName(),
                                                                 size        => "52M", 
                                                                 filesystem  => "ext3",
                                                                 econtext    => $self->{nas}->{econtext},
                                                                 erollback   => $self->{erollback});
        $self->{_objs}->{motherboard}->setAttr(name=>'etc_device_id', value=>$etc_id);
        
        $log->info("Motherboard <".$self->{_objs}->{motherboard}->getAttr(name=>"motherboard_mac_address") ."> etc disk is now created");
        if ((exists $self->{_objs}->{powersupplycard} and defined $self->{_objs}->{powersupplycard})&&
            (exists $self->{_objs}->{powersupplyport_number} and defined $self->{_objs}->{powersupplyport_number})){
            my $powersupplycard_id = 1;
            my $powersupply_id = $self->{_objs}->{powersupplycard}->addPowerSupplyPort(powersupplyport_number => $self->{_objs}->{powersupplyport_number});
            $self->{_objs}->{motherboard}->setAttr(name=>'motherboard_powersupply_id', value=>$powersupply_id);
            
        }

        # set initial state to down
        $self->{_objs}->{motherboard}->setAttr(name => 'motherboard_state', value => 'down:'.time);

        # AddMotherboard finish, just save the Entity in DB
        $self->{_objs}->{motherboard}->save();
        my @group = Entity::Gp->getGroups(hash => {gp_name=>'Motherboard'});
        $group[0]->appendEntity(entity => $self->{_objs}->{motherboard});
        $log->info("Motherboard <".$self->{_objs}->{motherboard}->getAttr(name=>"motherboard_mac_address") ."> is now created");

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