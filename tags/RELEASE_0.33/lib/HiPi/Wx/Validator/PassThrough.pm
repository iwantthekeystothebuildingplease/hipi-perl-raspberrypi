#########################################################################################
# Package       HiPi::Wx::Validator::PassThrough
# Description:  Base Classes For Validators
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Validator::PassThrough;

#########################################################################################

# This validator is a base for use by controls that do not
# change a data value, but rely on the value for
# setting state etc. Override the OnValidatorSetValue method
# and optionally the OnValidatorGetValue
# in a derived Validator class. Note that OnValidatorGetValue
# is always passed the DataValue NOT the window value
# as this would be useless (it is the value if THIS window.)
# You can implement getting the value from the control you are
# interested in in your OnValidatorGetValue if that is what
# you require.

use strict;
use warnings;
use HiPi::Wx::Validator;
use base qw( HiPi::Wx::Validator );

our $VERSION = '0.22';

sub new { shift->SUPER::new( @_ ) };

sub TransferToWindow   { $_[0]->OnValidatorSetValue( $_[0]->GetDataValue ); 1; }

sub TransferFromWindow { $_[0]->OnValidatorGetValue( $_[0]->GetDataValue ); 1; }

sub Validate           { $_[0]->OnValidatorGetValue( $_[0]->GetDataValue ); 1; }

sub OnValidatorSetValue { 1 }
sub OnValidatorGetValue { 1 }

1;
