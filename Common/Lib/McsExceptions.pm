
#TODO http://www.drdobbs.com/web-development/184416129

package McsExceptions;
use Data::Dumper;

use Exception::Class (
    Mcs::Exception => {
	description => "Mcs General Exception",
	fields => [ 'level', 'request' ],
    },
    Mcs::Exception::DB => {
	isa => 'Mcs::Exception',
	description => 'MicroCluster System Database exception',
    },
    Mcs::Exception::Network => {
	isa => 'Mcs::Exception',
	description => 'MicroCluster SSH communication exception',
    },
    Mcs::Exception::Internal => {
	isa => 'Mcs::Exception',
	description => 'MicroCluster System Internal exception',
    },
    Mcs::Exception::Internal::WrongValue => {
	isa => 'Mcs::Exception::Internal',
	description => 'Wrong Value',
    },
    Mcs::Exception::Internal::IncorrectParam => {
	isa => 'Mcs::Exception::Internal',
	description => 'Wrong attribute or parameter',
    },
    Mcs::Exception::Execution => {
	isa => 'Mcs::Exception',
	description => 'Command execution failed',
    }
    
    );

#$SIG{__DIE__} = \&handle_die;

sub handle_die {
	my $err = shift;
	warn("Caught error: ", $err);
	exit(55);
}
1;
