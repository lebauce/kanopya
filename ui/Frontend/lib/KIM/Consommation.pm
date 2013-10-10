package KIM::Consommation;

use Dancer ':syntax';

use Entity;
use Entity::ServiceProvider::Cluster;

prefix undef;

get '/consommation/cluster/:clusterid' => sub {
  content_type 'application/octet-stream';

  my $cluster   = Entity->methodCall(method => 'get', param => { id => param('clusterid') });
  my $user      = $cluster->user;

  header 'Content-Disposition'  => "attachment; filename='user-" . $user->getId . "-" . $cluster->getAttr(name => 'cluster_name') . ".csv'";

  return $cluster->methodCall(method => 'getMonthlyConsommation');
};

