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
use UserProfile;
use Entity::Gp;
use Quota;

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
    user_system => {
        label        => 'Grant full persmissions',
        type         => 'boolean',
        pattern      => '^\w*$',
        is_mandatory => 0,
        is_editable  => 1
    },
    quotas => {
        label        => 'Quotas',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
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

sub getAttrDef{ return ATTR_DEF; }

sub methods {
    return {
        setProfiles => {
            description => 'set user profiles',
            perm_holder => 'entity',
        },
    };
}

=head2 create 

=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    my $cryptpasswd  = General::cryptPassword(password => $self->user_password);
    my $creationdate = DateTime->now->set_time_zone('local');

    $self->setAttr(name => 'user_password', value => $cryptpasswd);
    $self->setAttr(name => 'user_creationdate', value => "$creationdate");
    $self->setAttr(name => 'user_lastaccess', value => undef);
    $self->save();

    return $self;
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

=head2 consumeQuota

    Consume any resource type in the user quota.

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

=head2 canConsumeQuota

    Check if we can consume amount on quata only. 

=cut

sub canConsumeQuota {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'resource', 'amount' ]);

    $self->consumeQuota(dryrun => 1, %args);
}

=head2 releaseQuota

    Check if we can consume amount on quata only. 

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

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('user_firstname'). " ". $self->{_dbix}->get_column('user_lastname');
    return $string;
}

1;
