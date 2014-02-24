#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;

use Entity::ServiceProvider::Cluster;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'stack_builder.t.log',
    layout => '%F %L %p %m%n'
});


my $testing = 1;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    lives_ok {
        $masterimage = Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    my $builder;
    lives_ok {
       $builder = Entity::ServiceProvider::Cluster->getKanopyaCluster->getComponent(
                      name => "KanopyaStackBuilder"
                  );
    } 'Get the StackBuilder component';

    my $build_stack;
    lives_ok {
       $build_stack = $builder->buildStack(stack => { hosts => { 'host1' => {}, 'host2' => {} } });
    } 'Run workflow BuildStack';

    Kanopya::Tools::Execution->executeOne(entity => $build_stack);

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
