package CICS::Scenario::Displayer_Planners;
use strict;

use CICS::Helpers;
use CICS::Scenario::Cache;
use CICS::Scenario::Helpers;
use File::Slurp;

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
  $self->fix_subrefs();
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
	  push(@{$result}, '<table class="maptable"> <tr><th style="width: 402px;"><h3>Historical</h3></th><th style="width: 402px;"><h3>Projected</h3></th><th style="width: 82px;"><h3>Range</h3></th></tr> <tr>'
	       . #join('', map( '<td style="max-width: 402px;"><div>'.$_.'</div></td>', @{make_html_from_desclist($self,$_)})) . '</tr> </table>')
	         '<td style="width: 402px;"><div>'.$images->[0].'</div></td>' . '<td style="width: 402px;"><div>'.$images->[1].'</div></td style="width: 82px;">' . '<td><div>'.$images->[2].'</div></td>');  # Hideous
#	  push(@{$result}, "<table> <tr><th><h3>Historical</h3></th><th><h3>Projected</h3></th><th><h3>Range</h3></th></tr> <tr><td><div>" . join("</div></td><td><div>", @{$images}) . "</div></td></tr></table>")
      } else {
#	  print STDERR "Plot type is $_->{plot_type}, $img_class_hash{$_->{plot_type}}\n";
	  push(@{$result}, "<img src=\"".$wrapper."?".mkgetstring($_)."\" class=\"" . $img_class_hash{$_->{plot_type}} . "\" alt=\"\"/>");
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
