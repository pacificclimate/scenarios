var P4326 = new OpenLayers.Projection("EPSG:4326");
var P3005 = new OpenLayers.Projection("EPSG:3005");
var popup = null;
var tempPopup = null;

//OpenLayers.DOTS_PER_INCH = 25.4 / 0.28;
function init_map(map_id, region, climate_overlay, climate_time, color_range, color_scale, center_point, zoom_level, min_range, max_range) {
    var P4326 = new OpenLayers.Projection("EPSG:4326");
    var P3005 = new OpenLayers.Projection("EPSG:3005");
    var maxBounds = new OpenLayers.Bounds(
	//minX, minY, maxX, maxY
	//270000,330000,1874400,1736400
	//258531.0,329419.5,1886910.0,1735948.5
	-236114,41654.75,2204236,1947346.25
    );

    var controlOptions = {
        maximized: false,
        size: new OpenLayers.Size(200,170),
	autoPan: false,
	mapOptions: {numZoomLevels: 2}
    };
    
    var options = {
        controls: [
	    new OpenLayers.Control.Navigation({zoomWheelEnabled : false})],
        maxExtent: maxBounds,
        displayProjection: P4326,
        maxResolution: 4437,
        resolutions: [4437, 2218.5, 1109.25,554.625,277.3125,138.6562,69.32812],
        projection: "EPSG:3005",
        units: 'm'
    }; 

    var map = new OpenLayers.Map(map_id, options);
	 
    params = {
        layers: climate_overlay,
        elevation: 0,
        time: climate_time,
        transparent: 'true',
        styles: "boxfill/" + color_scale, 
        colorscalerange: color_range, 
        numcolorbands: 254,
        logscale: false,
        format: 'image/png',
        version: '1.1.1',
        srs: 'EPSG:4326'
    };
    ncwms =  new OpenLayers.Layer.WMS("ncwmsLayer",
                                      "/ncWMS/wms?",
                                      params,
                                      {buffer: 1, ratio: 1.5, 
				       singleTile: false, wrapDateLine: true, visibility:true, opacity: 0.7, displayInLayerSwitcher: false}
                                     );
    
    osm_mq = new OpenLayers.Layer.WMS(
	"OpenStreetMap", 
	"/geoserver/gwc/service/wms",
	{LAYERS: 'osm_pnwa_p2a_gwc',
	 tiled: true,
	 tilesOrigin : map.maxExtent.left + ',' + map.maxExtent.bottom,// this is the origin for all the grid:3005 (not the grid subset)
	 'transparent' : true},
	{isBaseLayer:true, displayOutsideMaxExtent: true, displayInLayerSwitcher: false});
    
    
    map.addLayers([osm_mq, ncwms]);
    var filter_1_1 = new OpenLayers.Format.Filter({version: "1.1.0"});
    var xml = new OpenLayers.Format.XML();
    filter_region = new OpenLayers.Filter.Logical({
	type: OpenLayers.Filter.Logical.AND,
	filters: [
            new OpenLayers.Filter.Comparison({
		type: OpenLayers.Filter.Comparison.LIKE,
		property: "name",
		value: region
            })
	]});
    filter_region_xml = xml.write(filter_1_1.write(filter_region));
    
    function addWMSLayer(layerSwitcherName, layerName, url, layerSwitcherDisplay, myFilter, myVis, myOpacity, myTiled, myTiledOrigin)
    {
        if (url == null) url="/geoserver/p2a/wms";
        if (layerSwitcherDisplay == null) layerSwitcherDisplay= true ;
        if (myFilter == null) myFilter='';
        if (myVis == null) myVis= false ;
        if (myOpacity == null) myOpacity=1.0;
	if (myTiled == null) myTiled=false;
        myLayer = new OpenLayers.Layer.WMS(
            layerSwitcherName, url,
            {
		LAYERS: layerName,
		format: 'image/png',
		projection: P3005,
		filter: myFilter,
		'transparent': true,
		tiled: myTiled,
		tilesOrigin: myTiledOrigin},
            {'opacity':myOpacity, 'isBaseLayer': false, 'visibility': myVis, displayOutsideMaxExtent: true, displayInLayerSwitcher: layerSwitcherDisplay});
	map.addLayer(myLayer);
    };
    addWMSLayer("Municipalities", 'p2a:municipalities');
    addWMSLayer("Glaciers", 'cwb_glaciers_gwc', "/geoserver/gwc/service/wms", null, null, null, null, true,  map.maxExtent.left + ',' + map.maxExtent.bottom);
    addWMSLayer("Tree Farm Licenses", 'p2a:fadm_tfl');
    addWMSLayer("Parks", 'p2a:bc_parks');
    addWMSLayer("Timber Supply Areas", 'p2a:fadm_tsa');
    addWMSLayer("Forestry Districts", 'p2a:fadm_dist');
    addWMSLayer("Land Cover", 'btmv1_landuse_gwc', "/geoserver/gwc/service/wms", null, null, null, null, true,  map.maxExtent.left + ',' + map.maxExtent.bottom);
    addWMSLayer("Biogeoclimatic Zones", 'bec_zones_gwc', "/geoserver/gwc/service/wms", null, null, null, null, true,  map.maxExtent.left + ',' + map.maxExtent.bottom);
    addWMSLayer("Regional Districts", 'p2a:rd_with_bbox', null, false, filter_region_xml, true, 0.7);
    addWMSLayer("Health Authority Districts", 'p2a:had_with_bbox', null, false, filter_region_xml, true, 0.7);
    addWMSLayer("Ecoprovinces", 'p2a:ecoprovince_with_bbox', null, false, filter_region_xml, true, 0.7);
    addWMSLayer("NRO Regions", 'p2a:nro_reg_with_bbox', null, false, filter_region_xml, true, 0.7);
    
    if (region == "British Columbia")
    {
	var new_center = new OpenLayers.LonLat(1006542.6812478, 1102399.852247);
	map.setCenter(new_center, 0);
    }
    else
    {
	map.setCenter(center_point.transform(P4326, map.getProjectionObject()), zoom_level);
    }

    var p2aBounds = new OpenLayers.Bounds(
	//minX, minY, maxX, maxY
        134672.1812478,192814.852247,1878413.1812478,2011984.852247
    );
    map.setOptions({restrictedExtent: p2aBounds});    
    //var clickEventHandler = new OpenLayers.Handler.Click({'map':map},{'click':getFeatureInfo});
    //clickEventHandler.activate();
    return map;
};

function getTopLayer(currentMap)
{
    for (var i = 0; i < currentMap.layers.length; i++){
        if (currentMap.layers[i].getVisibility() == true && currentMap.layers[i].displayInLayerSwitcher == true) {
            return currentMap.layers[i];
        }
    }
    return currentMap.getLayersByName('ncwmsLayer')[0];
};

function getElementValue(xml, elName)
{
    var el = xml.getElementsByTagName(elName);
    if (!el || !el[0] || !el[0].firstChild) return null;
    return el[0].firstChild.nodeValue;
};


var var2units = {
    'pr': 'mm/day',
    'tas': '\u00B0' + 'C',
    'tasmin': '\u00B0' + 'C',
    'tasmax': '\u00B0' + 'C',
    'pass': 'mm',
    'nffd': 'days',
    'dl18': 'degree-days',
    'dg18': 'degree-days',
    'dl00': 'degree-days',
    'dg05': 'degree-days'
};

function adjustValue(myVar, val){
    switch (myVar){
    case 'pr': return (val * 60 * 60 * 24);
    case 'tas':
    case 'tasmin':
    case 'tasmax': return(val - 273.15);
    case 'nffd':
    case 'pass':
    case 'dg18':
    case 'dl18':
    case 'dg05':
    case 'dl00':return(val);
    };
};

function unAnomaly(myVar, val, baseline){
    switch (myVar){
    case 'pr': return baseline * (val / 100) + baseline;
    case 'tas':
    case 'tasmin':
    case 'tasmax':
    case 'nffd':
    case 'pass':
    case 'dg18':
    case 'dl18':
    case 'dg05':
    case 'dl00':return(val + baseline);
    };
};

function numFix(myVar){
    switch (myVar){
    case 'tas':
    case 'tasmin':
    case 'tasmax': return(1); 
    case 'pr': 
    case 'pass': 
    case 'nffd': return(2);
    case 'dg18':
    case 'dl18':
    case 'dg05':
    case 'dl00': return(0);
    };
};

function getLocation(e)
{
    var lonLat = this.map.getLonLatFromPixel(e.xy);
    return lonLat;
};

function getFeatureInfo(currentMap, location, e_xy, closeBoxCallback, minRange, maxRange)
{
    var lonLat = location;
    var topLayer = getTopLayer(currentMap);
    var trimmedName = topLayer.params.LAYERS.replace('_gwc', '');
    var myVar = trimmedName.match(/(tas|pr|tasmin|tasmax|dl18|dl00|dg05|dg18|pass|nffd)/)[0];
    var units = var2units[myVar];
    if (topLayer.name == 'ncwmsLayer') {
        var wmsurl = topLayer.url;
        var type = 'xml'
        var url = wmsurl
            + "REQUEST=GetFeatureInfo"
            + "&EXCEPTIONS=application/vnd.ogc.se_xml"
            + "&BBOX=" + currentMap.getExtent().toBBOX()
            + "&X=" + e_xy.x.toFixed(0)
            + "&Y=" + e_xy.y.toFixed(0)
            + "&INFO_FORMAT=text/" + type
            + "&QUERY_LAYERS=" + trimmedName
            + "&LAYERS=" + trimmedName
            + "&FEATURE_COUNT=50"
            + "&SRS=EPSG:3005"
            + "&STYLES="
            + "&VERSION=1.1.1"
            + "&TIME=" + topLayer.params.TIME
            + "&WIDTH=" + currentMap.size.w
            + "&HEIGHT=" + currentMap.size.h;

    } else {
        var wmsurl = "/geoserver/p2a/wms?";
        var type = 'html'
        var url = wmsurl
            + "REQUEST=GetFeatureInfo"
            + "&EXCEPTIONS=application/vnd.ogc.se_xml"
            + "&BBOX=" + currentMap.getExtent().toBBOX()
            + "&X=" + e_xy.x.toFixed(0)
            + "&Y=" + e_xy.y.toFixed(0)
            + "&INFO_FORMAT=text/" + type
            + "&QUERY_LAYERS=" + trimmedName
            + "&LAYERS=" + trimmedName
            + "&FEATURE_COUNT=5"
            + "&SRS=EPSG:3005"
            + "&STYLES="
            + "&VERSION=1.1.1"
            + "&WIDTH=" + currentMap.size.w
            + "&HEIGHT=" + currentMap.size.h;
    };
    if (topLayer.name == 'ncwmsLayer') {
	if (popup) currentMap.removePopup(popup);
	OpenLayers.loadURL(url, '', currentMap,
			   function(response) {
            var xmldoc = response.responseXML;
            var val = parseFloat(getElementValue(xmldoc, 'value'));
            if (!isNaN(val)) {
		var ncwms_value = adjustValue(myVar, val);
                var ncwms_text = ncwms_value.toFixed(numFix(myVar)) + ' ' + units;
		if(minRange != undefined) {
		    var minRange_adj = unAnomaly(myVar, minRange, ncwms_value).toFixed(numFix(myVar));
		    var maxRange_adj = unAnomaly(myVar, maxRange, ncwms_value).toFixed(numFix(myVar));
		    ncwms_text += "<br/>(" + minRange_adj + " to " + maxRange_adj + ") " + units;
		}
                popup = new OpenLayers.Popup.Anchored (
                    "chicken",
                    lonLat,
                    new OpenLayers.Size(100, 100),
                    ncwms_text,
                    null,
                    true, // Means "add a close box"
		    closeBoxCallback
                );
                popup.autoSize = true;
		popup.border = '1px solid #808080';
		// this is to keep the popup within the map when zoom = 0 and the bounds are restricted
		// normally, the popup would handle this by moving the map, but we have restricted the map
		popup.keepInMap = true;
                popup.panMapIfOutOfView = (this.getZoom() != 0);
                this.addPopup(popup, true);
            }});
    } else {
        if (popup) currentMap.removePopup(popup);
        tempPopup = new OpenLayers.Popup.Anchored (
            "temp",
            lonLat,
            new OpenLayers.Size(100, 60),
	    'Loading... <center><img style="padding-top:4px" width="30" height="30" src="lib/anim_loading.gif"></center>',
            null,
            true, // Means "add a close box"
            null  // Do nothing when popup is closed.
        );
        tempPopup.autoSize = true;
	tempPopup.border = '1px solid #808080';
        currentMap.addPopup(tempPopup, true);
        OpenLayers.loadURL(url, '', currentMap, function(response){
            if ($('<div/>').append(response.responseText).find('table').length > 0){  //you got data } else { //it was empty }
		popup = new OpenLayers.Popup.Anchored (
                    "chicken",
                    lonLat,
                    new OpenLayers.Size(100, 100),
                    response.responseText,
                    null,
                    true, // Means "add a close box"
		    closeBoxCallback
		);
		popup.autoSize = true;
		popup.border = '1px solid #808080';
		// this is to keep the popup within the map when zoom = 0 and the bounds are restricted
		// normally, the popup would handle this by moving the map, but we have restricted the map
		popup.keepInMap = true;
                popup.panMapIfOutOfView = (this.getZoom() != 0);
		this.removePopup(tempPopup);
		this.addPopup(popup, true);
            } else {
                this.removePopup(tempPopup);
            };
        });
    };
};
