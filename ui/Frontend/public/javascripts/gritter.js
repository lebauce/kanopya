// This file is used to check and display notifications about new messages.
window.setInterval(function(){

	var jsondata = '';
	

	// Get Messages
	$.ajax({
 		url: '/messager/messages',
 		success: function(data) {
		$(data.rows).each(function(row) {
    		// Get the ID of last emmited message :
    		if ( data.rows[row].pk > lastMsgId ) {
    			var content = data.rows[row].content;
    			// Display the notification :
    				$.gritter.add({
						title: 'Message',
						text: content,
					});
				}
    		});
  		}
	});
}, 5000);