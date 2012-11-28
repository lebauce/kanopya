require('t/common.t.js');

var phases = [
    {
        name    : 'Register mock monitor',
        steps   : steps_createTechService('My MockMonitor', 'Collectormanager', 'MockMonitor', {})
    },
    {
        name    : 'Register sco',
        steps   : steps_createTechService('My SCO', 'WorkflowManager', 'SCO', {})
    },
    {
        name    : 'Register ActiveDirectory',
        steps   : steps_createTechService('My ActiveDirectory', 'DirectoryServiceManager', 'ActiveDirectory', {ad_host : 'DOMAIN_CONTROLLER', ad_user : 'test@hedera'})
    },
    {
        name    : 'Create service with all managers',
        steps   : steps_createService()
    }
];

function steps_createTechService(name, manager_category, manager_name, manager_params) {
    var steps = [
        {
            name            : 'Create tech service "' + name + '"',
            start_condition : { exists : 'body' },
            action          : function() {
                menuGoTo('Administration', 'Technical Services');
                $('#create-tech-service-button').click();
                $('#input_externalcluster_name').val(name);
                $('.ui-dialog :button:contains("Ok"):visible').click();
            },
            end_condition   : { exists : '.ui-dialog-title:contains(Register IT application)' }
        },
        {
            name        : 'Select "' + manager_category + '"',
            action      : function() {
                $('option:contains(' + manager_category + ')').attr('selected', 'selected').parent('select').change();
            } ,
            end_condition   : { exists : 'option:contains('+manager_category+')' }
        },
        {
            name        : 'Select "' + manager_name + '"',
            action      : function() {
                $('option:contains('+manager_name+')').attr('selected', 'selected').parent('select').change();
            }
        },
        {
            name        : 'Configure manager',
            action      : function() {
                $.each(manager_params, function (k,v) {
                    console.log(k);
                    console.log(v);
                    $('#input_' + k).val(v);
                });
            }
        },
        {
            name        : 'add connector',
            action      : function() {
                clickOk();
            },
            end_condition   : { not_exists : '.ui-dialog:visible' }
        }
    ];
    return steps;
}

function steps_createService() {
    var steps = [
        {
            name          : 'Create service',
            action      : function() {
                menuGoTo('Services');
                $('#add-service-button').click();
                $('#input_externalcluster_name').val('service_test');
                $('#input_externalcluster_desc').val('test service description');
                clickOk();
            },
            end_condition   : { exists : '.ui-dialog-title:contains(Link to a DirectoryServiceManager)' }
        },
        {
            name        : 'Add DirectoryService manager',
            action      : function() {
                selectOption('My ActiveDirectory - ActiveDirectory');
                $('input#ad_nodes_base_dn').val('OU=foo,CN=bar');
                clickOk();
            },
            end_condition   : {  exists : '.ui-dialog-title:contains(Link to a Collectormanager)' }
        },
        {
            name        : 'Add monitor manager',
            action      : function() {
                selectOption('My MockMonitor - MockMonitor');
                clickOk();
            },
            end_condition   : {  not_exists : '.ui-dialog:visible' }
        }
    ];
    return steps;
}

launchTest(phases);
