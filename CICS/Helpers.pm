package CICS::Helpers;

use strict;
use Fcntl ':flock';
use File::Slurp;
use Apache2::Util qw(escape_uri);
use Exporter 'import';
use Time::HiRes qw(usleep);

our(@EXPORT) = qw(file_size stream_from_cache stream_file stream_cachefile fix_param cb_to_bool is_numeric mkgetstring subamps square ls_intersect point_line_distance foreach_TIL SendMail MailError is_tainted fix_numeric fix_string is_boolean accessvar is_arrayref is_hashref testfunc createXMLElement parseTemplate parseTemplateString set_if_empty clean_string);

sub set_if_empty {
  my($self, $var, $value) = @_;

  if(!defined($self->{$var})) {
    $self->{$var} = $value;
  }
}

sub clean_string {
  my($str) = @_;
  $str =~ s/\n/\\n/g;
  $str =~ s/\'/\\'/g; #'/g;

  return $str;
}

## Tries to fetch stuff from plot data if requested (by tokens being prefixed by data:) in a template on demand...
sub parseTemplateString {  # FIXME maybe fork this to planners version so nobody else trips on it
  my($str, $hash, $plotdat_cache) = @_;
#  $str =~ s/<%([^%]*)%>/(defined($hash->{$1})?$hash->{$1}:"")/egs;
  $str =~ s|<%([^%]*)%>|($1 =~ /^(data:.*)$/)?(CICS::Scenario::Helpers::get_ruledat($plotdat_cache, $1)):((defined($hash->{$1})?$hash->{$1}:""))|egs;
  return $str;
}

sub parseTemplate {
  my($filename, $hash, $plotdat_cache) = @_;
  my($template);
  $template = read_file($filename) or print STDERR "Couldn't read template file '" . $filename . "'!\n";

  return parseTemplateString($template, $hash, $plotdat_cache);
}

sub createXMLElement {
  my($type, $selfclose, $bithash, $extra) = @_;
  my($str) = "<" . $type;

  foreach(keys(%{$bithash})) {
    my($key) = $_;
    if(defined($bithash->{$key})) {
      $str .= " " . $key . "=\"" . $bithash->{$key} . "\"";
    }
  }

  if(defined($extra)) {
    $str .= " " . $extra;
  }

  if($selfclose) {
    $str .= "/";
  }
  $str .= ">";

  return $str;
}

sub testfunc {
  my($func, $testname, $expected, @args) = @_;

  if(&{$func}(@args) eq $expected) {
    print $testname . " successful!<br/>";
  } else {
    print "<br/>" . $testname . " FAILED!<br/><br/>";
  }
}

sub is_boolean {
  my($var) = shift();
  if(defined($var) && ($var == 0 || $var == 1)) {
    return 1;
  } else {
    return 0;
  }
}

sub accessvar {
  my($var, $validation, $self, $value) = @_;

  if(defined($value)) {
    if(defined($validation)) {
      if(&{$validation}($value)) {
	$self->{$var} = $value;
      }
    } else {
      $self->{$var} = $value;
    }
  }

  return $self->{$var};
}

sub is_arrayref {
  my($var) = @_;

  return (defined($var) && (ref($var) eq "ARRAY"));
}

sub is_hashref {
  my($var) = @_;

  return (defined($var) && ref($var) eq "HASH");
}

# Get the prettyified size of a file (or DNE if it does not exist)
sub file_size {
  my($filename) = @_;
  my(@fstats, $size, $offset);

  @fstats = stat($filename);

  $size = $fstats[7];

  if(!defined($size)) {
    $size = "DNE";
  } else {
    if($size >> 10 == 0) {
      $size .= "B";
    } elsif($size >> 20 == 0) {
      $size = ($size >> 10) . "kB";
    } elsif($size >> 30 == 0) {
      $size = ($size >> 20) . "MB";
    } else {
      $size = ($size >> 30) . "GB";
    }
  }
  return $size;
}

# Stream a file from the cache (requires that it be locked so nothing can write to it)
sub stream_from_cache {
  my($fd) = @_;
  my($count) = 300;
  my($lockres);


  binmode($fd);
  while(!($lockres = flock($fd, Fcntl::LOCK_SH)) && $count-- > 0) { usleep(200000); }
  die("Failed to acquire lock on cache file after 60s, aborting.\n") if(!$lockres);
  my($blob);
  while(read($fd, $blob, 65536)) {
      print $blob;
  }
  flock($fd, Fcntl::LOCK_UN);
}

# Takes in a file and outputs it to stdout
sub stream_file {
  my($filename) = @_;
  my($data);

  if(!($data = read_file($filename, binmode => ":raw"))) {
    print STDERR "Couldn't open file " . $filename . "\n";
    return 0;
  }
  print $data;
  return 1;
}

# Takes in a file and outputs it to stdout
sub stream_cachefile {
  my($filename) = @_;
  my($file);

  if(!open($file, $filename)) {
    print STDERR "Couldn't open file " . $filename;
    return -1;
  }

  stream_from_cache($file);
  close($file);
}

sub is_tainted {
  return ! eval { eval("#" . substr(join("", @_), 0, 0)); 1 };
}

# Returns a parameter value which is within bounds
sub fix_param {
  my($indata, $varname, $default, $list) = @_;
  my($current) = $indata->{$varname};

  # If either the variable isn't there, the variable is out of bounds, or the 
  # variable is not available, return the default
  if(!exists($indata->{$varname}) || $indata->{$varname} < 0 || $indata->{$varname} > $#{$list} || length($list->[$indata->{$varname}]) == 0) {

    # DEBUG: Very useful when there's variable bork
    #print STDERR $varname . ": " . exists($indata->{$varname}) . ($indata->{$varname} >= 0) . ($indata->{$varname} <= $#{$list}) . length($list->[$indata->{$varname}]) . $#{$list};
    return ( 0, $default );
  } else {
    $current =~ /^([-\@\w.]+)$/;
    $current = $1;

    return ( 1, $current );
  }
  # Note about code above: It returns a list containing a 'was it good' value
  # and the fixed value.
}

# Return a boolean depending on if a variable is set or not
sub cb_to_bool {
  my($varname, $post) = @_;

  if(exists($post->{$varname})) {
    return 1;
  } else {
    return 0;
  }
}

# Return 1 if a variable is numeric in contents
sub is_numeric {
  my($var) = @_;

  if(defined($var) && $var =~ /^-?\d+\.?\d*$/) {
    return 1;
  } else {
    return 0;
  }
}

# Forces the number into a numeric format
sub fix_numeric {
  my($item) = @_;

  if(defined($item) && $item =~ /^((-){0,1})([0-9\.]+)$/ == 2) {
    return $1.$2;
  } else {
    return 0;
  }
}

# Forces the string into a boring format
sub fix_string {
  my($item) = @_;

  if(defined($item) && $item =~ /^([\.\,\@\w\s]*)$/ == 1) {
    return $1;
  } else {
    return "";
  }
}

# Get rid of not so valid chars
sub uri_escape {
  my($str) = @_;
  $str =~ s/([^a-zA-Z0-9_.-])/sprintf("%%%02X", ord($1))/eg;
  return $str;
}

# Create a GET string from a list of parameters
sub mkgetstring {
  my($params) = @_;
  my(@bits);

  foreach(keys(%{$params})) {
    if($_ ne "vars") {
      push(@bits, uri_escape($_) . "=" . uri_escape($params->{$_}));
    }
  }
  return join("&amp;", @bits);
}

sub subamps {
  my($str) = @_;
  $str =~ s/\&/\&amp;/g;
  return $str;
}

# Square a number
sub square {
  my($num) = @_;

  return $num * $num;
}

# The Perl version of the line segment intersect code
sub ls_intersect {
  my($p00, $p01, $p10, $p11, $ignore_first_range) = @_;
  my($mA, $mB, $x, $y, $s, $t);
  my($vlA, $vlB) = (0, 0);

  # Check for vertical lines

  if(($p00->[0] - $p01->[0]) == 0) {
    # A is vertical line
    $vlA = 1;
    if(($p10->[0] - $p11->[0]) == 0) {
      # B is vertical line
      # Parallel
      return [ ];
    } else {
      $mB = ($p10->[1] - $p11->[1]) / ($p10->[0] - $p11->[0]);
    }
  } else {
    $mA = ($p00->[1] - $p01->[1]) / ($p00->[1] - $p01->[1]);
    if(($p10->[0] - $p11->[0]) == 0) {
      # B is vertical line
      $vlB = 1;
    } else {
      $mB = ($p10->[1] - $p11->[1]) / ($p10->[0] - $p11->[0]);
    }
  }

  # If parallel or antiparallel...
  if($mA == $mB) {
    return 0;
  }

  if($vlA) {
    # Line A (p00 - p01) is a vertical line
    $x = $p00->[0];
    $y = (($p00->[0] - $p11->[0]) * $mB + $p11->[1]);
    $s = (($y - $p00->[1]) / ($p01->[1] - $p00->[1]));
    $t = (($x - $p10->[0]) / ($p11->[0] - $p10->[0]));
  } elsif($vlB) {
    # Line B (p10 - p11) is a vertical line
    $x = $p10->[0];
    $y = (($p10->[0] - $p01->[0]) * $mA + $p01->[1]);
    $s = (($x - $p00->[0]) / ($p01->[0] - $p00->[0]));
    $t = (($y - $p10->[1]) / ($p11->[1] - $p10->[1]));
  } else {
    # Neither line is a vertical line
    $x = ( -1 * $mB * $p10->[0] + $p10->[1] + $mA * $p00->[1] - $p00->[1] ) / ( $mA - $mB );
    $y = ($mA * ( $x - $p00->[0] ) + $p00->[1]);
    $s = (($x - $p00->[0]) / ($p01->[0] - $p00->[0]));
    $t = (($x - $p10->[0]) / ($p11->[0] - $p10->[0]));
  }

  # Check range
  if((defined($ignore_first_range) || ($s >= 0 && $s <= 1)) && $t >= 0 && $t <= 1) {
    # Return point
    return [ $x, $y ];
  } else {
    # Return nothing
    return [ ];
  }
}

# Function to determine the distance of a point from a given line segment
sub point_line_distance {
  my($x0, $y0, $x1, $y1, $x2, $y2, $line) = @_;
  my($temp) = 0;
  my($mA, $mB, $x, $y, $s);

  $line = (defined($line))?1:0;

  # Compute intersect
  if(($x1 - $x2) == 0) {
    # A is vertical line
    $x = $x1;
    $y = $y0;
    if(($y2 - $y1) == 0) {
      $s = 0;
    } else {
      $s = (($y - $y1) / ($y2 - $y1));
    }
  } else {
    $mA = ($y1 - $y2) / ($x1 - $x2);
    if($mA == 0) {
      # B is vertical line
      $x = $x0;
      $y = $y2;
      $s = (($x - $x1) / ($x2 - $x1));
    } else {
      # Neither A nor B is a vertical line
      $mB = -1 / $mA;
      $x = ( - $mB * $x0 + $y0 + $mA * $x1 - $y1 ) / ( $mA - $mB );
      $y = ($mA * ( $x - $x1 ) + $y1);
      $s = (($x - $x1) / ($x2 - $x1));
    }
  }

  # If the intersection is closer to point 2...
  if($s > 1 && !$line) {
    $temp = sqrt(square($x2 - $x0) + square($y2 - $y0));
  } elsif($s < 0 && !$line) {
    # If the intersection is closer to point 1...
    $temp = sqrt(square($x1 - $x0) + square($y1 - $y0));
  } else {
    # If the intersection is between the 2 points
    $temp = abs((($x2 - $x1) * ($y1 - $y0)) - (($x1 - $x0) * ($y2 - $y1)));
    my($distance) = sqrt(square($x2 - $x1) + square($y2 - $y1));
    if($distance > 0) {
      $temp /= $distance;
    } else {
      $temp = sqrt(square($x1 - $x0) + square($y1 - $y0));
    }
  }

  return $temp;
}

# Takes in a text index list declaration as defined.
# TIL == text index list
# For each element in the TIL, runs a function with the index of the current 
# element as the last parameter, along with any provided parameters.
# Expects the function to return its (text) output
# DEPRECATED / OBSOLETE / BADIDEA
sub foreach_TIL {
  my($list, $idx, $func, @args) = @_;
  my($output, $tmpdesc, $tmpidx, $min, $max, @ranges);

  $output = "";

  if($list->[$idx] =~ /^#/) {
    $tmpdesc = substr($list->[$idx], 1);
    @ranges = split(/,/, $tmpdesc);

    foreach(@ranges) {
      # Try to extract the elements separated by dashes
      ($min, $max) = split(/-/, $_);

      # If only a single value was present, we assume only one was wanted
      if(length($max) == 0) {
	$output .= &{$func}(@args, $min);
      } else {
	# Go through the range doing whatever processing's wanted
	for($tmpidx = $min; $tmpidx <= $max; $tmpidx++) {
	  $output .= &{$func}(@args, $tmpidx);
	}
      }
    }
  } else {
    $output .= &{$func}(@args, $idx);
  }

  return $output;
}

# Sends $message to the given address, from the given address, with the given subject
sub SendMail {
  # Localize variables used in this subroutine.
  my($message, $subject, $to, $from) = @_;
  my($mailprog) = '/usr/sbin/sendmail';
  my($fd);
  print STDERR $message;

  $ENV{PATH} = "";

  if(open( $fd, "|$mailprog -t" )) {
    print $fd "To: ".$to."\n";
    print $fd "From: ".$from."\n";
    print $fd "Subject: ".$subject."\n\n";
    print $fd $message."\n\n";
    close($fd);
    return 1;
  }
  return 0;
}

# Sends an error message to Trevor
sub MailError {
  # Localize variables used in this subroutine.
  my($message) = @_;

  SendMail($message, 'Scenarios error', 'tmurdock@uvic.ca', 'tmurdock@uvic.ca');
}

return 1;
