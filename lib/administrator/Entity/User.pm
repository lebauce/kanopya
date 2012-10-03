#    Copyright © 2011 Hedera Technology SAS
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

package Entity::User;
use base "Entity";

use strict;
use warnings;

use Administrator;
use DateTime;
use Kanopya::Exceptions;
use General;
use Profile;
use Entity::Gp;

use Log::Log4perl "get_logger";

our $VERSION = "1.00";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    user_login => {
        label        => 'Login',
        type         => 'string',
        pattern      => '^\w*$',
        is_mandatory => 1,
        is_editable  => 0
    },
    user_desc => {
        label        => 'Description',
        type         => 'text',
        # Impossible to check char used because of \n doesn't match with \w
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1
    },
    user_password => {
        label        => 'Password',
        type         => 'password',
        pattern      => '^.+$',
        is_mandatory => 1,
        is_editable  => 1
    },
    user_firstname => {
        label        => 'First name',
        type         => 'string',
        pattern      => '^.+$',
        is_mandatory => 1,
        is_editable  => 1
    },
    user_lastname => {
        label        => 'Last name',
        type         => 'string',
        pattern      => '^.+$',
        is_mandatory => 1,
        is_editable  => 1
    },
    user_email => {
        label        => 'Email',
        type         => 'string',
        pattern      => '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$',
        is_mandatory => 1,
        is_editable  => 1
    },
    user_sshkey => {
        label        => 'SSH Public key',
        type         => 'text',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1
    },
    user_creationdate => {
        label        => 'Account creation date',
        type         => 'date',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 0
    },
    user_lastaccess => {
        label        => 'Last access',
        type         => 'date',
        pattern      => '^\w*$',
        is_mandatory => 0,
        is_editable  => 0
    },
    user_profiles => {
        label        => 'Profiles',
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'profile',
        is_mandatory => 0,
        is_editable  => 1,
    }
};

sub methods {
    return {
        create => {
            description => 'create a new user',
            perm_holder => 'mastergroup',
        },
        get => {
            description => 'view this user',
            perm_holder => 'entity',
        },
        update => {
            description => 'save changes applied on this user',
            perm_holder => 'entity',
        },
        remove => {
            description => 'delete this user',
            perm_holder => 'entity',
        },
        setperm => {
            description => 'set permissions on this user',
            perm_holder => 'entity',
        },
        getProfiles => {
            description => 'get user profiles',
            perm_holder => 'entity',
        },
        setProfiles => {
            description => 'set user profiles',
            perm_holder => 'entity',
        },
        getExtensions => {
            description => 'get extended user attributes',
            perm_holder => 'entity',
        },
        setExtension => {
            description => 'create or update extended user attribute',
            perm_holder => 'entity',
        },
    };
}

=head2 getUsers

    Class: public
    desc: retrieve several Entity::User instances
    args:
        hash : hashref : where criteria
    return: @ : array of Entity::User instances
    
=cut

sub getUsers {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

=head2 create 

=cut

sub create {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    my $cryptpasswd = General::cryptPassword(password => $self->{_dbix}->user_password);
    $self->{_dbix}->user_password($cryptpasswd);
    my $dt = DateTime->now->set_time_zone('local');
    $self->{_dbix}->user_creationdate("$dt");
    $self->{_dbix}->user_lastaccess(undef);
    $self->save();
    return $self;
}

sub new {
    my $self = shift;
    $self->create();
}

=head2 setAttr

    overide setAttr to crypt password

=cut 

sub setAttr {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['name']);
    my $value;
    if($args{name} eq 'user_password') {
        $args{value} = General::cryptPassword(password => $args{value});
    }
    $self->SUPER::setAttr(%args);
}

=head2 remove

=cut

sub remove {
    my $self = shift;
    $self->SUPER::delete();
}

sub setProfiles {
    my ($self, %args) = @_; 
    my $adm = Administrator->new;
    $self->{_dbix}->user_profiles->delete_all;
    foreach my $profile_name (@{$args{profile_names}}) {
        eval {
            my $profile = Profile->find(hash => { profile_name => $profile_name } );

            # Link the user to the profile
            $self->{_dbix}->user_profiles->create({ profile_id => $profile->id });

            # Automatically add the user in the groups associated to this profile
            my $rs = $profile->{_dbix}->profile_gps;
            while (my $row = $rs->next) {
                my $gp = Entity::Gp->get(id => $row->gp->id);
                $gp->appendEntity(entity => $self);
            }
        };
        if ($@) {
            throw Kanopya::Exception::Internal::IncorrectParam(error => "Unknown profile $profile_name");
        }
    }
}

sub getProfiles {
    my ($self) = @_;
    my $result = $self->{_dbix}->user_profiles; 
    my @array = ();
    while(my $row = $result->next) {
        push @array, $row->profile->get_column('profile_name');
    }
    return \@array;
}

sub getExtensions {
    my ($self) = @_;
    my $extensions = [];
    my $rs = $self->{_dbix}->user_extensions;
    while (my $row = $rs->next) {
        my %hash = ( 
            id    => $row->get_column('user_extension_id'),
            key   => $row->get_column('user_extension_key'),
            value => $row->get_column('user_extension_value'),
        );
        push @$extensions, \%hash;
    }
    return $extensions;
}

sub setExtension {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['key','value']);
    my $rs = $self->{_dbix}->user_extensions->update_or_create(
        { user_extension_key => $args{key},user_extension_value => $args{value} },
        { key => 'user_id' }
    );
    
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('user_firstname'). " ". $self->{_dbix}->get_column('user_lastname');
    return $string;
}

sub getAttrDef{
    return ATTR_DEF;
}

1;
