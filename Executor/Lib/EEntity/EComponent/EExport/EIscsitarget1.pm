package EEntity::EComponent::EExport::EIscsitarget1;

use strict;
use Date::Simple (':all');
use base "EEntity::EComponent::EExport";
use Log::Log4perl "get_logger";
my $log = get_logger("executor");

# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub generateInitiatorname{
	my $self = shift;
	my %args  = @_;	

	if ((! exists $args{id} or ! defined $args{id})) { 
		throw Mcs::Exception::Internal(error => "EEntity::EStorage::EIscsitarget1->generateInitiatorname need an id named argument to generate initiatorname!"); }
	return "test";
}
sub generateTargetname {
	my $self = shift;
	my %args  = @_;	
	
	if ((! exists $args{name} or ! defined $args{name})||
		(! exists $args{type} or ! defined $args{type})) { 
		throw Mcs::Exception::Internal(error => "EEntity::EStorage::EIscsitarget1->generateTargetname need a name and a type named argument to generate initiatorname!"); }
	my $today = today();
	my $res = "iqn." . $today->year . "-" . $today->format("%m") . ".com.hedera-technology.nas:$args{name}"."_".$args{type};
	$log->info("TargetName generated is $res");
}


sub addTarget {
	my $self = shift;
	my %args  = @_;	

	if ((! exists $args{targetname} or ! defined $args{targetname})||
		(! exists $args{mount_point} or ! defined $args{mount_point})) { 
		throw Mcs::Exception::Internal(error => "EEntity::EStorage::EIscsitarget1->addTarget need an targetname and a mount_point named argument to generate initiatorname!"); }

	return $self->_getEntity()->addTarget(%args);
}

sub reload {
	my $self = shift;

	$self->generateConf();
	
	$self->restart();
}

sub addLun {
	
}
1;
