require('jquery/jsrender.js');

function render(templatename, datas) {
    var html;
    $.ajax({
        url         : '/' + templatename + '.html',
        type        : 'GET',
        dataType    : 'text',
        async       : false,
        success     : function(template) {
            html    = $('<script>', {
                type    : 'text/x-jsrender',
                html    : template
            }).render(datas);
        }
    });
    return html;
}
