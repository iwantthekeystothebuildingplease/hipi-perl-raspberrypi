#########################################################################################
# Package       HiPi::Wx::Validator::SetValue
# Description:  Base Classes For Validators
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Validator::SetValue;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator );

our $VERSION = '0.22';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_);
    return $self;
}

sub SetWindowValue {
    my($self, $newvalue) = @_;
    $self->GetWindow->SetValue($newvalue);
}

1;
