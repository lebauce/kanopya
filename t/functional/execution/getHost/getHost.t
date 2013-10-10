# --- Test of the getFreeHost method ---
#
# Three main categories with several cases of tests are performed :
#
#   1 -> Only one host is valid, we must ensure that it is effectively the one selected.
#
#       1.A - There is only one host matching the minimum RAM constraint.
#       1.B - There is only one host matching the minimum CPU Cores number constraint.
#       1.C - There is only one host matching the minimum Ifaces number.
#       1.D - There is only one host matching the minimum bonding configuration.
#       1.E - There is only one host matching the minimum network configuration constraint.
#       1.F - There is only one host matching the minimum tags constraint.
#       1.G - There is only one host allowing a deployment on disk.
#
#       * There must be at least one host matching all the constraints but the one tested among the
#         invalid ones.
#
#   2 -> No host is selected, the getFreeHost must throw an exception.
#
#       2.A - None of the hosts match the minimum RAM constraint.
#       2.B - None of the hosts match the minimum CPU Cores number constraint.
#       2.C - None of the hosts match the minimum Ifaces number constraint.
#       2.D - None of the hosts match the minimum bonding configuration.
#       2.E - None of the hosts match the minimum network configuration constraint.
#       2.F - None of the hosts match the minimum tags constraint.
#       2.G - None of the hosts have a disk for a deployment on disk.
#
#       * There must be at least one host matching all the constraints but the one tested among the hosts.
#
#   3 -> All the hosts are valid, the one with the lowest cost must be chosen.
#
#       3.A - One host have a better cost than the others because of its RAM cost.
#       3.B - One host have a better cost than the others because of its CPU cost.
#       3.C - One host have a better cost than the others because of its number of Iface.
#       3.D - One host have a better cost than the others because of its bonding configuration.
#       3.E - One host have a better cost than the others because of its network configuration.
#       3.F - One host have a better cost than the others because of its tags number.
#
#       * In each case the costs for the non tested criterion are equals.
#
# Each tested case will be detailed before being tested (hosts and constraints) (See files _test**.pm) :

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Kanopya::Exceptions;

use Entity::Netconf;
use Kanopya::Tools::Create;
use Kanopya::Tools::Register;

use Kanopya::Database;

# Allow the test to be launched from an external repository
use File::Basename;
use lib dirname (__FILE__);

use _test1a;
use _test1b;
use _test1c;
use _test1d;
use _test1e;
use _test1f;
use _test1g;

use _test2a;
use _test2b;
use _test2c;
use _test2d;
use _test2e;
use _test2f;
use _test2g;

use _test3a;
use _test3b;
use _test3c;
use _test3d;
use _test3e;
use _test3f;
use _test4a;
use _test4b;

use DecisionMaker::HostSelector;

use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'getHost.t.log',
    layout => '%F %L %p %m%n'
});

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    # 1st serie of tests : Only one matching host in each case.

    Kanopya::Database::beginTransaction;
    test1a();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test1b();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test1c();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test1d();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test1e();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test1f();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test1g();
    Kanopya::Database::rollbackTransaction;

    # 2nd serie of tests : None of the hosts match the constraints.

    Kanopya::Database::beginTransaction;
    test2a();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test2b();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test2c();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test2d();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test2e();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test2f();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test2g();
    Kanopya::Database::rollbackTransaction;

    # 3rd serie of tests : Choosing the host with the best cost for a given criterion.

    Kanopya::Database::beginTransaction;
    test3a();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test3b();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test3c();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test3d();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test3e();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test3f();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test4a();
    Kanopya::Database::rollbackTransaction;

    Kanopya::Database::beginTransaction;
    test4b();
    Kanopya::Database::rollbackTransaction;
}