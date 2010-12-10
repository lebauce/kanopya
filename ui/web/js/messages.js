function updatelist() {
	
	$('#messagelist tr').hide();
	
	var shows = '';
	var showsFrm = new Array();
	var showsLvl = new Array();
		
	$('.frm').each(function() {
		if($(this).attr('checked')) {
			showsFrm.push('.C'+ $(this).attr('value'));
		} 
	});
	
	$('.lvl').each(function() {
		if($(this).attr('checked')) {
			showsLvl.push('.C'+ $(this).attr('value'));
		} 
	});
	
	for(var i=0; i<showsFrm.length; i++) {
		for(var j=0; j<showsLvl.length; j++) {
			shows += 'tr'+showsFrm[i]+showsLvl[j]+', ';
		}
	}
	$(shows).show();
	
}

$(document).ready(function(){
	
	$('#checkAllFrom').click(function() {
		$('.frm').attr('checked', true);
		updatelist();
		
	});
	
	$('#checkAllLevel').click(function() {
		$('.lvl').attr('checked', true);
		updatelist();
	});
	
	$('.frm, .lvl').change(function() {
		updatelist();
	});

	updatelist();
	
	

});
 


