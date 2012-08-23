require('messages.js');
require('gritter.js');

var lastMsgId = 0;

$(document).ready(function () {

    var loginModalOpened    = false;
    var mustOpen            = true;

    var openedRequests      = 0;

    $(this).ajaxSend(function(event) {
        ++openedRequests;
        $('body').css('cursor', 'wait');
        setTimeout(function() {
            openedRequests  = 0;
            $('body').css('cursor', 'default');
        }, 10000);
    });

    $(this).ajaxComplete(function(event, jqXHR, ajaxOptions) {
        --openedRequests;
        if (openedRequests === 0) {
            $('body').css('cursor', 'default');
        }
        if (jqXHR.responseXML !== undefined && !loginModalOpened && mustOpen) {
            loginModalOpened    = true;
            var form    = $("<form>", { id : "loginform", class : 'LOGINFORM' });
            var table   = $("<table>", { width : "100%" }).appendTo($(form));
            $(table).append($("<tr>")
              .append($("<td>", { align : 'center', colspan : 2, id : 'errorCell', class : 'ui-state-error ui-corner-all' }).css('display', 'none')));
            $(table).append($("<tr>")
              .append($("<td>").append($("<label>", { for : 'loginInput', text : 'Login : ' })))
              .append($("<td>", { align : 'right' })
                .append($("<input>", { type : 'text', name : 'login', id : 'loginInput' }))));
            $(table).append($("<tr>")
              .append($("<td>").append($("<label>", { for : 'passwordInput', text : 'Password : ' })))
              .append($("<td>", { align : 'right' })
                .append($("<input>", { type : 'password', name : 'password', id : 'passwordInput' }))));
            $(form).dialog({
                resizable       : false,
                closeOnEscape   : false,
                close           : function() { $(this).remove(); },
                modal           : true,
                buttons         : {
                    'Ok'    : function() {
                      var dial  = this;
                      $.ajax({
                        url         : '/login',
                        type        : 'POST',
                        data        : {
                            login       : $(form).find("input#loginInput").attr('value'),
                            password    : $(form).find("input#passwordInput").attr('value')
                        },
                        complete    : function(a, b) {
                            var response    = JSON.parse(a.responseText);
                            if (response.status === 'success') {
                                $(dial).dialog("destroy");
                                loginModalOpened    = false;
                                mustOpen            = false;
                            } else {
                                $("#errorCell").empty().text("Login failed").css("display", "block");
                            }
                        }
                      });
                    }
                }
            });
            $("a.ui-dialog-titlebar-close").remove();
        } else if (jqXHR.responseXML !== undefined && !mustOpen) {
          mustOpen  = true;
        }
    });

    var main_layout = $('body').layout(
               { 
                   applyDefaultStyles: true,
                   defaults : { 
                       resizable : false,
                       slidable : false,
                   },
                   center : {
                       onresize : function () {
                           // Manage current jqgrid resizing
                           $('.current_content .ui-jqgrid-btable').each( function () {
                               // Also manage grid inside an accordion
                               var new_width = $(this).closest('.ui-accordion-content').width() || $('.current_content').width();
                               $(this).jqGrid('setGridWidth', new_width);
                           } );

                           // Manage current jqplot resizing
                           $('.jqplot-target').trigger('resizeGraph');
                       }
                   },
                   north : {
                       closable : false
                   },
                   west : {
                       minSize   : 220,
                       closable  : false,
                       resizable : true
                   },
                   east : {
                       resizable : true,
                       initClosed : true
                   },
                   south : {
                       togglerContent_closed : 'Messages',
                       togglerLength_closed : 100,
                       spacing_closed : 14,
                       togglerContent_open : 'Messages',
                       togglerLength_open : 100,
                       spacing_open : 14,
                       initClosed : true
                   },
               }
    );

    initMessages();

    // TODO maybe we can do this in initMessages
    $.ajax({
        url: '/api/message?order_by=message_id%20DESC&rows=1&dataType=jqGrid',
        success: function(data) {
            $(data.rows).each(function(row) {
                if (parseInt(data.rows[row].pk) > lastMsgId) {
                    lastMsgId = parseInt(data.rows[row].pk);
                }
            });
        }
    });

    // call for the themeswitcher
    //$('#switcher').themeswitcher();
});
