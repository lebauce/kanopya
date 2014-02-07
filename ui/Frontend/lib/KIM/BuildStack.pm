package KIM::BuildStack;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Entity::ServiceProvider::Cluster;

prefix undef;

ajax '/buildstack' => sub {
    my $stack = param('stack');

    # Retrieve the builder on Kanopya
    my $builder = Entity::ServiceProvider::Cluster->getKanopyaCluster->getComponent(
                      name => "KanopyaStackBuilder"
                  );

    # Build the stack
    $builder->buildStack(stack => $stack);
};
