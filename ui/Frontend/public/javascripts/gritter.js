// This file is used to check and display notifications about new messages.
window.setInterval(function(){

    var jsondata = '';
    var maxID = lastMsgId;
    // Get Messages
    $.ajax({
        url: '/api/message',
        success: function(rows) {
            var newMsg = false;
            $(rows).each(function(row) {
                // Get the ID of last emmited message :
                if ( rows[row].pk > lastMsgId ) {
                    var content = rows[row].message_content;
                    newMsg = true;
                    // Display the notification :
                    $.gritter.add({
                        title: 'Message',
                        text: content,
                    });
                    if (parseInt(rows[row].pk) > maxID) {maxID = parseInt(rows[row].pk)}
                }
            });
            if (newMsg === true) {
                $("#grid-message").trigger('reloadGrid');
            }
            lastMsgId = maxID;
         }
    });
}, 5000);
