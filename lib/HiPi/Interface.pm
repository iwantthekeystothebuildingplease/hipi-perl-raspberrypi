#########################################################################################
# Package       HiPi::Interface
# Description:  Base class for interfaces
# Created       Sat Dec 01 18:34:18 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it
#               under the terms of the GNU General Public License as published by the
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );

__PACKAGE__->create_accessors( qw( device ) );

our $VERSION = '0.20';

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub DESTROY { $_[0]->device( undef ); } 

1;
