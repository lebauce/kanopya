require('detailstable.js');

function loadServicesDetails(cid, eid) {
        
    var divId = 'service_details';
    var container = $('#'+ cid);
    var div = $('<div>', { id: divId}).appendTo(container);
     $('<h4>Details</h4>').appendTo(div);
        
    var service_opts = {
        name   : 'cluster',
        fields : { cluster_name         : {label: 'Name'},
                   cluster_state        : {label: 'State'},
                   cluster_prev_state   : {label: 'Previous state'},
                   active               : {label: 'Active'},
                   cluster_min_node     : {label: 'Min node'},
                   cluster_max_node     : {label: 'Max node'},
                   masterimage_id       : {label: 'Master Image'},
                   kernel_id            : {label: 'Kernel'},
                   service_template_id  : {label: 'Service template'},
                   cluster_domainname   : {label: 'Domain name'},
                   cluster_nameserver1  : {label: 'Domain name server 1'},
                   cluster_nameserver2  : {label: 'Domain name server 2'},
                   cluster_boot_policy  : {label: 'Boot policy'},
                   cluster_basehostname : {label: 'Base hostname'},
                   cluster_priority     : {label: 'Priority'},
                   cluster_si_persistent: {label: 'Persistent'},
                   cluster_si_shared    : {label: 'Shared'},
                   user_id              : {label: 'User'},
                                            

        },
    };   
    var details = new DetailsTable(divId, eid, service_opts);
    
    details.show();
    
}


/*

$('').appendTo(div);
            
            var cluster_state =         data.cluster_state;
            var cluster_prev_state =    data.cluster_prev_state;
            var active =                data.active;
            var user_id =               data.user_id;
            var cluster_priority =      data.cluster_priority;
            var cluster_type =          data.cluster_type;
            var class_type_id =         data.class_type_id;
            var cluster_desc =          data.cluster_desc;
            var entity_comment_id =     data.entity_comment_id;
            var cluster_basehostname =  data.cluster_basehostname;
            var service_template_id =   data.service_template_id;
            var cluster_boot_policy =   data.cluster_boot_policy;
            var cluster_min_node =      data.cluster_min_node;
            var cluster_max_node =      data.cluster_max_node;
            var masterimage_id =        data.masterimage_id;
            var kernel_id =             data.kernel_id;
            var cluster_domainname =    data.cluster_domainname;
            var cluster_nameserver1 =   data.cluster_nameserver1;
            var cluster_nameserver2 =   data.cluster_nameserver2;
            var cluster_si_persistent = data.cluster_si_persistent;
            var cluster_si_shared =     data.cluster_si_shared;
            
*/