=head1 API test logger
    Common init for logging
    Warnings are catched and logged instead of printed on stderr
    Unecessary warning 'Deep recursion on subroutine' are skipped ("no warning 'recursion';" do not work)
=cut

package APITestLogger;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'api.t.log', layout=>'%F %L %p %m%n'});
my $log = get_logger("");

$SIG{__WARN__} = sub {
    my $warn = shift;
    if ($warn !~ /Deep recursion on subroutine/) {
        $log->warn($warn);
    }
};

1;