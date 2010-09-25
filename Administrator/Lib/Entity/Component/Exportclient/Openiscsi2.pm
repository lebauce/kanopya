package Entity::Component::Exportclient::Openiscsi2;

use base "Entity::Component::Exportclient";
use strict;
use Template;
use String::Random;
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

sub getExports {
	my $self = shift;
	my $export_rs = $self->{_dbix}->openiscsi2s;
	my @tab_exports =();
	while (my $export_row = $export_rs->next){
		my $export ={};
		$export->{target} = $export_row->get_column('openiscsi2_target');
		$export->{ip} = $export_row->get_column('openiscsi2_server');
		$export->{port} = $export_row->get_column('openiscsi2_port');
		$export->{mount_point} = $export_row->get_column('openiscsi2_mount_point');
		$export->{options} = $export_row->get_column('openiscsi2_mount_options');
		$export->{fs} = $export_row->get_column('openiscsi2_filesystem');
		push @tab_exports, $export;
	}
	$log->debug("asked openiscsi import : " . Dumper(@tab_exports));
	return \@tab_exports;
}

1;
