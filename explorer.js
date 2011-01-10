var tabs = new Array('regiontab', 'mapstab', 'datatab', 'scatterplotstab');
var tabcontents = new Array('regioncontents', 'mapscontents', 'datacontents', 'scatterplotscontents');

var tabset = new Array(0, 0, 1, 1, 2, 2, 3, 3, 3);
var taboffset = new Array(0, 2, 4, 6);
var numsidetabs = new Array(2, 2, 2, 3);
var sidetabset = new Array(0, 1, 0, 1, 0, 1, 0, 1, 2);
var sidetabs = new Array('st_region', 'st_suggest', 'st_maps', 'st_differencemaps', 'st_metadata', 'st_files', 'bp_timeslice', 'st_timeslice', 'st_variable');
var contents = new Array('dregion', 'suggest', 'maps', 'differencemaps', 'metadata', 'data', 'boxplotts', 'scatterts', 'scattervar');

var hiddenimgs = new Array('regionimgs', '', 'mapimgs', 'differencemapimgs', '', '', 'boxplottsimgs', 'scattertsimgs', 'scattervarimgs');
var hidden_shown = new Array(0, 1, 0, 0, 1, 1, 0, 0, 0);

var oldtabs = new Array(0, 0, 0, 0);

var active_tab_colour = "#636584";
var active_tab_image = "/tools/tabtop-ltblue.png";
var inactive_tab_colour = "#150f3c";
var inactive_tab_image = "/tools/tabtop-dkblue.png";

function doLoad() {
  document.getElementById(tabs[0]).onclick = function() { selectTab(0); };
  document.getElementById(tabs[1]).onclick = function() { selectTab(1); };
  document.getElementById(tabs[2]).onclick = function() { selectTab(2); };
  document.getElementById(tabs[3]).onclick = function() { selectTab(3); };

  document.getElementById(sidetabs[0]).onclick = function() { selectSideTab(0); };
  document.getElementById(sidetabs[1]).onclick = function() { selectSideTab(1); };
  document.getElementById(sidetabs[2]).onclick = function() { selectSideTab(2); };
  document.getElementById(sidetabs[3]).onclick = function() { selectSideTab(3); };
  document.getElementById(sidetabs[4]).onclick = function() { selectSideTab(4); };
  document.getElementById(sidetabs[5]).onclick = function() { selectSideTab(5); };
  document.getElementById(sidetabs[6]).onclick = function() { selectSideTab(6); };
  document.getElementById(sidetabs[7]).onclick = function() { selectSideTab(7); };
  document.getElementById(sidetabs[8]).onclick = function() { selectSideTab(8); };

  loadSel(document.getElementById('c_form').seltab.value);
}

function loadSel(val) {
  oldtabs[taboffset[val]] = sidetabset[val];
  showTab(tabset[val]);
  showSideTab(val);
}

function selectSideTab(tab) {
  prevsel = document.getElementById('c_form').seltab.value;
  if(tab != prevsel) {
    hideSideTab(prevsel);
    showSideTab(tab);
    prevsel = tab;
    oldtabs[tabset[tab]] = sidetabset[tab];
  }
  document.getElementById('c_form').seltab.value = prevsel;
}

function selectTab(tab) {
  prevsel = document.getElementById('c_form').seltab.value;
  cursel = taboffset[tab] + oldtabs[tab];
  if(cursel != prevsel) {
    hideSideTab(prevsel);
    hideTab(tabset[prevsel]);
    showTab(tab);
    showSideTab(cursel);
    prevsel = cursel;
  }
  document.getElementById('c_form').seltab.value = prevsel;
}

function showSideTab(tab) {
  if(hidden_shown[tab] == 0) {
    myspan = document.getElementById(hiddenimgs[tab]);
    myspan.innerHTML = imghtml[tab];
    hidden_shown[tab] = 1;
  }
  document.getElementById(sidetabs[tab]).style.color = '#ffffff';
  document.getElementById(contents[tab]).style.display = 'inline';
  document.getElementById(sidetabs[tab]).style.backgroundColor = active_tab_colour;
}

function hideSideTab(tab) {
  document.getElementById(sidetabs[tab]).style.color = '#b0b0b0';
  document.getElementById(contents[tab]).style.display = 'none';
  document.getElementById(sidetabs[tab]).style.backgroundColor = inactive_tab_colour;
}

function showTab(tab) {
  document.getElementById(tabcontents[tab]).style.display = 'inline';
  document.getElementById(tabs[tab]).style.color = '#ffffff';
  document.getElementById(tabs[tab]).style.background = active_tab_colour + " url(" + active_tab_image + ") top center no-repeat";
  document.getElementById(tabs[tab]).style.height = "21px";

  for(var i = 0; i < numsidetabs[tab]; i++) {
    document.getElementById(sidetabs[taboffset[tab] + i]).style.display = 'block';
  }
}

function hideTab(tab) {
  document.getElementById(tabcontents[tab]).style.display = 'none';
  document.getElementById(tabs[tab]).style.color = '#b0b0b0';
  document.getElementById(tabs[tab]).style.background = inactive_tab_colour + " url(" + inactive_tab_image + ") top center no-repeat";
  document.getElementById(tabs[tab]).style.height = "20px";;

  for(var i = 0; i < numsidetabs[tab]; i++) {
    document.getElementById(sidetabs[taboffset[tab] + i]).style.display = 'none';
  }
}

function printDebug(message) {
  document.getElementById('debug').innerHTML = message;
}

function setContent(id) {
  document.getElementById('boxcontent').innerHTML = content[id];
}

