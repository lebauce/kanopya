use strict;
use warnings;
use Win32;
use Win32::Daemon;
use Win32::Process;
use Data::Dumper;

use constant SERVICE_NAME => 'kanopya-orchestrator';
use constant SERVICE_DESC => 'Orchestrator service for Kanopya';

main();

sub main {
    # Get command line argument - if none passed, use empty string
    my $opt = shift (@ARGV) || "";

    # Check command line argument
    if ($opt =~ /^(-i|--install)$/i) {
        install_service(srv_name => SERVICE_NAME, srv_desc => SERVICE_DESC, dir => $ARGV[0], login => $ARGV[1], pwd => $ARGV[2]);
    }
    elsif ($opt =~ /^(-r|--remove)$/i) {
        remove_service(SERVICE_NAME);
    }
    elsif ($opt =~ /^(--run)$/i) {

        # Redirect STDOUT and STDERR to a log file
        # Derive the name of the file from the name of the program
        # The log file will be in the scripts directory, with extension .log
        my ($cwd,$bn,$ext) =
            (Win32::GetFullPathName($0) =~ /^(.*\\)(.*)\.(.*)$/ ) [0..2];
        my $log = $cwd . $bn . ".log";
        # Redirection
        open(STDOUT, ">> $log") or die "Couldn't open $log for appending: $!\n";
        open(STDERR, ">&STDOUT");

        # Autoflush, no buffering
        $|=1;

        # Register the events which the service responds to
        Win32::Daemon::RegisterCallbacks({
            start    => \&Callback_Start,
            running  => \&Callback_Running,
            stop     => \&Callback_Stop,
            pause    => \&Callback_Pause,
            continue => \&Callback_Continue,
         });
        my %context = (
            last_state => SERVICE_STOPPED,
            start_time => time(),
            dir        => $ARGV[0],
        );

        Win32::Daemon::StartService(\%context, 10000);

        # Here the service has stopped
        close STDERR; close STDOUT;
    }
    else {
        print "No valid options passed - nothing done\n";
    }
}

sub Callback_Running {
    my( $Event, $context ) = @_;

    if(SERVICE_RUNNING == Win32::Daemon::State()) {
    print 'main running loop'."\n";
    $context->{pid} = fork();

        if ($context->{pid} == 0) { # Child
            while (1 == 1) {
                print 'Running the service: '."\n";
                my $cmd = "perl $context->{dir}\\kanopya\\sbin\\kanopya-orchestrator";
                print $cmd."\n";
                system($cmd);
            }
        }
        else {
            while (SERVICE_STOP_PENDING != Win32::Daemon::State()) {
               sleep 5;
            }
            #### We are done so close down... ###
            print "SERVICE STOP PENDING IS RECEIVED\n";
            Win32::Daemon::State( SERVICE_STOPPED );
            Win32::Daemon::StopService();
            # kill(9, $context->{pid});
            my $tokill = 'orchestrator';
            my $cmd    = 'WMIC PROCESS WHERE (Commandline LIKE \'%'
                         .$tokill
                         .'%\' AND name LIKE \'perl.exe\' AND NOT Commandline LIKE \'%%WMIC\') call terminate';
            print $cmd."\n";
            system($cmd);
            exit;
        }
    }
}

sub Callback_Start {
    my($Event, $context) = @_;
    print "Starting the service...\n";

    $context->{last_state} = SERVICE_RUNNING;
    Win32::Daemon::State(SERVICE_RUNNING);
}

sub Callback_Pause {
    my($Event, $context) = @_;

    print "Pausing...\n";

    $context->{last_state} = SERVICE_PAUSED;
    Win32::Daemon::State(SERVICE_PAUSED);
}

sub Callback_Continue {
    my($Event, $context) = @_;

    print "Continuing...\n";

    $context->{last_state} = SERVICE_RUNNING;
    Win32::Daemon::State(SERVICE_RUNNING);
}

sub Callback_Stop {
    my($Event, $context) = @_;

    print "Stopping...\n";

    $context->{last_state} = SERVICE_STOPPED;
    Win32::Daemon::State(SERVICE_STOPPED);

    # We need to notify the Daemon that we want to stop callbacks and the service.
    Win32::Daemon::StopService();
}

sub install_service {
    my %args = @_;
    my ($path, $parameters);

    # Get the program's full filename
    my $fn = Win32::GetFullPathName($0);

    # Source perl script - invoke perl interpreter
    $path = "\"$^X\"";

    # The command includes the --run switch needed in main()
    $parameters = "\"$fn\" --run $args{dir}";

    # Populate the service configuration hash
    # The hash is required by Win32::Daemon::CreateService
    my %srv_config = (
        name         => $args{srv_name},
        display      => $args{srv_name},
        user         => $args{login},
        password     => $args{pwd},
        path         => $path,
        description  => $args{srv_desc},
        parameters   => $parameters,
        service_type => SERVICE_WIN32_OWN_PROCESS,
        start_type   => SERVICE_AUTO_START,
    );
    # Install the service
    if( Win32::Daemon::CreateService(\%srv_config)) {
        print "Service installed successfully\n";
    }
    else {
        print "Failed to install service\n";
    }
}

sub remove_service {
    my ($srv_name, $hostname) = @_;
    $hostname ||= Win32::NodeName();
    if (Win32::Daemon::DeleteService($srv_name)) {
        print "Service uninstalled successfully\n";
    }
    else {
        print "Failed to uninstall service\n";
    }
}
