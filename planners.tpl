<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
   <meta name="description" content="The Pacific Climate Impacts Consortium Regional Analysis Tool provides easy access to and tools to manipulate climate model data."/>
   <meta name="keywords" content="climate, long range, seasonal, prediction, weather, research, climate change, global warming, atmospheric, canada"/>
   <meta name="AUTHOR" content="Paul Nienaber for the Pacific Climate Impacts Consortium"/>
   <meta name="COPYRIGHT" content="(C) Pacific Climate Impacts Consortium 2006"/>
   <meta name="RESOURCE-TYPE" content="DOCUMENT"/>
   <meta name="LANGUAGE" content="EN"/>
   <meta name="RATING" content="GENERAL"/>
   <meta name="REVISIT-AFTER" content="14 DAYS"/>

   <link rel="stylesheet" type="text/css" href="/tools/pi.css" />
   <script src="/tools/pi.js" type="text/javascript"></script>

   <script type="text/javascript">
<!--

/* one of each these per content div, aka two per tab ATM, WARNING note that all of these use the same offset right now */
var thmimghtmloffsets = new Array(123,123, 123,123,                                 0,123, 0,123, 0,123, 0,123, 0,123, 0,123, 123,123, 123,123, 123,123); /* offsets into thmimghtml */
var thmimghtmlids = new Array(     '','',   '','',  'thm_temp_h_map thm_temp_h_bar','',   'thm_prec_h_map thm_prec_h_bar','',   'thm_pass_h_map thm_pass_h_bar','', 'thm_dg05_h_map thm_dg05_h_bar','', 'thm_dl18_h_map thm_dl18_h_bar','', 'thm_nffd_h_map thm_nffd_h_bar','',   '','', '','', '','');
var thmimghtmlshown = new Array(1,1, 1,1, 0,1, 0,1, 0,1, 0,1, 0,1, 0,1, /*1,1,*/ 1,1, 1,1, 1,1);
/* and the actual array of markup - - TODO these should have sizes - - TODO these should be dynamic perhaps, or not? */
var thmimghtml = new Array('<img src="/~phox/pi_demo/thumb_map2.png" alt="" />', '<img src="/~phox/pi_demo/thumb_graph.png" alt="" />', 
                           '<img src="/~phox/pi_demo/thumb_map2.png" alt="" />', '<img src="/~phox/pi_demo/thumb_graph.png" alt="" />', 
                           '<img src="/~phox/pi_demo/thumb_map2.png" alt="" />', '<img src="/~phox/pi_demo/thumb_graph.png" alt="" />');
/* one of each these for every zoomed image div - - should probably be as many elements as there are in thmimghtml - -  FIXME is this going to stay as singles or become blocks like thumbs? */
var zoomimghtmlids = new Array('zoomimg_temp_h_map','zoomimg_temp_h_bar',
                               'zoomimg_prec_h_map','zoomimg_prec_h_bar',
                               'zoomimg_pass_h_map','zoomimg_pass_h_bar',
                               'zoomimg_dg05_h_map','zoomimg_dg05_h_bar',
                               'zoomimg_dl18_h_map','zoomimg_dl18_h_bar',
                               'zoomimg_nffd_h_map','zoomimg_nffd_h_bar'
);
var zoomimghtmlshown = new Array(0,0,                                       0,0, 0,0, 0,0, 0,0);
var zoomimghtml = new Array(<%planners_content%>); /* TODO sizes */

-->
   </script>

   
   <title>Pacific Climate Impacts Consortium Plan2Adapt ALPHA</title>
</head>

<body onload="doLoad();" onkeydown="keyPress(event)">


  <div id="centre">
    <div id="title-left"><a href="http://www.pacificclimate.org/"><img src="/~phox/pi_demo/pcic_logo.png" alt="Pacific Climate Impacts Consortium" /></a></div>
    <div id="title-right"><a href="http://www.plan2adapt.ca/"><img src="/~phox/pi_demo/p2a.png" alt="Plan2Adapt" /></a></div>

    <div id="navbarcontainer">
      <ul id="navbar">
        <li><a href="http://www.pacificclimate.org/aboutus/contactus/">Contact Us</a></li><li>|</li>
        <li><a href="http://www.pacificclimate.org/">PCIC Home</a></li><li>|</li>
        <li><a href="http://www.plan2adapt.ca/">Home</a></li>
      </ul>
    </div>

    <div id="mainbox">

      <div id="sidetabs">
        <ul>
          <li id="summary_tab" class="active">Summary</li>
          <li id="impacts_tab" class="inactive">Impacts</li>
          <li id="temp_tab" class="inactive">Temperature</li>
          <li id="prec_tab" class="inactive">Precipitation</li>
          <li id="pass_tab" class="inactive">Snowfall</li>
          <li id="dg05_tab" class="inactive">Growing DD</li>
          <li id="dl18_tab" class="inactive">Heating DD</li>
          <li id="nffd_tab" class="inactive">Frost-Free Days</li>
          <!--        <li id="dg05_tab" class="inactive">GDD</li>  -->
          <li id="settings_tab" class="inactive">Settings</li>
          <li id="notes_tab" class="inactive">Notes</li>
          <li id="references_tab" class="inactive">References</li>
        </ul>
      </div>

      <div id="tabbedbox">

        <div id="innertabs" class="hidden">
          <div id="historical_toptab" class="active">Historical</div>
          <div id="future_toptab" class="inactive">Future</div>
        </div>

        <%c_form:header%>

        <div id="content">

          <div id="summary" class="visible"><div>
              <div class="heading"><h1>Summary of Climate Variables</h1></div>
              <div class="summary">
                <table>
                  <tr class="dkerblue"><th colspan="4">Climate Change for <%var:region%> Region in <%var:ts_period%> Period</th></tr>
                  <!--              <tr class="dkblue"><th>Climate Variable</th><th>Time of Year</th><th>Future Change for <%var:ts%></th></tr> -->

                  <tr class="dkblue"><th rowspan="2">Climate Variable</th><th rowspan="2">Time of Year</th><th colspan="2">Projected Change<br/>from 1961-1990 Baseline</th></tr>
                  <tr class="dkblue"><th>Ensemble Median</th><th>Range</th></tr>

                  <tr class="ltblue">
                    <td>Mean Temperature (&deg;C)</td>
                    <td>Annual<!--<br /><br />Summer<br /><br />Winter--></td>
                    <td><%data:ann_temp_50p%> &deg;C<!--<br /><br /><%data:jja_temp_50p%> &deg;C<br /><br /><%data:djf_temp_50p%> &deg;C--></td>
                    <td><%data:ann_temp_10p%> &deg;C to <%data:ann_temp_90p%> &deg;C<!--<br /><br /><%data:jja_temp_10p%> &deg;C to <%data:jja_temp_90p%> &deg;C<br /><br /><%data:djf_temp_10p%> &deg;C to <%data:djf_temp_90p%> &deg;C--></td>
                  </tr>
                  <tr>
                    <td>Precipitation (%)</td>
                    <td>Annual<br /><br />Summer<br /><br />Winter</td>
                    <td><%data:ann_prec_50p%>%<br /><br /><%data:jja_prec_50p%>%<br /><br /><%data:djf_prec_50p%>%</td>
                    <td><%data:ann_prec_10p%>% to <%data:ann_prec_90p%>%<br /><br /><%data:jja_prec_10p%>% to <%data:jja_prec_90p%>%<br /><br /><%data:djf_prec_10p%>% to <%data:djf_prec_90p%>%</td>
                  </tr>
                  <tr class="ltblue">
                    <td>Snowfall* (%)</td>
                    <td><!--Annual<br /><br />-->Winter<br /><br />Spring</td>
                    <td><!--<%data:ann_pass_50p%>%<br /><br />--><%data:djf_pass_50p%>%<br /><br /><%data:mam_pass_50p%>%</td>
                    <td><!--<%data:ann_pass_10p%>% to <%data:ann_pass_90p%>%<br /><br />--><%data:djf_pass_10p%>% to <%data:djf_pass_90p%>%<br /><br /><%data:mam_pass_10p%>% to <%data:mam_pass_90p%>%</td>
                  </tr>
                  <tr>
                    <td>Growing Degree Days* (degree days)</td>
                    <td>Annual</td>
                    <td><%data:ann_dg05_50p%> degree days</td>
                    <td><%data:ann_dg05_10p%> to <%data:ann_dg05_90p%> degree days</td>
                  </tr>
                  <tr class="ltblue">
                    <td>Heating Degree Days* (degree days)</td>
                    <td>Annual</td>
                    <td><%data:ann_dl18_50p%> degree days</td>
                    <td><%data:ann_dl18_10p%> to <%data:ann_dl18_90p%> degree days</td>
                  </tr>
                  <tr>
                    <td>Frost-Free Days* (days)</td>
                    <td>Annual</td>
                    <td><%data:ann_nffd_50p%> days</td>
                    <td><%data:ann_nffd_10p%> to <%data:ann_nffd_90p%> days</td>
                  </tr>
                </table> 
                <!--            <table><%planners_variable_table%></table>  -->
                <p>The table above shows projected changes in average (mean) temperature, precipitation and several derived climate variables from the baseline historical period (1961-1990) to the <strong><%var:ts_period%></strong> for the <strong><%var:region%></strong> region. The ensemble median is a mid-point value, chosen from a PCIC standard set of Global Climate Model (GCM) projections (see the 'Notes' tab for more information). The range values represent the lowest and highest results within the set. Please note that this summary table does not reflect the 'time of year' choice made under the 'Settings' tab. However, this setting does affect results obtained under each variable tab.</p>
                <br />
                <p>* These values are derived from temperature and precipitation. Please select the appropriate variable tab for more information.</p>
                <!--            <a href="#">Download CSV</a> -->
              </div>
          </div></div>
          
          <div id="impacts" class="hidden"><div>
              <div class="heading"><h1>Summary of Potential Impacts</h1></div>
              <div class="summary">
                <%planners_summary_table%>
                <p><span class="warningtext">Warning: DO NOT USE OR REPRODUCE THE CONTENTS OF THIS TABLE. The current table is created using rules to relate projected climate change to impacts. The thresholds and rules are arbitrary. This table is for demonstration purposes only and will be replaced by new rules developed through a more rigorous process involving climate science experts.</span></p>
                <br />
                <p>The table above shows potential impacts resulting from climate change for the <strong><%var:region%></strong> region by the <strong><%var:ts_period%></strong> period. It is important to note that these are <strong>potential</strong> impacts only, based on the amount of projected climate change. An appropriate regional adaptation expert should be consulted prior to making use of this information in order to further determine its local relevance and completeness.</p>
          </div>
          </div></div>
          

          <%planners_vardivs%>

          
          <div id="settings" class="hidden">
            <div class="heading"><h1>Settings</h1></div>
            
            <table border="0" width="400px">
              <tr>
                
                <td valign="top"> 
                  <h3>Regional District <span class="navigationsub"> </span></h3> 
                  <div style="padding: 10px 0px 18px 10px;">
                    <%c_form:pr%>
                  </div>
                </td>
                
                <td valign="top"> 
                </td>
                
              </tr>
              <tr>
                
                <td valign="top"> 
                  <h3>Time Period</h3> 
                  <div style="padding: 10px 0px 18px 10px;">
                    <%c_form:ts%>
                  </div>
                </td>
                
                <td valign="top"> 
                  <h3>Time of Year</h3> 
                  <!-- FIXME this should be using c_form but at present that doesn't get us radio buttons -->
                  <div style="padding: 10px 0px 18px 10px;">
                    <%c_form:toy%>
                  </div>
                </td>
                
              </tr>
            </table>
            
            
            <div class="update" style="margin: 18px 0px 0px 12px;"><%c_form:update%></div>
            
            <%c_form:c_submit%><br/>
            
            <%c_form:oldregion%>  <%c_form:oldvar%>  <%c_form:oldres%>  <%c_form:oldexpt%>  <%c_form:oldts%>  <%c_form:oldpr%>  <%c_form:points%>  <%c_form:dpoint%>  <%c_form:seltab%>
            <div style="display: none;">
              <%c_form:fringe_size%>  <%c_form:view_x%>  <%c_form:view_y%>  <%c_form:th%>  <%c_form:zoom%>  <!-- FIXME make these hidden and remove this div -->
            </div>
	      </div> <!-- end settings pane -->
          
          <div id="notes" class="hidden"><!-- <div> what? -->
            <div class="heading"><h1>Notes</h1></div>
            <ol>
          <li>Multiple projections information is drawn from a set of 30 GCM projections based on results from 15 different Global Climate Models (GCMs), each using one run of a high (A2) and a lower (B1) greenhouse gas emissions scenario. By the end of the 21<span class="superscript">st</span> century, these scenarios anticipate an atmospheric concentration of greenhouse gases of approximately 1250 ppm (A2) and 600 ppm (B1), expressed as carbon dioxide (CO<span class="subscript">2</span>) equivalent. Neither scenario incorporates the effects of international agreements on the reduction of greenhouse gas emissions, though other socio-economic factors like population growth are modelled. Each GCM comes from a different modelling centre (e.g. the Hadley Centre (UK), National Centre for Atmospheric Research (USA), Geophysical Fluid Dynamics Laboratory (USA), and Commonwealth Scientific and Industrial Research Organisation (Australia), etc.).</li>
          <li>The single projection used for the maps is the CGCM3 A2 run 4. CGCM3 is the Canadian Global Climate Model, developed and run by Environment Canada's Canadian Centre for Climate Modelling and Analysis at the University of Victoria. The A2 specification denotes a possible future where emissions continue to rise alongside increases in human population and economic growth. A2 is one emissions scenario amongst several developed by the Intergovernmental Panel on Climate Change (IPCC) and published in its Special Report on Emissions Scenarios (SRES) (see 'References' tab).</li>
	      <li>High-resolution climate data is obtained by using the ClimateBC empirical downscaling tool. ClimateBC uses interpolation, an elevation correction on temperature, and the PRISM (Parameter-elevation Regressions on Independent Slopes Model) 4 km high-resolution climatology derived from a multiple regression of weather station data against topographical features. This projected change from Global Climate Models (GCMs) is applied to the high resolution past in order to obtain an estimate of future climate at the same high resolution.</li>
	      <li>The 2020s, 2050s, and 2080s time periods are meant to be used as three representative planning horizons over the 21<span class="superscript">st</span> century. Results for these three planning horizons are computed by averaging GCM projections over the 2010-2039, 2040-2069, and 2070-2099 periods, respectively.</li>
	      <li>With the exception of temperature and precipitation, most variable values shown here are not directly observed or obtained from the GCMs. Instead, they are derived from temperature and/or precipitation using methods described in Wang et al., 2006 (see 'References' tab).</li>
	    </ol>
	    <div class="heading"><h1>Acknowledgements</h1></div>
	    <p>Development of this tool has been made possible through funding and support provided by the BC Ministry of Environment and the BC Ministry of Forests and Range Forest Science Program and is a project of Natural Resources Canada's British Columbia Regional Adaptation Collaborative.</p>
	    
	  </div>
	  
	  <div id="references" class="hidden"><!-- <div> what? -->
	    <div class="heading"><h1>References</h1></div>
	    
	    <p>British Columbia Ministry of Water, Land and Air Protection. 2002. <em>Indicators of Climate Change for British Columbia 2002</em>. Victoria, BC. 48 pp.</p>
	    <br />
	    
	    <p>Cohen, Stewart. 2009. <em>Climate Change in the 21st Century - Understanding the World's Biggest Crisis</em>. McGill-Queen's University Press. 379 pp.</p>
	    <br />
	    
	    <p>Daly, C., W.P. Gibson, G.H. Taylor, G.L. Johnson, and P. Pasteris. 2002. "A knowledge-based approach to the statistical mapping of climate", <em>Climate Research</em>, 22: 99-113. Details the PRISM 4km climatology.</p>
	    <br />

        <p>Intergovernmental Panel on Climate Change. 2000. <em>Special Report on Emissions Scenarios</em>. Cambridge University Press. 570 pp. <a href="http://www.ipcc.ch/ipccreports/sres/emission/index.htm">http://www.ipcc.ch/ipccreports/sres/emission/index.htm</a></p>
        <br />
	    
	    <p>Rodenhuis, D.R., Bennett, K.E., Werner, A.T., Murdock, T.Q., Bronaugh, D. Revised 2009. <em>Hydro-climatology and future climate impacts in British Columbia</em>. Pacific Climate Impacts Consortium, University of Victoria, Victoria BC, 132 pp. Provides additional information on future climate projects in British Columbia.</p>
	    <br />
	    
	    <p>Wang, T.L., Hamann, A., Spittlehouse, D.L. and Aitken, S.N., 2006. "Development of scale-free climate data for Western Canada for use in resource management", <em>International Journal of Climatology</em>, 26: 383-397. Details the ClimateBC empirical downscaling tool.</p>
	    <br />
	    
	    <!-- </div> /what? -->
	  </div> <!-- end References tab -->
	  
	</div> <!-- end content div -->
	
	<%c_form:footer%>
	
      </div> <!-- end tabbed box -->
      
    </div>
    
    <div id="footer">
      &copy; 2010 Pacific Climate Impacts Consortium
    </div>
    
  </div> <!-- end centre -->
  
<div style="z-index: 50;" id="whiteout" class="hidden"><!-- put centered div here --></div>  


</body>
</html>

