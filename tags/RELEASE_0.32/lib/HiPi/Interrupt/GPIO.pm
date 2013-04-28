#########################################################################################
# Package       HiPi::Interrupt::GPIO
# Description:  Device GPIO Interrupt Handler
# Created       Wed Apr 24 05:59:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interrupt::GPIO;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Interrupt::Base );
use IO::Epoll;
use Fcntl;
use Try::Tiny;
use Time::HiRes;
use POSIX;

__PACKAGE__->create_accessors( qw( handles handleindex epfd epollflags epfdsize ) );

use constant {
    EDGE_DETECT_FALLING => 4,
    EDGE_DETECT_RISING  => 8,
};

sub new {
    my ($class, %params) = @_;
    
    # common
    $params{pinclass}    = 'gpio';
    
    # override
    $params{polltimeout} = 1000;
    
    # specific
    $params{epollflags}  = EPOLLET | EPOLLPRI | EPOLLIN;
    $params{epfdsize}    = 30;
    $params{epfd}        = epoll_create( $params{epfdsize} );
    $params{handles}     = {};
    $params{handleindex} = {};
    
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
            $self->sleep_timeout($self->polltimeout);
            next;
        }
        
        my $epevents = epoll_wait($self->epfd, $self->epfdsize, $self->polltimeout );        
        
        if( $epevents ) {
            
            my $timestamp = $self->get_timestamp;
            for my $event ( @$epevents ) {
                
                my ($fileno, $evmask) = @$event;
                my $gpioname = $self->handleindex->{$fileno};
                my $fhdata = $self->handles->{$gpioname};
                
                try {
                    my $value = $self->read_value($fhdata->{fh});
                    $fhdata->{BCMVALUE} = $value;
                    my $sendinterrupt = 0;
                    $sendinterrupt = 1 if(($value == 0) && ( $fhdata->{EMASK} & EDGE_DETECT_FALLING ) );
                    $sendinterrupt = 1 if(($value == 1) && ( $fhdata->{EMASK} & EDGE_DETECT_RISING ) );
                    if( $fhdata->{FIRST} || $evmask == EPOLLIN ) {
                        # ignore first epoll or plain EPOLLIN
                        $fhdata->{FIRST} = 0;
                        $sendinterrupt = 0;
                    }
                    $self->send_interrupt_result($fhdata->{BCMGPIOID}, $value, $timestamp) if $sendinterrupt;
                } catch {
                    $self->send_action_result('interrupt', $fhdata->{BCMGPIOID}, qq(Error : $_));
                };
            }
            
        } else {
            # error
            $self->send_action_result('interrupt', -1, qq(Error : $!));
        }
    }
    
    #-----------------------------
    # close everything
    #-----------------------------
    
    for my $gpioname ( sort keys(%{ $self->handles } ) ) {
        $self->handle_remove( $self->pinname_2_pinid($gpioname) );
    }
    
    POSIX::close( $self->epfd );
    
    $self->send_action_result('stop', -1);
}

sub handle_add {
    my($self, $gpiopin) = @_;
    my $gpioname = $self->pinid_2_pinname($gpiopin);
    
    if( exists $self->handles->{$gpioname} ) {
        $self->send_action_result('add', $gpiopin, qq(Pin already polled by handler));
        return;
    }
    
    my $valfile = qq(/sys/class/gpio/gpio${gpiopin}/value);
    my $edgfile = qq(/sys/class/gpio/gpio${gpiopin}/edge);

    my ($efh, $edgstr);
    
    $edgstr = try {
        my $buffer;
        sysopen($efh, $edgfile, O_RDONLY) or die $!;
        sysseek($efh,0,0);
        defined(sysread($efh, $buffer, 16)) or die $!;
        chomp($buffer);
        close($efh);
        return $buffer;
    } catch {
        close($efh) if $efh;
        $self->send_action_result('add', $gpiopin, qq(Failed to read interrupt status : $_));
        return 'error';
    };
    
    return if(!$edgstr || $edgstr eq 'error');
    
    if( $edgstr eq 'none' ) {
        $self->send_action_result('add', $gpiopin, qq(Pin has egde detection set to 'none'));
        return;
    }
        
    try {
        my ($fh, $rmask);
        sysopen($fh, $valfile, O_RDONLY|O_NONBLOCK) or die $!;
        my $value = $self->read_value($fh);
        
        epoll_ctl($self->epfd, EPOLL_CTL_ADD, $fh->fileno, $self->epollflags ) >= 0 || die qq(epoll_ctl: $!);
        
        if( $edgstr eq 'falling' ) {
            $rmask = EDGE_DETECT_FALLING;
        } elsif( $edgstr eq 'rising' ) {
            $rmask = EDGE_DETECT_RISING;
        } elsif( $edgstr eq 'both' ) {
            $rmask = EDGE_DETECT_RISING | EDGE_DETECT_FALLING;
        } else {
            die qq(unknown edge detect setting $edgstr);
        }
        
        $self->handles->{$gpioname}->{fh} = $fh;
        $self->handles->{$gpioname}->{BCMVALUE}    = $value;
        $self->handles->{$gpioname}->{BCMGPIONAME} = $gpioname;
        $self->handles->{$gpioname}->{BCMGPIOID}   = $gpiopin;
        $self->handles->{$gpioname}->{EMASK}       = $rmask;
        $self->handles->{$gpioname}->{FIRST}       = 1;
        
        my $index = $fh->fileno;
        $self->handleindex->{$index} = $gpioname;
        $self->pollcount( $self->pollcount + 1 );
        $self->send_action_result('add', $gpiopin);
    } catch {
        $self->send_action_result('add', $gpiopin, qq(Failed to add pin to interrupt handler : $_));
    };
}

sub handle_remove {
    my($self, $gpiopin) = @_;
    my $gpioname = $self->pinid_2_pinname($gpiopin);
    
    unless( exists $self->handles->{$gpioname} ) {
        $self->send_action_result('remove', $gpiopin, qq(Pin not polled by handler));
        return;
    }
    
    my $fh = $self->handles->{$gpioname}->{fh};
    try {
           
        epoll_ctl($self->epfd, EPOLL_CTL_DEL, $fh->fileno, $self->epollflags ) >= 0 || die qq(epoll_ctl: $!);
        
        my $index = $fh->fileno;
        delete( $self->handleindex->{$index} );
        
        close($fh);
        delete( $self->handles->{$gpioname} );
        $self->send_action_result('remove', $gpiopin);
    } catch {
        $self->send_action_result('remove', $gpiopin, qq(Error removing pin from interrupt handler : $_));
    };
    $self->pollcount( $self->pollcount - 1 );
}



sub read_value {
    my($self, $fh) = @_;
    sysseek($fh,0,0);
    my $value;
    defined(sysread($fh, $value, 1)) or die $!;
    chomp($value);
    return $value;
}


1;
