package CICS::FormHandler::Checkbox;
use strict;

use CICS::FormHandler::FormBit;
use base qw(CICS::FormHandler::FormBit);

use CICS::Helpers;

sub value {
  my($self) = shift;

  if(@_) {
    my($val) = shift;
    $self->{value} = $val;
    return $self->{value};
  }

  if(!defined($self->{value}) || !length($self->{value}) || $self->{value} == 0) {
    return 0
  } else {
    return 1;
  }
}

sub renderField {
  my($self) = shift;
  my($hash) = { class => $self->cssclass(), type => "checkbox", value => 1,
		name => $self->name() };
  if($self->value()) {
    $hash->{checked} = 1;
  }

  if(!defined($self->name())) {
    print STDERR "Warning: Checkbox has no name\n";
  }

  return createXMLElement("input", 1, $hash);
}

return 1;
