#########################################################################################
# Package       HiPi::Wx::ValidatedText
# Description:  Validated TextCtrl
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::ValidatedText;

#########################################################################################

use strict;
use warnings;
use Wx qw( :textctrl :misc :id );
use base qw( Wx::TextCtrl HiPi::Class );

our $VERSION = '0.22';

sub new {
    my ($class, $parent, $label, $vdata, $vdatafield, $style ) = @_;
    $style ||= 0;
    my $self = $class->SUPER::new( $parent, wxID_ANY, $label, wxDefaultPosition, wxDefaultSize, $style );
    $self->SetValidator(HiPi::Wx::ValidatedText::Validator->new($vdata, $vdatafield));
    return $self;
}

#########################################################################################

package HiPi::Wx::ValidatedText::Validator;

#########################################################################################
use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator );

sub new {
    my($class, $vdata, $vdatafield ) = @_;
    my $self = $class->SUPER::new( $vdata, $vdatafield );
    return $self;
}

sub GetWindowValue {
    my $self = shift;
    my $value = $self->GetWindow->GetValue;
    return $value;
}

sub SetWindowValue {
    my($self, $newvalue) = @_;
    $self->GetWindow->ChangeValue($newvalue);
}

1;
