#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Kanopya::Tools::OpenStack;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'openstack.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;

my $testing = 0;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    Kanopya::Tools::OpenStack->start1OpenStackOn3Clusters();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
