// This file is used to check and display notifications about new messages.
window.setInterval(function(){

	var jsondata = '';
	

	// Get Messages
	$.ajax({
 		url: '/api/message',
 		success: function(rows) {
		$(rows).each(function(row) {
    		// Get the ID of last emmited message :
    		if ( rows[row].pk > lastMsgId ) {
    			var content = rows[row].message_content;
    			// Display the notification :
    				$.gritter.add({
						title: 'Message',
						text: content,
					});
				}
    		});
  		}
	});
}, 50000000);
