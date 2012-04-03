package CICS::Scenario::Config;
use strict;

our(@dat);

my($host) = 1;

## Hash indexed data
# 0 is English, 1 is French, 2 is Data, anything beyond 2 is extended data

# Mapping from model names to long names
$dat[0]{'model'} = 
  { 
   "ccsrnies" => "Center for Climate Research - National Institute for Environmental Studies",
   "cgcm1" => "Canadian Centre for Climate Modelling and Analysis Global Coupled Model 1",
   "cgcm2" => "Canadian Centre for Climate Modelling and Analysis Global Coupled Model 2",
   "cgcm3" => "Canadian Centre for Climate Modelling and Analysis Global Coupled Model 3",
   "csiromk2b" => "Commonwealth Scientific Industrial Research Organization Mk2",
   "echam4" => "ECHAM4",
   "gfdlr15" => "Geophysical Fluid Dynamics Laboratory R15",
   "gfdlr30" => "Geophysical Fluid Dynamics Laboratory R30",
   "hadcm2" => "Hadley Centre Coupled Model 2",
   "hadcm3" => "Hadley Centre Coupled Model 3",
   "ncarpcm" => "National Center for Atmospheric Research",
  };

# FIXME - LANG
$dat[1]{'model'} = 
  { 
   "ccsrnies" => "Center for Climate Research - National Institute for Environmental Studies",
   "cgcm1" => "Canadian Centre for Climate Modelling and Analysis Global Coupled Model 1",
   "cgcm2" => "Canadian Centre for Climate Modelling and Analysis Global Coupled Model 2",
   "cgcm3" => "Canadian Centre for Climate Modelling and Analysis Global Coupled Model 3",
   "csiromk2b" => "Commonwealth Scientific Industrial Research Organization Mk2",
   "echam4" => "ECHAM4",
   "gfdlr15" => "Geophysical Fluid Dynamics Laboratory R15",
   "gfdlr30" => "Geophysical Fluid Dynamics Laboratory R30",
   "hadcm2" => "Hadley Centre Coupled Model 2",
   "hadcm3" => "Hadley Centre Coupled Model 3",
   "ncarpcm" => "National Center for Atmospheric Research",
  };

if ($host == 0) {
  # Path to add for this model's data
  $dat[2]{'model'} = 
    {
     "ccsrnies" => "ccsrnies_Change_fields/",
     "cgcm1" => "cgcm1_Change_fields/",
     "cgcm2" => "cgcm2_Change_fields/",
     "cgcm3" => "",
     "csiromk2b" => "csiromk2b_Change_fields/",
     "echam4" => "echam4_Change_fields/",
     "gfdlr15" => "gfdlr15_Change_fields/",
     "gfdlr30" => "gfdlr30_Change_fields/",
     "hadcm2" => "hadcm2_Change_fields/",
     "hadcm3" => "hadcm3_Change_fields/",
     "ncarpcm" => "ncarpcm_Change_fields/",
    };
} elsif ($host == 1) {
  # Path to add for this model's data
  $dat[2]{'model'} = 
    {
     "ccsrnies" => "2002/ccsrnies_Change_fields/",
     "cgcm1" => "2002/cgcm1_Change_fields/",
     "cgcm2" => "2002/cgcm2_Change_fields/",
     "cgcm3" => "",
     "csiromk2b" => "2002/csiromk2b_Change_fields/",
     "echam4" => "2002/echam4_Change_fields/",
     "gfdlr15" => "2002/gfdlr15_Change_fields/",
     "gfdlr30" => "2002/gfdlr30_Change_fields/",
     "hadcm2" => "2002/hadcm2_Change_fields/",
     "hadcm3" => "2002/hadcm3_Change_fields/",
     "ncarpcm" => "2002/ncarpcm_Change_fields/",
    };
}

# Model data from who (URL)
$dat[3]{'model'} = 
  {
   "ccsrnies" => "<a href=\"http://ipcc-ddc.cru.uea.ac.uk\" target=\"_new\">IPCC-DDC</a>",
   "cgcm1" => "<a href=\"http://www.cccma.bc.ec.gc.ca/\" target=\"_new\">CCCma</a>",
   "cgcm2" => "<a href=\"http://www.cccma.bc.ec.gc.ca/\" target=\"_new\">CCCma</a>",
   "cgcm3" => "<a href=\"http://www.cccma.bc.ec.gc.ca/\" target=\"_new\">CCCma</a>",
   "csiromk2b" => "<a href=\"http://ipcc-ddc.cru.uea.ac.uk\" target=\"_new\">IPCC-DDC</a>",
   "echam4" => "<a href=\"http://ipcc-ddc.cru.uea.ac.uk\" target=\"_new\">IPCC-DDC</a>",
   "gfdlr15" => "<a href=\"http://ipcc-ddc.cru.uea.ac.uk\" target=\"_new\">IPCC-DDC</a>",
   "gfdlr30" => "<a href=\"http://ipcc-ddc.cru.uea.ac.uk\" target=\"_new\">IPCC-DDC</a>",
   "hadcm2" => "<a href=\"http://ipcc-ddc.cru.uea.ac.uk\" target=\"_new\">IPCC-DDC</a>",
   "hadcm3" => "<a href=\"http://ipcc-ddc.cru.uea.ac.uk\" target=\"_new\">IPCC-DDC</a>",
   "ncarpcm" => "<a href=\"http://ipcc-ddc.cru.uea.ac.uk\" target=\"_new\">IPCC-DDC</a>",
  };

# Range covered by each model for each region
# [ World, Canada, North America ]
# [ [Min Lat, Max Lat, Min Lon, Max Lon], [Min Lat, Max Lat, Min Lon, Max Lon] ]
$dat[4]{'model'} = 
  {
   "ccsrnies" => [ [ -90, 90, -181.875, 178.125], [ 38.764503, 88.507004, -171.562500, -36.562500 ], [ 5.537800, 88.506500, -171.562500, -36.562500 ] ],
   "cgcm1" => [ [ -90, 90, -181.875, 178.125], [ 40.822502, 88.998993, -170.625000, -39.375000 ], [ 3.711100, 88.999207, -170.625000, -39.375000 ] ],
   "cgcm2" => [ [ -90, 90, -181.875, 178.125], [ 40.822502, 88.998993, -170.625000, -39.375000 ], [ 3.711100, 88.999207, -170.625000, -39.375000 ] ],
   "cgcm3" => [ [ -90, 90, -181.875, 178.125], [ 40.822502, 88.998993, -170.625000, -39.375000 ], [ 3.711100, 88.999207, -170.625000, -39.375000 ] ],
   "csiromk2b" => [ [ -90, 90, -181.875, 178.125], [ 41.414497, 89.140495, -171.562500, -36.562500 ], [ 6.371450, 89.140854, -171.562500, -36.562500 ] ],
   "echam4" => [ [ -90, 90, -181.875, 178.125], [ 39.069000, 89.248001, -170.156494, -37.969002 ], [ 5.581200, 89.247452, -170.156250, -37.968750 ] ],
   "gfdlr15" => [ [ -90, 90, -181.875, 178.125], [ 39.995998, 88.801498, -176.250000, -33.750000 ], [ 4.444150, 88.801544, -176.250000, -33.750000 ] ],
   "gfdlr30" => [ [ -90, 90, -181.875, 178.125], [ 40.247551, 89.397049, -174.375000, -35.625000 ], [ 4.472050, 89.397049, -174.375000, -35.625000 ] ],
   "hadcm2" => [ [ -90, 90, -181.875, 178.125], [ 38.750000, 88.750000, -170.625000, -39.375000 ], [ 6.250000, 88.750000, -170.625000, -39.375000 ] ],
   "hadcm3" => [ [ -90, 90, -181.875, 178.125], [ 38.750000, 88.750000, -170.625000, -39.375000 ], [ 6.250000, 88.750000, -170.625000, -39.375000 ] ],
   "ncarpcm" => [ [ -90, 90, -181.875, 178.125], [ 39.069000, 89.248001, -170.156494, -37.969002 ], [ 5.581200, 89.247452, -170.156250, -37.968750 ] ]
  };

if ($host == 0) {  # uh maybe ignore this because it doesn't do anything sane
  # More or less general variable
  my($pfw) = "/home/bronaugh/public_html/scen-access/";
  my($pfd) = "/home/bronaugh/cics/";
  $dat[2]{'gcminfofile'} = $pfw . "126.csv";
  $dat[2]{'regionfile'} = $pfw . "regions.csv";
  $dat[2]{'genimage'} = "/usr/local/bin/genimage";
  $dat[2]{'datapath'} = "/~bronaugh/data/";
  $dat[2]{'errimgdir'} = $pfw . "err_imgs/";
  $dat[2]{'wrapper'} = '/scen/wrapper';
  $dat[2]{'timeseriesdir_www'} = '/scenarios2/data/timeseries/';
  $dat[2]{'timeseriesdir_local'} = '/scenarios2/data/timeseries/';
  $dat[2]{'mcachedir'} = $pfw . 'cache/maps/';
  $dat[2]{'dcachedir'} = $pfw . 'cache/data/';
  $dat[2]{'zcachedir'} = $pfw . 'cache/zips/';
  $dat[2]{'tmpdir'} = $pfw . 'cache/temp/';
  $dat[2]{'maccesslog'} = $pfw . 'logs/access.log';
  $dat[2]{'zipcmd'} = "/usr/bin/zip";
  $dat[2]{'contact_email'} = 'bronaugh@localhost';
  $dat[2]{'email_from'} = 'bronaugh@uvic.ca';
  $dat[2]{'template'} = $pfw . 'explorer.tpl';

  # Slated for removal
  $dat[2]{'datadir'} = "/home/bronaugh/data/nc/";

} elsif ($host == 1) {
  my($pfd) = "/home/data3/modperl/scenarios-windy/";
  my($pfw) = "/tools/";
  $dat[2]{'gcminfofile'} = $pfd . "136.csv";
  $dat[2]{'regionfile'} = $pfd . "regions-new.csv";
  $dat[2]{'template'} = $pfd . 'explorer.tpl';

  $dat[2]{'planners_regionfile'} = $pfd . "planners-analysis-regions.csv";
  $dat[2]{'planners_impacts_template'} = $pfd . 'impacts.tpl';
  $dat[2]{'planners_rules_template'} = $pfd . 'rules.tpl';
  $dat[2]{'planners_template'} = $pfd . 'planners.tpl';
  $dat[2]{'planners_desclist'} = $pfd . 'planners-desclist.csv';  # TODO unused right now, make it so!
  $dat[2]{'planners_tab_template'} = $pfd . 'planners-tab.tpl';
  $dat[2]{'planners_vars_csv'} = $pfd . 'planners-vars.csv';
  $dat[2]{'planners_impacts_csv'} = $pfd . 'planners-impacts-v7.csv';

  $dat[2]{'genimage'} = "/usr/local/bin/genimage";
  $dat[2]{'datapath'} = $pfw;
  $dat[2]{'errimgdir'} = $pfd . "err_imgs/";
  $dat[2]{'wrapper'} = $pfw . 'wrapper';
  $dat[2]{'timeseriesdir_www'} = $pfw . 'data/timeseries/';
  $dat[2]{'timeseriesdir_local'} = '/home/websites/www.cics.uvic.ca/htdocs/scenarios/data/timeseries/';
  $dat[2]{'mcachedir'} = $pfd . 'cache/maps/';
  $dat[2]{'dcachedir'} = $pfd . 'cache/data/';
  $dat[2]{'zcachedir'} = $pfd . 'cache/zips/';
  $dat[2]{'maccesslog'} = $pfd . 'logs/access.log';
  $dat[2]{'zipcmd'} = "/usr/bin/zip";
  $dat[2]{'contact_email'} = 'tmurdock@uvic.ca,bronaugh@uvic.ca';
  $dat[2]{'email_from'} = 'tmurdock@uvic.ca';

  # Slated for removal
  $dat[2]{'datadir'} = "/home/websites/www.cics.uvic.ca/htdocs/scenarios/data/";

}

$dat[2]{max_plots} = 2000;
$dat[2]{max_scatterplots} = 500;

return 1;
