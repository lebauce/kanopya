require('common/general.js');
require('kanopyaformwizard.js');

function loadServicesConfig(cid, eid) {
        create_grid({
            url: '/api/component?service_provider_id=' + eid,
            content_container_id: cid,
            grid_id: 'services_components',
            rowNum : 20,
            colNames: [ 'ID', 'Component', 'Version' ],
            colModel: [
                { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
                { name: 'component_type_id', index: 'component_type_id', width: 200, formatter: fromIdToComponentName },
                { name: 'component_type_id', index: 'component_type_id', width: 200, formatter: fromIdToComponentVersion },
            ],
            caption: 'Components',
            details : {
                onSelectRow : function(eid, e) {
                    var componentType = fromIdToComponentType(ajax('GET', '/api/component/' + e.pk).component_type_id);
                    var componentName = componentType.component_name.toLowerCase() + componentType.component_version;

                    require('KIM/components/' + componentName + '.js');

                    // Find the component class, use generix component instead.
                    var componentClass;
                    if (componentClass = window[componentName.ucfirst()]) {
                        // Open the configuration modal
                        (new componentClass(e.pk)).configure();
                    }
                }
            }
        });
}
