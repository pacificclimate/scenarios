<div class="zoomable" id="<%rules_id%>">
  <div class="bg" onclick="hideImpact('<%category%>')"></div>
  <div class="zoomwin">
    <div class="closebutton" onclick="hideImpact('<%rules_id%>')">CLOSE&nbsp;<span>&times;</span></div>
    <div class="impactsrulestable">
      <h2 style="text-align: center;">Detailed Impacts Rules Logic</h2>
      <br/>
      <p>The table below shows all of the rules used to determine whether or not to display specific impacts and specific management implications in the impacts tab. This preliminary compilation of rules was developed based on a workshop attended by climate impacts experts and subsequent peer review. They are fairly technical and quite a bit of shorthand is used, as described under terminology below. Although quite comprehensive, the rules are a work in progress, and some key impacts or management implications may be missing. We welcome contributions and suggestions from users of Plan2Adapt.</p>
      <p>There are two types of rules: internal rules and impacts rules. The internal rules, listed first below, are used as part of the conditions in many other rules, with additional information given under the management implications column. The internal rule &quot;<span class="monospace">snow</span>&quot;, for example, is true if a region has locations with hydrological regimes that would be classified as snowfall-dominated based on the 1961-1990 climatology. This is determined by the condition of whether any 50km cells within the selected region have mean winter temperatures below -6&deg;C. The &quot;<span class="monospace">hybrid</span>&quot; and &quot;<span class="monospace">rain</span>&quot; rules are similar but for hybrid and rain-dominated classifications. Note that a region may have locations that meet multiple classifications. The &quot;<span class="monospace">future-...</span>&quot; internal rules make the same determination about the region in the selected future time period. </p>
      <p>The impacts rules display information directly in the Potential Impacts table, and are also sometimes used as part of conditions for other rules. Their IDs are classified by sector: For example, &quot;<span class="monospace">2a-iv-bio</span>&quot;, which comes under the general impact of <span class="italic">Reduced Water Supply</span>, has management implications that appear under the <span class="italic">Biodiversity</span> sector. The rule, which is about the effect of a decrease in moisture availability on habitat, displays based on the condition that at least one season has a decrease in precipitation according to at least 75% of the climate model projections (strong agreement) is met.</p>

      <h3>Terminology</h3>
      <ul>
	<li><span class="monospace">s0p</span>/<span class="monospace">s50p</span>/<span class="monospace">s100p</span> = <strong>Spatial</strong> minimum/median/maximum 0.5&deg; grid box value in the region.</li>
	<li><span class="monospace">iastddev</span> = <strong>I</strong>nter<strong>a</strong>nnual <strong>standard deviation</strong> of the monthly, seasonal, or annual mean.</li>
	<li><span class="monospace">hist</span> = CRU TS 2.1 1961-1990 historical baseline.</li>
	<li><span class="monospace">e25p</span>/<span class="monospace">e75p</span> = GCM <strong>ensemble</strong> 25th/75th percentile. This is always an interannual mean.</li>
	<li><span class="monospace">ann</span>, <span class="monospace">djf</span>, <span class="monospace">mam</span>, <span class="monospace">jja</span>, <span class="monospace">son</span> = Annual, Dec/Jan/Feb, Mar/Apr/May, Jun/Jul/Aug, Sep/Oct/Nov.</li>
	<li><span class="monospace">anom</span> = Value is an anomaly (not a percentage) from the baseline (i.e. future minus historical).</li>
	<li><span class="monospace">percent</span> = Value is a percentage anomaly from the baseline.</li>
	<li><span class="monospace">rule_&lt;rule-ID&gt;</span> = A reference to another rule.</li>
	<li><span class="monospace">region_oncoast</span> = Whether the region is on the coast.</li>
	<li><span class="monospace">rule ? if_true : if_false</span> = Checks whether a rule is true; if true, runs the clause represented by <span class="monospace">if_true</span>; if false, runs the clause represented by <span class="monospace">if_false</span>.</li>
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
      <p>If not otherwise specified, values are an interannual and spatial mean, and in the same units used on the maps (&deg;C for temperatures, mm per day for precipitation, etc.).</p>

      <%rules_table%>
    </div>
  </div>
</div>
