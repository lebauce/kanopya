#    Copyright © 2011-2012 Hedera Technology SAS
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

=head1 NAME

EFactory - Module which instanciate EEntity and EContext

=head1 SYNOPSIS

    use EFactory;
    
    # Creates an EEntity
    my $eentity = EFactory::newEEntity();
    
    # Create an EContext
    my $econtext = EFactory::newEContext

=head1 DESCRIPTION


=head1 METHODS

=cut
package EFactory;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);

use General;
use Entity;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Net::IP qw(:PROC);

my $log = get_logger("executor");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub newEOperation{
    my %args = @_;

    General::checkParams(args => \%args, required => ['op']);
    my $data = $args{op};
    my $class = "EOperation::E". $args{op}->getType();
#    $log->debug("EOperation class is $class"); 
    my $location = General::getLocFromClass(entityclass => $class);
    
    eval { require $location; };
    if ($@){
        $errmsg = "EFactory->newEOperation : require '$location' failed : $@";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
#    $log->info("$class instanciated");
    return $class->new(data => $args{op});
}

=head2 newEEntity

EFactory::newEEntity($objdata) instanciates a new object EEntity from Entity.

=cut

sub newEEntity {
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['data']);

    my $data = $args{data};
    my %params = (data => $args{data});

    my $class = General::getClassEEntityFromEntity(entity => $data);
    $log->debug("GetClassEEntityFromEntity return $class");

    # Workaround to avoid to have Entity::Host sub-classes corresponding to
    # EEntity::EHost since we dont have specific data in base for instance.
    if ($class eq "EEntity::EHost"){
        $log->debug("Get a new EHost !");

        my $manager = Entity->get($data->{host_manager_id});
        if ($manager->isa("Entity::Component::Opennebula3")) {
            $class .= "::EVirtualHost";
        }
        elsif ($manager->isa("Entity::Connector::UcsManager")) {
            $class .= "::EUcsHost";
        }
    }

    my $location = General::getLocFromClass(entityclass => $class);

    eval { require $location; };
    if ($@){
        $errmsg = "EFactory->newEEntity : require locaction failed (location is $location) : $@";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
#    $log->info("$class instanciated");
    return $class->new(%params);
}

=head2 newEContext

EFactory::newEContext(ip_source, ip_destination) instanciates a new object EContext.

=cut

sub newEContext {
    my %args = @_;

    General::checkParams(args => \%args, required => ['ip_source', 'ip_destination']);

    if (!ip_is_ipv4($args{ip_source})){
        $errmsg = "EFactory::newEContext ip_source needs to be an ipv4 address";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    if (!ip_is_ipv4($args{ip_destination})){
        $errmsg = "EFactory::newEContext ip_source needs to be an ipv4 address";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    #Create EContext::Local or EContext::SSH
    if($args{ip_source} eq $args{ip_destination}) {
        # EContext::Local
        $log->debug("ip_source & ip_destination are the same, using EContext::Local");
        use EContext::Local;
        return EContext::Local->new(local => $args{ip_source});
    } else {
        # EContext::SSH
        use EContext::SSH;
        my $ssh = EContext::SSH->new(local => $args{ip_source},
                                     ip    => $args{ip_destination});
        return $ssh;
    }
}



1;

__END__

=head1 AUTHOR

Copyright (c) 2011-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
