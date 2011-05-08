# ERemoveSystemimage.pm - Operation class implementing System image deletion operation

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

EOperation::ERemoveSystemimage - Operation class implementing System image deletion operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image deletion operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::ERemoveSystemimage;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use EFactory;
use Kanopya::Exceptions;
use Entity::Cluster;
use Entity::Systemimage;

our $VERSION = '1.00';
my $log = get_logger("executor");
my $errmsg;


=head2 new

    my $op = EOperation::ERemoveSystemimage->new();

EOperation::ERemoveSystemimage->new creates a new ERemoveSystemimage operation.

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
    
    
    # check if systemimage is not active
    $log->debug("checking systemimage active value <".$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id').">");
   	if($self->{_objs}->{systemimage}->getAttr(name => 'active')) {
	    	$errmsg = "EOperation::ERemoveSystemiamge->new : systemimage <". $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id') ."> is already active";
	    	$log->error($errmsg);
	    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

=head2 prepare

	$op->prepare();

=cut

sub prepare {
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "EAddSystemimage->prepare need an internal_cluster named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $params = $self->_getOperation()->getParams();

	$self->{_objs} = {};
	$self->{nas} = {};
	$self->{executor} = {};

#### Get instance of Systemimage Entity
	$log->info("Load systemimage instance");
    eval {
	   $self->{_objs}->{systemimage} = Entity::Systemimage->get(id => $params->{systemimage_id});
    };
    if($@) {
        my $err = $@;
    	$errmsg = "EOperation::EActivateSystemimage->prepare : systemimage_id $params->{systemimage_id} does not find\n" . $err;
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
	$log->debug("get systemimage self->{_objs}->{systemimage} of type : " . ref($self->{_objs}->{systemimage}));

    ### Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
		$errmsg = "Operation ActivateSystemimage failed an error occured :\n$error";
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
		
	## Instanciate Component needed (here LVM on nas cluster)
	# Instanciate Cluster Storage component.
	my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
										 version => "2");
	
	$self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
}

sub execute{
	my $self = shift;
	$self->SUPER::execute();
		
	my $devs = $self->{_objs}->{systemimage}->getDevices();
	my $etc_name = 'etc_'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name');
	my $root_name = 'root_'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name');
	
	# creation of etc and root devices based on distribution devices
	$log->info("etc device deletion for systemimage");
	$self->{_objs}->{component_storage}->removeDisk(name => $etc_name, econtext => $self->{nas}->{econtext});

	$log->info("etc device deletion for systemimage");													
	$self->{_objs}->{component_storage}->removeDisk(name => $root_name, econtext => $self->{nas}->{econtext});
	
	# TODO update vg freespace
		
	$self->{_objs}->{systemimage}->delete();
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