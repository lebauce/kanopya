package Entity::Component::Tftpserver::Atftpd0;

use strict;

use base "Entity::Component::Tftpserver";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getConf{
	my $self = shift;
	my $conf_raw = $self->{_dbix}->atftpd0s->first();
	return {options => $conf_raw->get_column('atftpd0_options'),
			   repository => $conf_raw->get_column('atftpd0_repository'),
			   use_inetd => $conf_raw->get_column('atftpd0_use_inetd'),
			   logfile => $conf_raw->get_column('atftpd0_logfile')};

}
1;
