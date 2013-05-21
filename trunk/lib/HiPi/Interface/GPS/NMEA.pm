#########################################################################################
# Package       HiPi::Interface::GPS::NMEA
# Description:  GPS NMEA Protocol Interface
# Created       Tue Apr 30 22:14:16 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::GPS::NMEA;

#########################################################################################

use strict;
use warnings;
use HiPi::Interface;
use base qw( HiPi::Interface );

our $VERSION = '0.33';

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        # standard device
        devicename      => '/dev/ttyAMA0',
        
        # serial port
        baudrate        => 9600,
        parity          => 'none',
        stopbits        => 1,
        databits        => 8,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        my %portparams;
        for (qw( devicename baudrate parity stopbits databits ) ) {
            $portparams{$_} = $params{$_};
        }
        require HiPi::Device::SerialPort;
        $params{device} = HiPi::Device::SerialPort->new(%portparams);
    }
    
    my $self = $class->SUPER::new(%params);
    return $self;
}



1;
