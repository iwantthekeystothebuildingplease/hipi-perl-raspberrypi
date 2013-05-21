#########################################################################################
# Package       HiPi::Interface::DS18X20
# Description:  1 Wire Thermometers 
# Created       Sun Feb 10 03:05:26 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::DS18X20;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi::Device::OneWire;
use Carp;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( id correction divider) );

sub list_slaves {
    my($class) = @_;
    my @slaves = grep { $_->{family} =~ /^(10|28)$/ } ( HiPi::Device::OneWire->list_slaves() );
    return @slaves;
}

sub new {
    my($class, %params) = @_;
    $params{correction} ||= 0.0;
    $params{divider}    ||= 1.0;
    unless ( HiPi::Device::OneWire->id_exists( $params{id} ) ){
        croak qq($params{id} is not present on 1 wire bus);
    }
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub temperature {
    my $self = shift;
    my $data = HiPi::Device::OneWire->read_data( $self->id );
    
    if($data !~ /YES/) {
        # invalid crc
        croak qq(CRC check failed or invalid device for id ) . $self->id;
    }
    if($data =~ /t=(\D*\d+)/i) {
        return ( $1 + $self->correction ) / $self->divider;
    } else {
        croak qq(Could not parse temperature data for device ) . $self->id;
    }
}

1;
