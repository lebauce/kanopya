CREATE TABLE `metric` (
	`metric_id` int(8) unsigned NOT NULL,
	`param_preset_id` int(8) unsigned DEFAULT NULL,
	PRIMARY KEY (`metric_id`),
	FOREIGN KEY (`param_preset_id`) REFERENCES `param_preset` (`param_preset_id`)
	    ON DELETE SET NULL ON UPDATE NO ACTION,
	FOREIGN KEY (`metric_id`) REFERENCES `entity` (`entity_id`)
		ON DELETE CASCADE ON UPDATE NO ACTION
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `anomaly` (
	`anomaly_id` int(8) unsigned NOT NULL,
	`related_metric_id` int(8) unsigned NOT NULL,
	PRIMARY KEY (`anomaly_id`),
	FOREIGN KEY (`related_metric_id`) REFERENCES `metric` (`metric_id`)
		ON DELETE CASCADE ON UPDATE NO ACTION,
	FOREIGN KEY (`anomaly_id`) REFERENCES `metric` (`metric_id`)
		ON DELETE CASCADE ON UPDATE NO ACTION
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;



CREATE TABLE `kanopya_anomaly_detector` (
	`kanopya_anomaly_detector_id` int(8) unsigned NOT NULL,
	`control_queue` char(255) DEFAULT NULL,
	`time_step` int(8) unsigned NOT NULL,
	`storage_duration` int(8) unsigned NOT NULL,
	PRIMARY KEY (`kanopya_anomaly_detector_id`),
	FOREIGN KEY (`kanopya_anomaly_detector_id`) REFERENCES `component` (`component_id`)
		ON DELETE CASCADE ON UPDATE NO ACTION
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;


INSERT INTO metric (metric_id) (SELECT clustermetric_id FROM clustermetric);
INSERT INTO param_preset (params) SELECT '{"store" : "rrd"}' FROM clustermetric;

-- link param presets to metric (linked to clustermetric) rows
-- need to use temporary tables in order to link

CREATE TEMPORARY TABLE tmp_pp (
        id int(8) unsigned,
        param_preset_id int(8) unsigned
);

INSERT INTO tmp_pp (id,param_preset_id)
SELECT (@tmp_pp_id := @tmp_pp_id + 1) AS id, pp.param_preset_id
FROM param_preset pp, (SELECT @tmp_pp_id := 0) r
WHERE (
    params = '{"store" : "rrd"}' AND (
        NOT EXISTS (
            SELECT param_preset_id FROM metric WHERE metric.param_preset_id = pp.param_preset_id
        )
    )
)
ORDER BY pp.param_preset_id DESC;

CREATE TEMPORARY TABLE tmp_metric (
        id int(8) unsigned,
        metric_id int(8) unsigned
);

INSERT INTO tmp_metric (id, metric_id)
SELECT (@tmp_metric_id := @tmp_metric_id + 1) AS id, m.metric_id
FROM metric m, (SELECT @tmp_metric_id := 0) r;

UPDATE metric m SET m.param_preset_id = (
  SELECT tmp_pp.param_preset_id
  FROM tmp_pp
  INNER JOIN tmp_metric ON tmp_metric.id = tmp_pp.id
  WHERE tmp_metric.metric_id = m.metric_id
);

DROP TABLE tmp_metric;
DROP TABLE tmp_pp;

-- combination does not have param presets since they are (currently) not stored on rrd

INSERT INTO metric (metric_id) (SELECT combination_id FROM combination);

-- Change foreign key, link to metric instread of entity since we created the new table metric
ALTER TABLE `combination` DROP FOREIGN KEY `combination_ibfk_1` ,
	ADD FOREIGN KEY ( `combination_id` ) REFERENCES `kanopya`.`metric` ( `metric_id` )
	ON DELETE CASCADE ON UPDATE NO ACTION ;

ALTER TABLE `clustermetric` DROP FOREIGN KEY `clustermetric_ibfk_3` ,
	ADD FOREIGN KEY ( `clustermetric_id` ) REFERENCES `kanopya`.`metric` ( `metric_id` )
	ON DELETE CASCADE ON UPDATE NO ACTION ;

INSERT INTO `kanopya`.`class_type` (`class_type_id` ,`class_type`)
	VALUES (NULL , 'Entity::Metric::Anomaly');

INSERT INTO `kanopya`.`class_type` (`class_type_id` ,`class_type`)
	VALUES (NULL , 'Entity::Component::KanopyaAnomalyDetector');

INSERT INTO component_type (component_type_id, component_name)
	(SELECT class_type_id, 'KanopyaAnomalyDetector' FROM class_type
		WHERE class_type = 'Entity::Component::KanopyaAnomalyDetector');

-- Create kanopya_anomaly_detector instance and rows of its intermediary tables (entity, component)
INSERT INTO entity (class_type_id)
	(SELECT class_type_id FROM class_type
		WHERE class_type = 'Entity::Component::KanopyaAnomalyDetector');

INSERT INTO component (component_id, service_provider_id, component_type_id)
	    SELECT entity_id, cluster_id, component_type_id
            FROM cluster, component_type, entity
            WHERE cluster_name = 'Kanopya' AND component_name = 'KanopyaAnomalyDetector'
            ORDER BY entity_id DESC LIMIT 1;

INSERT INTO kanopya_anomaly_detector (kanopya_anomaly_detector_id, time_step, storage_duration)
	SELECT component_id, '300', '6048000' FROM component ORDER BY component_id DESC LIMIT 1;

-- Add component to node
INSERT INTO component_node (component_id, node_id, master_node)
	SELECT kanopya_anomaly_detector_id,  node_id, '1' FROM kanopya_anomaly_detector, node
		WHERE service_provider_id = (SELECT cluster_id FROM cluster WHERE cluster_name = 'Kanopya')

