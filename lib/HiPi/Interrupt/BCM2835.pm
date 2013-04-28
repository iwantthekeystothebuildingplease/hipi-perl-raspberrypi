#########################################################################################
# Package       HiPi::Interrupt::BCM2835
# Description:  BCM2835 Interrupt Handler
# Created       Wed Apr 24 05:59:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interrupt::BCM2835;

#########################################################################################
use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Interrupt::Base );
use HiPi::BCM2835;
use HiPi::Constant qw( :raspberry );
use Time::HiRes;
use Try::Tiny;

__PACKAGE__->create_accessors( qw( pins ) );

use constant {
    EDGE_DETECT_FALLING => 4,
    EDGE_DETECT_RISING  => 8,
};

sub new {
    my ($class, %params) = @_;
    
    $params{pinclass} = 'bcmd';
    $params{pins}     = {};
    
    my $self = $class->SUPER::new(%params);
    
    return $self;
}

sub run {
    my $self = shift;
    $self->docontinue(1);

    #-----------------------------
    # Run Loop
    #-----------------------------
    
    while( $self->docontinue ) {
        
        # Standard Queue Check
        last unless $self->check_queue;
        
        # Loop wait if no interrupts
        unless($self->pollcount) {
            $self->sleep_timeout(250);
            next;
        }
        
        # poll for value changes for a total of polltimeout milliseconds
        # delays in microseconds, polltimeout in milliseconds
        my $elapsedms = 0;
        my $limitms   = $self->polltimeout * 1000;
        my $delayms   = 15000;
        
        while( $elapsedms < $limitms ) {
            my @pinevents;
            for my $pinid ( sort keys %{ $self->pins } ) {
                my $pdata = $self->pins->{$pinid};
                my $value = HiPi::BCM2835::bcm2835_gpio_lev($pinid);
                my $oldvalue = $pdata->{value};
                $pdata->{value} = $value;
                
                my $checkmask = $pdata->{mask};
                
                if( $value != $oldvalue ) {
                    my $evneeded = 0;
                    if( ($value == 1) && ( $checkmask & EDGE_DETECT_RISING )) {
                        $evneeded = 1;
                    }
                    if( ($value == 0) && ( $checkmask & EDGE_DETECT_FALLING )) {
                        $evneeded = 1;
                    }
                    push @pinevents, [$pinid, $value] if $evneeded;
                }
            }
            
            if( @pinevents ) {
                my $timestamp = $self->get_timestamp;
                for my $pev ( @pinevents ) {
                    $self->send_interrupt_result(@$pev, $timestamp);
                }
            }
            
            HiPi::BCM2835::bcm2835_delayMicroseconds($delayms);
            $elapsedms += $delayms;
        }
    }
    
    #-----------------------------
    # close everything
    #-----------------------------
    
    foreach my $pinid ( sort keys( %{ $self->pins } )) {
        $self->handle_remove( $pinid );
    }
    
    $self->send_action_result('stop', -1);
}

sub handle_add {
    my($self, $gpiopin) = @_;
    
    HiPi::BCM2835::bcm2835_init();
    
    if( exists $self->pins->{$gpiopin} ) {
        $self->send_action_result('add', $gpiopin, qq(Pin already polled by handler));
        return;
    }
    
    try {
        # get the edge status for the pin
        my $bcmedge = HiPi::BCM2835::hipi_gpio_get_eds($gpiopin);
        
        my $genericedge = 0;
        
        $genericedge = $genericedge | EDGE_DETECT_FALLING if( $bcmedge & RPI_INT_FALL );
        $genericedge = $genericedge | EDGE_DETECT_FALLING if( $bcmedge & RPI_INT_AFALL );
        $genericedge = $genericedge | EDGE_DETECT_FALLING if( $bcmedge & RPI_INT_LOW );
        $genericedge = $genericedge | EDGE_DETECT_RISING  if( $bcmedge & RPI_INT_RISE );
        $genericedge = $genericedge | EDGE_DETECT_RISING  if( $bcmedge & RPI_INT_ARISE );
        $genericedge = $genericedge | EDGE_DETECT_RISING  if( $bcmedge & RPI_INT_HIGH );
         
        my $value = HiPi::BCM2835::bcm2835_gpio_lev($gpiopin);
        $self->pins->{$gpiopin} = { mask => $genericedge , value => $value };
        
        $self->pollcount( $self->pollcount + 1 );
        
        $self->send_action_result('add', $gpiopin);
    } catch {
        $self->send_action_result('add', $gpiopin, qq(Failed to add pin to interrupt handler : $_));
    };
}

sub handle_remove {
    my($self, $gpiopin) = @_;
    
    unless( exists( $self->pins->{$gpiopin} ) ) {
        $self->send_action_result('remove', $gpiopin, qq(Pin not polled by handler));
        return;
    }
    
    delete( $self->pins->{$gpiopin} );
    $self->pollcount( $self->pollcount - 1 );
    
    $self->send_action_result('remove', $gpiopin);
    
    $self->pollcount( $self->pollcount - 1 );
}

1;
