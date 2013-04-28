#########################################################################################
# Package       HiPi::Constant::BoardRev2
# Description:  Constants for Raspberry Pi board revision 2
# Created       Fri Nov 23 22:32:56 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Constant::BoardRev2;

#########################################################################################

use strict;
use warnings;

our $VERSION = '0.20';

package HiPi::Constant;


sub gpio_2_rpitext {
    my $gpiotext = shift;
    my %lookup = (
        GPIO_02 => 'Pad 1 Pin 3',
        GPIO_03 => 'Pad 1 Pin 5',
        GPIO_04 => 'Pad 1 Pin 7',
        GPIO_14 => 'Pad 1 Pin 8',
        GPIO_15 => 'Pad 1 Pin 10',
        GPIO_17 => 'Pad 1 Pin 11',
        GPIO_18 => 'Pad 1 Pin 12',
        GPIO_27 => 'Pad 1 Pin 13',
        GPIO_22 => 'Pad 1 Pin 15',
        GPIO_23 => 'Pad 1 Pin 16',
        GPIO_24 => 'Pad 1 Pin 18',
        GPIO_10 => 'Pad 1 Pin 19',
        GPIO_09 => 'Pad 1 Pin 21',
        GPIO_25 => 'Pad 1 Pin 22',
        GPIO_11 => 'Pad 1 Pin 23',
        GPIO_08 => 'Pad 1 Pin 24',
        GPIO_07 => 'Pad 1 Pin 26',
        GPIO_28 => 'Pad 5 Pin 3',
        GPIO_29 => 'Pad 5 Pin 4',
        GPIO_30 => 'Pad 5 Pin 5',
        GPIO_31 => 'Pad 5 Pin 6',
    );
    if(exists($lookup{$gpiotext})) {
        return $lookup{$gpiotext}
    } else {
        return 'Unknown';
    }
}


#-------------------------------------------
# Constants to convert RPI pin ids
# to Broadcom Pin numbers
#-------------------------------------------

use constant {
    RPI_HIGH               =>  1,
    RPI_LOW                =>  0,
    RPI_BOARD_REVISION     =>  2,
    RPI_PAD1_PIN_3         =>  2,
    RPI_PAD1_PIN_5         =>  3,
    RPI_PAD1_PIN_7         =>  4,
    RPI_PAD1_PIN_8         => 14,
    RPI_PAD1_PIN_10        => 15,
    RPI_PAD1_PIN_11        => 17,
    RPI_PAD1_PIN_12        => 18,
    RPI_PAD1_PIN_13        => 27,
    RPI_PAD1_PIN_15        => 22,
    RPI_PAD1_PIN_16        => 23,
    RPI_PAD1_PIN_18        => 24,
    RPI_PAD1_PIN_19        => 10,
    RPI_PAD1_PIN_21        =>  9,
    RPI_PAD1_PIN_22        => 25,
    RPI_PAD1_PIN_23        => 11,
    RPI_PAD1_PIN_24        =>  8,
    RPI_PAD1_PIN_26        =>  7,
    
    RPI_PAD5_PIN_3         => 28,
    RPI_PAD5_PIN_4         => 29,
    RPI_PAD5_PIN_5         => 30,
    RPI_PAD5_PIN_6         => 31,
    
    RPI_INT_NONE           => 0x00,
    RPI_INT_FALL           => 0x01,
    RPI_INT_RISE           => 0x02,
    RPI_INT_BOTH           => 0x03,
    RPI_INT_AFALL          => 0x04,
    RPI_INT_ARISE          => 0x08,
    RPI_INT_HIGH           => 0x10,
    RPI_INT_LOW            => 0x20,
    
    RPI_PINMODE_INPT       => 0,
    RPI_PINMODE_OUTP       => 1,
    RPI_PINMODE_ALT0       => 4,
    RPI_PINMODE_ALT1       => 5,
    RPI_PINMODE_ALT2       => 6,
    RPI_PINMODE_ALT3       => 7,
    RPI_PINMODE_ALT4       => 3,
    RPI_PINMODE_ALT5       => 2,

    I2C0_SDA	           => 28,
    I2C0_SCL	           => 29,
    I2C1_SDA	           => 2,
    I2C1_SCL	           => 3,
    
    RPI_PUD_NULL           => -1,
    RPI_PUD_OFF            => 0,
    RPI_PUD_DOWN           => 1,
    RPI_PUD_UP             => 2,
    
    # pad 1
    WPI_PIN_0   => 17,
    WPI_PIN_1   => 18,
    WPI_PIN_2   => 27,
    WPI_PIN_3   => 22,
    WPI_PIN_4   => 23,
    WPI_PIN_5   => 24,
    WPI_PIN_6   => 25,
    WPI_PIN_7   => 4,
    WPI_PIN_8   => 2,
    WPI_PIN_9   => 3,
    WPI_PIN_10  => 8,
    WPI_PIN_11  => 7,
    WPI_PIN_12  => 10,
    WPI_PIN_13  => 9,
    WPI_PIN_14  => 11,
    WPI_PIN_15  => 14,
    WPI_PIN_16  => 15,
    # pad 5
    WPI_PIN_17  => 28,
    WPI_PIN_18  => 29,
    WPI_PIN_19  => 30,
    WPI_PIN_20  => 31,
};

our @_rpi_const = qw(
    RPI_HIGH RPI_LOW RPI_BOARD_REVISION
    RPI_PAD1_PIN_3 RPI_PAD1_PIN_5 RPI_PAD1_PIN_7 RPI_PAD1_PIN_8 
    RPI_PAD1_PIN_10 RPI_PAD1_PIN_11 RPI_PAD1_PIN_12 RPI_PAD1_PIN_13
    RPI_PAD1_PIN_15 RPI_PAD1_PIN_16 RPI_PAD1_PIN_18 RPI_PAD1_PIN_19
    RPI_PAD1_PIN_21 RPI_PAD1_PIN_22 RPI_PAD1_PIN_23 RPI_PAD1_PIN_24 
    RPI_PAD1_PIN_26
    RPI_PAD5_PIN_3 RPI_PAD5_PIN_4 RPI_PAD5_PIN_5 RPI_PAD5_PIN_6
    RPI_INT_NONE RPI_INT_FALL RPI_INT_RISE RPI_INT_BOTH
    RPI_INT_AFALL RPI_INT_ARISE RPI_INT_HIGH RPI_INT_LOW
    RPI_PINMODE_INPT RPI_PINMODE_OUTP RPI_PINMODE_ALT0 RPI_PINMODE_ALT1
    RPI_PINMODE_ALT2 RPI_PINMODE_ALT3 RPI_PINMODE_ALT4 RPI_PINMODE_ALT5
    RPI_PUD_NULL RPI_PUD_OFF RPI_PUD_DOWN RPI_PUD_UP
    gpio_2_rpitext );

our @_i2c_const = qw( I2C0_SDA I2C0_SCL I2C1_SDA I2C1_SCL );

our @_wiring_const = qw(
        WPI_PIN_0  WPI_PIN_1  WPI_PIN_2  WPI_PIN_3  WPI_PIN_4
        WPI_PIN_5  WPI_PIN_6  WPI_PIN_7  WPI_PIN_8  WPI_PIN_9
        WPI_PIN_10 WPI_PIN_11 WPI_PIN_12 WPI_PIN_13 WPI_PIN_14
        WPI_PIN_15 WPI_PIN_16
        WPI_PIN_17 WPI_PIN_18 WPI_PIN_19 WPI_PIN_20
        );

1;
