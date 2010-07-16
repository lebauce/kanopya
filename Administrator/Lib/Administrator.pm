package Administrator;


use strict;
use AdministratorDB::Schema;
use Data::Dumper;

###########################################
# new (login, password)
# 
# object constructor


sub new {
	my $class = shift;
	my %args = @_;
	
	my $login = $args{login};
	my $password = $args{password};
	 
	# ici on va chercher la conf pour se connecter à la base 
	my $dbi = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %opts = ();
		
	my $self = {
		db => AdministratorDB::Schema->connect($dbi, $user, $pass, \%opts),
	};
	
	if( ! $self->{db} ) { die "Unable to connect to the database : "; }
	
	# on recup l'identite de l'utilisateur
	$self->{user} = $self->{db}->resultset('User')->find( { user_login => $login } );
	
	if(! $self->{user} || $self->{user}->user_password ne $password) {
		warn "incorrect login/password pair";
		return undef;
	}
	
	bless $self, $class;
	return $self;
}


sub getObj {}

sub getObjs {}

sub getAllObjs {}

sub newObj {}

sub saveObj {}

1;