package Entity::Distribution;

use strict;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use base "Entity";
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	distribution_name => {pattern => "//", is_mandatory => 1, is_extended => 0},
	distribution_version => {pattern => "//", is_mandatory => 1, is_extended => 0},
	distribution_desc => {pattern => "//", is_mandatory => 1, is_extended => 0},
	etc_device_id => {pattern => "//", is_mandatory => 1, is_extended => 0},
	root_device_id => {pattern => "//", is_mandatory => 1, is_extended => 0}
};

=head new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})) { 
		$errmsg = "Entity::Distribution->new need a data and rightschecker named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $ext_attrs = $args{ext_attrs};
	delete $args{ext_attrs};
    my $self = $class->SUPER::new( %args );
	$self->{_ext_attrs} = $ext_attrs;
	$self->{extension} = $self->extension();
    return $self;
}

=head getDevices 

get etc and root device attributes for this distribution

=cut

sub getDevices {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Distribution->getDevices must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	
	my $etcrow = $self->{_dbix}->etc_device_id;
	my $rootrow = $self->{_dbix}->root_device_id;
	my $devices = {
		etc => { lv_id => $etcrow->get_column('lvm2_lv_id'), 
				 lvname => $etcrow->get_column('lvm2_lv_name'),
				 lvsize => $etcrow->get_column('lvm2_lv_size'),
				 lvfreespace => $etcrow->get_column('lvm2_lv_freespace'),	
				 filesystem => $etcrow->get_column('lvm2_lv_filesystem'),
				 vg_id => $etcrow->get_column('lvm2_vg_id'),
				 vgname => $etcrow->lvm2_vg_id->get_column('lvm2_vg_name'),
				 vgsize => $etcrow->lvm2_vg_id->get_column('lvm2_vg_size'),
				 vgfreespace => $etcrow->lvm2_vg_id->get_column('lvm2_vg_freespace'),
				},
		root => { lv_id => $rootrow->get_column('lvm2_lv_id'), 
				 lvname => $rootrow->get_column('lvm2_lv_name'),
				 lvsize => $rootrow->get_column('lvm2_lv_size'),
				 lvfreespace => $rootrow->get_column('lvm2_lv_freespace'),	
				 filesystem => $rootrow->get_column('lvm2_lv_filesystem'),
				 vg_id => $rootrow->get_column('lvm2_vg_id'),
				 vgname => $rootrow->lvm2_vg_id->get_column('lvm2_vg_name'),
				 vgsize => $rootrow->lvm2_vg_id->get_column('lvm2_vg_size'),
				 vgfreespace => $rootrow->lvm2_vg_id->get_column('lvm2_vg_freespace'),
		}
	};
	$log->info("Distribution etc and root devices retrieved from database");
	return $devices;
}

=head getProvidedComponents

get components provided by this distribution
return array ref containing hash ref 

=cut

sub getProvidedComponents {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Distribution->getComponents must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my $components = [];
	my $search = $self->{_dbix}->component_provideds->search(undef, 
		{ '+columns' => [ 'component_id.component_id', 
						'component_id.component_name', 
						'component_id.component_version', 
						'component_id.component_category' ],
			join => ['component_id'] } 
	);
	while (my $row = $search->next) {
		my $tmp = {};
		$tmp->{component_id} = $row->get_column('component_id');
		$tmp->{component_name} = $row->get_column('component_name');
		$tmp->{component_version} = $row->get_column('component_version');
		$tmp->{component_category} = $row->get_column('component_category');
		push @$components, $tmp;
	}
	return $components;
}


1;