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
package EEntity::EComponent::EPuppetmaster2;
use base 'EEntity::EComponent';

use strict;
use warnings;

use Template;
use File::Path qw/ mkpath /;
use File::Temp qw/ tempdir tmpnam /;
use YAML "DumpFile";
use Log::Log4perl 'get_logger';
use TryCatch;

my $log = get_logger("");
my $errmsg;

# generate configuration files on node

sub configureNode {
    my ($self, %args) = @_;
    my $data;

    my $conf = $self->_entity->getConf();

    # Generation of /etc/default/puppetmaster
    $data = { 
        puppetmaster2_options   => $conf->{puppetmaster2_options},
    };
    
    $self->generateFile(
        file          => $args{mount_point} . '/etc/default/puppetmaster',
        template_dir  => "components/puppetmaster",
        template_file => "default_puppetmaster.tt",
        data          => $data
    );
}

sub addNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mount_point', 'host' ]);
  
    $self->configureNode(
        mount_point => $args{mount_point}.'/etc',
        host        => $args{host}
    );

    $self->addInitScripts(    
        mountpoint => $args{mount_point}, 
        scriptname => 'puppet', 
    );
    
}

sub updateSite {
    my ($self) = @_;
    my $command = 'touch /etc/puppet/manifests/site.pp';
    $self->getEContext->execute(command => $command);
}

sub createHostCertificate {
    my ($self, %args) = @_;
 
    General::checkParams(args => \%args, required => [ 'mount_point', 'host_fqdn' ]);
    
    my $certificate = $args{host_fqdn} . '.pem';

    # check if new certificate is required
    my $command = "find /etc/puppet/ssl/certs -name $certificate";
    my $result = $self->getEContext->execute(command => $command);

    if (! $result->{stdout}) {
        # generate a certificate for the host
        $command = "puppet ca generate $args{host_fqdn}";
        my $result = $self->getEContext->execute(command => $command);
        # TODO check for error in command execution
    }

    # clean existing certificates information
    $command = 'rm -rf ' . $args{mount_point} . '/var/lib/puppet/ssl/*';
    $self->_host->getEContext->execute(command => $command);

    my $tmpdir = tempdir(CLEANUP => 1);
    mkpath($tmpdir . "/ssl/certs");
    mkpath($tmpdir . "/ssl/private_keys");

    # We do not use 'mkdir' because of a strange guestmount bug that forbids us
    # to create a folder in the puppet folder if it's owned by the 'puppet' user
    $self->_host->getEContext->send(
        src  => $tmpdir . "/ssl",
        dest => $args{mount_point} . '/var/lib/puppet/'
    );

    # copy master certificate to the image
    try {
        $self->getEContext->retrieve(
            src  => '/var/lib/puppet/ssl/certs/ca.pem',
            dest => $args{mount_point} . '/var/lib/puppet/ssl/certs/ca.pem'
        );
    }
    catch ($err) {
        my $msg = "Error while copying master certificate to the images, $err\n";
        throw Kanopya::Exception::IO(error => $msg);
    }
    
    # copy host certificate to the image
    $self->getEContext->retrieve(
        src  => '/var/lib/puppet/ssl/certs/' . $certificate,
        dest => $args{mount_point} . '/var/lib/puppet/ssl/certs/' . $certificate
    );
    
    # copy host private key to the image
    $self->getEContext->retrieve(
        src  => '/var/lib/puppet/ssl/private_keys/' . $certificate,
        dest => $args{mount_point} . '/var/lib/puppet/ssl/private_keys/' . $certificate
    );

    $self->updateSite;
}


sub removeHostCertificate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_fqdn' ]);

    # Remove the certificate
    my $command = "puppetca clean $args{host_fqdn}";
    my $result = $self->getEContext->execute(command => $command);
    if (! $result->{stdout}) {
        # TODO check for error in command execution
    }
}


sub createHostManifest {
    my ($self, %args) = @_;
    General::checkParams(args => \%args,
                         required => [ 'node', 'puppet_definitions' ],
                         optional => { configuration => {} });

    my $fqdn = $args{node}->fqdn;
    my $cluster = $args{node}->service_provider->cluster_name;
    my $sourcepath = $cluster . '/' . $args{node}->node_hostname;

    my $data = {
        host_fqdn          => $fqdn,
        cluster            => $cluster,
        puppet_definitions => $args{puppet_definitions},
        sourcepath         => $sourcepath
    };

    $self->generateFile(
        host          => EEntity->new(entity => $self->getMasterNode->host),
        template_dir  => 'components/puppetmaster',
        template_file => 'host_manifest.pp.tt',
        file          => '/etc/puppet/manifests/nodes/' . $fqdn . '.pp',
        data          => $data,
        user          => 'puppet',
        group         => 'puppet'
    );

    my ($fh, $filename) = tmpnam();
    DumpFile($filename, $args{configuration});
    close $fh;

    my $path = $self->_executor->getConf->{clusters_directory} . '/' .
               $sourcepath . '/' .
               $fqdn . ".yaml";

    $self->getEContext->send(src   => $filename,
                             dest  => $path,
                             user  => 'puppet',
                             group => 'puppet');

    $self->updateSite;
}

1;
