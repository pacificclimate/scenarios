package CICS::FormHandler::Radiobutton;
use strict;

use CICS::FormHandler::FormBit;
use base qw(CICS::FormHandler::FormBit);

use CICS::Helpers;

sub new {
  my($class, $self) = @_;
  if(!defined($self)) {
    $self = {};
  }

  set_if_empty($self, "height", 1);
  set_if_empty($self, "allowed_values", []);
  set_if_empty($self, "separator", "");

  return CICS::FormHandler::FormBit::new($class, $self);
}

sub renderField {
  my($self) = shift;
  my(@text, $hash);

  if(!defined($self->name())) {
    print STDERR "Warning: Radio button has no name\n";
  }

  if(defined($self->{allowed_values}) && is_arrayref($self->{allowed_values})) {
    my($key);
    for($key = 0; $key <= $#{$self->{allowed_values}}; $key++) {
      if(length($self->{allowed_values}->[$key])) {
	$hash = { class => $self->{cssclass}, name => $self->{name}, type => "radio", value => $key };
	if($self->{value} eq $key) {
	  $hash->{checked} = "checked";
	}
	push(@text, createXMLElement("input", 1, $hash) . $self->{allowed_values}->[$key]);
      }
    }
  }
  return join($self->{separator}, @text);
}

return 1;
