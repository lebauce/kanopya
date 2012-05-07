// each link will show the div with id "view_<link_name>" and hide all div in "#view-container"
var mainmenu_def = {
    'Infrastructure'    : {
        'Compute' : ['overview', 'hosts'],
        'Storage' : [''],
        'IaaS'    : ['All IaaS'],
        'Network' : [],
        'System'  : [],
    },
    'Business'          : {
        'Profiles'   : [],
        'Accounting' : []
    },
    'Services'           : {
    
    },
    'Administration'    : {
        'Kanopya'          : [],
        'Right Management' : [],
        'Monitoring'       : []
    },
};


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
    var submenu_cont = $('<ul></ul>').appendTo(view);
    
    for (var label in links) {
        var content_id = 'content_' + label;
        submenu_cont.append('<li><a href="#' + content_id + '">' + links[label] + '</a></li>');
        view.append('<div id="' + content_id + '">' + links[label] + '</div>');
    }
    view.tabs();
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
    });
}

$(document).ready(function () {

    build_mainmenu();
    link_mainmenu();

    //$('#example').tabs();
});
