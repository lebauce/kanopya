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
use base 'EEntity::EComponent';

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

# generate configuration files on node
sub addNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['host','mount_point']);

    my $cluster = $self->_getEntity->getServiceProvider;
    my $data = $self->_getEntity()->getConf();

    #$log->debug(Dumper($args{mount_point}));

    foreach my $row (@{$data->{mountdefs}}) {
        delete $row->{mounttable1_id};
    }

    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/fstab',
        template_dir  => '/templates/components/mounttable',
        template_file => 'fstab.tt',
        data          => $data 
    );
          
    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc'
    );

    my $automountnfs = 0;
    for my $mountdef (@{$data->{mountdefs}}) {
        my $mountpoint = $mountdef->{mounttable1_mount_point};
        $self->getExecutorEContext->execute(command => "mkdir -p $args{mount_point}/$mountpoint");
        
        if ($mountdef->{mounttable1_mount_filesystem} eq 'nfs') {
            $automountnfs = 1;
        }
    }
    
    if ($automountnfs) {
        my $grep_result = $self->getExecutorEContext->execute(
                              command => "grep \"ASYNCMOUNTNFS=no\" $args{mount_point}/etc/default/rcS"
                          );

        if (not $grep_result->{stdout}) {
            $self->getExecutorEContext->execute(
                command => "echo \"ASYNCMOUNTNFS=no\" >> $args{mount_point}/etc/default/rcS"
            );
        }
    }
}



1;
