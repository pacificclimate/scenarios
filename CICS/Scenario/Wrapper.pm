package CICS::Scenario::Wrapper;
use strict;

use CICS::Helpers;
use CICS::Scenario::Data;
use CICS::Scenario::Config;
use CICS::Scenario::Cache;
use CICS::Scenario::MainForm;
use CICS::Scenario::MainForm_Planners;
use CICS::Scenario::Helpers;
use CICS::Scenario::Regions;
use CICS::Scenario::Displayer;

use Fcntl ':flock';
use POSIX qw(strftime);

use CGI;
use Apache2::Const ':common';
use APR::URI ();
use APR::Table;
use Apache2::Util;
use Apache2::RequestRec;

use Carp;
$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__} = \&Carp::cluck;

sub handler {
  my($r) = shift();
  my($q) = CGI->new($r->args());
  my($args);
  %{$args} = $q->Vars;

  # Default important stuff
  if(!defined($args->{lang})) {
    print STDERR "Wrapper was not given a language\n";
    return DECLINED;
  } else {
    my(@langs) = [ 0, 1 ];
    if(!defined($langs[$args->{lang}])) {
      print STDERR "Wrapper was not given a valid language: " . $args->{lang} . "\n";
      return DECLINED;
    } else {
      $args->{lang} = 0;
    }
  }
  if(!defined($args->{expt})) {
    $args->{expt} = 0;
  }

  my($regions);
  if(defined($args->{planners})) {
      $regions = loadRegions($CICS::Scenario::Config::dat[2]{'planners_regionfile'}, $args->{lang});
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
      wrapper => 1
    };

  my($cache) = CICS::Scenario::Cache->new($hash);
  $hash->{cache} = $cache;







  # To planners, or not to planners?  TODO
  my($mainform);
  if(defined($args->{planners})) {
      $mainform = CICS::Scenario::MainForm_Planners->new($hash);
  } else {
      $mainform = CICS::Scenario::MainForm->new($hash);
  }
  $hash->{mainform} = $mainform;

  if(!$mainform->{form}->validate()) {
    print STDERR "Wrapper has invalid inputs: " . $mainform->{form}->{error} . "\n";
    return DECLINED;
  }

  my($inputdata) = $mainform->get_postdata();
  my($plot_type) = $inputdata->{plot_type};
  my($cachefile) = "";

  my($desc, $olddesc);
  my(@accum_wmean);

  if($plot_type == TYPE_METADATA_CSV) {
    my($descriptions) = $mainform->make_desc_list();
    my($displayer) = CICS::Scenario::Displayer->new($hash);

    my(@metadataitems, $i);
    push(@metadataitems, "Name,Region min,Region max,Region weighted mean,Region median,Region weighted standard deviation,Units,\n");
    for($i = 0; $i <= $#{$descriptions}; $i++) {
      $desc = $descriptions->[$i];
      my($anythingbutexptchanged) = 0;

      if($i != 0) {
	$anythingbutexptchanged = !($olddesc->{var} == $desc->{var} && $olddesc->{toy} == $desc->{toy} && $olddesc->{ts} == $desc->{ts});
      }

      # Grab in the plot data from genimage
      $displayer->{plotdat} = CICS::Scenario::Helpers::parse_textdata($cache->create_cachefile($desc, TYPE_TEXT));

      my($dd) = $hash->{dat}->[$hash->{lang}];
      my($list) = join(" - ", $desc->{vars}->[$desc->{var}], $dd->{timeslice}->[$desc->{ts}], $dd->{timeofyear}->[$desc->{toy}], $hash->{expt}->[$desc->{expt}]);

      # Print out percentiles for groups of metadata
      if($desc->{md_pctile}) {
	if ($anythingbutexptchanged) { # Only print when there is a change
	  push(@metadataitems, $displayer->get_percentile_rows($desc, \@accum_wmean, "csv"));
	  @accum_wmean = ();
	}
	push(@accum_wmean, $displayer->{plotdat}->{selwmean});
      }

      if(defined($displayer->{plotdat}->{error})) {
	push(@metadataitems, $displayer->make_metadata_error_row($desc, $list, "csv"));
      } else {
	push(@metadataitems, $displayer->make_metadata_row($desc, $list, "csv"));
      }

      $olddesc = $desc;
    }

    # Don't forget to print  metadata percentiles for the very last group of metadata.
    if ($desc->{md_pctile} && $i != 0) {
      push(@metadataitems, $displayer->get_percentile_rows($desc, \@accum_wmean, "csv"));
    }

    $cachefile = "metadata.csv";

    $r->headers_out->add("Content-Disposition" => "attachment; filename=\"".$cachefile."\"" );
    $r->content_type('text/csv');

    print join("", @metadataitems);
  } else {
    #my($inputdata) = $mainform->get_postdata();
    $inputdata->{vars} = get_variables($hash->{lang}, $hash->{str}->[$hash->{lang}], $hash->{exptdata}->[$hash->{post}->{expt}]->{varmask}, $hash->{dat}->[$hash->{lang}]);
    my($outputfilename) = create_output_filename($inputdata, $hash->{exptdata}, $hash->{dat}->[2], $inputdata->{plot_type});
    $hash->{'plotdat'} = CICS::Scenario::Helpers->parse_textdata($cache->create_cachefile($inputdata, TYPE_TEXT));

    $cachefile = $cache->create_cachefile($inputdata, $inputdata->{plot_type});

    # Output the correct headers for various plot types
    if( $plot_type == TYPE_MAP || $plot_type == TYPE_MAP_DIFFERENCE || $plot_type == TYPE_REGIONONLY || $plot_type == TYPE_SCATTER_TIMESLICE
	|| $plot_type == TYPE_SCATTER_VARIABLE || $plot_type == TYPE_SCATTER_TIMESLICE_HIST || $plot_type == TYPE_STICKPLOT || $plot_type == TYPE_BANDS_TIMESLICE || $plot_type == TYPE_BANDS_TIMESLICE_HIST) {
      # Image parts
      $r->content_type('image/png');
    } elsif(($plot_type >= TYPE_TEXT && $plot_type <= TYPE_PLOTINFO) || ($plot_type >= TYPE_SCENARIO_DATA && $plot_type <= TYPE_LONGS_DATA)) {
      # Metadata and region mask and georef'd data
      $r->headers_out->add("Content-Disposition" => "attachment; filename=\"".$outputfilename."\"" );
      $r->content_type('application/octet-stream');
    } elsif($plot_type == TYPE_SCATTER_TIMESLICE_TEXT || $plot_type == TYPE_SCATTER_VARIABLE_TEXT || $plot_type == TYPE_BOXPLOT_TIMESLICE_TEXT) {
      $r->headers_out->add("Content-Disposition" => "attachment; filename=\"".$outputfilename."\"" );
      $r->content_type('text/csv');
    } elsif($plot_type >= TYPE_ZIP_ALLEXPT_GEOREF || $plot_type <= TYPE_ZIP_ALLEXPTVAR) {
      # Various zip files
      $r->headers_out->add("Content-Disposition" => "attachment; filename=\"".$outputfilename."\"" );
      $r->content_type('application/zip');
    }

    # Check if generating a cached file succeeded
    if(defined($cachefile)) {
      # Output from cache
      if(stream_cachefile($cachefile) == -1) {
	print STDERR "Cache file was not readable or did not exist -- BAD!\n";
      }
    } else {
      print STDERR "File generation failed";
    }
  }


  my($accesslog);
  # Now write to access log
  if(open($accesslog, ">>", $hash->{cfg}->[2]->{'maccesslog'})) {
    flock($accesslog, LOCK_EX);
    
    # Seek to end just in case
    seek($accesslog, 0, 2);
    
    # Write out line
    print $accesslog $ENV{'REMOTE_ADDR'} . " - - " . strftime("[%d/%b/%Y:%H:%M:%S %z]", localtime()) . " \"GET /" . $cachefile . " HTTP/1.0\" 200 0\n";
    
    # Unlock and close
    flock($accesslog, LOCK_UN);
    close($accesslog);
  } else {
    print STDERR "Couldn't write to access log: " . $hash->{cfg}->[2]->{maccesslog} . "\n";
  }

  return OK;
}

return 1; # modules must return true
