// mainmenu_def is set in product specific menu.conf.js

function build_mainmenu() {
    
    var container = $('#mainmenu-container');
    
    for (var label in mainmenu_def) {
        container.append('<h3><a href="#">' + label + '</a></h3>');
        var content = $('<ul></ul>');
        container.append(content.wrap('<div />'));
        for (var sublabel in mainmenu_def[label]) {
            var submenu_links = mainmenu_def[label][sublabel];
            var id = 'view_' + sublabel;
            content.append('<li><a class="view_link" href="#' + id + '">' + sublabel + '</a></li>');
            build_submenu(id, submenu_links);
        }
    }
    
    container.accordion();
}

function build_submenu(id, links) {
    var container = $('#view-container');
    
    // Create the div container for this view
    var view = $('<div class="view" id="' + id + '"></div>').appendTo(container);
    // Tab container of the view
    var submenu_cont = $('<ul></ul>').appendTo(view);
    
    view.tabs({
        select: function(event, ui) { 
            var link = String(ui.tab);
            //alert('Event select : ' + link.split('#')[1] + '  => ' + ui.panel);
            reload_content(link.split('#')[1]);
        }
    });
    
    for (var smenu in links) {
        var content_id = 'content_' + links[smenu]['id'];
        var content = $('<div id="' + content_id + '"></div>');
        view.append(content);
        view.tabs('add', '#' + content_id , links[smenu]['label'])
    }
    
    view.hide();
}

function link_mainmenu() {
    var all_view_links = $('#mainmenu-container .view_link');
    all_view_links.click(function () {
        // Hide all view div
        $('#view-container .view').hide();
        
        // Show div corresponding to this link 
        //$($(this).attr('href')).show(0, function(){alert('end show')});
        $($(this).attr('href')).show();
        
        //reload content of the current selected sub menu of the selected view (menu)
        var content_link_selector = $(this).attr('href') + ' .ui-tabs-selected a';
        var content_ref = $(content_link_selector).attr('href');
        var content_id  = content_ref.split('#')[1]
        reload_content(content_id);
    });
}

$(document).ready(function () {

    build_mainmenu();
    link_mainmenu();

});
