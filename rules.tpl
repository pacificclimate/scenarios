<div class="zoomable" id="<%rules_id%>">
  <div class="bg" onclick="hideImpact('<%category%>')"></div>
  <div class="zoomwin">
    <div class="closebutton" onclick="hideImpact('<%rules_id%>')">CLOSE&nbsp;<span>&times;</span></div>
    <div style="text-align: left; padding-left: 10px;">
      <h2>Rules</h2>
      <p>The table below lists a cleaned up version of all of the rules in use. Quite a bit of shorthand is used; this is described here. If not otherwise specified, fields are an interannual and spatial mean, and in standard units (degrees C for temperatures, mm/day for precipitation, etc). Rules highlighted in <strong>bold</strong> are true for the inputs selected.</p>

      <h3>Terminology</h3>
      <ul>
	<li>s0p/s50p/s100p = Minimum/median/maximum 0.5&deg; grid box value in the region.</li>
	<li>iastddev = Standard deviation of given month or period for years in time period.</li>
	<li>hist = CRU historical baseline.</li>
	<li>e25p/e75p = GCM ensemble 25th/75th percentile.</li>
	<li>ann, djf, mam, jja, son = Annual, Dec/Jan/Feb, Mar/Apr/May, Jun/Jul/Aug, Sep/Oct/Nov.</li>
	<li>anom = Value is an anomaly from the baseline (ie: future minus historical).</li>
	<li>percent = Value is a percentage anomaly from the baseline.</li>
	<li>rule_ = A reference to another rule.</li>
      </ul>

      <%rules_table%>
    </div>
  </div>
</div>
