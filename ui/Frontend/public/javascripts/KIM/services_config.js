require('common/general.js');

function getComponentTypes() {
    return {
        'Linux'     : 'linux0'
    };
}

function loadServicesConfig(cid, eid) {

        create_grid({
            url: '/api/component?service_provider_id=' + eid,
            content_container_id: cid,
            grid_id: 'services_components',
            colNames: [ 'ID', 'Component Type', ],
            colModel: [
                { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
                { name: 'component_type_id', index: 'component_type_id', width: 200, formatter:fromIdToComponentType},
            ],
            caption: 'Components',
            details : {
                onSelectRow : function(eid, e) {
                    var componentType   = (getComponentTypes())[e.component_type_id];
                    if (componentType != undefined) {
                        require('KIM/components/' + componentType + '.js');
                        (new window[componentType.ucfirst()](e.pk)).openConfig();
                    }
                }
            }
        });
}
