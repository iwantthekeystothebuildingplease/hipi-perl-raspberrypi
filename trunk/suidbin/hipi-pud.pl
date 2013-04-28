#!/usr/bin/perl

#########################################################################################
# Description:  Access to pull up pull down functions via /dev/mem
# Created       Mon Mar 18 22:38:41 2013
# svn id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

use 5.14.0;
use strict;
use warnings;
use HiPi::BCM2835 qw( :all );
use Carp;
use HiPi::RaspberryPi;

our $VERSION ='0.33';

my( $inputpinid, $inputaction ) = @ARGV;

# have we got args
unless ( $inputpinid && $inputaction ) {
    do_usage(1);
}

my $pinid = confirm_pin( $inputpinid );

my $pudaction = confirm_action( $inputaction );

my $dev = HiPi::BCM2835->new;
$dev->gpio_set_pud($pinid, $pudaction);

sub confirm_action {
    my $useraction = shift;
    my $rval;
    given( lc($useraction) ) {
        when(['c', 'clear', 'n', 'none']) {
            $rval = BCM2835_GPIO_PUD_OFF;
        }
        when(['u', 'up']) {
            $rval = BCM2835_GPIO_PUD_UP;
        }
        when(['d', 'down']) {
            $rval = BCM2835_GPIO_PUD_DOWN;
        }
        default {
            do_usage(1);
        }
    }
    return $rval;
}

sub confirm_pin {
    my $userpin = shift;
    my @validpins = HiPi::RaspberryPi::get_validpins;
    if( $userpin ~~ @validpins ) {
        $pinid = $userpin;
    } else {
        croak(qq(Invalid Pin Number $userpin));
    }
}

sub do_usage {
    my $exit = shift;
    my $usage = q(
usage : hipi-pud PINID SETTING
    
    PINID    = bcm2835 gpio pin number
    SETTING  = c[lear] | u[p] | d[own]
    
    Examples:
      clear pull up /down resistors for GPIO 24
        hipi-pud 24 clear
      
      set pull up resistor on GPIO 24
        hipi-pud 24 up

      set pull down resistor on GPIO 24
        hipi-pud 24 down

    Note: PUD settings cannot be read or queried
          and last across restarts.
      
);
    say $usage;
    exit($exit);
}

1;
