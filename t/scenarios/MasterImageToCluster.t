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

my $dist_name    = 'Debian';
my $dist_ver     = '6';
my $master_image = dirname(abs_path($0)) .
                   '/distribution_' . $dist_name .
                   '_' . $dist_ver . '.tar.bz2.tar';

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('Entity::Distribution');
use_ok ('Entity::Systemimage');

# Test the existance of the master image test file.
if(! -e $master_image) {
    ok (-e $master_image, "Test master image required");
    
    BAIL_OUT('Cannot find test master image file: ' . $master_image);
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
            type     => 'DeployDistribution',
            params   => { file_path => $master_image },
        );
    } 'DeployDistribution operation enqueue';

    lives_ok { $executor->oneRun(); } 'DeployDistribution operation execution succeed';

	my $distribution;
	lives_ok { 
		$distribution = Entity::Distribution->find(
                            hash => {
                                distribution_name => $dist_name,
                                distribution_version => $dist_ver
                            }
                        );
	} 'Retrieve master image';

    # Add system image from distribution
    my $systemimage_name = 'TestScenario';
    lives_ok {
        Entity::Systemimage->create(
			systemimage_name => $systemimage_name,
			systemimage_desc => 'System image for test scenario MasterImageToCluster.',
            distribution_id  => $distribution->getAttr(name => 'distribution_id'),
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

    # Manualy remove distribution containers
    my $econtext = EContext::Local->new();
    $econtext->execute(command => 'lvremove -f vhd1/etc_' . $dist_name . '_' . $dist_ver);
    $econtext->execute(command => 'lvremove -f vhd1/root_' . $dist_name . '_' . $dist_ver);

    $db->txn_rollback;

    };
if($@) {
    my $error = $@;
    print Dumper $error;
};
