# EComponent.pm - Abstract class of EComponents object

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

EComponent - Abstract class of component object

=head1 SYNOPSIS



=head1 DESCRIPTION

EComponent is an abstract class of component objects

=head1 METHODS

=cut
package EEntity::EComponent;
use base "EEntity";

use strict;
use warnings;

use String::Random;
use Template;
use Log::Log4perl "get_logger";
use Nmap::Scanner;
use General;
use EFactory;

our $VERSION = '1.00';

my $log = get_logger("executor");
my $errmsg;


=head2 new

    my comp = EComponent->new();

EComponent::new creates a new component object.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
	$self->_init();
    
    return $self;
}

=head2 _init

EComponent::_init is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;

	return;
}

=head2 addInitScripts

add start and stop rc init scripts

=cut

sub addInitScripts {
	my $self = shift;
	my %args = @_;
	
	if ((! exists $args{etc_mountpoint} or ! defined $args{etc_mountpoint}) ||
		(! exists $args{econtext} or ! defined $args{econtext}) ||
		(! exists $args{scriptname} or ! defined $args{scriptname}) ||
		(! exists $args{startvalue} or ! defined $args{startvalue}) ||
		(! exists $args{stopvalue} or ! defined $args{stopvalue})) {
			$errmsg = "EEntity::EComponent->addInitScripts needs a etc_mountpoint, econtext,scriptname, startvalue, stopvalue  named argument!";
			$log->error($errmsg);
			throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
		
	foreach my $startlevel ((2, 3, 4, 5)) { 
      		my $command = "ln -fs ../init.d/$args{scriptname} $args{etc_mountpoint}/rc$startlevel.d/S$args{startvalue}$args{scriptname}";
      		$log->debug($command);
      		my $result = $args{econtext}->execute(command => $command);
      		#TODO gere les erreurs d'execution
  	}
  	
  	foreach my $stoplevel ((0, 1, 6)) { 
      		my $command = "ln -fs ../init.d/$args{scriptname} $args{etc_mountpoint}/rc$stoplevel.d/K$args{stopvalue}$args{scriptname}";
      		$log->debug($command);
      		my $result = $args{econtext}->execute(command => $command);
      		#TODO gere les erreurs d'execution
    }	
}


sub generateFile {
	my $self = shift;
	my %args = @_;
	
	General::checkParams( args => \%args, require => ['econtext', 'mount_point','input_file','data','output'] );
	
	my $template_dir = defined $args{template_dir} 	? $args{template_dir}
													: $self->_getEntity()->getTemplateDirectory();
	
	my $config = {
	    INCLUDE_PATH => $template_dir,
	    INTERPOLATE  => 1,               # expand "$var" in plain text
	    POST_CHOMP   => 0,               # cleanup whitespace 
	    EVAL_PERL    => 1,               # evaluate Perl code blocks
	    RELATIVE => 1,                   # desactive par defaut
	};
	
	my $rand = new String::Random;
	my $template = Template->new($config);
	
	# generation 
	my $tmpfile = $rand->randpattern("cccccccc");
	
	$template->process($args{input_file}, $args{data}, "/tmp/".$tmpfile) || do {
		$errmsg = "error during generation from '$args{input_file}':" .  $template->error;
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);	
	};
	$args{econtext}->send(src => "/tmp/$tmpfile", dest => $args{mount_point} . $args{output});	
	unlink "/tmp/$tmpfile";
	
}

sub addNode {}
sub removeNode {}
sub stopNode {}
sub postStartNode {}
sub preStartNode{}
sub preStopNode{return 0;}
sub postStopNode{}

sub is_up {
    my $self = shift;
    my %args = @_;
    my $availability = 1;
    
    General::checkParams( args => \%args, require => ['cluster', 'host', 'host_econtext'] );

    my $execution_list = $self->{_entity}->getExecToTest();
    my $net_conf = $self->{_entity}->getNetConf();

    # Test executable
    foreach my $i (keys %$execution_list) {
        my $ret = $args{host_econtext}->execute(command=>$execution_list->{$i}->{cmd});
        $log->debug("Test executable <$i> with command $execution_list->{$i}->{cmd}");
        
    }
    # Test Services
    foreach my $j (keys %$net_conf) {
        my $scanner = new Nmap::Scanner;
        $scanner->max_rtt_timeout(200);
        my $ip = $args{host}->getInternalIP()->{ipv4_internal_address};
        $scanner->add_target($ip);
        if ($net_conf->{$j} eq "udp") {
            $scanner->udp_scan();
        }
        else {
            $scanner->tcp_connect_scan();
        }
        $scanner->add_scan_port($j);
        my $results = $scanner->scan();
        my $port_state = $results-> get_host_list()->get_next()->get_port_list()->get_next()->state();
        $log->debug("Check host <$ip> on port $j ($net_conf->{$j}) is <$port_state>");
        if ($port_state eq "closed"){
            return 0;
        }
    }
    return 1;
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
