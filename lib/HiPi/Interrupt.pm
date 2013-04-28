#########################################################################################
# Package       HiPi::Interrupt
# Description:  GPIO Interrupt Handler
# Created       Wed Apr 24 05:56:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interrupt;

#########################################################################################
use 5.14.0;
use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue;
use HiPi::Utils;
use HiPi::RaspberryPi;
use HiPi;
use HiPi::Constant;

# Queues
my $bcmdqueue = Thread::Queue->new();
my $gpioqueue = Thread::Queue->new();
my $wirequeue = Thread::Queue->new();
my $listqueue = Thread::Queue->new();

our @bgqueues = ( $bcmdqueue, $gpioqueue, $wirequeue );

our $bcmdthread = threads->create(
    { exit => 'thread_only' },
    \&_create_bcmd_thread
);

our $gpiothread = threads->create(
    { exit => 'thread_only' },
    \&_create_gpio_thread
);

our $wirethread = threads->create(
    { exit => 'thread_only' },
    \&_create_wire_thread
);

our @bgthreads = ( $bcmdthread, $gpiothread, $wirethread );

sub _create_gpio_thread {
    require HiPi::Interrupt::GPIO;
    my $handler = HiPi::Interrupt::GPIO->new(
        writeq => $listqueue,
        readq  => $gpioqueue
    );
    $handler->run;
    threads->exit(0);
}

sub _create_bcmd_thread {
    require HiPi::Interrupt::BCM2835;
    my $handler = HiPi::Interrupt::BCM2835->new(
        writeq => $listqueue,
        readq  => $bcmdqueue
    );
    $handler->run;
    threads->exit(0);
}

sub _create_wire_thread {
    require HiPi::Interrupt::Wiring;
    my $handler = HiPi::Interrupt::Wiring->new(
        writeq => $listqueue,
        readq  => $wirequeue
    );
    $handler->run;
    threads->exit(0);
}

sub send_gpio_message {
    my ($class, %input ) = @_;
    $gpioqueue->enqueue( \%input );
}

sub send_bcmd_message {
    my ($class, %input ) = @_;
    $bcmdqueue->enqueue( \%input );
}

sub send_wire_message {
    my ($class, %input ) = @_;
    $wirequeue->enqueue( \%input );
}

sub broadcast_message {
    my ($class, %input ) = @_;
    for my $q ( @bgqueues ) {
        my %msg = %input; 
        $q->enqueue( \%msg );
    }
}

sub tqueue { return $listqueue; }

sub close_interrupts {
    my $class = shift;
    $class->broadcast_message(  action => 'stop'  );
    for my $thr(  @bgthreads   ) {
        $thr->join();
    }
}

sub add_bcmd_pin {
    my( $class, $gpiopin ) = @_;
    my $msg = { action => 'add', pinid => $gpiopin };
    $class->send_bcmd_message( %$msg );
}

sub add_wire_pin {
    my( $class, $gpiopin ) = @_;
    my $msg = { action => 'add', pinid => $gpiopin };
    $class->send_wire_message( %$msg );
}

sub add_gpio_pin {
    my( $class, $gpiopin ) = @_;
    my $msg = { action => 'add', pinid => $gpiopin };
    $class->send_gpio_message( %$msg );
}

sub remove_bcmd_pin {
    my( $class, $gpiopin ) = @_;
    my $msg = { action => 'remove', pinid => $gpiopin };
    $class->send_bcmd_message( %$msg );
}

sub remove_wire_pin {
    my( $class, $gpiopin ) = @_;
    my $msg = { action => 'remove', pinid => $gpiopin };
    $class->send_wire_message( %$msg );
}

sub remove_gpio_pin {
    my( $class, $gpiopin ) = @_;
    my $msg = { action => 'remove', pinid => $gpiopin };
    $class->send_gpio_message( %$msg );
}

sub set_gpio_polltimeout {
    my( $class, $value ) = @_;
    my $msg = { action => 'polltimeout', timeout => $value };
    $class->send_gpio_message( %$msg );
}

sub set_bcmd_polltimeout {
    my( $class, $value ) = @_;
    my $msg = { action => 'polltimeout', timeout => $value };
    $class->send_bcmd_message( %$msg );
}

sub set_wire_polltimeout {
    my( $class, $value ) = @_;
    my $msg = { action => 'polltimeout', timeout => $value };
    $class->send_wire_message( %$msg );
}

1;
