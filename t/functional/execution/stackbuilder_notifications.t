#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;
use Test::Differences;

use Kanopya::Tools::Execution;

use EEntity;
use Entity::User::Customer;
use Entity::Component::KanopyaStackBuilder;
use Entity::Operation;
use NotificationSubscription;

use Data::Dumper;
use TryCatch;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'INFO',
    file   => __FILE__.'.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});


my $testing = 0;

# Get the stackbuilder
my $stackbuilder;
lives_ok {
    $stackbuilder = EEntity->new(entity => Entity::Component::KanopyaStackBuilder->find());
} 'Get the KanopyaStackBuilder component';


my $firstname = "First";
my $login = "flast";
my $admin_password = "password";
my $stackid = 123;
my $access_ip = $stackbuilder->getAccessIp();

my $expected_message = 'Hi ' . $firstname . ',

Before accessing your stack, please read the entire email.
You recently launched a stack on www.pimpmystack.net. If you did not, please ignore this email.

Before accessing to your stacks make sure to check the following steps:

1) Make sure your VPN is activated, you received the VPN configuration files in a previous email. If you didn\'t or can\'t find it, please contact us at support@pimpmystack.net

2) Make sure the VPN is activated. You need to be logged on pimpmystack.net and click the button on www.pimpmystack.net/My account,

After, you can connect to your OpenStack using this credentials:

Your OpenStack login:       ' . $login . '
Your OpenStack password:    ' . $admin_password . '
Your OpenStack Horizon URL: http://' . $access_ip . '/

Visit http://www..pimpmystack.net?q=content/builder/#/' . $stackid . ' to get more informations about your stack.

  
Keep in mind that complete guides and scenarios are available on the scenarios menu:
- How to : Open a VPN connection with OpenVPN  
- How to : Connect to Horizon
- How to : First commands on OpenStack
';

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    # Create a customer to use as subscriber
    my $customer;
    lives_ok {
        $customer = Entity::User::Customer->findOrCreate(
            user_login     => $login,
            user_password  => 'flastpass',
            user_firstname => $firstname,
            user_lastname  => 'Last',
            user_email     => 'kpouget@hederatech.com',
        );
    } 'Create a customer stack_builder_test for the subscriber';

    my $operation = EEntity::EOperation->new(operation => Entity::Operation->new(
                        priority => 200,
                        type     => "ConfigureStack",
                        params   => {
                            context => {
                                user           => $customer,
                                # We use any component here as the message builder method will call ->adminIp only
                                novacontroller => $stackbuilder
                            },
                            stack_id => $stackid,
                            admin_password => $admin_password
                        }
                    ));

    my $message =  $stackbuilder->notificationMessage(operation  => $operation,
                                                      state      => 'succeeded',
                                                      subscriber => $customer);

    eq_or_diff $expected_message, $message, "Compare builded notification with the execpted one";

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
