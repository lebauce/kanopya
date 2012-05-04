// each link will show the div with id "view_<link_name>" and hide all div in "#view-container"
var mainmenu_def = {
    'Infrastructure'    : ['Compute','Storage','IaaS','Network','System'],
    'Business'          : ['Profiles', 'Accounting'],
    'Services'           : [],
    'Administration'    : ['Kanopya', 'Right Management', 'Monitoring'],
    };


function build_mainmenu() {
    
    var container = $('#mainmenu-container');
    
    for (var k in mainmenu_def) {
        container.append('<h3><a href="#">' + k + '</a></h3>');
        var content = $('<ul></ul>');
        container.append(content.wrap('<div />'));
        for (var idx in mainmenu_def[k]) {
            var li = mainmenu_def[k][idx];
            content.append('<li><a class="view_link" href="#view_' + li + '">' + li + '</a></li>');
        }
    }
    
    container.accordion();
}

function link_mainmenu() {
    var all_view_links = $('#mainmenu-container .view_link');
    all_view_links.click(function () {
        // Hide all view div
        $('#view-container div').hide();
        // Show div corresponding to this link 
        //$($(this).attr('href')).show(0, function(){alert('end show')});
        $($(this).attr('href')).show();
    });
}

$(document).ready(function () {

    build_mainmenu();
    link_mainmenu();

});
