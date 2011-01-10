package CICS::FormHandler::PointList;
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

sub value {
  my($self, $value) = @_;
  if(defined($value)) {
    # Parse
    if(is_arrayref($value)) {
      $self->{value} = $value;
    } else {
      $self->{value} = str2coords($value);
    }
 #   print STDERR "Set: PointList " . (is_arrayref($self->{value})?"is an arrayref":"is not an arrayref") . "\n";
  } else {
    # Fetch
    #print STDERR "Get: PointList " . (is_arrayref($self->{value})?"is an arrayref":"is not an arrayref") . "\n";
    return coords2str($self->{value});
  }
}

sub untaint {
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
