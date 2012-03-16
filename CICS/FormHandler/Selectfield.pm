package CICS::FormHandler::Selectfield;
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

  return CICS::FormHandler::FormBit::new($class, $self);
}

sub renderField {
  my($self) = shift;
  my($text);

  my($hash) = { class => $self->cssclass(), name => $self->name(), size => $self->height() };

  if(!defined($self->name())) {
    print STDERR "Warning: Select field has no name\n";
  }

  $text = createXMLElement("select", 0, $hash);

  if(defined($self->{allowed_values}) && is_arrayref($self->{allowed_values})) {
    my($key);
    my(@itemidx);
    if(defined($self->{value_order}) && is_arrayref($self->{value_order})) {
	print STDERR "Value ordering enabled\n";
	@itemidx = @{$self->{value_order}};
    } else {
	@itemidx = 0 .. $#{$self->{allowed_values}};
    }
    my($oldgroup) = "";
    foreach(@itemidx) {
      $key = $_;
      if(length($self->{allowed_values}->[$key])) {
	$hash = { value => $key };
	if($self->{value} eq $key) {
	  $hash->{class} = "selected";
	  $hash->{selected} = "selected";
	}
	if(defined($self->{group}) && is_arrayref($self->{group})) {
	    if($oldgroup ne $self->{group}->[$key]) {
		if($oldgroup ne "") {
		    $text .= "</optgroup>\n";
		}
		if($self->{group}->[$key] ne "") {
		    my($optgroup_hash) = { label => $self->{group}->[$key] };
		    $text .= createXMLElement("optgroup", 0, $optgroup_hash);
		}
		$oldgroup = $self->{group}->[$key];
	    }
	}
	if(substr($self->{allowed_values}->[$key], 0, 2) eq "--") {
	    #$hash->{disabled} = "disabled";
	}
	$text .= createXMLElement("option", 0, $hash);
	$text .= $self->{allowed_values}->[$key] . "</option>\n";
      }
    }
    if($oldgroup ne "") {
	$text .= "</optgroup>\n";
    }
  }
  
  $text .= "</select>\n";

  return $text;
}

return 1;
