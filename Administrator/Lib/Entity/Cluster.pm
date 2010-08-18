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
		$errmsg = "Entity::Motherboard->checkAttr need a name and value named argument!";
		$log->error($errmsg);	
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	if (!exists $struct->{$args{name}}){
		$errmsg = "Entity::Motherboard->checkAttr invalid name";	
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

#TODO soit on fait un getMasterNode et on retourne le node mais du coup il faut l'admin
sub getMasterNodeIp{
	my $self = shift;
	#TODO Test if cluster is active, return undef if not found ?
	my $node_instance_rs = $self->{_dbix}->search_related("nodes", { master_node => 1 })->single;
	my $node_ip = $node_instance_rs->motherboard_id->get_column('motherboard_internal_ip');
	$log->debug("Master node found and its ip is $node_ip");
	return $node_ip
}

1;
