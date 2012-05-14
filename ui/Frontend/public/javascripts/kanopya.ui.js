$(document).ready(function () {
    var main_layout = $('body').layout(
               { 
                   applyDefaultStyles: true,
                   defaults : { 
                       resizable : false,
                       slidable : false,
                   },
                   south : { 
                       togglerContent_closed : 'Messages',
                       togglerLength_closed : 100,
                       spacing_closed : 14,
                       initClosed : true,},
                   north : { closable : false },
                   west : { closable : false },
               }
    );
    
    /*var stateUrl = '/images/icons/question.png';
    var upUrl = '/images/icons/up.png';
    var brokenUrl = '/images/icons/broken.png';*/

    $("#grid-message").jqGrid({
    	url:'/messager/messages', 
        datatype: "json",
        loadonce: true,
        height: '200px',
        width: 'auto',
        colNames:['Id','From','Level','Date','Time','Content'],
        colModel:[
        		{name:'id',index:'id', width:60, key:true},
                {name:'from',index:'from',width:90},
                {name:'level',index:'level',width:40,formatter:stateFormatter},
                {name:'date',index:'date',width:130},
                {name:'time',index:'time',width:130},
                {name:'content',index:'content', width:500,}
        ],
        //multiselect: true,
        rowNum:8, rowList:[5,10,20,50],
        pager: '#msgGridPager',
        caption: "Messages",
        altRows: false,
        onSelectRow: function (id) {
            alert('Select row: ' + id);
        },
    });
    
	function stateFormatter(cell, options, row) {
		if (cell == 'info') {
			return "<img src='/images/icons/up.png' />";
		} else {
			return "<img src='/images/icons/broken.png' />";
		}
	}
    
    $("#grid-message").jqGrid('navGrid','#msgGridPager',{edit:false,add:false,del:false});

   /*var mydata = [ 
                    {mess_id:"1",user_id:"NULL",mess_from:"Executor",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:18",mess_level:"warning",content:"Kanopya Executor stopped"},
					{mess_id:"2",user_id:"NULL",mess_from:"StateManager",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:20",mess_level:"warning",content:"Kanopya State Manager stopped"},
					{mess_id:"3",user_id:"NULL",mess_from:"Executor",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:21",mess_level:"info",content:"Kanopya Executor started"},
					{mess_id:"4",user_id:"NULL",mess_from:"Monitor",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:22",mess_level:"warning",content:"Kanopya Collector stopped"},
					{mess_id:"5",user_id:"NULL",mess_from:"StateManager",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:23",mess_level:"info",content:"Kanopya State Manager started"},
					{mess_id:"6",user_id:"NULL",mess_from:"Monitor",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:24",mess_level:"warning",content:"Kanopya Grapher stopped"},
					{mess_id:"7",user_id:"NULL",mess_from:"Monitor",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:25",mess_level:"info",content:"Kanopya Collector started"},
					{mess_id:"8",user_id:"NULL",mess_from:"Orchestrator",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:26",mess_level:"warning",content:"Kanopya Orchestrator stopped"},
					{mess_id:"9",user_id:"NULL",mess_from:"Monitor",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:27",mess_level:"info",content:"Kanopya Grapher started"},
					{mess_id:"10",user_id:"NULL",mess_from:"Orchestrator",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:29",mess_level:"info",content:"Kanopya Orchestrator started"},
					{mess_id:"11",user_id:"NULL",mess_from:"Executor",mess_creationdate:"2012-05-02",mess_creationtime:"16:06:35",mess_level:"error",content:"Cluster cluster01 failure"},
                ];*/ 
   /* for(var i=0;i<=mydata.length;i++) {
    	jQuery("#grid-message").jqGrid('addRowData',i+1,mydata[i]);
    }*/

    // Needed to fix bad panels resizing when opening Messages pane (south) for the first time
    // Layout will take in account the message grid size fill with data 
    main_layout.resizeAll();
});
