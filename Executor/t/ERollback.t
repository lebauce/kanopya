use Test::More 'no_plan';
use lib "../Lib", "../../Common/Lib" ;
use McsExceptions;
use Log::Log4perl qw(:easy);
use Data::Dumper;

Log::Log4perl->easy_init({level=>'ERROR', file=>'STDOUT', layout=>'%F %L %p %m%n'});

# a simple class to test rollback calls
{
package myobj;

sub new { return bless {}, shift; }

sub f1 ($) {
	my $self = shift;
	my $param = shift;
	print time(), ": f1 call with param $param\n";
}

sub f2 ($) {
	my $self = shift;
	my $param = shift;
	print time(), ": f2 call with param $param\n";
}

sub f3 ($) {
	my $self = shift;
	my $param = shift;
	print time(), ": f3 call with param $param\n";
}
}

use_ok(ERollback);

my $obj = myobj->new();

# create ERollback object and add a rollback
my $f1 = $obj->can('f1');
my $p1 = [$obj, 'one string'];
my $rb = ERollback->new(function => $f1, parameters => $p1);

isa_ok($rb, "ERollback", '$rb');
is($rb->{function}, $f1, 'Storing function in ERollback object');
is($rb->{parameters}, $p1, 'Storing parameters in ERollback object');

my $f2 = $obj->can('f2');
my $p2 = [$obj, 'another string'];
$rb->add(function => $f2, parameters => $p2);
isa_ok($rb->{next_item}, "ERollback", '$rb->{next_item}');
isa_ok($rb->{next_item}->{prev_item}, "ERollback", '$rb->{next_item}->{prev_item}');
is($rb->{next_item}->{function}, $f2, 'Storing function in ERollback {next_item} object');
is($rb->{next_item}->{parameters}, $p2, 'Storing parameters in ERollback {next_item} object');

my $f3 = $obj->can('f3');
my $p3 = [$obj, 'another string again'];
$rb->add(function => $f3, parameters => $p3);
isa_ok($rb->{next_item}->{next_item}, "ERollback", '$rb->{next_item}->{next_item}');
isa_ok($rb->{next_item}->{next_item}->{prev_item}, "ERollback", '$rb->{next_item}->{next_item}->{prev_item}');
is($rb->{next_item}->{next_item}->{function}, $f3, 'Storing function in ERollback {next_item}->{next_item} object');
is($rb->{next_item}->{next_item}->{parameters}, $p3, 'Storing parameters in ERollback {next_item}->{next_item} object');

$rb->undo();
# see the output to verify calls order
