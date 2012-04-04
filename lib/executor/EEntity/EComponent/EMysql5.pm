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
package EEntity::EComponent::EMysql5;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext','host','mount_point']);

    $args{mount_point} .= '/etc';

    my $data = $self->_getEntity()->getConf();    
        
    # generation of /etc/mysql/my.cnf
    $self->generateFile( econtext => $args{econtext}, mount_point => $args{mount_point},
                         template_dir => "/templates/components/mysql5",
                         input_file => "my.cnf.tt", output => "/mysql/my.cnf", data => $data);

    $self->addInitScripts(etc_mountpoint => $args{mount_point}, 
                                econtext => $args{econtext}, 
                                scriptname => 'mysql', 
                                startvalue => '18', 
                                stopvalue => '02');
    
}

sub removeNode {}

sub reload {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['econtext']);

    my $command = "invoke-rc.d mysql restart";
    my $result = $args{econtext}->execute(command => $command);
    return undef;
}

1;
