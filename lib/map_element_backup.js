var P4326 = new OpenLayers.Projection("EPSG:4326");
var P3005 = new OpenLayers.Projection("EPSG:3005");
    //var P3005 = new Proj4js.Proj('EPSG:3005');

//OpenLayers.DOTS_PER_INCH = 25.4 / 0.28;
function init_map(map_id, region, climate_overlay, climate_time, color_range, color_scale, center_point, zoom_level) {
    var P4326 = new OpenLayers.Projection("EPSG:4326");
    var P3005 = new OpenLayers.Projection("EPSG:3005");

    var bounds = new OpenLayers.Bounds(
	//minX, minY, maxX, maxY
	270000,330000,1874400,1736400
    );
    var controlOptions = {
        maximized: false,
        size: new OpenLayers.Size(200,170),
	autoPan: false,
	mapOptions: {numZoomLevels: 2}
    };

    var options = {
        controls: [
	    new OpenLayers.Control.Navigation({'handleRightClicks':true}),
            new OpenLayers.Control.LayerSwitcher({'ascending':false}),
            new OpenLayers.Control.ScaleLine(),
            new OpenLayers.Control.KeyboardDefaults(),
	    new OpenLayers.Control.PanZoomBar({
		position: new OpenLayers.Pixel(2, 15)
	    }),
	    new OpenLayers.Control.Scale($('scale')),
	    new OpenLayers.Control.MousePosition({element: $('location')}),
	    new OpenLayers.Control.NavigationHistory(),
	    new OpenLayers.Control.NavToolbar()
	],
        maxExtent: bounds,
        displayProjection: P4326,
        maxResolution: 4437,
        resolutions: [4437, 2218.5, 1109.25,554.625,277.3125,138.6562,69.32812],
        projection: "EPSG:3005",
        units: 'm',
    }; 

    map = new OpenLayers.Map(map_id, options);
	 
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
    filter_region_xml = xml.write(filter_1_1.write(filter_region))

    ecoprov_regions = new OpenLayers.Layer.WMS(
        "EcoProvinces", "http://medusa.pcic.uvic.ca/geoserver/CRMP/wms",
        {
            LAYERS: 'CRMP:ecoprovince_with_bbox',
            format: 'image/png',
            projection: P3005,
	    filter : filter_region_xml,
            'transparent':'true'},
        {'opacity':0.7, 'isBaseLayer': false, 'visibility':true, displayOutsideMaxExtent: true});

    health_regions = new OpenLayers.Layer.WMS(
        "Health Authority Boundaries", "http://medusa.pcic.uvic.ca/geoserver/CRMP/wms",
        {
            LAYERS: 'CRMP:had_with_bbox',
            format: 'image/png',
            projection: P3005,
	    filter : filter_region_xml,
            'transparent':'true'},
        {'opacity':0.7, 'isBaseLayer': false, 'visibility':true, displayOutsideMaxExtent: true});


    rd_regions = new OpenLayers.Layer.WMS(
        "Regional Districts", "http://medusa.pcic.uvic.ca/geoserver/CRMP/wms",
        {
            LAYERS: 'CRMP:rd_with_bbox',
            format: 'image/png',
	    projection: P3005,
	    filter : filter_region_xml,
            'transparent':'true'},
        {'opacity':0.7, 'isBaseLayer': false, 'visibility':true, displayOutsideMaxExtent: true});


/// BC Administrative
    muni = new OpenLayers.Layer.WMS(
        "Municipalities", "http://medusa.pcic.uvic.ca/geoserver/CRMP/wms",
        {
            LAYERS: 'CRMP:municipalities',
            format: 'image/png',
	    projection: P3005,
	    'transparent':'true'},
        {'opacity':1.0, 'isBaseLayer': false, 'visibility':false, displayOutsideMaxExtent: true});

/// Forestry
    tfl = new OpenLayers.Layer.WMS(
        "Tree Farm Licenses", "http://medusa.pcic.uvic.ca/geoserver/CRMP/wms",
        {
            LAYERS: 'CRMP:fadm_tfl',
            format: 'image/png',
	    projection: P3005,
	    'transparent':'true'},
        {'opacity':1.0, 'isBaseLayer': false, 'visibility':false, displayOutsideMaxExtent: true});

    tsa = new OpenLayers.Layer.WMS(
        "Tree Supply Areas", "http://medusa.pcic.uvic.ca/geoserver/CRMP/wms",
        {
            LAYERS: 'CRMP:fadm_tsa',
            format: 'image/png',
	    projection: P3005,
	    'transparent':'true'},
        {'opacity':0.4, 'isBaseLayer': false, 'visibility':false, displayOutsideMaxExtent: true});

    fadm_dist = new OpenLayers.Layer.WMS(
        "Forestry Districts", "http://medusa.pcic.uvic.ca/geoserver/CRMP/wms",
        {
            LAYERS: 'CRMP:fadm_dist',
            format: 'image/png',
	    projection: P3005,
	    'transparent':'true'},
        {'opacity':0.4, 'isBaseLayer': false, 'visibility':false, displayOutsideMaxExtent: true});
    
    params2 = {
        layers: climate_overlay,//activeLayer.id,
        elevation: 0,//getZValue(),
        time: climate_time, //"2002-12-15T00:00:00.000Z",//isoTValue,
        transparent: 'true',
        styles: "boxfill/" + color_scale,//style,
        colorscalerange: color_range, //"-0.000012962963,0.00029768518",//scaleMinVal + ',' + scaleMaxVal,
        numcolorbands: 254,//$('numColorBands').value,
        logscale: false,
        format: 'image/png',
        version: '1.1.1',
        srs: 'EPSG:4326'
    };
    ncwms =  new OpenLayers.Layer.WMS("ncWMS-1852",
                                      "http://medusa.pcic.uvic.ca:8080/ncWMS-1.0RC3/wms?",
                                      params2,
                                      {buffer: 1, ratio: 1.5, 
				       singleTile: false, wrapDateLine: true, visibility:false, opacity: 0.5}
                                     );
    
    osm_mq = new OpenLayers.Layer.WMS(
	"OpenStreetMap", 
	//"http://medusa.pcic.uvic.ca:8080/geoserver/gwc/service/wms",
	"http://medusa.pcic.uvic.ca:8080/geoserver/wms",
	{LAYERS: 'osm_pnwa_p2a',
	 tiled: true,
	 //tilesOrigin : map.maxExtent.left + ',' + map.maxExtent.bottom,
	 'transparent' : true},
	{isBaseLayer:true, displayOutsideMaxExtent: true});
    
    
    map.addLayers([osm_mq, ncwms, rd_regions, health_regions, ecoprov_regions, muni, tfl, tsa, fadm_dist]);
    map.setCenter(new OpenLayers.LonLat(center_point.x, center_point.y),3, forceZoomChange=false);
    
    map.zoomToMaxExtent();
};
