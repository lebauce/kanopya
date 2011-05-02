package EEntity::EComponent::EExportclient::EOpeniscsi2;

use strict;

use base "EEntity::EComponent::EExportclient";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub initiator_conf ($$) {
	my $self = shift;
	my %args = @_;

    if ((! exists $args{initiatorname} or ! defined $args{initiatorname})||
		(! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{remotepath} or ! defined $args{remotepath})) { 
		throw Kanopya::Exception::Internal(error => "EEntity::EExport::EOpeniscsi2->generateInitiatorConf need a initiatorname and a econtext named argument to generate initiatorname!"); }
        
        my $result = $args{econtext}->execute("echo \"InitiatorName=$args{'initiatorname'}\" > $args{remotepath}/iscsi/initiatorname.iscsi");
        return 0;
}

sub AddNode {}

1;
