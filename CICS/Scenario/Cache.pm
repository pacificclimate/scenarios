package CICS::Scenario::Cache;
use strict;

use File::Copy;
use Fcntl ':mode';
use CICS::Helpers;
use CICS::Scenario::Helpers;
use CICS::Scenario::Regions;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Exporter 'import';

our(@EXPORT) = qw(TYPE_MAP TYPE_TEXT TYPE_MASK TYPE_GEOREF TYPE_PLOTINFO TYPE_REGIONONLY TYPE_SCATTER_TIMESLICE TYPE_SCATTER_TIMESLICE_HIST TYPE_SCATTER_VARIABLE TYPE_SCATTER_TIMESLICE_TEXT TYPE_SCATTER_VARIABLE_TEXT TYPE_MAP_DIFFERENCE TYPE_SCENARIO_DATA TYPE_SLMASK_DATA TYPE_LATS_DATA TYPE_LONGS_DATA TYPE_BOXPLOT_TIMESLICE TYPE_BOXPLOT_TIMESLICE_TEXT TYPE_STICKPLOT TYPE_GEOTIFF TYPE_BANDS_TIMESLICE TYPE_BANDS_TIMESLICE_HIST TYPE_SCENARIO_SET_METADATA TYPE_MAX_GENIMAGE       TYPE_ZIP_ALLEXPT_GEOREF TYPE_ZIP_ALLEXPT TYPE_ZIP_ALLVAR_GEOREF TYPE_ZIP_ALLVAR TYPE_ZIP_ALLEXPTVAR_GEOREF TYPE_ZIP_ALLEXPTVAR TYPE_METADATA_CSV MAX_PLOT_TYPE create_output_filename);

use constant {
  TYPE_MAP => 0, TYPE_TEXT => 1, TYPE_MASK => 2, TYPE_GEOREF => 3, TYPE_PLOTINFO => 4, TYPE_REGIONONLY => 5, TYPE_SCATTER_TIMESLICE => 6, TYPE_SCATTER_TIMESLICE_HIST => 7, TYPE_SCATTER_VARIABLE => 8, TYPE_SCATTER_TIMESLICE_TEXT => 9, TYPE_SCATTER_VARIABLE_TEXT => 10, TYPE_MAP_DIFFERENCE => 11, TYPE_SCENARIO_DATA => 12, TYPE_SLMASK_DATA => 13, TYPE_LATS_DATA => 14, TYPE_LONGS_DATA => 15, TYPE_BOXPLOT_TIMESLICE => 16, TYPE_BOXPLOT_TIMESLICE_TEXT => 17, TYPE_STICKPLOT => 18, TYPE_GEOTIFF => 19, TYPE_BANDS_TIMESLICE => 20, TYPE_BANDS_TIMESLICE_HIST => 21, TYPE_SCENARIO_SET_METADATA => 22, TYPE_MAX_GENIMAGE => 22, TYPE_ZIP_ALLEXPT_GEOREF => 23, TYPE_ZIP_ALLEXPT => 24, TYPE_ZIP_ALLVAR_GEOREF => 25, TYPE_ZIP_ALLVAR => 26, TYPE_ZIP_ALLEXPTVAR_GEOREF => 27, TYPE_ZIP_ALLEXPTVAR => 28, TYPE_METADATA_CSV => 29, MAX_PLOT_TYPE => 30
};

use constant {
    ANOM_DEFAULT => 0, ANOM_ANOMALY => 1, ANOM_ABSOLUTE => 2
};

sub new {
  my($class, $in) = @_;
  my($self) = {};

  if(defined($in) && is_hashref($in)) {
    foreach(qw(cfg lang expt dat exptdata exptmulti regions prs)) {
      if(defined($in->{$_})) {
	$self->{$_} = $in->{$_};
      }
    }
  }

  bless($self, $class);

  $self->{ver} = 3;

  set_if_empty($self, "cfg", undef);
  set_if_empty($self, "lang", 0);
  set_if_empty($self, "dat", undef);
  set_if_empty($self, "expt", undef);
  set_if_empty($self, "exptdata", undef);
  set_if_empty($self, "exptmulti", undef);

  $self->fix_subrefs();

  return $self;
}

sub fix_subrefs {
  my($self) = @_;

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
  return $lang;
  return accessvar("dat", undef, @_);
}
sub expt {
  return accessvar("expt", undef, @_);
}
sub exptdata {
  return accessvar("exptdata", undef, @_);
}

# Creates an output aka display filename
sub create_output_filename {
  my($post, $exptdata, $d, $plot_type) = @_;
  if(!defined($plot_type)) {
    $plot_type = $post->{'plot_type'};
  }
  my(@args);
  
  my(@tslist) = (@{$exptdata->[$post->{'expt'}]{"netcdf_periods"}}, @{$exptdata->[$post->{'expt'}]->{'data_yearlist'}});

  # Images and metadata
  if($plot_type == TYPE_MAP || $plot_type == TYPE_TEXT 
     || $plot_type == TYPE_SCATTER_TIMESLICE || $plot_type == TYPE_SCATTER_TIMESLICE_HIST
     || $plot_type == TYPE_BANDS_TIMESLICE || $plot_type == TYPE_BANDS_TIMESLICE_HIST
     || $plot_type == TYPE_SCATTER_VARIABLE  || $plot_type == TYPE_BOXPLOT_TIMESLICE
     || $plot_type == TYPE_MAP_DIFFERENCE) {
    return "";
  }

  push(@args, $exptdata->[$post->{'expt'}]->{'modelname'},
       $exptdata->[$post->{'expt'}]->{'exptname'},
       $tslist[$post->{'ts'}],
       $d->{'variable'}->[$post->{'var'}],
       $d->{'region'}->[$post->{'region'}]);

  if($plot_type == -1) {
    # Data file
    $args[$#args] .= ".dat";
  } elsif($plot_type == TYPE_MASK) {
    @args = ($exptdata->[$post->{'expt'}]->{'modelname'}, "custom", "mask.dat");
  } elsif($plot_type == TYPE_GEOREF) {
    unshift(@args, "georef");
    if(length($post->{points}) > 0) {
      push(@args, "custom");
    }
    $args[$#args] .= ".dat";
  } elsif($plot_type == TYPE_GEOTIFF) {
    unshift(@args, "geotiff");
    if(length($post->{points}) > 0) {
      push(@args, "custom");
    }
    $args[$#args] .= ".tif";
  } elsif($plot_type == TYPE_SCATTER_TIMESLICE_TEXT) {
    @args = ("scatter", "timeslice", $d->{'variable'}->[$post->{'var'}], 
	     $d->{'region'}->[$post->{'region'}], $d->{sset}->[$post->{sset}],
	     $d->{stype}->[$post->{st}], $d->{timeofyear}->[$post->{toy}] . ".csv");
  } elsif($plot_type == TYPE_BOXPLOT_TIMESLICE_TEXT) {
    @args = ("boxplot", "timeslice", $d->{'variable'}->[$post->{'var'}], 
	     $d->{'region'}->[$post->{'region'}], $d->{sset}->[$post->{sset}],
	     $d->{stype}->[$post->{st}], $d->{timeofyear}->[$post->{toy}] . ".csv");
  } elsif($plot_type == TYPE_SCATTER_VARIABLE_TEXT) {
    @args = ("scatter", "variable", $d->{'variable'}->[$post->{'var'}], 
	     $d->{'variable'}->[$post->{'var2'}], $tslist[$post->{'ts'}],
	     $d->{'region'}->[$post->{'region'}], $d->{sset}->[$post->{sset}],
	     $d->{stype}->[$post->{st}], $d->{timeofyear}->[$post->{toy}] . ".csv");
  } elsif($plot_type == TYPE_SCENARIO_SET_METADATA) {
      @args = ("scenario_set", "metadata", $d->{'variable'}->[$post->{'var'}], 
	       $d->{'variable'}->[$post->{'var2'}], $tslist[$post->{'ts'}],
	       $d->{'region'}->[$post->{'region'}], $d->{sset}->[$post->{sset}],
	       $d->{stype}->[$post->{st}], $d->{timeofyear}->[$post->{toy}] . ".csv");
  } elsif($plot_type == TYPE_ZIP_ALLEXPT_GEOREF || $plot_type == TYPE_ZIP_ALLEXPT) {
    # Zipped data of all experiment data for the variable and model
    if($plot_type == TYPE_ZIP_ALLEXPT_GEOREF) {
      unshift(@args, "georef");
    }
    push(@args, $exptdata->[$post->{'expt'}]->{'modelname'}, $d->{'variable'}->[$post->{'var'}], "allexpt.zip");
  } elsif($plot_type == TYPE_ZIP_ALLVAR_GEOREF || $plot_type == TYPE_ZIP_ALLVAR) {
    # Zipped data of all variable data for the experiment and model
    if($plot_type == TYPE_ZIP_ALLVAR_GEOREF) {
      unshift(@args, "georef");
    }
    push(@args, $exptdata->[$post->{'expt'}]->{'modelname'}, $exptdata->[$post->{'expt'}]->{'exptname'}, "allvar.zip");
  } elsif($plot_type == TYPE_ZIP_ALLEXPTVAR_GEOREF || $plot_type == TYPE_ZIP_ALLEXPTVAR) {
    # Zipped data of all experiment and variable data for the model
    if($plot_type == TYPE_ZIP_ALLEXPTVAR_GEOREF) {
      unshift(@args, "georef");
    }
    push(@args, $exptdata->[$post->{'expt'}]->{'modelname'}, "all.zip");
  } elsif($plot_type == TYPE_METADATA_CSV) {
    push(@args, "metadata.csv");
  } elsif($plot_type >= TYPE_SLMASK_DATA && $plot_type <= TYPE_LONGS_DATA) {
    my(@types) = ("slmask", "lats", "longs");
    @args = ($exptdata->[$post->{'expt'}]->{'modelname'},
	     $types[$plot_type - TYPE_SLMASK_DATA],
	     $d->{'region'}->[$post->{'region'}] . ".dat");
  } elsif($plot_type == TYPE_SCENARIO_DATA) {
    $args[$#args] .= ".dat";
  }

  my($fn) = join("_", @args);
  $fn =~ s/ /_/g;

  return $fn;
}

sub make_pretty_datapoint {
  my($self, $dpoint) = @_;
  my($output) = "";
  my(@bits) = split(/:/, $dpoint);

  if($#bits > 0) {
    if($bits[0] < 0) {
      $output .= sprintf("%0.2fW", abs($bits[0]));
    } elsif($bits[0] == 0) {
      $output .= "0";
    } else {
      $output .= sprintf("%0.2fE", $bits[0]);
    }
    $output .= " ";
    if($bits[1] < 0) {
      $output .= sprintf("%0.2fS", abs($bits[1]));
    } elsif($bits[1] == 0) {
      $output .= "0";
    } else {
      $output .= sprintf("%0.2fN", $bits[1]);
    }
  }
  return $output;
}

sub make_difference_title {
  my($self, $desc) = @_;

  # Text to identify this graphic (printed in bottom left corner)

  my(@bits);
  my(@ddtslist) = (@{$self->{'exptdata'}->[$desc->{'expt'}]{"display_periods"}}, @{$self->{'exptdata'}->[$desc->{'expt'}]->{'data_yearlist'}});

  # Show either experiment or the difference
  my($exptdesc) = $self->{expt}->[$desc->{expt}];
  if($desc->{expt} != $desc->{expt_d}) {
      $exptdesc = $self->{expt}->[$desc->{expt_d}] . " minus " . $self->{expt}->[$desc->{expt}] . " ";
  }
  if(defined($desc->{baseline_expt}) && $desc->{baseline_expt} != "") {
      $exptdesc .= "(Baseline: " . $self->{expt}->[$desc->{baseline_expt}] . ")";
  }
  push(@bits, $exptdesc);

  # Show either the time of year or the difference
  if($desc->{toy} == $desc->{toy_d}) {
    push(@bits, $self->{dd}->{timeofyear}[$desc->{toy}]);
  } else {
    push(@bits, $self->{dd}->{timeofyear}[$desc->{toy_d}] . " minus " . $self->{dd}->{timeofyear}[$desc->{toy}]);
  }

  push(@bits, $self->get_var_text($desc->{vars}, $desc->{var}, $desc->{ts}, $desc->{expt}));

  # Show either the timeslice or the difference
  if($desc->{ts} == $desc->{ts_d}) {
    push(@bits, $ddtslist[$desc->{ts}]);
  } else {
    push(@bits, $ddtslist[$desc->{ts_d}] . " minus " . $ddtslist[$desc->{ts}]);
  }

  return join(" - ", @bits);
}

sub make_map_title {
  my($self, $desc) = @_;

  my(@ddtslist) = (@{$self->{'exptdata'}->[$desc->{'expt'}]{"display_periods"}}, @{$self->{'exptdata'}->[$desc->{'expt'}]->{'data_yearlist'}});
  my($exptdesc) = $self->{expt}->[$desc->{expt}];
  if(defined($desc->{baseline_expt}) && $desc->{baseline_expt} != "") {
      $exptdesc .= "(Baseline: " . $self->{expt}->[$desc->{baseline_expt}] . ")";
  }

  return join(" - ", $exptdesc, $self->{dd}->{timeofyear}[$desc->{toy}], $self->get_var_text($desc->{vars}, $desc->{var}, $desc->{ts}, $desc->{expt}), $ddtslist[$desc->{ts}]);
}

sub make_scatter_title {
  my($self, $desc, $type) = @_;
  my($expts) = $self->{expt}->[$desc->{expt}];
  if(defined($desc->{baseline_expt}) && $desc->{baseline_expt} != "") {
      $expts .= "(Baseline: " . $self->{expt}->[$desc->{baseline_expt}] . ")";
  }
  my($drtext) = "";

  my(@points) = split(/,/, $desc->{points});
  # Region
  if($#points == 0) {
    $drtext .= $self->make_pretty_datapoint($points[0]);
  } elsif($#points >= 2) {
    if($desc->{pr} > 0) {
      $drtext .= $self->{prs}->[$desc->{pr}];
    } else {
      $drtext .= "Custom region";
    }
  } else {
    $drtext .= "Entire map";
  }

  my($output);
  my(@ddtslist) = (@{$self->{'exptdata'}->[$desc->{'expt'}]{"display_periods"}}, @{$self->{'exptdata'}->[$desc->{'expt'}]->{'data_yearlist'}});
  my($future) = CICS::Scenario::Helpers::is_ts_future($desc->{ts}, $desc->{expt}, $self->{exptdata});
  if($type == TYPE_SCATTER_VARIABLE) {
    $output = join(" - ", $self->{dd}->{'timeofyear'}[$desc->{'toy'}], 
		   $ddtslist[$desc->{'ts'}], 
		   $desc->{vars}->[$desc->{'var'}] . (($future)?" Change":"") . " vs " .
		   $desc->{vars}->[$desc->{'var2'}] . (($future)?" Change":""),
		   $expts, $drtext);
  } elsif($type == TYPE_SCATTER_TIMESLICE || $type == TYPE_BOXPLOT_TIMESLICE) {
    $output = join(" - ", $self->{dd}->{'timeofyear'}[$desc->{'toy'}], 
		   $desc->{vars}->[$desc->{'var'}] . " Change",
		   $expts, $drtext);
    if($desc->{pctile}) {
      $output .= " - Weighted percentiles";
    }
  }

  return $output;
}

# Create an argument list to run genimage with given the input data
sub make_cmdlist {
  my($self, $desc, $of, $plot_type, $identify_text) = @_;
  my($dat_dec_places, $leg_dec_places, $reverse, $ocean);
  my($leg_text, $lon_text_spacing, $lat_text_spacing);
  my(@stuff);

  my(@tslist) = (@{$self->{'exptdata'}->[$desc->{'expt'}]->{"netcdf_periods"}}, @{$self->{'exptdata'}->[$desc->{'expt'}]->{'data_yearlist'}});

  # Make it possible to set the output file
  if(!defined($of)) {
    $of = "-";
  }

  foreach(keys(%{$desc})) {
    if(is_tainted($desc->{$_})) {
      print STDERR $_ . " tainted!\n";
    }
  }

  # Reverse colour map
  $reverse = $self->{dat}->[9]->{'variable'}->[$desc->{'var'}];

  # Override plot over ocean stuff if needed
  $ocean = $desc->{'ocean'};
  if($self->{dat}->[10]->{'variable'}->[$desc->{'var'}] != -1) {
    $ocean = $self->{dat}->[10]->{'variable'}->[$desc->{'var'}];
  }

  # Inform about missing files
  if(!stat($self->{cd}->{'genimage'})) {
    return [ "Missing file " . $self->{cd}->{'genimage'} . "\n" ];
  }

  # Configure anomalies properly
  my($anomaly) = ANOM_DEFAULT;
  if($self->{'exptdata'}->[$desc->{'expt'}]->{'ts_abs'}->[$desc->{'ts'}]) {
      $anomaly = ANOM_ABSOLUTE;
  } else {
      $anomaly = ANOM_ANOMALY;
  }

  # This will need to be replaced when zoom (and maybe other things) come in
  # FIXME ZOOM MOREDATA

  # Push all the stuff onto the argument list
  my($sset_list) = $self->{exptmulti}->[$desc->{sset}];
  print STDERR "sset: " . $desc->{sset} . ", sset resolved: " . $sset_list . "\n";
  push(@stuff, 
       $self->{cd}->{'genimage'},
       "--fringe-size=".$desc->{fringe_size},
       "--box-threshold=".$desc->{th},
       "--region=".$self->{d}->{region}->[$desc->{region}],
       "--model=".$self->{exptdata}->[$desc->{expt}]->{modelname},
       "--model2=".$self->{exptdata}->[$desc->{expt_d}]->{modelname},
       "--expt=".$self->{exptdata}->[$desc->{expt}]->{exptname},
       "--expt2=".$self->{exptdata}->[$desc->{expt_d}]->{exptname},
       "--timeslice=".$tslist[$desc->{ts}],
       "--timeslice2=".$tslist[$desc->{ts_d}],
       "--timeofyear=".$self->{d}->{timeofyear}->[$desc->{toy}],
       "--timeofyear2=".$self->{d}->{timeofyear}->[$desc->{toy_d}],
       "--resolution=".$desc->{res},
       "--identify-text=".$identify_text,
       "--output-file=".$of,
       "--ocean-plot=".$ocean,
       "--scenario-set=".join(",", is_arrayref($sset_list) ? @{$sset_list} : $sset_list),
       "--plot-type=".$plot_type,
       "--zoom=".$self->{d}->{'zoom'}->[$desc->{'zoom'}],
       "--center-point=".$desc->{'view_x'}.":".$desc->{'view_y'}.":0",
       "--use-anomalies=".$anomaly
      );
  if(defined($desc->{'x-axis-text'})) {
    push(@stuff, "--x-axis-text=".$desc->{'x-axis-text'});
  }
  if(defined($desc->{'y-axis-text'})) {
    push(@stuff, "--y-axis-text=".$desc->{'y-axis-text'});
  }
  if(defined($desc->{xvariable})) {
    push(@stuff, "--xvariable=".$self->{d}->{variable}->[$desc->{xvariable}]);
  }
  if(defined($desc->{yvariable})) {
    push(@stuff, "--yvariable=".$self->{d}->{variable}->[$desc->{yvariable}]);
  }

  if($self->{dat}->[13]->{'variable'}->[$desc->{'var'}] && CICS::Scenario::Helpers::is_ts_future($desc->{ts}, $desc->{expt}, $self->{exptdata})) {
    push(@stuff, "--percent-change-calculations");
  }
  if($desc->{'grid'}) {
    push(@stuff, "--show-grid");
  }
  if($desc->{'pctile'} && ($plot_type == TYPE_SCATTER_TIMESLICE || $plot_type == TYPE_SCATTER_TIMESLICE_HIST || $plot_type == TYPE_BANDS_TIMESLICE || $plot_type == TYPE_BANDS_TIMESLICE_HIST || $plot_type == TYPE_SCATTER_TIMESLICE_TEXT)) {
    push(@stuff, "--percentiles");
  }
  if($reverse) {
    push(@stuff, "--colour-map-inverse");
  }

  if(defined($desc->{'baseline_expt'}) && $desc->{'baseline_expt'} != "") {
      push(@stuff, "--baseline-expt=".$self->{exptdata}->[$desc->{baseline_expt}]->{exptname},
	           "--baseline-model=".$self->{exptdata}->[$desc->{baseline_expt}]->{modelname});
  }

  # Autorange from map input file (default, don't push anything down the pipe)
  if(!$desc->{'rt'}) {
    push(@stuff, "--dynamic-range");
  } else {
    push(@stuff, 
	 "--xrange-min=".$desc->{xrange_min},
	 "--xrange-max=".$desc->{xrange_max},
	 "--yrange-min=".$desc->{yrange_min},
	 "--yrange-max=".$desc->{yrange_max},
	);
  }

  if(defined($desc->{'no-region-vertices'}) && $desc->{'no-region-vertices'}) {
    push(@stuff, "--no-region-vertices");
  }

  foreach(@{str2coords($desc->{points})}) {
    push(@stuff, "--poly-point=".join(":", @{$_}));
  }

  #print STDERR "Command: " . join(" ", @stuff) . "\n";

  return \@stuff;
}

# Creates a unique filename for caching data (this could be improved)
sub create_cache_filename {
  my($self, $desc, $plot_type) = @_;
  my($extn, $dir, @parts, @bits);

  # Select appropriate extension, dir to put it in, and stuff to determine caching
  if($plot_type == TYPE_MAP) {
    @parts = qw(zoom view_x view_y th var expt toy ts region ocean grid res rt points r_min r_max lang fringe_size baseline_expt no-region-vertices);
    $extn = ".png";
    $dir = $self->{cd}->{'mcachedir'};
  } elsif($plot_type == TYPE_TEXT || $plot_type == TYPE_PLOTINFO) {
    @parts = qw(zoom view_x view_y th var expt toy ts region ocean res rt points r_min r_max fringe_size baseline_expt);
    $extn = ".dat";
    $dir = $self->{cd}->{'dcachedir'};
  } elsif($plot_type == TYPE_GEOREF || $plot_type == TYPE_MASK || $plot_type == TYPE_GEOTIFF) {
    @parts = qw(zoom view_x view_y th var expt toy ts region ocean points fringe_size baseline_expt);
    $extn = ".dat";
    $dir = $self->{cd}->{'dcachedir'};
  } elsif($plot_type == TYPE_REGIONONLY) {
    @parts = qw(zoom view_x view_y expt region res points lang no-region-vertices);
    $extn = ".png";
    $dir = $self->{cd}->{'mcachedir'};
  } elsif($plot_type == TYPE_SCATTER_TIMESLICE || $plot_type == TYPE_SCATTER_TIMESLICE_HIST || $plot_type == TYPE_BANDS_TIMESLICE || $plot_type == TYPE_BANDS_TIMESLICE_HIST || $plot_type == TYPE_SCATTER_TIMESLICE_TEXT || $plot_type == TYPE_BOXPLOT_TIMESLICE || $plot_type == TYPE_BOXPLOT_TIMESLICE_TEXT || $plot_type == TYPE_STICKPLOT || $plot_type == TYPE_SCENARIO_SET_METADATA) {
    if($plot_type == TYPE_STICKPLOT || $plot_type == TYPE_SCENARIO_SET_METADATA) {
      @parts = qw(zoom view_x view_y var expt toy ts region ocean lang pctile th points fringe_size baseline_expt);
    } else {
      @parts = qw(zoom view_x view_y var toy region ocean lang pctile th points fringe_size baseline_expt);
    }
    my($sset_list) = $self->{exptmulti}->[$desc->{sset}];
    my(@sset_bits) = is_arrayref($sset_list) ? @{$sset_list} : $sset_list;
    foreach(@sset_bits) {
	push(@bits, $self->{expt}->[$_]);
    }
    if($plot_type == TYPE_SCATTER_TIMESLICE || $plot_type == TYPE_SCATTER_TIMESLICE_HIST || $plot_type == TYPE_BANDS_TIMESLICE || $plot_type == TYPE_BANDS_TIMESLICE_HIST || $plot_type == TYPE_BOXPLOT_TIMESLICE || $plot_type == TYPE_STICKPLOT) {
      $extn = ".png";
      $dir = $self->{cd}->{'mcachedir'};
    } else {
      $extn = ".dat";
      $dir = $self->{cd}->{'dcachedir'};
    }
  } elsif($plot_type == TYPE_SCATTER_VARIABLE || $plot_type == TYPE_SCATTER_VARIABLE_TEXT) {
    @parts = qw(zoom view_x view_y var var2 toy region ocean lang ts th points fringe_size baseline_expt);
    my($sset_list) = $self->{exptmulti}->[$desc->{sset}];
    my(@sset_bits) = is_arrayref($sset_list) ? @{$sset_list} : $sset_list;
    foreach(@sset_bits) {
	push(@bits, $self->{expt}->[$_]);
    }
    if($plot_type == TYPE_SCATTER_VARIABLE) {
      $extn = ".png";
      $dir = $self->{cd}->{'mcachedir'};
    } else {
      $extn = ".dat";
      $dir = $self->{cd}->{'dcachedir'};
    }
  } elsif($plot_type == TYPE_MAP_DIFFERENCE) {
    @parts = qw(zoom view_x view_y th var expt expt_d toy toy_d ts ts_d region ocean grid res rt points r_min r_max lang fringe_size baseline_expt no-region-vertices);
    $extn = ".png";
    $dir = $self->{cd}->{'mcachedir'};
  } elsif($plot_type == TYPE_SCENARIO_DATA) {
    @parts = qw(zoom view_x view_y var expt ts region baseline_expt);
    $extn = ".dat";
    $dir = $self->{cd}->{'dcachedir'};
  } elsif($plot_type >= TYPE_SLMASK_DATA && $plot_type <= TYPE_LONGS_DATA) {
    @parts = qw(expt region baseline_expt);
    $extn = ".dat";
    $dir = $self->{cd}->{'dcachedir'};
  } elsif($plot_type == TYPE_ZIP_ALLEXPT_GEOREF || $plot_type == TYPE_ZIP_ALLEXPTVAR) {
    @parts = qw(th var expt toy ts region ocean points baseline_expt);
    $extn = ".zip";
    $dir = $self->{cd}->{'zcachedir'};
  }

  # Glom it all together
  foreach(@parts) {
      if(defined($desc->{$_})) {
	  push(@bits, $desc->{$_});
      }
  }

  my($md5text) = md5_hex(join("-", @bits) . $plot_type);

  # Create a directory hierarchy
  my($i);
  for($i = 0; $i < 2; $i++) {
    $dir .= substr($md5text, $i, 1) . "/";
    print STDERR "Checking " . $dir . "...\n";
    my(@statdat) = stat($dir);
    if($#statdat == -1) {
	print STDERR "Making dir " . $dir . "\n";
	if(!mkdir($dir)) {
	    print STDERR "Failed to create directory " . $dir . "\n";
	}
    } else {
      if(!S_ISDIR($statdat[2])) {
	print STDERR $dir . " is not a directory. Removing.\n";
	unlink($dir);
	print STDERR "Making dir " . $dir . "\n";
	if(!mkdir($dir)) {
	    print STDERR "Failed to create directory " . $dir . "\n";
	}
      }
    }
  }

  # Return the complete filename
  my($fn) = $dir . $md5text . $extn;
  return $fn;
}

sub get_var_text {
  my($self, $vars, $var, $ts, $expt) = @_;
  my($name);
  my($abs) = CICS::Scenario::Helpers::is_ts_absolute($ts, $expt, $self->{exptdata});

  $name = $vars->[$var];
  if(!$abs) {
    # Prediction
    $name .= " Change";
  }

  # Override plot over ocean stuff if needed
  if($self->{dat}->[10]->{'variable'}->[$var] != -1) {
    if($self->{dat}->[10]->{'variable'}->[$var] == 0) {
      $name .= " (land data only)";
    } elsif($self->{dat}->[10]->{'variable'}->[$var] == 2) {
      $name .= " (ocean data only)";
    }
  }

  if($abs) {
    # Baseline
    $name .= " (" . $self->{dat}->[3]->{variable}->[$var] . ")";
  } else {
    # Prediction
    $name .= " (" . $self->{dat}->[4]->{variable}->[$var] . ")";
  }

  return $name;
}

# Creates a file in the cache
# Returns undef if the file could not be created; otherwise returns filename
sub create_cachefile {
  my($self, $desc, $plot_type) = @_;
  my($INMAP, $OUTMAP);
  my($dataline, $identify_text);
  my($modelname) = $self->{exptdata}->[$desc->{'expt'}]->{'modelname'};

  if(!defined($plot_type)) {
    $plot_type = $desc->{plot_type};
  }

  $identify_text = "";

  # Set up a few goodies...
  if($plot_type >= TYPE_MAP && $plot_type <= TYPE_REGIONONLY) {
    # Text to identify this graphic (printed in bottom left corner)
    $identify_text = $self->make_map_title($desc);

    $desc->{'x-axis-text'} = $self->get_var_text($desc->{vars}, $desc->{var}, $desc->{ts}, $desc->{expt});
    $desc->{'y-axis-text'} = "";
    $desc->{xvariable} = $desc->{var};
    $desc->{xrange_min} = $desc->{r_min};
    $desc->{xrange_max} = $desc->{r_max};
    $desc->{yrange_min} = 0;
    $desc->{yrange_max} = 0;
  } elsif($plot_type == TYPE_SCATTER_TIMESLICE || $plot_type == TYPE_SCATTER_TIMESLICE_HIST || $plot_type == TYPE_BANDS_TIMESLICE || $plot_type == TYPE_BANDS_TIMESLICE_HIST || $plot_type == TYPE_SCATTER_TIMESLICE_TEXT || $plot_type == TYPE_BOXPLOT_TIMESLICE || $plot_type == TYPE_BOXPLOT_TIMESLICE_TEXT || $plot_type == TYPE_SCENARIO_SET_METADATA || $plot_type == TYPE_STICKPLOT) {
    # Text to identify this graphic (printed in bottom left corner)
    $identify_text = $self->make_scatter_title($desc, TYPE_SCATTER_TIMESLICE);

    # Always turn on dynamic range; this is for axis tickmark spacing
    $desc->{'rt'} = 0;
    my($ts_future) = $self->{exptdata}->[$desc->{expt}]{'ts_future'};
    my($i);
    for($i = 0; $i <= $#{$ts_future} && !$ts_future->[$i]; $i++) {}
    if($plot_type == TYPE_STICKPLOT) {  #HACK, FIXME.
	$desc->{'x-axis-text'} = "";
	$desc->{'y-axis-text'} = $self->get_var_text($desc->{'vars'}, $desc->{'var'}, $i, $desc->{expt});
    } else {
	$desc->{'x-axis-text'} = "Timeslice";
	$desc->{'y-axis-text'} = $self->get_var_text($desc->{'vars'}, $desc->{'var'}, $i, $desc->{expt});
    }
    $desc->{yvariable} = $desc->{var}
  } elsif($plot_type == TYPE_SCATTER_VARIABLE || $plot_type == TYPE_SCATTER_VARIABLE_TEXT) {
    # Text to identify this graphic (printed in bottom left corner)
    $identify_text .= $self->make_scatter_title($desc, TYPE_SCATTER_VARIABLE);

    # Always turn on dynamic range; this is for axis tickmark spacing
    $desc->{rt} = 0;
    $desc->{xvariable} = $desc->{var2};
    $desc->{yvariable} = $desc->{var};
    $desc->{'y-axis-text'} = $self->get_var_text($desc->{vars}, $desc->{var}, $desc->{ts}, $desc->{expt});
    $desc->{'x-axis-text'} = $self->get_var_text($desc->{vars}, $desc->{var2}, $desc->{ts}, $desc->{expt});
  } elsif($plot_type == TYPE_MAP_DIFFERENCE) {
    $identify_text .= $self->make_difference_title($desc);

    $desc->{'x-axis-text'} = $self->get_var_text($desc->{vars}, $desc->{var}, $desc->{ts}, $desc->{expt});
    $desc->{'y-axis-text'} = "";
    $desc->{xvariable} = $desc->{var};
    $desc->{xrange_min} = $desc->{r_min};
    $desc->{xrange_max} = $desc->{r_max};
    $desc->{yrange_min} = 0;
    $desc->{yrange_max} = 0;

    # Always turn on dynamic range; for now this is a good default
    $desc->{rt} = 0;
  } elsif($plot_type == TYPE_SCENARIO_DATA) {
    $identify_text .= $self->make_difference_title($desc);

    $desc->{'x-axis-text'} = $desc->{'y-axis-text'} = "";
    $desc->{xvariable} = $desc->{var};
  }

  # Get name of file in cache
  my($cachefile) = $self->create_cache_filename($desc, $plot_type);

  # Get parameter list to call executable with
  my(@params) = @{$self->make_cmdlist($desc, $cachefile, $plot_type, $identify_text)};

  # 1 element returned; error
  # FIXME THIS SHOULD BE MORE GRACEFUL
  if(!$#params) {
    print STDERR $params[0];
    return "";
  }

  # If file exists in the cache
  if(-e($cachefile)) {
    return $cachefile; # FIXME Return what?
  } else {
    if($plot_type >= TYPE_MAP && $plot_type <= TYPE_MAX_GENIMAGE) {
      my($i);

      # Need to make PATH "secure"
      $ENV{'PATH'} = "";

      for($i = 0; $i <= $#params; $i++) {
	if(is_tainted($params[$i])) {
	  print STDERR "Variable " . $i . " tainted: " . $params[$i] . "\n";
	}
      }

      print STDERR "'" . join("' '", @params) . "'\n";

      if(system(@params) == -1) {
	print STDERR "Couldn't exec genimage!\n";
      }

      if($? != 0) {
	if(($? >> 8) == 99) {
	  # File was already locked
	} else {
	  # Something bad happened
	  print STDERR "An error occurred running genimage\n";
	}
      }
    } elsif($plot_type >= TYPE_ZIP_ALLEXPT_GEOREF && $plot_type <= TYPE_ZIP_ALLEXPTVAR) {
      # "Special" plot types (zip files)
      my(@vars, @expts, @files, @timeslices);
      my($georef) = 0;
      my($dir) = $self->{cd}->{'tmpdir'} . make_random_name($desc) . "/";

      mkdir($dir);

      # List of available timeslices
      #@timeslices = @{get_available_index_list(get_timeslice_list($dd, $exptdata, $desc->{'expt'}))};
      my(@tslist) = (@{$self->{'exptdata'}->[$desc->{'expt'}]{"netcdf_periods"}}, @{$self->{'exptdata'}->[$desc->{'expt'}]->{'data_yearlist'}});
      @timeslices = @{get_available_index_list(remove_allvars(get_timeslice_list($self->{dd}, $self->{exptdata}, $desc->{'expt'}), \@tslist))};

      if($plot_type == TYPE_ZIP_ALLEXPT_GEOREF || $plot_type == TYPE_ZIP_ALLEXPT) {
	# Zipped data of all data for the variable and model
	# List of timeslices, list of experiments
	
	if($plot_type == TYPE_ZIP_ALLEXPT_GEOREF) {
	  $georef = 1;
	}

	# Cook up the stuff to generate / copy
	push(@vars, $desc->{'var'});
	@expts = make_expt_list($desc->{'var'}, $desc->{'expt'}, $modelname, $self->{exptdata});
      } elsif($plot_type == TYPE_ZIP_ALLVAR_GEOREF || $plot_type == TYPE_ZIP_ALLVAR) {
	# Zipped data of all data for the experiment and model
	# List of timeslices, list of variables
	
	if($plot_type == TYPE_ZIP_ALLVAR_GEOREF) {
	  $georef = 1;
	}
	
	# Cook up the stuff to generate / copy
	@vars = make_var_list($desc->{'var'}, $desc->{'expt'}, $self->{exptdata}, $self->{dd}, $self->{d});
	push(@expts, $desc->{'expt'});
      } elsif($plot_type == TYPE_ZIP_ALLEXPTVAR_GEOREF || $plot_type == TYPE_ZIP_ALLEXPTVAR) {
	# Zipped data of all data for the model
	# List of timeslices, list of variables, list of experiments
	
	if($plot_type == TYPE_ZIP_ALLEXPTVAR_GEOREF) {
	  $georef = 1;
	}
	
	# Cook up the stuff to generate / copy
	@vars = make_var_list($desc->{'var'}, $desc->{'expt'}, $self->{exptdata}, $self->{dd}, $self->{d});
	@expts = make_expt_list($desc->{'var'}, $desc->{'expt'}, $modelname, $self->{exptdata});
      }

      #print STDERR "VARS: " . join(",", @vars) . "\n";
      #print STDERR "EXPTS: " . join(",", @expts) . "\n";
      #print STDERR "TSES: " . join(",", @timeslices) . "\n";

      @files = $self->make_file_list($dir, $georef, \@vars, \@expts, \@timeslices, $desc);

      #print STDERR "FILES: " . join(",", @files) . "\n";

      if(!make_zipfile(\@files, $cachefile, $self->{cd})) {
	print STDERR "Couldn't create zip file!";
	return undef;
      }

      # Wipes out file list and directory (and zip file)
      # This code is dangerous, and thus commented out
      #unlink(@files);
      #rmdir($dir);
    }
  }

  return $cachefile;
}

# Makes a list of files (and ensures the files are present) given a list of
# expts and vars
sub make_file_list {
  my($self, $dir, $georef, $vars, $expts, $timeslices, $desc, $plot_type) = @_;
  my($modelname) = $self->{exptdata}->[$desc->{'expt'}]->{'modelname'};
  my(@files);

  my($prev_var) = $desc->{'var'};
  my($prev_expt) = $desc->{'expt'};
  my($prev_ts) = $desc->{'ts'};

  if($georef) {
    $plot_type = 6; # Georef data
  } else {
    $plot_type = -1; # Data file (phony)
  }

  # Run through all the var, expts, ts specified and create/copy the files
  foreach(@{$timeslices}) {
    my($ts) = $_;
    $desc->{ts} = $ts;
    foreach(@{$vars}) {
      my($var) = $_;
      $desc->{'var'} = $var;
      foreach(@{$expts}) {
	my($exptbit) = $_;
	my($outputfile, $inputfile);
	$desc->{'expt'} = $exptbit;

	# MAKE SURE IT IS ALL COPIES
	if($georef) {
	  $outputfile = create_output_filename($desc, $self->{exptdata}, $self->{d}, $plot_type);
	  # This is commented out so georef is always generated
	  #if($desc->{'xpoint2'}) {
	    $inputfile = $self->create_cachefile($desc);
	  #} else {
	  #  $inputfile = $self->{cd}->{'datadir'} . $outputfile;
	  #}
	} else {
	  $outputfile = create_output_filename($desc, $self->{exptdata}, $self->{d}, $plot_type);
	  # FIXME THIS IS GONE
	  $inputfile = $self->{cd}->{'datadir'} . $outputfile;
	}
	$outputfile = $dir . $outputfile;
	if(!copy($inputfile, $outputfile)) {
	  print STDERR "Couldn't copy file " . $inputfile . " to " . $outputfile . "\n";
	}
	push(@files, $outputfile);
      }
    }
  }

  if($georef) {
    # Nothing to do
  } else {
    # Create the region mask
    $desc->{'plot_type'} = 5; # Region mask
    my($cachefile) = $self->create_cachefile($desc, $plot_type);
    my($outputfile) = $dir . create_output_filename($desc, $self->{exptdata}, $self->{d});
    copy($cachefile, $outputfile);
    push(@files, $outputfile);
  }

  $desc->{'var'} = $prev_var;
  $desc->{'expt'} = $prev_expt;
  $desc->{'ts'} = $prev_ts;

  return @files;
}

sub is_cacheable {
  my($self, $desc) = @_;
  return (length($desc->{points}) == 0 || (defined($desc->{'pr'}) && $desc->{'pr'} != 0));
}

return 1;
