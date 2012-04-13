use Test::More;# 'no_plan';

plan tests => 2;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});


note("Use Tests");
use_ok(Monitor::Collector);
use_ok(Monitor::Grapher);

eval {
my %args = (login =>'xebech', password => 'pass');
my $adm = Administrator->new( %args);



};
if ($@){
   print "Error:" . $@;
}
