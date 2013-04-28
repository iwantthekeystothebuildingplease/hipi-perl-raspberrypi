#########################################################################################
# Package       HiPi::Dummy::BCM2835
# Description:  Dummy debug BCM2835
# Created       Wed Feb 27 18:15:13 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Dummy::BCM2835;

#########################################################################################

use strict;
use warnings;

our $VERSION = '0.20';

# Basic dummy implementation for none raspberry platforms

package HiPi::BCM2835;

use strict;
use warnings;
use Carp;
use HiPi::Constant qw( :all );
use Time::HiRes;

#BCM2835_GPIO_FSEL_INPT  => 0, # Input
#BCM2835_GPIO_FSEL_OUTP  => 1, # Output
#BCM2835_GPIO_FSEL_ALT0  => 4, # Alternate function 0
#BCM2835_GPIO_FSEL_ALT1  => 5, # Alternate function 1
#BCM2835_GPIO_FSEL_ALT2  => 6, # Alternate function 2
#BCM2835_GPIO_FSEL_ALT3  => 7, # Alternate function 3
#BCM2835_GPIO_FSEL_ALT4  => 3, # Alternate function 4
#BCM2835_GPIO_FSEL_ALT5  => 2, # Alternate function 5

use constant {
    DUMMY_GPIO_BASE  => 0x20000000 + 0x200000,
    DUMMY_ST_BASE    => 0x20000000 + 0x3000,
    DUMMY_GPIO_PADS  => 0x20000000 + 0x100000,
    DUMMY_CLOCK_BASE => 0x20000000 + 0x101000,
    DUMMY_SPI0_BASE  => 0x20000000 + 0x204000,
    DUMMY_BSC0_BASE  => 0x20000000 + 0x205000,
    DUMMY_GPIO_PWM   => 0x20000000 + 0x20C000,
    DUMMY_BSC1_BASE  => 0x20000000 + 0x804000,
    
    DUMMY_INT_NONE   => 0x00,
    DUMMY_INT_FALL   => 0x01,
    DUMMY_INT_RISE   => 0x02,
    DUMMY_INT_AFALL  => 0x04,
    DUMMY_INT_ARISE  => 0x08,
    DUMMY_INT_HIGH   => 0x10,
    DUMMY_INT_LOW    => 0x20,
    
    DUMMY_FSEL_INPT  => 0, # Input
    DUMMY_FSEL_OUTP  => 1, # Output
    DUMMY_FSEL_ALT0  => 4, # Alternate function 0
    DUMMY_FSEL_ALT1  => 5, # Alternate function 1
    DUMMY_FSEL_ALT2  => 6, # Alternate function 2
    DUMMY_FSEL_ALT3  => 7, # Alternate function 3
    DUMMY_FSEL_ALT4  => 3, # Alternate function 4
    DUMMY_FSEL_ALT5  => 2, # Alternate function 5
    
    DUMMY_PUD_OFF    => 0b00,
    DUMMY_PUD_DOWN   => 0b01,
    DUMMY_PUD_UP     => 0b10,
    
};

our $_dummypins = [
    { pin => 0,   value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_UP, },
    { pin => 1,   value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_UP, },
    { pin => 2,   value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_UP, },
    { pin => 3,   value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_UP, },
    { pin => 4,   value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 5,   value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 6,   value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 7,   value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 8,   value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 9,   value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 10,  value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 11,  value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 12,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 13,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 14,  value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 15,  value => 0, function => DUMMY_FSEL_ALT0, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 16,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 17,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_HIGH|DUMMY_INT_RISE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 18,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 19,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 20,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 21,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 22,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 23,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 24,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 25,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 26,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 27,  value => 0, function => DUMMY_FSEL_OUTP, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 28,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 29,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 30,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 31,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 32,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 33,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 34,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 35,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 36,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 37,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 38,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 39,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 40,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 41,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 42,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 43,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 44,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 45,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 46,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 47,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 48,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 49,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 50,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 51,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 52,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 53,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 54,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 55,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 56,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 57,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 58,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 59,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 60,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 61,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 62,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
    { pin => 63,  value => 0, function => DUMMY_FSEL_INPT, eds => DUMMY_INT_NONE, interrupt => 0, pud => DUMMY_PUD_OFF, },
];



sub bcm2835_gpio { DUMMY_GPIO_BASE }
sub bcm2835_pwm  { DUMMY_GPIO_PWM }
sub bcm2835_clk  { DUMMY_CLOCK_BASE }
sub bcm2835_pads { DUMMY_GPIO_PADS }
sub bcm2835_spi0 { DUMMY_SPI0_BASE }
sub bcm2835_bsc0 { DUMMY_BSC0_BASE }
sub bcm2835_bsc1 { DUMMY_BSC1_BASE }
sub bcm2835_st   { DUMMY_ST_BASE }

#
# Custom Functions
#

sub hipi_gpio_fget {
    my $pin = shift;    
    return $_dummypins->[$pin]->{function};
}

sub hipi_gpio_get_eds {
    my $pin = shift;
    return $_dummypins->[$pin]->{eds};
}

sub _hipi_bcm2835_init { 1 }

sub _hipi_bcm2835_close { 1 }

sub bcm2835_set_debug { 1 }

sub bcm2835_peri_read {
    my $address = shift;
    croak qq(method not implemented);
}

sub bcm2835_peri_read_nb {
    my $address = shift;
    croak qq(method not implemented);
}

sub bcm2835_peri_write {
    my($address, $value ) =@_;
    croak qq(method not implemented);
}

sub bcm2835_peri_write_nb {
    my($address, $value ) =@_;
    croak qq(method not implemented);
}

sub bcm2835_peri_set_bits {
    my($address, $value, $mask ) =@_;
    croak qq(method not implemented);
}

#
# GPIO register access
#

sub bcm2835_gpio_fsel {
    my($pin, $mode) = @_;
    $_dummypins->[$pin]->{function} = $mode;
}

sub bcm2835_gpio_set {
    my($pin ) = @_;
    $_dummypins->[$pin]->{value} = 1;
}

sub bcm2835_gpio_clr {
    my($pin ) = @_;
    $_dummypins->[$pin]->{value} = 0;
}

sub bcm2835_gpio_set_multi {
    my( $mask ) = @_;
    croak qq(method not implemented);
}

sub bcm2835_gpio_clr_multi {
    my( $mask ) = @_;
    croak qq(method not implemented);
}

sub bcm2835_gpio_lev {
    my($pin ) = @_;
    return $_dummypins->[$pin]->{value};
}

sub bcm2835_gpio_eds {
    my($pin ) = @_;
    return $_dummypins->[$pin]->{interrupt};
}

sub bcm2835_gpio_set_eds {
    my($pin ) = @_;
    $_dummypins->[$pin]->{interrupt} = 0;
}

sub bcm2835_gpio_ren {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} | DUMMY_INT_RISE;
}

sub bcm2835_gpio_clr_ren {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} & ~DUMMY_INT_RISE;
}

sub bcm2835_gpio_fen {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} | DUMMY_INT_FALL;
}

sub bcm2835_gpio_clr_fen {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} & ~DUMMY_INT_FALL;
}

sub bcm2835_gpio_hen {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} | DUMMY_INT_HIGH;
}

sub bcm2835_gpio_clr_hen {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} & ~DUMMY_INT_HIGH;
}

sub bcm2835_gpio_len {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} | DUMMY_INT_LOW;
}

sub bcm2835_gpio_clr_len {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} & ~DUMMY_INT_LOW;
}

sub bcm2835_gpio_aren {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} | DUMMY_INT_ARISE;
}

sub bcm2835_gpio_clr_aren {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} & ~DUMMY_INT_ARISE;
}

sub bcm2835_gpio_afen {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} | DUMMY_INT_AFALL;
}

sub bcm2835_gpio_clr_afen {
    my($pin ) = @_;
    $_dummypins->[$pin]->{eds} = $_dummypins->[$pin]->{eds} & ~DUMMY_INT_AFALL;
}

sub bcm2835_gpio_pud {
    my( $pin, $pud) = @_;
    croak qq(method not implemented);
}

sub bcm2835_gpio_pudclk {
    my($pin, $on) = @_;
    croak qq(method not implemented);
}

sub bcm2835_gpio_pad {
    my($group) = @_;
    croak qq(method not implemented);
}

sub bcm2835_gpio_set_pad {
    my($group, $control) = @_;
    croak qq(method not implemented);
}

sub bcm2835_delay {
    my($millis) = @_;
    Time::HiRes::sleep( $millis / 1000.0 );
}

sub bcm2835_delayMicroseconds {
    my($micros) = @_;
    Time::HiRes::usleep( $micros );
}

sub bcm2835_gpio_write {
    my($pin, $on) = @_;
    if($on) {
        bcm2835_gpio_set($pin);
    } else {
        bcm2835_gpio_clr($pin);
    }
}

sub bcm2835_gpio_write_multi {
    my($mask, $on) = @_;
    croak qq(method not implemented);
}

sub bcm2835_gpio_write_mask {
    my($value, $mask) = @_;
    croak qq(method not implemented);
}

sub bcm2835_gpio_set_pud {
    my($pin, $pud) = @_;
    $_dummypins->[$pin]->{pud} = $pud;
}

sub bcm2835_spi_begin {
    bcm2835_gpio_fsel(RPI_PAD1_PIN_26, RPI_PINMODE_ALT0); # CE1
    bcm2835_gpio_fsel(RPI_PAD1_PIN_24, RPI_PINMODE_ALT0); # CE0
    bcm2835_gpio_fsel(RPI_PAD1_PIN_21, RPI_PINMODE_ALT0); # MISO
    bcm2835_gpio_fsel(RPI_PAD1_PIN_19, RPI_PINMODE_ALT0); # MOSI
    bcm2835_gpio_fsel(RPI_PAD1_PIN_23, RPI_PINMODE_ALT0); # CLK
}

sub bcm2835_spi_end {
    bcm2835_gpio_fsel(RPI_PAD1_PIN_26, RPI_PINMODE_INPT); # CE1
    bcm2835_gpio_fsel(RPI_PAD1_PIN_24, RPI_PINMODE_INPT); # CE0
    bcm2835_gpio_fsel(RPI_PAD1_PIN_21, RPI_PINMODE_INPT); # MISO
    bcm2835_gpio_fsel(RPI_PAD1_PIN_19, RPI_PINMODE_INPT); # MOSI
    bcm2835_gpio_fsel(RPI_PAD1_PIN_23, RPI_PINMODE_INPT); # CLK
}

sub bcm2835_spi_setBitOrder {
    my($order) = @_;
    croak qq(method not implemented);
}

sub bcm2835_spi_setClockDivider {
    my($divider) = @_;
    croak qq(method not implemented);
}

sub bcm2835_spi_setDataMode {
    my($mode) = @_;
    croak qq(method not implemented);
}

sub bcm2835_spi_chipSelect {
    my($cs) = @_;
    croak qq(method not implemented);
}

sub bcm2835_spi_setChipSelectPolarity {
    my($cs, $active) = @_;
    croak qq(method not implemented);
}

sub bcm2835_spi_transfer {
    my($value) = @_;
    return $value;
}

sub bcm2835_spi_transfern {
    my($tbuf) = @_;
    return $tbuf;
}

sub bcm2835_spi_transfernb {
    my($tbuf) = @_;
    return $tbuf;
}

sub bcm2835_spi_writenb {
    my($tbuf) = @_;
    return $tbuf;
}

sub bcm2835_i2c_begin { croak qq(method not implemented); }

sub bcm2835_i2c_end {croak qq(method not implemented); }

sub bcm2835_i2c_setSlaveAddress {
    my($addr) = @_;
    croak qq(method not implemented);
}

sub bcm2835_i2c_setClockDivider {
    my($divider) = @_;
    croak qq(method not implemented);
}

sub bcm2835_i2c_write {
    my( $buf ) = @_;
    croak qq(method not implemented);
}

sub bcm2835_i2c_read {
    my( $len ) = @_;
    croak qq(method not implemented);
}

sub bcm2835_st_read {
    croak qq(method not implemented);
}

sub bcm2835_st_delay {
    my($offset_micros, $micros) = @_;
    croak qq(method not implemented);
}


1;
