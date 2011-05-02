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

use strict;
use warnings;
use String::Random;
use Template;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);

use lib qw(/workspace/mcs/Common/Lib);
use base "EEntity";

my $log = get_logger("executor");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

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

=head2 generateFile
	
	Class : Public
	
	Desc : Generate a file using a template file and data, and send it to the desired location using econtext 
	
=cut

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


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
