package CICS::FormHandler::Textbox;
use strict;

use CICS::FormHandler::FormBit;
use base qw(CICS::FormHandler::FormBit);

use CICS::Helpers;

sub renderField {
  my($self) = shift;
  my($hash) = { class => $self->cssclass(), name => $self->name(),
		rows => $self->height(), cols => $self->width(),
	      };

  if(!defined($self->name())) {
    print STDERR "Warning: TextField has no name\n";
  }

  my($text) = createXMLElement("textarea", 0, $hash, $self->extra());
  $text .= (defined($self->value()) ? $self->value() : "");
  $text .= "</textarea>\n";

  return $text;
}

return 1;
