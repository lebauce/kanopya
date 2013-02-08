# HAProxy1.pm - HAProxy1 component
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

package Entity::Component::HAProxy1;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }

sub getConf {
    my $self = shift;

    my $conf = {};

    my $confindb = $self->{_dbix};
    if($confindb) {
        my %row = $confindb->get_columns(); 
        $conf = \%row;
    }

    return $conf;
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};
    if (not $conf->{haproxy1_id}) {
        # new configuration -> create
        $self->{_dbix}->create($conf);
    } else {
        # old configuration -> update
        $self->{_dbix}->update($conf);
    }
}

sub getNetConf {
    my $self = shift;
    
    my $conf = $self->getConf();
    
    # TODO manage check depending on master node or not
    return;
    #return { $conf->{haproxy1_http_frontend_port} => ['tcp'],
    #         $conf->{haproxy1_https_frontend_port} => ['tcp', 'ssl'] };

}

sub getBaseConfiguration {
    return {
        haproxy1_http_frontend_port => 80,
        haproxy1_http_backend_port => 8080,
        haproxy1_https_frontend_port => 443,
        haproxy1_https_backend_port => 4443,
        haproxy1_log_server_address => "0.0.0.0:514",
    };
}

sub insertDefaultExtendedConfiguration {
    my $self = shift;
    my %args = @_;

    # Retrieve admin ip
    my $admin_ip = "0.0.0.0";

    $self->setAttr(name => "haproxy1_log_server_address", value => "$admin_ip:514");
    $self->save();
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return "class { 'kanopya::haproxy': }\n";
}

1;
