# Copyright © 2014 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

Preserve original Kanopya DB after a test

Usage :

    perl -MKanopya::Tools::PreserveDB foo.t

or

    prove --exec 'perl -MKanopya::Tools::PreserveDB' *.t

=end classdoc

=cut

package Kanopya::Tools::PreserveDB;

use Kanopya::Database;

my $filepath;

=pod
=begin classdoc

Dump kanopya DB in the file /tmp/kanopya_dump_<time>.sql where <time> is the current time in epoch

@return the path of the created sql file

=end classdoc
=cut

sub dumpKanopyaDB {
    my $config = Kanopya::Database::config;
    my $dump_cmd = 'mysqldump'
                   . ' --user=' . $config->{user}
                   . ' --password=' . $config->{password}
                   . ' ' . $config->{name};

    my $filepath = '/tmp/kanopya_dump_' . time() . '.sql';
    system($dump_cmd . ' > ' . $filepath);

    return $filepath;
}

=pod
=begin classdoc

Restore kanopya DB from a sql file

@param filepath the path of the sql file

=end classdoc
=cut

sub restoreKanopyaDB {
    my (%args) = @_;
    General::checkParams(args => \%args, required => [ 'filepath' ]);
    my $config = Kanopya::Database::config;
    my $restore_cmd = 'mysql'
                      . ' --user=' . $config->{user}
                      . ' --password=' . $config->{password}
                      . ' ' . $config->{name};

    system($restore_cmd . ' < ' . $args{filepath});
}

# This code block is executed at the very beginning of the test
BEGIN {
    Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');
    $filepath = dumpKanopyaDB();
    system('mount -t tmpfs -o size=512M tmpfs /var/cache/kanopya/monitor');
}

# This code block is executed at the very end of the test
END {
    system('umount /var/cache/kanopya/monitor');
    restoreKanopyaDB(filepath => $filepath);
}

1;
