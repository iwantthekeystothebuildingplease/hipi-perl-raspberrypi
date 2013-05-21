#########################################################################################
# Package       HiPi::Wx::Validator::BoolEnable
# Description:  Base Classes For Validators
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Validator::BoolEnable;

#########################################################################################

use strict;
use warnings;
use HiPi::Wx::Validator::PassThrough;
use base qw( HiPi::Wx::Validator::PassThrough );

our $VERSION = '0.22';

sub new {
    my($class, $vdata, $vdatafield, $trueisfalse ) = @_;
    my $self = $class->SUPER::new( $vdata, $vdatafield );
    $self->{_trueisfalse} = $trueisfalse || 0;
    return $self;
}

sub OnValidatorSetValue {
    my ($self, $value) = @_;
    my $enabled = ( $value ) ? 1 : 0;
    if(  $self->{_trueisfalse} ) {
        $enabled = ( $enabled ) ? 0 : 1;
    }
    $self->GetWindow->Enable($enabled);
}

sub Clone {
    my $self = shift;
    my $clone = $self->SUPER::Clone;
    $clone->{_trueisfalse} = $self->{_trueisfalse};
    return $clone;
}


1;
