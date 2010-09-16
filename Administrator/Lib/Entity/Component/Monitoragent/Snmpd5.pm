package Entity::Component::Monitoragent::Snmpd5;

use strict;

use base "Entity::Component::Monitoragent";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getConf{
	my $self = shift;
	my $conf_raw = $self->{_dbix}->snmpd5s->first();
	return { options => $conf_raw->get_column('snmpd_options'),
			 monitor_server_ip => $conf_raw->get_column('monitor_server_ip'),
	};
}

1;