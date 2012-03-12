#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use Operation;
use EContext::Local;
use EFactory;

use Data::Dumper;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => '/tmp/MasterImageToCluster.t.log',
    layout => '%F %L %p %m%n'
});

use Cwd qw(abs_path);
use File::Basename;

my $master_name = 'Opennebula3';
my $master_archive = dirname(abs_path($0)) .
                     '/' . $master_name . '.tar.bz2';

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('Entity::Masterimage');
use_ok ('Entity::Systemimage');

# Test the existance of the master image test file.
if(! -e $master_archive) {
    ok (-e $master_archive, "Test master image required");
    
    BAIL_OUT('Cannot find test master image file: ' . $master_archive);
}

# Test root access
if ($< != 0) {
    ok ($< == 0, "Root access required");

    BAIL_OUT('You need to be root.');
}

eval {
    my @args = ();
    note ("Execution begin");
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    Administrator::authenticate(login => 'admin', password => 'K4n0pY4');
    my $adm = Administrator->new;
    my $db  = $adm->{db};

    $db->txn_begin;

    # Deploy master image
    lives_ok {
        Operation->enqueue(
            priority => 200,
            type     => 'DeployMasterimage',
            params   => {
                file_path => $master_archive,
                keep_file => 1,
            },
        );
    } 'DeployMasterimage operation enqueue';

    lives_ok { $executor->oneRun(); } 'DeployMasterimage operation execution succeed';

	my $master_image;
	lives_ok { 
		$master_image = Entity::Masterimage->find(
                            hash => {
                                masterimage_name => $master_name,
                            }
                        );
	} 'Retrieve master image';

    # Add system image from distribution
    my $systemimage_name = 'TestScenario';
    lives_ok {
        Entity::Systemimage->create(
			systemimage_name => $systemimage_name,
			systemimage_desc => 'System image for test scenario MasterImageToCluster.',
            masterimage_id   => $master_image->getAttr(name => 'masterimage_id'),
        );
    } 'AddSytemImage operation enqueue';
    
    lives_ok { $executor->oneRun(); } 'AddSytemImage operation execution succeed';

    my $systemimage;
	lives_ok {
		$systemimage = Entity::Systemimage->find(
                           hash => {
                               systemimage_name => $systemimage_name,
                           }
                       );
	} 'Retrieve system image ' . $systemimage_name;

    # Clone system image
    my $systemimage_id = $systemimage->getAttr(name => 'systemimage_id');
    my $clone_name = 'Clone' . $systemimage_name;
    lives_ok {
        Operation->enqueue(
            priority => 200,
            type     => 'CloneSystemimage',
            params   => {
                systemimage_id   => $systemimage_id,
                systemimage_name => $clone_name,
                systemimage_desc => 'System image for test scenario MasterImageToCluster.',
            },
        );
    } 'CloneSystemImage operation enqueue';
    
    lives_ok { $executor->oneRun(); } 'CloneSystemImage operation execution succeed';

    my $clone;
	lives_ok {
		$clone = Entity::Systemimage->find(
                     hash => {
                         systemimage_name => $clone_name,
                     }
                 );
	} 'Retrieve system image ' . $clone_name;

    # Remove clone system image
    lives_ok {
        Operation->enqueue(
            priority => 200,
            type     => 'RemoveSystemimage',
            params   => {
                systemimage_id => $clone->getAttr(name => 'systemimage_id')
            },
        );
    } 'RemoveSystemImage (clone) operation enqueue';
    
    lives_ok { $executor->oneRun(); } 'RemoveSystemImage operation execution succeed';

    # Remove system image
    lives_ok {
        Operation->enqueue(
            priority => 200,
            type     => 'RemoveSystemimage',
            params   => {
                systemimage_id => $systemimage_id
            },
        );
    } 'RemoveSystemImage operation enqueue';
    
    lives_ok { $executor->oneRun(); } 'RemoveSystemImage operation execution succeed';

	throws_ok {
		Entity::Systemimage->get(id => $systemimage_id);
	} 'Kanopya::Exception::DB',
      'Systemimage removed ' . $systemimage_name . ', id ' . $systemimage_id;

    $db->txn_rollback;

    };
if($@) {
    my $error = $@;
    print Dumper $error;
};
