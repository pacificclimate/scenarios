package CICS::Scenario::Test;
use strict;

use CICS::FormHandler::Form;

sub handler {
  my $r = shift;

  $r->send_http_header('text/html');

  print "<html><head><title>foo</title></head><body>";


  print "</body></html>\n";

  return OK;
}

return 1; # modules must return true
