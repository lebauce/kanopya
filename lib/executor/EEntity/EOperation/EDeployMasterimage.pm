#    Copyright 2011 Hedera Technology SAS
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

package EEntity::EOperation::EDeployMasterimage;
use base "EEntity::EOperation";

use strict;
use warnings;

use Data::Dumper;
use XML::Simple;
use File::Temp qw/ tempdir /;
use File::Copy qw/ move /;
use File::Path qw/ mkpath /;
use Kanopya::Config;
use Kanopya::Exceptions;
use Entity::Masterimage;
use Entity::ServiceProvider::Cluster;
use ClassType::ServiceProviderType::ClusterType;
use Entity::Gp;
use EEntity;

use TryCatch;
my $err;

use Log::Log4perl "get_logger";
my $log = get_logger("");


sub check {
    my $self = shift;
    my %args = @_;
    $self->SUPER::check();

    General::checkParams(args => $self->{params}, required => [ "file_path" ]);
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();
    my ($cmd, $cmd_res);

    # check file_path set
    my $file_path = $self->{params}->{file_path};

    if (not defined $file_path) {
        throw Kanopya::Exception::Internal(
                  error => "Invalid operation argument ; $file_path not defined !"
              );
    }

    # check tarball existence
    if (! -e $file_path) {
        throw Kanopya::Exception::Internal(
                  error => "Invalid operation argument ; $file_path not found !"
              );
    }

    # check tarball format
    if (`file $file_path` !~ /(bzip2|gzip) compressed data/) {
        throw Kanopya::Exception::Internal(
                  error => "Invalid operation argument ; $file_path must be a gzip or bzip2 compressed file !"
              );
    }
    else {
        $self->{params}->{compress_type} = $1;
        $self->{params}->{file} = $file_path;
    }

    # Instanciate tftp server
    my $tftp = Entity::ServiceProvider::Cluster->getKanopyaCluster->getComponent(category => 'Tftpserver');
    $self->{context}->{tftp_component} = EEntity->new(entity => $tftp);

    # Untar master image archive in a temporary folder
    my $tmpdir = tempdir(CLEANUP => 1);
    $log->debug("Unpack archive files from archive '$self->{params}->{file}' into $tmpdir");
    my $compress = $self->{params}->{compress_type} eq 'bzip2' ? 'j' : 'z';
    $cmd = "tar -x -$compress -f $self->{params}->{file} -C $tmpdir"; 
    $cmd_res = $self->getEContext->execute(command => $cmd);

    # check metadata file exists
    my $metadatafile = "$tmpdir/img-metadata.xml";
    if(! -e $metadatafile) {
        throw Kanopya::Exception::Internal(error => "File missing in archive ; $metadatafile");
    }
    
    # parse and validate metadata file
    # TODO check metadata format and values
    my $metadata = XMLin($metadatafile, ForceArray => [ "kernel", "component" ]); # , ForceArray => 'name');

    General::checkParams(args     => $metadata,
                         required => [ "file", "name" ],
                         optional => { "type" => "Cluster", "kernel" => undef });

    my $imagefile = $metadata->{file};
    
    # retrieve master images directory
    $log->debug(Dumper $metadata);
    my $directory = $self->_executor->getConf->{masterimages_directory};
    $directory =~ s/\/$//g;
    
    # get the image size
    $cmd = "du -s --bytes $tmpdir/$imagefile | awk '{print \$1}'";
    $cmd_res = $self->getEContext->execute(command => $cmd);
    my $image_size = $cmd_res->{stdout};  
    
    # create the directory for the image
    mkpath("$directory/$imagefile");
    
    # move image and metadata to the directory
    move("$tmpdir/$imagefile", "$directory/$imagefile");
    move($metadatafile, "$directory/$imagefile");

    # Get the cluster type
    my $clustertype;
    try {
        $clustertype = ClassType::ServiceProviderType::ClusterType->find(hash => {
                            service_provider_name => $metadata->{type}
                       });
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Unknown distribution type <$metadata->{type}>"
              );
    }
    catch ($err) {
        $err->rethrow();
    }

    # register the available kernels
    my $defaultkernel;
    if (defined $metadata->{kernel}) {
        while (my ($name, $infos) = each(%{$metadata->{kernel}})) {
            my $kernel;
            eval {
                $kernel = Entity::Kernel->find(hash => { kernel_name => $name });
            };
            if ($@) {
                # move image and metadata to the directory
                my $tftpdir = $self->{context}->{tftp_component}->getTftpDirectory;
                move("$tmpdir/" . $infos->{file}, $tftpdir);

                if (defined ($infos->{initrd})) {
                    move("$tmpdir/" . $infos->{initrd}, $tftpdir);
                }

                $kernel = Entity::Kernel->new(
                              kernel_name    => $name,
                              kernel_version => $infos->{version},
                              kernel_desc    => $infos->{description}
                          );
            }

            if ($infos->{default}) {
                $defaultkernel = $kernel->id;
            }
        }
    }

    # delete uploaded archive
    if (! $self->{params}->{keep_file}) {
        unlink $self->{params}->{file};
    }

    my $masterimage = Entity::Masterimage->new(
                          masterimage_name             => $metadata->{name},
                          masterimage_file             => "$directory/$imagefile/$imagefile",
                          masterimage_desc             => $metadata->{description},
                          masterimage_os               => $metadata->{os},
                          masterimage_size             => $image_size,
                          masterimage_cluster_type_id  => $clustertype->id,
                          masterimage_defaultkernel_id => $defaultkernel
                      );

    # set components
    foreach my $name (keys %{ $metadata->{component} }) {
        my $vers = $metadata->{component}->{$name}->{version};
        $log->debug("Set provided component: $name, $vers");
        $masterimage->setProvidedComponent(component_name    => $name,
                                           component_version => $vers);
    }
}

1;
