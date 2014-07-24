UPDATE entityright SET entityright_consumed_id = (SELECT gp_id FROM gp WHERE gp_name = 'Metric') WHERE entityright_method = 'evaluateTimeSerie'
