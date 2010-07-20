use FindBin qw($Bin);
use lib "$Bin/../Lib";

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;

my $adm = Administrator->new( login =>'thom', password => 'pass' );

is( "test", "test", "test");