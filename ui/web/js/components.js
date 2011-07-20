$(document).ready(function(){
  
  	var url_params = window.location.href.split('?')[1];
  	var save_component_conf_link = "/cgi/kanopya.cgi/components/process_configurecomponent_from_json?" + url_params;
  	var redirect_link = "/cgi/kanopya.cgi/clusters/view_clusterdetails";
  
  	// Given a jQuery object as root, build the conf struct
  	function buildConf ( root ) {
 		var conf = {};
 		
 		// Store simple value
 		root.find( '.' + root.attr('name') + '_simple_value').each( function() {
			if ($(this).attr('type') == 'checkbox' ) {
				conf[$(this).attr('name')] = $(this).attr('checked') ? 1 : 0;
			} else {
 				conf[$(this).attr('name')] = $(this).attr('value');
			}
 		} );

		// Store array
 		var multi = root.find('.' + root.attr('name') + '_array_value').each( function() {		
 			var id = $(this).attr('id'); 			
 			var elems = $(this).find('.elem_' + id).map( function() {
 				return buildConf($(this));
 			}).get();
 			conf[id] = elems;
 		} );
 		
 		return conf; 
 	}

	// Build conf struct, stringify and send it to the server
	function save () {
		var conf = buildConf( $('.elem_root') );

		var params = { conf : JSON.stringify(conf) };
		$.get(save_component_conf_link, params, function(resp) {
			//loading_stop();
			alert(resp);
			window.location= redirect_link + "?cluster_id=" + conf['cluster_id'];
		});
		
	}

	$('#save_button').click( save );


	// link remove button to the corresponding element
	function linkRemoveElem () {
		var elem = $(this);
		var remove_button = $(this).find('.remove_' + $(this).attr('name'));
		remove_button.click( function () {
			elem.replaceWith("");	
		});
	}
	
	// link add button to the corresponding array
	function linkAddElem () {
		var array = $(this);
		var add_button = $(this).parents('[class^=elem_]').first().find('.add_' + array.attr('id'));
		var model_elem = $('#models .elem_'  + array.attr('id'));
		add_button.click( function () {
			new_elem = model_elem.clone();
			new_elem.find('[class$=_array_value]').each( linkAddElem );
			new_elem.find('[class^=elem_]').each( linkRemoveElem );
			new_elem.each( linkRemoveElem );
			array.append(new_elem);
			} );
	}
	
	// Init add button links
	$('[class$=_array_value]').each( linkAddElem );

	// Init remove button links
	$('[class^=elem_]').each( linkRemoveElem );

	
	// Init select tags by selecting option with same value than selected_value attr of select tag
	$('select').each( function () {
		var option = $(this).find('option[value=' + $(this).attr('selected_value') + ']');
		option.attr('selected', 'selected');
	});
	
});
 
