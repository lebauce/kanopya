$(document).ready(function(){
  
  	var url_params = window.location.href.split('?')[1];
  	var url = window.location.href;
	var path = url.replace(/^[^\/]+\/\/[^\/]+/g,''); // remove the beginning of the url to keep only path
  	var save_orchestrator_settings_link = path + '/save';
	var save_controller_settings_link = "/cgi/kanopya.cgi/orchestration/save_controller_settings?" + url_params;
  
  	commonInit();
  
  	function selectCondition () {
		if ($(this).not('.condtree').size() > 0) {
			var nb_selected = $('#rules_table tr.selected').size();
 			if ( nb_selected == 0 || (nb_selected == 1 && $(this).parent('tr').hasClass('selected')) ) {
 				$(this).parent('tr').toggleClass('selected'); 
 			} else {
 				var selected_neighbors = 0;
 				if ( $(this).parent('tr').prev().hasClass('selected') ) {selected_neighbors++;}
 				if ( $(this).parent('tr').next().hasClass('selected') ) {selected_neighbors++;} 
 				if ( selected_neighbors == 1 ) {
 					$(this).parent('tr').toggleClass('selected');
 				}
 			}
 		}
  	}
  
 	$('#rules_table .then_col').click( selectCondition ).addClass('clickable');
 	
 	$('.operator_button').click( function () { 
 		var selected = $('.rulesview .selected');
 		
 		var id = new Date().getTime();
 		
 		selected.each( function () { $(this).find('.indicator_name').attr('cond_id', id) } );
 		
 		selected.first().find('.op_col').replaceWith("<td class='operator' op_id='" + id + "' rowspan='" + selected.size() + "'>" + $(this).attr('op') + "</td>");
 		selected.find('.op_col').replaceWith('');
 		
 		var new_op = selected.first().find('.operator');
 		
 		selected.first().find('.then_col').replaceWith("<td class='then_col first' rowspan='" + selected.size() + "'></td>");
 		selected.find('.then_col').not('.first').replaceWith('');
 		
 		var action_text = selected.first().find('.action_col').text();
 		selected.first().find('.action_col').replaceWith("<td class='action_col first' rowspan='" + selected.size() + "'>" + action_text + "</td>");
 		selected.find('.action_col').not('.first').replaceWith('');

 		var node_selection_text = selected.first().find('.node_selection').text();
 		selected.first().find('.node_selection').replaceWith("<td class='node_selection first' rowspan='" + selected.size() + "'>" + node_selection_text + "</td>");
 		selected.find('.node_selection').not('.first').replaceWith('');
 		 		
 		selected.removeClass('selected').addClass('condtree');
 		//selected.click( function() {} );
 		
 		
 		new_op.click( onOperatorClick ).addClass('clickable');
 		
 	 } ).addClass('clickable');
 	
 	function onOperatorClick () {
		$(this).toggleClass('selected_op');
		$('[cond_id=' + $(this).attr('op_id') + ']').parent('.rule').toggleClass('selected'); 
 	}
 	
 	$('.operator').click( onOperatorClick ).addClass('clickable');
 	
 	function removeCond () {
 		var rule = $(this).parent('.rule').first();
 		var cond_id = rule.find('[cond_id]').attr('cond_id');
 		var cond_tree = $('[cond_id=' + cond_id + ']').parent('.rule');
alert('remove');
 		if ( cond_tree.size() == 1) { // stand alone condition (cond + action)
 			rule.replaceWith('');
 		} else { // condition in a tree
 			resizeMasterRow( cond_tree.first(), -1);
 			if (rule.find('.operator').size() > 0) { // master cond
 				var new_master = cond_tree.first().next();
 				new_master.append(rule.find('.operator'));
 				new_master.append(rule.find('.then_col'));
 				new_master.append(rule.find('.action_col'));
 				new_master.append(rule.find('.node_selection'));
 			} 
 			if (cond_tree.size() == 2) { // left only one condition in tree => remove tree operator
 				cond_tree.find('.operator').removeClass('operator').addClass('op_col').text('');
 			}
 			rule.replaceWith('');
 		}
 	}
 	
 	$('#rules_table .remove_cond').click( removeCond ).addClass('clickable');
 	
 	$('#optim_table .remove_cond').click( function () { $(this).parent('.condition').first().replaceWith(''); } ).addClass('clickable');
 	
 	function resizeMasterRow(row, diff) {
 			var new_rowspan = row.find('.operator').attr('rowspan') + diff;
 			row.find('.operator').attr('rowspan', new_rowspan);
 			row.find('.then_col').attr('rowspan', new_rowspan );
 			row.find('.action_col').attr('rowspan', new_rowspan );
 			row.find('.node_selection').attr('rowspan', new_rowspan );
 	}
 	
 	$('#add_cond_button').click( function () {
 		
 		var new_rule;
 		var selected_op = $('.selected_op');
 		if ( selected_op.size() == 1 ) { // add a condition to the selected operator (group of conditions)
 			resizeMasterRow(selected_op.parent('.rule'), 1);
 				
 			$('.selected').last().after('<tr class="new_rule rule selected">' + $('#rules_table #rule_model').html() + '</tr>');
 			new_rule = $('.new_rule');
 			new_rule.find('.indicator_name').attr('cond_id', selected_op.attr('op_id'));
 			new_rule.find('.op_col').replaceWith('');
 			new_rule.find('.then_col').replaceWith('');
 			new_rule.find('.action_col').replaceWith('');
 			new_rule.find('.node_selection').replaceWith('');
 		} else { // add a new rule (condition + action)
	 		new_rule = $('#rules_table').append('<tr class="new_rule rule">' + $('#rules_table #rule_model').html() + '</tr>').find('.new_rule');
	 		var id = new Date().getTime();
	 		new_rule.find('[cond_id]').attr('cond_id', id);
	 		new_rule.find('[op_id]').attr('op_id', id);
	 		new_rule.find('.then_col').click( selectCondition ).addClass('clickable');
 		}
 		
 		new_rule.removeClass('new_rule');
 		new_rule.find('.editable_choice').click( toggleChoiceMode ).addClass('clickable');//.addClass('new_edit');
 		new_rule.find('.editable').click( toggleEditMode ).addClass('clickable');//.addClass('new_edit');
	 	new_rule.find('.remove_cond').click( removeCond ).addClass('clickable');	
 		
 	} ).addClass('clickable');
 	
 	$('#add_optim_cond_button').click( function () {
 		new_cond = $('#optim_table').append('<tr class="new_cond condition">' + $('#optim_table #condition_model').html() + '</tr>').find('.new_cond');
 		new_cond.removeClass('new_cond');
 		new_cond.find('.editable_choice').click( toggleChoiceMode ).addClass('clickable').addClass('new_edit');
 		new_cond.find('.editable').click( toggleEditMode ).addClass('clickable').addClass('new_edit');
	 	new_cond.find('.remove_cond').click( function () { $(this).parent('.condition').first().replaceWith(''); } ).addClass('clickable');
 	} ).addClass('clickable');
 	
 	function getConditionStruct (row) {
 		if (row.find('.new_edit').size() > 0) {
			alert("A condition has unset field => will be not recorded");
			return;
		}
		
		var indicator = row.find('.indicator_name').text();
		var time_laps = row.find('.time_laps').text();
		var thresh_value = row.find('.thresh_value').text();
		
		var comp_op_map = { '<' : 'inf', '>' : 'sup' };
		var comp_operator = comp_op_map[row.find('.comp_op').text()]; 
		
		return { 'var' : indicator, 'value' : thresh_value, 'time_laps' : time_laps, 'operator': comp_operator };
 	}

 	function getConditionTree (elem) {
 		
 		if (elem.hasClass('operator')) {
 			var nb_cond = elem.attr('rowspan');
 			var bin_op_map = {'or': '|', 'and': '&'};
 			var bin_op = bin_op_map[elem.text()];
 			var id = elem.attr('op_id');
 			var children = $('[cond_id=' + id + ']');
 			var cond_tree = children.map( function () { var sub_tree = getConditionTree($(this)); if (sub_tree) return [sub_tree, bin_op]; } ).get();
 			cond_tree.pop();
 			
 			return cond_tree;
 		} else {
 			return getConditionStruct(elem.parent('.rule'));
 		}
 	}
 	 	
 	$('#save_orchestrator_settings').click( function () {
 		loading_start(); 
 		
	 	var rules = $('#rules_table .rule .then_col').map( function() {	
	 		var cond_tree = getConditionTree( $(this).prev() );
 			if ( ! cond_tree ) {return;}
 			//alert( [cond_tree].join() );
 			var action = $(this).siblings('.action_col').text();
 			return { 'condition': cond_tree, 'action': action };
 		} ).get();
 		
 		var optim_cond = $('#optim_table .condition').map( function() {	
			var cond = getConditionStruct($(this));
 			return [ cond, '&'];
 		} ).get();
 		optim_cond.pop();
 		
 		var params = { rules : JSON.stringify(rules), optim_conditions : JSON.stringify(optim_cond)  };
		$.get(save_orchestrator_settings_link, params, function(resp) {
			loading_stop();
			alert(resp);
		});
		
 	}).addClass('clickable');
 	
 	$('#save_controller_settings').click( function () {
		loading_start();	
		var params = {
				visit_ratio : $('#visit_ratio').text(),
				service_time : $('#service_time').text(),
				delay : $('#delay').text(), 
				think_time : $('#think_time').text(),  
			};
		$.get(save_controller_settings_link, params, function(resp) {
			loading_stop();
			alert(resp);
		});
	}).addClass('clickable');
 	
     //$('a.normalTip').aToolTip(); 
     //$('div.aToolTip').aToolTip();
     //$('p.aToolTipContent').aToolTipContent();

});
 
