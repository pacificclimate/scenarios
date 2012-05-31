<div id="<%symname%>" class="hidden">
  <div class="heading"><h1>Future <%uc_varname%> Projections</h1></div>
  <div class="contentcolumn">
    <div id="thm_<%symname%>_h_map" class="thumbdiv"></div>
    Click on the thumbnail at left to view high-resolution maps showing <strong><%toy%></strong> <%lc_varname%> for the <strong><%region%></strong> region for both the historical baseline (1961-1990) period and the <strong><%ts_period%></strong> period. An accompanying range plot shows how the results illustrated in the projected future map compare to a PCIC-standard set of Global Climate Model (GCM) projections (see 'Notes' tab for more information).
    <div class="zoomable" id="zoom_<%symname%>_h_map"><div class="bg" id="bg_<%symname%>_h_map"></div><div class="zoomwin">
      <div class="closebutton" id="close_<%symname%>_h_map">CLOSE&nbsp;<span>&times;</span></div>

      <h1 style="margin-top: -4px;"><%toy%> <%lc_varname%> for the <%region%> region.</h1>

      <table class="maptable"> 
	<tr><th style="width: 395px;"><h3>Historical</h3></th><th style="width: 395px;"><h3>Projected</h3></th><th style="width: 82px;"><h3>Range</h3></th></tr>
	<tr>
	  <td><div id="ol_<%symname%>_hist"></div></td><td><div id="ol_<%symname%>_future"></div></td>
	  <td rowspan="2"><div id="zoomimg_<%symname%>_h_map" class="zoomimg_map"></div></td>
	</tr>
	<tr><td colspan="2" style="text-align: center;"><div id="legend_<%symname%>" class="legend" height="75px" width="660px"></div></td></tr>
      </table>
      
      <p>The <span style="font-style: italic">Historical</span> map shows interpolated 1961-1990 station data. The <span style="font-style: italic">Projected</span> map shows how this picture will change by the <strong><%ts_period%></strong> period, based on a single GCM projection.</p>
      <p>The blue dot in the <span style="font-style: italic">Range</span> plot at far right shows how the mean change reflected in the <span style="font-style: italic">Projected</span> map compares to a PCIC-standard set of GCM projections. Use this to determine whether the projection used can be considered high or low relative to other projections in the set.</p>
      <p>Note: some variables do not come directly from the climate models (see 'Notes' tab for more information).</p>
    </div></div>
  </div>
  <div class="contentcolumn">
    <div id="thm_<%symname%>_h_bar" class="thumbdiv"></div>
    Click on the thumbnail at left to view a plot showing the range of projected change in <strong><%toy%></strong> <%lc_varname%> for the <strong><%region%></strong> region over three future periods (2020s, 2050s, and 2080s) according to a PCIC-standard set of Global Climate Model (GCM) projections (see 'Notes' tab for more information).
    <br /><br /> 
    The data used for the future projections are also available for <a href="<%scatter_link%>">download as a CSV (comma-separated values) file</a> that can be imported into a spreadsheet program.      
    <div class="zoomable" id="zoom_<%symname%>_h_bar"><div class="bg" id="bg_<%symname%>_h_bar"></div><div class="zoomwin">
      <div class="closebutton" id="close_<%symname%>_h_bar">CLOSE&nbsp;<span>&times;</span></div>
      <table>
        <tr><th><h3>Plot</h3></th><th><h3>Interpretation</h3></th></tr>
        <tr>
          <td><div id="zoomimg_<%symname%>_h_bar" class="zoomimg_scatter"></div></td>
          <td> 
            <p>This figure shows the range of projected <strong><%toy%></strong> <%lc_varname%> change (<%change_units%>), for the <strong><%region%></strong> region over three time periods (2020s, 2050s, and 2080s), according to a PCIC-standard set of GCM projections (see 'Notes' tab for more information). The range of change based on this set of projections is indicated as follows:</p> 
            <ul> 
              <li class="indent">The black line indicates the mid-point (median) in the set.</li> 
              <li class="indent">The blue line indicates the model used for display purposes (CGCM3 A2 run 4).</li> 
              <li class="indent">The dark grey shading shows the middle 50% (25<span class="superscript">th</span> to 75<span class="superscript">th</span> percentiles), representing half of the projections in the set.</li> 
              <li class="indent">The light grey shading shows the range according to 80% of the climate change projections used (10<span class="superscript">th</span> to 90<span class="superscript">th</span> percentiles).</li> 
            </ul> 
            <p>Note: some variables do not come directly from the climate models (see 'Notes' tab for more information).</p> 
          </td> 
	</tr>
      </table>
    </div></div>
  </div>
  <%caveat%>
</div>







