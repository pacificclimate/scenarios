package CICS::Scenario::Data;

use strict;

our(@dat, @str);

## Data
# 0 is English, 1 is French, 2 is Data, anything beyond 2 is extended data

$dat[0]{'timeofyear'} = 
  [ "January", "February", "March", "April", "May", "June", "July", "August",
    "September", "October", "November", "December", "Winter - DJF", 
    "Spring - MAM", "Summer - JJA", "Fall - SON", "Annual",
    "All Months", "All Seasons", "All Seasons, Months, and Annual"
  ];
$dat[1]{'timeofyear'} = 
  [ "janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
    "septembre", "octobre", "novembre", "décembre", "hiver - djf", 
    "printemps - mam", "été - jja", "automne - son", "annuel",
    "tout les mois", "tout les saisons", "tout les saisons, mois, et annuel"
  ];
$dat[2]{'timeofyear'} = 
  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, [0..11], [12..15], [0..16] ];
$dat[3]{'timeofyear'} = # symbolic toy names
  [ "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec", "djf", "mam", "jja", "son", "ann" ];
$dat[4]{'timeofyear'} =
  [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 12, -9999, -9999, -9999 ];  # FIXME 
## ncWMS times of year
$dat[5]{'timeofyear'} =
    [ '01-16',  '02-16',  '03-16',  '04-16',  '05-16',  '06-16',  '07-16',  '08-16',  '09-16',  '10-16',  '11-16',  '12-16',  '01-15',  '04-15',  '07-15',  '10-15',  '07-01' ];

# Idea for variables is: Write them here now, change them later if needed
$dat[0]{'variable'} = 
  [ "Mean Temperature",        "Precipitation",
    "Maximum Temperature",     "Minimum Temperature",
    "Specific Humidity",       "Incident Solar Radiation",
    "Fractional Cloud Cover",  "Wind Speed",
    "Evaporation",             "Soil Moisture",
    "Mean Sea Level Pressure", "Snow Water Content",
    "Sea Ice",                 "Vapour Pressure",
    "Relative Humidity",       "Diurnal Temperature Range",
    "Surface Temperature",     "Soil Moisture Content",
    "Snow Depth",	       "Geopotential Height",
    "Snow Melt",	       "Degree-Days Below 0",
    "Degree-Days Above 5",     "Degree-Days Below 18",
    "Degree-Days Above 18",    "Number of Frost-Free Days",
    "Snowfall",                "Interannual SD of Temperature",
    "Interannual SD of Precipitation", "T & P",
    "All Variables"
  ];

$dat[1]{'variable'} = 
  [ "Température moyenne",                  "Précipitations",
    "Température maximale",                 "Température minimale",
    "Humidité spécifique",                  "Rayonnement solaire incident",
    "Couverture nuageuse",                  "Vitesse du vent",
    "Évaporation",                          "Humidité du sol",
    "Pression moyenne au niveau de la mer", "Teneur en eau de la neige",
    "Glace de mer",                         "Pression de vapeur",
    "Humidité relative",                    "Variation de température diurne",
    "Température en surface",               "Soil Moisture Content",
    "Snow Depth",		            "Geopotential Height",
    "Snow Melt",	       "Degree-Days Below 0",
    "Degree-Days Above 5",     "Degree-Days Below 18",
    "Degree-Days Above 18",    "Number of Frost-Free Days",
    "Snowfall",                "Interannual SD of Temperature",
    "Interannual SD of Precipitation", "T & P",
    "All Variables"
  ];

# Filename stuff
$dat[2]{'variable'} = 
  [ "temp", "prec", "tmax", "tmin", "shum", "irad", "tcld", "wind", 
    "evap", "soil", "mslp", "snow", "sice", "vapp", "rhum", "ditr", 
    "surt", "somm", "snod", "h500", "melt", "dl00", "dg05", "dl18",
    "dg18", "nffd", "pass", "isdt", "isdp", [0..1], [0..29]
  ];

# FIXME - LANG -- BIG!
# Baseline legend text
$dat[3]{'variable'} = 
  [ '°C','mm/day','°C','°C','kg/kg','W/m^2','Fraction','m/s',
    'mm/day','capacity frac.','hPa','kg/m^2','kg/m^2','hPa','Percent','°C',
    '°C', 'mm','m','m','mm/day', 'degree-days', 'degree-days', 'degree-days',
    'degree-day', 'days', 'mm', '°C', 'mm/day'
  ];

# FIXME - LANG -- BIG!
# Prediction legend text
$dat[4]{'variable'} = 
  [ '°C','Percent','°C','°C','kg/kg','W/m^2','Percent','Percent',
    'mm/day','capacity frac.','hPa','kg/m^2','kg/m^2','hPa','Percent','°C',
    '°C','mm','m','m','mm/day', 'degree-days', 'degree-days', 'degree-days',
    'degree-day', 'days', 'Percent', '°C', 'mm/day'

  ];
# Baseline legend range default
#$dat[5]{'variable'} = 
#  [ [-30, 30], [0, 10], [-30, 30], [-30, 30], [0, 0.020], [0, 400], [0, 1], [0, 11],
#    [0, 5], [0, 1], [990, 1020], [0, 250], [0, 2500], [0, 30], [60, 100], [0, 20],
#    [-30, 30], [0, 0.5], [0, 5], [5000, 6000], [0, 2], [0, 5000], [0, 5000], [0, 5000], [0, 5000], [0, 365], [0, 2000]
#  ];
$dat[5]{'variable'} = 
  [ [-20, 20], [0, 20], [-30, 30], [-30, 30], [0, 0.020], [0, 400], [0, 1], [0, 11],
    [0, 5], [0, 1], [990, 1020], [0, 250], [0, 2500], [0, 30], [60, 100], [0, 20],
    [-30, 30], [0, 0.5], [0, 5], [5000, 6000], [0, 2], [0, 5000], [0, 5000], [0, 8000], 
    [0, 5000], [0, 365], [0, 3500], [0, 5], [0, 5]
  ];
# Prediction legend range default
$dat[6]{'variable'} = 
  [ [-1, 9], [-25, 25], [-1, 9], [-1, 9], [-0.5, 2], [-15, 25], [-15, 35], [-25, 25],
    [-0.5, 1], [-0.2, 0.3], [-5, 5], [-60, 10], [-2500, 100], [-1, 4], [-4, 4], [-8, 2],
    [-1, 9], [-0.2, 0], [-4, 1], [0, 150], [-0.8, 0.2], [0, 5000], [0, 5000], [0, 8000], 
    [0, 5000], [0, 365], [-25, 25 ], [0, 5], [0, 5]
  ];
# Baseline decimal places
$dat[7]{'variable'} = 
  [ 2, 2, 0, 0, 4, 0, 1, 0, 
    1, 1, 0, 0, 0, 0, 0, 0, 
    0, 2, 1, 0, 1, 0, 0, 0,
    0, 0, 0, 2, 3
  ];
# Prediction decimal places
$dat[8]{'variable'} = 
  [ 1, 0, 1, 1, 5, 0, 0, 1, 
    2, 2, 1, 2, 0, 1, 1, 1, 
    1, 3, 1, 0, 1, 0, 0, 0,
    0, 0, 0, 2, 3
  ];
# Reverse (range)
$dat[9]{'variable'} = 
  [ 0, 1, 0, 0, 1, 0, 1, 0,
    0, 0, 0, 0, 0, 1, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 0, 0
  ];
# Plot over ocean override (-1 for no override)
$dat[10]{'variable'} = 
  [ -1, -1, -1, -1, -1, -1, -1, -1,
    -1,  0, -1, -1,  2, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1
  ];
# Baseline legend dynamic range default (unused?)
$dat[11]{'variable'} = 
  [   6,   1,   6,   6,   0.002,  40, 0.1,   1,
      0.5, 0.1,   3,  25, 250,   3,   4,   2,
      6, 0.05, 0.5, 100, 0.2, 0, 0, 0, 
      0, 0, 0, 6, 6
  ];
# Prediction legend dynamic range default (unused?)
$dat[12]{'variable'} = 
  [  1,   5,   1,   1,0.25,   0.002,   5,    5,
     0.15,0.05,   1,   7, 250, 0.5,  0.8,   1,
     1,0.02, 0.5,  15, 0.1, 0, 0, 0, 
     0, 0, 0, 6, 6
  ];

# Percentage of baseline boolean (Prediction only)
$dat[13]{'variable'} = 
  [ 0, 1, 0, 0, 0, 0, 1, 1,
    0, 0, 0, 0, 0, 0, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 1, 0, 0
  ];

# Cumulative (therefore non-annual range is a *fraction* of annual)  FIXME need to abstract getting range so everything uses it properly
$dat[14]{'variable'} =
  [ 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 1, 1, 1,
    1, 1, 1, 0, 0
  ];
# "Fudge Factor"
$dat[15]{'variable'} = 
  [ 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 1, 0.37, 0.63,
    1, 1.01, 0.50, 0, 0
  ];

# ncWMS layer variable name
$dat[16]{'variable'} = 
  [ "tas", "pr", "tasmax", "tasmin", "shum", "irad", "tcld", "wind", 
    "evap", "soil", "mslp", "snow", "sice", "vapp", "rhum", "ditr", 
    "surt", "somm", "snod", "h500", "melt", "dl00", "dg05", "dl18",
    "dg18", "nffd", "pass", "isdt", "isdp"
  ];

# ncWMS color pallette name
$dat[17]{'variable'} = 
  [ "blue_darkred", "brown_green", "rainbow", "rainbow", "rainbow", "rainbow", "rainbow", "rainbow", 
    "rainbow", "rainbow", "rainbow", "rainbow", "rainbow", "rainbow", "rainbow", "rainbow", 
    "rainbow", "rainbow", "rainbow", "rainbow", "rainbow", "rainbow", "blue_darkred", "lightblue_darkblue", 
    "rainbow", "blue_brown", "brown_blue", "brown_green", "brown_green"
  ];

# ncWMS scale factor
$dat[18]{'variable'} = 
  [ 1,1/86400,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,
    1,1,1,1,1
  ];

# ncWMS add factor
$dat[19]{'variable'} = 
  [ 273.15,0,273.15,273.15,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,
    0,0,0,0,0
  ];

# Time periods aka timeslices
$dat[0]{'timeslice'} = [ "1961-1990 Baseline", "2020s (2010-2039)", "2050s (2040-2069)", "2080s (2070-2099)", "All Time Slices" ];
$dat[1]{'timeslice'} = [ "Données de référence 1961-1990", "2020s", "2050s", "2080s", "Tout" ];
$dat[2]{'timeslice'} = [ "1961_1990", "2020", "2050", "2080", [ 0..3 ] ];
$dat[3]{'timeslice'} = [ "1961_1990", "2010_2039", "2040_2069", "2070_2099", [ 0..3 ] ];
## ncWMS filename periods and time periods
$dat[4]{'timeslice'} = [ "1961-1990", "2010-2039", "2040-2069", "2070-2099", [ 0..3 ] ];
$dat[5]{'timeslice'} = [ "1975", "2025", "2055", "2075", [ 0..3 ] ];

# FIXME - LANG
# Map regions (this will be extended later)
$dat[0]{'region'} = [ "World", "Canada", "North America", "BC", "PCIC Region", "BC Albers", "Pacific Canada" ];
$dat[1]{'region'} = [ "World", "Canada", "North America", "BC", "PCIC Region", "BC Albers", "Pacific Canada" ];
$dat[2]{'region'} = [ "world", "cdn", "nam", "bc", "pcic", "bca", "pcan" ];
$dat[3]{'region'} = [ 0, 0, 0, 0, 0, 1, 2 ];

# Scenario set for scatter plots
$dat[0]{'sset'} = [ "Show All", "All SRES AR4", "All SRES", "All IS92a" ];
$dat[1]{'sset'} = [ "Tout", "Tout du AR4 SRES", "Tout du SRES", "Tout du IS92a" ];
$dat[2]{'sset'} = [ "", "SRES AR4", "SRES", "IS92a" ];

# Data source type for scatter plots
$dat[0]{'stype'} = [ "Data point", "Region" ];
$dat[1]{'stype'} = [ "Point de donnees", "Region" ];
$dat[2]{'stype'} = [ 0, 1 ];

# Zoom levels and filename mappings
$dat[0]{'zoom'} = [ "1x", "2x", "4x", "8x", "16x" ];
$dat[1]{'zoom'} = [ "1x", "2x", "4x", "8x", "16x" ];
$dat[2]{'zoom'} = [ "1", "2", "4", "8", "16" ];

# Resolutions and actual widths (heights would be nice)
$dat[0]{'resolution'} = [ "800x600", "1024x768", "1280x1024", "640x480" ];  #FIXME ugh the last one is planner-specific
$dat[1]{'resolution'} = [ "800x600", "1024x768", "1280x1024", "640x480" ];
$dat[2]{'resolution'} = [ 800, 1024, 1280, 640 ];

# Image formats we offer
$dat[0]{'image_formats'} = [ "PNG", "JPEG" ];
$dat[1]{'image_formats'} = [ "PNG", "JPEG" ];
$dat[2]{'image_formats'} = [ 0, 1 ];

# Ops performed by clicking on image
# FIXME - LANG
$dat[0]{'image_ops'} = [ "- Select Op -", "Add Point", "Select Point", "Move Point", "Zoom In" ];
$dat[1]{'image_ops'} = [ "- Select Op -", "Add Point", "Select Point", "Move Point", "Zoom In" ];
$dat[2]{'image_ops'} = [ 0, 1, 2, 3, 4 ];

# Ops performed by clicking a button (which affect the image)
# FIXME - LANG
$dat[0]{'button_ops'} = [ "Deselect Point", "Remove Point", "", "Clear Points", "Zoom Out" ];
$dat[1]{'button_ops'} = [ "Deselect Point", "Remove Point", "", "Clear Points", "Zoom Out" ];
$dat[2]{'button_ops'} = [ 0, 1, 2, 3, 4, 5 ];

# Ranging type
$dat[0]{'range_type'} = [ "Fixed", "Auto" ];
$dat[1]{'range_type'} = [ "Fixe", "Auto" ];
$dat[2]{'range_type'} = [ 0, 1 ];

# Language (in both English and French)
$dat[0]{'lang'} = [ 'English', 'French' ];
$dat[1]{'lang'} = [ 'Anglais', 'Fran&ccedil;ais' ];
$dat[2]{'lang'} = [ 'en', 'fr' ];

# FIXME - LANG
# Number of data decimal places
$dat[0]{'numdatdec'} = [ 'Default', 0, 1, 2, 3, 4, 5, 6 ];
$dat[1]{'numdatdec'} = [ 'Default', 0, 1, 2, 3, 4, 5, 6 ];
$dat[2]{'numdatdec'} = [ '', 0, 1, 2, 3, 4, 5, 6 ];

## Strings not directly connected to data
$str[0]{'grid'} = "Grid";
$str[1]{'grid'} = "grille";

$str[0]{'plotoverocean'} = "Plot over ocean";
$str[1]{'plotoverocean'} = "Yracer sur les océans";

# FIXME - LANG
$str[0]{'plotregion'} = "Plot window";
$str[1]{'plotregion'} = "Plot window";

$str[0]{'experiment'} = "Experiment";
$str[1]{'experiment'} = "Expérience";

$str[0]{'experiment_long'} = "Select GCM and emissions scenario";
$str[1]{'experiment_long'} = "Choisissez MCG et sc&eacute;nario d'&eacute;missions";

# FIXME - LANG
$str[0]{'variables'} = "Variables";
$str[1]{'variables'} = "Variables";

# FIXME - LANG
$str[0]{'variables_long'} = "Select climate variable, time of year and time slice";
$str[1]{'variables_long'} = "Select climate variable, time of year and time slice";

# FIXME - LANG
$str[0]{'variable'} = "Variable";
$str[1]{'variable'} = "Variable";

$str[0]{'timeslice'} = "Time Slice";
$str[1]{'timeslice'} = "Tranche de temps";

$str[0]{'timeofyear'} = "Time of Year";
$str[1]{'timeofyear'} = "Période de l'année";

# FIXME - LANG
$str[0]{'down_opts'} = "Download Options";
$str[1]{'down_opts'} = "Options de télécharger";

#FIXME - LANG
$str[0]{'cust_region_mask'} = "Custom region mask file";
$str[1]{'cust_region_mask'} = "Custom region mask file";

$str[0]{'down_img'} = "Download Map";
$str[1]{'down_img'} = "Télécharger la carte";

$str[0]{'show'} = "Show";
$str[1]{'show'} = "Montrer";

# FIXME - LANG
$str[0]{'please_select_point'} = "Please select a point using the \"Gridbox Options\" menu to get timeseries data for that grid box";
$str[1]{'please_select_point'} = "Please select a point using the \"Gridbox Options\" menu to get timeseries data for that grid box";

$str[0]{'data_links'} = "Data links";
$str[1]{'data_links'} = "Liens du donn&eacute;es";

# FIXME - LANG
$str[0]{'timeseries_links'} = "Timeseries";
$str[1]{'timeseries_links'} = "Timeseries";

$str[0]{'metadata'} = "Metadata";
$str[1]{'metadata'} = "M&eacute;tadonn&eacute;e";

$str[0]{'printable_img'} = "Printable Image";
$str[1]{'printable_img'} = "Image imprimable";

$str[0]{'all'} = "All";
$str[1]{'all'} = "Tout";

# FIXME - LANG
$str[0]{'alldata'} = "All experiments, variables, and time periods plus map files";
$str[1]{'alldata'} = "All experiments, variables, and time periods plus map files";

$str[0]{'scenario_access'} = "Scenario Access";
$str[1]{'scenario_access'} = "Accès aux scénarios";

$str[0]{'zoom_level'} = "Zoom Level";
$str[1]{'zoom_level'} = "Level de magnification";

$str[0]{'update'} = "Update";
$str[1]{'update'} = "Actualiser";

$str[0]{'suggest_region'} = "Suggest Region";
$str[1]{'suggest_region'} = "Sugg&eacute;rez la r&eacute;gion";

$str[0]{'suggest_current_region'} = "Suggest Current Region";
$str[1]{'suggest_current_region'} = "Sugg&eacute;rez la r&eacute;gion courante";

$str[0]{'resolution'} = "Display resolution";
$str[1]{'resolution'} = "R&eacute;solution du moniteur";

# FIXME - LANG
$str[0]{'region_options'} = "Region Options";
$str[1]{'region_options'} = "Options de r&eacute;gion";

# FIXME - LANG
$str[0]{'scenarios'} = "Scenarios";
$str[1]{'scenarios'} = "Scenarios";

# FIXME - LANG
$str[0]{'geotiff'} = "Geotiff";
$str[1]{'geotiff'} = "Geotiff";

# FIXME - LANG
$str[0]{'numgridboxes'} = "# Grid Boxes";
$str[1]{'numgridboxes'} = "# Grid Boxes";

# FIXME - LANG
$str[0]{'img_format'} = "Image Format";
$str[1]{'img_format'} = "Format d'image";

# FIXME - LANG
$str[0]{'mask'} = "Mask (Scenarios format)";
$str[1]{'mask'} = "Mask (Scenarios format)";

# FIXME - LANG
$str[0]{'region_mask'} = "Region mask (Scenarios format)";
$str[1]{'region_mask'} = "Region mask (Scenarios format)";

# FIXME - LANG
$str[0]{'data_files'} = "Data files";
$str[1]{'data_files'} = "Data files";

# FIXME - LANG
$str[0]{'zip_files_allexpt'} = "Zipped data files: All expts for var and model";
$str[1]{'zip_files_allexpt'} = "Zipped data files: All expts for var and model";

# FIXME - LANG
$str[0]{'zip_files_allvar'} = "Zipped data files: All vars for model and expt";
$str[1]{'zip_files_allvar'} = "Zipped data files: All vars for model and expt";

# FIXME - LANG
$str[0]{'zip_files_allexptvar'} = "Zipped data files: All expts and vars for model";
$str[1]{'zip_files_allexptvar'} = "Zipped data files: All expts and vars for model";

# FIXME - LANG
$str[0]{'georef_region_data'} = "Georeferenced region data";
$str[1]{'georef_region_data'} = "Georeferenced region data";

# FIXME - LANG
$str[0]{'georeferenced'} = "Georeferenced";
$str[1]{'georeferenced'} = "Georeferenced";

# FIXME - LANG
$str[0]{'scenarios_format'} = "Scenarios format";
$str[1]{'scenarios_format'} = "Scenarios format";

# FIXME - LANG
$str[0]{'geotiff_format'} = "Geotiff format";
$str[1]{'geotiff_format'} = "Geotiff format";

# FIXME - LANG
$str[0]{'anomaly_timeseries'} = "Anomaly timeseries";
$str[1]{'anomaly_timeseries'} = "Anomaly timeseries";

# FIXME - LANG
$str[0]{'timeseries_data'} = "Timeseries data";
$str[1]{'timeseries_data'} = "Timeseries data";

# FIXME - LANG
$str[0]{'timeseries_ratio'} = "Timeseries ratio";
$str[1]{'timeseries_ratio'} = "Timeseries ratio";

# FIXME - LANG
$str[0]{'scen_file_format'} = '<a href="http://www.cics.uvic.ca/scenarios/index.cgi?More_Info-Data_File_Information#scenback">Scenario file format</a>';
$str[1]{'scen_file_format'} = '<a href="http://www.cics.uvic.ca/scenarios/index.cgi?More_Info-Data_File_Information#scenback">Scenario file format</a>';

# FIXME - LANG
$str[0]{'georef_file_format'} = '<a href="http://www.cics.uvic.ca/scenarios/index.cgi?More_Info-Data_File_Information#georef">Geo-referenced format</a>';
$str[1]{'georef_file_format'} = '<a href="http://www.cics.uvic.ca/scenarios/index.cgi?More_Info-Data_File_Information#georef">Geo-referenced format</a>';

# FIXME - LANG
$str[0]{'fine_resolution'} = '<a href="http://www.cics.uvic.ca/scenarios/index.cgi?More_Info-Fine_Resolution_Scenarios">Fine resolution</a>';
$str[1]{'fine_resolution'} = '<a href="http://www.cics.uvic.ca/scenarios/index.cgi?More_Info-Fine_Resolution_Scenarios">Fine resolution</a>';

# FIXME - LANG
$str[0]{'gis_shape_files'} = "<a href=\"http://www.cics.uvic.ca/scenarios/index.cgi?More_Info-GIS_Shape_Files\">GIS Shape Files</a>";
$str[1]{'gis_shape_files'} = "<a href=\"http://www.cics.uvic.ca/scenarios/index.cgi?More_Info-GIS_Shape_Files\">GIS Shape Files</a>";

# FIXME - LANG
$str[0]{'grid_boxes'} = "Grid boxes";
$str[1]{'grid_boxes'} = "Grid boxes";

# FIXME - LANG
$str[0]{'grid_points'} = "Grid points";
$str[1]{'grid_points'} = "Grid points";

$str[0]{'ppt_grids'} = "<a href=\"http://www.cics.uvic.ca/scenarios/data/GCM_Output_Grids_and_Grid_Points.ppt\">GCM Output Grids - Powerpoint Presentation</a>";
$str[1]{'ppt_grids'} = "<a href=\"http://www.cics.uvic.ca/scenarios/data/GCM_Output_Grids_and_Grid_Points.ppt\">Grilles de résultats des MCG - Présentation en Powerpoint (Offerte en anglais seulement)</a>";

# These are an experiment -- I'll see if I use them.
$str[0]{'cccma'} = "Canadian Centre for Climate Modelling and Analysis";
$str[1]{'cccma'} = "Centre canadien de la mod&eacute;lisation et de l'analyse climatique";

$str[0]{'gcm'} = "Global Coupled Model";
$str[1]{'gcm'} = "Mod&egrave;le de circulation g&eacute;n&eacute;rale";

# FIXME - LANG
$str[0]{'sur_sw_rad'} = "Surface Shortwave Radiation";
$str[1]{'sur_sw_rad'} = "Surface Shortwave Radiation";

# FIXME - LANG
$str[0]{'sur_pressure'} = "Surface Pressure";
$str[1]{'sur_pressure'} = "Surface Pressure";

# FIXME - LANG
$str[0]{'max'} = "Max";
$str[1]{'max'} = "Max";

# FIXME - LANG
$str[0]{'datapoint'} = "Grid box";
$str[1]{'datapoint'} = "Grid box";

# FIXME - LANG
$str[0]{'min'} = "Min";
$str[1]{'min'} = "Min";

# FIXME - LANG
$str[0]{'maxdata'} = "Max data";
$str[1]{'maxdata'} = "Max data";

# FIXME - LANG
$str[0]{'coordslonlat'} = "Coordinates (lon, lat)";
$str[1]{'coordslonlat'} = "Coordinates (lon, lat)";

# FIXME - LANG
$str[0]{'coordslatlon'} = "Coordinates (lat, lon)";
$str[1]{'coordslatlon'} = "Coordinates (lat, lon)";

# FIXME - LANG
$str[0]{'mindata'} = "Min data";
$str[1]{'mindata'} = "Min data";

# FIXME - LANG
$str[0]{'selection'} = "Selection";
$str[1]{'selection'} = "S&eacute;lection";

# FIXME - LANG
$str[0]{'mean'} = "Weighted Mean";
$str[1]{'mean'} = "Weighted Mean";

# FIXME - LANG
$str[0]{'timeseries'} = "Timeseries";
$str[1]{'timeseries'} = "Timeseries";

# FIXME - LANG
$str[0]{'median'} = "Median";
$str[1]{'median'} = "Median";

# FIXME - LANG
$str[0]{'area'} = "Area";
$str[1]{'area'} = "Area";

# FIXME - LANG
$str[0]{'dont_show_data'} = "Hide point";
$str[1]{'dont_show_data'} = "F_Hide point";

# FIXME - LANG
$str[0]{'display_opts'} = "Display options";
$str[1]{'display_opts'} = "Display options";

# FIXME - LANG
$str[0]{'data_opts'} = "Data options";
$str[1]{'data_opts'} = "Data options";

# FIXME - LANG
$str[0]{'map_opts'} = "Map options";
$str[1]{'map_opts'} = "Map options";

# FIXME - LANG
$str[0]{'map_opts_long'} = "Customise visualisation of map and select sub-regions";
$str[1]{'map_opts_long'} = "Customise visualisation of map and select sub-regions";

# FIXME - LANG
$str[0]{'stddev'} = "Weighted Standard Deviation";
$str[1]{'stddev'} = "Weighted Standard Deviation";

# FIXME - LANG
$str[0]{'range'} = "Range (lat, lon)";
$str[1]{'range'} = "Range (lat, lon)";

# FIXME - LANG
$str[0]{'range'} = "Range";
$str[1]{'range'} = "Range";

# FIXME - LANG
$str[0]{'area'} = "Area";
$str[1]{'area'} = "Area";

# FIXME - LANG
$str[0]{'map'} = "Map";
$str[1]{'map'} = "Carte";

# FIXME - LANG
$str[0]{'decplaces'} = "Dec. places";
$str[1]{'decplaces'} = "Dec. places";

# FIXME - LANG
$str[0]{'predef_region'} = "Predefined Region";
$str[1]{'predef_region'} = "Predefined Region";

# FIXME - LANG
$str[0]{'use_region'} = "Use Region";
$str[1]{'use_region'} = "Use Region";

# FIXME - LANG
$str[0]{'clear_points'} = "Clear points";
$str[1]{'clear_points'} = "Clear points";

# FIXME - LANG
$str[0]{'round_factor'} = "Rounding factor";
$str[1]{'round_factor'} = "Rounding factor";

# FIXME - LANG
$str[0]{'too_many_plots'} = "Maximum number of plots per page reached.";
$str[1]{'too_many_plots'} = "Maximum number of plots per page reached.";

# FIXME - LANG
$str[0]{'warn_timeslice_defaulted'} = "Please note that the time slice you have chosen has been set to the default. Plots involving more than one 'all' variable selected are not allowed.";
$str[1]{'warn_timeslice_defaulted'} = "Please note that the time slice you have chosen has been set to the default. Plots involving more than one 'all' variable selected are not allowed.";

# FIXME - LANG
$str[0]{'warn_timeofyear_defaulted'} = "Please note that the time of year you have chosen has been set to the default. Plots involving more than one 'all' variable selected are not allowed.";
$str[1]{'warn_timeofyear_defaulted'} = "Please note that the time of year you have chosen has been set to the default. Plots involving more than one 'all' variable selected are not allowed.";

# FIXME - LANG
$str[0]{'warn_variable_defaulted'} = "Please note that the variable you have chosen has been set to the default. Plots involving more than one 'all' variable selected are not allowed.";
$str[1]{'warn_variable_defaulted'} = "Please note that the variable you have chosen has been set to the default. Plots involving more than one 'all' variable selected are not allowed.";

# FIXME - LANG
$str[0]{'warn_no_var_for_expt'} = "The variable you have selected is not available in this experiment. It has been defaulted to the first variable available.<br>";
$str[1]{'warn_no_var_for_expt'} = "The variable you have selected is not available in this experiment. It has been defaulted to the first variable available.<br>";

# FIXME - LANG
$str[0]{'prepared_by_ccis'} = "Prepared by the Canadian Climate Impacts Scenarios (CCIS) Group.";
$str[1]{'prepared_by_ccis'} = "Prepared by the Canadian Climate Impacts Scenarios (CCIS) Group.";

# FIXME - LANG
$str[0]{'please_ack_ccis'} = "Please acknowledge the CCIS Project if you use this information in any reports or publications.";
$str[1]{'please_ack_ccis'} = "Please acknowledge the CCIS Project if you use this information in any reports or publications.";

# FIXME - LANG
$str[0]{'is92a_warning'} = "NOTE: The IS92a emissions scenarios have been replaced by the SRES emissions scenarios. We do not recommend the use of IS92a scenarios for any new studies.<br>";
$str[1]{'is92a_warning'} = "NOTE: The IS92a emissions scenarios have been replaced by the SRES emissions scenarios. We do not recommend the use of IS92a scenarios for any new studies.<br>";

# FIXME - LANG
$str[0]{'ga1'} = "Greenhouse Gas With Aerosol Simulation 1";
$str[0]{'ga2'} = "Greenhouse Gas With Aerosol Simulation 2";
$str[0]{'ga3'} = "Greenhouse Gas With Aerosol Simulation 3";
$str[0]{'ga4'} = "Greenhouse Gas With Aerosol Simulation 4";
$str[0]{'gax'} = "Greenhouse Gas With Aerosol Simulation Mean";
$str[0]{'gg1'} = "Greenhouse Gas Only Simulation 1";
$str[0]{'gg2'} = "Greenhouse Gas Only Simulation 2";
$str[0]{'gg3'} = "Greenhouse Gas Only Simulation 3";
$str[0]{'gg4'} = "Greenhouse Gas Only Simulation 4";
$str[0]{'ggx'} = "Greenhouse Gas Only Simulation Mean";
$str[0]{'A21'} = "Economic Regional Focus Simulation 1";
$str[0]{'A22'} = "Economic Regional Focus Simulation 2";
$str[0]{'A23'} = "Economic Regional Focus Simulation 3";
$str[0]{'A2x'} = "Economic Regional Focus Ensemble Mean";
$str[0]{'B21'} = "Environmental Regional Focus Simulation 1";
$str[0]{'B22'} = "Environmental Regional Focus Simulation 2";
$str[0]{'B23'} = "Environmental Regional Focus Simulation 3";
$str[0]{'B2x'} = "Environmental Regional Focus Ensemble Mean";
$str[0]{'B11'} = "Environmental Global Focus Simulation 1";
$str[0]{'A11'} = "Economic Global Focus Simulation 1";
$str[0]{'A1T'} = "Economic Global Focus Non-Fossil-Fuel Transition Simulation 1";
$str[0]{'A1FI'} = "Economic Global Focus Fossil-Fuel Intensive Simulation 1";
$str[1]{'ga1'} = "Simulation 1 - Gaz à effet de serre avec aérosols";
$str[1]{'ga2'} = "Simulation 2 - Gaz à effet de serre avec aérosols";
$str[1]{'ga3'} = "Simulation 3 - Gaz à effet de serre avec aérosols";
$str[1]{'ga4'} = "Simulation 4 - Gaz à effet de serre avec aérosols";
$str[1]{'gax'} = "Simulation moyenne - Gaz à effet de serre avec aérosols";
$str[1]{'gg1'} = "Simulation 1 - Gaz à effet de serre seulement";
$str[1]{'gg2'} = "Simulation 2 - Gaz à effet de serre seulement";
$str[1]{'gg3'} = "Simulation 3 - Gaz à effet de serre seulement";
$str[1]{'gg4'} = "Simulation 4 - Gaz à effet de serre seulement";
$str[1]{'ggx'} = "Simulation moyenne - Gaz à effet de serre seulement";
$str[1]{'A21'} = "Economic Regional Focus Simulation 1";
$str[1]{'A22'} = "Economic Regional Focus Simulation 2";
$str[1]{'A23'} = "Economic Regional Focus Simulation 3";
$str[1]{'A2x'} = "Economic Regional Focus Ensemble Mean";
$str[1]{'B21'} = "Environmental Regional Focus Simulation 1";
$str[1]{'B22'} = "Environmental Regional Focus Simulation 2";
$str[1]{'B23'} = "Environmental Regional Focus Simulation 3";
$str[1]{'B2x'} = "Environmental Regional Focus Ensemble Mean";
$str[1]{'B11'} = "Environmental Global Focus Simulation 1";
$str[1]{'A11'} = "Economic Global Focus Simulation 1";
$str[1]{'A1T'} = "Economic Global Focus Non-Fossil-Fuel Transition Simulation 1";
$str[1]{'A1FI'} = "Economic Global Focus Fossil-Fuel Intensive Simulation 1";

# FIXME CHECK THESE
$str[0]{varerrmsg} = "Warning: Experiment does not have this variable available. Default chosen.";
$str[1]{varerrmsg} = "Avertissement : L'exp&eacute;rience n'a pas cette variable disponible. D&eacute;faut choisi.";

$str[0]{tserrmsg} = "Warning: Experiment does not have this timeslice available. Default chosen.";
$str[0]{tserrmsg} = "Avertissement : L'exp&eacute;rience n'a pas cette période disponible. D&eacute;faut choisi.";
return 1;
