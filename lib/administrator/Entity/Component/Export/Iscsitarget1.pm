# Iscsitarget1.pm -Ietd (iscsi target) 1 server component (Adminstrator side)
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 5 august 2010

=head1 NAME

<Entity::Component::Export::Iscsitarget1> <Iscsitarget component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Export::Iscsitarget1> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Export::Iscsitarget1>;

my $component_instance_id = 2; # component instance id

Entity::Component::Export::Iscsitarget1->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Export::Iscsitarget1->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Export::Iscsitarget1 is class allowing to instantiate an Mysql5 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut
package Entity::Component::Export::Iscsitarget1;
use base "Entity::Component::Export";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

=head2 get
B<Class>   : Public
B<Desc>    : This method allows to get an existing Iscsitarget component.
B<args>    : 
    B<component_instance_id> : I<Int> : identify component instance 
B<Return>  : a new Entity::Component::Export::Iscsitarget1 from Kanopya Database
B<Comment>  : To modify configuration use concrete class dedicated method
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
	
=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
		$errmsg = "Entity::Component::Export::Iscsitarget1->get need an id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
   my $self = $class->SUPER::get( %args, table=>"ComponentInstance");
   return $self;
}

=head2 new
B<Class>   : Public
B<Desc>    : This method allows to create a new instance of Export component and concretly Iscsitarget1.
B<args>    : 
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component::Export::Iscsitarget1 from parameters.
B<Comment>  : Like all component, instantiate it creates a new empty component instance.
        You have to populate it with dedicated methods.
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
=cut

sub new {
	my $class = shift;
    my %args = @_;
	
	if ((! exists $args{cluster_id} or ! defined $args{cluster_id})||
		(! exists $args{component_id} or ! defined $args{component_id})){ 
		$errmsg = "Entity::Component::Export::Iscsitarget1->new need a cluster_id and a component_id named argument!";	
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# We create a new DBIx containing new entity
	my $self = $class->SUPER::new( %args);

    return $self;

}

=head2 
	
	Desc : 
	args: 

	return : a system image instance

=cut
=head2 AddTarget
B<Class>   : Public
B<Desc>    : This function add a new target entry into iscsitarget configuration.
B<args>    : 
    B<iscsitarget1_target_name> : I<String> : Identify component. Refer to component identifier table
    B<mountpoint> : I<String> : Identify cluster owning the component instance
    B<mount_option> : I<String> : Identify cluster owning the component instance
B<Return>  : Int : Targetid contained by iscsitarget component instance
B<Comment>  : None
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
=cut
sub addTarget {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name}) ||
		(! exists $args{mountpoint} or ! defined $args{mountpoint}) ||
		(! exists $args{mount_option} or ! defined $args{mount_option})) {
		$errmsg = "Component::Export::Iscsitarget1->addTarget needs a iscsitarget1_targetname and mountpoint named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $iscsitarget1_rs = $self->{_dbix}->iscsitarget1_targets;
	my $res = $iscsitarget1_rs->create(\%args);
	$log->info("New target <$args{iscsitarget1_target_name}> added with mount point <$args{mountpoint}> and options <$args{mount_option}> and return " .$res->get_column("iscsitarget1_target_id"));
	return $res->get_column("iscsitarget1_target_id");
}

=head2 AddLun
	
	Desc : This function a new lun to a target.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
	return : a system image instance

=cut
sub addLun {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) ||
		(! exists $args{iscsitarget1_lun_number} or ! defined $args{iscsitarget1_lun_number}) ||
		(! exists $args{iscsitarget1_lun_device} or ! defined $args{iscsitarget1_lun_device}) ||
		(! exists $args{iscsitarget1_lun_typeio} or ! defined $args{iscsitarget1_lun_typeio}) ||
		(! exists $args{iscsitarget1_lun_iomode} or ! defined $args{iscsitarget1_lun_iomode})) {
		$errmsg = "Component::Export::Iscsitarget1->addLun needs a iscsitarget1_target_id, iscsitarget1_lun_number, iscsitarget1_lun_device, iscsitarget1_lun_typeio and iscsitarget1_lun_iomode named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$log->debug("New Lun try to be added with iscsitarget1_target_id $args{iscsitarget1_target_id} iscsitarget1_lun_number $args{iscsitarget1_lun_number} iscsitarget1_lun_device $args{iscsitarget1_lun_device}" );
	my $iscsitarget1_lun_rs = $self->{_dbix}->iscsitarget1_targets->single( {iscsitarget1_target_id => $args{iscsitarget1_target_id}})->iscsitarget1_luns;

	my $res = $iscsitarget1_lun_rs->create(\%args);
	$log->info("New Lun <$args{iscsitarget1_lun_device}> added");
	return $res->get_column('iscsitarget1_lun_id');
}

sub getTargetIdLike {
	my $self = shift;
    my %args = @_;

	if (! exists $args{iscsitarget1_target_name} or ! defined $args{iscsitarget1_target_name}) {
		$errmsg = "Component::Export::Iscsitarget1->getTargetId needs a iscsitarget1_target_name named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->iscsitarget1_targets->search({iscsitarget1_target_name => {-like => $args{iscsitarget1_target_name}}})->first()->get_column('iscsitarget1_target_id');
}

sub getLunId {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id})||
		(! exists $args{iscsitarget1_lun_device} or ! defined $args{iscsitarget1_lun_device})) {
		$errmsg = "Component::Export::Iscsitarget1->getLun needs an iscsitarget1_target_id and an iscsitarget1_lun_device named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->iscsitarget1_luns->first({ iscsitarget1_lun_device=> $args{iscsitarget1_lun_device}})->get_column('iscsitarget1_lun_id');
	
}

sub removeLun {
	my $self = shift;
	my %args  = @_;
	if ((! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id})||
		(! exists $args{iscsitarget1_lun_id} or ! defined $args{iscsitarget1_lun_id})) {
		$errmsg = "Component::Export::Iscsitarget1->removeLun needs an iscsitarget1_lun_id and an iscsitarget1_target_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->iscsitarget1_luns->find($args{iscsitarget1_lun_id})->delete();
}

sub removeTarget{
	my $self = shift;
	my %args  = @_;	
	if (! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) {
		$errmsg = "Component::Export::Iscsitarget1->removeTarget needs an iscsitarget1_target_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->delete();	
}

sub getTarget {
	my $self = shift;
	my %args  = @_;	
	if (! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) {
		$errmsg = "Component::Export::Iscsitarget1->getTarget needs an iscsitarget1_target_id named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $target_raw = $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id});
	my $export ={};
	$export->{target} = $target_raw->get_column('iscsitarget1_target_name');
	$export->{mountpoint} = $target_raw->get_column('mountpoint');
	$export->{mount_option} = $target_raw->get_column('mount_option');

	return $export;
}

# return a data structure to pass to the template processor 
sub getTemplateData {
	my $self = shift;
	my $data = {};
	my $targets = $self->{_dbix}->iscsitarget1_targets;
	$data->{targets} = [];
	while (my $onetarget = $targets->next) {
		my $record = {};
		$record->{target_name} = $onetarget->get_column('iscsitarget1_target_name');
		$record->{luns} = [];
		my $luns = $onetarget->iscsitarget1_luns->search();
		while(my $onelun = $luns->next) {
			push @{$record->{luns}}, { 
				number => $onelun->get_column('iscsitarget1_lun_number'),
				device => $onelun->get_column('iscsitarget1_lun_device'),
				type => $onelun->get_column('iscsitarget1_lun_typeio'),
				iomode => $onelun->get_column('iscsitarget1_lun_iomode'),
			}; 
		}
		push @{$data->{targets}}, $record;
	}
	 
	return $data;	  
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
