#########################################################################################
# Package       HiPi::Apps::Control::Data::Pad
# Description:  Base Class for Pads
# Created       Tue Feb 26 04:46:27 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::Pad;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator::Data );
use Wx qw( wxTheApp );
use HiPi::Apps::Control::Data::Utils;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( pincount pinmap padname ) );


sub new {
    my ($class, $padname, $pinmap, $readonly) = @_;
    my $self = $class->SUPER::new('pins', 'padname');
    $self->readonly(1) if $readonly;
    my $pincount = scalar @{ $pinmap };
    $self->pincount( $pincount  );
    $self->pinmap( $pinmap );
    $self->padname( $padname );
    return $self;
}

sub read_data {
    my $self = shift;
    
    my @pins;
    
    my @pinmap = @{ $self->pinmap };
    
    for (my $i = 0; $i < @pinmap; $i ++ ) {
        my $rpipin  = $i + 1;
        my $gpiopin = $pinmap[$i];
        my $pindata = HiPi::Apps::Control::Data::Utils::get_pin_data( $rpipin, $gpiopin );
        push( @pins, $pindata );
    }
    
    $self->set_value('padname', $self->padname );
    $self->set_value('pins',    \@pins );
    
    return 1;
}

1;
