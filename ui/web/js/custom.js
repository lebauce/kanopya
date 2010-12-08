 $(document).ready(function(){
 
  	var url_params = window.location.href.split('?')[1];
 	var content_link = "/cgi/mcsui.cgi/monitoring/xml_graph_list?" + url_params;
 	var save_clustermonitoring_settings_link = "/cgi/mcsui.cgi/monitoring/save_clustermonitoring_settings?" + url_params;
 	var save_monitoring_settings_link = "/cgi/mcsui.cgi/monitoring/save_monitoring_settings";
 	var save_orchestrator_settings_link = "/cgi/mcsui.cgi/orchestration/save_orchestrator_settings"
 	
 // ------------------------------------------------------------------------------------
 	
 	$('.expand_ul ul').hide();
 	$('.expand_ul').click( function() {
 		$(this).find('ul').toggle();
 	} ).addClass('clickable');

	$('[id^=X] .expandable').hide();  // hide all elems of class 'expandable' under elem with id starting with 'X'
 	$(".expander", this).click(function() {
 		
 		var elem_to_expand = $('#X'+this.id).find('.expandable');
 		
 		if ( ! $('#X'+this.id).hasClass('expand_on')) {
 			
 			$('.expanded').hide('blind', {}, 300).removeClass('expanded');
 			$('.expand_on').removeClass('expand_on');
 		}
     	elem_to_expand.toggle('blind', {}, 300);
     	elem_to_expand.toggleClass('expanded');
     	$('#X'+this.id).toggleClass('expand_on');
     	
   }).addClass('clickable');
 	 
 	
 	function toggleEditMode() {
 		$(this).html( '<input value="' + $(this).text() + '"></input>'
					).find('input'
					).focusout( function () { $(this).replaceWith(this.value); } 
					).focus();
 		if ($(this).hasClass('new_edit')) {$(this).removeClass('new_edit');}
 	}
 	
 	function toggleChoiceMode() {
		if ($(this).hasClass('editing')) {return;}
		var value = $(this).text();
		var choices = $(this).attr('choices').split(',').map( function(elem) { return "<option>"+elem+"</option>";} ).join();
		$(this).html( '<select>' + choices + '</select>'
				).addClass('editing'
				).find('select'
				).focusout( function () { $(this).parent().removeClass('editing'); $(this).replaceWith( $(this).find('option:selected').text() );} 
				).focus().val(value);
		if ($(this).hasClass('new_edit')) {$(this).removeClass('new_edit');}
 	}
 	
 	$('.editable').click( toggleEditMode ).addClass('clickable');
 	
 	$('.editable_choice').click( toggleChoiceMode ).addClass('clickable');
 	
 	
 	
 	$('.select_collect').click( function () {
 				$(this).toggleClass('collected'); 
 				$(this).siblings('.select_graph').removeClass('graphed');
 	} ).addClass('clickable');
 	
 	$('.select_graph').click( function () {
 				$(this).toggleClass('graphed');
 				$(this).siblings('.select_collect').addClass('collected');
 	} ).addClass('clickable');
 	
 	$('.select_ds').click( function () { $(this).toggleClass('on_graph'); } ).addClass('clickable');
 	
 	$('#save_clustermonitoring_settings').click( function () {
 			loading_start(); 
 			var set_array = $('.select_collect.collected').map( function () { return $(this).siblings('.expander').attr('id');} ).get();

 			var settings = $('.select_graph.graphed').map( function() {
 				var set_label = $(this).siblings('.expander').attr('id');
 				var graph_settings = { 'set_label': set_label };
 				$('.graph_settings_' + set_label + ' .graph_option').each( function() { 												
	 															graph_settings[$(this).attr('opt_name')] = $(this).text(); 
	 														} )
	 			graph_settings['ds_label'] = $('.graph_settings_' + set_label + ' .select_ds.on_graph').map( function() { 												
	 															return $(this).attr('id'); 
	 														} ).get().join(",");
	 														
	 			return graph_settings;
 			}).get();
 			

 			var params = { 'collect_sets[]': set_array, 'graphs_settings': JSON.stringify(settings) };
 			
 			$.get(save_clustermonitoring_settings_link, params, function(resp) {
				loading_stop();
				alert(resp);				
				
			});
 	} ).addClass('clickable');
 
 
 	$('#save_monitoring_settings').click( function () {
 		loading_start(); 
 		
 		var settings = $('pouet');
 		
 		var params = {  };
 			
		$.get(save_monitoring_settings_link, params, function(resp) {
			loading_stop();
			alert(resp);
		});
 	}).addClass('clickable');
 
 	$('.set_def_show').click( function () { $('.set_def').show(); } );
 	$('.set_def_hide').click( function () { $('.set_def').hide(); } );
 	
 	
 	$('.yes_no_choice').click( function () { $(this).text($(this).text() == 'no' ? 'yes' : 'no') } ).addClass('clickable');
 	
 
 // ---------------------------------------- orchestrator --------------------------------------------	
 	
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

 // ------------------------------------------------------------------------------------
 
 	$('.simpleexpand').click( function () {
 		$('#X'+this.id).toggle();
 	}).addClass('clickable');
 
 // ------------------------------------------------------------------------------------
 
 	setInterval( 
 		function() {
	 		$("img.autorefresh").each( function() {
	 			var timestamp = new Date().getTime();
				//$(this).fadeOut('fast').attr('src',$(this).attr('src').split('?')[0] + '?' +timestamp ).fadeIn('fast');		
				$(this).attr('src',$(this).attr('src').split('?')[0] + '?' +timestamp );
 	 		})
 	 	} , 5000);
 
 	//$("#ivy1").show('bounce', {}, 500);
 	//$("#logo").show('slide', {}, 500);
 	//$("#logo").mouseover(function() { $(this).show('shake', {}, 500); });
 	
 	function toggleNodeSet() {
 /*
 		loading_start();
 		alert("marche pas encore... " + $(this).attr('id'));
		var anim = 'blind';//'blind/slide';
   		var anim_duration = 500;
   		$(".selected_node").removeClass('selected_node');
   		$(this).parents().find(".node_selector").addClass('selected_node');

		var set_name = $(this).attr('id');

		$(".selected_node table img").hide(anim, {}, anim_duration);

   		setTimeout( function() {
	   		var node_name = $('.selected_node').attr('id');
	   		
	   		var params;
		   	if ($('.selected_node').hasClass('expanded')) {
		   		$(".selected_node").removeClass('expanded'); 
		   		//var set_name = $('.selected_set').attr('id').split('_')[1];;
		   		params = {node: node_name, set: set_name};
		   	} else {
		   		$(".selected_node").addClass('expanded');
		   		params = {node: node_name};
		   	}
		   	
	   		// send request
	    	$.get(content_link, params, function(xml) {
				
				fill_content_container(xml);
		
				$(".selected_node img").addClass('autorefresh').show(anim, {}, anim_duration);
				loading_stop();
			});
		}, anim_duration);
*/   	 		
 	}
 
	function toggleNode() {

		loading_start();
		var anim = 'fold';//'blind/slide';
   		var anim_duration = 500;
   		$(".selected_node").removeClass('selected_node');
   		$(".activated_content_container").removeClass('activated_content_container');
   		$(this).addClass('selected_node');
   		var content_node = $("#" + $('.selected_node').attr('id') + "_content").addClass('selected_node');
   		content_node.addClass('activated_content_container');
   		
   		var delay = anim_duration;
   		//var imgs = $(".selected_node img");
   		var imgs = content_node.find("img");
   		if (imgs.size() == 0) {
   			delay = 0;
   		} else {
   			imgs.hide(anim, {}, anim_duration);
   		}

   		setTimeout( function() {
	   		var node_name = $('.selected_node').attr('id');
	   		var period = $('.selected_period').attr('id');
	   		var params;
		   	if ($('.selected_node').hasClass('expanded')) {
		   		$(".selected_node").removeClass('expanded');
		   		if ($('.selected_set').size() == 0) {
		   			$('.activated_content_container').html("");
		   			loading_stop();
		   			return;
		   		}
		   		var set_name = $('.selected_set').attr('id');
		   		params = {node: node_name, set: set_name, period: period};
		   	} else {
		   		$(".selected_node").addClass('expanded');
		   		params = {node: node_name, period: period};
		   	}
	   		// send request
	    	$.get(content_link, params, function(xml) {

				fill_content_container(xml);

				if ($('.selected_node').hasClass('expanded')) {
					$('.activated_content_container').find(".set_selector").click( toggleNodeSet ).addClass('clickable');
				}
				
				$('.activated_content_container').find("img").addClass('autorefresh').show(anim, {}, anim_duration);
				loading_stop();
			});
		}, delay);
		
	}
   
   function fill_content_container(xml) {
		$(xml).find('node').each(function(){ 
			var id = $(this).attr('id');
			$("#" + id + "_content").html($(this).children());
		});
		
		$("#nodecount_graph").html($(xml).find('nodecount').html());
   }
   
   function loading_start() {
   		$('body').css('cursor','wait');
   		$('.set_selector').addClass('unactive_set_selector').removeClass('set_selector');
   		$('.clickable').addClass('unactive_clickable').removeClass('clickable');		
   }
   
   function loading_stop() {
   		$('body').css('cursor','auto');
   		$('.unactive_set_selector').addClass('set_selector').removeClass('unactive_set_selector');	
   		$('.unactive_clickable').addClass('clickable').removeClass('unactive_clickable');
   }
   
   $(".set_selectors .set_selector").click(function() {
   
   		loading_start();
   		
   		var anim = 'fold';//'blind/slide';
   		var anim_duration = 0;
   		
   		$(".selected_set").removeClass('selected_set');
   		$(".expanded").removeClass('expanded');
   		$(this).addClass('selected_set');
   		//$("#graph_table img").hide(anim, {}, anim_duration);
   		setTimeout( function() {
   			
	   		var set_name = $('.selected_set').attr('id');
	   		var period = $('.selected_period').attr('id');
	   		// send request
	    	$.get(content_link, {set: set_name, period: period}, function(xml) {

				fill_content_container(xml);
				 
				$("#graph_table img").addClass('autorefresh');
				//$("#graph_table img").show(anim, {}, anim_duration);
				loading_stop();
			});
		}, anim_duration); 
   });
   
   $("#graph_table .node_selector").click( toggleNode ).addClass('clickable');
   
   //$(".period_selectors .period_selector").click(function() {
   $(".period_selector").click(function() {
   		$('.selected_period').removeClass('selected_period');
   		$(this).addClass('selected_period');
   		$('#period_label').html($(this).text());
   		var period = $(this).attr('id');
   		$('.content_container img').each( function() {
   			$(this).attr('src',$(this).attr('src').replace(/(day|hour|custom)/, period) );
   		});
   		$('#nodecount_graph img').attr('src', $('#nodecount_graph img').attr('src').replace(/(day|hour|custom)/, period) );
   		
   }).addClass('clickable');
   
   
   $('#fold_all').click( function() {
   		$('.selected_set').removeClass('selected_set');
   		$('.content_container img').hide('fold', {}, 500);
   		setTimeout( function() {$('.content_container').html('');}, 500);
   });
   
   
   //$("a").toggle(function(){ $("b").fadeOut('slow'); },function(){$("b").fadeIn('slow');});
   
   
   //$( ".draggable" ).draggable();
   
 });
