#########################################################################################
# Package       HiPi::Apps::Control::Data::PadPin
# Description:  Base Class for Pads
# Created       Tue Feb 26 04:46:27 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::PadPin;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator::Data );
use HiPi::Constant qw( :raspberry :i2c :spi :serial :pwm  );
use Wx qw( wxTheApp );

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( gpionum rpinum ) );

our @fields = qw( pindata );

sub new {
    my ($class, $rpinum, $gpionum, $readonly) = @_;
    my $self = $class->SUPER::new( @fields );
    $self->readonly(1) if $readonly;
    $self->gpionum( $gpionum );
    $self->rpinum( $rpinum );
    return $self;
}

sub set_new_pin {
    my($self, $rpinum, $gpionum) = @_;
    $self->gpionum( $gpionum );
    $self->rpinum( $rpinum );
}

sub read_data {
    my $self = shift;
    use HiPi::Apps::Control::Data::Utils;
    
    my $pindata = HiPi::Apps::Control::Data::Utils::get_pin_data( $self->rpinum, $self->gpionum );
    
    for ( qw( SPI0 I2C0 I2C1 UART0 UART1 CTS0 CTS1 PWM0 ) ) {
        $pindata->{$_} = 0;
    }
    
    
    my $gpio = wxTheApp->devmem;
    
    # SPI0 = SPI0_MOSI = ALT0
    if( $gpio->gpio_fget( RPI_PAD1_PIN_19 ) == RPI_PINMODE_ALT0 ) {
        $pindata->{SPI0} = 1;
    }
    
    # I2C0 = I2C0_SDA  = ALT0
    if( $gpio->gpio_fget( I2C0_SDA ) == RPI_PINMODE_ALT0 ) {
        $pindata->{I2C0} = 1;
    }
    
    # I2C1 = I2C1_SDA  = ALT0
    if( $gpio->gpio_fget( I2C1_SDA ) == RPI_PINMODE_ALT0 ) {
        $pindata->{I2C1} = 1;
    }
    
    # UART0 = UART0_TXD = ALT0
    if( $gpio->gpio_fget( UART0_TXD ) == RPI_PINMODE_ALT0 ) {
        $pindata->{UART0} = 1;
    }
    
    # UART1 = UART1_TXD = ALT5
    if( $gpio->gpio_fget( UART1_TXD ) == RPI_PINMODE_ALT5 ) {
        $pindata->{UART1} = 1;
    }
    
    # RTSCTS0 = UART0_CTS = ALT3
    if( $gpio->gpio_fget( UART0_CTS ) == RPI_PINMODE_ALT3 ) {
        $pindata->{CTS0} = 1;
    }
    
    # RTSCTS1 = UART1_CTS = ALT5
    if( $gpio->gpio_fget( UART1_CTS ) == RPI_PINMODE_ALT5 ) {
        $pindata->{CTS1} = 1;
    }
    
    # PWM0 = PWM0 = ALT5
    if( $gpio->gpio_fget( PWM0 ) == RPI_PINMODE_ALT5 ) {
        $pindata->{PWM0} = 1;
    }
    
    $self->set_value('pindata', $pindata );
    
    return 1;
}



1;
