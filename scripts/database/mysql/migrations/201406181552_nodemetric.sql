CREATE TABLE `nodemetric` (
  `nodemetric_id` int(8) unsigned NOT NULL,
  `nodemetric_label` char(255),
  `nodemetric_node_id` int(8) unsigned NOT NULL,
  `nodemetric_indicator_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`nodemetric_id`),
  UNIQUE KEY (`nodemetric_node_id`,`nodemetric_indicator_id`),
  FOREIGN KEY (`nodemetric_indicator_id`) REFERENCES `collector_indicator` (`collector_indicator_id`)
      ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`nodemetric_node_id`) REFERENCES `node` (`node_id`)
      ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`nodemetric_id`) REFERENCES `metric` (`metric_id`)
      ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO class_type (class_type) VALUES ('Entity::Metric::Nodemetric');

INSERT INTO entity (class_type_id) (
SELECT class_type_id FROM
    (SELECT DISTINCT clustermetric_indicator_id,  node_id, class_type_id
        FROM clustermetric, node, class_type
        where clustermetric_service_provider_id = service_provider_id
            AND class_type = 'Entity::Metric::Nodemetric') as T);


INSERT INTO metric (metric_id) (
    SELECT entity_id FROM entity, class_type
        WHERE entity.class_type_id = class_type.class_type_id
            AND class_type.class_type = 'Entity::Metric::Nodemetric'
);

INSERT INTO param_preset (params) SELECT '{"store" : "rrd"}' FROM (
    SELECT entity_id FROM entity, class_type
        WHERE entity.class_type_id = class_type.class_type_id
            AND class_type.class_type = 'Entity::Metric::Nodemetric'
) as T;

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
FROM metric m, entity, class_type, (SELECT @tmp_metric_id := 0) r
WHERE m.metric_id = entity.entity_id
    AND entity.class_type_id = class_type.class_type_id
    AND class_type.class_type = 'Entity::Metric::Nodemetric';

UPDATE metric m SET m.param_preset_id = (
  SELECT tmp_pp.param_preset_id
  FROM tmp_pp
  INNER JOIN tmp_metric ON tmp_metric.id = tmp_pp.id
  WHERE tmp_metric.metric_id = m.metric_id
) WHERE m.metric_id IN (
      SELECT entity_id
      FROM entity,class_type
      WHERE  entity.class_type_id = class_type.class_type_id
		  AND class_type.class_type = 'Entity::Metric::Nodemetric');

DROP TABLE tmp_metric;
DROP TABLE tmp_pp;

INSERT INTO nodemetric( nodemetric_id, nodemetric_indicator_id, nodemetric_node_id ) (
	SELECT entity_id, clustermetric_indicator_id, node_id
	FROM (
		SELECT entity_id, (
			@tmp_metric_id := @tmp_metric_id +1
		) AS metric_id
		FROM entity, class_type, (
			SELECT @tmp_metric_id :=0
		) AS T
		WHERE entity.class_type_id = class_type.class_type_id
		AND class_type.class_type = 'Entity::Metric::Nodemetric'
	) AS A, (
		SELECT clustermetric_indicator_id, node_id, (
			@tmp_nmetric_id := @tmp_nmetric_id +1
		) AS nmetric_id
		FROM (
			SELECT DISTINCT clustermetric_indicator_id, node_id
			FROM clustermetric, node
			WHERE clustermetric_service_provider_id = service_provider_id
		) AS T, (
			SELECT @tmp_nmetric_id :=0
		) AS U
	) AS B
	WHERE A.metric_id = B.nmetric_id
);

-- DOWN --
DROP TABLE IF EXISTS `nodemetric`;
