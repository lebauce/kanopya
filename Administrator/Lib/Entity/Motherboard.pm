package Entity::Motherboard;

use strict;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use base "Entity";

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	motherboard_model_id	=>	{pattern			=> 'm//s',
											is_mandatory	=> 1,
											is_extended		=> 0},
			  processor_model_id		=> {pattern			=> 'm//m',
											is_mandatory	=> 1,
											is_extended 	=> 0},
			  kernel_id					=> {pattern			=> 'm//s',
											is_mandatory	=> 1,
											is_extended		=> 0},
			  motherboard_serial_number	=> {pattern 		=> 'm//s',
											is_mandatory	=> 1,
											is_extended 	=> 0},
			  motherboard_slot_position	=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_desc			=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  active		=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_mac_address	=> {pattern 		=> 'm//s',
											is_mandatory	=> 1,
											is_extended 	=> 0},
			  motherboard_internal_ip	=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_hostname		=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  motherboard_initiatorname	=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0},
			  etc_device_id				=> {pattern 		=> 'm//s',
											is_mandatory	=> 0,
											is_extended 	=> 0}
			};



=head2 checkAttrs
	
	Desc : This function check if new object data are correct and sort attrs between extended and global
	args: 
		class : String : Real class to check
		data : hashref : Entity data to be checked
	return : hashref of hashref : a hashref containing 2 hashref, global attrs and extended ones

=cut

sub checkAttrs {
	# Remove class
	shift;
	my %args = @_;
	my (%global_attrs, %ext_attrs, $attr);
	my $attr_def = ATTR_DEF;
	#print Dumper $attr_def;
	if (! exists $args{attrs} or ! defined $args{attrs}){ 
		$errmsg = "Entity::Motherboard->checkAttrs need an attrs hash named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach $attr (keys(%$attrs)) {
		if (exists $attr_def->{$attr}){
			$log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
			#TODO Check param with regexp in pattern field of struct
			if ($attr_def->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else {
				$global_attrs{$attr} = $attrs->{$attr};
			}
		}
		else {
			$errmsg = "Entity::Motherboard->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$attr_def)) {
		if (($attr_def->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Motherboard->checkAttrs detect a missing attribute $attr !";
				$log->error($errmsg);
				throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
			}
	}
	#TODO Check if id (systemimage, kernel, ...) exist and are correct.
	return {global => \%global_attrs, extended => \%ext_attrs};
}

=head2 checkAttr
	
	Desc : This function check new object attribute
	args: 
		name : String : Attribute name
		value : String : Attribute value
	return : No return value only throw exception if error

=cut

sub checkAttr{
	my $self = shift;
	my %args = @_;
	my $attr_def = ATTR_DEF;

	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value})) { 
		$errmsg = "Entity::Motherboard->checkAttr need a name and value named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (! defined $args{value} && $attr_def->{$args{name}}->{is_mandatory}){
		$errmsg = "Entity::Motherboard->checkAttr detect a null value for a mandatory attr ($args{name})";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}

	if (!exists $attr_def->{$args{name}}){
		$errmsg = "Entity::Motherboard->checkAttr invalid attr name : '$args{name}'";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	# Here check attr value
}

sub extension {
	return "motherboarddetails";
}

sub new {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker}) ||
		(! exists $args{ext_attrs} or ! defined $args{ext_attrs})) { 
		$errmsg = "Entity::Motherboard->new need a data, ext_attrs and rightschecker named argument!";	
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

sub getEtcName {
	my $self = shift;
	my $mac = $self->getAttr(name => "motherboard_mac_address");
	$mac =~ s/\:/\_/mg;
	return "etc_". $mac;
}

=head getMacName

return Mac address with separator : replaced by _

=cut
sub getMacName {
	my $self = shift;
	my $mac = $self->getAttr(name => "motherboard_mac_address");
	$mac =~ s/\:/\_/mg;
	return $mac;
}


=head getEtcDev

get etc attributes used by this motherboard

=cut
sub getEtcDev {
	my $self = shift;
	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Motherboard->getEtcDev must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	$log->info("retrieve etc attributes");
	my $etcrow = $self->{_dbix}->etc_device_id;
	my $devices = {
		etc => { lv_id => $etcrow->get_column('lvm2_lv_id'), 
				 vg_id => $etcrow->get_column('lvm2_vg_id'),
				 lvname => $etcrow->get_column('lvm2_lv_name'),
				 vgname => $etcrow->lvm2_vg_id->get_column('lvm2_vg_name'),
				 size => $etcrow->get_column('lvm2_lv_size'),
				 freespace => $etcrow->get_column('lvm2_lv_freespace'),	
				 filesystem => $etcrow->get_column('lvm2_lv_filesystem')
				}	};
	$log->info("Motherboard etc and root devices retrieved from database");
	return $devices;
}

sub generateHostname{
#TODO generateHostname
	return "node002";
}


sub getClusterId {
	my $self = shift;
	return $self->{_dbix}->nodes->first()->cluster_id->get_column('cluster_id');
}
1;
