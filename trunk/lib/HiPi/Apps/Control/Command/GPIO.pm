#########################################################################################
# Package       HiPi::Apps::Control::Command::GPIO
# Description:  GPIO Commands
# Created       Fri Mar 01 02:09:39 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Command::GPIO;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Class );
use Wx qw( wxTheApp );
use Carp;
use HiPi::Constant qw( :raspberry );

our $VERSION = '0.22';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub clear_interrupts {
    my($self, $pin) = @_;
    my $rasp = wxTheApp->devmem;
    $rasp->gpio_clr_fen($pin);
    $rasp->gpio_clr_ren($pin);
    $rasp->gpio_clr_afen($pin);
    $rasp->gpio_clr_aren($pin);
    $rasp->gpio_clr_hen($pin);
    $rasp->gpio_clr_len($pin);
}

sub property_change {
    my($self, $propname, $propvalue, $gpiopin, $oldvalue) = @_;
    
    my $rasp = wxTheApp->devmem;
    
    # Wx::LogMessage('Property : %s - Old Value : %s - New value : %s', $propname, $oldvalue, $propvalue );
    
    given( $propname ) {
        when( ['SPI0'] ) {
            $rasp->set_SPI0($propvalue);
        }
        when( ['I2C0'] ) {
            $rasp->set_I2C0($propvalue);
        }
        when( ['I2C1'] ) {
            $rasp->set_I2C1($propvalue);
        }
        when( ['UART0'] ) {
            $rasp->set_UART0($propvalue);
        }
        when( ['UART1'] ) {
            $rasp->set_UART1($propvalue);
        }
        when( ['CTS0'] ) {
            $rasp->set_CTS0($propvalue);
        }
        when( ['CTS1'] ) {
            $rasp->set_CTS1($propvalue);
        }
        when( ['PWM0'] ) {
            $rasp->set_PWM0($propvalue);
        }
        when( ['PUD'] ) {
            if($propvalue !=  RPI_PUD_NULL) {
                # Remove existing resistor setting if we are applying a pull up / pull down
                $rasp->gpio_set_pud($gpiopin, RPI_PUD_OFF) if $propvalue > RPI_PUD_OFF;
                $rasp->gpio_set_pud($gpiopin, $propvalue);
                my $msg;
                if( $propvalue == RPI_PUD_DOWN ) {
                    $msg = 'Pull Down Resistor Applied To GPIO %s.';
                } elsif( $propvalue == RPI_PUD_UP ) {
                    $msg = 'Pull Up Resistor Applied To GPIO %s.';
                } else {
                    $msg = 'PUD Resistors Removed from GPIO %s.';
                }
                Wx::LogMessage($msg, $gpiopin);
            }
        }
        when( ['INTERRUPTS'] ) {
            if( $propvalue & RPI_INT_FALL) {
                $rasp->gpio_fen($gpiopin);
            } else {
                $rasp->gpio_clr_fen($gpiopin);
            }
            if( $propvalue & RPI_INT_RISE) {
                $rasp->gpio_ren($gpiopin);
            } else {
                $rasp->gpio_clr_ren($gpiopin);
            }
            if( $propvalue & RPI_INT_AFALL) {
                $rasp->gpio_afen($gpiopin);
            } else {
                $rasp->gpio_clr_afen($gpiopin);
            }
            if( $propvalue & RPI_INT_ARISE) {
                $rasp->gpio_aren($gpiopin);
            } else {
                $rasp->gpio_clr_aren($gpiopin);
            }
            if( $propvalue & RPI_INT_HIGH) {
                $rasp->gpio_hen($gpiopin);
            } else {
                $rasp->gpio_clr_hen($gpiopin);
            }
            if( $propvalue & RPI_INT_LOW) {
                $rasp->gpio_len($gpiopin);
            } else {
                $rasp->gpio_clr_len($gpiopin);
            }
            
            $rasp->gpio_set_eds($gpiopin);
        }
        when( ['HIGH'] ) {
            $self->clear_interrupts($gpiopin);
            $rasp->gpio_write($gpiopin, $propvalue);
            #Wx::LogMessage('Any interrupts have been removed.');
        }
        when( ['DIRECTION'] ) {
            $self->clear_interrupts($gpiopin);
            $rasp->gpio_fsel($gpiopin, $propvalue);
            #Wx::LogMessage('Any interrupts have been removed.');
        }
        default {
            croak qq(Unknown property name $propname);
        }
    }
}


1;
