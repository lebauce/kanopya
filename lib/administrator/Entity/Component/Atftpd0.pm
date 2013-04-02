# Atftpd0.pm atftp (trivial ftp, part of pxe) component (Adminstrator side)
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
# Created 24 july 2010

package Entity::Component::Atftpd0;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    atftpd0_options => { 
        label        => 'Daemon options',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    atftpd0_repository => { 
        label        => 'Repository path',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    atftpd0_use_inetd => {
        label        => 'Use inetd',
        type         => 'enum',
        options      => ['TRUE','FALSE'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    atftpd0_logfile => {
        label        => 'Log file path',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getConf{
    my $self = shift;
    my $conf_raw = $self->{_dbix};
    return {options => $conf_raw->get_column('atftpd0_options'),
               repository => $conf_raw->get_column('atftpd0_repository'),
               use_inetd => $conf_raw->get_column('atftpd0_use_inetd'),
               logfile => $conf_raw->get_column('atftpd0_logfile')};

}

=head2 getNetConf
B<Class>   : Public
B<Desc>    : This method return component network configuration in a hash ref, it's indexed by port and value is the port
B<args>    : None
B<Return>  : hash ref containing network configuration with following format : {port => protocol}
B<Comment>  : None
B<throws>  : Nothing
=cut

# Warning Atftp bug when a port scan is done
#sub getNetConf {
#    return {69=> ['udp']};
#}
sub getExecToTest {
    return {atftp =>   {cmd => 'netstat -lnpu | grep 69',
                         answer => '.+$',
                         return_code => '0'}
    };
}

sub getBaseConfiguration {
    return {
        atftpd0_options    => '--daemon --tftpd-timeout 300 --retry-timeout 5 --no-multicast --maxthread 100 --verbose=5',
        atftpd0_repository => '/tftp',
        atftpd0_use_inetd  => 'FALSE',
        atftpd0_logfile    => '/var/log/atftpd.log',
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return "class { 'kanopya::atftpd': }\n";
}

sub getTftpDirectory {
    my ($self, %args) = @_;

    return $self->atftpd0_repository;
}

1;
