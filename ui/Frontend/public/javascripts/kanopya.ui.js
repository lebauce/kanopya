$(document).ready(function () {
    $('body').layout(
               { 
                   applyDefaultStyles: true,
                   defaults : { 
                       resizable : true,
                       slidable : true,
                   },
                   south : { 
                       togglerContent_closed : 'Messages',
                       togglerLength_closed : 100,
                       spacing_closed : 14,},
                   north : { closable : false },
                   west : { closable : false },
               }
    );
//    $('body').layout({
//        resizable : true,
//    });


    $("#grid-message").jqGrid({ 
        datatype: "local",
        loadonce: true,
        height: '100%',
        width: 'auto',
        colNames:['Mess ID','User ID','From','Date','Time','Level','content'],
        colModel:[ 
                {name:'mess_id',index:'entity_id',width:80,sorttype:"int",hidden:false,key:true},
                {name:'user_id',index:'user_id',width:60,sorttype:"int",key:true},
                {name:'from',index:'from',width:150},
                {name:'date',index:'date',width:130, sorttype:"date"},
                {name:'time',index:'time',width:130},
                {name:'level',index:'level',width:150,editable:true},
                {name:'content',index:'content', width:500,}],
        //multiselect: true,
        rowNum:5, rowList:[5,10,20,50],
        pager: '#pager',
        caption: "Messages",
        altRows: true,
        onSelectRow: function (id) {
            alert('Select row: ' + id);
        },
    });
    
    $("#grid-message").jqGrid('navGrid','#pager',{edit:false,add:false,del:false});

   var mydata = [ 
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
                ]; 
    for(var i=0;i<=mydata.length;i++) jQuery("#grid-message").jqGrid('addRowData',i+1,mydata[i]);

});
