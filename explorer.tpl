<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
   <meta http-equiv="Content-Type" content="text/html"/>
   <meta name="description" content="The Pacific Climate Impacts Consortium Regional Analysis Tool provides easy access to and tools to manipulate climate model data."/>
   <meta name="keywords" content="climate, long range, seasonal, prediction, weather, research, climate change, global warming, atmospheric, canada"/>

   <meta name="AUTHOR" content="David Bronaugh for the Pacific Climate Impacts Consortium"/>
   <meta name="COPYRIGHT" content="(C) Pacific Climate Impacts Consortium 2006"/>
   <meta name="RESOURCE-TYPE" content="DOCUMENT"/>
   <meta name="LANGUAGE" content="EN"/>
   <meta name="RATING" content="GENERAL"/>
   <meta name="REVISIT-AFTER" content="14 DAYS"/>
   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
   <link rel="stylesheet" href="css/scenaccess.css" type="text/css"/>
   <style type="text/css">
     
.footer{
        font-family: time;
        font-size: 12px;
}


#maps, #dregion {
  width: <%mapwidth%>px;
}
#data, #metadata, #datadisplay {
  width: <%scrnwidth_sidetabs%>px;
}
DIV.heading, DIV.update {
  width: <%scrnwidth%>px;
}

TD.column1, TD.column3 {
  width: <%txtcolumnwidth%>px;
}

TD.column2 {
  width: <%narrowdcol%>px;
}

TD.column4 {
  width: <%widedcol%>px;
}
   </style>
   <script type="text/javascript">
     <!--
	 var prevsel = <%tabno%>;
	 
	 var imghtml = new Array('<%regioncontent%>', '', '<%mapcontent%>', '<%differencemapcontent%>', '', '',  '<%boxplottscontent%>', '<%scattertscontent%>', '<%scattervarcontent%>');
	 
       -->
   </script>
   <script src="lib/explorer.js" type="text/javascript"></script>
   
   <title>PCIC Regional Analysis Tool (BETA)</title>
</head>
<body onload="doLoad();">
  <h1>PCIC Regional Analysis Tool (BETA): <a href="http://www.pacificclimate.org/tools/regionalanalysis/#Help">Help</a></h1>
  <%c_form:header%>
  <div class="heading">Data Options</div>
  <table border="0">
    <tr>
      <td class="column1">Experiment</td><td class="column2"><%c_form:expt%></td>
      <td class="column3">Variable</td><td class="column4"><%c_form:var%></td>
    </tr>
    <tr>
      <td class="column1">Timeslice</td><td class="column2"><%c_form:ts%></td>
      <td class="column3">Time of Year</td><td class="column4"><%c_form:toy%></td>
    </tr>
  </table>
  <div class="heading">Display Options</div>
  <table border="0">
    <tr>
      <td class="column1">Window</td><td class="column2"><%c_form:region%></td>
      <td class="column3">Region</td><td class="column4"><%c_form:pr%></td>
    </tr>
  </table>
  <div class="update"><%c_form:update%></div>
  
  <div class="heading">Plot Options</div>
  
  <table class="layout">
    <tr><td rowspan="2">
	<div class="sidetabs">
	  <div id="st_region" class="dkbluetab"><div class="hdr"></div>R<br/>e<br/>g<br/>i<br/>o<br/>n<div class="ftr"></div></div>
	  <div id="st_suggest" class="dkbluetab"><div class="hdr"></div>S<br/>u<br/>g<br/>g<br/>e<br/>s<br/>t<div class="ftr"></div></div>
	  <div id="st_maps" class="dkbluetab"><div class="hdr"></div>M<br/>a<br/>p<br/>s<div class="ftr"></div></div>
	  <div id="st_differencemaps" class="dkbluetab"><div class="hdr"></div>D<br/>i<br/>f<br/>f<br/>M<br/>a<br/>p<div class="ftr"></div></div>
	  <div id="st_metadata" class="dkbluetab"><div class="hdr"></div>M<br/>e<br/>t<br/>a<br/>d<br/>a<br/>t<br/>a<div class="ftr"></div></div>
	  <div id="st_files" class="dkbluetab"><div class="hdr"></div>F<br/>i<br/>l<br/>e<br/>s<div class="ftr"></div></div>
	  <div id="bp_timeslice" class="dkbluetab"><div class="hdr"></div>B<br/>o<br/>x<br/>p<br/>l<br/>o<br/>t<div class="ftr"></div></div>
	  <div id="st_timeslice" class="dkbluetab"><div class="hdr"></div>T<br/>i<br/>m<br/>e<br/>s<br/>l<br/>i<br/>c<br/>e<div class="ftr"></div></div>
	  <div id="st_variable" class="dkbluetab"><div class="hdr"></div>V<br/>a<br/>r<br/>i<br/>a<br/>b<br/>l<br/>e<div class="ftr"></div></div>
	</div>
      </td>
      <td>
	<div class="tabs">
	  <div id="regiontab" class="dkbluetab">Region</div>
	  <div id="mapstab" class="dkbluetab">Maps</div>
	  <div id="datatab" class="dkbluetab">Data</div>
	  <div id="scatterplotstab" class="dkbluetab">Scatter Plots</div>
	</div>
    </td></tr>
    <tr><td class="display">
	<div id="datadisplay">
	  <div id="regioncontents"></div>
	  <div id="dregion">
	    <div class="controls">
	      <div class="heading">Map Ops</div><%c_form:op%><br/><br/><%c_form:bop%><br/>
	      <div class="heading">Mask options</div><%c_form:ocean%> Include ocean<br/>
	      <div class="heading">Region</div>Threshold: <%c_form:th%><br/>
	      Fringe size: <%c_form:fringe_size%><br/>
	    </div>
	    <br/>
	    <span id="regionimgs"></span>
          </div>
	  
	  <div id="suggest">
	    <p><%suggestresult%></p>
	    <p>
	      Name: <%c_form:p_name%><br/>
	      Email: <%c_form:p_email%><br/>
	      <br/>
	      Region name: <br/>
	      <%c_form:r_name%><br/>
	      <br/>
	      <%c_form:suggest%>
	    </p>
	  </div>
	  
	  <div id="mapscontents"></div>
	  <div id="maps">
	    <div class="controls">
	      <div class="heading">Map Range</div><%c_form:rt%><br/><%c_form:r_min%> to <%c_form:r_max%><br/>
	      <div class="heading">Options</div><%c_form:grid%> Show Grid<br/>
	      <div class="heading">Map Size</div><%c_form:res%><br/>
	      <!--<br/><%c_form:update%>-->
	    </div>
	    <span id="mapimgs"></span><br style="clear: both"/>
	  </div>
	  
	  <div id="differencemaps">
	    Difference Experiment: <%c_form:expt_d%><br/>
	    Difference Timeslice: <%c_form:ts_d%> | Difference Time of Year: <%c_form:toy_d%>
	    <br/><br/>
	    <span id="differencemapimgs"></span><br style="clear: both"/>
	  </div>
	  
	  <div id="datacontents"></div>
	  <div id="data">
	    <%modeldatatable%><br/>
	    <%datatable%>
	  </div>
	  
	  <div id="metadata">
	    <%modelmetadatatable%><br/>
	    <%metadatatable%>
	    <hr class="wide"/>Decimal Places: <%c_form:numdatdec%>, <%c_form:md_pctile%> Percentile Calculations 
	    <!--<div class="update"><%c_form:update%></div>-->
	    <br/><%md_csvlink%>
	  </div>
	  <div id="scatterplotscontents">
	  </div>

	  <div id="boxplotts">
	    <%c_form:spbpdata%> Display data
	    <br/>
	    <span id="boxplottsimgs"></span>
	    <br/><%boxplottstext%>
	  </div>
	  
	  <div id="scatterts">
	    <%c_form:sptsdata%> Display data | <%c_form:pctile%> Weighted percentiles<br/>
	    <hr/>
	    <br/>
	    <span id="scattertsimgs"></span>
	    <br/><%scattertstext%>
	  </div>
	  
	  <div id="scattervar">
	    <%c_form:spvardata%> Display data | X axis variable: <%c_form:var2%>
	    <hr/>
	    <br/>
	    <span id="scattervarimgs"></span>
	    <br/><%scattervartext%>
	  </div>
	  
	  <%c_form:c_submit%><br/>
	  <%c_form:oldregion%>
	  <%c_form:oldvar%>
	  <%c_form:oldres%>
	  <%c_form:oldexpt%>
	  <%c_form:oldts%>
	  <%c_form:oldpr%>
	  <%c_form:points%>
	  <%c_form:dpoint%>
	  <%c_form:seltab%>
	  <%c_form:view_x%>
	  <%c_form:view_y%>
	  <%c_form:zoom%>
	</div>
      </td>
    </tr>
  </table>
  
  <%c_form:footer%>
</body>

</html>

