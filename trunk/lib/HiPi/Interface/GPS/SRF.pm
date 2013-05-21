#########################################################################################
# Package       HiPi::Interface::GPS::SRF
# Description:  GPS SRF Chip Interface
# Created       Tue Apr 30 22:14:16 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::GPS::SRF;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::GPS::NMEA );

our $VERSION = '0.33';

use constant {
    SRF_MID_SET_SERIAL_PORT => '100',
    SRF_MID_NAV_INIT        => '101',
    SRF_MID_SET_DGPS_PORT   => '102',
    SRF_MID_QUERY_RATE      => '103',
    SRF_MID_LLA_NAV_INIT    => '104',
    SRF_MID_DEV_DATA        => '105',
    SRF_MID_SELECT_DATUM    => '106',
    
    SRF_PROTOCOL_SIRF       => '0',
    SRF_PROTOCOL_NMEA       => '1',
    
    SRF_BAUD_4800           => 4800,
    SRF_BAUD_9600           => 9600,
    SRF_BAUD_19200          => 19200,
    SRF_BAUD_38400          => 38400,
    SRF_BAUD_57600          => 57600,
    
    SRF_PARITY_NONE         => '0',
    SRF_PARITY_ODD          => '1',
    SRF_PARITY_EVEN         => '2',
    
    SRF_RESET_HOT_START     => 0x01,
    SRF_RESET_WARM_START    => 0x02,
    SRF_RESET_WARM_START_INIT  => 0x03,
    SRF_RESET_COLD_START    => 0x04,
    SRF_RESET_DEFAULTS      => 0x08,
};

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
        
    my $self = $class->SUPER::new(%params);
    return $self;
}





1;
