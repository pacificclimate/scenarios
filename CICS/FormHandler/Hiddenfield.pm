package CICS::FormHandler::Hiddenfield;
use strict;

use CICS::FormHandler::FormBit;
use base qw(CICS::FormHandler::FormBit);

use CICS::Helpers;

sub renderField {
  my($self) = shift;

  if(!defined($self->name()) || !defined($self->value())) {
    print STDERR "Warning: Hidden field doesn't have both name and value\n";
  }

  my($hash) = { type => "hidden", class => $self->cssclass(), name => $self->name(), value => $self->value() };
  return createXMLElement("input", 1, $hash, $self->extra());
}

return 1;
