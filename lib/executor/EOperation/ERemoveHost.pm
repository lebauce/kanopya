# ERemoveHost.pm - Operation class implementing Host creation operation

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

EEntity::Operation::EAddHost - Operation class implementing Host creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Host creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::ERemoveHost;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;

use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

    my $op = EEntity::EOperation::ERemoveHost->new();

EEntity::Operation::ERemoveHost->new creates a new RemoveMotheboard operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
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
    
    # check if host is not active
    $log->debug("checking host active value <$args{params}->{host_id}>");
       if($self->{_objs}->{host}->getAttr(name => 'active')) {
            $errmsg = "EOperation::ERemoveHost->prepare : host $args{params}->{host_id} is still active";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
    }

}


=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    if ((! exists $args{internal_cluster} or ! defined $args{internal_cluster})) { 
        $errmsg = "ERemoveHost->prepare need an internal_cluster named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    $log->debug("After Eoperation prepare and before get Administrator singleton");
    my $params = $self->_getOperation()->getParams();

    $self->{_objs} = {};
    $self->{nas} = {};
    $self->{executor} = {};

    # Instantiate host and so check if exists
    $log->debug("checking host existence with id <$params->{host_id}>");
    eval {
        $self->{_objs}->{host} = Entity::Host->get(id => $params->{host_id});
    };
    if($@) {
        $errmsg = "EOperation::ERemoveHost->prepare : host_id $params->{host_id} not found";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "EOperation::ERemoveHost->checkOp failed :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    ## Instanciate Clusters
    # Instanciate nas Cluster 
    $self->{nas}->{obj} = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{nas});
    # Instanciate executor Cluster
    $self->{executor}->{obj} = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{executor});

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
    my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
                                         version => "2");
    $log->debug("Value return by getcomponent ". ref($tmp));
    $self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
    
}

sub execute{
    my $self = shift;
    $self->SUPER::execute();
    my ($powersupplycard,$powersupplyid);

    my $powersupplycard_id = $self->{_objs}->{host}->getPowerSupplyCardId();
    if ($powersupplycard_id) {
        $powersupplycard = Entity::Powersupplycard(id => $powersupplycard_id);
        $powersupplyid = $self->{_objs}->{host}->getAttr(name => 'host_powersupply_id');
    }
    $self->{_objs}->{component_storage}->removeDisk(name => $self->{_objs}->{host}->getEtcName(), econtext => $self->{nas}->{econtext});
    $self->{_objs}->{host}->delete();
    if ($powersupplycard_id){
        $log->debug("Deleting powersupply with id <$powersupplyid> on the card : <$powersupplycard>");
        $powersupplycard->delPowerSupply(powersupply_id => $powersupplyid);
    }
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
