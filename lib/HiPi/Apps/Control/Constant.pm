#########################################################################################
# Package       HiPi::Apps::Control::Constant
# Description:  Application Constants
# Created       Tue Feb 26 05:55:02 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Constant;

#########################################################################################

use strict;
use warnings;
require Exporter;
use base qw( Exporter );

our $VERSION = '0.22';

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

#-------------------------------------------
# Pad Pin Constants
#-------------------------------------------

use constant {
    DNC_PIN_3V3       =>    -100,
    DNC_PIN_5V0       =>    -101,
    DNC_PIN_GND       =>    -102,
    DNC_PIN_NC        =>    -103,
};


{
    my @const = qw(
        DNC_PIN_3V3 DNC_PIN_5V0 DNC_PIN_GND DNC_PIN_NC
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{padpin}  = \@const;
}

1;
