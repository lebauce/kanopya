USE `kanopya`;

SET @collector := 1;


--
-- class type list
--

-- Do not put abstract types here (eg. ServiceProvider)

INSERT INTO `class_type` VALUES
(74, 'Entity::Component::KanopyaCollector');

--
-- components type list
--

INSERT INTO `component_type` VALUES
(17,'KanopyaCollector','1','DataCollector');

--
-- KanopyaCollector
--

INSERT INTO `entity` VALUES (@eid, 74, NULL);
INSERT INTO `component` VALUES(@eid, @admin_cluster, 17, NULL, NULL);
INSERT INTO `kanopyacollector1` VALUES(@collector, 3600, 86400);