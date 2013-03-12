# EEntity.pm - Entity is the highest general execution object

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

=pod
=begin classdoc

EEntity - EEntity is the highest general execution object

=end classdoc
=cut
package EEntity;

use strict;
use warnings;

use Entity;
use Entity::Host;
use Kanopya::Exceptions;
use Kanopya::Config;
use EContext;

use File::Basename;
use Template;
use vars qw ( $AUTOLOAD );

use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);

my $log = get_logger("");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };


my $mocks_classes = {};
my $host;

sub new {
    my ($class, %args) = @_;

    $args{entity} = $args{entity} || $args{data};

    General::checkParams(args     => \%args,
                         required => [ 'entity' ],
                         optional => { 'eclass' => $class->eclass(class => ref($args{entity})) });

    # Use a possibly defined mock for this execution class
    $args{eclass} = $mocks_classes->{$args{eclass}}
                        ? $args{eclass} . '::' . $mocks_classes->{$args{eclass}} : $args{eclass};

    while ($args{eclass} ne "EEntity") {
        my $location = General::getLocFromClass(entityclass => $args{eclass});
        eval { require $location; };
        if ($@) {
            my $err = $@;
            # If file does not exists, use the parent package
            if ($err =~ m/Can't locate $location/) {
                $args{eclass} =~ s/\:\:[a-zA-Z0-9]+$//g;
            }
            else { die $err; }
        }
        else { last; }
    }

    my $self = {
        _entity => $args{entity},
        config  => Kanopya::Config::get('executor')
    };

    bless $self, $args{eclass};
    return $self;
}

sub eclass {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'class' ]);
    
    $args{class} =~s/\:\:/\:\:E/g;
    return "E" . $args{class};
}

sub getEContext {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'dst_host' ]);

    return EContext->new(src_host => $self->_host, dst_host => $args{dst_host});
}

sub generateNodeFile {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => ['cluster','host','file','template_dir','template_file','data']
    );
    
    my $config = Kanopya::Config::get('executor');

    my $path = $config->{clusters}->{directory};
    $path .= '/' . $args{cluster}->cluster_name;
    $path .= '/' . $args{host}->node->node_hostname;
    $path .= '/' . $args{file};
    my ($filename, $directories, $prefix) = fileparse($path);

    $self->_host->getEContext->execute(command => "mkdir -p $directories");
    
    my $template_conf = {
        INCLUDE_PATH => $args{template_dir},
        INTERPOLATE  => 0,               # expand "$var" in plain text
        POST_CHOMP   => 0,               # cleanup whitespace
        EVAL_PERL    => 1,               # evaluate Perl code blocks
        RELATIVE     => 1,               # desactive par defaut
    };

    my $template = Template->new($template_conf);
    eval {
        $template->process($args{template_file}, $args{data}, $path);
    };
    if($@) {
        $errmsg = "error during generation from '$args{template}':" .  $template->error;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    return $path;
}

sub setMock {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'mock' => undef });

    $mocks_classes->{$class} = $args{mock};
}

=pod
=begin classdoc

Build a notification message with a given Operation

@param operation
@return notification message

=end classdoc
=cut

sub notificationMessage {
    my $self    = shift;
    my %args    = @_;

    General::checkParams(
        args        => \%args,
        required    => [ 'operation' ]
    );

    my $message = "";

    my $template        = Template->new(General::getTemplateConfiguration());
    my $templatedata    = { operation => $args{operation}->label };
    $template->process('notificationmail.tt', $templatedata, \$message)
        or throw Kanopya::Exception::Internal(
             error => "Error when processing template notificationmail.tt"
         );

    return $message;
}

sub _host {
    my $self = shift;
    my %args = @_;

    return $host if defined $host;

    my $hostname = `hostname`;
    chomp($hostname);

    $host = EEntity->new(entity => Entity::Host->find(hash => { 'node.node_hostname' => $hostname }));
    return $host;
}

sub _entity {
    my $self = shift;
    return $self->{_entity};
}

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $method = $autoload[-1];

    return $self->_entity->$method(%args);
}

sub DESTROY {
    my $self = shift;
    my %args = @_;
}

1;
