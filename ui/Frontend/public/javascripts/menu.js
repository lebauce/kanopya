// mainmenu_def is set in product specific menu.conf.js
function add_menu(container, label, submenu_links, elem_id) {
    var id_suffix = elem_id ? elem_id : 'static';
    var view_id = 'view_' + label + '_' + id_suffix;
    var link_id = 'link_' + view_id;
    
    // If this link already exists for this menu then we don't repeat it
    var existing_link = container.find('#'+link_id);
    if (existing_link.length != 0) {
        existing_link.addClass('alive_link');
        return;
    };
    
    var link = $('<li id="' + link_id + '" class="view_link alive_link"><a href="#' + view_id + '">' + label + '</a></li>');
    container.append(link);
    build_submenu($('#view-container'), view_id, submenu_links, elem_id);
    link.find('a').click( function() {onViewLinkSelect($(this), elem_id)} );
}

// Create and link all generic menu elements based on mainmenu_def from conf
function build_mainmenu() {
    
    var container = $('#mainmenu-container');
    
    for (var label in mainmenu_def) {
        var menu_head = $('<h3><a href="#">' + label + '</a></h3>');
        var menu_def = mainmenu_def[label];
        container.append(menu_head);
        
        var content = $('<ul></ul>');
        container.append(content);
        
        if (menu_def['onLoad']) {
            // Custom menu
            menu_head.click(menu_def['onLoad']);
        } else if (menu_def['json']) {
            // Dynamic load from json
            menu_head.click(menu_def['json'], loadMenuFromJSON);
        } else {
            // Static menu
            for (var sublabel in menu_def) {
                var submenu_links = menu_def[sublabel];
                add_menu(content, sublabel, submenu_links);
            }
        }
    }
    
    container.accordion();
}

function build_submenu(container, view_id, links, elem_id) {
    //var container = $('#view-container');
    
    // Create the div container for this view
    var view = $('<div class="view" id="' + view_id + '"></div>').appendTo(container);
    // Tab container of the view
    var submenu_cont = $('<ul></ul>').appendTo(view);
    
    view.tabs({
        select: function(event, ui) { 
            var link = String(ui.tab);
            //alert('Event select : ' + link.split('#')[1] + '  => ' + ui.panel);
            reload_content(link.split('#')[1], elem_id);
        }
    });
    for (var smenu in links) {
        var id_suffix = elem_id ? elem_id : 'static';
        //if (elem_id) {id_suffix = elem_id};
         
        var content_id = 'content_' + links[smenu]['id'] + '_' + id_suffix;
        var content = $('<div id="' + content_id + '"></div>');
        view.append(content);
        view.tabs('add', '#' + content_id , links[smenu]['label']);
        
        if (links[smenu]['onLoad']) {
            _content_handlers[content_id] = {'onLoad' : links[smenu]['onLoad']};
        }
    }
    
    view.hide();
}

function build_detailmenu(container, view_id, links, elem_id) {
    // Create the div container for this view
    var view = $('<div class="view" id="' + view_id + '"></div>').appendTo(container);
    // Tab container of the view
    var submenu_cont = $('<ul></ul>').appendTo(view);
    
    view.tabs({
        select: function(event, ui) { 
            var link = String(ui.tab);
            //alert('Event select : ' + link.split('#')[1] + '  => ' + ui.panel);
            reload_content(link.split('#')[1], elem_id);
        }
    });
    
    for (var smenu in links) {
        var content_id = 'content_' + links[smenu]['id'];
        var content = $('<div id="' + content_id + '"></div>');
        view.append(content);
        view.tabs('add', '#' + content_id , links[smenu]['label'])
        
        if (links[smenu]['onLoad']) {
            _content_handlers[content_id] = {'onLoad' : links[smenu]['onLoad']};
        }
    }
}

function onViewLinkSelect(view_link, elem_id) {
    // Hide all view div
    $('#view-container .view').hide();
    
    // Show div corresponding to this link 
    //$($(this).attr('href')).show(0, function(){alert('end show')});
    var view = $(view_link.attr('href'));
    view.show();
    
    //var selected_tab_idx = view.tabs('option', 'selected');
    //view.tabs('select', selected_tab_idx);
    
    
    //reload content of the current selected sub menu of the selected view (menu)
    var content_ref =  view.find('.ui-tabs-selected a').attr('href');
    if (content_ref !== undefined) {
        var content_id  = content_ref.split('#')[1]
        reload_content(content_id, elem_id);
    }
    
}

function remove_link (container) {
 // Remove dead links and associated view
    console.log($(container));
    console.log('######################');
    console.log($($(container).context).children());
    //$(container).find('.view_link').each(function (index,elem) {
    $(container).context.children.each(function (index,elem) {
        console.log('VIEW LINK');
        console.log(elem);
        if ($(elem).hasClass('alive_link')) {
            console.log('remove class')
            
            $(elem.context).removeClass('alive_link');
            console.log(elem);
        } else {
            var view = $($(this).find('a').attr('href'));
            view.remove();
        }
        //$(this).empty();
        //$(this).remove();
        console.log(this);
    });
    return;
    container.find('.view_link').each(function () {
        console.log('VIEW LINK ====');
        console.log(this);
    });
    //container.find('.view_link').remove();
}

function loadMenuFromJSON(event) {
    var menu_info = event.data;
    var container = $(this).next();
    
    $.getJSON(menu_info.url, function (data) {
        for (var elem in data) {
            add_menu(   container,
                        data[elem][menu_info.label_key],
                        menu_info.submenu,
                        data[elem][menu_info.id_key]
            );
        }
    });
    console.log('AFTER CREATE');
    console.log(container);
    console.log($('.view_link'));
    
    //container.empty();
    
    //remove_link(container[0]);
}

$(document).ready(function () {
    build_mainmenu();
});
