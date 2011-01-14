package CICS::Scenario::Planners;
use strict;

use CICS::Helpers;
use CICS::Scenario::Data;
use CICS::Scenario::Config;
use CICS::Scenario::Cache;
use CICS::Scenario::MainForm_Planners;
use CICS::Scenario::Helpers;
use CICS::Scenario::Regions;
#use CICS::Scenario::Displayer;
use CICS::Scenario::Displayer_Planners;

use POSIX qw(floor);

use CGI;
use Apache2::Const qw(OK);
use APR::URI ();
use Apache2::Util;
use Apache2::RequestRec;

use Carp;
$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__} = \&Carp::cluck;

use Data::Dumper;

sub handler {
  my($r) = shift();
  my($q) = CGI->new($r->args());
  my($args);
  %{$args} = $q->Vars;

  # Let the world know which module this is (clean up later)
  $args->{planners} = 1;  #PI

  $r->content_type('text/html');

  # Default important stuff
  if(!defined($args->{lang})) {
    $args->{lang} = 0;
  } else {
    my(@langs) = ( 0, 1 );
    if(defined($langs[$args->{lang}])) {
      $args->{lang} = $langs[$args->{lang}];
    } else {
      # Defaults
      $args->{lang} = 0;
      $args->{ocean} = 1;
    }
  }
  if(!defined($args->{expt})) {
      if(defined($args->{planners})) {  #PI -- this is a single-point decision and should net a config structure from which all of these things are pulled...
	  $args->{expt} = 11; # 203;  # this is irrelevant for plots, but will get used for summary etc
      } else {
	  $args->{expt} = 11;
      }
  }

  my($regions);
  if(defined($args->{planners})) {
      $regions = loadRegions($CICS::Scenario::Config::dat[2]{'planners_regionfile'}, $args->{lang});  #PI
  } else {
      $regions = loadRegions($CICS::Scenario::Config::dat[2]{'regionfile'}, $args->{lang});
  }

  my($expt, $exptmulti, $exptdata) = load_gcminfo($CICS::Scenario::Config::dat[2]{gcminfofile}, \@CICS::Scenario::Data::dat);
  my($hash) =
  { expt => $expt,
    exptmulti => $exptmulti,
    exptdata => $exptdata,
    str => \@CICS::Scenario::Data::str,
    dat => \@CICS::Scenario::Data::dat,
    cfg => \@CICS::Scenario::Config::dat,
    lang => $args->{lang},
    post => $args,
    prs => getRegionList($regions, $args->{lang}),
    regions => $regions,
    action => $r->uri
      };

  my($cache) = CICS::Scenario::Cache->new($hash);
  $hash->{cache} = $cache;

  my($mainform) = CICS::Scenario::MainForm_Planners->new($hash);
  $hash->{mainform} = $mainform;

  my($inputdata) = $mainform->get_postdata();
  my($descriptions) = $mainform->make_desc_list();
  my($displayer) = CICS::Scenario::Displayer_Planners->new($hash);   #PI
  my($template_hash) = {};
  $mainform->addElements($template_hash);


  # Reverse lookup table to allow codification of constants as strings instead of numbers
  my $lookup_by_symname = {};
  $lookup_by_symname->{'var'} = {};
  @{$lookup_by_symname->{'var'}}{@{$hash->{'dat'}[2]{'variable'}}} = (0..(@{$hash->{'dat'}[2]{'variable'}} - 1));
  $lookup_by_symname->{'toy'} = {};
  @{$lookup_by_symname->{'toy'}}{@{$hash->{'dat'}[3]{'timeofyear'}}} = (0..(@{$hash->{'dat'}[3]{'timeofyear'}} - 1));



  #################
  ## Planners... ##
  #################

  my($basedesc) = {%{$descriptions->[0]}, region => 3, };  # something to mangle to set up all the other plots

  if($basedesc->{pr} != 0) { #FIXME HACK fixing gridbox coverage issues, for now...
    $basedesc->{ocean} = 1;
  }

  my($planners_descs);
  $template_hash->{'planners_vardivs'} = "";

  # Text to be used here and there
  $template_hash->{'var:toy'} = $hash->{'dat'}->[$hash->{'lang'}]->{'timeofyear'}->[$basedesc->{'toy'}];
  $template_hash->{'var:ts'} = $hash->{'mainform'}->{'ts'}->[$basedesc->{'ts'}];
  $template_hash->{'var:ts_period'} = substr($template_hash->{'var:ts'}, 0, 5);
  $template_hash->{'var:region'} = $hash->{'mainform'}->{'prs'}->[$basedesc->{'pr'}];

  # Images for each tab
  my $planners_plots = [ [ {plot_type => TYPE_MAP, res => 3,         expt => 209, ts => 0, ts_d => 0, region => 5},
			   {plot_type => TYPE_MAP, res => 3,         expt => 204, region => 5},
			   {plot_type => TYPE_STICKPLOT,             expt => 11,  sset => 280, zoom => 0, baseline_expt => 217} ],
			 {plot_type => TYPE_BANDS_TIMESLICE_HIST,  expt => 11, sset => 280, zoom => 0, baseline_expt => 217}    ];

  my($planners_plotdat_basedesc) = mod_desc_with_params($basedesc, { plot_type => TYPE_SCATTER_TIMESLICE_TEXT, expt => 280, sset => 280, baseline_expt => 217});

  # Plot data (and resulting formatted data) caching, containing things like mam_prec_50p (and consequently data:mam_prec_50p in $template_hash)
  my $planners_plotdat = {};  # This ends up containing things (keys) like mam_prec_50p, etc., containing values (as opposed to formatted text of those values)
  my $planners_plotdat_cache = [ $cache,
				 $planners_plotdat_basedesc,
				 substr( $hash->{'mainform'}->{'ts'}->[$basedesc->{'ts'}], 0, 4 ),
				 $planners_plotdat,
				 $template_hash,
				 $lookup_by_symname,
				 $hash->{'dat'}[8]{'variable'} ];


  ############################
  ## Variable speficiations ##
  ############################
  my $planners_vars_csv = parse_csv($hash->{cfg}->[2]->{'planners_vars_csv'});
  $planners_vars_csv->{'var'} = [ map { $lookup_by_symname->{'var'}->{$_} } @{$planners_vars_csv->{'symname'}} ];
  my $planners_vars = transpose_csv_hash($planners_vars_csv);

  #############################################################
  ## Loop through vars, set up tabs, specs for zoomed images ##
  #############################################################
  for my $var_hash (@{$planners_vars}) {  #TODO almost everything moves into here...
    my $var_basedesc = { %{$basedesc}, var => $var_hash->{'var'} };
    print STDERR "var_basedesc is for variable " . $var_basedesc->{var} . "\n";

    # Build dynamically-loaded image URL descs
    push( @{$planners_descs}, @{make_descs_from_list($var_basedesc, $planners_plots)} );

    # Build content div -- conveniently all of these start out hidden.
    my $tab_template_hash = {%{$var_hash}, toy => $template_hash->{'var:toy'}, region => $template_hash->{'var:region'}, ts => $template_hash->{'var:ts'}, ts_period => $template_hash->{'var:ts_period'}, lc_varname => lc($var_hash->{'uc_varname'})};
    $tab_template_hash->{'scatter_link'} = $displayer->make_url_from_desc(mod_desc_with_params($var_basedesc, { plot_type => TYPE_SCATTER_TIMESLICE_TEXT,  expt => 280, sset => 280, baseline_expt => 217}));

    $template_hash->{'planners_vardivs'} .= parseTemplate($hash->{cfg}->[2]->{'planners_tab_template'}, $tab_template_hash, $planners_plotdat_cache);
  }

  # Zoomed image tags
  $template_hash->{planners_content} = join(', ', map { "'" . $_ . "'" } @{$displayer->make_html_from_desclist($planners_descs)});


  ###################  DECTODO
  ## Impacts Table ##
  ###################

  # Conditionals and resulting table rows -- TODO needs to be read from a file
  my($summary_row_metadata) = [
#    ["0.20<=ann_temp_10p & 1.00<=ann_temp_50p & 1.00<=ann_temp_90p" , "<td>Warmer annual temperature</td><td><ul><li>Glacier retreat (if applicable)</li><li>Changes in seasonality of streamflow</li><li>Increased evaporation</li></ul></td>"],
#    ["0.50<=jja_temp_10p & 1.25<=jja_temp_50p & 1.25<=jja_temp_90p" , "<td>Summer warming</td><td><ul><li>Higher temperatures encourage the growth of unfavorable algae and bacteria, adversely impacting water quality"
#                                                                    . "</li><li>Longer fire seasons may result in more interface fires that threaten communities and infrastructure</li></ul></td>"],
#    ["0.50<=djf_temp_10p & 1.25<=djf_temp_50p & 1.25<=djf_temp_90p" , "<td>Winter warming</td><td><ul><li>Mid-winter thaw events may damage roads and cause ice jams and flooding with damage to infrastructure such as bridges</li></ul></td>"],
#    ["0.00<=djf_prec_10p & 7.00<=djf_prec_50p & 15.0<=djf_prec_90p" , "<td>Considerably wetter conditions projected in winter</td>"
#                                                                    . "<td>Higher winter streamflows and extreme precipitation events may damage infrastructure, cause flooding, or increase the risks of more severe or more frequent floods and landslides"
#                                                                    . "</li><li>Increase in storm events a concern for infrastructure</li></ul></td>"],
#    ["-5.0<=jja_prec_10p & 5.00<=jja_prec_50p & 10.0<=jja_prec_90p" , "<td>Most projections for wetter summer</td><td><ul><li>Increased consecutive days of rain could cause summer flooding in normally dry areas</li></ul></td>"],
#    ["jja_prec_10p<=-10.0 & jja_prec_50p<=-1.0 & jja_prec_90p<=5.00" , "<td>Most projections for drier summer</td><td><ul><li>Increased drought</li><li>Possible declines in recharge rates for groundwater sources</li></ul></td>"],
#    ["0.20<=jja_temp_10p & 1.00<=jja_temp_50p & 1.00<=jja_temp_90p & jja_prec_10p<=-10.0 & jja_prec_50p<=-1.0 & jja_prec_90p<=5.00" , "<td>Warmer, drier summers</td>"
#                                                                    . "<td><ul><li>Possibility of more prolonged and intense droughts with lower water supply during periods of peak demand"
#                                                                    . "</li><li>Reduced soil moisture and increased evaporation, increasing irrigation needs at the same time of year that streamflows are expected to decline"
#                                                                    . "</li><li>Improved potential for high value crops, if sufficient water is available; warmer temperatures may favour weeds, insects and plant diseases</li></ul></td>"],
    ["0.20<=ann_temp_10p & 1.00<=ann_temp_50p & 1.00<=ann_temp_90p" , "<td>Warmer annual temperature</td><td><ul><li>Glacier retreat (if applicable)</li><li>Changes in seasonality of streamflow</li><li>Increased evaporation"
                                                                    ."</li><li>Longer fire seasons may result in more interface fires that threaten communities and infrastructure</li></ul></td>"],
    ["0.50<=djf_temp_10p & 1.25<=djf_temp_50p & 1.25<=djf_temp_90p" , "<td>Winter warming</td><td><ul><li>Mid-winter thaw events may damage roads and cause ice jams and flooding with damage to infrastructure such as bridges</li></ul></td>"],
    ["0.00<=djf_prec_10p & 7.00<=djf_prec_50p & 15.0<=djf_prec_90p" , "<td>Considerably wetter conditions projected in winter</td>"
                                                                    . "<td><ul><li>Higher winter streamflows and extreme precipitation events may damage infrastructure, cause flooding, or increase the risks of more severe or more frequent floods and landslides"
                                                                    . "</li><li>Increase in storm events a concern for infrastructure</li></ul></td>"],
    ["-5.0<=jja_prec_10p & 5.00<=jja_prec_50p & 10.0<=jja_prec_90p" , "<td>Wetter summers</td><td><ul><li>Increased consecutive days of rain could cause summer flooding in normally dry areas</li></ul></td>"],
    ["0.20<=jja_temp_10p & 1.00<=jja_temp_50p & 1.00<=jja_temp_90p & jja_prec_10p<=-10.0 & jja_prec_50p<=-1.0 & jja_prec_90p<=5.00" , "<td>Warmer, drier summers</td>"
                                                                    . "<td><ul><li>Possibility of more prolonged and intense droughts with lower water supply during periods of peak demand"
                                                                    . "</li><li>Reduced soil moisture and increased evaporation, increasing irrigation needs at the same time of year that streamflows are expected to decline"
                                                                    . "</li><li>Higher temperatures encourage the growth of unfavorable algae and bacteria, adversely impacting water quality"
                                                                    . "</li><li>Possible declines in recharge rates for groundwater sources"
                                                                    . "</li><li>Improved potential for high value crops, if sufficient water is available; warmer temperatures may favour weeds, insects and plant diseases</li></ul></td>"],
  ];

  ## Header Row
  $template_hash->{'planners_summary_table'}  = "<table>\n";
  $template_hash->{'planners_summary_table'} .= '<tr class="dkerblue"><th colspan="2">Potential Impacts for the ' . $template_hash->{'var:region'} . ' region in ' . $template_hash->{'var:ts_period'} . " period</th></tr>\n";
  $template_hash->{'planners_summary_table'} .= '<tr class="dkblue"><th>Projections and Variability Effects</th><th>Potential Impacts</th></tr>' . "\n";

  # Impacts Rows
  my $expression_success_count = 0;
  foreach my $row (@$summary_row_metadata) {
    if(test_expression($row->[0], $planners_plotdat_cache)) {
      $expression_success_count++;
      $template_hash->{'planners_summary_table'} .= (($expression_success_count % 2) ? '<tr class="ltblue">' : '<tr>') . $row->[1] .  '</tr>' . "\n";
    }
  }
  if ($expression_success_count == 0) {
    $template_hash->{'planners_summary_table'} .= '<tr><td style="text-align: center;">-</td><td style="text-align: center;">-</td><tr>' . "\n";
  }
  $template_hash->{'planners_summary_table'} .= "</table>\n";

  ###################
  ## Summary Table ##
  ###################
#  HARDCODED  $template_hash->{'planners_variable_table'}  = '<tr class="dkerblue"><th colspan="3">Climate Change Summary for the ' . $template_hash->{'var:region'} . ' region in ' . $template_hash->{'var:ts'} . ' period</th></tr>';
#  $template_hash->{'planners_variable_table'} .= '<tr class="dkblue"><th>Variable</th><th>Time of Year</th><th>Future Change for ' . $template_hash->{'var:ts'} .'</th></tr>';
#  HARDCODED  $template_hash->{'planners_variable_table'} .= '<tr class="dkblue"><th>Variable</th><th>Time of Year</th><th>Projected change from 1961-1990 baseline</th></tr>';






#NOT MUCH IN THIS SECTION IS NEEDED IN PLANNERS, BUT SOME IS    TODO:  GUTME/REPLACEME

  # Used to accumulate the weighted means so we can crunch out
  # 10th, 50th (median) and 90th percentiles.
  my (@accum_wmean);

  # Figure out how the grouping should go
  my($title_t, $list_t, $deschdr, @list, @title, %old);
  {
    # Note about this section: It is coupled to MainForm.pm's make_desc_list
    # The order generated by make_desc_list and the order below must match.
    # Both the GATHER and the MAKEHEADERS block must use the -opposite- order
    # to which the multivars are processed in make_desc_list.
    #
    # To change the order:
    # 1) Rearrange the GATHER block so that the @vars, @vars2, and @descs arrays
    #    contain the data in the correct order
    # 2) Rearrange the items in the 'foreach' statement in the MAKEHEADERS
    #    block to match this
    # 3) Ensure that this is the -opposite- order to that used in
    #    make_desc_list.
    my($i) = 0;
    my(@listvars, @titlevars, @vars, @vars2, @descs, @foo);

    # BLOCK NAME: GATHER
    # Gather up a coherent list of data items for use in next loop
    push(@vars, $hash->{expt});
    push(@vars2, $hash->{exptmulti});
    push(@descs, $hash->{str}->[$hash->{lang}]->{experiment});
    foreach(qw(timeofyear timeslice variable)) {
      push(@vars, $hash->{dat}->[$hash->{lang}]->{$_});
      push(@vars2, $hash->{dat}->[2]->{$_});
      push(@descs, $hash->{str}->[$hash->{lang}]->{$_});
    }

    # BLOCK NAME: MAKEHEADERS
    # Run through all potential multivars
    foreach(qw(expt toy ts var)) {
      my($var) = $_;
      $old{$var} = -1;
      # Put up to 2 multivars as the "list" vars -- names shown in the list
      if(is_multivar($vars2[$i]->[$inputdata->{$var}]) && $#listvars < 1) {
	push(@listvars, "<%" . $var . "%>");
	push(@list, [ $var, $i, $vars[$i], $descs[$i] ]);
	push(@foo, $descs[$i]);
      } else {
	# Put the remainder in the "title" vars -- stuff to title things up
	push(@titlevars, "<%" . $var . "%>");
	push(@title, [ $var, $i, $vars[$i], $descs[$i] ]);
      }
      $i++;
    }

    # Reverse the title and list headers' display ordering.
    @title = reverse(@title);
    @list = reverse(@list);

    # Put together the templates
    $list_t = (($#listvars == -1) ? "" : join(" - ", reverse(@listvars)));
    $title_t = join(" - ", reverse(@titlevars));
    $deschdr = (($#listvars == -1) ? "Name" : join(" and<br> ", reverse(@foo)));
  }




  # FIXME this is needed multiple times in planners; perhaps it should just be part of the image tag code e.g. s/$/<br/><span style="...: right;"><a href...></span>/....
  # Output metadata CSV link
  my($desc);
  %{$desc} = %{$inputdata};
  $desc->{plot_type} = TYPE_METADATA_CSV;
  $template_hash->{md_csvlink} = "<a href=\"".$hash->{cfg}->[2]->{wrapper}."?".mkgetstring($desc)."\" alt=\"Metadata CSV\"/>Metadata CSV</a>";

  # Run through the plot descriptions and plot them (up to max)
  my($itemhash, @bits, @diffmaps, @dataitems, @metadataitems, @modeldataitems, @modelmetadataitems, $i, $model);
  my($max) = $hash->{cfg}->[2]->{max_plots};
  push(@modeldataitems, $displayer->make_modeldata_header());
  push(@modelmetadataitems, $displayer->make_modelmetadata_header());
  my(%modelhash);

  # Iterate over every description up to maximum number.
  my($num_descriptions) = ($#{$descriptions} + 1 < $max) ? $#{$descriptions} + 1: $max;

  my($olddesc);
  for($i = 0; $i < $num_descriptions; $i++) {
    my($desc) = $descriptions->[$i];
    
    # Grab in the plot data from genimage
    $displayer->{plotdat} = CICS::Scenario::Helpers::parse_textdata($cache->create_cachefile($desc, TYPE_TEXT));

    
    # Put items into template hash
    foreach(@title, @list) {
      $itemhash->{$_->[0]} = $_->[2]->[$desc->{$_->[0]}];
    }
    
    # Generate title and row desc
    my($title) = ""; #  DEBUG parseTemplateString($title_t, $itemhash);
    my($list) = "";#  DEBUG parseTemplateString($list_t, $itemhash);
    
    if(defined($displayer->{plotdat}->{error})) {
      push(@bits, $displayer->make_error_img($desc));
      push(@metadataitems, $displayer->make_metadata_error_row($desc, $list));
      push(@dataitems, $displayer->make_data_error_row($desc, $list));
    } else {
      if($i == 0) {
	$template_hash->{regioncontent} = $displayer->make_region_img($desc);   #PITODO  need to dupe this based on some metadata specifying all of the different required plot types
      }
      push(@bits, $displayer->make_display_img($desc, 0));
      if(($desc->{ts} != $desc->{ts_d} || $desc->{toy} != $desc->{toy_d} || $desc->{expt_d} != $desc->{expt}) && ($desc->{ts} * $desc->{ts_d} || ($desc->{ts} == $desc->{ts_d} && $desc->{ts} == 0))) {
	push(@diffmaps, $displayer->make_difference_img($desc));
      }
      my($changedmodel, $changed, $rowheader, $exptchanged, $anythingbutexptchanged) = (0, 0, 0, 0, 0);

      # Figure out what vars changed
      my($j) = 0;
      if($#metadataitems == -1) {
	$rowheader = 1;
      }
      foreach(@title, @list) {
	# If something changed
	if($old{$_->[0]} != $desc->{$_->[0]}) {
	  if ($_->[0] eq "expt") {
	    $exptchanged = 1;
	  } else {
	    $anythingbutexptchanged = 1;
	  }
	  if($j <= $#title) {
	    # Title var changed
	    $changed = 1;
	  }
	  my($modelname) = $hash->{exptdata}->[$desc->{$_->[0]}]->{modelname};
	  my($oldmodelname) = $hash->{exptdata}->[$old{$_->[0]}]->{modelname};
	  if($_->[0] eq "expt" && ($old{$_->[0]} == -1 || $modelname ne $oldmodelname) && !defined($modelhash{$modelname})) {
	    # Model changed; output title and model description/data
	    $changedmodel = 1;
	    $model = uc($hash->{exptdata}->[$desc->{$_->[0]}]->{modelname});
	    $modelhash{$modelname} = 1;
	  }
	  $old{$_->[0]} = $desc->{$_->[0]};
	}
	$j++;
      }

      # Add stuff, dependent on variables
      if($changed) {
	push(@metadataitems, $displayer->make_metadata_vars_header($desc, $title));
	push(@dataitems, $displayer->make_data_vars_header($desc, $title));
	if($rowheader) {
	  push(@metadataitems, $displayer->make_metadata_row_header($desc, $deschdr));
	  push(@dataitems, $displayer->make_data_row_header($desc, $deschdr));
	}
      }
      if($changedmodel) {
	push(@modelmetadataitems, $displayer->make_modelmetadata_row($desc, $model));
	push(@modeldataitems, $displayer->make_modeldata_row($desc, $model));
      }

      # Print out percentiles for groups of metadata
      if($desc->{md_pctile}) {
	if ($i != 0) {  # Don't print percentiles on first row!
	  if ($anythingbutexptchanged) { # Only print when there is a change
	    push(@metadataitems, $displayer->get_percentile_rows($olddesc, \@accum_wmean));
	    @accum_wmean = ();
	  }
	}
	push(@accum_wmean, $displayer->{plotdat}->{selwmean});
      }
      push(@metadataitems, $displayer->make_metadata_row($desc, $list));
      push(@dataitems, $displayer->make_data_row($desc, $list));
    }
    $olddesc = $desc;
  }

  # Don't forget to print  metadata percentiles for the very last group of metadata.
  if ($desc->{md_pctile} && $i != 0) {
    push(@metadataitems, $displayer->get_percentile_rows($desc, \@accum_wmean));
  }

  # Set maps as visible
  $template_hash->{mapsclass} = "shown";
  
  # If we've reached the max # of plots, prepare a warning message
  my($too_many_plots) = "";
  if($i == $max) {
    $too_many_plots = "<br/>" . $hash->{str}->[$hash->{lang}]->{too_many_plots};
  }

  # If no region and type of scatter plot is by region, warn user
  {
    my(@scattertsdescs) = @{$mainform->make_scatterts_desc_list()};
    my(@scattervardescs) = @{$mainform->make_scattervar_desc_list()};
    my(@points) = split(/,/, $olddesc->{points});

    # Initialize strings, informing user if average is over entire map
    if($#points == 0) {
      $template_hash->{boxplottscontent} = $template_hash->{scattertscontent} =
	$template_hash->{scattervarcontent} = "<h3>Note: Displaying data point</h3>";
    } elsif($#points < 2) {
      $template_hash->{boxplottscontent} = $template_hash->{scattertscontent} =
	$template_hash->{scattervarcontent} = "<h3>Note: Displaying average over entire map</h3>";
    } else {
      $template_hash->{boxplottscontent} = $template_hash->{scattertscontent} = $template_hash->{scattervarcontent} = "";
    }

    {
      my($i);
      my($max) = $hash->{cfg}->[2]->{max_scatterplots};

      # Plot all the appropriate scatterplots
      for($i = 0; $i <= $#scattertsdescs && $i < $max; $i++) {
	my($desc) = $scattertsdescs[$i];
	$template_hash->{scattertscontent} .= $displayer->make_scatterts_img($desc);
	$template_hash->{boxplottscontent} .= $displayer->make_boxplotts_img($desc);
	if($desc->{sptsdata}) {
	  $template_hash->{scattertstext} .= $displayer->make_scatterts_text($desc);
	}
	if($desc->{spbpdata}) {
	  $template_hash->{boxplottstext} .= $displayer->make_boxplotts_text($desc);
	}
      }
      # If we have more than the max # of plots, warn the person
      if($i == $max) {
	$template_hash->{boxplottscontent} .= $hash->{str}->[$hash->{lang}]->{too_many_plots};
	$template_hash->{scattertscontent} .= $hash->{str}->[$hash->{lang}]->{too_many_plots};
	if($desc->{sptsdata}) {
	  $template_hash->{scattertstext} .= $hash->{str}->[$hash->{lang}]->{too_many_plots};
	  $template_hash->{boxplottstext} .= $hash->{str}->[$hash->{lang}]->{too_many_plots};
	}
      }

      # Plot all the appropriate scatterplots
      for($i = 0; $i <= $#scattervardescs && $i < $max; $i++) {
	my($desc) = $scattervardescs[$i];
	$template_hash->{scattervarcontent} .= $displayer->make_scattervar_img($desc);
	if($desc->{spvardata}) {
	  $template_hash->{scattervartext} .= $displayer->make_scattervar_text($desc);
	}
      }
      # If we have more than the max # of plots, warn the person
      if($i == $max) {
	$template_hash->{scattervarcontent} .= $hash->{str}->[$hash->{lang}]->{too_many_plots};
	if($desc->{spvardata}) {
	  $template_hash->{scattervartext} .= $hash->{str}->[$hash->{lang}]->{too_many_plots};
	}
      }
    }
  }

  $template_hash->{mapcontent} = join("<br/>", @bits) . $too_many_plots;
  if($#diffmaps >= 0) {
    $template_hash->{differencemapcontent} = join("<br/>", @diffmaps) . $too_many_plots;
  } else {
    $template_hash->{differencemapcontent} = "<br/>No valid difference maps available";
  }
  $template_hash->{metadatatable} = "<table cellspacing=\"0\" cellpadding=\"0\" class=\"metadatatable\" width=\"100%\">" . join("", @metadataitems) . "</table>" . $too_many_plots;
  $template_hash->{datatable} = "<table cellspacing=\"0\" cellpadding=\"0\" class=\"datatable\" width=\"100%\">" . join("", @dataitems) . "</table>" . $too_many_plots;
  
  $template_hash->{modelmetadatatable} = "<table cellspacing=\"0\" cellpadding=\"0\" class=\"metadatatable\" width=\"100%\">" . join("", @modelmetadataitems) . "</table>";
  $template_hash->{modeldatatable} = "<table cellspacing=\"0\" cellpadding=\"0\" class=\"datatable\" width=\"100%\">" . join("", @modeldataitems) . "</table>";
  
  $template_hash->{tabno} = $inputdata->{seltab};
  

#END CRAP NOT IN PLANNERS


  # Set up widths
  my($t) = $template_hash;
  $t->{scrnwidth} = $hash->{dat}->[2]->{resolution}->[$inputdata->{res}] - 32;
  $t->{scrnwidth_sidetabs} = $t->{scrnwidth} - 20;
  $t->{mapwidth} = $t->{scrnwidth} - 121;
  $t->{narrowdcol} = floor(0.296 * $t->{scrnwidth});
  $t->{widedcol} = floor(0.40 * $t->{scrnwidth});
  $t->{txtcolumnwidth} = floor(0.14 * $t->{scrnwidth});
  
  # Parse template and output
  if(defined($hash->{post}->{planners})) {
      print parseTemplate($hash->{cfg}->[2]->{planners_template}, $template_hash, $planners_plotdat_cache);
  } else {
      print parseTemplate($hash->{cfg}->[2]->{template}, $template_hash);
  }
  
  return OK;
}

return 1; # modules must return true
