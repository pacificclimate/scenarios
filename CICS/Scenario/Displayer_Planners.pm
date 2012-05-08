package CICS::Scenario::Displayer_Planners;
use strict;

use CICS::Helpers;
use CICS::Scenario::Cache;
use CICS::Scenario::Helpers;
use File::Slurp;
use Language::Functional qw(all);
use HTML::Entities qw(encode_entities);

sub new {
  my($class, $in) = @_;
  my($self) = {};

  foreach(qw(cfg plotdat lang expt dat str exptdata mainform regions prs cache)) {
    set_if_empty($self, $_, undef);
    if(defined($in) && is_hashref($in) && defined($in->{$_})) {
      $self->{$_} = $in->{$_};
    }
  }

  $self->{error} = "";
  bless($self, $class);
  $self->fix_subrefs();
  return $self;
}

sub fix_subrefs {
  my($self) = @_;

  if(defined($self->{str}) && defined($self->{lang})) {
    $self->{ss} = $self->{str}->[$self->{lang}];
  }
  if(defined($self->{dat})) {
    $self->{d} = $self->{dat}->[2];
    if(defined($self->{lang})) {
      $self->{dd} = $self->{dat}->[$self->{lang}];
    }
  }
  if(defined($self->{cfg})) {
    $self->{cd} = $self->{cfg}->[2];
    if(defined($self->{lang})) {
      $self->{cl} = $self->{cfg}->[$self->{lang}];
    }
  }
}

sub cfg {
  my($cfg) = accessvar("cfg", undef, @_);
  my($self) = @_;
  $self->fix_subrefs();
  return $cfg;
}
sub str {
  my($str) = accessvar("str", undef, @_);
  my($self) = @_;
  $self->fix_subrefs();
  return $str;
}
sub lang {
  my($lang) = accessvar("lang", undef, @_);
  my($self) = @_;
  $self->fix_subrefs();
  return $lang;
}
sub dat {
  my($lang) = accessvar("lang", undef, @_);
  my($self) = @_;
#  return $lang;  # FIXME ?
  return accessvar("dat", undef, @_);
}
sub expt {
  return accessvar("expt", undef, @_);
}
sub exptdata {
  return accessvar("exptdata", undef, @_);
}

sub format_latlon {
  my($lat, $lon) = @_;

  my($text) = "(" . (($lat > 0) ? $lat . "N, " : (-1 * $lat) . "S, ");
  $text .= (($lon > 0) ? $lon . "E" : (-1 * $lon) . "W") . ")";

  return $text;
}

sub get_units {
  my($self, $desc) = @_;
  # Set up units
  if(is_ts_absolute($desc->{ts}, $desc->{expt}, $self->{exptdata})) {
    # Baseline
    return $self->{dat}->[3]->{variable}->[$desc->{var}];
  } else {
    # Prediction
    return $self->{dat}->[4]->{variable}->[$desc->{var}] . " change";
  }
}

sub get_dec_places {
  my($self, $desc) = @_;

  # Get # of decimal places to display
  if($self->{d}->{numdatdec}->[$desc->{'numdatdec'}] eq '') {
    if(is_ts_absolute($desc->{ts}, $desc->{expt}, $self->{exptdata})) {
      return $self->{dat}->[7]->{'variable'}->[$desc->{'var'}];
    } else {
      return $self->{dat}->[8]->{'variable'}->[$desc->{'var'}];
    }
  } else {
    return $self->{d}->{'numdatdec'}->[$desc->{'numdatdec'}];
  }
}

sub make_modeldata_header {
  my($self) = @_;
  my($text) = "";

  $text .= "<tr><th>Model</th><th>Land-Sea Mask</th><th>Latitude file</th><th>Longitude file</th><th>Region mask</th></tr>";

  return $text;
}

sub make_modeldata_row {
  my($self, $desc, $header) = @_;
  my($plotdat) = $self->{plotdat};
  my($text) = "";
  my(@items) = ($header);
  my($modelname) = $self->{exptdata}->[$desc->{'expt'}]->{'modelname'};

  foreach((["Land-Sea Mask", TYPE_SLMASK_DATA]), ["Lat file", TYPE_LATS_DATA], ["Lon file", TYPE_LONGS_DATA]) {
    my($ftype) = $_;
    $desc->{'plot_type'} = $ftype->[1];
    push(@items, "<a href=\"".$self->{cd}->{wrapper}."?".mkgetstring($desc)."\">" . $ftype->[0] . "</a>");
  }

  $desc->{plot_type} = TYPE_MASK;
  if(is_polygon($desc->{points})) {
    push(@items, "<a href=\"".$self->{cd}->{wrapper}."?".mkgetstring($desc)."\">Region mask</a>");
  } else {
    push(@items, "No region mask");
  }

  $text .= "<tr><td>" . join("</td><td>", @items) . "</td></tr>";
  return $text;
}

sub make_data_vars_header {
  my($self, $desc, $header) = @_;

  return "<tr><th colspan=\"5\">" . $header . "</th></tr>\n";
}

sub make_data_row_header {
  my($self, $desc, $title) = @_;
  my($text) = "";
  my($unit);

  if(is_ts_absolute($desc->{ts}, $desc->{expt}, $self->{exptdata})) {
    # Baseline
    $unit = $self->{dat}->[3]->{variable}->[$desc->{var}];
  } else {
    # Prediction
    $unit = $self->{dat}->[4]->{variable}->[$desc->{var}];
  }

  $text .= "<tr><th>" . $title . "</th><th>Scenarios</th><th>Georef</th><th>Timeseries (".$unit.")</th><th>Timeseries (" . $unit . ") anomaly</th></tr>";

  return $text;
}

sub make_data_error_row {
  my($self, $desc, $rowdesc) = @_;
  my(@bits) = ($rowdesc);
  my($i);
  for($i = 1; $i < 5; $i++) {
    push(@bits, "NA");
  }

  return "<tr><td class=\"dataidentifier\">" . join("</td><td>", @bits) . "</td></tr>\n";
}

sub make_data_row {
  my($self, $desc, $rowdesc) = @_;
  my(@items, $ftype);
  my(@datafmts) = ([ $self->{ss}->{'scenarios_format'}, TYPE_SCENARIO_DATA ], [ $self->{ss}->{'georeferenced'}, TYPE_GEOREF ]);
  my($datafilename);
  my($modelname) = $self->{exptdata}->[$desc->{'expt'}]->{'modelname'};

  push(@items, $rowdesc);

  foreach(@datafmts) {
    $ftype = $_;
    $desc->{'plot_type'} = $ftype->[1];
    push(@items, "<a href=\"".$self->{cd}->{wrapper}."?".mkgetstring($desc)."\">" . $ftype->[0] . "</a>");
  }

  my(@numpoints) = split(/,/, $desc->{points});

  if($#numpoints == 0 && defined($self->{plotdat}->{box_x})) {
    my($bx, $by) = ($self->{plotdat}->{box_x}, $self->{plotdat}->{box_y});
    my($bxr, $byr) = (sprintf("%02i", $bx + 1), sprintf("%02i", $by + 1));
    foreach("", "anom") {
      my(@bits) = ($modelname, $self->{d}->{variable}->[$desc->{var}] . "/" . $modelname,
		   $self->{exptdata}->[$desc->{expt}]->{exptname},
		   $self->{dat}->[3]->{timeslice}->[$desc->{ts}],
		   $self->{d}->{variable}->[$desc->{var}]);
      if($_ eq "anom") {
	push(@bits, "anom");
      }
      push(@bits, "long" . $bxr, "lat" . $byr . ".dat");

      $datafilename = join("_", @bits);

      if(stat($self->{cd}->{timeseriesdir_local} . $datafilename)) {
	push(@items, "<a href=\"" . $self->{cd}->{timeseriesdir_www} . $datafilename."\">Timeseries</a>\n");
      } else {
	push(@items, "NA");
	$self->{error} .= "Missing file " . $datafilename . "\n";
      }
    }
  } else {
    push(@items, "NA", "NA");
  }

  return "<tr><td class=\"dataidentifier\">" . join("</td><td>", @items) . "</td></tr>";
}

sub make_modelmetadata_header {
  my($self) = @_;
  my($text) = "";

  $text .= "<tr><th>Model</th><th>Map corners (topleft, bottomright)</th><th>Region area (km<sup>2</sup>)</th><th>Boxes in region</th><th>Gridbox lat/lon</th></tr>";

  return $text;
}

sub make_modelmetadata_row {
  my($self, $desc, $header) = @_;
  my($plotdat) = $self->{plotdat};
  my($text) = "";

  my(@bits) = ( $header );
  my($mapcorners) = format_latlon($plotdat->{mapmaxlat}, $plotdat->{mapminlon}) . " - " . format_latlon($plotdat->{mapminlat}, $plotdat->{mapmaxlon});
  push(@bits, $mapcorners);

  push(@bits, $plotdat->{selarea}, $plotdat->{selgridboxes});

  my(@numpoints) = split(/,/, $desc->{points});
  if($#numpoints == 0) {
    push(@bits, format_latlon($plotdat->{dpointlat}, $plotdat->{dpointlon}));
  } else {
    push(@bits, "NA");
  }
  $text .= "<tr><td>" . join("</td><td>", @bits) . "</td></tr>";
  return $text;
}

sub make_metadata_vars_header {
  my($self, $desc, $header) = @_;

  return "<tr><th colspan=\"7\">" . $header . "</th></tr>\n";
}

sub make_metadata_row_header {
  my($self, $desc, $title) = @_;
  my($text) = "";

  $text .= "<tr><th rowspan=\"2\">" . $title . "</th><th colspan=\"5\">Region data</th><th rowspan=\"2\">Units</th></tr>\n";
  $text .= "<tr><th>Min</th><th>Max</th><th>W.Mean</th><th>Median</th><th>W.Std Dev</th></tr>\n";

  return $text;
}

sub make_metadata_error_row {
  my($self, $desc, $rowdesc, $csv) = @_;
  my(@bits) = ($rowdesc);
  my($i);
  for($i = 1; $i < 10; $i++) {
    push(@bits, "NA");
  }

  if(defined($csv)) {
    return join(",", @bits) . ",\n";
  } else {
    return "<tr><td class=\"dataidentifier\">" . join("</td><td>", @bits) . "</td></tr>\n";
  }
}

sub make_metadata_row {
  my($self, $desc, $rowdesc, $csv) = @_;
  my($plotdat) = $self->{plotdat};
  my($unit) = $self->get_units($desc);
  my($numdatdec) = $self->get_dec_places($desc);
  my(@donebits) = ($rowdesc);
  my($fmt) = "%0." . $numdatdec . "f";

  foreach(qw(selmin selmax selwmean selmedian selwstddev)) {
    if(length($_) && defined($plotdat->{$_})) {
      push(@donebits, sprintf($fmt, $plotdat->{$_}));
    } else {
      push(@donebits, "NA");
    }
  }
  push(@donebits, $unit);

  if(defined($csv)) {
    return join(",", @donebits) . ",\n";
  } else {
    return "<tr><td class=\"dataidentifier\">" . join("</td><td>", @donebits) . "</td></tr>\n";
  }
}

sub get_percentile_rows {
  my ($self, $desc, $values, $csv) = @_;
  my ($units) = $self->get_units($desc);
  my ($numdatdec) = $self->get_dec_places($desc);
  my (@percentiles) = (0.90, 0.75, 0.50, 0.25, 0.10);
  my (@titles) = ('90th Percentile', '75th percentile', 'Median', '25th percentile', '10th Percentile');
  my ($i);
  my(@donebits);

  # Choose format
  my($fmt);
  if(defined($csv)) {
    $fmt = "%s,-,-,%0.".$numdatdec."f,-,-,%s,";
  } else {
    $fmt = "<tr><td>%s</td><td>-</td><td>-</td><td>%0.".$numdatdec."f</td><td>-</td><td>-</td><td>%s</td></tr>";
  }

  # Accumulate rows
  for ($i=0; $i <= $#percentiles; $i++) {
    my ($val) = weighted_pctile($values, $percentiles[$i]);
    push(@donebits, sprintf($fmt, $titles[$i], $val, $units))
  }

  # Finish output
  return join("\n", @donebits) . "\n";
}

# make_scatterts_img creates all the HTML needed for a scatter plot by timeslice
sub make_scatterts_img {
  my($self, $desc) = @_;
  my($wrapper, $hash, $s, $output) = ($self->{cd}->{wrapper}, $self->{plotdat}, $self->{ss}, "");
  my($cache) = $self->{cache};
  my($title) = $cache->make_scatter_title($desc, TYPE_SCATTER_TIMESLICE);

  $desc->{'plot_type'} = TYPE_SCATTER_TIMESLICE_TEXT;
  $output .= "<a href=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Scatter plot CSV\"/>CSV data</a>";

  $desc->{'plot_type'} = TYPE_SCATTER_TIMESLICE;

  $output .= "<div class=\"mapheader\">" . $title . "</div>";

  $output .= "<img src=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Scatter plot by timeslice\" style=\"width: ";
  $output .= $self->{plotdat}->{scattersize_x}."px; height: ".$self->{plotdat}->{scattersize_y}."px;\"/>";
  $output .= "<br/><br/>";

  return $output;
}

# make_boxplotts_img creates all the HTML needed for a boxplot by timeslice
sub make_boxplotts_img {
  my($self, $desc) = @_;
  my($wrapper, $hash, $s, $output) = ($self->{cd}->{wrapper}, $self->{plotdat}, $self->{ss}, "");
  my($cache) = $self->{cache};
  my($title) = $cache->make_scatter_title($desc, TYPE_BOXPLOT_TIMESLICE);

  $desc->{'plot_type'} = TYPE_BOXPLOT_TIMESLICE_TEXT;
  $output .= "<a href=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Scatter plot CSV\"/>CSV data</a>";

  $desc->{'plot_type'} = TYPE_BOXPLOT_TIMESLICE;

  $output .= "<div class=\"mapheader\">" . $title . "</div>";

  $output .= "<img src=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Box plot by timeslice\" style=\"width: ";
  $output .= $self->{plotdat}->{scattersize_x}."px; height: ".$self->{plotdat}->{scattersize_y}."px;\"/>";
  $output .= "<br/><br/>";

  return $output;
}

# make_boxplotts_text creates all the HTML needed for a scatter plot by timeslice
sub make_boxplotts_text {
  my($self, $desc) = @_;
  my($wrapper, $hash, $s, $output) = ($self->{cd}->{wrapper}, $self->{plotdat}, $self->{ss}, "");
  my($cache) = $self->{cache};
  my($title) = $cache->make_scatter_title($desc, TYPE_BOXPLOT_TIMESLICE);

  # If we want to display data, show it here
  my($csv);
  $csv = read_file($cache->create_cachefile($desc, TYPE_BOXPLOT_TIMESLICE_TEXT));
  $output .= "<div class=\"mapheader\">" . $title . "</div>";
  $output .= csv2html($csv, "spdatacontent");
  $output .= "<br/><br/>";

  return $output;
}

# make_scatterts_img creates all the HTML needed for a scatter plot by timeslice
sub make_scatterts_text {
  my($self, $desc) = @_;
  my($wrapper, $hash, $s, $output) = ($self->{cd}->{wrapper}, $self->{plotdat}, $self->{ss}, "");
  my($cache) = $self->{cache};
  my($title) = $cache->make_scatter_title($desc, TYPE_SCATTER_TIMESLICE);

  # If we want to display data, show it here
  my($csv);
  $csv = read_file($cache->create_cachefile($desc, TYPE_SCATTER_TIMESLICE_TEXT));
  $output .= "<div class=\"mapheader\">" . $title . "</div>";
  $output .= csv2html($csv, "spdatacontent");
  $output .= "<br/><br/>";

  return $output;
}

# make_scattervar_img creates all the HTML needed for a scatter plot by variable
sub make_scattervar_img {
  my($self, $desc) = @_;
  my($wrapper, $hash, $s, $output) = ($self->{cd}->{wrapper}, $self->{plotdat}, $self->{ss}, "");
  my($cache) = $self->{cache};
  my($title) = $cache->make_scatter_title($desc, TYPE_SCATTER_VARIABLE);

  $desc->{'plot_type'} = TYPE_SCATTER_VARIABLE_TEXT;
  $output .= "<a href=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Scatter plot CSV\"/>CSV data</a>";

  $output .= "<div class=\"mapheader\">" . $title . "</div>";

  $desc->{'plot_type'} = TYPE_SCATTER_VARIABLE;

  $output .= "<img src=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Scatter plot by variable\" style=\"width: ";
  $output .= $self->{plotdat}->{scattersize_x}."px; height: ".$self->{plotdat}->{scattersize_y}."px;\"/>";
  $output .= "<br/><br/>";

  return $output;
}

# make_scattervar_img creates all the HTML needed for a scatter plot by variable
sub make_scattervar_text {
  my($self, $desc) = @_;
  my($wrapper, $hash, $s, $output) = ($self->{cd}->{wrapper}, $self->{plotdat}, $self->{ss}, "");
  my($cache) = $self->{cache};
  my($title) = $cache->make_scatter_title($desc, TYPE_SCATTER_VARIABLE);

  # If we want to display data, show it here
  my($csv);
  $csv = read_file($cache->create_cachefile($desc, TYPE_SCATTER_VARIABLE_TEXT));
  $output .= "<div class=\"mapheader\">" . $title . "</div>";
  $output .= csv2html($csv, "spdatacontent");
  $output .= "<br/><br/>";

  return $output;
}

# make_region_img creates all the HTML needed for a regionmap image
sub make_region_img {
  my($self, $desc) = @_;
  my($wrapper, $hash, $s, $output) = ($self->{cd}->{wrapper}, $self->{plotdat}, $self->{ss}, "");

  $desc->{'plot_type'} = TYPE_REGIONONLY;

  $output .= "<input type=\"image\" name=\"regionmap\" src=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Reload to view region\" style=\"width: ";
  $output .= $self->{plotdat}->{fullsize_x}."px; height: ".$self->{plotdat}->{fullsize_y}."px;\"/>";

  return $output;
}

# make_difference_img creates all the HTML needed for a difference map image
sub make_difference_img {
  my($self, $desc) = @_;
  my($wrapper, $output) = ($self->{cd}->{wrapper}, "");

  $desc->{'plot_type'} = TYPE_MAP_DIFFERENCE;

  # Lay things out nicely
  $output .= "<div class=\"mapheader\">" . $self->{cache}->make_difference_title($desc) . "</div>";

  $output .= "<img src=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Reload to view map\" style=\"width: ".$self->{plotdat}->{fullsize_x}."px; height: ".$self->{plotdat}->{fullsize_y}."px;\"/>" . "<br/>";

  return $output;
}

# make_display_img creates all the HTML needed for a map image
sub make_display_img {
  my($self, $desc, $make_clickable) = @_;
  my($wrapper, $output) = ($self->{cd}->{wrapper}, "");

  $desc->{'plot_type'} = TYPE_MAP;

  # Lay things out nicely
  $output .= "<div class=\"mapheader\">" . $self->{cache}->make_map_title($desc) . "</div>";

  if($make_clickable) {
    $output .= "<input type=\"image\" name=\"map\" src=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Reload to view map\" style=\"width: ".$self->{plotdat}->{fullsize_x}."px; height: ".$self->{plotdat}->{fullsize_y}."px;\"/>";
  } else {
    $output .= "<img src=\"".$wrapper."?".mkgetstring($desc)."\" alt=\"Reload to view map\" style=\"width: ".$self->{plotdat}->{fullsize_x}."px; height: ".$self->{plotdat}->{fullsize_y}."px;\"/>";
  }
  $output .= "<br/>";

  return $output;
}

sub make_error_img {
  my($self, $desc) = @_;
  my($wrapper, $hash, $s, $output) = ($self->{cd}->{wrapper}, $self->{plotdat}, $self->{ss}, "");

  $desc->{'plot_type'} = TYPE_MAP;

  # Lay things out nicely
  $output .= "<div class=\"mapheader\">".
    join(" - ", $self->{expt}->[$desc->{'expt'}], 
	 $self->{dd}->{'timeofyear'}[$desc->{'toy'}], 
	 $desc->{vars}->[$desc->{'var'}] . (is_ts_absolute($desc->{ts}, $desc->{expt}, $self->{exptdata})?"":" Change"), 
	 $self->{dd}->{'timeslice'}[$desc->{'ts'}]) .
	   "</div><br/>";

  $output .= "Data missing<br/>";

  return $output;
}

sub get_sector_internal_name {
    my($str) = @_;
    $str = lc($str);
    $str =~ s/ /_/g;
    return($str);
}

sub make_sector_span {
    my($str) = @_;
    my($internal_str) = get_sector_internal_name($str);
    my(%sectorimgmapper) = ("hydrology" => "img/hydrology.png", "agriculture" => "img/agriculture.png", "biodiversity" => "img/biodiversity.png", "infrastructure" => "img/infrastructure.png", "land_use_planning" => "img/land_use_planning.png", "fisheries" => "img/fisheries.png", "forestry" => "img/forestry.png");
    if(exists($sectorimgmapper{$internal_str})) {
	return '<img src="' . $sectorimgmapper{$internal_str} . '" alt="' . $str . '" title="' . $str . '" />';
    } else {
	return '<span class="' . $internal_str . '">' . $str . '</span>';
    }
}

sub get_category_internal_name {
    my($str) = @_;
    my(%catmapper) = ("High Intensity Precipitation" => "high_intensity_precipitation", "Possible Flooding" => "possible_flooding", "Waterlogged Soil" => "waterlogged_soil", "Sea Level Rise / Storm Surge" => "sea_level_rise", "Reduced Water Supply" => "reduced_water_supply", "Longer Dry Season" => "longer_dry_season", "Increase in Temperature" => "increase_in_temperature", "Considerable Increase in Temperature" => "considerable_increase_in_temperature", "Change in Hydrologic Regime" => "change_in_hydrologic_regime", "Increase in Freeze/Thaw Cycles" => "increase_in_freeze_thaw_cycles", "Increase in Hot and Dry Conditions" => "increase_in_hot_and_dry_conditions", "Decrease in Snowpack" => "decrease_in_snowpack", "Change in Species Range" => "change_in_species_range", "Possible Change in Productivity" => "possible_change_in_productivity");
    return($catmapper{$str});
}

sub make_category_span {
    my($str) = @_;
    my($internal_str) = get_category_internal_name($str);
    return '<img src="img/' . $internal_str . '.png" alt="' . $str . '" title="' . $str . '" />';
}

sub anchorify {
    my($str) = @_;
    $str =~ tr/a-zA-Z0-9_/_/c;
    return($str);
}


sub make_pretty_impacts_data {
    my($self, $planners_plotdat_cache) = @_;
    my($result_html) = "";
    my($impacts_logic_filename) = $self->{cfg}->[2]->{planners_impacts_csv};
    my $impacts_logic_csv = parse_csv($impacts_logic_filename, ";");

    ## Emit variable table
    # $result_html .= "<br/><h3>Variables</h3>\n";
    # $result_html .= '<table id="varstable">' . "\n";
    # $result_html .= '<tr class="dkerblue"><th>Variable</th><th>Description</th><th>Units</th></tr>';
    # foreach my $varid (0..$#{$self->{dat}[3]{'variable'}}) {
    # 	$result_html .= '<tr class="varrow">' . "\n";
    # 	$result_html .= '<td>' . $self->{dat}[2]{'variable'}->[$varid] . "</td>\n";
    # 	$result_html .= '<td>' . $self->{dat}[0]{'variable'}->[$varid] . "</td>\n";
    # 	$result_html .= '<td>' . $self->{dat}[3]{'variable'}->[$varid] . "</td>\n";
    # 	$result_html .= "</tr>\n";
    # }
    # $result_html .= "</table>\n";

    ## Header Row
    $result_html .= "<br/><h3>Rules</h3>\n";
    $result_html .= "<table>\n";
    $result_html .= '<tr class="dkblue"><th>ID</th><th>Condition</th><th>Category</th><th>Sector</th><th>Impact</th><th>Management Implications</th></tr>' . "\n";

    my %cond_hash;
    @cond_hash{@{$impacts_logic_csv->{id}}} = @{$impacts_logic_csv->{condition}};

    foreach my $rowid (0..$#{$impacts_logic_csv->{id}}) {
	## Condition munger...
	my($cond) = encode_entities($impacts_logic_csv->{condition}->[$rowid]);

	## Map <= and >= to appropriate entities
	$cond =~ s/&lt;=/&le;/g;
	$cond =~ s/&gt;=/&ge;/g;
	
	## Tag percentage change fields as percent
	$cond =~ s/prec_([a-z]+)_iamean_([a-z0-9]+)_e([0-9]+)p/prec_$1_iamean_$2_e$3p_percent/g;

	## Show non-percentage fields as that, not a bunch of math.
	$cond =~ s/\(([a-z0-9]+)_([a-z]+)_iamean_([a-z0-9]+)_e([0-9]+)p_percent\s*\/\s*100\)\s*\*\s*\1_\2_iamean_\3_hist/$1_$2_iamean_$3_e$4p/g;
	$cond =~ s/prec_([a-z]+)_iamean_([a-z0-9]+)_hist\s*\*\s*\(1\s*\+\s*\(prec_\1_iamean_\2_e([0-9]+)p_percent\s*\/\s*100\)\)/prec_$1_iamean_$2_e$3p/g;

	## Tag anomalies as anomalies
	$cond =~ s/([a-z0-9]+)_([a-z]+)_iamean_([a-z0-9]+)_e([0-9]+)p([^_])/$1_$2_iamean_$3_e$4p_anom$5/g;
	
	## Show fields where we are summing together historical and future as absolute
	$cond =~ s/([a-z0-9]+)_([a-z]+)_iamean_([a-z0-9]+)_e([0-9]+)p_anom \+ \1_\2_iamean_\3_hist/$1_$2_iamean_$3_e$4p/g;
	$cond =~ s/([a-z0-9]+)_([a-z]+)_iamean_([a-z0-9]+)_hist \+ \1_\2_iamean_\3_e([0-9]+)p_anom/$1_$2_iamean_$3_e$4p/g;

	## Get rid of extra parens
	$cond =~ s/\(([a-z0-9_]*)\)/$1/g;

	## Get rid of redundant parameters
	$cond =~ s/iamean_//g;
	$cond =~ s/smean_//g;

	## Map division and equality
	$cond =~ s/\//&divide;/g;
	$cond =~ s/==/=/g;

	## Change operators to more readable forms
	$cond =~ s/&amp;&amp;/<br\/>AND/g;
	$cond =~ s/\|\|/<br\/>OR/g;
	$cond =~ s/!\(/NOT\(/g;
	$cond =~ s/!([a-z0-9_-]+)/NOT\($1\)/g;

	## Link rules together
	$cond =~ s/(rule_[a-z0-9-]+)/'<a href="#' . anchorify($1) . '">' . $1 . '<\/a>'/eg;

	my $rule = resolve_rule_references(\%cond_hash, $impacts_logic_csv->{id}->[$rowid]);
	my($ruletruth) = test_expression($rule, $planners_plotdat_cache);

	$result_html .= '<tr><td><a name="rule_' . anchorify($impacts_logic_csv->{id}->[$rowid]) . '"></a>' . join("</td><td>", (($ruletruth) ? '<strong>' . $impacts_logic_csv->{id}->[$rowid] . '</strong>' : $impacts_logic_csv->{id}->[$rowid]), $cond, encode_entities($impacts_logic_csv->{category}->[$rowid]), encode_entities($impacts_logic_csv->{sector}->[$rowid]), encode_entities($impacts_logic_csv->{text1}->[$rowid]), $impacts_logic_csv->{text2}->[$rowid]) . "</td></tr>\n";
    }

    $result_html .= "</table>\n";
    return(parseTemplate($self->{cfg}->[2]->{planners_rules_template}, {"rules_id" => "raw_impacts", "rules_table" => $result_html}));
}

sub make_planners_impacts_table {
    my($self, $template_hash, $planners_plotdat_cache) = @_;
    my($impacts_logic_filename) = $self->{cfg}->[2]->{planners_impacts_csv};
    my($expression_success_count) = 0;
    my($result_html) = "";

    # Conditionals and resulting table rows
    my $impacts_logic_csv = parse_csv($impacts_logic_filename, ";");

    ## Header Row
    $result_html = '<table id="impactstable">' . "\n";
    $result_html .= '<tr class="dkerblue"><th colspan="2">Potential Impacts for the ' . $template_hash->{'var:region'} . ' region in ' . $template_hash->{'var:ts_period'} . " period</th></tr>\n";
    $result_html .= '<tr class="dkblue category"><th>Impacts</th><th>Sectors</th></tr>' . "\n";
    $result_html .= '<tr class="dkblue sector"><th>Sectors</th><th>Impacts</th></tr>' . "\n";

    my %cond_hash;
    @cond_hash{@{$impacts_logic_csv->{id}}} = @{$impacts_logic_csv->{condition}};

    my %category_hash;
    my %sector_hash;
    foreach my $rowid (0..$#{$impacts_logic_csv->{id}}) {
	my $category = $impacts_logic_csv->{category}->[$rowid];
	my $sector = $impacts_logic_csv->{sector}->[$rowid];
	if($category eq "") {
	    next;
	}
	my $rule = resolve_rule_references(\%cond_hash, $impacts_logic_csv->{id}->[$rowid]);
	print STDERR "id: " . $impacts_logic_csv->{id}->[$rowid] . ", rule: " . $rule . "\n";
	if(test_expression($rule, $planners_plotdat_cache)) {
	    my $dathash;
	    my $secthash;
	    if(exists($sector_hash{$sector})) {
		$secthash = $sector_hash{$sector};
	    } else {
		$secthash = {};
		$secthash->{categories} = {};
		$secthash->{sector_text} = "";
		$sector_hash{$sector} = $secthash;
	    }
	    if(exists($category_hash{$category})) {
		$dathash = $category_hash{$category};
	    } else {
		$dathash = {};
		$dathash->{sectors} = {};
		$dathash->{category_text} = "";
		$category_hash{$category} = $dathash;
	    }
	    $dathash->{sectors}->{$sector} = 1;
	    $secthash->{categories}->{$category} = 1;
	    $dathash->{category_text} .= "<h3>" . make_sector_span($sector) . '<span> ' . encode_entities($impacts_logic_csv->{text1}->[$rowid]) . '</span></h3>';
	    $dathash->{category_text} .= '<div class="impacticon">' . $impacts_logic_csv->{text2}->[$rowid] . "</div><br/>\n";
	    $secthash->{sector_text} .= "<h3>" . make_category_span($category) . '<span> ' . encode_entities($impacts_logic_csv->{text1}->[$rowid]) . '</span></h3>';
	    $secthash->{sector_text} .= '<div class="impacticon">' . $impacts_logic_csv->{text2}->[$rowid] . "</div><br/>\n";
	}
    }
    
    my($zoomwins) = "";

    foreach my $cat (sort(keys(%category_hash))) {
	my($linktext) = '<a href="#" onclick="' . "zoomImpact('" . get_category_internal_name($cat) . "')\">";
	$result_html .= '<tr class="category"><td>' . $linktext . make_category_span($cat) . '<span> ' . encode_entities($cat) . '</span></a></td>';
	$result_html .= '<td>' . $linktext . join(" ", map { make_sector_span($_) } sort(keys(%{$category_hash{$cat}->{sectors}}))) . '</a></td></tr>' . "\n";

	my($innertext) = '<h2>' . make_category_span($cat) . ' <span>' . encode_entities($cat) . '</span></h2><div class="categorytext">' . $category_hash{$cat}->{category_text} . "</div>\n";
	$zoomwins .= parseTemplate($self->{cfg}->[2]->{planners_impacts_template}, {"category" => get_category_internal_name($cat), "category_text" => $innertext});
    }

    foreach my $sect (sort(keys(%sector_hash))) {
	my($linktext) = '<a href="#" onclick="' . "zoomImpact('" . get_sector_internal_name($sect) . "')\">";
	$result_html .= '<tr class="sector"><td>' . $linktext . make_sector_span($sect) . '<span> ' . encode_entities($sect) . '</span></a></td>';;
	$result_html .= '<td>' . $linktext . join(" ", map {make_category_span($_) } sort(keys(%{$sector_hash{$sect}->{categories}}))) . '</a></td></tr>' . "\n";
	
	my($innertext) = '<h2>' . make_sector_span($sect) . ' <span>' . encode_entities($sect) . '</span></h2><div class="categorytext">' . $sector_hash{$sect}->{sector_text} . "</div>\n";
	$zoomwins .= parseTemplate($self->{cfg}->[2]->{planners_impacts_template}, {"category" => get_sector_internal_name($sect), "category_text" => $innertext});
    }

    $result_html .= '<tr class="dkblue category"><th colspan="2"><a onclick="' . "hideTRClass('category'); showTRClass('sector'); return false;" . '" id="switchtosector" href="#">Switch to sector view</a></th></tr>';
    $result_html .= '<tr class="dkblue sector"><th colspan="2"><a onclick="' . "hideTRClass('sector'); showTRClass('category'); return false;" . '" id="switchtocategory" href="#">Switch to category view</a></th></tr>';
    $result_html .= "</table>\n";

    $result_html .= $zoomwins;

    return $result_html;
}

sub make_map_creation_param_js {
    my($self, $desc, $expt) = @_;
    my(%curexpt) = %{$self->{exptdata}->[($desc->{ts} == 0 ? $desc->{expt} : $expt)]};
    my($scale_factor) = $self->{dat}->[18]{'variable'}->[$desc->{var}];
    my($add_factor) = $self->{dat}->[19]{'variable'}->[$desc->{var}];
    my($ncwms_varname) = $self->{dat}->[16]{variable}->[$desc->{var}];
    my($ncwms_period) = $curexpt{ncwms_periods}->[$desc->{ts}];
    my($ncwms_expt) = lc($curexpt{exptname});
    my($ncwms_scen, $ncwms_run) = split(/-/, $ncwms_expt);
    my($varname) = $self->{dat}->[2]{'variable'}[$desc->{'var'}];
    my($canvas_id) = '"legend_' . $varname . '"';
    my($dec_places) = $self->{dat}->[7]{'variable'}[$desc->{'var'}];
    my($vardesc_txt) = '"' . $self->{dat}->[0]{'variable'}[$desc->{'var'}] . ' (' . $self->{dat}->[3]{'variable'}[$desc->{'var'}] . ')"';

    ## Fetch metadata file for this data, slurp it in, give an anom range.
    my($minrange, $maxrange) = (1000000, -1000000);
    if($desc->{ts} != 0) {
	my($metadata_csv) = parse_csv($self->{cache}->create_cachefile($desc, TYPE_SCENARIO_SET_METADATA));
	my(@means);
	my($exptdat) = $self->{exptdata}->[$desc->{expt}];
	my($exptname) = $exptdat->{modelname} . " " . $exptdat->{exptname};
	my($exptmean);
	print STDERR "Expt name: " . $exptname;
	foreach my $rowid (0..$#{$metadata_csv->{Experiment}}) {
	    my($meanval) = $metadata_csv->{mean}->[$rowid];
	    if($meanval < $minrange) {
		$minrange = $meanval;
	    }
	    if($meanval > $maxrange) {
		$maxrange = $meanval;
	    }
	    if($metadata_csv->{Experiment}->[$rowid] eq $exptname) {
		$exptmean = $meanval;
	    }
	}
	print STDERR "; Mean: " . $exptmean . "\n";
	$minrange -= $exptmean;
	$maxrange -= $exptmean;
    }

    my($div_id) = '"ol_' . $varname . '_' . (($desc->{'ts'} == 0) ? 'hist' : 'future') . '"';
    my($region) = '"' . $self->{regions}->[$desc->{pr}]{name}->[0] . '"';
    my($climate_overlay) = '"' . join("-", $curexpt{modelname}, $ncwms_scen, $ncwms_varname, $ncwms_run, $ncwms_period) . '/' . $ncwms_varname . '"';
    my($climate_time) = '"' . $curexpt{'ncwms_centers'}[$desc->{ts}] . '-' . $self->{dat}->[5]{'timeofyear'}->[$desc->{toy}] . 'T00:00:00Z"';
    my($climate_color_scale) = '"' . $self->{dat}[17]{variable}->[$desc->{var}] . '"';
    my($climate_color_range) = '"' . (($desc->{r_min} * $scale_factor) + $add_factor) . "," . (($desc->{r_max} * $scale_factor) + $add_factor) . '"';
    ## FIXME: NEED TO PROJECT THIS.
    my($center_point) = 'new OpenLayers.LonLat(' . join(",", $desc->{view_x}, $desc->{view_y}) .')';
    my($zoom_level) = $desc->{zoom};
    return 'new Array(' . join(",", $div_id, $region, $climate_overlay, $climate_time, $climate_color_range, $climate_color_scale, $center_point, $zoom_level, $canvas_id, $desc->{r_min}, $desc->{r_max}, $dec_places, $vardesc_txt, $minrange, $maxrange) . ')';
}

sub make_ol_map_js_from_desclist {
    my($self, $descs, $expt) = @_;
    my($result) = [];

    foreach(@$descs) {
	if(is_arrayref($_)) {
	    push(@{$result}, make_ol_map_js_from_desclist($self, $_, $expt));
	} else {
	    if($_->{plot_type} == TYPE_MAP) {
		push(@{$result}, make_map_creation_param_js($self, $_, $expt));
	    }
	}
    }
    return(join(",", @{$result}));
}

sub make_html_from_desclist {  # WARNING do not use this with arrays for general purposes!
  my($self, $descs) = @_;
  my($wrapper) = $self->{cd}->{wrapper};

  my %img_class_hash = ( TYPE_MAP() => 'map', TYPE_STICKPLOT() => 'stickplot', TYPE_SCATTER_TIMESLICE_HIST() => 'scatterplot' );

  print STDERR "make_html_from_desclist was passed " . @$descs . " descs or lists of descs.\n";

  my($result) = [];

  foreach (@$descs) {
      if(is_arrayref($_)) {
	  print STDERR "Plot type keys are: " . join(",",keys(%img_class_hash)) . "\n";
	  my $images = make_html_from_desclist($self,$_);
	  push(@{$result}, $images->[0]);
      } else {
	  if($_->{plot_type} != TYPE_MAP) {
	      my(%desc);
	      %desc = %{$_};
	      delete($desc{points});
	      push(@{$result}, "<div><img src=\"".$wrapper."?".mkgetstring(\%desc)."\" class=\"" . $img_class_hash{$_->{plot_type}} . "\" alt=\"\"/></div>");
	  }
      }
  }

  return $result;
}

sub make_url_from_desc {
  my($self, $desc) = @_;
  my($wrapper) = $self->{cd}->{wrapper};

  return $wrapper."?".mkgetstring($desc);
}

return 1;
