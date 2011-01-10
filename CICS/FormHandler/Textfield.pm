package CICS::FormHandler::Textfield;
use strict;

use CICS::FormHandler::FormBit;
use base qw(CICS::FormHandler::FormBit);

use CICS::Helpers;

sub renderField {
  my($self) = shift;
  my($hash) = { class => $self->cssclass(), type => "text", 
		value => $self->value(), name => $self->name(),
		size => $self->width()
	      };

  if(!defined($self->name())) {
    print STDERR "Warning: TextField has no name\n";
  }

  return createXMLElement("input", 1, $hash, $self->extra());
}

return 1;
