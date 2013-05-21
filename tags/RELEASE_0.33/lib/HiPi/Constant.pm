#########################################################################################
# Package       HiPi::Constant
# Description:  Utility constants for HiPi
# Created       Fri Nov 23 22:23:29 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Constant;

#########################################################################################

use strict;
use warnings;
use HiPi::RaspberryPi;
require Exporter;
use base qw( Exporter );

our $VERSION = '0.20';

our @_rpi_const;
our @_i2c_const;
our @_wiring_const;

if( HiPi::RaspberryPi::get_piboard_rev() == 1 ) {
    require HiPi::Constant::BoardRev1;
} else {
    require HiPi::Constant::BoardRev2;
}

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

#-------------------------------------------
# Constants to convert Raspberry Pi 
# PAD Pin numbers to BCM pin ids.
# our @_rpi_const is populated in BoardRevX
# sub-module
#-------------------------------------------

sub RPI_HAS_ROOT_PERM { return ( $< == 0 ) ? 1 : 0; }

push @_rpi_const, 'RPI_HAS_ROOT_PERM';

push @EXPORT_OK, @_rpi_const;
push @EXPORT_OK, @_i2c_const;
push @EXPORT_OK, @_wiring_const;

$EXPORT_TAGS{raspberry} = \@_rpi_const;
$EXPORT_TAGS{i2c} = \@_i2c_const;
$EXPORT_TAGS{wiring} = \@_wiring_const;

#-------------------------------------------
# Pin mode constants
#-------------------------------------------

use constant {
    PIN_MODE_OUTPUT => 1,
    PIN_MODE_INPUT  => 0,
};

{
    my @const = qw(
        PIN_MODE_OUTPUT PIN_MODE_INPUT
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{pinmode}  = \@const;
}

#-------------------------------------------
# Constants to convert UART to Raspberry
# Pi PAD Pin numbers
#-------------------------------------------

use constant {
    UART0_TXD      => 14,
    UART0_RXD      => 15,
    UART0_RTS      => 31,
    UART0_CTS      => 30,
    UART1_TXD      => 14,
    UART1_RXD      => 15,
    UART1_RTS      => 31,
    UART1_CTS      => 30,
};

{
    my @const = qw(
        UART0_TXD UART0_RXD UART0_RTS UART0_CTS
        UART1_TXD UART1_RXD UART1_RTS UART1_CTS
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{serial}  = \@const;
}

#-------------------------------------------
# Constants to convert SPI to BCM GPIO Pins
#-------------------------------------------

use constant {
    SPI0_MOSI       => 10,
    SPI0_MISO       => 9,
    SPI0_CLK        => 11,
    SPI0_SCLK       => 11,
    SPI0_CEO_N      => 8,
    SPI0_CE1_N      => 7,
};

{
    my @const = qw(
        SPI0_MOSI SPI0_MISO SPI0_CLK SPI0_SCLK SPI0_CE0_N SPI0_CE1_N
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{spi}  = \@const;
}

#-------------------------------------------
# Constants for General Purpose Clock
#-------------------------------------------

use constant {
    GPCLK0 => 4,
    GPCLK1 => 7,
};

{
    my @const = qw(
        GPCLK0 GPCLK1
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{gpclock}  = \@const;
}

#-------------------------------------------
# Constants for PWM
#-------------------------------------------

use constant {
    PWM0 => 18,
};

{
    my @const = qw(
        PWM0
    );

    push @EXPORT_OK, @const;
    $EXPORT_TAGS{pwm}  = \@const;
}

1;

__END__
