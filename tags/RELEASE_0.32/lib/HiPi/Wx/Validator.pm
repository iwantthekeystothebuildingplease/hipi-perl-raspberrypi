#########################################################################################
# Package       HiPi::Wx::Validator
# Description:  Base Classes For Validators
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Validator;

#########################################################################################

use strict;
use warnings;
use Wx;
use HiPi::Class;
use base qw( Wx::PlValidator HiPi::Class);
use Storable;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( vdata vdatafield ) );

sub new {
    my( $class, $data, $datafield ) = @_;
    croak('Invalid data member') if(!$data || !$data->isa('HiPi::Wx::Validator::Data'));
    my $self = $class->SUPER::new;
    $self->init_hipi_object
    (
        'vdata'        => $data,
        'vdatafield'   => $datafield,
    );
}

sub CompareValues {
    my($firstval, $secondval) = @_;
    my $rval = 0;
    if(!ref($firstval) && !ref($secondval)) {
        $rval = ( $firstval eq $secondval ) ? 1 : 0;
    } elsif(ref($firstval) eq ref($secondval)) {
        $Storable::canonical = 1;
        my $checkone = Storable::freeze($firstval);
        my $checktwo = Storable::freeze($secondval);
        $Storable::canonical = 0;
        $rval = ( $checkone eq $checktwo) ? 1 : 0;
    } else {
        $rval = 0
    }
    return $rval;
}

sub CompareWindowToSource { CompareValues($_[1]->GetDataValue, $_[0]->GetWindowValue); }

sub GetWindowValue { $_[0]->GetWindow->GetValue; }

sub SetWindowValue { $_[0]->GetWindow->ChangeValue( $_[1] ); }

sub GetDataValue { $_[0]->vdata->get_value( $_[0]->vdatafield ); }

sub SetDataValue {
    my ($self, $newvalue) = @_;
    my $oldvalue = $self->GetDataValue;
    $self->vdata->set_dirty(1) if !CompareValues($oldvalue, $newvalue);
    $self->vdata->set_value($self->vdatafield, $newvalue);
}

sub TransferToWindow { $_[0]->SetWindowValue( $_[0]->GetDataValue ); 1; }

sub TransferFromWindow { $_[0]->SetDataValue( $_[0]->GetWindowValue); 1; }

sub Validate { 1 }

sub Clone {
    my( $self ) = @_;
    return ref( $self )->new( $self->vdata, $self->vdatafield );
}

sub RefreshSource {
    my $self = shift;
    $self->TransferFromWindow;
    $self->vdata->flush_if_dirty;
    $self->vdata->load_data;
    $self->TransferToWindow;
}

1;
