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

use Entity::User::Customer;
use Entity::Component::Physicalhoster0;
use Entity::Operation;
use NotificationSubscription;

use Data::Dumper;
use TryCatch;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'INFO',
    file   => 'notification_subscriptions.t.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});


BEGIN {
    # Test will fail if any mail notifier is running
    my $executor_exist = `ps aux | grep kanopya-mail-notifier | grep -cv grep`;
    if ($executor_exist != 0) {
        throw Kanopya::Exception::Internal(error => 'A mail notifier is already running');
    }
}


my $testing = 0;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    use_ok ('Daemon::MessageQueuing');

    # Dynamically modify the EAddHost pre/post requisites
    # methods to control when operations are reported
    use_ok ('EEntity::EOperation::EAddHost');

    my ($prereport, $postreport) = (0, 0);
    sub EEntity::EOperation::EAddHost::prerequisites {
        my ($self, %args) = @_;

        return $prereport;
    }
    sub EEntity::EOperation::EAddHost::postrequisites {
        my ($self, %args) = @_;

        return $postreport;
    }

    # Use a generic daemon to consume mail notifications ourself
    my $daemonconf = {
        config => {
            user => {
                name     => 'admin',
                password => 'K4n0pY4'
            },
            amqp => {
                user     => 'executor',
                password => 'K4n0pY4'
            }
        }
    };

    my @configarray = %$daemonconf;
    my $genericdaemon = new_ok("Daemon::MessageQueuing", \@configarray, "Instantiate a generic Daemon::MessageQueuing");

    # Get the physical hoster to enqueue AddHost operations
    my $physicalhoster;
    lives_ok {
       $physicalhoster = Entity::Component::Physicalhoster0->find(),
    } 'Get the Physicalhoster component';

    # Create a customer to use as subscriber
    my $customer;
    lives_ok {
        $customer = Entity::User::Customer->findOrCreate(
            user_login     => 'notification_subscriptions_test',
            user_password  => 'notification_subscriptions_test',
            user_firstname => 'Notif',
            user_lastname  => 'Ica Tion',
            user_email     => 'kpouget@hederatech.com',
        );
    } 'Create a customer stack_builder_test for the owner of the stack';

    # List all states that should be notified
    my @states = Entity::Operation::OPERATION_STATES;

    # State "pending" is never notified
    @states = grep { $_ ne "pending" } @states;

    # Define the callback method to consume notifications
    my @notified_states = @states;
    sub callback {
        my ($self, %args) = @_;

        General::checkParams(args     => \%args,
                             required => [ "user_id", "message" ],
                             optional => { "subject" => "" });

        lives_ok {
            if ($args{user_id} != $customer->id) {
                die 'Notified user and subscriber differs'
            }
        } 'Compare notifed user to subscriber';

        my $state;
        if ($args{message} =~ m/is waiting your approval/) {
            $state = "waiting_validation"
        }
        else {
            ($state = $args{message}) =~ s/^.* //g;
            $state =~ s/\.(.*\n.*)*//g;
        }

        # For succeded state, the notification message is about "executed"
        if ($state eq "executed") {
            $state = "succeeded";
        }
        # For timeouted state, the notification message is about "timeout"
        if ($state eq "timeout") {
            $state = "timeouted";
        }

        lives_ok {
            if (scalar(grep { $_ eq $state } @states) <= 0) {
                die "State $state should not be notified"
            }
        } "Check if the notified state \"$state\" should be notified";
        @notified_states = grep { $_ ne $state } @notified_states;

        return 1;
    }

    my $queue = 'kanopya.mailnotifier.notification';
    $genericdaemon->connect(%{ $daemonconf->{config}->{amqp} });
    $genericdaemon->registerWorker(cbname   => $queue,
                                   type     => "queue",
                                   queue    => $queue,
                                   callback => \&callback);
    $genericdaemon->purgeQueue(queue => $queue);

    # Subscribe to notifications on the operation state
    for my $state (@states) {
        lives_ok {
            $physicalhoster->subscribe(subscriber_id   => $customer->id,
                                       operationtype   => "addhost",
                                       operation_state => $state);
        } "Subscribe to notifications on state $state for operation AddHost"
    }

    # Enqueue an operation that should succeed
    my $add_host;
    my $executor = $physicalhoster->service_provider->getManager(manager_type => 'ExecutionManager');
    lives_ok {
        $add_host = $executor->enqueue(
                        type     => 'AddHost',
                        params   => {
                            context  => {
                                host_manager => $physicalhoster,
                            },
                            host_serial_number => "notification_subscriptions_test",
                            host_core          => 1,
                            host_ram           => 1
                        }
                    );
        Kanopya::Tools::Execution->executeOne(entity => $add_host);
    } 'Run workflow AddHost';

    # Enqueue an operation that should timeout
    lives_ok {
        $add_host = $executor->enqueue(
                        type     => 'AddHost',
                        params   => {
                            context  => {
                                host_manager => $physicalhoster,
                            },
                            host_serial_number => "notification_subscriptions_test",
                            host_core          => 1,
                            host_ram           => 1
                        },
                        timeout => 1,
                    );
        Kanopya::Tools::Execution->executeOne(entity => $add_host);
    } 'Run workflow AddHost with timeout';

    # Enqueue an operation that should cancel
    throws_ok {
        $add_host = $executor->enqueue(
                        type     => 'AddHost',
                        params   => {
                            context  => {
                                host_manager => $physicalhoster,
                            },
                        }
                    );

        Kanopya::Tools::Execution->executeOne(entity => $add_host);
    } 'Kanopya::Exception::Internal', 'Run workflow AddHost with mandatory attr required';

    # Enqueue an operation that should fail
    throws_ok {
        $add_host = $executor->enqueue(
                        type     => 'AddHost',
                        harmless => 1,  
                        params   => {
                            context  => {
                                host_manager => $physicalhoster,
                            },
                        }
                    );

        Kanopya::Tools::Execution->executeOne(entity => $add_host);
    } 'Kanopya::Exception::Internal', 'Run workflow AddHost with mandatory attr required';

    # Enqueue an operation that should interrupted
    throws_ok {
        $add_host = $executor->enqueue(
                        type     => 'AddHost',
                        params   => {
                            context  => {
                                host_manager => $physicalhoster,
                            },
                            host_serial_number => "notification_subscriptions_test",
                            host_core          => 1,
                            host_ram           => 1,
                        }
                    );

        Kanopya::Tools::Execution->_executor->oneRun(cbname => 'run_workflow', duration => 1);
    
        $add_host->workflow->interrupt();

        Kanopya::Tools::Execution->executeOne(entity => $add_host);
    } 'Kanopya::Exception::Internal', 'Run workflow AddHost with interrupted workflow';

    # Enqueue an operation that should statereported
    lives_ok {
        $add_host = $executor->enqueue(
                        type     => 'AddHost',
                        params   => {
                            context  => {
                                host_manager => $physicalhoster,
                            },
                            host_serial_number => "notification_subscriptions_test",
                            host_core          => 1,
                            host_ram           => 1,
                        }
                    );

        # Manually lock an an entity of the context to get the state "statereported"
        $physicalhoster->unlock(consumer => $customer);
        $physicalhoster->lock(consumer => $customer);

        Kanopya::Tools::Execution->oneRun();

        $physicalhoster->unlock(consumer => $customer);
    } 'Run workflow AddHost with already locked context';

    # Subcribe with validation
    my $subsciption;
    lives_ok {
        $subsciption = NotificationSubscription->find(hash => {
                           entity_id       => $physicalhoster->id,
                           subscriber_id   => $customer->id,
                           operation_state => "processing"
                       });
        $subsciption->validation(1);
    } "Subscribe to validation on state \"processing\" for operation AddHost";

    # Enqueue an operation that require validation
    lives_ok {
        $add_host = $executor->enqueue(
                        type     => 'AddHost',
                        params   => {
                            context  => {
                                host_manager => $physicalhoster,
                            },
                            host_serial_number => "notification_subscriptions_test",
                            host_core          => 1,
                            host_ram           => 1
                        },
                        related_id => $physicalhoster->service_provider->id,
                    );
        Kanopya::Tools::Execution->oneRun();

        $subsciption->validation(0);
    } 'Run workflow AddHost';

    # Validate the operation
    lives_ok {
        $add_host->validate();

        Kanopya::Tools::Execution->executeOne(entity => $add_host);

    } 'Run workflow AddHost';

    # Enqueue an operation that is prereported
    lives_ok {
        $prereport = 1;

        $add_host = $executor->enqueue(
                        type     => 'AddHost',
                        params   => {
                            context  => {
                                host_manager => $physicalhoster,
                            },
                            host_serial_number => "notification_subscriptions_test",
                            host_core          => 1,
                            host_ram           => 1
                        },
                        related_id => $physicalhoster->service_provider->id,
                    );
        Kanopya::Tools::Execution->oneRun();

        $prereport = 0;
        $postreport = 1;

        Kanopya::Tools::Execution->oneRun();

        $postreport = 0;

        Kanopya::Tools::Execution->oneRun();

    } 'Run workflow AddHost';

    # Browse all notification messages of the mail notifier to check if subscribed states are notified
    try {
        while (1) {
            $genericdaemon->oneRun(cbname => $queue, duration => 1);
        }
    }
    catch (Kanopya::Exception::MessageQueuing::NoMessage $err) {
        # No more mail notification
    }
    catch ($err) {
        throw Kanopya::Exception(error => $err);
    }

    lives_ok {
        if (scalar(@notified_states)) {
            die "States " . Dumper(\@notified_states) . " should not be notified."
        }
    } 'Check for remaining not notifed states';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

1;
