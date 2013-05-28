# Puppetagent2.pm - Puppet agent (Adminstrator side)
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
# Created 4 sept 2010

package Entity::Component::Puppetagent2;
use base "Entity::Component";

use strict;
use warnings;

use Entity::ServiceProvider::Cluster;
use Kanopya::Exceptions;
use Kanopya::Config;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    puppetagent2_options => {
        label         => 'Puppet agent options',
        type          => 'string',
        pattern       => '^.*$',
        is_mandatory  => 0,
        is_editable   => 1,
    },
    puppetagent2_mode => {
        label         => 'Puppet Master to use',
        type          => 'enum',
        options       => ['kanopya','custom'],
        pattern       => '^.*$',
        is_mandatory  => 1,
        is_editable   => 1,
    },
    puppetagent2_masterip => {
        label         => 'Puppet Master IP',
        type          => 'string',
        pattern       => '^.*$',
        is_mandatory  => 0,
        is_editable   => 1,
    },
    puppetagent2_masterfqdn => {
        label         => 'Puppet Master FQDN',
        type          => 'string',
        pattern       => '^.*$',
        is_mandatory  => 0,
        is_editable   => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub priority { return 5; }

sub setConf {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};
    if ($conf->{puppetagent2_mode} eq 'kanopya') {
        my $master = $self->getPuppetMaster->getMasterNode;

        $conf->{puppetagent2_masterip}   = $master->adminIp;
        $conf->{puppetagent2_masterfqdn} = $master->fqdn;
    }
    $self->SUPER::setConf(conf => $conf);
}

sub getPuppetMaster {
    my $self = shift;
    my %args = @_;

    my $kanopya_cluster = Entity::ServiceProvider::Cluster->getKanopyaCluster();
    return $kanopya_cluster->getComponent(name => "Puppetmaster");
}

sub getHostsEntries {
    my ($self) = @_;

    my $fqdn = $self->puppetagent2_masterfqdn;
    my @tmp = split(/\./, $fqdn);
    my $hostname = shift @tmp;

    return [ { ip         => $self->puppetagent2_masterip,
               fqdn       => $fqdn,
               aliases    => [ $hostname ] } ];
}

sub getBaseConfiguration {
    my ($class) = @_;

    my $master = $class->getPuppetMaster->getMasterNode;

    return {
        puppetagent2_options    => '',
        puppetagent2_mode       => 'kanopya',
        puppetagent2_masterip   => $master->adminIp,
        puppetagent2_masterfqdn => $master->fqdn
    };
}

1;
