# EAddVirtualHost.pm - Operation class implementing Virtual Machine creation operation

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

EEntity::Operation::EAddVirtualHost - Operation class implementing Virutal machine creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Virutal machine creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EAddVirtualHost;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;
use Template;
use Log::Log4perl "get_logger";
use Data::Dumper;

use Entity::Host;
use Entity::Cluster;
use Entity::Gp;
use Operation;
use ERollback;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

    my $op = EEntity::EOperation::EAddVirtualHost->new();

EEntity::Operation::EAddVirtualHost->new creates a new AddMotheboard operation.

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
	
    # Instanciate the pre created Host Entity
    eval {
        $self->{_objs}->{host} = Entity::Host->get(id => $params->{host_id} );
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddVirtualHost->prepare : No host found with id $params->{host_id}\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # Instanciate target cluster
    eval {
        $self->{_objs}->{cluster} = Entity::Cluster->get(id => $params->{cluster_id} );
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddVirtualHost->prepare : No cluster found with id $params->{target_cluster_id}\n" . $err;
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
    
    ## Instanciate LVM Component
    # Instanciate Cluster Storage component.
    my $tmp = $self->{nas}->{obj}->getComponent(name       => "Lvm",
                                                version    => "2");
   
    $self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
    $log->debug("Load Lvm component version 2, it ref is " . ref($self->{_objs}->{component_storage}));
    
}

sub execute {
    my $self = shift;
    my $adm = Administrator->new();
    
    my $etc_id = $self->{_objs}->{component_storage}->createDisk(
		name       => $self->{_objs}->{host}->getEtcName(),
        size       => "52M", 
        filesystem => "ext3",
        econtext   => $self->{nas}->{econtext},
        erollback  => $self->{erollback}
    );
	$self->{_objs}->{host}->setAttr(name=>'etc_device_id', value=>$etc_id);
	
	$log->info("Host <".$self->{_objs}->{host}->getAttr(name=>"host_mac_address") ."> etc disk is now created");
	
	# AddHost finish, just save the Entity in DB
	$self->{_objs}->{host}->save();
	my @group = Entity::Gp->getGroups(hash => {gp_name=>'Host'});
	$group[0]->appendEntity(entity => $self->{_objs}->{host});
	$log->info("Virtual Host <".$self->{_objs}->{host}->getAttr(name=>"host_mac_address") ."> is now created");

	Operation->enqueue( 
		type     => 'PreStartNode',
		priority => 100,
		params   => {  
			host_id    => $self->{_objs}->{host}->getAttr(name => 'host_id'),
			cluster_id => $self->{_obj}->{cluster}->getAttr(name => 'cluster_id'),
		}
	);

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
