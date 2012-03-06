
function openform(url, title, w, h, options) {
    window.open(url, title, config='width='+w+', height='+h+', '+options);
}

function toggleEditMode() {
	$(this).html( '<input value="' + $(this).text() + '"></input>'
				).find('input'
				).focusout( function () { $(this).replaceWith(this.value); } 
				).focus();
	if ($(this).hasClass('new_edit')) {$(this).removeClass('new_edit');}
}

function toggleChoiceMode() {
	if ($(this).hasClass('editing')) {return;}
	var value = $(this).text();
	var choices = $(this).attr('choices').split(',').map( function(elem) { return "<option>"+elem+"</option>";} ).join();
	$(this).html( '<select>' + choices + '</select>'
			).addClass('editing'
			).find('select'
			).focusout( function () { $(this).parent().removeClass('editing'); $(this).replaceWith( $(this).find('option:selected').text() );} 
			).focus().val(value);
	if ($(this).hasClass('new_edit')) {$(this).removeClass('new_edit');}
}

function loading_start() {
	$('body').css('cursor','wait');
	$('.clickable').addClass('unactive_clickable').removeClass('clickable');		
}
   
function loading_stop() {
   	$('body').css('cursor','auto');	
   	$('.unactive_clickable').addClass('clickable').removeClass('unactive_clickable');
}

// Link must be a route witch return a JSON with one of the following keys: (error | redirect)
function catchError(link) {
    loading_start();
    $.getJSON(link, function(resp) {
            loading_stop();
            if (resp.error != undefined) {
                alert(resp.error);
            } else if (resp.redirect != undefined) {
                window.location= resp.redirect;
             }  
        });
}
   
/*********************************************
	Initialize generic behaviors
*********************************************/
function commonInit () {

	$('.editable').click( toggleEditMode ).addClass('clickable');
	
	$('.editable_choice').click( toggleChoiceMode ).addClass('clickable');

}

