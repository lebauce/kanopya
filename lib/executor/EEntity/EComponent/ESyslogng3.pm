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
package EEntity::EComponent::ESyslogng3;

use strict;
use Template;
use String::Random;
use base "EEntity::EComponent";
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

# generate configuration files on node
sub configureNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ "host", "mount_point" ]);

    my $template_path = $args{template_path} || "/templates/components/syslogng";
    
    my $data = $self->_getEntity()->getConf();
        
    $self->generateFile(
         mount_point => $args{mount_point},
        template_dir => $template_path,
          input_file => "syslog-ng.conf.tt", 
              output => "/syslog-ng/syslog-ng.conf",
                data => $data
    );
}

sub addNode {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ "host", "mount_point" ]);

    $self->configureNode(
               host => $args{host},
        mount_point => $args{mount_point}.'/etc');

    # add init scripts
    $self->addInitScripts(
        mountpoint => $args{mount_point},
        scriptname => 'syslog-ng',
    );
}

# Reload process
sub reload {
    my $self = shift;
    my %args = @_;

    my $command = "invoke-rc.d syslog-ng restart";
    my $result = $self->getEContext->execute(command => $command);
    return undef;
}

1;
