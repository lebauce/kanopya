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

package EEntity::EComponent::EHpcManager;
use base "EEntity::EComponent";
use base "EManager::EHostManager";

use strict;
use warnings;

use EContext::SSH;

use Text::CSV;
use Data::Dumper;

=head2 get_blades

    Desc: retrieve informations about the HPC blades

=cut

sub get_blades {
    my $self = shift;

    my $bladesystem_ip    = '172.21.3.11';
    my $virtualconnect_ip = '172.21.3.13';

    my $bladesystem_context    = EContext::SSH->new(
        ip       => $bladesystem_ip,
        timeout  => 30,
        username => 'Administrator'
    );
    my $virtualconnect_context = EContext::SSH->new(
        ip       => $virtualconnect_ip,
        timeout  => 30,
        username => 'Administrator'
    );

    my $bsReturn = $bladesystem_context->execute(command => 'SHOW SERVER INFO ALL');
    # -output=script2 is actually CSV...
    my $vcReturn = $virtualconnect_context->execute(command => 'show profile * -output=script2');
    my @blades   = $self->_parseOutputs(
        bladesystem    => $bsReturn->{stdout},
        virtualconnect => $vcReturn->{stdout}
    );

    return @blades;
}

sub _parseOutputs {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'bladesystem', 'virtualconnect' ]);

    my $_id   = 'Serial Number';
    my $_mac  = 'MAC Address';
    my $_pxe  = 'PXE';

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
                for my $i (1..$#lines) {
                    $csv->parse($lines[$i]);
                    @columns  = $csv->fields;
                    my $iface = {
                        PXE     => ($columns[$pxe] eq 'Enabled') ? 1 : 0,
                        MACAddr => $columns[$macAddr]
                    };
                    push @{$blades{$bladeId}->{ifaces}}, $iface;
                }
            }
        }
    }

    return %blades;
}

=head2 synchronize

    Desc: synchronize hpc7000 information with kanopya database

=cut

sub synchronize {
    my $self = shift;
    my %args = @_;

    my @blades = $self->get_blades();

    foreach my $blade (@blades) {
    }
}

1;
