#    Copyright © 2013 Hedera Technology SAS
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

=pod
=begin classdoc

Contain the connection singleton, provide methods to connect,
open/close transaction and some database information utils.

@since    2012-Jun-10
@instance hash
@self     $class

=end classdoc
=cut

package Kanopya::Database;

use strict;
use warnings;

use General;
use Kanopya::Exceptions;
use Kanopya::Config;

use Module::Find;

use Log::Log4perl "get_logger";
my $log = get_logger("connection");

use TryCatch;
my $err;

# Loading schemas, firstly load custom schema definition
# and then load generated ones.
useall Kanopya::Schema::Custom;
use Kanopya::Schema;


my $adm = {
    # DBix database schema
    schema => undef,
    # Libkanopya configuration
    config => undef,
    # Current logged in user
    user   => undef,
    # Must authenticate ? Global setting.
    global_user_check => 1
};


=pod
=begin classdoc

Return the $adm instance if defined, instanciate it instead.
The $adm singleton contains the database schema to proccess
queries, the loaded configuration and the current user informations.

@return the adminitrator singleton

=end classdoc
=cut

sub _adm {
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'no_user_check' => 0 });

    if (! $adm->{config}) {
        $adm->{config} = _loadconfig();
    }

    if (not defined $adm->{schema}) {
        $adm->{schema} = _connectdb(config => $adm->{config});
    }

    unless ($args{no_user_check} or ! $adm->{global_user_check}) {
        if (not exists $ENV{EID} or not defined $ENV{EID}) {
            $err = "No valid session registered:";
            $err .= " authenticate must be call with a valid login/password pair";
            throw Kanopya::Exception::AuthenticationRequired(error => $err);
        }

        if (! defined $adm->{user} || $adm->{user}->{user_id} != $ENV{EID}) {
            my $user = $adm->{schema}->resultset('User')->find($ENV{EID});

            # Set new user infomations in the adm singleton
            if (defined $user) {
                $adm->{user} = {
                    user_id     => $user->id,
                    user_system => $user->user_system,
                };
            }
        }
    }
    return $adm;
}


=pod
=begin classdoc

@return the config singleton.

=end classdoc
=cut

sub config {
    return _adm->{config}->{dbconf};
}


=pod
=begin classdoc

@return the schema singleton.

=end classdoc
=cut

sub schema {
    return _adm->{schema};
}

=pod
=begin classdoc

@return A DBI handle for direct database access.
This should only be used by migration scripts written in Perl.

=end classdoc
=cut

sub dbh {
    return schema->storage->dbh;
}


=pod
=begin classdoc

@return the user singleton.

=end classdoc
=cut

sub user {
    return _adm->{user};
}

=pod
=begin classdoc

Whether the current singleton must authenticate the user or not
(parameter "value" must be 1 if authentication is desired, 0 otherwise).
This is a global setting for the whole Kanopya::Database.
If it's just for one access, use the "no_user_check" option to _adm().

@return the config singleton.

=end classdoc
=cut
sub global_user_check {
    my (%args) = @_;
    General::checkParams(args => \%args, required => ['value']);
    if ($args{value} != 0 and $args{value} != 1) {
        throw Kanopya::Exception::Internal::IncorrectParam(
            error => "Kanopya::Database::global_user_check: value must be 1 or 0"
        );
    }
    $adm->{global_user_check} = $args{value};
}


=pod
=begin classdoc

Return the current logged user id.

@return the current user id.

=end classdoc
=cut

sub currentUser {
    return user->{user_id};
}


=pod
=begin classdoc

Authenticate the user on the permissions management system.

=end classdoc
=cut

sub authenticate {
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'login', 'password' ]);

    my $user_data = _adm(no_user_check => 1)->{schema}->resultset('User')->search({
                        user_login    => $args{login},
                        user_password => General::cryptPassword(password => $args{password}),
                    })->single;

    if(not defined $user_data) {
        $err = "Authentication failed for login " . $args{login};
        throw Kanopya::Exception::AuthenticationFailed(error => $err);
    }
    else {
        $log->debug("Authentication succeed for login " . $args{login});
        $ENV{EID} = $user_data->id;
        $user_data->update({ user_lastaccess => \'NOW()' });
    }
}


=pod
=begin classdoc

Start a transction on the ORM.

=end classdoc
=cut

sub beginTransaction {
    $log->debug("Beginning database transaction");

    schema->txn_begin;
}


=pod
=begin classdoc

Commit a transaction according the database configuration.

=end classdoc
=cut

sub commitTransaction {
    my $counter = 0;
    my $commited = 0;

    COMMIT:
    while ($counter++ < config->{txn_commit_retry}) {
        try {
            $log->debug("Committing transaction to database");

            schema->txn_commit;
            $commited = 1;
        }
        catch ($err) {
            $log->error("Transaction commit failed: $err");
        }
        if ($commited) { last COMMIT; }
    }
}


=pod
=begin classdoc

Rollback (cancel) an openned transaction.

=end classdoc
=cut

sub rollbackTransaction {
    $log->debug("Rollbacking database transaction");
    try {
        schema->txn_rollback;
    }
    catch ($err) {
        $log->warn($err);
    }
}


=pod
=begin classdoc

Get the configuration config module and check the configuration
constants existance

@return the configuration hash

=end classdoc
=cut

sub _loadconfig {
    my $config = Kanopya::Config::get('libkanopya');

    General::checkParams(args => $config->{dbconf}, required => [ 'name', 'password', 'type', 'host', 'user', 'port' ]);

    General::checkParams(args => $config->{amqp}, required => [ 'user', 'password' ]);

    if (! defined ($config->{dbconf}->{txn_commit_retry})) {
        $config->{dbconf}->{txn_commit_retry} = 10;
    }

    $config->{dbi} = "dbi:" . $config->{dbconf}->{type} . ":" . $config->{dbconf}->{name} .
                     ":" . $config->{dbconf}->{host} . ":" . $config->{dbconf}->{port};

    return $config;
}


=pod
=begin classdoc

Get the DBIx schema by connecting to the database server.

@return the whole databse schema

=end classdoc
=cut

sub _connectdb {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'config' ]);

    try {
        return Kanopya::Schema->connect($args{config}->{dbi},
                                        $args{config}->{dbconf}->{user},
                                        $args{config}->{dbconf}->{password},
                                        { mysql_enable_utf8 => 1 });
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(error => $err);
    }
}

1;
