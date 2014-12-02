INSERT INTO component_type_category VALUES ( (SELECT component_type_id from component_type WHERE component_name = 'Vsphere'), (SELECT component_category_id FROM component_category WHERE category_name = 'NetworkManager') );

-- DOWN --
