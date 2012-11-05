#    Copyright © 2012 Hedera Technology SAS
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

package Administrator;

use strict;
use warnings;

use General;
use Entityright::User;
use Entityright::System;
use AdministratorDB::Schema;
use Kanopya::Exceptions;
use Kanopya::Config;
use Log::Log4perl "get_logger";

our $VERSION = "1.00";

my $log = get_logger("");
my $errmsg;

my ($schema, $config, $oneinstance);

=head2 Administrator::loadConfig
    Class : Private

    Desc : This method allow to load configuration from xml file
            ../kanopya/conf/administrator.conf
            File Administrator with config hash containing

    return: scalar string : a dbi data_source used for database connection

=cut

sub _loadconfig {
    $config = Kanopya::Config::get('libkanopya');
    if (! exists $config->{internalnetwork}->{ip} ||
        ! defined $config->{internalnetwork}->{ip} ||
        ! exists $config->{internalnetwork}->{mask} ||
        ! defined $config->{internalnetwork}->{mask})
        {
            $errmsg = "Administrator->new need internalnetwork definition in config file!";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
        }

    if (! exists $config->{dbconf}->{name} ||
        ! defined exists $config->{dbconf}->{name} ||
        ! exists $config->{dbconf}->{password} ||
        ! defined exists $config->{dbconf}->{password} ||
        ! exists $config->{dbconf}->{type} ||
        ! defined exists $config->{dbconf}->{type} ||
        ! exists $config->{dbconf}->{host} ||
        ! defined exists $config->{dbconf}->{host} ||
        ! exists $config->{dbconf}->{user} ||
        ! defined exists $config->{dbconf}->{user} ||
        ! exists $config->{dbconf}->{port} ||
        ! defined exists $config->{dbconf}->{port})
        {
            $errmsg = "Administrator::loadConfig need db definition in config file!";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
        }

    if (! defined ($config->{dbconf}->{txn_commit_retry})) {
        $config->{dbconf}->{txn_commit_retry} = 10;
    }

    return "dbi:" . $config->{dbconf}->{type} .
            ":" . $config->{dbconf}->{name} .
            ":" . $config->{dbconf}->{host} .
            ":" . $config->{dbconf}->{port};
}

sub _connectdb {
    eval {
        my $dbi = _loadconfig() if not defined $config;
        $schema = AdministratorDB::Schema->connect($dbi,
                                                   $config->{dbconf}->{user},
                                                   $config->{dbconf}->{password},
                                                   { mysql_enable_utf8 => 1 });
    };

    if ($@) {
        my $error = $@;
        $log->error($error);
        throw Kanopya::Exception::Internal(error => $error);
    }
}

=head2 Administrator::authenticate (%args)

    Class : Public

    Desc :     method used to authenticate user by login/password.
            ! THIS IS THE FIRST METHOD TO CALL BEFORE instanciating an Administrator;

    args :     login : string scalar : user login
            password : string scalar : user password

=cut

sub authenticate {
    my %args = @_;

    General::checkParams(args => \%args, required => ['login', 'password']);

    if(not defined $schema) {
        _connectdb()
    }

    my $user_data = $schema->resultset('User')->search(
        {
            user_login => $args{login},
            user_password => General::cryptPassword(password => $args{password}),
        }
    )->single;

    if(not defined $user_data) {
        $errmsg = "Authentication failed for login ".$args{login};
        $log->error($errmsg);
        throw Kanopya::Exception::AuthenticationFailed(error => $errmsg);
    } else {
        $log->debug("Authentication succeed for login ".$args{login});
        $ENV{EID} = $user_data->id;
    }
}

=head2

    Desc: start database transaction

=cut

sub beginTransaction {
    my $self = shift;
    $log->debug("Beginning database transaction");
    $self->{db}->txn_begin;
}

=head2

    Desc: try to close the transaction a few times to avoid transaction lock timeout

=cut

sub commitTransaction {
    my $self = shift;
    my $counter = 0;

    while ($counter++ < $config->{dbconf}->{txn_commit_retry}) {
        eval {
            $log->debug("Committing transaction to database");
            $self->{db}->txn_commit;
        };
        if ($@) {
            $log->error("Transaction commit failed: $@");
        }
        else {
            last;
        }
    }
}

=head2

    Desc: rollback database transaction

=cut

sub rollbackTransaction {
    my $self = shift;

    $log->debug("Rollbacking database transaction");
    $self->{db}->txn_rollback;
}

=head2 Administrator::buildEntityright (%args)

    desc : instanciate an Entityright::User/System depending on
            environment variable $ENV{EID}
    args : schema : AdministratorDB::Schema instance
    return : Entityright::User or Entityright::System

=cut

sub buildEntityright {
    my %args =  @_;

    General::checkParams(args => \%args, required => ['schema']);

    if (defined ($config->{dbconf}->{god_mode}) && $config->{dbconf}->{god_mode} eq "1") {
        return Entityright::System->new(user_id => 0, schema => $args{schema});
    }

    my $user = $args{schema}->resultset('User')->find($ENV{EID});
    if ($user->get_column('user_system')) {
        #$log->debug("Entityright build a new Entityright::System with EID ".$ENV{EID});
        return Entityright::System->new(user_id => $user->id, schema => $args{schema});
    } else {
        #$log->debug("Entityright build a new Entityright::User with EID ".$ENV{EID});
        return Entityright::User->new(user_id => $user->id, schema => $args{schema});
    }
}

=head2 Administrator::new (%args)

    Class : Public

    Desc : Instanciate Administrator object ; Administrator::authenticate must have been called

    return: Administrator instance

=cut

sub new {
    my ($class, %args) = @_;
    
    if(not defined $schema) {
        _connectdb();
    }

    if(not exists $ENV{EID} or not defined $ENV{EID}) {
        $errmsg = "No valid session registered ;";
        $errmsg .= " Administrator::authenticate must be call with a valid login/password pair";
        throw Kanopya::Exception::AuthenticationRequired(error => $errmsg);
    }

    if (defined $oneinstance) {
        if ($oneinstance->{EID} != $ENV{EID}) {
            $oneinstance->{_rightchecker} = buildEntityright(schema => $schema);
            $oneinstance->{EID} = $ENV{EID};
        }

        return $oneinstance;
    }

    $log->debug("Administrator instance created");

    my $self = {
        _rightchecker => buildEntityright(schema => $schema),
        db => $schema,
        manager => {}
    };

    bless $self, $class;
    $oneinstance = $self;
    $oneinstance->{EID} = $ENV{EID};
    return $self;
}


#TODO Comment getRow
# This is a very deep core method in Kanopya.
# It is used to get a row from an id in a specific table

sub getRow {
	my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'id', 'table' ]);

    my $dbix;
    eval {
        if (ref($args{id}) eq 'ARRAY') {
            $dbix = $self->{db}->resultset( $args{table} )->find(@{$args{id}});
        } else {
            $dbix = $self->{db}->resultset( $args{table} )->find($args{id});
        }
	};
    if ($@) {
        $errmsg = "Administrator->getRow error ".$@;
        $log->error($errmsg);
        throw Kanopya::Exception::DB(error => $errmsg);
    }
    
    if (not $dbix) {
        $errmsg = "Administrator->getRow : no row found with id $args{id} in table $args{table}";
        $log->warn($errmsg);
        throw Kanopya::Exception::Internal::NotFound(error => $errmsg);
    }

    return $dbix;
}	

=head2 Administrator::_getDbix(%args)

    Class : Private

    Desc : Instanciate dbix class mapped to corresponding raw in DB

    args:
        table : String : DB table name
        id: Int : id of required entity in table
    return: db schema (dbix)

=cut



=head2 Administrator::_getDbixFromHash(%args)

    Class : Private

    Desc : Instanciate dbix class mapped to corresponding raw in DB

    args:
        table : String : DB table name
        hash: Hash ref : hash of constraints to find entity
    return: db schema (dbix)

=cut

sub _getDbixFromHash {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['table', 'hash']);

    if (defined ($args{rows}) and not defined ($args{page})) {
        $args{page} = 1;
    }

    my $dbix;
    eval {
        $dbix = $self->{db}->resultset( $args{table} )->search( $args{hash},
                                                                { prefetch => $args{join},
                                                                  rows     => $args{rows},
                                                                  page     => $args{page},
                                                                  order_by => $args{order_by} });
    };
    if ($@) {
        $errmsg = "Administrator->_getDbixFromHash error ".$@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error =>  $errmsg);
    }
    return $dbix;
}

=head2 _newDbix

    Class : Private

    Desc : Instanciate dbix class filled with <params>, doesn't add in DB

    args:
        table : String : DB table name
        row: hash ref : representing the new row (key mapped on <table> columns)
    return: db schema (dbix)

=cut

sub _newDbix {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => ['table', 'row']);

    my $new_obj = $self->{db}->resultset($args{table})->new($args{row});
    return $new_obj;
}

sub registerComponent {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["component_name", "component_version", "component_category"]);
    return $self->{db}->resultset('Component')->create(\%args)->get_column("component_id");
}

sub registerTemplate {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => ["component_template_name", "component_template_directory", "component_id"]);
    return $self->{db}->resultset('ComponentTemplate')->create(\%args)->get_column("component_template_id");
}

sub getRightChecker {
    my $self = shift;

    return $oneinstance->{_rightchecker};
}

1;


