#########################################################################################
# Package       HiPi::Interrupt::Message
# Description:  Interrupt Message
# Created       Wed Apr 24 17:17:43 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interrupt::Message;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );

__PACKAGE__->create_accessors( qw( action pinid error value timestamp msgtext pinclass ) );

sub new {
    my ($class, $params) = @_;
    my $self = $class->SUPER::new(%$params);
    return $self;
}

1;
