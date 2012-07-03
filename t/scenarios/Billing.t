use Administrator;
use Entity::User;
use Entity::ServiceProvider::Inside::Cluster;
use BillingManager;
use DateTime::Format::ISO8601;

use Log::Log4perl 'get_logger';

Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => '/tmp/Billing.t.log',
    layout => '%F %L %p %m%n'
});

my $log = get_logger('billing');

# my CPU_BILLING = 1;
# my RAM_BILLING = 2;

Administrator::authenticate(login => 'admin', password => 'K4n0pY4');

for my $user (Entity::User->search(hash => {})) {
    my $from = DateTime::Format::ISO8601->parse_datetime("2012-06-26T00:00:00");
    my $to = DateTime::Format::ISO8601->parse_datetime("2012-06-28T00:00:00");

    BillingManager::userBilling($user, $from, $to);
}
