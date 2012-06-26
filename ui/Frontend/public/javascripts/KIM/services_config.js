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
        });
}