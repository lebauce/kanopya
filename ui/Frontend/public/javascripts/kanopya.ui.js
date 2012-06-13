var lastMsgId = '';

$(document).ready(function () {

    var loginModalOpened    = false;

    $(this).ajaxComplete(function(event, jqXHR) {
        if (jqXHR.responseXML !== undefined && !loginModalOpened) {
            loginModalOpened    = true;
            var form    = $("<form>", { id : "loginform"});
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
                draggable       : false,
                closeOnEscape   : false,
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
                            } else {
                                $("#errorCell").empty().text("Login failed").css("display", "block");
                            }
                        }
                      });
                    }
                }
            });
            $("a.ui-dialog-titlebar-close").remove();
        }
    });

    var main_layout = $('body').layout(
               { 
                   applyDefaultStyles: true,
                   defaults : { 
                       resizable : false,
                       slidable : false,
                   },
                   north : { closable : false },
                   west : { closable : false, resizable : true},
                   south : {
                       togglerContent_closed : 'Messages',
                       togglerLength_closed : 100,
                       spacing_closed : 14,
                       togglerContent_open : 'Messages',
                       togglerLength_open : 100,
                       spacing_open : 14,
                       initClosed : true,},
               }
    );               
               
	$.ajax({
		url: '/api/message?order_by=message_id%20DESC&rows=1&dataType=jqGrid',
		success: function(data) {
			$(data.rows).each(function(row) {
				lastMsgId = data.rows[row].pk;
			});
		}
	});
                
    // call for the themeswitcher
    //$('#switcher').themeswitcher();
    
});
