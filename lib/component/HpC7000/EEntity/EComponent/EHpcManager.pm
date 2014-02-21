# copyright © 2013 hedera technology sas
#
# this program is free software: you can redistribute it and/or modify
# it under the terms of the gnu affero general public license as
# published by the free software foundation, either version 3 of the
# license, or (at your option) any later version.
#
# this program is distributed in the hope that it will be useful,
# but without any warranty; without even the implied warranty of
# merchantability or fitness for a particular purpose.  see the
# gnu affero general public license for more details.
#
# you should have received a copy of the gnu affero general public license
# along with this program.  if not, see <http://www.gnu.org/licenses/>.

=pod
=begin classdoc

TODO

=end classdoc
=cut

package EEntity::EComponent::EHpcManager;
use base "EEntity::EComponent";
use base "EManager::EHostManager";

use strict;
use warnings;

use EContext::SSH;
use Entity::Host;
use Entity::Iface;

use Text::CSV;
use Data::Dumper;

=pod
=begin classdoc

Retrieve informations about the HPC blades.

=end classdoc
=cut

sub get_blades {
    my $self = shift;

    my $bladesystem_context    = EContext::SSH->new(
        ip       => $self->bladesystem_ip,
        timeout  => 30,
        username => $self->bladesystem_user
    );
    my $virtualconnect_context = EContext::SSH->new(
        ip       => $self->virtualconnect_ip,
        timeout  => 30,
        username => $self->virtualconnect_user
    );

    my $bsReturn = $bladesystem_context->execute(command => 'SHOW SERVER INFO ALL');
    my $vcReturn = $virtualconnect_context->execute(command => 'show profile * -output=script2'); # -output=script2 is actually CSV...
    my @blades   = $self->_parseOutputs(
        bladesystem    => $bsReturn->{stdout},
        virtualconnect => $vcReturn->{stdout}
    );

    return @blades;
}

=pod
=begin classdoc

Extract datas from BladeSystem and VirtualConnect CLIs' stdouts into a hash.

=end classdoc
=cut

sub _parseOutputs {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'bladesystem', 'virtualconnect' ]);

    my $_id   = 'Serial Number';
    my $_mac  = 'MAC Address';
    my $_pxe  = 'PXE';
    my $_name = 'Network Name';

    my @bladesInfo   = split '\n', $args{bladesystem};
    my %blades       = ();
    my $currentBlade = undef;

    for my $line (@bladesInfo) {
        if ($line =~ /^(Server Blade \#\d+) Information:$/) {
            $blades{$currentBlade->{serial_number}} = $currentBlade if $currentBlade != undef;
            $currentBlade = {
                serial_number => undef,
                cores         => 0,
                memory        => undef,
                name          => $1,
                ifaces        => []
            };
        }
        elsif ($currentBlade != undef && $line =~ /^\s*Serial Number: (\w[\w|\s]*)$/) {
            $currentBlade->{serial_number} = $1;
        }
        elsif ($currentBlade != undef && $line =~ /^\s*CPU \d+: .* \((\d+) cores\)$/) {
            $currentBlade->{cores} += int($1);
        }
        elsif ($currentBlade != undef && $line =~ /^\s*Memory: (\d+) (\D+)$/) {
            $currentBlade->{memory} = int($1) * 1024 * 1024;
        }
    }
    $blades{$currentBlade->{serial_number}} = $currentBlade if $currentBlade != undef;

    return () if not scalar keys %blades;

    my $csv     = Text::CSV->new({ binary => 1, sep_char => ';' });
    @bladesInfo = split /^-+\n/m, $args{virtualconnect};
    for my $bladeInfo (@bladesInfo) {
        my $bladeId = '';
        my @chunks  = split /^\s*\n/m, $bladeInfo;
        for my $chunk (@chunks) {
            my @lines   = split '\n', $chunk;
            $csv->parse($lines[0]);
            my @columns = $csv->fields;
            if (scalar grep /^$_id$/, @columns) {
                my ($idIndex) = grep { $columns[$_] =~ /^$_id$/ } 0..$#columns;
                $csv->parse($lines[1]);
                @columns      = $csv->fields;
                $bladeId      = $columns[$idIndex];
            }
            elsif ($bladeId ne '' && scalar grep /^$_mac$/, @columns) {
                my ($macAddr) = grep { $columns[$_] =~ /^$_mac$/ } 0..$#columns;
                my ($pxe)     = grep { $columns[$_] =~ /^$_pxe$/ } 0..$#columns;
                my ($name)    = grep { $columns[$_] =~ /^$_name$/ } 0..$#columns;
                for my $i (1..$#lines) {
                    $csv->parse($lines[$i]);
                    @columns  = $csv->fields;
                    my $iface = {
                        PXE     => ($columns[$pxe] eq 'Enabled') ? 1 : 0,
                        MACAddr => lc $columns[$macAddr],
                        name    => $columns[$name]
                    };
                    $iface->{MACAddr} =~ s/-/:/g;
                    push @{$blades{$bladeId}->{ifaces}}, $iface;
                }
            }
        }
    }

    return %blades;
}

=pod
=begin classdoc

Synchronize hpc7000 information with kanopya database.

=end classdoc
=cut

sub synchronize {
    my $self = shift;
    my %args = @_;

    my $manager_id = $self->entity_id;

    my %blades = $self->get_blades();

    BLADE:
    foreach my $blade_id (keys %blades) {
        my $blade = $blades{$blade_id};
        my @existing_host = Entity::Host->search(
            hash => {
                host_serial_number => $blade->{serial_number},
                host_manager_id    => $manager_id
            }
        );
        next BLADE if scalar @existing_host;

        my $host = Entity::Host->new(
            host_serial_number => $blade->{serial_number},
            host_ram           => $blade->{memory},
            host_core          => $blade->{cores},
            active             => 1,
            host_desc          => $blade->{name},
            host_manager_id    => $manager_id
        );

        my $i = 0;
        for my $iface (@{$blade->{ifaces}}) {
            Entity::Iface->new(
                iface_name     => "eth$i",
                iface_mac_addr => $iface->{MACAddr},
                iface_pxe      => $iface->{PXE},
                host_id        => $host->id
            );
            ++$i;
        }
    }
}

sub _startStopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' , 'command' ]);

    if ($args{host}->host_desc =~ /^Server Blade \#(\d+)$/) {
        my $blade_id = $1;
        my $bladesystem_context    = EContext::SSH->new(
            ip       => $self->bladesystem_ip,
            timeout  => 30,
            username => $self->bladesystem_user
        );
        my $force    = $args{command} eq 'POWEROFF' ? ' FORCE' : '';
        my $bsReturn = $bladesystem_context->execute(command => $args{command} . ' SERVER ' . $blade_id . $force);
    }
    else {
        throw Kanopya::Exception::Internal::IncorrectParam(
            error => 'Provided host ' . $args{host}->id . ' is not a valid HP Blade'
        );
    }
}

sub checkUp {
    return 1;
}

sub startHost {
    my $self = shift;
    my %args = @_;

    $args{command} = 'POWERON';
    $self->_startStopHost(%args);
}

sub stopHost {
    my $self = shift;
    my %args = @_;

    $args{command} = 'POWEROFF';
    $self->_startStopHost(%args);
}

1;
