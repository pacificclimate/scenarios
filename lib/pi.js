var sidetabs = new Array('summary_tab', 'impacts_tab', 'temp_tab', 'prec_tab', 'pass_tab', 'dg05_tab', 'dl18_tab', 'nffd_tab', 'settings_tab', 'notes_tab', 'references_tab');

var tabhastoptabs = new Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
var toptabclasses = new Array('hidden', 'visible');
var toptabs = new Array('historical_toptab', 'future_toptab');

var panecontents = new Array('summary', 'summary',   // split/collapse this now that top tabs are deprecated?
			     'impacts','impacts',
                             'temp', 'temp',
                             'prec', 'prec', 
			     'pass', 'pass',
			     'dg05', 'dg05',
			     'dl18', 'dl18',
			     'nffd', 'nffd',
                             'settings', 'settings',
			     'notes', 'notes',
			     'references', 'references'/* both the same */ );


/* one line per unique panecontents id, for both thumbs and zoomed TODO does this get used anymore or just stuff in template? */
var thumbs = new Array(
'thm_temp_h_map', 'thm_temp_h_bar',
'thm_prec_h_map', 'thm_prec_h_bar',
'thm_pass_h_map', 'thm_pass_h_bar',
'thm_dg05_h_map', 'thm_dg05_h_bar',
'thm_dl18_h_map', 'thm_dl18_h_bar',
'thm_nffd_h_map', 'thm_nffd_h_bar'
);
var zoomed = new Array(
'zoom_temp_h_map', 'zoom_temp_h_bar',
'zoom_prec_h_map', 'zoom_prec_h_bar',
'zoom_pass_h_map', 'zoom_pass_h_bar',
'zoom_dg05_h_map', 'zoom_dg05_h_bar',
'zoom_dl18_h_map', 'zoom_dl18_h_bar',
'zoom_nffd_h_map', 'zoom_nffd_h_bar'
);
var bgs = new Array( /* these need replacing with a single bg */
'bg_temp_h_map', 'bg_temp_h_bar',
'bg_prec_h_map', 'bg_prec_h_bar',
'bg_pass_h_map', 'bg_pass_h_bar',
'bg_dg05_h_map', 'bg_dg05_h_bar',
'bg_dl18_h_map', 'bg_dl18_h_bar',
'bg_nffd_h_map', 'bg_nffd_h_bar'
);
var closebuttons = new Array(
'close_temp_h_map', 'close_temp_h_bar',
'close_prec_h_map', 'close_prec_h_bar',
'close_pass_h_map', 'close_pass_h_bar',
'close_dg05_h_map', 'close_dg05_h_bar',
'close_dl18_h_map', 'close_dl18_h_bar',
'close_nffd_h_map', 'close_nffd_h_bar'
);

/* these align with defaults in the HTML -- form state will clobber them, but they are here when vars are not set */
var seltab = 0;
var seltoptab = 0;
var selpane = 0;
var zoomedwindow = -1;

function doLoad() {
  setOnclicks(toptabs, clickTopTab);
  setOnclicks(sidetabs, clickSideTab);
  setOnclicks(thumbs, zoomImg);
  /*   setOnclicks(zoomed, hideImg);  replacing w/ BG + close button*/
    setOnclicks(bgs, hideImg); /* this needs to be a single element at some point... */
    setOnclicks(closebuttons, hideImg);
  detectExploder();
  detectPostageStamp();

  /*  document.getElementById('screenwidth').innerHTML = screen.availWidth;
      document.getElementById('screenheight').innerHTML = screen.availHeight; */
}

function makeCallback(func, i) {
    return function() { id = i; func(id); return false; };
}

function setOnclicks(idarray, func) {
    var i;
    for(i = 0; i < idarray.length; i++) {
	var elem = document.getElementById(idarray[i])
	if(elem) { elem.onclick = makeCallback(func, i); }
    }
}

function unsetAllOnclicks() {
    unsetOnclicks(toptabs);
    unsetOnclicks(sidetabs);
}

function unsetOnclicks(idarray) {  /* note that I also disable the "clicky" cursor */
    var i;
    for(i = 0; i < idarray.length; i++) {
        document.getElementById(idarray[i]).setAttribute("onclick", "");
        document.getElementById(idarray[i]).style.cursor = "auto";
    }
}

function loadSel(val) {  /* not used -- for stateful page reloads */
    selectTopTab(0 /* replace me */);
    selectSideTab(0 /* replace me */);
}

function clickSideTab(tab) {
    if (tab != seltab) {
	document.getElementById(sidetabs[seltab]).className = 'inactive';
	seltab = tab;
	document.getElementById(sidetabs[seltab]).className = 'active';
	document.getElementById('innertabs').className = toptabclasses[tabhastoptabs[seltab]];
	updateContentPane();
    }
}

function clickTopTab(toptab) {
    if (toptab != seltoptab) {
	document.getElementById(toptabs[seltoptab]).className = 'inactive';
	seltoptab = toptab;
	document.getElementById(toptabs[seltoptab]).className = 'active';
	updateContentPane();
    }
}

function updateContentPane() {
    if (panecontents[selpane] != panecontents[((seltab * 2) + seltoptab)] ) { /* redundant sanity check */
	document.getElementById(panecontents[selpane]).className = 'hidden';
	selpane = (seltab * 2) + seltoptab;
	if (thmimghtmlshown[selpane] != 1) { // dynamically-loaded thumbnails
	    showImages(selpane);
	    thmimghtmlshown[selpane] = 1;
	}
	document.getElementById(panecontents[selpane]).className = 'visible';
    }
}


function zoomImg(foo) {
    //    document.body.style.overflow = 'hidden';
    document.getElementById(zoomed[foo]).className = 'zoomed';
    zoomedwindow = foo;
    if (zoomimghtmlshown[foo] != 1) {
	zoomimghtmlshown[foo] = 1;
	document.getElementById(zoomimghtmlids[foo]).innerHTML = zoomimghtml[foo];
	if(foo % 2 == 0) {
	    var fut = ol_params[foo + 1];
	    var past = ol_params[foo];
	    var map1 = init_map(past[0], past[1], past[2], past[3], past[4], past[5], past[6], past[7]);
	    var map2 = init_map(fut[0], fut[1], fut[2], fut[3], fut[4], fut[5], fut[6], fut[7], fut[8], fut[9]);
	    // only add PanZoomBar & Scale controls to map 1 (don't need them in both maps)
	    map1.addControl(new OpenLayers.Control.PanZoomBar({position: new OpenLayers.Pixel(2, 15),
							       panIcons:false}));
	    map1.addControl(new OpenLayers.Control.ScaleLine());

	    
	    var switcher = new OpenLayers.Control.LayerSwitcher({'ascending':false});
	    switcher.onInputClick = function(e) {
		if (!this.inputElem.disabled) {
		    if (this.layer.baseLayer) {
			this.inputElem.checked = true;
			this.layer.map.setBaseLayer(this.layer);
		    } else {
			if(this.inputElem.checked) {
			    this.inputElem.checked = false;
			    for(i = 0; i < map2.layers.length; i++) {
				if(map2.layers[i].name == this.layer.name) {
				    map2.layers[i].setVisibility(this.inputElem.checked);
				}
			    }
			} else {
			    for(i = 0; i < this.layerSwitcher.dataLayers.length; i++) {
				this.layerSwitcher.dataLayers[i].inputElem.checked = false;
				this.layerSwitcher.dataLayers[i].layer.setVisibility(false);
			    }
			    this.inputElem.checked = true;
			    for(i = 0; i < map2.layers.length; i++) {
				if(map2.layers[i].displayInLayerSwitcher) {
				    map2.layers[i].setVisibility(false);
				}
				if(map2.layers[i].name == this.layer.name) {
				    map2.layers[i].setVisibility(this.inputElem.checked);
				}
			    }
			}
			this.layer.setVisibility(this.inputElem.checked);
		    }
		}
		OpenLayers.Event.stop(e);
	    };
	    map1.addControl(switcher);

	    var slider1 = new OpenLayers.Control.OpacitySlider({layerToOpacisize:map1.getLayersByName('ncwmsLayer')[0]});
	    map1.addControl(slider1);
	    // functions to Synchronize position and zoom of both maps
	    var c1, c2, z1, z2;
	    updatingMap1 = false,updatingMap2 = false;
	    map1.events.register("moveend", map1, function() {
		if(!updatingMap1){
		    c1 = this.getCenter();
		    z1 = this.getZoom();
		    updatingMap1 = true;
		    map2.panTo(c1);
		    map2.zoomTo(z1);
		    updatingMap1 = false;
		}
	    });
	    map2.events.register("moveend", map2, function() {
		if(!updatingMap2){
		    c1 = this.getCenter();
		    z1 = this.getZoom();
		    updatingMap2 = true;
		    map1.panTo(c1);
		    map1.zoomTo(z1);
		    updatingMap2 = false;
		}
	    });
	    // function to synchronize the popups
	    closeBoxCallback = function() {
		while(map1.popups.length) {
		    map1.removePopup(map1.popups[0]);
		}
		while(map2.popups.length) {
		    map2.removePopup(map2.popups[0]);
		}
	    }
	    popMap1 = false,popMap2 = false;
	    map1.events.register("click", map1, function(e) {
		if(!popMap1){
		    var popupLoc = this.getLonLatFromPixel(e.xy);
		    popMap1 = true;
		    getFeatureInfo(map1, popupLoc, e.xy, closeBoxCallback);
		    getFeatureInfo(map2, popupLoc, e.xy, closeBoxCallback, fut[13], fut[14]);
		    popMap1 = false;
		};
	    });
	    map2.events.register("click", map2, function(e) {
		if(!popMap2){
		    var popupLoc = this.getLonLatFromPixel(e.xy);
		    popMap2 = true;
		    wmsResponse = getFeatureInfo(map1, popupLoc, e.xy, closeBoxCallback)
                    getFeatureInfo(map2, popupLoc, e.xy, closeBoxCallback, fut[13], fut[14]);
		    popMap2 = false;
		}
	    });
	    // functions to synchronize the opacity slider in both maps
	    slider1.slider.bind('slide',function(event, ui){
		map2.getLayersByName('ncwmsLayer')[0].setOpacity(ui.value/100);
		$('div.legend svg image').css('opacity',ui.value/100)
	    });
	    try {
		draw_raphael_legend(past[8], past[5], past[9], past[10], past[11], past[12]);
	    } catch(e) { /* silently fail */ };
	    $('div.legend svg image').css('opacity',slider1.slider.slider('value')/100)
	}
    }
}


function zoomImpact(foo) {
    document.getElementById(foo).className = 'zoomed_impact';
    return false;
}

function hideImpact(foo) {
    document.getElementById(foo).className = 'zoomable';
    return false;
}

function hideImg(foo) {
    document.getElementById(zoomed[foo]).className = 'zoomable';
    //    document.body.style.overflowY = 'scroll';
    zoomedwindow = -1;
}

function hideDiv(c) {
    jQuery('#' + c).css('display', 'none');
}

function showDiv(c) {
    jQuery('#' + c).css('display', 'block');
}

function showImages(contentpaneindex) { // display all thumbs (FIXME and for now all zoomed images for a given )
    var imgdivids = thmimghtmlids[contentpaneindex].split(" ");
    var i;
    for (i = 0; i < imgdivids.length; i++) {
	document.getElementById(imgdivids[i]).innerHTML = thmimghtml[thmimghtmloffsets[contentpaneindex] + i];
    }
}

function printDebug(message) {
  document.getElementById('debug').innerHTML = message;
}

function setContent(id) {
  document.getElementById('boxcontent').innerHTML = content[id];
}

function keyPress(e) {
    // Esc
    if ((window.event) ? (event.keyCode == 27) : (e.keyCode == e.DOM_VK_ESCAPE)) { // MSIE : FF
	if (zoomedwindow >= 0) {
	    hideImg(zoomedwindow);
	}
    }

    return true;
}

function detectExploder() {
    if ((navigator.appName == 'Microsoft Internet Explorer') && (parseFloat(/MSIE ([0-9]{1,}[\.0-9]{0,})/.exec(navigator.userAgent)[1]) < 7.0)) {
	alert("This site is not compatible with versions of Internet Explorer prior to 7.0.");
    }
}

function detectPostageStamp() {
  if((screen.availWidth < 1000) || (screen.availHeight < 690)) {
    alert("Your screen resolution may result in a suboptimal viewing experience.");
  }
}

