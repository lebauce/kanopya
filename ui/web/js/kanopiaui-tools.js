
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

/*********************************************
	Initialize generic behaviors
*********************************************/
function commonInit () {

	$('.editable').click( toggleEditMode ).addClass('clickable');
	
	$('.editable_choice').click( toggleChoiceMode ).addClass('clickable');

}
