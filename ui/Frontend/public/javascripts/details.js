 $(document).ready(function(){
	
	$('.simpleexpand').click( function () {
 		$('#X'+this.id).toggle();
 	}).addClass('clickable');

 //
    $('.node_action').click(function() {
        
        $.getJSON(
            '/architectures/extclusters/'+$('#cluster_id').attr('value')+'/actions',
            {action_id:$('#action_id').attr('value'), 
             hostname:$(this).attr('name'), 
             node_id:$(this).attr('value'),
            },
            function(data){
                alert(data.message);
                window.location = '/architectures/extclusters/'+$('#cluster_id').attr('value');
                
            }
        );
    });
    
});
