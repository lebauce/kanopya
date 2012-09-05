# This script is called during setup to insert some kanopya data in DB
# The other way to insert data during setup is Data.sql.tt (pb: id management)
#
use lib qw(/opt/kanopya/lib/common/ /opt/kanopya/lib/administrator/ /opt/kanopya/lib/executor/ /opt/kanopya/lib/monitor/ /opt/kanopya/lib/orchestrator/ /opt/kanopya/lib/external);

use Administrator;
use ComponentType;
use Entity::Component;
use WorkflowDef;
use Operationtype;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'ERROR', file=>'STDOUT', layout=>'%F %L %p %m%n'});

my ($login, $pwd) = @ARGV;

if (!defined $login || !defined $pwd) {
    print "Usage: perl populate_db.pl <login> <password>\n";
    exit;
}

Administrator::authenticate(login => $login, password => $pwd);

populate_workflow_def();

sub populate_workflow_def {
    my $wf_manager_component_type_id = ComponentType->find( hash => { component_category => 'Workflowmanager' } )->id;
    my $kanopya_wf_manager           = Entity::Component->find( hash => { component_type_id => $wf_manager_component_type_id, service_provider_id => 1 } );
    my $scale_op_id                  = Operationtype->find( hash => { operationtype_name => 'LaunchScaleInWorkflow' })->id;
    
    # ScaleIn cpu workflow def
    my $scale_cpu_wf = $kanopya_wf_manager->createWorkflow(
        workflow_name => 'ScaleInCPU',
        params => {
            specific => {
                scalein_value => { label => 'Nb core' },
            },
            internal => {
                scope_id => 1,
            },
            automatic => {
                context => { cloudmanager_comp => undef, host => undef },
                scalein_type => 'cpu',
            },
        }
    );
    $scale_cpu_wf->addStep( operationtype_id => $scale_op_id );
    
    # ScaleIn memory workflow def
    my $scale_mem_wf = $kanopya_wf_manager->createWorkflow(
        workflow_name => 'ScaleInMemory',
        params => {
            specific => {
                scalein_value => { label => 'Amount', unit => 'byte' },
            },
            internal => {
                scope_id => 1,
            },
            automatic => {
                context => { cloudmanager_comp => undef, host => undef },
                scalein_type => 'memory',
            },
        }
    );
    $scale_mem_wf->addStep( operationtype_id => $scale_op_id );
}