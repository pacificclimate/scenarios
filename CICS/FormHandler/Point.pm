package CICS::FormHandler::Point;
use strict;

use CICS::Helpers;
use CICS::Scenario::Regions;
use base qw(CICS::FormHandler::FormBit);

sub new {
  my($class, $self) = @_;
  if(!defined($self)) {
    $self = {};
  }

  if(defined($self->{value})) {
    value($self, $self->{value});
  }

  set_if_empty($self, "allow_empty", 1);
  set_if_empty($self, "numeric", 0);

  return CICS::FormHandler::FormBit::new($class, $self);
}

# FIXME NEED VALIDATE METHOD?

sub value {
  my($self, $value) = @_;


  if(defined($value)) {
    #print STDERR "newValue: " . $value . "\n";
    # Parse
    if(is_arrayref($value)) {
      $self->{value} = $value;
    } else {
      my(@foo) = split(/:/, $value);
      if($#foo == -1 || (is_numeric($foo[0]) && is_numeric($foo[1]))) {
	$self->{value} = \@foo;
      }
    }
#   print STDERR "Set: Point " . (is_arrayref($self->{value})?"is an arrayref":"is not an arrayref") . "\n";
  } else {
    # Fetch
 #   print STDERR "Get: Point " . (is_arrayref($self->{value})?"is an arrayref":"is not an arrayref") . "\n";
    return join(":", @{$self->{value}});
  }
}

sub untaint {
  my($self) = @_;
  my($i);
  for($i = 0; $i <= $#{$self->{value}}; $i++) {
    $self->{value}->[$i] =~ /^(.+)$/;
    $self->{value}->[$i] = $1;
  }
}

sub renderField {
  my($self) = shift;

  if(!defined($self->name()) || !defined($self->value())) {
    print STDERR "Warning: Hidden field doesn't have both name and value\n";
  }

  my($hash) = { type => "hidden", class => $self->cssclass(), name => $self->name(), value => $self->value() };
  return createXMLElement("input", 1, $hash, $self->extra());
}

return 1;
