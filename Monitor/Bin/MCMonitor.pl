# MCMonitor.pl - This is the main script to run microCluster Monitoring server.

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

MCMonitor - MCMonitor Server

=head1 SYNOPSIS	    

	$ ./MCMonitor

=head1 DESCRIPTION

Monitor is the main script to run microCluster Monitor server.

=head1 METHODS

=cut


use strict;
use warnings;
use Proc::PID::File;
use lib "/workspace/mcs/Monitor/Lib";
use Monitor::Collector;
use Log::Log4perl "get_logger";
use Error qw(:try);

Log::Log4perl->init('/workspace/mcs/Monitor/Conf/log.conf');
my $log = get_logger("collector");

# If already running, then exit
if( Proc::PID::File->running()) {
    $log->warn("$0 already running ; don't start another process");
    exit(1);
}



my $running = 1;

sub signalHandler {
	my $sig = shift;
	$log->info($sig." received : stopping main loop");
	$running = 0;
}

$SIG{TERM} = \&signalHandler;
	
$log->info("MCMonitor.pl PID: $$");

try	{
	my $collector = Monitor::Collector->new();
	$log->info("Starting main loop");
	# enter in the main loop and continue while $$running is true
	$collector->run(\$running);
}
catch Error::Simple with {
	my $ex = shift;
	die "Catch error in Monitor instanciation: $ex";
};

$log->info("MCMonitor end.");






__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
