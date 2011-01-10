package CICS::FormHandler::Form;
use strict;

use CICS::Helpers;

# Creates a new form
sub new {
  my($class) = shift();
  my($self) = {};

  if(@_) {
    $self = shift();
  }

  set_if_empty($self, "only_allow_valid", 1);
  set_if_empty($self, "bits", {});
  set_if_empty($self, "title", "form");
  set_if_empty($self, "name", "c_form");
  set_if_empty($self, "error", "");
  set_if_empty($self, "method", "get");
  set_if_empty($self, "extra", undef);
  set_if_empty($self, "action", "/scen/select");

  bless($self, $class);
  return $self;
}

# Accessors
sub bits {
  return accessvar("bits", undef, @_);
}
sub title {
  return accessvar("title", undef, @_);
}
sub name {
  return accessvar("name", undef, @_);
}
sub error {
  return accessvar("error", undef, @_);
}
sub method {
  return accessvar("method", undef, @_);
}
sub action {
  return accessvar("action", undef, @_);
}
sub extra {
  return accessvar("extra", undef, @_);
}

# Adds a bit to the form
sub addBit {
  my($self, $bit) = @_;

  $self->{bits}->{$bit->name()} = $bit;
}

sub getBitByName {
  my($self, $name) = @_;
  my($bk);

  return $self->{bits}->{$name};
}

# Add these elements to a hash (used to process a template)
sub addElements {
  my($self, $hash) = @_;
  my($bk);

  if(!defined($self->{name})) {
    print STDERR "Error: Can't continue with form with no name or method\n";
    return;
  }

  $hash->{$self->name() . ":header"} = createXMLElement("form", 0, { method => $self->method(), id => $self->name(), action => $self->action()}, $self->extra());
  $hash->{$self->name() . ":footer"} = "</form>";

  foreach(keys(%{$self->{bits}})) {
    $hash->{$self->name() . ":" . $_} = $self->{bits}->{$_}->renderField();
  }
}

# Fills in the variables with the data given
sub populate {
  my($self, $data) = @_;
  my($bk);

  foreach(keys(%{$data})) {
    if(defined($self->{bits}->{$_})) {
      my($item) = $self->{bits}->{$_};
      if((!$self->{only_allow_valid} || $item->validate($data->{$item->name()}))) {
	my($value) = $data->{$_};
	if(defined($value)) {
	  $value =~ s/\"/\&quot;/g;
	}
	$item->value($value);
      }
    }
  }
}

sub untaint {
  my($self) = @_;

  foreach(keys(%{$self->{bits}})) {
    $self->{bits}->{$_}->untaint();
  }
}

sub get_errors {
  my($self, $prefix, $postfix) = @_;
  my($err) = "";

  foreach(keys(%{$self->{bits}})) {
    my($item) = $self->{bits}->{$_};
    if(length($item->{error_text})) {
      $err .= $prefix . $item->{error_text} . $postfix;
    }
  }
  return $err;
}

# Validates the items
sub validate {
  my($self) = @_;
  my($result) = 1;
  my($res);
  $self->error("<p class=\"error\">");
  foreach(keys(%{$self->{bits}})) {
    my($item) = $self->{bits}->{$_};
    $res = $item->validate();

    if(!$res) {
      if(!$result) {
	$self->{error} .= "<br>";
      }
      $self->{error} .= $item->error_text();
    }
    $result *= $res;
  }
  $self->{error} .= "</p>";

  return $result;
}

sub get_datahash {
  my($self) = @_;
  my($hash);
  foreach(keys(%{$self->{bits}})) {
    my($item) = $self->{bits}->{$_};
    $hash->{$item->{name}} = $item->value();
  }

  return $hash;
}

return 1;
