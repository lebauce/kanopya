INSERT INTO  `entityright` (entityright_consumed_id, entityright_consumer_id, entityright_method)
(SELECT entityright_consumed_id, entityright_consumer_id, 'evaluateFormula'
 FROM `entityright`
 WHERE entityright_method = 'evaluateTimeSerie');
