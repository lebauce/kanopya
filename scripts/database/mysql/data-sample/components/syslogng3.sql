USE `administrator`;
SET foreign_key_checks=0;

# SET @eid = (SELECT MAX(template_id) FROM template) + 1;

# Component
SET @eid_new_component = (SELECT MAX(component_id) FROM component) + 1;
INSERT INTO `component` VALUES (@eid_new_component,'Syslogng','3','Logger');


# provide component on distribution
INSERT INTO `component_provided` VALUES (@eid_new_component,1);
# install component on systemimage
INSERT INTO `component_installed` VALUES (@eid_new_component,1);

# Template
SET @eid_new_component_template = (SELECT MAX(component_template_id) FROM component_template) + 1;
INSERT INTO `component_template` VALUES (@eid_new_component_template,'syslogng','/templates/components/syslogng', @eid_new_component);

# instance on cluster
SET @cluster_id = 1;
SET @eid_new_component_instance = (SELECT MAX(component_instance_id) FROM component_instance) + 1;
INSERT INTO `component_instance` VALUES (@eid_new_component_instance,@cluster_id,@eid_new_component,@eid_new_component_template);

SET @eid_new_entity = (SELECT MAX(entity_id) FROM entity) + 1;
INSERT INTO `entity` VALUES (@eid_new_entity);
INSERT INTO `component_instance_entity` VALUES (@eid_new_entity,@eid_new_component_instance);;

###########################
# Component configuration #
###########################
INSERT INTO `syslogng3` VALUES (1, @eid_new_component_instance);
INSERT INTO `syslogng3_log` VALUES (1, 1);
INSERT INTO `syslogng3_log` VALUES (2, 1);

# link log to entry
INSERT INTO `syslogng3_log_param` VALUES (1, 1, 'source', 's_net');
INSERT INTO `syslogng3_log_param` VALUES (2, 1, 'destination', 'd_loc');
INSERT INTO `syslogng3_log_param` VALUES (3, 2, 'TYPE', 'NAME');
INSERT INTO `syslogng3_log_param` VALUES (4, 2, 'KJLNJL', 'ljbnljmbkhmb');


INSERT INTO `syslogng3_entry` VALUES (1, 's_net', 'source', 1);
INSERT INTO `syslogng3_entry_param` ( `syslogng3_entry_param_content`, `syslogng3_entry_id`) VALUES
       ('udp(ip(0.0.0.0))',1), ('driver2(gzegr mpiojpj)',1), ('driver3(gzegr)',1);

INSERT INTO `syslogng3_entry` VALUES (2, 's_all_local', 'source', 1);
INSERT INTO `syslogng3_entry_param` ( `syslogng3_entry_param_content`, `syslogng3_entry_id`) VALUES
       ('internal()', 2), ('unix-stream(\"/dev/log\")', 2), ('file(\"/proc/kmsg\" program_override(\"kernel\"))', 2);

INSERT INTO `syslogng3_entry` VALUES (3, 'd_net', 'destination', 1);
INSERT INTO `syslogng3_entry` VALUES (4, 'd_local', 'destination', 1);


SET foreign_key_checks=1;
