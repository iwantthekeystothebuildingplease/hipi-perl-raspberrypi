#########################################################################################
# Package       HiPi::Apps::Control::Data::DeviceI2C
# Description:  Manage Device I2C
# Created       Fri Mar 01 15:53:01 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::DeviceI2C;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator::Data );
use Wx qw( wxTheApp );;
use HiPi::Utils qw( is_raspberry );
use HiPi::Constant qw( :raspberry );
use HiPi::Device::I2C;
use HiPi;
use Carp;

our $VERSION = '0.22';

sub new {
    my ($class, $readonly) = @_;
    my $self = $class->SUPER::new('devicelist', 'udevgroup', 'udevactive', 'baudrate', 'passthrough', 'loaded');
    $self->readonly(1) if $readonly;
    return $self;
}

sub read_data {
    my $self = shift;
    
    # Handle testing use on none Raspbian
    return $self->_set_dummy_data unless is_raspberry;        
    
    my $baudrate = HiPi::Device::I2C->get_baudrate();
    my @devices = HiPi::Device::I2C->get_device_list();
    
    $self->set_value('devicelist', \@devices);
    $self->set_value('baudrate', $baudrate);

    my $udata = HiPi::Utils::parse_udev_rule();
    # Currently defaulting to i2c group on
    #$self->set_value('udevgroup', $udata->{spi}->{group});
    #$self->set_value('udevactive', $udata->{spi}->{active});
    $self->set_value('udevgroup', 'i2c');
    $self->set_value('udevactive', 1);
    $self->set_value('passthrough', 1);
    $self->set_value('loaded', HiPi::Device::I2C->modules_are_loaded());
    
    return 1;
}

sub _set_dummy_data {
    my $self = shift;
    $self->set_value('devicelist', [ qw( /dev/i2c-0 /dev/i2c-1 ) ]);
    $self->set_value('baudrate', '100000');
    $self->set_value('udevgroup', 'i2c');
    $self->set_value('udevactive', 1);
    $self->set_value('passthrough', 1);
    $self->set_value('loaded', 1);
    return 1;
}

1;
