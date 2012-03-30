# EHost.pm - Abstract class of EHosts object

#    Copyright © 2011-2012 Hedera Technology SAS
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

EHost - execution class of host entities

=head1 SYNOPSIS



=head1 DESCRIPTION

EHost is the execution class of host entities

=head1 METHODS

=cut
package EEntity::EHost;
use base "EEntity";

use Entity::Powersupplycard;

use strict;
use warnings;

use Entity;
use String::Random;
use Template;
use IO::Socket;
use Net::Ping;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    $self->{sp} = Entity::ServiceProvider->get(
                      id => $self->_getEntity->getAttr(name => "service_provider_id")
                  );

    $self->{host_manager} = EFactory::newEEntity(
                                data => $self->{sp}->getManager(
                                   id => $self->_getEntity->getAttr(name => "host_manager_id")
                                )
                            );

    $self->{host} = $self->_getEntity();

    $log->debug("Created a EHost");
    return $self;
}

sub start {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "econtext" ]);

    $self->{host_manager}->startHost(cluster  => $self->{sp},
                                     host     => $self->{host},
                                     econtext => $args{econtext});

    $self->{host}->setState(state => 'starting');
}

sub halt {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "node_econtext" ]);

    my $result = $args{node_econtext}->execute(command => 'halt');
    $self->{host}->setState(state => 'stopping');
}

sub stop {
    my $self = shift;
    my %args = @_;

    $self->{host_manager}->stopHost(cluster => $self->{sp},
                                    host    => $self->{host});
}

sub postStart {
    my $self = shift;
    my %args = @_;

    $self->{host_manager}->postStart(cluster => $self->{sp},
                                     host    => $self->{host});
}

sub checkUp {
    my $self = shift;
    my %args = @_;

    my $ip = $self->{host}->getInternalIP()->{ipv4_internal_address};
    my $ping = Net::Ping->new();
    my $pingable = $ping->ping($ip);
    $ping->close();
    
    if ($pingable) {
        eval {
            my $node_econtext = EFactory::newEContext(
                                    ip_source      => '127.0.0.1',
                                    ip_destination => $ip
                                );
            $log->debug("In checkUP test if host <$ip> is pingable <$pingable>\n");
        };
        if ($@) {
            $log->info("Ehost->checkUp for host <$ip>, host pingable but not sshable");
            return 0;
        }
    }

    return $pingable;
}

sub generateUdevPersistentNetRules {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => [ 'econtext', 'etc_path' ]);

    my $rand = new String::Random;
    my $tmpfile = $rand->randpattern("cccccccc");

    # create Template object
    my $template = Template->new(General::getTemplateConfiguration());
    my $input = "udev_70-persistent-net.rules.tt";

    my @interfaces = ();
    
    for my $iface ($self->_getEntity()->getIfaces()) {
        my $tmp = {
            mac_address   => lc($iface->{iface_mac_addr}),
            net_interface => $iface->{iface_name}
        };
        push @interfaces, $tmp;
    }
       
    $template->process($input, { interfaces => \@interfaces }, "/tmp/" . $tmpfile)
        or die $template->error(), "\n";

    $args{econtext}->send(
        src => "/tmp/$tmpfile",
        dest => "$args{etc_path}/udev/rules.d/70-persistent-net.rules"
    );
    unlink "/tmp/$tmpfile";
}

sub generateHostname {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         required => ['econtext', 'etc_path']);

    my $hostname = $self->_getEntity()->getAttr(name => 'host_hostname');
    $args{econtext}->execute(
        command => "echo $hostname > $args{etc_path}/hostname"
    );
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2011-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
