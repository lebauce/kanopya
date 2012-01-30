# EComponent.pm - Abstract class of EComponents object

#    Copyright 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
use Data::Dumper;
use String::Random;
use Template;
use Log::Log4perl "get_logger";
#use Nmap::Scanner;
use General;
use EFactory;

our $VERSION = '1.00';

my $log = get_logger("executor");
my $errmsg;

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
            throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
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

    General::checkParams( args => \%args, required => ['econtext', 'mount_point','input_file','data','output'] );

    my $template_dir = defined $args{template_dir} ? $args{template_dir}
                                                   : $self->_getEntity()->getTemplateDirectory();

    my $config = {
        INCLUDE_PATH => $template_dir,
        INTERPOLATE  => 0,               # expand "$var" in plain text
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
        throw Kanopya::Exception::Internal(error => $errmsg);
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
sub cleanNode {
#    my $class = shift;
#    my %args = @_;
#
#    General::checkParams(args => \%args,
#                         required => ['host', ]);

}

sub isUp {
    my $self = shift;
    my %args = @_;
    my $availability = 1;

    General::checkParams( args => \%args, required => ['cluster', 'host', 'host_econtext'] );

    my $execution_list = $self->{_entity}->getExecToTest();
    my $net_conf = $self->{_entity}->getNetConf();

    # Test executable
    $log->info("Test component " . ref $self);
    foreach my $i (keys %$execution_list) {
        my $ret;
        eval {
        $ret = $args{host_econtext}->execute(command=>$execution_list->{$i}->{cmd});
        $log->debug("Test executable <$i> with command $execution_list->{$i}->{cmd}");
        $log->debug("Value returned are <$ret->{stdout}> and has to match $execution_list->{$i}->{answer}")
        };
        if ((not defined $ret->{stdout}) || $ret->{stdout}  !~ m/($execution_list->{$i}->{answer})/) {
            return 0;
        }
        if ($@) {
            return 0;
                   }

    }
#    my $scanner = new Nmap::Scanner;
#    $scanner->max_rtt_timeout(200);
    my $ip = $args{host}->getInternalIP()->{ipv4_internal_address};
#    $scanner->add_target($ip);
#        $scanner->fast_scan();

    # Test Services
    while(my ($port, $protocols) = each %$net_conf) {
        my $cmd = "nmap -n ";
        PROTO:
        foreach my $proto (@$protocols) {
            next PROTO if ($proto eq "ssl");
            if ($proto eq "udp") {
                $cmd .= "-sU ";
            }
            else {
                $cmd .= "-sT ";
            }
            $cmd .= "-p $port $ip | grep $port | cut -d\" \" -f1";
            my $port_state = `$cmd`;
                $log->debug("Check host <$ip> on port $port ($proto) is <$port_state>");
            if ($port_state eq "closed"){
                return 0;
               }
        }
    }
    return 1;
}
    # Test Services
#    foreach my $j (keys %$net_conf) {
#        my $cmd = "nmap ";
#        if ($net_conf->{$j} eq "udp") {
#            $cmd .= "-sU ";
##            $scanner->udp_scan();
#        }
#        else {
#            $cmd .= "-sT ";
##            $scanner->tcp_connect_scan();
#        }
#        $cmd .= "-p $j $ip | grep $j | cut -d\" \" -f1";
##        $scanner->add_scan_port($j);
##        my $results = $scanner->scan();
##        my $port_state = $results->get_host_list()->get_next()->get_port_list()->get_next()->state();
#        my $port_state = `$cmd`;
#        $log->debug("Check host <$ip> on port $j ($net_conf->{$j}) is <$port_state>");
#        if ($port_state eq "closed"){
#            return 0;
#        }
##        $scanner->reset_scan_ports();
#     }
#    return 1;


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
