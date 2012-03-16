package CICS::Scenario::Helpers;

use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use POSIX qw(floor ceil);
use Text::CSV_XS;

use CICS::Helpers;
use CICS::Scenario::Cache;  #need to know plot types for desc-mangling!

use Exporter 'import';

our(@EXPORT) = qw(
  clear_selected find_selected find_closest find_nearest_line_segments find_farthest_lines
  is_multivar is_valid_lat is_valid_lon xtolon ytolat lontox lattoy fix_up_range
  make_varbox_content create_heading create_var_list create_bare_list_entry create_var_list_entry
  load_gcminfo get_variables get_variable_availability_list get_timeslice_availability_list
  get_available_index_list create_availability_list is_var_available is_timeslice_available
  is_available is_ts_absolute is_ts_future post_is_numeric make_random_name make_expt_list make_var_list
  remove_allvars make_zipfile suggest_region is_polygon csv2html weighted_pctile order
  mod_desc_with_params make_descs_from_list test_expression get_range transpose_csv_hash parse_csv);

sub order { 
  my(@stuff) = @_;
  return sort { $stuff[$a] cmp $stuff[$b] } 0 .. $#stuff;
}

sub is_ts_absolute {
  my($tsno, $exptno, $exptdata) = @_;
  my($ts_abs) = $exptdata->[$exptno]{"ts_abs"};
  return ($tsno > $#{$ts_abs} || $ts_abs->[$tsno]);
}

sub is_ts_future {
    my($tsno, $exptno, $exptdata) = @_;
    my($ts_future) = $exptdata->[$exptno]{"ts_future"};
    return($tsno <= $#{$ts_future} && $ts_future->[$tsno]);
}

sub weighted_pctile {
  my($vars, $pct) = @_;
  my(@svars) = sort {$a <=> $b} @{$vars};
  my($max) = $#svars;
  my($lowelement) = floor($pct * $max);
  my($highelement) = ceil($pct * $max);
  if($lowelement == $highelement) {
    # Single element, no weighting
    return $svars[$lowelement]
  } else {
    # Weight for the low element should be proportional to the distance of
    # the high element to the desired percentile
    my($lowweight) = (($highelement / $max) - $pct) * $max;
    my($highweight) = 1.0 - $lowweight;
    return $lowweight * $svars[$lowelement] + $highweight * $svars[$highelement];
  }
}

# Suggest region
sub suggest_region {
  my($threshold, $regionname, $name, $email, $points, $to, $from) = @_;
  my($csv) = join(",", $threshold, "\"".$regionname."\"", "\"".$regionname."\"", $points);
  my($msg) = "Region suggested:\n" . $csv . "\n";

  SendMail($msg, "New region suggested", $to, $from);
}

# Returns if the pointlist supplied forms a polygon
sub is_polygon {
  return (scalar(() = $_[0] =~ /,/g) >= 2);
}

# Is this a multi-variable?
sub is_multivar {
  return is_arrayref(@_);
}

# Does a simple check to verify that this is a valid latitude
sub is_valid_lat {
  my($lat, $min_lat, $max_lat) = @_;

  return ($lat <= $max_lat && $lat >= $min_lat);
}

# Does a simple check to verify that this is a valid longitude
sub is_valid_lon {
  my($lon, $min_lon, $max_lon) = @_;

  return ($lon <= $max_lon && $lon >= $min_lon);
}

# Convert an X coordinate to a longitude, given the specified data
sub xtolon {
  my($min_lon, $max_lon, $min_x, $width, $x) = @_;
  my($difflon) = $max_lon - $min_lon;

  if($x >= $min_x && $x <= $min_x + $width) {
    return ((($x - $min_x) / $width) * $difflon) + $min_lon;
  } else {
    return undef;
  }
}

# Convert a Y coordinate to a latitude, given the specified data
sub ytolat {
  my($min_lat, $max_lat, $min_y, $height, $y) = @_;
  my($difflat) = $max_lat - $min_lat;

  if($y >= $min_y && $y <= $min_y + $height) {
    return ((1 - (($y - $min_y) / $height)) * $difflat) + $min_lat;
  } else {
    return undef;
  }
}

# Convert a longitude to an X coordinate, given the specified data
#sub lontox {
#  my($post, $cfg, $exptdata, $lon, $off_lon) = @_;
#  my($max_x, $max_y, $max_lat, $max_lon, $min_lat, $min_lon, $difflat, $difflon, $modelname);
#  $modelname = $exptdata->[$post->{'expt'}]->{'modelname'};
#  ($max_x, $max_y) = @{$cfg->[5]->{'model'}->{$modelname}->[$post->{'plotregion'}]->[$post->{'old_resolution'}]->[$post->{'zoom'}]};
#  ($min_lat, $max_lat, $min_lon, $max_lon) = @{$cfg->[4]->{'model'}->{$modelname}->[$post->{'plotregion'}]};
#  $difflat = $max_lat - $min_lat;
#  $difflon = $max_lon - $min_lon;
#
#  return (($lon - $min_lon - $off_lon) / $difflon) * $max_x;
#}

# Convert a latitude to a Y coordinate, given the specified data
#sub lattoy {
#  my($post, $cfg, $exptdata, $lat, $off_lat) = @_;
#  my($max_x, $max_y, $max_lat, $max_lon, $min_lat, $min_lon, $difflat, $difflon, $modelname);
#  $modelname = $exptdata->[$post->{'expt'}]->{'modelname'};
#  ($max_x, $max_y) = @{$cfg->[5]->{'model'}->{$modelname}->[$post->{'plotregion'}]->[$post->{'old_resolution'}]->[$post->{'zoom'}]};
#  ($min_lat, $max_lat, $min_lon, $max_lon) = @{$cfg->[4]->{'model'}->{$modelname}->[$post->{'plotregion'}]};
#  $difflat = $max_lat - $min_lat;
#  $difflon = $max_lon - $min_lon;
#
#  return $max_y - ((($lat - $min_lat - $off_lat) / $difflat) * $max_y);
#}

# Clear selections in list
sub clear_selected {
  my($points) = @_;
  my($i);

  for($i = 0; $i <= $#{$points}; $i++) {
    $points->[$i]->[2] = 0;
  }
}

# Find selected point in list
sub find_selected {
  my($points) = @_;
  my(@selected, $i);

  for($i = 0; $i <= $#{$points}; $i++) {
    if($points->[$i]->[2] == 1) {
      push(@selected, $i);
    }
  }
  return @selected;
}

# Find closest point in list to coordinate
sub find_closest {
  my($points, $point) = @_;
  my($i, $min, $minidx, $temp);

  for($i = 0; $i <= $#{$points}; $i++) {
    $temp = sqrt(square($points->[$i]->[0] - $point->[0]) + square($points->[$i]->[1] - $point->[1]));
    if(!defined($min) || $temp < $min) {
      $minidx = $i;
      $min = $temp;
    }
  }
  return $minidx;
}

# Finds the indexes of the closest (equidistant) line segments to the
# specified point.
sub find_nearest_line_segments {
  my($points, $point) = @_;
  my($i, $j) = ( 0, 1 );
  my($min, $temp);
  my(@minidx);

  while($i <= $#{$points}) {
    # Using point-line distance formula here
    $temp = point_line_distance($point->[0], $point->[1], $points->[$i]->[0], $points->[$i]->[1], $points->[$j]->[0], $points->[$j]->[1]);

    if(!defined($min) || $min > $temp) {
      @minidx = ( $i );
      $min = $temp;
    } elsif($min == $temp) {
      push(@minidx, $i);
    }
    $i++;
    $j = ($j + 1) % ($#{$points} + 1);
  }
  return @minidx;
}

# Finds the indexes of the farthest (equidistant) lines from the specified
# point, from the list of line indexes.
sub find_farthest_lines {
  my($points, $point, @lineidx) = @_;
  my($i, $j, $max, $temp);
  my(@indexes);

  foreach(@lineidx) {
    ($i, $j) = ($_, ($_ + 1) % ($#{$points} + 1));
    $temp = point_line_distance($point->[0], $point->[1], $points->[$i]->[0], $points->[$i]->[1], $points->[$j]->[0], $points->[$j]->[1], 1);

    if(!defined($max) || $max < $temp) {
      @indexes = ( $i );
      $max = $temp;
    } elsif($max == $temp) {
      push(@indexes, $_);
    }
  }
  return @indexes;
}

sub parse_textdata {
  my($cachefile) = @_;
  my($datastream, $i);
  my($hash) = {};

  print STDERR "Cache file: " . $cachefile . "\n";

  if(!open($datastream, $cachefile)) {
    return {error => "Error opening cache file", size_x => 384, size_y => 128, file => $cachefile};
  }

  # Loop through the data fetched from genimage
  my(%dhash);
  while(<$datastream>) {
    my($arg) = $_;

    # Do initial parsing
    # Gotta revise this shit
    $arg =~ /:/;
    my($left, $right) = ($`, $'); #'
    my($rargs) = [];
    while($right =~ /\(([^\)]+)\)/g) {
      my($val) = $1;
      $val =~ s/^\s*//;
      $val =~ s/\s*$//;
      push(@{$rargs}, $val);
    }

    $dhash{$left} = $rargs;
  }
  close($datastream);

  my(@v) = ( ["Selection area weighted mean", ["selwmean"]],
	     ["Selection area weighted median", ["selwmedian"]],
	     ["Selection median", ["selmedian"]],
	     ["Selection area weighted standard deviation", ["selwstddev"]],
	     ["Selection data max (d, lon, lat)", ["selmax", "selmaxlon", "selmaxlat"]],
	     ["Selection data min (d, lon, lat)", ["selmin", "selminlon", "selminlat"]],
	     ["Selection area", ["selarea"]],
	     ["Selection num grid boxes", ["selgridboxes"]],
	     ["Data proj4 string", ["proj4_string"]],
	     ["Lat range", ["mapminlat", "mapmaxlat"]],
	     ["Lon range", ["mapminlon", "mapmaxlon"]],
	     ["Map data min (d, lon, lat)", ["mapdatamin", "mapdataminlon", "mapdataminlon"]],
	     ["Map data max (d, lon, lat)", ["mapdatamax", "mapdatamaxlon", "mapdatamaxlon"]],
	     ["Data point (d, lon, lat)", ["dpointdat", "dpointlon", "dpointlat"]],
	     ["Grid box", ["box_x", "box_y"]],
	     ["Size", ["fullsize_x", "fullsize_y"]],
	     ["Scatter size", ["scattersize_x", "scattersize_y"]],
	     ["Map size", ["mapsize_x", "mapsize_y"]],
	     ["Map offset", ["offset_x", "offset_y"]],
	   );

  foreach(@v) {
    my($item) = $_;
    if(defined($dhash{$item->[0]})) {
      my($hashitem) = $dhash{$item->[0]};
      my($i) = 0;
      foreach(@{$item->[1]}) {
	$hash->{$_} = $hashitem->[$i];
	$i++;
      }
    }
  }

  return $hash;
}

sub transpose_csv_hash { # convert column-major hashref-of-column-arrayrefs to row-major arrayref-of-row-hashrefs (no header row).  this -of course- assumes the CSV hash that comes in is rectangular, not jagged!!
  my($hash) = @_;

  return [
      map { 
          my $row = $_ ;
          +{ map { $_ => $hash->{$_}->[$row] } keys(%{$hash}) }
      } ( 0 .. $#{ $hash->{(keys %{$hash})[0]} } )
      ];
}

sub parse_csv { # generic CSV hashifier (column-major, using header row) for things like SCATTER_TIMESLICE_TEXT
  my($cachefile, $sep) = @_;
  my($datastream, $i);
  my($hash) = {};

  if(!defined($sep)) {
      $sep = ",";
  }

  my $csv = Text::CSV_XS->new ({ binary => 1, sep_char => $sep }) or
      die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

#  print STDERR "Cache file: " . $cachefile . "\n";

  if(!open($datastream, $cachefile)) {  #FIXME we don't know that this will always be a 
    return {error => "parse_csv: Error opening cache file", size_x => 384, size_y => 128, file => $cachefile};
  } else {
    print STDERR "parse_csv: Opened CSV file for parsing: '" . $cachefile . "'\n";  #SNAFU
  }

  my($csvarr, @hashkeys, $csvhash);
  my($splitpattern) = '("[^"]*"|[^' . $sep . ']+)';

  while(my $fields = $csv->getline($datastream) ) {
      if(!is_arrayref($csvarr)) { # first row
	  # first row, store the column keys
	  @hashkeys = @{$fields};
	  # init the corresponding arrayrefs
	  $csvarr = [];
	  foreach (0..$#{$fields}) {
	      push(@$csvarr, []);
	  }
      } else {                    # data
	  # append to each column array.
	  if($#{$fields} != $#hashkeys) {
	      die("CSV file '" . $cachefile . "' is jagged: " . $#hashkeys . " keys but contains row with " . $#{$fields} . " fields.");
	  }
	  foreach (0..$#{$fields}) {
	      push(@{$csvarr->[$_]}, $fields->[$_]);
	  }
      }
  }
  $csv->eof or $csv->error_diag ();
  close($datastream);

  # hashify it
  $csvhash = {};
  @{$csvhash}{@hashkeys} = (@$csvarr);


  return $csvhash;
}

sub get_multivar_availability {
    my($numexpt, $exptmulti, $exptdata) = @_;
    my($j, @varmask);
    for($j = 0; $j <= $numexpt; $j++) {
	$varmask[$j] = 0;
    }
    foreach(@{$exptmulti}) {
	my($e) = $_;
	for($j = 0; $j <= $numexpt; $j++) {
	    $varmask[$j] |= is_available($exptdata->[$e]{"varmask"}[$j]);
	}
    }
    return \@varmask;
}

sub get_multits_availability {
    my($numexpt, $exptmulti, $exptdata) = @_;
    my($j, @tsmask);
    for($j = 0; $j <= $numexpt; $j++) {
	$tsmask[$j] = 0;
    }
    foreach(@{$exptmulti}) {
	my($e) = $_;
	for($j = 0; $j <= $numexpt; $j++) {
	    $tsmask[$j] |= is_available($exptdata->[$e]{"tsmask"}[$j]);
	}
    }
    return \@tsmask;
}

# Loads a gcminfo file and populates the expt and exptdata array with data
sub load_gcminfo {
  my($gcmfile, $dat) = @_;
  my(@expt, @exptmulti, @exptdata, $gcminfo, @PCICset1, @PCICset2, @PCICset21, @PCICsetTG, @PCICsetPlanners);
  my(%expthash, %scenhash, %modelhash);
  
  my(%PCIC21) = ("CCCMA_CGCM3" => {"A2-run1" => 0, "A2-run4" => 1, "A2-run5" => 2, "A1B-run1" => 3, "B1-run1" => 4},
		 "UKMO_HADCM3" => {"A2-run1" => 5, "A1B-run1" => 6, "B1-run1" => 7}, "UKMO_HADGEM1" => {"A1B-run1" => 8}, 
		 "MPI_ECHAM5" => {"A2-run1" => 9, "A1B-run1" => 10, "B1-run1" => 11}, "MRI_CGCM232A" => {"B1-run5" => 12}, 
		 "GFDL_CM21" => {"A2-run1" => 13, "B1-run1" => 14}, 
		 "NCAR_CCSM30" => {"A2-run1" => 15, "B1-run1" => 16, "A1B-run5" => 17}, "GISS_EH" => {"A1B-run3" => 18}, 
		 "MIROC32_HIRES" => {"A1B-run1" => 19}, "CSIRO_MK30" => {"B1-run1" => 20});
  
  my(%PCICPlanners) = ("BCCR_BCM20" => {"A2-run1" => 0, "B1-run1" => 1}, "CCCMA_CGCM3" => {"A2-run4" => 2, "B1-run1" => 3},
		       "CNRM_CM3" => {"A2-run1" => 4, "B1-run1" => 5}, "CSIRO_MK30" => {"A2-run1" => 6, "B1-run1" => 7}, 
		       "MPI_ECHAM5" => {"A2-run1" => 8, "B1-run1" => 9}, "GFDL_CM20" => {"A2-run1" => 10, "B1-run1" => 11}, 
		       "GFDL_CM21" => {"A2-run1" => 12, "B1-run1" => 13}, "GISS_ER" => {"A2-run1" => 14, "B1-run1" => 15}, 
		       "INMCM30" => {"A2-run1" => 16, "B1-run1" => 17}, "IPSL_CM4" => {"A2-run1" => 18, "B1-run1" => 10}, 
		       "MIROC32_MEDRES" => {"A2-run1" => 20, "B1-run1" => 21}, "MIUB_ECHOG" => {"A2-run1" => 22, "B1-run1" => 23}, 
		       "MRI_CGCM232A" => {"A2-run1" => 24, "B1-run1" => 25}, "NCAR_CCSM30" => {"A2-run1" => 26, "B1-run1" => 27}, 
		       "UKMO_HADCM3" => {"A2-run1" => 28, "B1-run1" => 29});

  my(%PCICTG) = ("CCCMA_CGCM3" => {"A1B-run1" => 0, "A1B-run2" => 1, "A1B-run3" => 2, "A1B-run4" => 3, "A1B-run5" => 4, 
				   "A2-run1" => 5, "A2-run2" => 6, "A2-run3" => 7, "A2-run4" => 8, "A2-run5" => 9, 
				   "B1-run1" => 10, "B1-run2" => 11, "B1-run3" => 12, "B1-run4" => 13, "B1-run5" => 14},
		 "MPI_ECHAM5" => {"A2-run1" => 15, "A1B-run1" => 16, "A1B-run4" => 17, "B1-run1" => 18}, 
		 "GFDL_CM20" => {"A1B-run1" => 19, "B1-run1" => 20}, 
		 "CSIRO_MK30" => {"B1-run1" => 21} );
  
  my(%PCICmhash) = ("BCCR_BCM20" => 0, "CCCMA_CGCM3" => 1, "CNRM_CM3" => 2, "CSIRO_MK30" => 3, "MPI_ECHAM5" => 4, "GFDL_CM20" => 5, "GFDL_CM21" => 6, "GISS_ER" => 7, "INMCM30" => 8, "IPSL_CM4" => 9, "MIROC32_MEDRES" => 10, "MIUB_ECHOG" => 11, "MRI_CGCM232A" => 12, "NCAR_CCSM30" => 13, "UKMO_HADCM3" => 14);
  my(%PCICehash1) = ("A2-run1" => 0, "B1-run1" => 1);
  my(%PCICehash2) = ("A2-run1" => 0, "B1-run1" => 1, "A1B-run1" => 2);
  my($i, $j) = (-1, 0);

  my(%tphash) = ();
  my($numtp) = 6;
  my(@emptytp, @notp, @ones, @zeros);

  # Generate empty lists of time periods
  for($j = 0; $j < $numtp; $j++) {
      push(@emptytp, "");
      push(@notp, 0);
      push(@ones, 1);
      push(@zeros, 0);
  }

  open($gcminfo, $gcmfile) or die("Could not open GCM info file '" . $gcmfile . "'");
  while(<$gcminfo>) {
    # Ignore the 1st line
    if($i >= 0) {
      # This is to untaint the data...
      $_ =~ /^(.*)$/;
      my(@temp) = split(/,/, $1);
      my(@tpname) = @emptytp;
      my(@tpmask) = @notp;
      
      # Do formatting
      $expt[$i] =  $temp[3] . " - " . $temp[0] . " " . $temp[5];
      $exptmulti[$i] = $i;
      
      # Fill out the exptdata array with useful things
      $exptdata[$i]{"modelname"} = lc($temp[0]);
      $exptdata[$i]{"scenario"} = $temp[3];
      $exptdata[$i]{"longname"} = $temp[4];
      $exptdata[$i]{"exptname"} = $temp[5];

      # Fill up name lists and mask lists for extra time periods
      for($j = 10; $j <= 12; $j++) {
	  if(length($temp[$j]) > 0) {
	      if(!exists($tphash{$temp[$j]})) {
		  print STDERR "Adding time period " . $temp[$j] . "\n";
		  $tphash{$temp[$j]} = scalar(keys(%tphash));
	      }
	      if(scalar(keys(%tphash)) < $#tpname) {
		  $tpname[$tphash{$temp[$j]}] = $temp[$j];
		  $tpmask[$tphash{$temp[$j]}] = 1;
	      }
	  }
      }

      # Create period name lists (per expt)
      @{$exptdata[$i]{"ncwms_periods"}} = ($dat->[4]{"timeslice"}[0], @tpname, @{$dat->[4]{"timeslice"}}[1..3]);
      @{$exptdata[$i]{"ncwms_centers"}} = ($dat->[5]{"timeslice"}[0], @tpname, @{$dat->[5]{"timeslice"}}[1..3]);
      @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tpname, @{$dat->[2]{"timeslice"}}[1..3]);
      @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tpname, @{$dat->[0]{"timeslice"}}[1..3]);
      for($j = 0; $j < $#{$exptdata[$i]{"netcdf_periods"}}; $j++) {
	  $exptdata[$i]{"netcdf_periods"}[$j] =~ s/-/_/g;
	  # Compute centers for new periods
	  if($exptdata[$i]{"ncwms_centers"}[$j] =~ /-/) {
	      my($sum) = 0;
	      my(@splitbits);
	      @splitbits = split("-", $exptdata[$i]{"ncwms_centers"}[$j]);
	      map {$sum += $_; } @splitbits;
	      $exptdata[$i]{"ncwms_centers"}[$j] = $sum / ($#splitbits + 1);
	  }
      }
      my($numperiods) = $#{$exptdata[$i]{"netcdf_periods"}};
      $exptdata[$i]{"netcdf_periods"}->[$numperiods + 1] = [0..$numperiods];
      $exptdata[$i]{"display_periods"}->[$numperiods + 1] = "All time slices";

      # Create timeslice mask
      @{$exptdata[$i]{"tsmask"}} = ($temp[9], @tpmask, @temp[6..8]);

      # Set up which timeslices are future
      @{$exptdata[$i]{"ts_future"}} = (0, @zeros, 1, 1, 1);

      # Set up which variables are absolute
      if($exptdata[$i]{"exptname"} =~ /^ABS/) {
	  @{$exptdata[$i]{"ts_abs"}} = (1, @ones, 1, 1, 1);
      } else {
	  @{$exptdata[$i]{"ts_abs"}} = (1, @ones, 0, 0, 0);
      }
      $exptdata[$i]{"yearly_start"} = $temp[13];
      $exptdata[$i]{"yearly_end"} = $temp[14];
      $exptdata[$i]{"proj_id"} = $temp[15];
      @{$exptdata[$i]{"varmask"}} = @temp[16..$#temp];
      @{$exptdata[$i]{"data_yearlist"}} = ();
      if($exptdata[$i]{'yearly_start'} != 0 && $exptdata[$i]{'yearly_end'} != 0) {
	  my($year);
	  for($year = $exptdata[$i]{'yearly_start'}; $year <= $exptdata[$i]{'yearly_end'}; $year++) {
	      push(@{$exptdata[$i]{'data_yearlist'}}, $year . "_" . $year);
	      push(@{$exptdata[$i]{"ts_abs"}}, 1);

	  }
      }

      # If model is part of PCIC model set...
      if(exists($PCICmhash{$temp[0]})) {
	  # If experiment/run is one of the chosen ones, put it in the set
	  if(exists($PCICehash1{$temp[5]})) {
	      push(@PCICset1, $i)
	  }
	  if(exists($PCICehash2{$temp[5]})) {
	      push(@PCICset2, $i)
	  }
      }

      if(exists($PCIC21{$temp[0]}) && exists($PCIC21{$temp[0]}{$temp[5]})) {
	  push(@PCICset21, $i);
      }

      if(exists($PCICTG{$temp[0]}) && exists($PCICTG{$temp[0]}{$temp[5]})) {
	  push(@PCICsetTG, $i);
      }

      if(exists($PCICPlanners{$temp[0]}) && exists($PCICPlanners{$temp[0]}{$temp[5]})) {
	  push(@PCICsetPlanners, $i);
      }

      push(@{$expthash{$temp[3] . " - " . substr($temp[5], 0, 2)}}, $i);
      push(@{$scenhash{$temp[3]}}, $i);
      push(@{$modelhash{$temp[3] . " - " . $temp[0]}}, $i);
    }
    $i++;
  }
  close($gcminfo);

  # Create a complete block of time period names
  my(@tp_ncdf) = @emptytp;
  @tp_ncdf[values(%tphash)] = keys(%tphash);
  my(@tp_display) = @tp_ncdf;
  for($j = 0; $j <= $#tp_ncdf; $j++) {
      $tp_ncdf[$j] =~ s/-/_/g;
  }

  # Multivars
  foreach(sort(keys(%modelhash))) {
    my($model) = $_;
    my($scen, $mname) = split(/ - /, $model);
    $expt[$i] = $scen . " - All " . $mname . " runs";
    $exptmulti[$i] = $modelhash{$model};
    %{$exptdata[$i]} = %{$exptdata[$exptmulti[$i]->[0]]};
    $exptdata[$i]{"modelname"} = $model;
    $exptdata[$i]{"scenario"} = $scen;
    @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tp_ncdf, @{$dat->[2]{"timeslice"}}[1..3]);
    @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tp_display, @{$dat->[0]{"timeslice"}}[1..3]);
    
    $exptdata[$i]{"varmask"} = get_multivar_availability($#{$exptdata[0]{"varmask"}}, $exptmulti[$i], \@exptdata);
    $exptdata[$i]{"tsmask"} = get_multits_availability($#{$exptdata[0]{"tsmask"}}, $exptmulti[$i], \@exptdata);
    $i++;
  }
  foreach(sort(keys(%expthash))) {
    my($exptbit) = $_;
    my($scen, $exptname) = split(/ - /, $exptbit);
    $expt[$i] = $scen . " - All " . $exptname . " experiments";
    $exptmulti[$i] = $expthash{$exptbit};
    %{$exptdata[$i]} = %{$exptdata[$exptmulti[$i]->[0]]};
    $exptdata[$i]{"exptname"} = $exptname;
    $exptdata[$i]{"scenario"} = $scen;
    @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tp_ncdf, @{$dat->[2]{"timeslice"}}[1..3]);
    @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tp_display, @{$dat->[0]{"timeslice"}}[1..3]);

    $exptdata[$i]{"tsmask"} = get_multits_availability($#{$exptdata[0]{"tsmask"}}, $exptmulti[$i], \@exptdata);
    $exptdata[$i]{"varmask"} = get_multivar_availability($#{$exptdata[0]{"varmask"}}, $exptmulti[$i], \@exptdata);
    $i++;
  }
  foreach(sort(keys(%scenhash))) {
    my($scen) = $_;
    $expt[$i] = $scen . " - All scenarios";
    $exptmulti[$i] = $scenhash{$scen};
    %{$exptdata[$i]} = %{$exptdata[$exptmulti[$i]->[0]]};
    $exptdata[$i]{"scenario"} = $scen;
    @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tp_ncdf, @{$dat->[2]{"timeslice"}}[1..3]);
    @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tp_display, @{$dat->[0]{"timeslice"}}[1..3]);

    $exptdata[$i]{"tsmask"} = get_multits_availability($#{$exptdata[0]{"tsmask"}}, $exptmulti[$i], \@exptdata);
    $exptdata[$i]{"varmask"} = get_multivar_availability($#{$exptdata[0]{"varmask"}}, $exptmulti[$i], \@exptdata);
    $i++;
  }

  # PCIC sets
  $expt[$i] = "SRES AR4 - !PCIC A2+B1";
  $exptmulti[$i] = \@PCICset1;
  %{$exptdata[$i]} = %{$exptdata[$exptmulti[$i]->[0]]};
  @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tp_ncdf, @{$dat->[2]{"timeslice"}}[1..3]);
  @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tp_display, @{$dat->[0]{"timeslice"}}[1..3]);
  $exptdata[$i]{"tsmask"} = get_multits_availability($#{$exptdata[0]{"tsmask"}}, $exptmulti[$i], \@exptdata);
  $exptdata[$i]{"varmask"} = get_multivar_availability($#{$exptdata[0]{"varmask"}}, $exptmulti[$i], \@exptdata);
  $i++;

  $expt[$i] = "SRES AR4 - !PCIC A2+B1+A1B";
  $exptmulti[$i] = \@PCICset2;
  %{$exptdata[$i]} = %{$exptdata[$exptmulti[$i]->[0]]};
  @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tp_ncdf, @{$dat->[2]{"timeslice"}}[1..3]);
  @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tp_display, @{$dat->[0]{"timeslice"}}[1..3]);
  $exptdata[$i]{"tsmask"} = get_multits_availability($#{$exptdata[0]{"tsmask"}}, $exptmulti[$i], \@exptdata);
  $exptdata[$i]{"varmask"} = get_multivar_availability($#{$exptdata[0]{"varmask"}}, $exptmulti[$i], \@exptdata);
  $i++;

  $expt[$i] = "SRES AR4 - !PCIC21 ensemble";
  $exptmulti[$i] = \@PCICset21;
  %{$exptdata[$i]} = %{$exptdata[$exptmulti[$i]->[0]]};
  @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tp_ncdf, @{$dat->[2]{"timeslice"}}[1..3]);
  @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tp_display, @{$dat->[0]{"timeslice"}}[1..3]);
  $exptdata[$i]{"tsmask"} = get_multits_availability($#{$exptdata[0]{"tsmask"}}, $exptmulti[$i], \@exptdata);
  $exptdata[$i]{"varmask"} = get_multivar_availability($#{$exptdata[0]{"varmask"}}, $exptmulti[$i], \@exptdata);
  $i++;

  $expt[$i] = "SRES AR4 - !PCIC TreeGen ensemble";
  $exptmulti[$i] = \@PCICsetTG;
  %{$exptdata[$i]} = %{$exptdata[$exptmulti[$i]->[0]]};
  @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tp_ncdf, @{$dat->[2]{"timeslice"}}[1..3]);
  @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tp_display, @{$dat->[0]{"timeslice"}}[1..3]);
  $exptdata[$i]{"tsmask"} = get_multits_availability($#{$exptdata[0]{"tsmask"}}, $exptmulti[$i], \@exptdata);
  $exptdata[$i]{"varmask"} = get_multivar_availability($#{$exptdata[0]{"varmask"}}, $exptmulti[$i], \@exptdata);
  $i++;

  $expt[$i] = "SRES AR4 - !PCIC Planners ensemble";
  $exptmulti[$i] = \@PCICsetPlanners;
  %{$exptdata[$i]} = %{$exptdata[$exptmulti[$i]->[0]]};
  @{$exptdata[$i]{"netcdf_periods"}} = ($dat->[2]{"timeslice"}[0], @tp_ncdf, @{$dat->[2]{"timeslice"}}[1..3]);
  @{$exptdata[$i]{"display_periods"}} = ($dat->[0]{"timeslice"}[0], @tp_display, @{$dat->[0]{"timeslice"}}[1..3]);
  $exptdata[$i]{"tsmask"} = get_multits_availability($#{$exptdata[0]{"tsmask"}}, $exptmulti[$i], \@exptdata);
  $exptdata[$i]{"varmask"} = get_multivar_availability($#{$exptdata[0]{"varmask"}}, $exptmulti[$i], \@exptdata);

  return (\@expt, \@exptmulti, \@exptdata);
}

# Fixes up the variables list in accordance with what is available
sub get_variables {
  my($lang, $s, $varmask, $dd) = @_;
  my($j, @varlist);

  # Fix up/change/remove variable choices
  for($j = 0; $j <= $#{$dd->{variable}}; $j++) {
    $varlist[$j] = $dd->{variable}[$j];
    if($j <= $#{$varmask}) {
      if($varmask->[$j] eq '9' || $varmask->[$j] eq 'd') {
	if($lang == 0) {
	  # English
	  $varlist[$j] = "Derived " . $dd->{'variable'}[$j];
	} elsif($lang == 1) {
	  # French (FIXME?)
	  $varlist[$j] .= " deriv&eacute;e";
	}
      } elsif($varmask->[$j] eq "*" || $varmask->[$j] eq "#") {
	if($varmask->[$j] eq "*") {
	  $varlist[$j] = $s->{'sur_sw_rad'};
	} elsif($varmask->[$j] eq "#") {
	  $varlist[$j] = $s->{'sur_pressure'};
	}
      } elsif(!is_available($varmask->[$j])) {
	$varlist[$j] = "";
      }
    }
  }
  return \@varlist;
}

# Gets variable availability list
sub get_var_availability_list {
  my($dd, $exptdata, $expt_no) = @_;
  return create_availability_list($dd->{'variable'}, $exptdata->[$expt_no]{'varmask'});
}

# Gets timeslice availability list
sub get_timeslice_availability_list {
  my($dd, $exptdata, $expt_no) = @_;
  my($expt) = $exptdata->[$expt_no];
  my($tslist) = create_availability_list($expt->{"display_periods"}, $expt->{'tsmask'});
  if($expt->{'yearly_start'} != 0 && $expt->{'yearly_end'} != 0) {
      push(@{$tslist}, ($expt->{'yearly_start'})..($expt->{'yearly_end'}));
  }
  return $tslist;
}

sub get_available_index_list {
  my($list) = @_;
  my(@retlist);
  my($i);

  for($i = 0; $i <= $#{$list}; $i++) {
    if(length($list->[$i]) && $list->[$i] !~ /^#/) {
      push(@retlist, $i);
    }
  }

  return \@retlist;
}

sub create_availability_list {
  my($list, $mask) = @_;
  my(@result, $i);

  for($i = 0; $i <= $#{$list}; $i++) {
    $result[$i] = (is_available($mask->[$i]) ? $list->[$i] : "");
    #print STDERR $mask->[$i] . ":" . $list->[$i] . ":" . $result[$i] . ", ";
  }
  print STDERR "\n";

  return \@result;
}

sub is_var_available {
  my($expt_no, $var, $exptdata) = @_;
  my($v) = $exptdata->[$expt_no]{'varmask'}[$var];

  return is_available($v);
}

sub is_timeslice_available {
  my($expt_no, $ts, $exptdata) = @_;
  my($v) = $exptdata->[$expt_no]{'tsmask'}[$ts];

  return is_available($v);
}

sub is_available {
  my($token) = @_;

  return (!defined($token) || !($token eq "o" || $token eq "0"));
}

# Returns 1 if a variable in post data is there and is numeric in form
sub post_is_numeric {
  my($POST, $varname) = @_;

  if(exists($POST->{$varname}) && is_numeric($POST->{$varname})) {
    return 1;
  } else {
    return 0;
  }
}

# Returns a random "name" string
# The returned should have about a 1e-38 probability of issuing the same name
# on the next run
sub make_random_name {
  my($post) = @_;
  my($stuff) = "";

  # Throw in -all- the POST data
  foreach(values(%{$post})) {
    $stuff .= fix_string($_);
  }

  # Make sure the filename's -really- random
  $stuff .= rand(10);

  # MD5sum it to perturb it a bit more
  return md5_hex($stuff);
}

# Makes a list of model-experiment combos
sub make_expt_list {
  my($var, $expt_no, $model, $exptdata) = @_;
  my(@expts, $i);

  for($i = 0; $i <= $#{$exptdata}; $i++) {
    if($model eq $exptdata->[$i]{'modelname'} && is_var_available($i, $var, $exptdata)) {
      push(@expts, $i);
    }
  }

  return @expts;
}

# Makes a list of available variable numbers
sub make_var_list {
  my($var, $expt_no, $exptdata, $dd, $d) = @_;
  my(@vars, $i);

  for($i = 0; $i <= $#{$dd->{'variable'}}; $i++) {
    if(is_var_available($expt_no, $var, $exptdata) && $d->{'variable'}[$i] !~ /^#/) {
      push(@vars, $i);
    }
  }

  return @vars;
}

sub remove_allvars {
  my($list, $data) = @_;
  my($i, @newlist);

  for($i = 0; $i <= $#{$list}; $i++) {
    $newlist[$i] = (is_multivar($data->[$i]) ? "" : $list->[$i]);
  }

  return \@newlist;
}

# Assumes InfoZip
sub make_zipfile {
  my($files, $filename, $cd) = @_;
  my($zipcmd) = $cd->{'zipcmd'};

  # -2 is about the compression/speed tradeoff. Try different values
  my(@params) = ($zipcmd, "-j", "-5", "-q", $filename, @{$files});

  print STDERR join(" ", @params) . "\n";

  if(system(@params) == 0) {
    return 1;
  } else {
    print STDERR $? . " foo\n";

    return 0;
  }
}

sub csv2html {
  my($csv, $tableclass) = @_;

  # Replace commas with table bits as appropriate
  $csv =~ s/\,\n$//s;

  # This is so unbelievably ill. Perl allows manipulation of the lvalue such
  # that the arg to substr ($csv) is modified in the next line.
  (substr($csv, 0, index($csv, "\n") + 1)) =~ s/\,(?!\n)/<\/th><th>/g;

  $csv =~ s/\,\n/<\/th><\/tr><tr><td>/s;
  $csv =~ s/\,\n/<\/td><\/tr><tr><td>/sg;
  $csv =~ s/\,/<\/td><td>/sg;

  # Return the complete table
  return "<table class=\"" . $tableclass . "\"><tr><th>" . $csv . "</td></tr></table>";
}

sub mod_desc_with_params { # FIXME this does some planners-specific stuff, which needs weeding out
    my($basedesc, $param) = @_;

    # Hack, but not FIXME or even TODO :)  This allows for nested arrays, allowing multiple descs for one chunk of image HTML...
    if (is_arrayref($param)) {
	return [ map { mod_desc_with_params($basedesc, $_) } @$param ];
    }

    ## Merge descs and clobber where appropriate. ##
    my($newdesc) = {%$basedesc, %$param};  #FIXME this needs some love to work correctly with things that use xvariable and yvariable -- added logic now but this might not be correct!

    ## Dupe fields that need it -- this is ugly and should NOT be necessary ##
    if ($newdesc->{'plot_type'} == TYPE_MAP) {
      $newdesc->{'xvariable'} = $newdesc->{'var'};  #FIXME really need to do something more intelligent based on whether these are already set and whether they SHOULD change together or not.
    }
    if (($newdesc->{'plot_type'} == TYPE_SCATTER_TIMESLICE_HIST) || ($newdesc->{'plot_type'} == TYPE_SCATTER_TIMESLICE_TEXT)) {
      $newdesc->{'sset'} = $newdesc->{'expt'};
      $newdesc->{'pctile'} = 1;  # FIXME this is planners-specific and shouldn't be here
    }

    return $newdesc;
}

sub make_descs_from_list {  #  TODO this is kind of redundant now, now isn't it...
  my($basedesc, $params) = @_;  # right now @params has keys [plot_type, var, expt] but perhaps this should use a hash or a fixed array of keys plus aligned arrays  FIXME

  [ map { mod_desc_with_params($basedesc, $_) } @$params ];
}

sub test_expression {
# Evaluates impact conditionals using eval()

# Assumes 3 underscore-delimited segments in data specifiers; this needs to be changed later FIXME

  my ($test, $plotdat_cache) = @_;

  print STDERR 'Testing: "' . $test . "\" => ";

  # Set up accesses to cache / genimage
  $test =~ s/([a-zA-Z0-9]*[a-zA-Z][a-zA-Z0-9]*(?:_[a-zA-Z0-9]*[a-zA-Z][a-zA-Z0-9]*){2})/ get_plotdat($plotdat_cache, $1) /g;
  print STDERR '"' . $test . '" => ';

  # Eval it (lazy eval now)
  my $returnme = eval $test;
  print STDERR ( $returnme ? "TRUE\n" : "FALSE\n" );

  return $returnme;
}

sub get_plotdat {
  my($plotdat_cache, $key) = @_;  # TODO this is getting huge, perhaps turn the whole thing into an object?
  my($cache, $basedesc, $ts, $hash, $texthash, $lut, $precision) = @{$plotdat_cache};  # TODO this is getting huge, perhaps turn the whole thing into an object?

  my $rows = {"10p" => "10th percentile ", "50p" => "Median ", "90p"  => "90th percentile "};

  if(defined($hash->{$key})) {
    return $hash->{$key};
  }
  if(defined($texthash->{$key})) {
    return $texthash->{$key};
  }

  my $data_key = 0;
  if ($key =~ s/^data://) {  #Looking for formatted value not numeric value
      $data_key = 1;
  }

  # TODO un-hardcode the order here?
  my($toy, $var, $row) = split('_', $key);

  (defined($lut->{'var'}->{$var})) or die "Invalid var in plotdat key: '" . $key . "'";
  (defined($lut->{'toy'}->{$toy})) or die "Invalid toy in plotdat key: '" . $key . "'";
  (defined($rows->{$row})) or die "Invalid row (percentile) in plotdat key: '" . $key . "'";

  my $desc_params = {var => $lut->{'var'}->{$var}, toy => $lut->{'toy'}->{$toy}};

  my $csv_hash = parse_csv($cache->create_cachefile(mod_desc_with_params($basedesc, $desc_params)));
  print STDERR "Retrieving plotdat item for var $var toy $toy\n";
  
  # Experiment-name-to-row (or percentile-to-row in our case) mapping
  my %exptkeys;
  @exptkeys{@{$csv_hash->{"Experiment"}}} = (0..(@{$csv_hash->{"Experiment"}} - 1));

  # The monkeys can touch the obelisk, but they do not understand its presence...
# old code from outside helpets  @{$hash}{map { join("_",@shortname_elements) . "_" . $_ } keys(%{$planners_plotdat_csv_rows})} = @{$csv_hash->{$timeslice}}[@exptkeys{values(%{$planners_plotdat_csv_rows})}];

  print STDERR "Added values to plotdat hash: " . join(", ", map{ "'" . $_ . "'" } @{$csv_hash->{$ts}}[@exptkeys{values(%{$rows})}]) . "\n";
  @{$hash}{map { "${toy}_${var}_${_}" } keys(%{$rows})} = @{$csv_hash->{$ts}}[@exptkeys{values(%{$rows})}];
  @{$texthash}{ map{ "data:${toy}_${var}_${_}" } keys(%{$rows}) } = map{ sprintf('%+.' . $precision->[$desc_params->{'var'}] . 'f', $_) } @{$csv_hash->{$ts}}[@exptkeys{values(%{$rows})}];  
 
  my $returnme;
  if ($data_key) {
    $returnme = $texthash->{'data:' . $key}
  } else {
    $returnme = $hash->{$key};
  }
  print STDERR "Returning value from cache: " . $returnme . "\n";
  return $returnme;
}

sub get_range {
  my ($var, $toy, $ts, $expt, $dat, $exptdata) = @_;

  if(is_ts_absolute($ts, $expt, $exptdata)) {
    if($dat->[14]->{'variable'}->[$var] == 1) {
      return  map { $_ * (($dat->[4]->{'timeofyear'}->[$toy] / $dat->[4]->{'timeofyear'}->[16]) ** $dat->[15]->{'variable'}->[$var]) } @{$dat->[5]->{variable}->[$var]};
    } else {
      return @{$dat->[5]->{variable}->[$var]};
    }
  } else {
    return @{$dat->[6]->{variable}->[$var]};
  }
}

return 1;
