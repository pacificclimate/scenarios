package CICS::FormHandler::FormBit;
use strict;

use CICS::Helpers;

sub new {
  my($class) = shift();
  my($self) = {};

  if(@_) {
    $self = shift();
  }

  bless($self, $class);

  # Friendly (display) name
  set_if_empty($self, "friendlyname", "");
  
  # Form element name
  set_if_empty($self, "name", undef);
  
  # Form element value
  set_if_empty($self, "value", "");
  
  # Whether empty values are allowed
  set_if_empty($self, "allow_empty", 1);
  
  # Whether to only allow numeric values
  set_if_empty($self, "numeric", 0);
  
  # Height and width of element
  set_if_empty($self, "height", undef);
  set_if_empty($self, "width", undef);
  
  # Max length of input field
  set_if_empty($self, "maxlength", undef);
  
  # Allowed values (if undef, then other constraints apply)
  set_if_empty($self, "allowed_values", undef);
  
  # Order of values
  set_if_empty($self, "value_order", undef);
  
  # Group to put stuff in (same length as data)
  set_if_empty($self, "group", undef);
  
  # Text of last error message
  set_if_empty($self, "error_text", "");
  
  # CSS class for field
  set_if_empty($self, "cssclass", undef);
  
  # Extra HTML bits
  set_if_empty($self, "extra", undef);

  # Default value (useless?)
  set_if_empty($self, "errormsg", "");
  
  return $self;
}

sub name {
  return accessvar("name", undef, @_);
}
sub friendlyname {
  return accessvar("friendlyname", undef, @_);
}
sub value {
  return accessvar("value", undef, @_);
}
sub allow_empty {
  return accessvar("allow_empty", is_boolean, @_);
}
sub numeric {
  return accessvar("numeric", is_boolean, @_);
}
sub height {
  return accessvar("height", undef, @_);
}
sub width {
  return accessvar("width", undef, @_);
}
sub maxlength {
  return accessvar("maxlength", undef, @_);
}
sub allowed_values {
  return accessvar("allowed_values", is_arrayref, @_);
}
sub value_order {
  return accessvar("value_order", is_arrayref, @_);
}
sub group {
  return accessvar("group", is_hashref, @_);
}
sub error_text {
  return accessvar("error_text", undef, @_);
}
sub cssclass {
  return accessvar("cssclass", undef, @_);
}
sub extra {
  return accessvar("extra", undef, @_);
}

sub renderField {
  my($self) = @_;
  return "STUB: " . $self->value;
}

# Untaints the data
sub untaint {
  my($self) = @_;
  if($self->validate()) {
    $self->{value} =~ /^(.*)$/;
    $self->{value} = $1;
  } else {
    print STDERR $self->{name} . " isn't valid data!\n";
  }
}

# Validates the input
sub validate {
  my($self, $text) = @_;
  my($retval) = 1;
  $self->{error_text} = "";

  if(!defined($text)) {
    $text = $self->value();
  }

  if($self->allow_empty()) {
    return 1;
  }

  if(!defined($text)) {
    $self->{error_text} = '"' . $self->{name} . '" is not defined.';
    return 0;
  }

  if(is_arrayref($self->{allowed_values})) {
    if(!defined($self->{allowed_values}->[$text])) {
      $self->{error_text} = '"' . $self->{name} . '" contains a value that is not a valid choice.';
      $retval = 0;
    } elsif(!length($self->{allowed_values}->[$text])) {
      $self->{error_text} = '"' . $self->{name} . '" contains a value that is disabled; valid choices are: (' . join(',', @{$self->{allowed_values}}) . ')' ;
      $retval = 0;
    }
  } elsif(length($text)) {
    if($self->{numeric}) {
      if(!is_numeric($text)) {
	$self->{error_text} = '"' . $self->{name} . '" is not a number.';
	$retval = 0;
      }
    } elsif($self->{maxlength} > 0 && $self->{maxlength} < length($text)) {
      $self->{error_text} = '"' . $self->{name} . '" is too long.';
      $retval = 0;
    }
  } else {
    $self->{error_text} = '"' . $self->{name} . '" is empty.';
    $retval = 0;
  }

  if(length($self->{errormsg})) {
    $self->{error_text} = $self->{errormsg};
  }

  return $retval;
}

return 1;
