#    Copyright © 2011 Hedera Technology SAS
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
package EEntity::EComponent::EMounttable1;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

# generate configuration files on node
sub configureNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "econtext", "host", "mount_point" ]);

    my $data = $self->_getEntity()->getConf();

    #$log->debug(Dumper($args{econtext}));
    #$log->debug(Dumper($args{mount_point}));

    foreach my $row (@{$data->{mountdefs}}) {
        delete $row->{mounttable1_id};
    }

    #$log->debug(Dumper($data));

    $self->generateFile(econtext     => $args{econtext},
                        mount_point  => $args{mount_point} . "/etc",
                        template_dir => "/templates/components/mounttable",
                        input_file   => "fstab.tt",
                        output       => "/fstab",
                        data         => $data);

    my $automountnfs = 0;
    for my $mountdef (@{$data->{mountdefs}}) {
        my $mountpoint = $mountdef->{mounttable1_mount_point};
        $args{econtext}->execute(command => "mkdir -p $args{mount_point}/$mountpoint");
        
        if ($mountdef->{mounttable1_mount_filesystem} eq 'nfs') {
            $automountnfs = 1;
        }
    }
    
    if ($automountnfs) {
        my $grep_result = $args{econtext}->execute(
                              command => "grep \"ASYNCMOUNTNFS=no\" $args{mount_point}/etc/default/rcS"
                          );

        if (not $grep_result->{stdout}) {
            $args{econtext}->execute(
                command => "echo \"ASYNCMOUNTNFS=no\" >> $args{mount_point}/etc/default/rcS"
            );
        }
    }
}

sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ "econtext", "host", "mount_point" ]);

    $self->configureNode(%args);
}

1;
