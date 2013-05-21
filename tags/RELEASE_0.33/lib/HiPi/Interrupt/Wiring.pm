#########################################################################################
# Package       HiPi::Interrupt::Wiring
# Description:  Wiring Interrupt Handler
# Created       Wed Apr 24 05:59:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interrupt::Wiring;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interrupt::Base );

sub new {
    my ($class, %params) = @_;
    $params{pinclass} = 'wire';
    my $self = $class->SUPER::new(%params);
    return $self;
}

1;
