package CICS::Scenario::Regions;
use strict;
use Text::CSV_XS;
use File::Slurp;

use CICS::Helpers;

use Exporter 'import';

our(@EXPORT) = qw(str2coords coords2str loadRegions saveRegions getRegionList getRegionGroupList);

sub str2coords {
  my($string) = @_;

  #if(is_tainted($string)) {
  #  warn("Incoming string is tainted");
  #}

  my($csv) = Text::CSV_XS->new();
  if($csv->parse($string)) {
    my(@coordlist) = $csv->fields();
    my(@coords);
    foreach(@coordlist) {
      if(length($_)) {
	my(@coord) = split(/:/, $_);
	if($#coord == 2 && is_numeric($coord[0]) && is_numeric($coord[1]) && is_numeric($coord[2])) {
	  foreach(0..2) {
	    $coord[$_] =~ /^(.+)$/;
	    $coord[$_] = $1;
	  }
	  push(@coords, \@coord);
	}
      }
    }
    return \@coords;
  } else {
    return [];
  }
}

sub coords2str {
  my($coords) = @_;
  my(@strs);
  foreach(@{$coords}) {
    push(@strs, join(":", @{$_}));
  }
  return join(",", @strs);
}

sub loadRegions {
  my($filename, $lang) = @_;
  my($regions) = [];
  my($csv) = Text::CSV_XS->new();
  my($fd);
  if(open($fd, $filename)) {
    my($header);
    $header = readline($fd);
    while(<$fd>) {
      $_ =~ /^(.*)$/;
      my($line) = $1;

      if($csv->parse($line)) {
	my($region);
	$region->{coords} = [];
	my($threshold, $enname, $group, $glacier_frac, $coast_bool, $coords) = $csv->fields();
	$region->{name} = [ $enname, $enname ];
	$region->{threshold} = $threshold;
	$region->{group} = $group;
	$region->{glacierfraction} = $glacier_frac;
	$region->{oncoast} = $coast_bool;
	my(@coordlist) = split(/;/, $coords);
	my(@bits);
	foreach(@coordlist) {
	  my(@otherbits) = split(/:/, $_);
	  if($#otherbits == 1) {
	    $otherbits[2] = 0;
	  }
	  push(@bits, join(":", @otherbits));
	}
	$region->{coords} = join(",", @bits);
	push(@{$regions}, $region);
      } else {
	  print STDERR "Bad CSV line!\n";
      }
    }
    close($fd);
  } else {
    print STDERR "Couldn't open region file " . $filename ."!\n";
  }
  
  return $regions;
}

sub saveRegions {
  my($regions, $filename, $lang) = @_;
  my($csv) = Text::CSV_XS->new();
  my($fd);
  if(open($fd, ">", $filename)) {
    foreach(@{$regions}) {
      my($region) = $_;
      my(@region_array) = ( @{$region->{name}});
      push(@region_array, split(/,/,$region->{coords}));
      $csv->combine(@region_array);
      print($fd, $csv->string() . "\n");
    }
    close($fd);
  } else {
    print STDERR "Couldn't open region file " . $filename ." for writing!\n";
  }
}

sub getRegionList {
  my($regions, $lang) = @_;
  my(@list);
  foreach(@{$regions}) {
    push(@list, $_->{name}[$lang]);
  }
  return \@list;
}

sub getRegionGroupList {
  my($regions) = @_;
  my(@list);
  foreach(@{$regions}) {
    push(@list, $_->{group});
  }
  return \@list;
}

return 1;
