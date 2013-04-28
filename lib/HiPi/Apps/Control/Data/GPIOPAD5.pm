#########################################################################################
# Package       HiPi::Apps::Control::Data::GPIOPAD5
# Description:  Data From GPIO PAD1
# Created       Tue Feb 26 04:46:27 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::GPIOPAD5;

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
    DNC_PIN_5V0, DNC_PIN_3V3,  RPI_PAD5_PIN_3,  RPI_PAD5_PIN_4,  RPI_PAD5_PIN_5,
    RPI_PAD5_PIN_6,  DNC_PIN_GND,     DNC_PIN_GND, 
);

sub new {
    my ($class, $readonly) = @_;
    my @objmap = @pinmap;
    my $self = $class->SUPER::new('Raspberry Pi GPIO Pad 5', \@objmap, $readonly);
    return $self;
}

sub get_gpio_pinnumber {
    my($self, $rpipin) = @_;
    return $pinmap[$rpipin -1];
}

1;
