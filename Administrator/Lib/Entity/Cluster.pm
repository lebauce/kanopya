package Entity::Cluster;

use strict;

use base "Entity";
use lib qw (..);
use Entity::Component;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");

my $struct = {cluster_name		=> {pattern			=> 'm//s',
									is_mandatory	=> 1,
									is_extended		=> 0},
			  cluster_desc		=> {pattern			=> 'm//m',
									is_mandatory	=> 0,
									is_extended 	=> 0},
			  cluster_type		=> {pattern			=> 'm//s',
									is_mandatory	=> 1,
									is_extended		=> 0},
			  cluster_min_node	=> {pattern 		=> 'm//s',
									is_mandatory	=> 1,
									is_extended 	=> 0},
			  cluster_max_node	=> {pattern			=> 'm//s',
									is_mandatory	=> 1,
									is_extended		=> 0},
			  cluster_priority	=> {pattern 		=> 'm//s',
									is_mandatory	=> 1,
									is_extended 	=> 0},
			  cluster_net_id	=> {pattern 		=> 'm//s',
									is_mandatory	=> 1,
									is_extended 	=> 0},
			  cluster_active	=> {pattern			=> 'm//s',
									is_mandatory	=> 1,
									is_extended		=> 0},
			  systemimage_id	=> {pattern 		=> 'm//s',
									is_mandatory	=> 1,
									is_extended 	=> 0},
			  kernel_id			=> {pattern 		=> 'm//s',
									is_mandatory	=> 1,
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

	if (! exists $args{data} or ! defined $args{data}){ 
		throw Mcs::Exception::Internal(error => "Entity->checkAttrs need an data hash and class named argument!"); }	

	my $attrs = $args{data};
	foreach $attr (keys(%$attrs)) {
		if (exists $struct->{$attr}){
			#TODO Check param with regexp in pattern field of struct
			if ($struct->{$attr}->{is_extended}){
				$ext_attrs{$attr} = $attrs->{$attr};
			}
			else {
				$global_attrs{$attr} = $attrs->{$attr};
			}
		}
		else {
			throw Mcs::Exception::Internal(error => "Entity->checkAttrs detect a wrong attr $attr !");
		}
	}
	foreach $attr (keys(%$struct)) {
		if (($struct->{$attr}->{is_mandatory}) &&
			(! exists $attrs->{$attr})) {
				throw Mcs::Exception::Internal(error => "Entity->checkAttrs detect a missing attribute $attr !");
			}
	}
	#TODO Check if id (systemimage, kernel, ...) exist and are correct.
	return {global => \%global_attrs, extended => \%ext_attrs};
}

# contructor

sub new {
    my $class = shift;
    my %args = @_;

	$log->info("Cluster Instanciation");
    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getComponents{
	
}

1;
