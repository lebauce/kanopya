
var current_user = get_current_user();

// mainmenu_def is set in product specific menu.conf.js
function add_menu(container, label, submenu_links, elem_id) {
    var id_suffix = elem_id ? elem_id : 'static';
    var view_id = 'view_' + label.replace(/ /g, '_') + '_' + id_suffix;
    var link_id = 'link_' + view_id;

    // If this link already exists for this menu then we don't repeat it
    var existing_link = container.find('#'+link_id);
    if (existing_link.length != 0) {
        existing_link.addClass('alive_link');
        return;
    };
    
    var link_li = $('<li id="' + link_id + '" class="view_link_cont alive_link"></li>');
    var link_a = $('<a class="view_link" href="#' + view_id + '">' + label + '</a>');
    
    if (container.index() == 1 && !elem_id) {
        link_li.append(
            $('<span class="kanopya-sprite kanopya-menu-sprite ui-icon-' + label.replace(/ /g, '-').toLowerCase() + '"></span>')
        );
    }else{
    	link_li.append(
            $('<span class="arrow"></span>')
        );
    }

    link_li.append(link_a);
    container.append(link_li);
    build_submenu($('#view-container'), view_id, submenu_links, elem_id);
    //link_li.find('a').click( function() {onViewLinkSelect($(this), elem_id)} );
    link_li.find('.view_link').click( {view_id: view_id, elem_id: elem_id,label:label}, onViewLinkSelect);
}

function add_menutree(container, label, menu_info, elem_id) {

    var link_li = $('<li>');
    var link_a = $('<a class="view_link"><span class="arrow"></span>' + label + '</a>');
    link_a.bind('click', function(event) {
        $(this).next().toggle();

        var add_button;
        if ($('#instantiate_service_button') != undefined && $('#instantiate_service_button').length) {
            add_button = $('#instantiate_service_button');
        }

        $('#services_list').jqGrid('GridDestroy');
        $('#view-container .master_view').hide();
        $('#view_Services').show();
        $('a[href=#content_services_overview_static]').text(label +' instances');
        $('.selected_viewlink').removeClass('selected_viewlink')
        $(this).addClass('selected_viewlink');

        var container_id = 'content_services_overview_static';

        create_grid( {
            url: '/api/cluster?expand=service_template,nodes&service_template.service_template_id=' + elem_id,
            content_container_id: container_id,
            grid_id: 'services_list',
            afterInsertRow: function (grid, rowid, rowdata, rowelem) {
                if (!servicesListFilter(rowelem)) {
                    $(grid).jqGrid('delRowData', rowid);
                } else {
                    addServiceExtraData(grid, rowid, rowdata, rowelem);
                }
            },
            rowNum : 25,
            colNames: [ 'ID', 'Instance Name', 'State', 'Rules State', 'Node Number' ],
            colModel: [
                { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
                { name: 'cluster_name', index: 'service_name', width: 200 },
                { name: 'cluster_state', index: 'service_state', width: 90, formatter:StateFormatter },
                { name: 'rulesstate', index : 'rulesstate' },
                { name: 'node_number', index: 'node_number', width: 150 }
            ],
            elem_name   : 'service',
            details     : { link_to_menu : 'yes', label_key : 'cluster_name'},
            before_container : add_button
        });
    });
    var sublevel = $('<ul>');
    sublevel.hide();

    var url = 'service_template_id=' + elem_id;
    if (menu_info.level2_url.indexOf("?") !== -1) {
        url = '&' + url;
    } else {
        url = '?' + url;
    }
    url = menu_info.level2_url + url;
    $.getJSON(url, function (data) {
        var n   = 0;
        for(index in data) {
            if (menu_info.level2_filter == null || menu_info.level2_filter(data[index]) === true) {
                ++n;
                add_menu(sublevel,data[index].cluster_name,menu_info.submenu,data[index].pk);
                //sublevel.append($('<li>'+data[index].cluster_name+'</li>'));
            }
        }
        if (n === 0) {
            $(link_li).remove();
        } else {
            $(link_li).show();
        }
    });

    link_li.append(link_a);
    link_li.append(sublevel);
    $(link_li).hide();
    container.append(link_li);
}

// Create and link all generic menu elements based on mainmenu_def from conf
function build_mainmenu() {
    var container = $('#mainmenu-container');

    var submenu_elements = undefined;
    var menu_elements    = undefined;

    // Get the list of menuentries for the current profile :
    $.ajax({
        async    : false,
        url      : 'javascripts/KIM/menuprofiles.json',
        type     : 'GET',
        dataType : 'json',
        success  : function(data) {
            for (var profile in current_user.profiles) {
                var profile_id = current_user.profiles[profile].profile_id;
                if (data[profile_id] != undefined) {
                    if (menu_elements !== undefined) {
                        menu_elements    = arrayIntersect(menu_elements, data[profile_id].menu_entries);
                        submenu_elements = arrayIntersect(submenu_elements, data[profile_id].submenu_entries)
                    } else {
                        menu_elements    = data[profile_id].menu_entries;
                        submenu_elements = data[profile_id].submenu_entries;
                    }
                }
            }
        }
    });
    
    for (var label in mainmenu_def) {
        if ($.inArray(label, menu_elements) < 0) {
            var menu_head = $('<h3 id="menuhead_' + label.replace(/ /g, '_') + '"><a href="#">' + label + '</a></h3>');
            var content = $('<ul id="'+label+'"></ul>');
            container.append(menu_head);
            container.append(content);
			jQuery.data(container,'section',label);
            if (mainmenu_def[label]['onLoad']) {
                // Custom menu
                menu_head.click(mainmenu_def[label]['onLoad']);

            } else if (mainmenu_def[label]['json']) {
                // Dynamic load from json
                menu_head.click(mainmenu_def[label]['json'], loadMenuFromJSON);

            } else if(mainmenu_def[label]['jsontree']) {
                menu_head.click(mainmenu_def[label]['jsontree'], loadTreeMenuFromJSON);

            } else {
                for (var sublabel in mainmenu_def[label]) {
                    if ($.inArray(sublabel, submenu_elements) < 0) {
                        add_menu(content, sublabel, mainmenu_def[label][sublabel]);
                    }
                }
            }
            // Specific view when select menu head
            if (mainmenu_def[label]['masterView']) {
                var view_id = 'view_' + label.replace(/ /g, '_');
                build_submenu($('#view-container'), view_id, mainmenu_def[label]['masterView']);
                menu_head.click( {view_id: view_id,category:label}, onViewLinkSelect);
            }
        }
    }

    container.accordion( {
        clearStyle  : true,     // size to content
        active      : false,    // all parts closed at start
    } );
}

function get_current_user () {
    // Get username of current logged user :
    var username = '';
    var user;
    $.ajax({
        async   : false,
        url     : '/me',
        type    : 'GET',
        success : function(data) {
            username = data.username;
        }
    });
    // Get profile list for the username :
    $.ajax({
        async   : false,
        url     : '/api/user?expand=profiles&user_login=' + username,
        type    : 'GET',
        success : function(data) {
            user = {
                user_id  : data[0].pk,
                profiles : data[0].profiles
            }
        }
    });
    return user;
}

function build_submenu(container, view_id, links, elem_id) {
    // Create the div container for this view
    var class_master='master_view';
    var class_menu='invisible';
    var style_master='';
    if(links.length>1){
        class_master+=' with-submenu';
        style_master='style=""'
        class_menu='';
    }
    var view = $('<div class="'+class_master+'" id="' + view_id + '" '+style_master+'></div>').appendTo(container);
    // Tab container of the view
    var submenu_cont = $('<ul class="'+class_menu+' submenu"></ul>').appendTo(view);

    var tabs = view.tabs({});

    for (var smenu in links) {
        if (links[smenu].hidden) {
            continue;
        }

        var id_suffix = elem_id ? elem_id : 'static';

        var content_id = 'content_' + links[smenu]['id'] + '_' + id_suffix;
        var content = $('<div id="' + content_id + '"></div>');
        view.append(content);
        view.tabs('add', '#' + content_id ,
                  (links[smenu]['icon'] ? "<span class='kanopya-tab-sprite kanopya-sprite ui-icon-" + links[smenu]['icon'] + "'></span>" : "" ) +
                  links[smenu]['label']);

        if (links[smenu]['onLoad']) {
            _content_handlers[content_id] = {
                    'onLoad' : links[smenu]['onLoad'],
                    'info' : links[smenu]['info']
            };
        }
    }
    w_cont = view.innerWidth() - 20;
    w_cont -= parseInt(submenu_cont.css('margin-left')) + parseInt(submenu_cont.css('margin-right'));
    var w  = 0;
    submenu_cont.find('li').each(function() {
        w += $(this).width();
    });

    if (w_cont > 0 && w > 0 && w_cont <= w) {
        tabs.scrollabletab();
    }

    // Load content on show event because we need the tab be visible to have a width and so scale content (grid autowidth)
    // Set here and not at tabs creation to avoid async problem (i.e trigger tabsshow before _content_handlers update)
    view.bind("tabsshow", function(event, ui) {
        var link = String(ui.tab);
        reload_content(link.split('#')[1], elem_id);
    });
   
    view.hide();
}

function onViewLinkSelect(event) {
    var view_id = event.data.view_id;
    var elem_id = event.data.elem_id;
    var category= event.data.category;
    
    var breadcrumb=$('h2#breadcrump');
    var id_actions='';
    // Hide all view div
    $('#view-container .master_view').hide();
    
    if (typeof category != 'undefined') {
    	var breadcrumb_html= category;	
    	id_actions=category;
    }else{	
    	var link_active=$('#link_'+view_id);
    	var element_parents=link_active.parents('ul');
    	var title_link_active=link_active.children('a').text();
    	var nombre_parents=element_parents.length;
    	id_actions=title_link_active;
    	if(nombre_parents==1){
    		var title_section_active=element_parents.attr('id');
    		var breadcrumb_html= title_section_active+' <span> &gt; '+title_link_active+'</span>';
   		}else{
   			var title_section_active=element_parents.parent('li').children('a').text();
   			var breadcrumb_html= 'Services &gt; '+title_section_active+' <span> &gt; '+title_link_active+'</span>';
   		}
   	}
   	breadcrumb.html(breadcrumb_html);		
    var view = $('#'+view_id);
    var tabs_view=$('#'+view_id+' > ul.ui-tabs-nav');
    if(tabs_view.nextAll('.action_buttons"').length == 0){
     tabs_view.after('<div class="action_buttons"></div>');	
    }
   
    view.show();
    
    //var selected_tab_idx = view.tabs('option', 'selected');
    //view.tabs('select', selected_tab_idx);
    
    $('.selected_viewlink').removeClass('selected_viewlink')
    $(this).addClass('selected_viewlink');
    
    
    //reload content of the current selected sub menu of the selected view (menu)
    var content_ref =  view.find('.ui-tabs-selected a').attr('href');
    if (content_ref !== undefined) {
        $('div.toRemove').remove();
        var content_id  = content_ref.split('#')[1];
        reload_content(content_id, elem_id);
    }
    
}

function loadMenuFromJSON(event) {
    var menu_info = event.data;
    var container = $(this).next();

    $.getJSON(menu_info.url, function (data) {
        // Add menu entry and associated view
        for (var elem in data) {
            if (data[elem][menu_info.label_key] != null) {
                if (menu_info.filter == null ||
                    menu_info.filter(data[elem]))
                {
                    add_menu(   container,
                        data[elem][menu_info.label_key],
                        menu_info.submenu,
                        data[elem][menu_info.id_key]
                    );
                }
            }
        }
        
        // Remove old links and view
        var dead_links = container.find('.view_link_cont:not(.alive_link)').each(function () {
            var view = $($(this).find('.view_link').attr('href'));
            view.remove();
            $(this).remove();
        });
        container.find('.alive_link').removeClass('alive_link');
    });

}

function loadTreeMenuFromJSON(event) {
    var menu_info = event.data;
    var container = $(this).next();

    container.empty();

    $.getJSON(menu_info.level1_url, function (data) {
        // Add menu entry and associated view
        for (var elem in data) {
            if (data[elem][menu_info.level1_label_key] != null) {
                add_menutree(   container,
                        data[elem][menu_info.level1_label_key],
                        menu_info,
                        data[elem][menu_info.id_key]
                );
            }
        }
        
        // Remove old links and view
        //~ var dead_links = container.find('.view_link_cont:not(.alive_link)').each(function () {
            //~ var view = $($(this).find('.view_link').attr('href'));
            //~ view.remove();
            //~ $(this).remove();
        //~ });
        //~ container.find('.alive_link').removeClass('alive_link');
    }); 
    
}

function arrayIntersect(arr1, arr2) {
    var temp = new Array();

    for(var i = 0; i < arr1.length; i++) {
        for(var k = 0; k < arr2.length; k++) {
            if(arr1[i] == arr2[k]) {
                temp[temp.length] = arr1[i];

            }
        }
    }
    return temp;
}

$(document).ready(function () {
    build_mainmenu();
    
    function show_mainpage() {
        $('#view-container .master_view').hide();
        $('#view-dashboard').show();
    }

    // Display dashboard when click on product name or kanopya logo
    $('#product-name').click( show_mainpage );
    $('#menu_logo').click( show_mainpage );

    // Display welcome image only when everythings loaded
    $('#image-welcome').show();
});
