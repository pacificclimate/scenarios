<div class="zoomable" id="<%rules_id%>">
  <div class="bg" onclick="hideImpact('<%category%>')"></div>
  <div class="zoomwin">
    <div class="closebutton" onclick="hideImpact('<%rules_id%>')">CLOSE&nbsp;<span>&times;</span></div>
    <div class="impactsrulestable">
      <h2>Rules</h2>
      <p>The table below lists a cleaned-up version of all of the rules. Quite a bit of shorthand is used; this is described here. If not otherwise specified, values are an interannual and spatial mean, and in the same units used on the maps (&deg;C for temperatures, mm per day for precipitation, etc.). Rules named in <strong>bold</strong> are true for the selected region and future time period.</p>

      <h3>Terminology</h3>
      <ul>
	<li>s0p/s50p/s100p = Minimum/median/maximum 0.5&deg; grid box value in the region.</li>
	<li>iastddev = <strong>I</strong>nter<strong>a</strong>nnual <strong>standard deviation</strong> of the monthly, seasonal, or annual mean.</li>
	<li>hist = CRU TS 2.1 historical baseline.</li>
	<li>e25p/e75p = GCM <strong>ensemble</strong> 25th/75th percentile.</li>
	<li>ann, djf, mam, jja, son = Annual, Dec/Jan/Feb, Mar/Apr/May, Jun/Jul/Aug, Sep/Oct/Nov.</li>
	<li>anom = Value is an anomaly (not a percentage) from the baseline (i.e. future minus historical).</li>
	<li>percent = Value is a percentage anomaly from the baseline.</li>
	<li>rule_&lt;rule-ID&gt; = A reference to another rule.</li>
	<li>region_oncoast = Whether the region is on the coast (0 for false, 1 for true).</li>
	<li>rule ? if_true : if_false = Checks whether a rule is true; if true, runs the clause represented by if_true; if false, runs the clause represented by if_false.</li>
      </ul>
      
      <br/><h3>Variables</h3>
      <table id="varstable">
	<tr class="dkerblue"><th>Variable</th><th>Description</th><th>Units</th></tr><tr class="varrow">
	  <td>temp</td>
	  <td>Mean Temperature</td>
	  <td>&deg;C</td>
	</tr>
	<tr>
	  <td>prec</td>
	  <td>Total precipitation</td>
	  <td>mm/day</td>
	</tr>
	<tr>
	  <td>pass</td>
	  <td>Snowfall</td>
	  <td>mm snow water equivalent</td>
	</tr>
	<tr>
	  <td>dg05</td>
	  <td>Growing DD (Degree-Days Above 5&deg;C)</td>
	  <td><a href="http://en.wikipedia.org/wiki/Degree_day">degree-days</a></td>
	</tr>
	<tr>
	  <td>dl18</td>
	  <td>Heating DD (Degree-Days Below 18&deg;C)</td>
	  <td><a href="http://en.wikipedia.org/wiki/Degree_day">degree-days</a></td>
	</tr>
	<tr>
	  <td>nffd</td>
	  <td>Number of Frost-Free Days</td>
	  <td>days</td>
	</tr>
      </table>

      <%rules_table%>
    </div>
  </div>
</div>
