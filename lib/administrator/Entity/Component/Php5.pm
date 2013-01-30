# Php5.pm - Php5 component
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

package Entity::Component::Php5;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    php5_session_handler => {
        label => 'Session handler',
        type => 'enum',
        options => ['files','memcache'],
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    php5_session_path => {
        label => 'Session path for files handler',
        type => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub getConf {
    my $self = shift;

    my $conf = { php5_session_handler => "files", php5_session_path => "/var/lib/php5" };

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
    if (not $conf->{php5_id}) {
        # new configuration -> create
        $self->{_dbix}->create($conf);
    } else {
        # old configuration -> update
        $self->{_dbix}->update($conf);
    }
    
}

sub getBaseConfiguration {
    return {
        php5_session_path => "/var/lib/php5",
        php5_session_handler => 'files'
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return "class { 'apache::mod::php': }\n" .
           "class { 'php5': }\n";
}

1;
