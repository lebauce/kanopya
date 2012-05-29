$(document).ready(function () {

$("#grid-message").jqGrid({
    	url:'/messager/messages', 
        datatype: "json",
        jsonReader : {
      		root:"rows",
      		page: "page",
      		total: "total_pages",
      		records: "records",
      		repeatitems: false,
      		//id: "id"
   		},
        // By comment loadonce the user will able to refresh the grid content :
        loadonce: false,
        height: '200px',
        width: 'auto',
        colNames:['Id','From','Level','Date','Time','Content'],
        colModel:[
        		{name:'id',index:'id', width:60, key:true},
                {name:'from',index:'from',width:90},
                {name:'level',index:'level',width:40,formatter:stateFormatter},
                {name:'date',index:'date',width:100},
                {name:'time',index:'time',width:100},
                {name:'content',index:'content', width:130,}
        ],
        //multiselect: true,
        rowNum:10, rowList:[5,10,20,50,100],
        pager: '#msgGridPager',
        caption: "",
        altRows: false,
        onSelectRow: function (id) {
            alert('Select row: ' + id);
        },
    });
    
    //jQuery('#grid-message').jqGrid('searchGrid', {multipleSearch:true} );
    
    // Remove rollup icon
	$("#grid-message.ui-jqgrid-titlebar-close").remove();
    
    // Set the correct state icon for each message :
	function stateFormatter(cell, options, row) {
		if (cell == 'info') {
			return "<img src='/images/icons/up.png' title='info' />";
		} else {
			return "<img src='/images/icons/broken.png' title='warning' />";
		}
	}
	
	// Resize the message grid to entire page width :
	//$(window).bind('resize', function() { $("#grid-message").setGridWidth($(window).width()-20); }).trigger('resize');
	$('#grid-message').jqGrid('setGridWidth', $('#view-container').parent().width()-20);

        
    $("#grid-message").jqGrid('navGrid','#msgGridPager',{edit:false,add:false,del:false});
    
    // Needed to fix bad panels resizing when opening Messages pane (south) for the first time
    // Layout will take in account the message grid size fill with data 
    $('body').layout().resizeAll();
    
    });