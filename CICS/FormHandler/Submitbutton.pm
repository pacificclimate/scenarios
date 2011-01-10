package CICS::FormHandler::Submitbutton;
use strict;

use CICS::FormHandler::FormBit;
use base qw(CICS::FormHandler::FormBit);

use CICS::Helpers;

sub new {
  my($class, $self) = @_;
  if(!defined($self)) {
    $self = {};
  } else {
    if((!defined($self->{allowed_values}) || !is_arrayref($self->{allowed_values}))) {
      if(defined($self->{value})) {
	$self->{allowed_values} = [ $self->{value} ];
      } elsif(defined($self->{friendlyname})) {
	$self->{allowed_values} = [ $self->{friendlyname} ];
      }
    }
  }

  set_if_empty($self, "allowed_values", [ "Submit" ]);
  set_if_empty($self, "separator", "");

  return CICS::FormHandler::FormBit::new($class, $self);
}

sub renderField {
  my($self) = shift;
  my(@elems) = ();

  if(!defined($self->name())) {
    print STDERR "Warning: Submit button(s) have no name\n";
  }

  if(defined($self->{allowed_values}) && is_arrayref($self->{allowed_values})) {
    my($key);
    for($key = 0; $key <= $#{$self->{allowed_values}}; $key++) {
      if(length($self->{allowed_values}->[$key])) {
	my($hash) = { type => "submit", class => $self->cssclass(), name => $self->name(), value => $self->{allowed_values}->[$key] };
	push(@elems, createXMLElement("input", 1, $hash, $self->extra()));
      } else {
	push(@elems, "&nbsp;");
      }
    }
  } else {
    print STDERR "Warning: Submit button(s) must have at least one value in allowed_values\n";
  }

  return join($self->{separator} . "\n", @elems);
}

return 1;
