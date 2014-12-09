require('common/general.js');
//require('kanopyaformwizard.js');

function loadServicesConfig(cid, eid) {
        create_grid({
            url: '/api/component?service_provider_id=' + eid + '&expand=component_type',
            content_container_id: cid,
            grid_id: 'services_components',
            rowNum : 20,
            colNames: [ 'ID', 'Component', 'Version' ],
            colModel: [
                { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
                { name: 'component_type.component_name', index: 'component_type.component_name', width: 200 },
                { name: 'component_type.component_version', index: 'component_type.component_version', width: 200 },
            ],
            caption: 'Components',
            details : {
                onSelectRow : function(eid, e) {
                    var componentType = fromIdToComponentType(ajax('GET', '/api/component/' + e.pk).component_type_id);
                    var componentName = componentType.component_name.toLowerCase() + componentType.component_version;

                    require('KIM/components/' + componentName + '.js');

                    // Find the component class, use generix component instead.
                    var componentClass;

                    // Work around to handle components without version number
                    if (window[componentName.ucfirst()] == undefined) {
                        componentName = componentName.substring(0, componentName.length - 1);
                        require('KIM/components/' + componentName + '.js');
                    }
                    if (componentClass = window[componentName.ucfirst()]) {
                        // Open the configuration modal
                        (new componentClass(e.pk)).configure();
                    }
                }
            }
        });
	var action_div=$('#' + cid).prevAll('.action_buttons');
    var addButton   = $('<a>', { text : 'Add component' }).appendTo(action_div)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', function (e) {
        (new KanopyaFormWizard({
            title      : 'Add components',
            id         : eid,
            displayed  : [ 'cluster_name', 'component_types' ],
            rawattrdef : {
                cluster_name : {
                    label       : 'Instance name',
                    type        : 'string',
                    is_editable : 0,
                },
                component_types : {
                    label         : 'Components to add',
                    type          : 'relation',
                    relation      : 'multi',
                    is_mandatory  : 1,
                    is_editable   : 1,
                    hide_existing : 1,
                }
            },
            optionsCallback : function (name) {
                if (name === 'component_types') {
                    // Get the component types supported by this service provider only
                    return ajax('GET', '/api/cluster/' + eid +
                                       '/service_provider_type/component_types?deployable=1');
                }
                return false;
            },
            valuesCallback : function (type, id) {
                var cluster = ajax('GET', '/api/cluster/' + eid + '?expand=components');
                var types = cluster.components
                                .map(function (component) { return component.component_type_id; });

                return { cluster_name: cluster.cluster_name, component_types: types };
            },
            submitCallback : function(data, $form, opts, onsuccess, onerror) {
                var params = { components: [] };
                for (var index in data.component_types) {
                    params.components.push({ component_type_id: data.component_types[index] });
                }
                ajax('PUT', '/api/cluster/' + eid, params, onsuccess, onerror);
            }
        })).start();
    });
}
