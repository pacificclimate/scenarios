#!/usr/bin/perl -w

use strict;

sub f {
    my($x, $y) = @_;

    return $x * $x + $y * $y;
}

print f(4, 3) . "\n";
