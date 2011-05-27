 $(document).ready(function(){
 

 // ------------------------------------------------------------------------------------
 // test jqplot
 
 	var line1 = [[1130000000000, 2],[1130003600000,5.12],[1130007200000,13.1],[1130010800000,33.6],[1130014400000,85.9],[1130018000000,219.9]];
 	var line2=[['23-May-08', 578.55], ['20-Jun-08', 566.5], ['25-Jul-08', 480.88], ['22-Aug-08', 509.84],
      ['26-Sep-08', 454.13], ['24-Oct-08', 379.75], ['21-Nov-08', 303], ['26-Dec-08', 308.56],]
 	
 	var plot = $.jqplot('chartdiv',  [line1], {
 	   axes:{
        xaxis:{
          renderer:$.jqplot.DateAxisRenderer,
          tickOptions:{
            //formatString:'%b&nbsp;%#d'
            formatString:'%R',
            showGridline: true,
            
          } 
        },
        yaxis: {
            min: 0,
            showTicks: true,
            autoscale: false,
        },
 	  },
 	  
    });
 	setTimeout("updateData()", 1000);
 	
 	var curr_time = 1130018000000;
 	 updateData = function()
        {
                        //if (dataIdx > 10)
                       //         data.shift();
                        //data.push([ dataIdx++, getRandomNumber()]);
                       // plot.series[0].data = data;
                       
                       curr_time += 3600000;
                       line1.shift();
                       line1.push( [ curr_time, 100 + Math.floor(Math.random()* 100)] );
                       plot.series[0].data = line1;
                       
                        plot.resetAxesScale();
                        //if (dataIdx > 10)
                         //       plot.axes.xaxis.min = (data[0][0] - 1);

                        //$('#line').empty();
                        plot.replot();

                        setTimeout("updateData()", 1000);
        }; 
 // ------------------------------------------------------------------------------------
 	
   
 });
