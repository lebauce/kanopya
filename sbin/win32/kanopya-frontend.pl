use strict;
use warnings;
use Win32;
use Win32::Daemon;

main();

use constant SERVICE_NAME => 'kanopya-frontend';
use constant SERVICE_DESC => 'Frontend service for Kanopya';

sub main
{
   # Get command line argument - if none passed, use empty string
   my $opt = shift (@ARGV) || "";

   # Check command line argument
   if ($opt =~ /^(-i|--install)$/i)
   {
      install_service(SERVICE_NAME, SERVICE_DESC);
   }
   elsif ($opt =~ /^(-r|--remove)$/i)
   {
      remove_service(SERVICE_NAME);
   }
   elsif ($opt =~ /^(--run)$/i)
   {
      # Redirect STDOUT and STDERR to a log file
      # Derive the name of the file from the name of the program
      # The log file will be in the scripts directory, with extension .log
      my ($cwd,$bn,$ext) =
      ( Win32::GetFullPathName($0) =~ /^(.*\\)(.*)\.(.*)$/ ) [0..2] ;
      my $log = $cwd . $bn . ".log"; 
      # Redirect STDOUT and STDERR to log file
      open(STDOUT, ">> $log") or die "Couldn't open $log for appending: $!\n";
      open(STDERR, ">&STDOUT");
      # Autoflush, no buffering
      $|=1;

      # Register the events which the service responds to
      Win32::Daemon::RegisterCallbacks( {
            start       =>  \&Callback_Start,
            running     =>  \&Callback_Running,
            stop        =>  \&Callback_Stop,
            pause       =>  \&Callback_Pause,
            continue    =>  \&Callback_Continue,
         } );
      my %Context = (
         last_state => SERVICE_STOPPED,
         start_time => time(),
      );
      # Start the service passing in a context and indicating to callback
      # using the "Running" event every 2000 milliseconds (2 seconds).
      # NOTE: the StartService method with in 'callback mode' will block, in other
      # words it won't return until the service has stopped, but the callbacks below
      # will respond to the various events - START, STOP, PAUSE etc...
      Win32::Daemon::StartService( \%Context, 2000 );

      # Here the service has stopped
      close STDERR; close STDOUT;
   }
   else
   {
      print "No valid options passed - nothing done\n";
   }
}


sub Callback_Running
{
   my( $Event, $Context ) = @_;

   # Note that here you want to check that the state
   # is indeed SERVICE_RUNNING. Even though the Running
   # callback is called it could have done so before
   # calling the "Start" callback.
   if( SERVICE_RUNNING == Win32::Daemon::State() )
   {
	print 'Running the service: '."\n";
	my $cmd = "START \"\"kanopya-frontend\"\" /Dc:\\opt\\kanopya\\sbin\\win32\\ \"kanopya-frontend.bat\"";
	print $cmd."\n";
	system($cmd);
   }
}   

sub Callback_Start
{
   my( $Event, $Context ) = @_;
	print "Starting the service...\n";
	# my $cmd = "START \"kanopya-frontend\" /DC:\\strawberry\\perl\\bin\\ \"perl.exe\" \"C:\\opt\\kanopya\\sbin\\win32\\kanopya-frontend.pl\"";
	# my $cmd = "START \"\"kanopya-frontend\"\" /Dc:\\opt\\kanopya\\sbin\\win32\\ \"kanopya-frontend.bat\"";
	# my $cmd = "START \"kanopya-frontend\" plackup \"-E production_win32 -p 5000 -workers 10 -a c:\\opt\\kanopya\\ui\\Frontend\\bin\\app.pl\"";
	
	# print $cmd."\n";
	# system($cmd);
	# my $exec = `$cmd`;
	
   $Context->{last_state} = SERVICE_RUNNING;
   Win32::Daemon::State( SERVICE_RUNNING );
}

sub Callback_Pause
{
   my( $Event, $Context ) = @_;

   print "Pausing...\n";

   $Context->{last_state} = SERVICE_PAUSED;
   Win32::Daemon::State( SERVICE_PAUSED );
}

sub Callback_Continue
{
   my( $Event, $Context ) = @_;

   print "Continuing...\n";

   $Context->{last_state} = SERVICE_RUNNING;
   Win32::Daemon::State( SERVICE_RUNNING );
}

sub Callback_Stop
{
   my( $Event, $Context ) = @_;

	print "Stopping...\n";
	# my $cmd = 'taskkill /T /F /FI "WINDOWTITLE eq kanopya-frontend"';
	# my $cmd ='taskkill /IM cmd.exe /F';
	# print $cmd."\n";
	# my $exec = `$cmd`;
   
   $Context->{last_state} = SERVICE_STOPPED;
   Win32::Daemon::State( SERVICE_STOPPED );

   # We need to notify the Daemon that we want to stop callbacks and the service.
   Win32::Daemon::StopService();
}


sub install_service
{
   my ($srv_name, $srv_desc) = @_;
   my ($path, $parameters);
   
   # Get the program's full filename
   my $fn = Win32::GetFullPathName($0);

  # Source perl script - invoke perl interpreter
  $path = "\"$^X\"";
   # my $inc = ' -IC:\opt\kanopya\ui\lib -IC:\opt\kanopya\lib\common -IC:\opt\kanopya\lib\administrator -IC:\opt\kanopya\lib\executor -IC:\opt\kanopya\lib\monitor -IC:\opt\kanopya\lib\orchestrator -IC:\opt\kanopya\lib\external';
   
  
  # The command includes the --run switch needed in main()
      $parameters = "\"$fn\" --run";

	#gather login and pwd
	my $login;
	my $pwd;
	print "Please enter your full Kanopya machine user: \n";
	chomp($login = <STDIN>);
	print "Please enter your full Kanopya machine password: \n";
	ReadMode('noecho');
	chomp($pwd = <STDIN>);
	ReadMode('original');
	
   # Populate the service configuration hash
   # The hash is required by Win32::Daemon::CreateService
   my %srv_config = (
      name         => $srv_name,
      display      => $srv_name,
	  user			=> $login,
	  password		=> $pwd,
      path         => $path,
      description  => $srv_desc,
      parameters   => $parameters,
      service_type => SERVICE_WIN32_OWN_PROCESS,
      start_type   => SERVICE_AUTO_START,
   );
   # Install the service
   if( Win32::Daemon::CreateService( \%srv_config ) )
   {
      print "Service installed successfully\n";
   }
   else
   {
      print "Failed to install service\n";
   }
}

sub remove_service
{
   my ($srv_name, $hostname) = @_;
   $hostname ||= Win32::NodeName();
   if ( Win32::Daemon::DeleteService ( $srv_name ) )
   {
      print "Service uninstalled successfully\n";
   }
   else
   {
      print "Failed to uninstall service\n";
   }
}