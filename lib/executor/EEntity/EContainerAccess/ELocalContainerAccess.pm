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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EContainerAccess::ELocalContainerAccess;
use base "EEntity::EContainerAccess";

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");
use Data::Dumper;


sub connect {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $file = $self->getContainer->container_device;

    my $retry = 20;
    do {
        $result = $args{econtext}->execute(command => "[ -f $file ]");
        if ($result->{exitcode} != 0) {
            if ($retry <= 0) {
                my $errmsg = "Unable to find waited file <$file>";
                throw Kanopya::Exception::Execution($errmsg);
            }
            $retry -= 1;
            $log->debug("File  not found yet (<$file>), sleeping 1s and retry.");
            sleep 1;
        }
    } while (defined $result && $result->{exitcode} != 0);

    $log->debug("Return file loop dev (<$file>).");
    $self->setAttr(name  => 'device_connected', value => $file);

    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('disconnect'),
            parameters => [ $self, "econtext", $args{econtext} ]
        );
    }

    return $file;
}


sub disconnect {
    my $self = shift;
    my %args = @_;
    my ($command, $result);

    General::checkParams(args => \%args, required => [ 'econtext' ]);

    my $file = $self->getContainer->container_device;

    $self->setAttr(name  => 'device_connected',
                   value => '');
}

1;
