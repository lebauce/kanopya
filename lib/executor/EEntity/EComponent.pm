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
use General;
use EFactory;

our $VERSION = '1.00';

my $log = get_logger("");
my $errmsg;

=head2 addInitScripts

add start and stop rc init scripts

=cut

sub addInitScripts {
    my ($self, %args) = @_;
    
    General::checkParams(args => \%args, required => [ 'mountpoint', 'scriptname' ]);

    my $cmd = "chroot $args{mountpoint} /sbin/insserv -d $args{scriptname}";
    $self->getExecutorEContext->execute(command => $cmd);
}

=head2 generateFile

    Class : Public

    Desc : Generate a file using a template file and data, and send it to the desired location using econtext

=cut

sub generateFile {
    my $self = shift;
    my %args = @_;

    General::checkParams( args => \%args, required => ['mount_point','input_file','data','output'] );

    if (not defined $args{econtext}) {
        $args{econtext} = $self->getExecutorEContext;
    }

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
sub stopNode {}
sub postStartNode {}
sub preStartNode{}
sub preStopNode{return 0;}
sub postStopNode{}

sub cleanNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args,
                         required => [ 'host' ]);

    eval { $self->preStopNode(%args); };
    eval { $self->stopNode(%args); };
    eval { $self->postStopNode(%args); };
}

sub isUp {
    my ($self, %args) = @_;
    General::checkParams( args => \%args, required => ['cluster', 'host' ] );
    
    my $availability = 1;
    my $execution_list = $self->{_entity}->getExecToTest();
    my $net_conf = $self->{_entity}->getNetConf();

    # Test executable
    foreach my $i (keys %$execution_list) {
        my $ret;
        eval {
            $ret = $args{host}->getEContext->execute(command => $execution_list->{$i}->{cmd});
        };
        if ($@ || (not defined $ret->{stdout}) || $ret->{stdout}  !~ m/($execution_list->{$i}->{answer})/) {
            return 0;
        }
    }

    my $ip = $args{host}->getAdminIp;
    my $econtext = $self->getExecutorEContext;

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
            $cmd .= "-p $port $ip | grep $port | cut -d\" \" -f2";
            my $result = $econtext->execute(command => $cmd);
            my $port_state = $result->{stdout};
            chomp($port_state);
            if ($port_state eq "closed"){
                return 0;
            }
        }
    }
    return 1;
}


=head2 getEContext

=cut

sub getEContext {
    my ($self) = @_;

    my $service_provider = $self->getServiceProvider;
    return EFactory::newEContext(ip_source      => $self->{_executor}->getMasterNodeIp(),
                                 ip_destination => $service_provider->getMasterNodeIp());
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
