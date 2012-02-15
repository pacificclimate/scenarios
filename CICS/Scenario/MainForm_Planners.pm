package CICS::Scenario::MainForm_Planners;
use strict;

use CICS::Helpers;
use CICS::Scenario::Helpers;
use CICS::Scenario::Cache;

use CICS::FormHandler::Form;
use CICS::FormHandler::FormBit;
use CICS::FormHandler::Textbox;
use CICS::FormHandler::Checkbox;
use CICS::FormHandler::Hiddenfield;
use CICS::FormHandler::Textfield;
use CICS::FormHandler::Selectfield;
use CICS::FormHandler::Submitbutton;
use CICS::FormHandler::Radiobutton;
use CICS::FormHandler::PointList;
use CICS::FormHandler::Point;

use constant {
  OP_ADD => 1, OP_SELECT => 2, OP_MOVE => 3
};

use constant {
  DESELECT_PT => 0, REMOVE_PT => 1, CLEAR_PTS => 3
};

# Idea: Can stick list of available expts / vars in the 'desc' along with orig post data

sub ltcomp {
    return($_[0] < $_[1]);
}

sub new {
  my($class, $in) = @_;
  my($self) = {};

  if(defined($in) && is_hashref($in)) {
    foreach(qw(post cfg lang expt dat str exptmulti exptdata prs regions cache action)) {
      if(defined($in->{$_})) {
	$self->{$_} = $in->{$_};
      }
    }
  } else {
    die("Can't create a new MainForm without sufficient input data");
  }

  $self->{templatebits} = {};

  $self->{exptorder} = [order(@{$self->{expt}})];

  print STDERR join(", ", @{$self->{exptorder}}) . "\n";

  my($wrapper) = defined($in->{wrapper});

  fix_subrefs($self);


  # Get and store list of available vars and timeslices (with this expt)
  $self->{vars} = get_variables($self->{lang}, $self->{ss}, $self->{exptdata}->[$self->{post}->{expt}]->{varmask}, $self->{dd});
  $self->{ts} = get_timeslice_availability_list($self->{dd}, $self->{exptdata}, $self->{post}->{expt});
  $self->{oldts} = get_timeslice_availability_list($self->{dd}, $self->{exptdata}, $self->{post}->{oldexpt});

  $self->{expt2} = remove_allvars($self->{expt}, $self->{exptmulti});
  $self->{vars2} = remove_allvars($self->{dd}->{variable}, $self->{d}->{variable});
  $self->{tsds} = remove_allvars($self->{ts}, $self->{d}->{timeslice});
  $self->{toyds} = remove_allvars($self->{dd}->{timeofyear}, $self->{d}->{timeofyear});


  #  FIXME
  if(defined($self->{post}->{planners}) && !defined($in->{wrapper})) {
      #FIXME HACK HACK HACK HACK HACK


# TEMP 2010-06-01      @{$self->{dd}->{timeofyear}}[(0..11,17..19)] = "";
      @{$self->{dd}->{timeofyear}}[(17..19)] = "";
      # No complex times of year
      @{$self->{dd}->{timeofyear}}[(17..19)] = "";
      # Per TQM 2011-08 removing monthly
      @{$self->{dd}->{timeofyear}}[(0..11)] = "";



      $self->{prs}->[0] = "British Columbia";

      $self->{ts}[0] = "";
      $self->{ts}[4] = "";
      $self->{ts}[10] = "";  #FIXME HACK

  }
  
  # Go through the list of regions, removing ones that aren't appropriate for the given experiment's projection ID

  print STDERR "proj_id: " . $self->{exptdata}->[$self->{post}->{expt}]{"proj_id"} . "\n";

  my($i);
  my(@region_defaults) = (4, 5, 6);
  my($expt_projid) = $self->{exptdata}->[$self->{post}->{expt}]{"proj_id"};
  my($region_default) = $region_defaults[$expt_projid];
  for($i = 0; $i <= $#{$self->{dd}->{region}}; $i++) {
      if($self->{dat}->[3]{"region"}[$i] == $expt_projid) {
	  $self->{regionlist}[$i] = $self->{dd}->{region}[$i];
      } else {
	  $self->{regionlist}[$i] = "";
      }
  }

  my($ts_default) = 8; # PI
  if(!length($self->{ts}->[$ts_default])) {
      for($i = 0; $i <= $#{$self->{ts}}; $i++) {
	  if(length($self->{ts}->[$i])) {
	      $ts_default = $i;
	      $i = $#{$self->{ts}} + 1;
	  }
      }
  }

  # Get first available var
  if(!defined($self->{post}->{var}) || !length($self->{vars}->[$self->{post}->{var}])) {
      if(defined($self->{post}->{planners})) {  #FIXME kill this crap for planners
	  $self->{post}->{var} = 21;
      } else {
	  for($i = 0; $i <= $#{$self->{vars}}; $i++) {
	      if(length($self->{vars}->[$i])) {
		  $self->{post}->{var} = $i;
		  $i = $#{$self->{vars}} + 1;
	      }
	  }
      }
  }

  my($form) = CICS::FormHandler::Form->new({action => $in->{action}});
  $self->{form} = $form;

  # Experiment
  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'baseline_expt', allow_empty => 1, numeric => 1, value => "", allowed_values => $self->{expt2}}));

  if(defined($self->{post}->{planners})) {
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => "planners", allow_empty => 0, numeric => 1, value => 1, allowed_values => [0, 1]}));

      # Experiment
      $form->addBit(CICS::FormHandler::Selectfield->new({name => 'expt', allow_empty => 0, numeric => 1, value => 203, allowed_values => $self->{expt}}));

      # Old Experiment
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldexpt', allow_empty => 0, numeric => 1, value => 203, allowed_values => $self->{expt}}));

      # Variable    FIXME planners does not have variable!
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'var', allow_empty => 0, numeric => 1, value => 20, allowed_values => $self->{vars}}));

      # Old Variable    FIXME planners does not have variable!
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldvar', allow_empty => 0, numeric => 1, value => -1, allowed_values => $self->{vars}}));

      # Predefined region
      $form->addBit(CICS::FormHandler::Selectfield->new({name => 'pr', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{prs}}));

      # Old Predefined region
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldpr', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{prs}}));

      # Selected tab    FIXME not in planners
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'seltab', allow_empty => 1, numeric => 1, value => 0, allowed_values => [ 0, 1, 2, 3 ]}));

      # Region   FIXME this is not in planners but it could just be defaulted here
      $form->addBit(CICS::FormHandler::Selectfield->new({name => 'region', allow_empty => 0, numeric => 1, value => 4, allowed_values => $self->{regionlist}}));   # Both of these were defaulted to 5 for some reason.
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldregion', allow_empty => 0, numeric => 1, value => 4, allowed_values => $self->{regionlist}}));

      # Fringe size  TODO for now this has to be 0 because genimage poly expansion code is broken. Used to be 0.1.
      $form->addBit(CICS::FormHandler::Textfield->new({name => 'fringe_size', allow_empty => 0, numeric => 1, value => 0, width => 4, cssclass => 'tf'}));

      # Disable region vertices
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'no-region-vertices', allow_empty => 1, value => 1}));      
  } else {
      # Experiment
      $form->addBit(CICS::FormHandler::Selectfield->new({name => 'expt', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{expt}, value_order => $self->{exptorder}}));

      # Old Experiment
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldexpt', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{expt}}));

      # Variable
      $form->addBit(CICS::FormHandler::Selectfield->new({name => 'var', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{vars}}));

      # Old Variable
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldvar', allow_empty => 0, numeric => 1, value => -1, allowed_values => $self->{vars}}));

      # Predefined region
      $form->addBit(CICS::FormHandler::Selectfield->new({name => 'pr', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{prs}}));

      # Old Predefined region
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldpr', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{prs}}));

      # Selected tab
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'seltab', allow_empty => 1, numeric => 1, value => 0, allowed_values => [ 0, 1, 2, 3 ]}));

      # Region
      $form->addBit(CICS::FormHandler::Selectfield->new({name => 'region', allow_empty => 0, numeric => 1, value => $region_default, allowed_values => $self->{regionlist}}));
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldregion', allow_empty => 0, numeric => 1, value => $region_default, allowed_values => $self->{regionlist}}));

      # Fringe size TODO for now this has to be 0 because genimage poly expansion code is broken.  Used to be 0.5.
      $form->addBit(CICS::FormHandler::Textfield->new({name => 'fringe_size', allow_empty => 0, numeric => 1, value => 0, width => 4, cssclass => 'tf'}));

      # Disable region vertices
      $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'no-region-vertices', allow_empty => 1, value => 0}));      
  }

  # Timeslice
  $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldts', allow_empty => 0, numeric => 1, value => 1, allowed_values => $self->{oldts}}));
#  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'ts', allow_empty => 0, numeric => 1, value => $ts_default, allowed_values => $self->{ts}}));
  $form->addBit(CICS::FormHandler::Radiobutton->new({name => 'ts', separator => "<br/><br/>", allow_empty => 0, numeric => 1, value => $ts_default, allowed_values => $self->{ts}}));

  # Language
  $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'lang', allow_empty => 0, numeric => 1, value => 0, allowed_values => [0, 1]}));

  # Experiment for difference
  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'expt_d', allow_empty => 0, numeric => 1, value => 8, allowed_values => $self->{expt2}}));

  # Threshold
  $form->addBit(CICS::FormHandler::Textfield->new({name => "th", allow_empty => 0, numeric => 1, value => 0.10, width => 4, cssclass => "tf"}));

  # Timeslice for difference    FIXME planners does not have (?)
  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'ts_d', allow_empty => 0, numeric => 1, value => $ts_default, allowed_values => $self->{tsds}}));

  # Time of year   FIXME planners needs to do something clever based on this
  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'toy', allow_empty => 0, numeric => 1, value => 16, allowed_values => $self->{dd}->{timeofyear}}));

  # Time of year for difference
  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'toy_d', allow_empty => 0, numeric => 1, value => 16, allowed_values => $self->{toyds}}));

  # Resolution of map image
  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'res', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{dd}->{resolution}}));
  $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'oldres', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{dd}->{resolutions}}));

  # Second variable    FIXME planners does not have variable!
  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'var2', allow_empty => 0, numeric => 1, value => 1, allowed_values => $self->{vars2}}));;

  # FIXME PLANNERS DOES NOT HAVE ANY OF THE NEXT 4

  # Percentiles
  $form->addBit(CICS::FormHandler::Checkbox->new({name => 'pctile', allow_empty => 1, value => 0}));

  # Display ts scatter plot data
  $form->addBit(CICS::FormHandler::Checkbox->new({name => 'sptsdata', allow_empty => 1, value => 0}));

  # Display bp scatter plot data
  $form->addBit(CICS::FormHandler::Checkbox->new({name => 'spbpdata', allow_empty => 1, value => 0}));

  # Display var scatter plot data
  $form->addBit(CICS::FormHandler::Checkbox->new({name => 'spvardata', allow_empty => 1, value => 0}));



  # Zoom
  $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'zoom', allow_empty => 0, numeric => 1, value => 0, allowed_values => [ 0..$#{$self->{d}->{'zoom'}} ]}));

  # Ocean
  $form->addBit(CICS::FormHandler::Checkbox->new({name => 'ocean', allow_empty => 1, value => 0}));

  # Range type
  $form->addBit(CICS::FormHandler::Radiobutton->new({name => 'rt', separator => "<br/>", value => 1, allowed_values => [ "Auto", "Fixed Range" ]}));

  # Points
  $form->addBit(CICS::FormHandler::PointList->new({name => 'points', allow_empty => 1, numeric => 1, value => ""}));

  # Data point
  $form->addBit(CICS::FormHandler::Point->new({name => 'dpoint', allow_empty => 1, numeric => 1, value => ""}));

  # Number of decimal places
  $form->addBit(CICS::FormHandler::Selectfield->new({name => 'numdatdec', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{dd}->{numdatdec}}));

  # Metadata Percentiles
  $form->addBit(CICS::FormHandler::Checkbox->new({name => 'md_pctile', allow_empty => 1, value => 0}));

  # Grid
  $form->addBit(CICS::FormHandler::Checkbox->new({name => 'grid', allow_empty => 1, value => 0}));

  # Update button
  $form->addBit(CICS::FormHandler::Submitbutton->new({name => 'update', cssclass => "submit", allowed_values => [ $self->{ss}->{update} ], extra => "onclick=\"this.disabled=true; unsetAllOnclicks(); this.value='Updating...'; this.form.submit();\""}));

  if($wrapper) {
    # Plot type
    $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'plot_type', allow_empty => 0, numeric => 1, value => 0, allowed_values => [ 0..MAX_PLOT_TYPE ]}));
    $form->{only_allow_valid} = 0;
    print STDERR "wrapper\n";
  } else {
    # Suggest Region
    $form->addBit(CICS::FormHandler::Textfield->new({name => "r_name", allow_empty => 1, numeric => 0, value => "", width => 40, cssclass => "tf"}));
    $form->addBit(CICS::FormHandler::Textfield->new({name => "p_name", allow_empty => 1, numeric => 0, value => "", width => 30, cssclass => "tf"}));
    $form->addBit(CICS::FormHandler::Textfield->new({name => "p_email", allow_empty => 1, numeric => 0, value => "", width => 30, cssclass => "tf"}));
    $form->addBit(CICS::FormHandler::Submitbutton->new({name => 'suggest', cssclass => "submit", allowed_values => [ "Suggest Region" ]}));

    # Region / point operations
    # These are in here so that the wrapper cannot perform operations on the
    # region; to do so is always wrong.
    $form->addBit(CICS::FormHandler::Selectfield->new({name => 'op', allow_empty => 0, numeric => 1, value => 0, allowed_values => $self->{dd}->{image_ops}}));
    $form->addBit(CICS::FormHandler::Submitbutton->new({name => 'bop', cssclass => "submit", allowed_values => $self->{dd}->{button_ops}}));
    print STDERR "mainform\n";
  }

  # Populate the first time, to get in data that's needed for the next stage
  $form->populate($self->{post});

  $form->untaint();
  bless($self, $class);

  my($hash) = $self->{form}->get_datahash();

  # Add in scatter plot scenario set
  $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'sset', allow_empty => 1, numeric => 1, value => $hash->{expt}, allowed_values => $self->{expt}}));

  my($temp_pd_filename) = $self->{cache}->create_cachefile($self->get_first_desc($hash), TYPE_TEXT);
  print STDERR "temp_pd_filename is $temp_pd_filename\n";
  my($temp_pd) = CICS::Scenario::Helpers::parse_textdata($temp_pd_filename);

  # x (lon) and y (lat) center coordinates for zoomed window centre, if different from window centre  FIXME allowed_range not implemented yet!!  FIXME need to deal with other projections here...
  $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'view_x', numeric => 1,
						     value => ($temp_pd->{'mapminlon'} + $temp_pd->{'mapmaxlon'}) / 2,
						     allowed_range => [ $temp_pd->{'mapminlon'},
									$temp_pd->{'mapmaxlon'} ]}));
  $form->addBit(CICS::FormHandler::Hiddenfield->new({name => 'view_y', numeric => 1,
						     value => ($temp_pd->{'mapminlat'} + $temp_pd->{'mapmaxlat'}) / 2,
						     allowed_range => [ $temp_pd->{'mapminlat'},
									$temp_pd->{'mapmaxlat'} ]}));


  # Default the ranges upon change of var or switch of ts from baseline to
  # prediction or vice versa
  if(($hash->{oldvar} != $hash->{var}) || is_ts_absolute($hash->{oldts}, $hash->{expt}, $self->{exptdata}) != is_ts_absolute($hash->{ts}, $hash->{expt}, $self->{exptdata})) {
    ($self->{post}->{r_min}, $self->{post}->{r_max}) = (undef, undef);
    print STDERR "ts: " . $hash->{ts} . "\n";
    print STDERR "oldts: " . $hash->{oldts} . "\n";
  }

  if(is_ts_absolute($hash->{ts}, $hash->{expt}, $self->{exptdata})) {
      print STDERR "TS ABSOLUTE\n";
  }

  # Set up error messages if experiment changed
  if($hash->{oldexpt} != $hash->{expt}) {
    my($var) = $form->getBitByName("var");
    my($ts) = $form->getBitByName("ts");

    $var->{errmsg} = $self->{ss}->{varerrmsg};
    $ts->{errmsg} = $self->{ss}->{tserrmsg};
  }

  if(is_multivar($self->{d}->{variable}->[$hash->{var}])) {
    $form->addBit(CICS::FormHandler::Textfield->new({name => "r_min", allow_empty => 0, numeric => 1, value => 0, width => 2, cssclass => "tf"}));
    $form->addBit(CICS::FormHandler::Textfield->new({name => "r_max", allow_empty => 0, numeric => 1, value => 0, width => 2, cssclass => "tf"}));
  } else {
    # Defaults for prediction vs baseline
    my($min, $max) = get_range($hash->{var}, $hash->{toy}, $hash->{ts}, $hash->{expt}, $self->{dat}, $self->{exptdata}); #TODO TESTME

#    if(is_ts_absolute($hash->{ts}, $hash->{expt}, $self->{exptdata})) {
#      if($self->{dat}->[14]->{'variable'}->[$hash->{var}] == 1) {
#	my $factor = (($self->{dat}->[4]->{'timeofyear'}->[$hash->{toy}] / $self->{dat}->[4]->{'timeofyear'}->[16]) ** $self->{dat}->[15]->{'variable'}->[$hash->{var}]);
#	print STDERR "Factor is $self->{dat}->[4]->{'timeofyear'}->[$hash->{toy}] / $self->{dat}->[4]->{'timeofyear'}->[16] ** $self->{dat}->[15]->{'variable'}->[$hash->{var}] = $factor.\n";
#	($min, $max) = @{$self->{dat}->[5]->{variable}->[$hash->{var}]};
#	$min *= $factor; $max *= $factor;
#      } else {
#	($min, $max) = @{$self->{dat}->[5]->{variable}->[$hash->{var}]};
#      }
#    } else {
#      ($min, $max) = @{$self->{dat}->[6]->{variable}->[$hash->{var}]};
#    }




    $form->addBit(CICS::FormHandler::Textfield->new({name => "r_min", allow_empty => 0, numeric => 1, value => $min, width => 2, cssclass => "tf"}));
    $form->addBit(CICS::FormHandler::Textfield->new({name => "r_max", allow_empty => 0, numeric => 1, value => $max, width => 2, cssclass => "tf"}));
  }

  # Figure out region map clicks
  if(is_numeric($self->{post}->{'regionmap.x'}) && is_numeric($self->{post}->{'regionmap.y'})) {
      print STDERR "Aieee!\n";
    if($self->handle_regionmapclick($form, $hash)) {
      # If region has changed, default the "predefined region" box to "Custom Region"
      $self->{post}->{pr} = $hash->{pr} = $hash->{oldpr} = $#{$self->{regions}};
    }

    # Make sure the wrapper does not have this information...
    # This is bug prevention paranoia
    $self->{post}->{'regionmap.x'} = $self->{post}->{'regionmap.y'} = "";
  }

  # Button clicks
  if(!$wrapper && length($hash->{bop})) {
    if($self->handle_buttons($form, $hash)) {
      # If region has changed, default the "predefined region" box to "Custom Region"
      $self->{post}->{pr} = $hash->{pr} = $hash->{oldpr} = $#{$self->{regions}};
    }
  }

  # Suggest Region
  if(defined($hash->{suggest}) && length($hash->{suggest})) {
    $hash->{r_name} =~ s/^\s*(.*?)\s*$/$1/;
    if(is_polygon($hash->{points})) {
      if(length($hash->{r_name})) {
	foreach(qw(r_name p_name p_email)) {
	  $self->{post}->{$_} = "";
	}
	$self->{templatebits}->{suggestresult} = "Region " . $hash->{r_name} . " suggested";
	suggest_region($hash->{th}, $hash->{r_name}, $hash->{p_name}, $hash->{p_email}, $hash->{points}, $self->{cd}->{contact_email}, $self->{cd}->{email_from});
      } else {
	$self->{templatebits}->{suggestresult} = "Please choose a region name";
      }
    } else {
      $self->{templatebits}->{suggestresult} = "Please select a region first";
    }
  }

  # Unset the predefined flag if the threshold changes
  if($hash->{pr} == $hash->{oldpr} && $hash->{th} != $self->{regions}->[$hash->{pr}]->{threshold}) {
    $self->{post}->{pr} = $hash->{pr} = $hash->{oldpr} = $#{$self->{regions}};
  }

  # Predefined region handling (NEEDS TO BE AFTER LAST POPULATE)
#  if(($hash->{pr} != 0 || $hash->{oldpr} != 0) && ($hash->{pr} != $#{$self->{regions}} || $hash->{oldpr} != $#{$self->{regions}})) {  PI -- doesn't have custom region!
  if($hash->{pr} != 0 || $hash->{oldpr} != 0) {
    $self->{post}->{points} = $self->{regions}->[$hash->{pr}]->{coords};
    $self->{post}->{th} = $self->{regions}->[$hash->{pr}]->{threshold};
    if(defined(($self->{post}->{planners}) || 1) && !$wrapper) { # FIXME take out the 1 once planners frontend can be used for testing images.  TESTME try removing this and see what happens
      if ($hash->{pr} == 0) { # we have CHANGED TO no region, so clear zoom and view_[xy] -- this relies on populate being called later again.
	  print STDERR "Resetting zoom.\n";
        delete $self->{post}->{'view_x'};
        delete $self->{post}->{'view_y'};
        $self->{post}->{'zoom'} = 0; 
# PI      } elsif ($hash->{pr} != $#{$self->{regions}}) { # we have changed to a predefined (as opposed to custom) region, so autozoom.
      } else { # we have changed to a predefined (as opposed to custom) region, so autozoom.
	my $temp_pd_desc = { %{$self->get_first_desc($hash)}, plot_type => TYPE_TEXT, expt => 209, ts => 0, ts_d => 0, region => 5, zoom => 0};  #FIXME hardcoded for Planners; need a more elegant solution to getting correct projection here.
	my($temp_pd) = CICS::Scenario::Helpers::parse_textdata($self->{cache}->create_cachefile($temp_pd_desc , TYPE_TEXT));

	my($windowwidth, $windowheight) = ($temp_pd->{'mapmaxlon'} - $temp_pd->{'mapminlon'}, $temp_pd->{'mapmaxlat'} - $temp_pd->{'mapminlat'}); # in native units, not necessarily degrees.

	my($minregiony, $maxregiony, $minregionx, $maxregionx) = (9999999999,-9999999999,9999999999,-9999999999);

	my $proj4;
	if(defined($temp_pd->{proj4_string}) && $temp_pd->{proj4_string} ne "") {
	  $proj4 = Geo::Proj4->new($temp_pd->{proj4_string}) or die "parameter error: ".Geo::Proj4->error. "\n";
#	  $proj4 = Geo::Proj4->new('+init=epsg:3005') or die "parameter error: ".Geo::Proj4->error. "\n";
	}

	# Find region bounds
	foreach (split (/,/, $self->{post}->{points})) {
	  my($lon, $lat) = split(/:/);
	  my($pointx, $pointy);

	  if(defined($temp_pd->{proj4_string}) && $temp_pd->{proj4_string} ne "") {
	    ($pointx, $pointy) = ($proj4->forward($lat, $lon));
	  } else {
	    ($pointx, $pointy) = ($lon, $lat);
	  }
	  if ($pointy < $minregiony) { $minregiony = $pointy; }
	  if ($pointy > $maxregiony) { $maxregiony = $pointy; }
	  if ($pointx < $minregionx) { $minregionx = $pointx; }
	  if ($pointx > $maxregionx) { $maxregionx = $pointx; }
	}

	print STDERR "minregiony = $minregiony, maxregiony = $maxregiony, minregionx = $minregionx, maxregionx = $maxregionx, proj4string was: " . $temp_pd->{proj4_string} . "\n";

	# Set center (as lat/lon)
	if(defined($temp_pd->{proj4_string}) && $temp_pd->{proj4_string} ne "") {
	  ($self->{post}->{'view_y'}, $self->{post}->{'view_x'}) = $proj4->inverse(($minregionx + $maxregionx) / 2, ($minregiony + $maxregiony) / 2);
	} else {
	  $self->{post}->{'view_x'} = ($minregionx + $maxregionx) / 2;
	  $self->{post}->{'view_y'} = ($minregiony + $maxregiony) / 2;
	}      

	# Determine zoom level
	my($widthratio, $heightratio) = (($maxregionx - $minregionx) / $windowwidth, ($maxregiony - $minregiony) / $windowheight);
	my($minratio) = ($widthratio > $heightratio) ? $widthratio : $heightratio;
	# Note that this assumes zoom levels are in ascending order (which they should be otherwise the frontend gets all oogleh)
	foreach (0..$#{$self->{d}->{'zoom'}}) {
	  if (($self->{d}->{'zoom'}->[$_] * $minratio) <= 1) {
	      $self->{post}->{'zoom'} = $_;
	  }
	}
      }
    }
  }

  # Reset to "Entire Window" in case of no points
  if(!defined($self->{post}->{points}) || !length($self->{post}->{points})) {
    $self->{post}->{pr} = $hash->{pr} = $hash->{oldpr} = 0;
  }

  # Fix old* to reflect new info
  foreach(qw(expt var ts pr region res)) {
    $self->{post}->{"old" . $_} = $hash->{$_};
  }

  # Populate the second time, to get the vars that weren't got in the first go
  $form->populate($self->{post});

  $hash = $self->{form}->get_datahash();

  print STDERR "Scenario set: " . $hash->{sset} . "\n";

  print STDERR "Region: " . $hash->{region} . "\n";

  $form->untaint();

  return $self;
}

sub handle_buttons {
  my($self, $form, $hash) = @_;
  my($bops) = $self->{dd}->{button_ops};
  my($bop) = $hash->{bop};
  my($points) = $form->getBitByName("points");
  my($regionchange) = 0;
  $points = $points->{value};

  if($bop eq $bops->[DESELECT_PT]) {
    clear_selected($points);
    $regionchange = 1;
  } elsif($bop eq $bops->[REMOVE_PT]) {
    my($idx) = find_selected($points);
    if(defined($idx)) {
      splice(@{$points}, $idx, 1);

      if($#{$points} >= 0) {
	if($idx > $#{$points}) {
	  $idx = $#{$points};
	}
	$points->[$idx]->[2] = 1;
      }
    }
    $regionchange = 1;
  } elsif($bop eq $bops->[CLEAR_PTS]) {
    $form->getBitByName("points")->value("");
    $regionchange = 1;
  }

  # Save back to post
  $points = $form->getBitByName("points");
  $self->{post}->{points} = $points->value();

  return $regionchange;
}

sub fixup_desc {
  my($self, $hash) = @_;

  # Replay to original state
  foreach(qw(expt var ts pr region res)) {
    $hash->{$_} = $hash->{"old" . $_};
  }

  $self->get_first_desc($hash);

  # Grab and set the appropriate range
  ($hash->{r_min}, $hash->{r_max}) = get_range($hash->{var}, $hash->{toy}, $hash->{ts}, $hash->{expt}, $self->{dat}, $self->{exptdata}); #TODO TESTME

}

sub get_click_coords {
  my($self, $hash, $prefix) = @_;
  my($lat, $lon, $pd);

  $self->fixup_desc($hash);

  # Untaint input
  $self->{post}->{$prefix . '.x'} =~ /^(.*)$/;
  $hash->{'map.x'} = $1;
  $self->{post}->{$prefix . '.y'} =~ /^(.*)$/;
  $hash->{'map.y'} = $1;

  # Get map size data and other goodies
  $pd = CICS::Scenario::Helpers::parse_textdata($self->{cache}->create_cachefile($hash, TYPE_TEXT));

  # Check for errors. Should have smarter handling, but oh well.
  if(defined($pd->{error})) {
    print STDERR $pd->{error} . ": " . $pd->{file} . "\n";
  }

  # Translate latitudes and longitudes
  if(!defined($pd->{proj4_string}) || $pd->{proj4_string} eq "") {
      $lon = xtolon($pd->{mapminlon}, $pd->{mapmaxlon}, $pd->{offset_x}, $pd->{mapsize_x}, $hash->{'map.x'});
      $lat = ytolat($pd->{mapminlat}, $pd->{mapmaxlat}, $pd->{offset_y}, $pd->{mapsize_y}, $hash->{'map.y'});
  } else {
      my($proj4) = Geo::Proj4->new($pd->{proj4_string}) or die "parameter error: ".Geo::Proj4->error. "\n";
      my($xc) = xtolon($pd->{mapminlon}, $pd->{mapmaxlon}, $pd->{offset_x}, $pd->{mapsize_x}, $hash->{'map.x'});
      my($yc) = ytolat($pd->{mapminlat}, $pd->{mapmaxlat}, $pd->{offset_y}, $pd->{mapsize_y}, $hash->{'map.y'});
      
      ($lat, $lon) = $proj4->inverse($xc, $yc);

  }

  return ($lat, $lon);
}

sub handle_regionmapclick {
  my($self, $form, $hash1) = @_;
  my($hash, $i);
  my($regionchange) = 0;

  %{$hash} = %{$hash1};

  my($lat, $lon) = $self->get_click_coords($hash, "regionmap");

  # If we have valid latitude and longitude...
  if(defined($lon) && defined($lat)) {
    my($point) = [ $lon, $lat, 1 ];

    my($points) = $form->getBitByName("points");
    $points = $points->{value};

    if($hash->{op} == OP_ADD) {
      # Make sure we don't have a duplicate point
      foreach(@{$points}) {
	if(abs($_->[0] - $point->[0]) < 1e-12 && abs($_->[1] - $point->[1]) < 1e-12) {
	  return $regionchange;
	}
      }
      clear_selected($points);
      if($#{$points} < 1) {
	# Not a polygon yet
	push(@{$points}, $point);
      } elsif($#{$points} == 1) {
	  # Closing a new polygon: make sure that polygon is clockwise
	  my($crossproduct) = ($points->[0]->[0] - $point->[0]) * ($points->[1]->[1] - $point->[1]) - ($points->[0]->[1] - $point->[1]) * ($points->[1]->[0] - $point->[0]);

	  if($crossproduct > 0) {
	      # Insert in between
	      splice(@{$points}, 1, 0, $point);
	  } else {
	      # Insert at end
	      splice(@{$points}, 0, 0, $point);
	  }
      } else {
	# Polygon
	my(@minidx) = find_nearest_line_segments($points, $point);
	
	# If we have 2 line segments equidistant to the point, resolve them
	# as lines. Choose the one whose line is farthest from the point.
	if($#minidx > 0) {
	  @minidx = find_farthest_lines($points, $point, @minidx)
	}
	
	# Insert the first point in the list regardless
	splice(@{$points}, ($minidx[0] + 1) % ($#{$points} + 1), 0, $point);

	

      }
      $regionchange = 1;
    } elsif($hash->{op} == OP_SELECT) {
      if($#{$points} >= 0) {
	# Find closest point to selection; clear old selection
	clear_selected($points);
	my($minidx) = find_closest($points, $point);
	
	# Mark selected
	$points->[$minidx]->[2] = 1;
      }
      $regionchange = 1;
    } elsif($hash->{op} == OP_MOVE) {
      # Find selected point, move it
      @{$i} = find_selected($points);

      if(defined($i->[0])) {
	$points->[$i->[0]] = $point;
      }
      $regionchange = 1;
    }

    # Save back to post
    $points = $form->getBitByName("points");
    $self->{post}->{points} = $points->value();
  }

  return $regionchange;
}

sub process_expt {
  my($self, $list, $hash) = @_;
  my($var) = $self->{d}->{variable}->[$hash->{var}];

  my($numi, $i, @newlist) = $#{$list};
  for($i = 0; $i <= $numi; $i++) {
    my(%hashent) = %{$hash};
    $hashent{expt} = $list->[$i];
    $hashent{vars} = get_variables($self->{lang}, $self->{ss}, $self->{exptdata}->[$hashent{expt}]->{varmask}, $self->{dd});
    if(is_multivar($var) || length($hashent{vars}->[$hashent{var}])) {
      push(@newlist, \%hashent);
    }
  }
  return @newlist;
}

sub process_var {
  my($self, $list, $hash) = @_;

  my($numi, $i, @newlist) = $#{$list};
  for($i = 0; $i <= $numi; $i++) {
    if(is_var_available($hash->{expt}, $i, $self->{exptdata})) {
      ($hash->{r_min}, $hash->{r_max}) = get_range($list->[$i], $hash->{toy}, $hash->{ts}, $hash->{expt}, $self->{dat}, $self->{exptdata}); #TODO TESTME

#	if(is_ts_absolute($hash->{ts}, $hash->{expt}, $self->{exptdata})) { #RANGES
#	    ($hash->{r_min}, $hash->{r_max}) = @{$self->{dat}->[5]->{variable}->[$list->[$i]]};
#	} else {
#	    ($hash->{r_min}, $hash->{r_max}) = @{$self->{dat}->[6]->{variable}->[$list->[$i]]};
#	}
      my(%hashent) = %{$hash};
      $hashent{var} = $list->[$i];
      push(@newlist, \%hashent);
    }
  }
  return @newlist;
}

sub process_ts {
  my($self, $list, $hash) = @_;

  my($numi, $i, @newlist) = $#{$list};
  for($i = 0; $i <= $numi; $i++) {
    if(is_timeslice_available($hash->{expt}, $i, $self->{exptdata})) {
      ($hash->{r_min}, $hash->{r_max}) = get_range($hash->{var}, $hash->{toy}, $list->[$i], $hash->{expt}, $self->{dat}, $self->{exptdata}); #TODO TESTME

#	if(is_ts_absolute($list->[$i], $hash->{expt}, $self->{exptdata})) { #RANGES
#	    ($hash->{r_min}, $hash->{r_max}) = @{$self->{dat}->[5]->{variable}->[$hash->{var}]};
#	} else {
#	    ($hash->{r_min}, $hash->{r_max}) = @{$self->{dat}->[6]->{variable}->[$hash->{var}]};
#	}
      my(%hashent) = %{$hash};
      $hashent{ts} = $list->[$i];
      push(@newlist, \%hashent);
    }
  }
  return @newlist;
}

sub process_toy {
  my($self, $list, $hash) = @_;

  my($numi, $i, @newlist) = $#{$list};
  for($i = 0; $i <= $numi; $i++) {
    my(%hashent) = %{$hash};
    $hashent{toy} = $list->[$i];
    push(@newlist, \%hashent);
  }
  return @newlist;
}

# Make list of plot descriptions
# Only pass a parameter into this function if you want to use alternate data
sub make_desc_list {
  my($self, $hash) = @_;
  if(!defined($hash)) {
    $hash = $self->get_postdata();
  }

  my(@descs) = $hash;
  my(@newdesc);
  my($numi, $i) = $#descs;
  my($exptlist) = $self->{exptmulti}->[$hash->{expt}];
  my($varlist) = $self->{d}->{variable}->[$hash->{var}];
  my($tslist) = $self->{d}->{timeslice}->[$hash->{ts}];
  my($toylist) = $self->{d}->{timeofyear}->[$hash->{toy}];

  $descs[0]->{vars} = get_variables($self->{lang}, $self->{ss}, $self->{exptdata}->[$descs[0]->{expt}]->{varmask}, $self->{dd});

  # Also see Explorer.pm around line 100; this code's output order is coupled to that code's output order
  #

  if(is_multivar($varlist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_var($varlist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  if(is_multivar($tslist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_ts($tslist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  if(is_multivar($toylist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_toy($toylist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  if(is_multivar($exptlist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_expt($exptlist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  return \@descs;
}

# Make list of plot descriptions for scatter plots by variable
# Only pass a parameter into this function if you want to use alternate data
sub make_scattervar_desc_list {
  my($self, $hash) = @_;

  if(!defined($hash)) {
    $hash = $self->get_postdata();
  }

  my(@descs) = $hash;
  my(@newdesc);
  my($numi, $i) = $#descs;
  my($exptlist) = $self->{exptmulti}->[$hash->{expt}];
  my($varlist) = $self->{d}->{variable}->[$hash->{var}];
  my($tslist) = $self->{d}->{timeslice}->[$hash->{ts}];
  my($toylist) = $self->{d}->{timeofyear}->[$hash->{toy}];

  $descs[0]->{vars} = get_variables($self->{lang}, $self->{ss}, $self->{exptdata}->[$descs[0]->{expt}]->{varmask}, $self->{dd});

  # Set a sane default for experiment in case of multiple timeslices
  #if(is_multivar($exptlist)) {
  #  $descs[0]->{expt} = 0; # First experiment
  #}

  if(is_multivar($varlist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_var($varlist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  if(is_multivar($tslist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_ts($tslist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  if(is_multivar($toylist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_toy($toylist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  return \@descs;
}

# Make list of plot descriptions for scatter plots by timeslice
# Only pass a parameter into this function if you want to use alternate data
sub make_scatterts_desc_list {
  my($self, $hash) = @_;
  if(!defined($hash)) {
    $hash = $self->get_postdata();
  }

  my(@descs) = $hash;
  my(@newdesc);
  my($numi, $i) = $#descs;
  my($exptlist) = $self->{exptmulti}->[$hash->{expt}];
  my($varlist) = $self->{d}->{variable}->[$hash->{var}];
  my($tslist) = $self->{d}->{timeslice}->[$hash->{ts}];
  my($toylist) = $self->{d}->{timeofyear}->[$hash->{toy}];

  $descs[0]->{vars} = get_variables($self->{lang}, $self->{ss}, $self->{exptdata}->[$descs[0]->{expt}]->{varmask}, $self->{dd});

  # Set a sane default for timeslice in case of multiple timeslices
  if(is_multivar($tslist)) {
    $descs[0]->{ts} = 1; # 2020s
  }

  # Set a sane default for experiment in case of multiple timeslices
  #if(is_multivar($exptlist)) {
  #  $descs[0]->{expt} = 0; # First experiment
  #}

  if(is_multivar($varlist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_var($varlist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  if(is_multivar($toylist)) {
    @newdesc = ();
    $numi = $#descs;
    for($i = 0; $i <= $numi; $i++) {
      push(@newdesc, $self->process_toy($toylist, $descs[$i]));
    }
    @descs = @newdesc;
  }

  return \@descs;
}

sub get_first_desc {
  my($self, $hash) = @_;
  if(!defined($hash)) {
    $hash = $self->get_postdata();
  }
  my($exptlist) = $self->{exptmulti}->[$hash->{expt}];
  my($varlist) = $self->{d}->{variable}->[$hash->{var}];
  my($tslist) = $self->{d}->{timeslice}->[$hash->{ts}];
  my($toylist) = $self->{d}->{timeofyear}->[$hash->{toy}];

  if(is_multivar($tslist)) {
    $hash->{ts} = $tslist->[0];
  }
  if(is_multivar($toylist)) {
    $hash->{toy} = $toylist->[0];
  }
  if(is_multivar($varlist)) {
    $hash->{var} = $varlist->[0];
  }
  if(is_multivar($exptlist)) {
    $hash->{expt} = $exptlist->[0];
  }

  # Set up variables list
  $hash->{vars} = get_variables($self->{lang}, $self->{ss}, $self->{exptdata}->[$hash->{expt}]->{varmask}, $self->{dd});

  return $hash;
}


# Accessors
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
  if(defined($self->{str})) {
    if(defined($self->{lang})) {
      $self->{ss} = $self->{str}->[$self->{lang}];
    }
  }
}

sub get_postdata {
  my($self) = @_;
  return $self->{form}->get_datahash();
}

sub addElements {
  my($self, $hash) = @_;
  foreach(keys(%{$self->{templatebits}})) {
    $hash->{$_} = $self->{templatebits}->{$_};
  }

  $self->{form}->addElements($hash);
}

return 1;
