package Entity::Cluster;

use strict;

use base "Entity";
use lib qw (.. ../../../Common/Lib);
use McsExceptions;
use Entity::Component;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;
use constant ATTR_DEF => {
			cluster_name			=> {pattern			=> 'm//s',
										is_mandatory	=> 1,
										is_extended		=> 0},
			cluster_desc			=> {pattern			=> 'm//m',
										is_mandatory	=> 0,
										is_extended 	=> 0},
			cluster_type			=> {pattern			=> 'm//s',
										is_mandatory	=> 0,
										is_extended		=> 0},
			cluster_min_node		=> {pattern 		=> 'm//s',
										is_mandatory	=> 1,
										is_extended 	=> 0},
			cluster_max_node		=> {pattern			=> 'm//s',
										is_mandatory	=> 1,
										is_extended		=> 0},
			cluster_priority		=> {pattern 		=> 'm//s',
										is_mandatory	=> 1,
										is_extended 	=> 0},
			active					=> {pattern			=> 'm//s',
										is_mandatory	=> 1,
										is_extended		=> 0},
			systemimage_id			=> {pattern 		=> 'm//s',
										is_mandatory	=> 1,
										is_extended 	=> 0},
			kernel_id				=> {pattern 		=> 'm//s',
										is_mandatory	=> 0,
										is_extended 	=> 0}
			};



=head2 checkAttr
	
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
	my $struct = ATTR_DEF;

	if (! exists $args{attrs} or ! defined $args{attrs}) { 
		$errmsg = "Entity::Cluster->checkAttrs need an data hash and class named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}	

	my $attrs = $args{attrs};
	foreach $attr (keys(%$attrs)) {
		if (exists $struct->{$attr}){
			#TODO Check param with regexp in pattern field of struct
			if ($struct->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else { $global_attrs{$attr} = $attrs->{$attr}; }
		}
		else {
			$errmsg = "Entity::Cluster->checkAttrs detect a wrong attr $attr !";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
		}
	}
	foreach $attr (keys(%$struct)) {
		if (($struct->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				$errmsg = "Entity::Cluster->checkAttrs detect a missing attribute $attr !";
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
	my $struct = ATTR_DEF;
	
	if ((! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{value} or ! defined $args{value})) { 
		$errmsg = "Entity::Cluster->checkAttr need a name and value named argument!";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (!exists $struct->{$args{name}}){
		$errmsg = "Entity::Cluster->checkAttr invalid name";	
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	# Here check attr value
}

# contructor

sub new {
    my $class = shift;
    my %args = @_;

	if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})) { 
		$errmsg = "Entity->new need a data and rightschecker named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $self = $class->SUPER::new( %args );
    return $self;
}

=head2 getComponents
	
	Desc : This function get components used in a cluster. This function allows to select
			category of components or all of them.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
		category : String : Component category
	return : a hashref of components, it is indexed on component_instance_id

=cut

sub getComponents{
	my $self = shift;
    my %args = @_;

	if ((! exists $args{administrator} or ! defined $args{administrator}) ||
		(! exists $args{category} or ! defined $args{category})) { 
		$errmsg = "Entity::Cluster->getComponent need a category and administrator named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", undef,
											{ '+columns' => [ "component_id.component_name", 
															  "component_id.component_category",
															  "component_id.component_version"], 
													join => ["component_id"]});
		
	my %comps;
	$log->debug("Category is $args{category} and adm ". ref($args{administrator}));
	while ( my $comp_instance_row = $comp_instance_rs->next ) {
		if (($args{category} eq "all")||
			($args{category} eq $comp_instance_row->get_column('component_category'))){
			$log->debug("One component instance found with " . ref($comp_instance_row));
			$comps{$comp_instance_row->get_column('component_instance_id')} = $args{administrator}->getEntity (
							class_path => "Entity::Component::".$comp_instance_row->get_column('component_category')."::" .$comp_instance_row->get_column('component_name') . $comp_instance_row->get_column('component_version'),
							id => $comp_instance_row->get_column('component_instance_id'),
							type => "ComponentInstance");
		}
	}
	return \%comps;
}

=head2 getComponent
	
	Desc : This function get component used in a cluster. This function allows to select
			a particular component with its name and version.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
		name : String : Component name
		version : String : Component version
	return : a component instance

=cut

sub getComponent{
	my $self = shift;
    my %args = @_;

	if ((! exists $args{administrator} or ! defined $args{administrator}) ||
		(! exists $args{name} or ! defined $args{name}) ||
		(! exists $args{version} or ! defined $args{version})) { 
		$errmsg = "Entity::Cluster->getComponent needs a name, version and administrator named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $hash = {'component_id.component_name' => $args{name}, 'component_id.component_version' => $args{version}};
	my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", $hash,
											{ '+columns' => [ "component_id.component_name",
															  "component_id.component_version",
															  "component_id.component_category"], 
													join => ["component_id"]});
		
	my %comps;
	$log->debug("name is $args{name}, version is $args{version} and adm ". ref($args{administrator}));
	while ( my $comp_instance_row = $comp_instance_rs->next ) {
		$log->debug("Component instance found with " . ref($comp_instance_row));
			return $args{administrator}->getEntity (
							class_path => "Entity::Component::".$comp_instance_row->get_column('component_category')."::" .
										  $comp_instance_row->get_column('component_name') . 
										  $comp_instance_row->get_column('component_version'),
							id => $comp_instance_row->get_column('component_instance_id'),
							type => "ComponentInstance");
	}
	# PAS TROUVER NE VEUT PAS DIRE ERREUR.
#	$errmsg = "Entity::Cluster->getComponent, no component found with name ($args{name}) and version ($args{version})";
#	$log->error($errmsg);
#	throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
}

=head2 getSystemImage
	
	Desc : This function return the cluster's system image.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
	return : a system image instance

=cut

sub getSystemImage {
	my $self = shift;
    my %args = @_;

	if (! exists $args{administrator} or ! defined $args{administrator}) {
		$errmsg = "Entity::Cluster->getSystemImage needs an administrator named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	return $args{administrator}->getEntity(type => 'Systemimage', id => $self->getAttr(name => 'systemimage_id'));
}

#TODO soit on fait un getMasterNode et on retourne le node mais du coup il faut l'admin
sub getMasterNodeIp{
	my $self = shift;
	#TODO Test if cluster is active, return undef if not found ?
	my $node_instance_rs = $self->{_dbix}->search_related("nodes", { master_node => 1 })->single;
	my $node_ip = $node_instance_rs->motherboard_id->get_column('motherboard_internal_ip');
	$log->debug("Master node found and its ip is $node_ip");
	return $node_ip
}

=head2 addComponent

create a new component instance
this is the first step of cluster setting

=cut

sub addComponent {
	my $self = shift;
	my %args = @_;
	# check arguments
	if((! exists $args{administrator} or ! defined $args{administrator}) ||
	   (! exists $args{component_id} or ! defined $args{component_id})) {
	   	$errmsg = "Entity::Cluster->addComponent needs administrator and component_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $admin = $args{administrator};
	my $template_id = undef;
	if(exists $args{component_template_id} and defined $args{component_template_id}) {
		$template_id = $args{component_template_id};
	}
	
	# check if component_id is valid
	my $row = $admin->{db}->resultset('Component')->find($args{component_id});
	if(not defined $row) {
		$errmsg = "Entity::Cluster->addComponent : component_id does not exist";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}
	
	# check if instance of component_id is not already inserted for  this cluster
	$row = $admin->{db}->resultset('ComponentInstance')->search(
		{ component_id => $args{component_id}, 
		  cluster_id => $self->getAttr(name => 'cluster_id') })->single;
	if(defined $row) {
		$errmsg = "Entity::Cluster->addComponent : cluster has already the component with id $args{component_id}";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
	}
	
	# check if component_template_id correspond to component_id
	if(defined $template_id) {
		my $row = $admin->{db}->resultset('ComponentTemplate')->find($template_id);
		if(not defined $row) {
			$errmsg = "Entity::Cluster->addComponent : component_template_id does not exist";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
		} elsif($row->get_column('component_id') != $args{component_id}) {
			$errmsg = "Entity::Cluster->addComponent : component_template_id does not belongs to component specified by component_id";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::WrongValue(error => $errmsg);
		}
	}
	
	# insertion of a new component instance can't use administrator->newEntity method
	# due to components database schema, so we do it by hand
	# create component instance record 
	my $componentinstance = $admin->{db}->resultset('ComponentInstance')->new(
		{	component_id => $args{component_id},
			cluster_id => $self->getAttr(name => 'cluster_id'),
			component_template_id => $template_id
		}
	);
	$componentinstance->insert();
	# create entity and component_instance_entity	
	my $entity = $admin->{db}->resultset('Entity')->create(
		{ "component_instance_entities" => [ {"component_instance_id" => $componentinstance->get_column('component_instance_id')} ] }
	);
		
	
	
}

=head2 getMotherboards
	
	Desc : This function get motherboards executing the cluster.
	args: 
		administrator : Administrator : Administrator object to instanciate all components
	return : a hashref of motherboard, it is indexed on motherboard_id

=cut

sub getMotherboards{
	my $self = shift;
    my %args = @_;

	if ((! exists $args{administrator} or ! defined $args{administrator})) { 
		$errmsg = "Entity::Cluster->getMotherboards need an administrator named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	my $motherboard_rs = $self->{_dbix}->nodes;
		
	my %motherboards;
	while ( my $node_row = $motherboard_rs->next ) {
		my $motherboard_row = $node_row->motherboard_id;
		$log->debug("Nodes found");
		my $motherboard_id = $motherboard_row->get_column('motherboard_id');
		$motherboards{$motherboard_id} = $args{administrator}->getEntity (
						id => $motherboard_id,
						type => "Motherboard");
	}
	return \%motherboards;
}

sub getPublicIps {
	my $self = shift;
  
	my $publicip_rs = $self->{_dbix}->publicips;
	my $i =0;
	my @pub_ip =();
	while ( my $publicip_row = $publicip_rs->next ) {
		my $publicip = {address => $publicip_row->get_column('ip_address'),
						netmask => $publicip_row->get_column('ip_mask'),
						gateway => $publicip_row->get_column('gateway'),
						name 	=> "eth0:$i"};
		$i++;
		push @pub_ip, $publicip;
	}
	return \@pub_ip;
}
1;
