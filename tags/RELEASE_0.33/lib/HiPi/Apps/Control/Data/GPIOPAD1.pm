#########################################################################################
# Package       HiPi::Apps::Control::Data::GPIOPAD1
# Description:  Data From GPIO PAD1
# Created       Tue Feb 26 04:46:27 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::GPIOPAD1;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Apps::Control::Data::Pad );
use HiPi::Constant qw( :raspberry );
use Wx qw( wxTheApp );
use HiPi::Apps::Control::Constant qw( :padpin );

our $VERSION = '0.22';

our @pinmap = (
    DNC_PIN_3V3,     DNC_PIN_5V0,     RPI_PAD1_PIN_3,  DNC_PIN_5V0,     RPI_PAD1_PIN_5,
    DNC_PIN_GND,     RPI_PAD1_PIN_7,  RPI_PAD1_PIN_8,  DNC_PIN_GND,     RPI_PAD1_PIN_10,
    RPI_PAD1_PIN_11, RPI_PAD1_PIN_12, RPI_PAD1_PIN_13, DNC_PIN_GND,     RPI_PAD1_PIN_15,
    RPI_PAD1_PIN_16, DNC_PIN_3V3,     RPI_PAD1_PIN_18, RPI_PAD1_PIN_19, DNC_PIN_GND,
    RPI_PAD1_PIN_21, RPI_PAD1_PIN_22, RPI_PAD1_PIN_23, RPI_PAD1_PIN_24, DNC_PIN_GND,
    RPI_PAD1_PIN_26,
);

sub new {
    my ($class, $readonly) = @_;
    my @objmap = @pinmap;
    my $self = $class->SUPER::new('Raspberry Pi GPIO Pad 1', \@objmap, $readonly);
    return $self;
}

sub get_gpio_pinnumber {
    my($self, $rpipin) = @_;
    return $pinmap[$rpipin -1];
}

1;
