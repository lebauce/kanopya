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


=pod
=begin classdoc

TODO

=end classdoc
=cut


package Entity::User;
use base "Entity";

use strict;
use warnings;

use DateTime;
use Kanopya::Exceptions;
use General;
use Profile;
use UserProfile;
use Entity::Gp;
use Quota;

use TryCatch;
use Log::Log4perl "get_logger";

my $log = get_logger("");


use constant ATTR_DEF => {
    user_login => {
        label        => 'Login',
        type         => 'string',
        pattern      => '^\w*$',
        is_mandatory => 1,
        is_editable  => 0,
        description  => 'The user login name, for the web interface as well as for his/her VMs',
    },
    user_desc => {
        label        => 'Description',
        type         => 'text',
        # Impossible to check char used because of \n doesn't match with \w
        pattern      => '.*',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'The user description. Specify his business unit, company, ...',
    },
    user_password => {
        label        => 'Password',
        type         => 'password',
        pattern      => '^.+$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'The user password',
    },
    user_firstname => {
        label        => 'First name',
        type         => 'string',
        pattern      => '^.+$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'The first name of the user',
    },
    user_lastname => {
        label        => 'Last name',
        type         => 'string',
        pattern      => '^.+$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'The last name of the user',
    },
    user_email => {
        label        => 'Email',
        type         => 'string',
        pattern      => '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$',
        is_mandatory => 1,
        is_editable  => 1,
        description  => 'The e-mail address of the user',
    },
    user_sshkey => {
        label        => 'SSH Public key',
        type         => 'text',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'The SSH Key of the user. HCM can push SSH keys on all the managed systems.',
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
        pattern      => '.*',
        is_mandatory => 0,
        is_editable  => 0
    },
    user_system => {
        label        => 'Grant full permissions',
        type         => 'boolean',
        pattern      => '^\w*$',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'If enabled, this user will be a super-user no matter what his roles/profiles say.',
    },
    quotas => {
        label        => 'Quotas',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'The quotas of the user. HCM can put an upper limit on the RAM and '.
                        'CPU core usage of a user.',
    },
    user_profiles => {
        label        => 'Profiles',
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'profile',
        is_mandatory => 0,
        is_editable  => 1,
        description  => 'HCM offers different user profiles (Administrator, Project Manager, Operator,'.
                        ' Customer. Read more informations in the full user documentation.',
    },
};

sub getAttrDef{ return ATTR_DEF; }

sub methods {
    return {
        setProfiles => {
            description => 'set user profiles',
            perm_holder => 'entity',
        },
    };
}


sub new {
    my ($class, %args) = @_;

    $args{user_password}     = General::cryptPassword(password => $args{user_password});
    $args{user_creationdate} = DateTime->now->set_time_zone('local');
    $args{user_lastaccess}   = undef;

    return $class->SUPER::new(%args);
}

=pod
=begin classdoc

Overrides <method>Entity::setAttr</method>.

Crypt password

=end classdoc
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

=pod
=begin classdoc

Overrides <method>BaseDB::update</method>.

Crypt password

=end classdoc
=cut

sub update {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'override_relations' => 1 });

    if (exists $args{user_password} && $args{user_password} ne $self->user_password) {
        $log->debug('Hashing password');
        $args{user_password} = General::cryptPassword(password => $args{user_password});
    }

    $self->SUPER::update(%args);
}

sub label {
    my ($self, %args) = @_;

    return $self->user_firstname . ' ' . $self->user_lastname . ' (' . $self->user_login . ')';
}


=pod
=begin classdoc

Consume any resource type in the user quota.

=end classdoc
=cut

sub consumeQuota {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'resource', 'amount' ],
                         optional => { 'dryrun' => 0 });

    # Search for a quota for this resource
    my $quota;
    eval {
        $quota = Quota->find(hash => { user_id => $self->id, resource => $args{resource} });
    };
    # If a quota exixts, try to consume some resource
    if ($quota) {
        $quota->consume(amount => $args{amount}, dryrun => $args{dryrun});
    }
}


=pod
=begin classdoc

Check if we can consume amount on quata only.

=end classdoc
=cut

sub canConsumeQuota {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'resource', 'amount' ]);

    $self->consumeQuota(dryrun => 1, %args);
}


=pod
=begin classdoc

Check if we can consume amount on quata only.

=end classdoc
=cut

sub releaseQuota {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'resource', 'amount' ]);

    # Search for a quota for this resource
    my $quota;
    eval {
        $quota = Quota->find(hash => { user_id => $self->id, resource => $args{resource} });
    };
    # If a quota exixts, try to consume some resource
    if ($quota) {
        $quota->release(amount => $args{amount});
    }
}

sub setProfiles {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'profile_names' ]);

    # Firstly check the validity for profiles
    my $profilestoset = {};
    foreach my $profile_name (@{$args{profile_names}}) {
        eval {
            $profilestoset->{$profile_name} = Profile->find(hash => { profile_name => $profile_name });
        };
        if ($@) {
            throw Kanopya::Exception::Internal::IncorrectParam(error => "Unknown profile $profile_name");
        }
    }

    # Then browse the current user profiles, and remove profiles not defined
    # in the profile list given in parameters
    foreach my $user_profile ($self->user_profiles) {
        if (defined $profilestoset->{$user_profile->profile->profile_name}) {
            delete $profilestoset->{$user_profile->profile->profile_name};
        }
        else {
            $user_profile->remove();
        }
    }
    # Finally create the newly defined profiles
    foreach my $profile (values %{ $profilestoset }) {
        UserProfile->create(user_id => $self->id, profile_id => $profile->id);
    }
}



=pod
=begin classdoc

Override the parent mathod to remove the password from the search criteria.

=cut

sub findOrCreate {
    my ($class, %args) = @_;

    my $password = delete $args{user_password};
    try {
        return $class->find(hash => \%args);
    }
    catch ($err) {
        return $class->create(user_password => $password, %args);
    }
}

1;
