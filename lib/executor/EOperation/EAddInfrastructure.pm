# EAddCluster.pm - Operation class implementing Cluster creation operation

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
# Created 14 july 2010

=head1 NAME

EEntity::Operation::EAddInfrastructure - Operation class implementing Infrastructure creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Infrastructure creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EAddInfrastructure;
use base "EOperation";

use strict;
use warnings;

use JSON -support_by_pp;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;

use Entity::Infrastructure;
use Entity::Systemimage;
use Entity::Tier;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

    my $op = EEntity::EOperation::EAddMotherboard->new();

EEntity::Operation::EAddMotherboard->new creates a new AddMotheboard operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

    $op->_init() is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;

    return;
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    
    General::checkParams(args => \%args, required => ["internal_cluster"]);
    
    my $adm = Administrator->new();
    my $params = $self->_getOperation()->getParams();
    $self->{_file_path} = $params->{file_path};
    
    $self->{_file_path} =~ /.*\/(.*)$/;
    my $file_name = $1;
    $self->{_file_name} = $file_name;

    $self->{_objs} = {};
    
    $self->{econtext} = EFactory::newEContext(ip_source => "127.0.0.1", ip_destination => "127.0.0.1");

}



sub execute {
    my $self = shift;

    my $adm = Administrator->new();
#    open (my $json_file, $self->{_file_path}) or die "an error occured while opening $self->{_file_path}: $!";
#    my @decoded_json = @{decode_json($json_file)};
    my $infrastructure_def;
    my $json_infra= new JSON;
    my $json;
    {
        local $/; #enable slurp
        open my $fh, "<", $self->{_file_path};
        $json = <$fh>;
        close $fh;
    } 
    $json_infra->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey();
    $infrastructure_def = $json_infra->decode($json);

    my $local_nameserver = "127.0.0.1";
    #TODO dev kanopya->getLocalNameserver

     $self->{_objs} = {};
    my $infrastructure = {
        infrastructure_reference    => $infrastructure_def->{reference},
        infrastructure_min_node     => $infrastructure_def->{size}->{min},
        infrastructure_max_node     => $infrastructure_def->{size}->{max},
        infrastructure_version      => $infrastructure_def->{version},
        infrastructure_desc         => $infrastructure_def->{description},
        infrastructure_domainname   => $infrastructure_def->{domain_name},
        infrastructure_nameserver   => $local_nameserver,
        infrastructure_tier_number  => $infrastructure_def->{tier_number},
        infrastructure_name         => $infrastructure_def->{name},
        infrastructure_priority     => $infrastructure_def->{priority},
    };
    # Infrastructure instantiation
    eval {
        $self->{_objs}->{infrastructure} = Entity::Infrastructure->new(%$infrastructure);
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddInfrastructure->prepare : Infrastructure instanciation failed because : " . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    $self->{_objs}->{infrastructure}->save();
    my $tiers = $infrastructure_def->{tier};
    my $i =0;
    $self->{_objs}->{tiers} = [];
    foreach my $tier (@$tiers) {
            my $tmp_tier = {infrastructure_id       => $self->{_objs}->{infrastructure}->getAttr(name=>"infrastructure_id"),
                            tier_name               => $tier->{name},
                            tier_rank               => $tier->{rank},
                            tier_data_src           => $tier->{data}->[0]->{repository},
                            tier_poststart_script   =>$tier->{data}->[0]->{init_script}
            };
            # Infrastructure instantiation
            eval {
                $self->{_objs}->{tiers}->[$i] = Entity::Tier->new(%$tmp_tier);
                $self->{_objs}->{tiers}->[$i]->save();
                $i++;
            };
            if($@) {
                my $err = $@;
                $errmsg = "EOperation::EAddInfrastructure->prepare : Infrastructure instanciation failed because : " . $err;
                $log->error($errmsg);
                throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
            }
        }

}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;