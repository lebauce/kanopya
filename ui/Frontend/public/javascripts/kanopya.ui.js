$(document).ready(function () {
    //$('body').layout({ applyDefaultStyles: true });
    $('body').layout({
        resizable : true,
        //applyDefaultStyles: true
    });


    $("#grid-message").jqGrid({ 
        datatype: "local",
        loadonce: true,
        height: 'auto',
        width: '100%',
        colNames:['Mess ID','Date', 'content'],
        colModel:[ 
                {name:'mess_id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
                {name:'date',index:'date', width:90, sorttype:"date"},
                {name:'content',index:'content', width:200,}],
        //multiselect: true,
        rowNum:5, rowList:[5,10,20,50],
        //caption: "Messages",
        altRows: true,
        onSelectRow: function (id) {
            alert('Select row: ' + id);
        },
    });

   var mydata = [ 
                    {mess_id:"1",date:"2007-10-01",content:"salut julien"},
                    {mess_id:"2",date:"2007-10-03",content:"bien ou bien?"},
                    {mess_id:"2",date:"2007-10-03",content:"bien ou bien?"},
                    {mess_id:"2",date:"2007-10-03",content:"bien ou bien?"},
                    {mess_id:"2",date:"2007-10-03",content:"bien ou bien?"},
                    {mess_id:"2",date:"2007-10-03",content:"bien ou bien?"},
                    {mess_id:"2",date:"2007-10-03",content:"bien ou bien?"},
                ]; 
    for(var i=0;i<=mydata.length;i++) jQuery("#grid-message").jqGrid('addRowData',i+1,mydata[i]);

});
