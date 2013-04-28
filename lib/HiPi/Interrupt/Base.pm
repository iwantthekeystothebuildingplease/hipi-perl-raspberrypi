#########################################################################################
# Package       HiPi::Interrupt::Base
# Description:  Interrupt Handler Base
# Created       Wed Apr 24 05:58:10 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interrupt::Base;

#########################################################################################
use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Class );
use Time::HiRes;

__PACKAGE__->create_accessors( qw( readq writeq docontinue pollcount polltimeout pinclass ) );

sub new {
    my ($class, %params ) = @_;
    
    $params{docontinue}   = 0;
    $params{pollcount}    = 0;
    $params{polltimeout}  ||= 100;
    
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
        
        # Loop if no interrupts
        
        $self->sleep_timeout($self->polltimeout);
    }
}

sub sleep_timeout {
    my($self, $millisecs) = @_;
    Time::HiRes::usleep( 1 + int($millisecs * 1000) );
}

sub check_queue {
    my $self = shift;
    if( defined(my $msg = $self->readq->dequeue_nb) ) {
        $self->handle_message($msg);
    }
    return $self->docontinue;
}

sub pinname_2_pinid {
    my( $self, $pinname ) = @_;
    $pinname =~ s/^GPIO//;
    return $pinname * 1;
}

sub pinid_2_pinname {
    my( $self, $pinid ) = @_;
    return 'GPIO' . $pinid;
}

sub send_interrupt_result {
    my($self, $gpiopin, $value, $timestamp) = @_;
    my $interruptmsg = {
        action    => 'interrupt',
        pinid     => $gpiopin,
        error     => 0,
        value     => $value,
        timestamp => $timestamp,
        msgtext   => '',
        pinclass  => $self->pinclass,
    };
    $self->writeq->enqueue($interruptmsg);
}

sub send_action_result {
    my($self, $action, $gpiopin, $error) = @_;
    
    my $actionmsg = {
        action    => $action,
        pinid     => $gpiopin,
        error     => ( $error ) ? 1 : 0,
        value     => '',
        timestamp => $self->get_timestamp,
        msgtext   => $error || '',
        pinclass  => $self->pinclass,
    };
    $self->writeq->enqueue($actionmsg);
}

sub get_timestamp {
    my ($secs, $msecs) = Time::HiRes::gettimeofday();
    my $timestamp = ($secs * 1000) + int($msecs / 1000);
    return( $timestamp );
}

sub handle_stop {
    my($self) = @_;
    $self->docontinue(0);
}

sub handle_message {
    my($self, $msg) = @_;
    
    $msg->{action} ||= 'undefined';
    given( $msg->{action} ) {
        when(['add']) {
            $self->handle_add($msg->{pinid});
        }
        when(['remove']) {
            $self->handle_remove($msg->{pinid});
        }
        when(['stop']) {
            $self->handle_stop();
        }
        when(['polltimeout']) {
            $self->polltimeout( $msg->{timeout} );
        }
        default {
            $self->send_action_result('error', -1, qq(Unknown message action = $msg->{action} ));
        }
    }
}


1;
