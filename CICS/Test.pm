package CICS::Test;
use strict;

use CICS::Helpers;

use Apache::Constants qw(OK);


sub validate_accessvar {
  my($value) = @_;

  if($value eq "test") {
    return 0;
  }
  return 1;
}

sub handler {
  my $r = shift;

  $r->send_http_header('text/html');

  print "<html><head><title>Test of CICS:: stuff</title></head><body>";

  testfunc(\&is_boolean, "Test is_boolean with 'true'", 1, 1);
  testfunc(\&is_boolean, "Test is_boolean with 'false'", 1, 0);
  testfunc(\&is_boolean, "Test is_boolean with 2", 0, 2);
  testfunc(\&is_boolean, "Test is_boolean with undef", 0, undef);

  my($hash) = {};
  $hash->{foo} = "bar";

  testfunc(\&accessvar, "Test accessvar for get", "bar", "foo", undef, $hash);
  testfunc(\&accessvar, "Test accessvar for set", "baz", "foo", undef, $hash, "baz");
  testfunc(\&accessvar, "Test accessvar for set w/validation func", "bonk", "foo", \&validate_accessvar, $hash, "bonk");
  testfunc(\&accessvar, "Test accessvar for set w/validation func", "bonk", "foo", \&validate_accessvar, $hash, "test");

  testfunc(\&is_arrayref, "Test is_arrayref with non-arrayref", '', 0);
  testfunc(\&is_arrayref, "Test is_arrayref with arrayref", 1, []);
  testfunc(\&is_arrayref, "Test is_arrayref with undef", '', undef);

  testfunc(\&is_hashref, "Test is_hashref with non-hashref", '', 0);
  testfunc(\&is_hashref, "Test is_hashref with hashref", 1, {});
  testfunc(\&is_hashref, "Test is_hashref with undef", '', undef);

  print "Could do more tests, but that'll do for now";

  print "</body></html>\n";

  return OK;
}

return 1; # modules must return true
