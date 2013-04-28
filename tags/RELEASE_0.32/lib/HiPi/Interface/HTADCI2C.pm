#########################################################################################
# Package       HiPi::Interface::HTADCI2C
# Description:  Control HTADCI2C I2C Analog to Digital ic via I2C
# Created       Sun Dec 02 01:42:27 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::HTADCI2C;

#########################################################################################

use strict;
use warnings;
use HiPi::Constant qw( :raspberry );
use parent qw( HiPi::Interface );
use Carp;

# Chip based on a PIC 18F14K22

our $VERSION = '0.20';

__PACKAGE__->create_accessors( qw( devicename address res fil1 fil0 backend ) );


sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        address     => 0x28,
        device      => undef,
        devicename  => ( RPI_BOARD_REVISION == 1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        res         => 1,
        fil1        => 0,
        fil0        => 0,
        backend     => 'smbus',
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        if ( $params{backend} eq 'bcm2835' ) {
            require HiPi::BCM2835::I2C;
            $params{device} = HiPi::BCM2835::I2C->new(
                address    => $params{address},
                peripheral => ( $params{devicename} eq '/dev/i2c-0' ) ? HiPi::BCM2835::I2C::BB_I2C_PERI_0() : HiPi::BCM2835::I2C::BB_I2C_PERI_1(),
            );
        } else {
            require HiPi::Device::I2C;
            $params{device} = HiPi::Device::I2C->new(
                devicename  => $params{devicename},
                address     => $params{address},
                busmode     => $params{backend},
            );
        }
    }
    
    my $self = $class->SUPER::new(%params);
    
    # set the device params
    my $setupflags = ( $params{res} ) ? 1 : 0;
    $setupflags += 2 if $params{fil0};
    $setupflags += 4 if $params{fil1};
    $self->device->bus_write( $setupflags );
    
    return $self;
}

sub set_option_flags {
    my($self, $res, $fil0, $fil1) = @_;
    my $setupflags = ( $res ) ? 1 : 0;
    $setupflags += 2 if $fil0;
    $setupflags += 4 if $fil1;
    $self->res($res);
    $self->fil0($fil0);
    $self->fil1($fil1);
    $self->device->bus_write( $setupflags );

}

sub read_channel {
    my ($self, $channel) = @_;
    return ( $self->read_register )[$channel];
}

sub read_channels {
    my ($self, @channels) = @_;
    my @all =  $self->read_register;
    my @results;
    for ( @channels ) {
        push (@results, $all[$_]);
    }
    return @results;
}

sub read_register {
    my($self) = @_;
    my $numbytes = ( $self->res ) ? 10 : 20;
    my $address  = ( $self->res ) ? 0x01 : 0x00;
    my @rvals = $self->device->bus_read( $address, $numbytes );
    if( $numbytes == 10 ) {
        for( my $i = 0; $i < 10; $i++ ) {
            $rvals[$i] *= 4;
        }
        return @rvals;
    } else {
        my @newvals;
        while( @rvals) {
            my $low  = shift( @rvals );
            my $high = shift( @rvals );
            push @newvals,  $high + $low * 256;
        }
        return @newvals;
    }
}

1;
