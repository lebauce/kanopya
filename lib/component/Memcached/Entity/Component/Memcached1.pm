# Memcached1.pm - Memcached1 component
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

package Entity::Component::Memcached1;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    memcached1_port => {
        label => 'Port',
        type => 'string',
        pattern      => '^[0-9]+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getConf {
    my $self = shift;

    my $conf = { memcached1_port => "11211" };

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

    # delete old conf
    my $conf = $args{conf};
    my $conf_row = $self->{_dbix};
    $conf_row->delete() if (defined $conf_row);

    # create
    $conf_row = $self->{_dbix}->create( $conf );
}

sub getBaseConfiguration {
    return {
        memcached1_port => '11211'
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        memcached => {
            classes => {
                'kanopya::memcached' => { }
            }
        }
    } );
}

1;
