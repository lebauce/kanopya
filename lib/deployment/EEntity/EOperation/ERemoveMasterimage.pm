#    Copyright © 2013 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EOperation::ERemoveMasterimage;
use base "EEntity::EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use EEntity;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Cluster;
use Entity::Masterimage;
use File::Basename;

my $log = get_logger("");
my $errmsg;


sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "masterimage" ]);
}

sub execute {
    my $self = shift;

    # Check if the masterimage is used by any clusters
    my $masterimage_id = $self->{context}->{masterimage}->getAttr(name => 'entity_id');
    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {
                       masterimage_id => $masterimage_id
                   });

    if (scalar(@clusters)) {
        throw Kanopya::Exception::Internal::WrongValue(
                  error => "Masterimage <$masterimage_id> is used by at least one cluster."
              );        
    }

    # delete master image directory
    my $directory = dirname($self->{context}->{masterimage}->getAttr(name => 'masterimage_file'));

    if (dirname($directory) eq '/') {
        throw Kanopya::Exception::Internal::WrongValue(
                  error => "Sounld not remove $directory, aborting..."
              );
    }

    my $cmd = "rm -rf $directory";
    
    $self->getEContext->execute(command => $cmd);
    $self->{context}->{masterimage}->delete();
}

1;
