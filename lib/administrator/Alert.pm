package Alert;
use parent 'BaseDB';

use Administrator;

use constant ATTR_DEF => {
    entity_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    alert_message => {
        pattern      => '^.+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    alert_message => {
        pattern      => '^.+$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my ($class, %args) = @_;
    General::checkParams(
        args => \%args, 
        required => ['entity_id', 'alert_message', 'alert_signature']);
    
    my $adm = Administrator->new();
    my $self = {};
    my $row = {
            alert_message => $args{alert_message},
            alert_active  => 1,
            alert_date    => \"CURRENT_DATE()",
            alert_time    => \"CURRENT_TIME()",
            entity_id     => $args{entity_id},
            alert_signature => $args{alert_signature}
    };

    $self->{_dbix} = $adm->{db}->resultset('Alert')->create($row);
    bless $self, $class;
    return $self;
}

sub mark_resolved {
    my ($self) = @_;
    $self->setAttr(alert_active => 0);
    $self->save;
}

1;
