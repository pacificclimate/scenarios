package CICS::FormHandler::Test;
use strict;

use CICS::FormHandler::Form;
use CICS::FormHandler::FormBit;

use CICS::FormHandler::Checkbox;
use CICS::FormHandler::Hiddenfield;
use CICS::FormHandler::Selectfield;
use CICS::FormHandler::Submitbutton;
use CICS::FormHandler::Textbox;
use CICS::FormHandler::Textfield;

use CICS::Helpers;

use Apache::Constants qw(OK);

sub handler {
  my $r = shift;

  $r->send_http_header('text/html');

  print "<html><head><title>Test of CICS::FormHandler::</title></head><body>";

  my($form) = CICS::FormHandler::Form->new();

  if($form->title("foo") eq "foo") {
    print "Test: Set variable: PASSED<br/>";
  } else {
    print "<br/>Test: Set variable: FAILED<br/><br/>";
  }

  my($checkbox) = CICS::FormHandler::Checkbox->new({name => 'cb1', friendlyname => 'Foo Checkbox'});
  my($textfield) = CICS::FormHandler::Textfield->new({name => 'tf1', friendlyname => 'Foo Textfield'});
  my($textbox) = CICS::FormHandler::Textbox->new({name => 'tb1', friendlyname => 'Foo Textbox'});
  my($hiddenfield) = CICS::FormHandler::Hiddenfield->new({name => 'hf1', friendlyname => 'Foo HiddenField'});
  my($submitbutton) = CICS::FormHandler::Submitbutton->new({name => 'sb1', friendlyname => 'Foo SelectButton'});
  my($selectfield) = CICS::FormHandler::Selectfield->new({name => 'sf1', friendlyname => 'Foo Selectfield', allowed_values => [ "foo", "bar", "baz" ]});

  $form->addBit($checkbox);
  $form->addBit($textfield);
  $form->addBit($textbox);
  $form->addBit($selectfield);
  $form->addBit($hiddenfield);
  $form->addBit($submitbutton);

  $form->populate({cb1 => "1", tf1 => "Foo", sf1 => 1});

  my($elemhash) = {};
  $form->addElements($elemhash);

  print parseTemplate("/home/bronaugh/public_html/scen-access/test-form.tpl", $elemhash);

  if($form->validate()) {
    print "Test: Validate form: PASSED<br/>";
  } else {
    print "<br/>Test: Validate form: FAILED<br/><br/>";
  }

  print "</body></html>\n";

  return OK;
}

return 1; # modules must return true
