package Entity::Component::Webserver::Apache2;
use base "Entity::Component::Webserver";
use strict;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;



# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub setGeneralConf {
	
}
sub addVirtualhost {
	
}

sub getVirtualhostConf{
	my $self = shift;

	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Distribution->getDevices must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my $virtualhost_rs = $self->{_dbix}->apache2s->first->apache2_virtualhosts;
	my @tab_virtualhosts = ();
	while (my $virtualhost_row = $virtualhost_rs->next){
		my %virtualhost = $virtualhost_row->get_columns();
		push @tab_virtualhosts, \%virtualhost;
	}
	return \@tab_virtualhosts;
}

sub getGeneralConf{
	my $self = shift;

	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Distribution->getDevices must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my %apache2_conf = $self->{_dbix}->apache2s->first->get_columns();
	return \%apache2_conf;
}
1;
