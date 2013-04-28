#########################################################################################
# Package       HiPi::Interrupt::Handler
# Description:  Main Thread Interrupt Handler
# Created       Wed Apr 24 16:22:56 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interrupt::Handler;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Class );
use Carp;
use HiPi::Interrupt::Message;
use Time::HiRes;

__PACKAGE__->create_accessors( qw(
    docontinue
    timeout
    pinref
    cbackstart
    cbackadd
    cbackremove
    cbackinterrupt
    cbackerror
    cbackcontinue
    cbackstop
    
));

sub new {
    my ($class, %params) = @_;
    $params{timeout} ||= 100;
    $params{pinref} = {};
    
    $params{cbackstart}     = \&_null_cback;
    $params{cbackadd}       = \&_default_cback;
    $params{cbackremove}    = \&_default_cback;
    $params{cbackinterrupt} = \&_default_cback;
    $params{cbackstop}      = \&_null_cback;
    $params{cbackcontinue}  = \&_null_cback;
    $params{cbackerror}     = \&_null_cback;
    
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub register_callback {
    my($self, $cbname, $codref) = @_;
    if( ref($codref) ne 'CODE' ) {
        croak('code reference parameter is not a code ref');
    }
    given( lc($cbname) ) {
        when(['start']) {
            $self->cbackstart($codref);
        }
        when(['add']) {
            $self->cbackadd($codref);
        }
        when(['remove']) {
            $self->cbackremove($codref);
        }
        when(['interrupt']) {
            $self->cbackinterrupt($codref);
        }
        when(['stop']) {
            $self->cbackstop($codref);
        }
        when(['continue']) {
            $self->cbackcontinue($codref);
        }
        when(['error']) {
            $self->cbackerror($codref);
        }
        default {
            croak(qq(unknown callback name $cbname));
        }
    }
}

sub stop {
    my $self = shift;
    HiPi::Interrupt->close_interrupts;
    $self->docontinue(0);
}

sub sleep_timeout {
    my($self, $millisecs) = @_;
    Time::HiRes::usleep( int($millisecs * 1000) );
}

sub poll {
    my $self = shift;
    $self->on_action_start;
    $self->docontinue(1);
    while($self->docontinue) {
        my $actions = 0;
        while (defined(my $msg = HiPi::Interrupt->tqueue->dequeue_nb)) {
            $actions ++;
            my $mobj = HiPi::Interrupt::Message->new($msg);
            given( $mobj->action ) {
                when( ['add'] ) {
                    $self->on_action_add($mobj);
                }
                when( ['remove'] ) {
                    $self->on_action_remove($mobj);
                }
                when( ['interrupt'] ) {
                    $self->on_action_interrupt($mobj);
                }
                when( ['stop'] ) {
                    # we ignore stop messages that
                    # should currently only come
                    # when application is closing
                    $actions --;
                }
                default {
                    $self->on_action_error($mobj);
                }
            }
        }
        $self->sleep_timeout($self->timeout) if !$actions;
        $self->on_action_continue($actions);
    }
    $self->on_action_stop;
}

sub add_pin {
    my($self, $pin, $pinclass) = @_;
    
    $pinclass ||= 'undefined';
    
    if(ref($pin)) {
        if($pin->isa('HiPi::Device::GPIO::Pin')) {
            $self->add_gpio_pin($pin->pinid);
        } elsif($pin->isa('HiPi::BCM2835::Pin')) {
            $self->add_bcmd_pin($pin->pinid);
        } elsif($pin->isa('HiPi::Wiring::Pin')) {
            $self->add_wire_pin($pin->pinid);
        } else {
            croak( 'Unknown pin class ' . ref($pin) );
        }
        return;
    } elsif( $pinclass eq 'undefined' && defined($self->pinref->{$pin}) ) {
        $pinclass = $self->pinref->{$pin}
    }
    
    given( lc($pinclass) ) {
        when( ['gpio'] ) {
            $self->add_gpio_pin($pin);
        }
        when( ['bcmd'] ) {
            $self->add_bcmd_pin($pin);
        }
        when( ['wire'] ) {
            $self->add_wire_pin($pin);
        }
        default {
            croak(qq(unknown pin class $pinclass));
        }
    }
}

sub remove_pin {
    my($self, $pin, $pinclass) = @_;
    
    $pinclass ||= 'undefined';
    
    if(ref($pin)) {
        if($pin->isa('HiPi::Device::GPIO::Pin')) {
            $self->remove_gpio_pin($pin->pinid);
        } elsif($pin->isa('HiPi::BCM2835::Pin')) {
            $self->remove_bcmd_pin($pin->pinid);
        } elsif($pin->isa('HiPi::Wiring::Pin')) {
            $self->remove_wire_pin($pin->pinid);
        } else {
            croak( 'Unknown pin class ' . ref($pin) );
        }
        return;
    } elsif( $pinclass eq 'undefined' && defined($self->pinref->{$pin}) ) {
        $pinclass = $self->pinref->{$pin}
    }
    
    given( lc($pinclass) ) {
        when( ['gpio'] ) {
            $self->remove_gpio_pin($pin);
        }
        when( ['bcmd'] ) {
            $self->remove_bcmd_pin($pin);
        }
        when( ['wire'] ) {
            $self->remove_wire_pin($pin);
        }
        default {
            croak(qq(unknown pin class $pinclass));
        }
    }
}

sub set_polltimeout {
    my($self, $value) = @_;
    my $msg = { action => 'polltimeout', timeout => $value };
    HiPi::Interrupt->broadcast_message(%$msg);
}

sub set_valuetimeout {
    my($self, $value) = @_;
    my $msg = { action => 'valuetimeout', timeout => $value };
    HiPi::Interrupt->broadcast_message(%$msg);
}

#------------------------------------------
# Events Handling
#------------------------------------------

sub _default_cback {
    my($self, $msg) = @_;
    if($msg->error && $self->cbackerror ) {
        $self->cbackerror->($self, $msg);
    }
}

sub _null_cback { my @params = @_; }

sub on_action_start {
    my($self) = @_;
    $self->cbackstart->($self);
}

sub on_action_add {
    my($self, $msg) = @_;
    $self->cbackadd->($self, $msg);
}

sub on_action_remove {
    my($self, $msg) = @_;
    $self->cbackremove->($self, $msg);
}

sub on_action_interrupt {
    my($self, $msg) = @_;
    $self->cbackinterrupt->($self, $msg);
}

sub on_action_error {
    my($self, $msg) = @_;
    $self->cbackerror->($self, $msg);
}

sub on_action_continue {
    my ($self, $actions) = @_;
    $self->cbackcontinue->($self, $actions);
}

sub on_action_stop {
    my($self, $msg) = @_;
    $self->cbackstop->($self, $msg);
}


#------------------------------------------
# GPIO Handling
#------------------------------------------

sub add_gpio_pin {
    my($self, $pin) = @_;
    $self->pinref->{$pin} = 'gpio';
    HiPi::Interrupt->add_gpio_pin($pin);
}

sub remove_gpio_pin {
    my($self, $pin) = @_;
    $self->pinref->{$pin} = undef;
    HiPi::Interrupt->remove_gpio_pin($pin);
}

sub set_gpio_polltimeout {
    my($self, $value) = @_;
    HiPi::Interrupt->set_gpio_polltimeout($value);
}

sub set_gpio_valuetimeout {
    my($self, $value) = @_;
    HiPi::Interrupt->set_gpio_valuetimeout($value);
}

#------------------------------------------
# BCM2835 Handling
#------------------------------------------

sub add_bcmd_pin {
    my($self, $pin) = @_;
    $self->pinref->{$pin} = 'bcmd';
    HiPi::Interrupt->add_bcmd_pin($pin);
}

sub remove_bcmd_pin {
    my($self, $pin) = @_;
    $self->pinref->{$pin} = undef;
    HiPi::Interrupt->remove_bcmd_pin($pin);
}

sub set_bcmd_polltimeout {
    my($self, $value) = @_;
    HiPi::Interrupt->set_bcmd_polltimeout($value);
}

sub set_bcmd_valuetimeout {
    my($self, $value) = @_;
    HiPi::Interrupt->set_bcmd_valuetimeout($value);
}

#------------------------------------------
# Wiring Handling
#------------------------------------------

sub add_wire_pin {
    my($self, $pin) = @_;
    $self->pinref->{$pin} = 'wire';
    HiPi::Interrupt->add_wire_pin($pin);
}

sub remove_wire_pin {
    my($self, $pin) = @_;
    $self->pinref->{$pin} = undef;
    HiPi::Interrupt->remove_wire_pin($pin);
}

sub set_wire_polltimeout {
    my($self, $value) = @_;
    HiPi::Interrupt->set_wire_polltimeout($value);
}

sub set_wire_valuetimeout {
    my($self, $value) = @_;
    HiPi::Interrupt->set_wire_valuetimeout($value);
}


1;
