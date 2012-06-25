require('KIM/policiesdefs.js');
require('KIM/policiesform.js');

var service_template = {
    service_name : {
        step         : 'Service',
        label        : 'Service name',
        type         : 'text',
        is_mandatory : 1,
        pattern      : '.*'
    },
    service_desc : {
        step         : 'Service',
        label        : 'Service description',
        type         : 'textarea',
        is_mandatory : 0,
        pattern      : '.*'
    },
}

function load_service_template_content (container_id) {
    function createServiceTemplateDef() {
      var service_template_def = jQuery.extend(true, {}, service_template);

      for (var policy in policies) {
        var policy_def = jQuery.extend(true, {}, policies[policy]);

        var step = policy.substring(0, 1).toUpperCase() + policy.substring(1);

        // Add the policy selection input
        service_template_def[policy + '_policy_id'] = {
          label           : step + ' policy',
          step            : step,
          type            : 'select',
          welcome_value   : 'Select a ' + policy + ' policy',
          entity          : 'policy',
          filters         : { policy_type : policy },
          display         : 'policy_name',
          values_provider : {
            func : 'getFlattenedHash',
            args : { },
          },
          is_mandatory : true,
          trigger      : true,
          pattern      : '^[1-9][0-9]*$',
        };

        for (var field in policy_def) {
          policy_def[field].policy = policy;
          policy_def[field].step = step;
          policy_def[field].triggered = policy + '_policy_id';
          policy_def[field].disable_filled = true;

          var policy_field;
          if (field === 'policy_name' || field === 'policy_desc') {
            policy_field = policy + '_' + field;
          } else {
            policy_field = field;
            policy_def[field].prefix = policy + '_';
          }
          service_template_def[policy_field] = policy_def[field];
        }
      }
      return service_template_def;
    }

    console.log(policies);
    function createAddServiceTemplateButton(cid, grid) {
        var service_template_opts = {
            title       : 'Add a service template',
            name        : 'servicetemplate',
            callback    : function () { grid.trigger("reloadGrid"); }
        };

        var button = $("<button>", { html : 'Add a service template'} );
        button.bind('click', function() {
            service_template_opts.fields    = createServiceTemplateDef();
            new PolicyForm(service_template_opts).start();
        });
        $('#' + cid).append(button);
    };

    var container = $('#' + container_id);
    var grid = create_grid( {
        url: '/api/servicetemplate',
        content_container_id: container_id,
        grid_id: 'service_template_list',
        colNames: [ 'ID', 'Name', 'Description' ],
        colModel: [ { name:'service_template_id', index:'service_template_id', width:60, sorttype:"int", hidden:true, key:true},
                    { name:'service_name', index:'service_name', width:300 },
                    { name:'service_desc', index:'service_desc', width:500 } ]
    } );

    createAddServiceTemplateButton(container_id, grid);
}

function load_service_template_details (elem_id, row_data, grid_id) {
    var service_template_simple_def = jQuery.extend(true, {}, service_template);
    var policies_for_service = jQuery.extend(true, {}, policies);

    for (var policy in policies_for_service) {
        var step = policy.substring(0, 1).toUpperCase() + policy.substring(1);

        // Add the policy selection input
        service_template_simple_def[policy + '_policy_id'] = {
            label           : step + ' policy',
            step            : 'Service',
            type            : 'select',
            entity          : 'policy',
            filters         : { policy_type : policy },
            display         : 'policy_name',
            is_mandatory    : true,
        };
    }

    var values;
    $.ajax({
        type     : 'GET',
        async    : false,
        url      : '/api/servicetemplate/' + elem_id,
        dataTYpe : 'json',
        success  : $.proxy(function(d) {
            values = d;
        }, this)
    });

    var service_tempate_opts = {
        id          : values.service_template_id,
        title       : 'Edit the service template: ' + values.service_name,
        name        : 'servicetemplate',
        fields      : service_template_simple_def,
        values      : values,
        callback    : function () { $('#' + grid_id).trigger("reloadGrid"); }
    };

    new PolicyForm(service_tempate_opts).start();
}
