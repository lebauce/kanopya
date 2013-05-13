#    Copyright © 2012 Hedera Technology SAS
#
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
package Entity::Component::Linux::Redhat;
use base 'Entity::Component::Linux';

use strict;
use warnings;

use Entity::Component::Linux::LinuxMount;

use Log::Log4perl 'get_logger';
use Data::Dumper;

my $log = get_logger("");

sub getPuppetDefinition {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    my $definition = "yumrepo {\n" .
                     "\t\"epel\":\n" .
                     "\t\tdescr          => \"Extra Packages for Enterprise Linux - \\\$basearch\",\n" .
                     "\t\tmirrorlist     => \"http://mirrors.fedoraproject.org/mirrorlist?repo=epel-\\\$releasever&arch=\\\$basearch\",\n" .
                     "\t\tfailovermethod => \"priority\",\n" .
                     "\t\tgpgcheck       => \"0\",\n" .
                     "\t\tenabled        => \"1\";\n" .
                     "}\n";

    my $superDef   = $self->SUPER::getPuppetDefinition(%args);
    return {
        manifest     => $superDef->{manifest} . $definition,
        dependencies => []
    };
}

1;
