$(document).ready(function(){
  
  	var url_params = window.location.href.split('?')[1];
  	var save_orchestrator_settings_link = "/cgi/mcsui.cgi/orchestration/save_orchestrator_settings?" +  + url_params;
  
  	commonInit();
  
 	$('#rules_table .then_col').click( function () {
 			if ($(this).not('.inrule').size() > 0) {
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
 		}).addClass('clickable');
 	
 	$('.operator_button').click( function () { 
 		var selected = $('.rulesview .selected');
 		
 		selected.first().find('.op_col').replaceWith("<td class='operator' rowspan='" + selected.size() + "'>" + $(this).attr('op') + "</td>");
 		selected.find('.op_col').replaceWith('');
 		
 		selected.first().find('.then_col').replaceWith("<td class='then_col' rowspan='" + selected.size() + "'></td>");
 		selected.find('.then_col').not('[rowspan]').replaceWith('');
 		
 		var action_text = selected.first().find('.action_col').text();
 		selected.first().find('.action_col').replaceWith("<td class='action_col' rowspan='" + selected.size() + "'>" + action_text + "</td>");
 		selected.find('.action_col').not('[rowspan]').replaceWith('');

 		var node_selection_text = selected.first().find('.node_selection').text();
 		selected.first().find('.node_selection').replaceWith("<td class='node_selection' rowspan='" + selected.size() + "'>" + node_selection_text + "</td>");
 		selected.find('.node_selection').not('[rowspan]').replaceWith('');
 		 		
 		selected.removeClass('selected').addClass('inrule');
 		//selected.click( function() {} );
 		
 	 } ).addClass('clickable');
 	
 	$('#add_cond_button').click( function () {
 		
 		var new_rule = $('#rules_table').append('<tr class="new_rule">' + $('#rules_table #rule_model').html() + '</tr>').find('.new_rule');
 		new_rule.removeClass('new_rule');
 		new_rule.find('.editable_choice').click( toggleChoiceMode ).addClass('clickable').addClass('new_edit');
 		new_rule.find('.editable').click( toggleEditMode ).addClass('clickable').addClass('new_edit');
 		
 		
 	} ).addClass('clickable');
 	
 	
 	$('#save_orchestrator_settings').click( function () {
 		loading_start(); 
 		
 		var conditions = $('#rules_table .rule').map( function() {
 				var indicator = $(this).find('.indicator_name').text();
 				var time_laps = $(this).find('.time_laps').text();
 				var thresh_value = $(this).find('.thresh_value').text();
 				var required = {'var' : indicator.split(':')[1]};
 				required['min'] = thresh_value;
 				var rule = { 'set': indicator.split(':')[0], 'time_laps' : time_laps , 'required' : required };

 				return rule;
 			}).get();
 		
 		var rules = { 'conditions' : conditions };
 		
 		var params = { rules : JSON.stringify(rules)  };
 			
		$.get(save_orchestrator_settings_link, params, function(resp) {
			loading_stop();
			alert(resp);
		});
 	}).addClass('clickable');
 	
 	
 	
 	
     //$('a.normalTip').aToolTip(); 
     //$('div.aToolTip').aToolTip();
     //$('p.aToolTipContent').aToolTipContent();

});
 
