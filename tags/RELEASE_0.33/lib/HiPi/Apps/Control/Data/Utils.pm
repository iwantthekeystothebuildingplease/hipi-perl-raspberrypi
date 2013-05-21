#########################################################################################
# Package       HiPi::Apps::Control::Data::Utils
# Description:  
# Created       Thu Feb 28 09:19:58 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::Utils;

#########################################################################################
use 5.14.0;
use strict;
use warnings;
use Wx qw( wxTheApp );
use HiPi::Apps::Control::Constant qw( :padpin );
use HiPi::Constant qw( :raspberry );

our $VERSION = '0.22';

sub get_pin_data {
    my ($rpipin, $gpiopin) = @_;
    my $gpio = wxTheApp->devmem;
    my $data;
    given( $gpiopin ) {
        when( [ DNC_PIN_3V3 ] ) {
            $data = {
                    label    => '3V3',
                    function => '3V3',
                    padnum   => $rpipin,
                    gpionum  => DNC_PIN_3V3,
                    value    => -1,
                    interrupts => RPI_INT_NONE,
                    colouter => [ 192, 0, 0 ],
                    colinner => [ 255, 255,255 ],
                    fsel     => -1,
                    powerpin => 1,
            };
        }
        when( [ DNC_PIN_5V0 ] ) {
            $data = {
                    label    => '5V0',
                    function => '5V0',
                    padnum   => $rpipin,
                    gpionum  => DNC_PIN_5V0,
                    value    => -1,
                    interrupts => RPI_INT_NONE,
                    colouter => [ 255, 0, 0 ],
                    colinner => [ 255, 255,255 ],
                    fsel     => -2,
                    powerpin => 1,
            };
        }
        when( [ DNC_PIN_GND ] ) {
            $data = {
                    label    => 'GND',
                    function => 'GND',
                    padnum   => $rpipin,
                    gpionum  => DNC_PIN_GND,
                    value    => -1,
                    interrupts => RPI_INT_NONE,
                    colouter => [ 80, 80, 80 ],
                    colinner => [ 255, 255,255 ],
                    fsel     => -3,
                    powerpin => 1,
                };
        }
        default {
            my $function  = $gpio->gpio_fget_name($gpiopin);
            my $fsel = $gpio->gpio_fget($gpiopin);
            my $value     = -1;
            my $interrupts = RPI_INT_NONE;
            my $label = $function;
            my $colouter = [ 127, 127, 127 ];
            my $colinner = [ 255, 255, 255 ];
            if( $function =~ /^(INPUT|OUTPUT)$/ ) {
                $value = $gpio->gpio_lev($gpiopin);
                $label = 'GPIO ' . $gpiopin;
                # for output
                $colouter = [ 127, 255, 127 ];
                $colinner = ( $value ) ? [ 255, 0, 0 ] : [ 255, 255, 255 ] ;
            }
            if( $function eq 'INPUT' ) {
                $interrupts = $gpio->gpio_get_eds($gpiopin);
                $colouter = [ 127, 127, 255 ];
            } elsif( $function =~ /^SPI\d/) {
                $colouter = [ 255, 0, 255 ];
                $colinner = [ 255, 255,255 ];
            } elsif( $function =~ /^I2C\d/) {
                $colouter = [ 100, 200, 255 ];
                $colinner = [ 255, 255,255 ];
            } elsif( $function =~ /^UART\d/) {
                $colouter = [ 255, 255, 0 ];
                $colinner = [ 255, 255,255 ];
            }
            $data = {
                    label    => $label,
                    function => $function,
                    fsel     => $fsel,
                    padnum   => $rpipin,
                    gpionum  => $gpiopin,
                    value    => $value,
                    interrupts => $interrupts,
                    colinner => $colinner,
                    colouter => $colouter,
                    powerpin => 0,
            };
        }
    }
    return $data;
}



1;
