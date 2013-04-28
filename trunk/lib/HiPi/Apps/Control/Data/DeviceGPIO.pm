#########################################################################################
# Package       HiPi::Apps::Control::Data::DeviceGPIO
# Description:  Manage Device GPIO
# Created       Fri Mar 01 15:53:01 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::DeviceGPIO;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator::Data );
use Wx qw( wxTheApp );
use HiPi::Device::GPIO;
use HiPi::Utils qw( is_raspberry );
use HiPi::Constant qw( :raspberry );
use Carp;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( pincount ) );

our @_validpins = HiPi::RaspberryPi::get_validpins;

sub new {
    my ($class, $readonly) = @_;
    my $self = $class->SUPER::new('pindata', 'udevgroup', 'udevactive');
    $self->readonly(1) if $readonly;
    $self->pincount( scalar @_validpins  );
    return $self;
}

sub read_data {
    my $self = shift;
    
    # Handle testing use on none Raspbian
    return $self->_set_dummy_data unless is_raspberry;        
    
    my $gpio = HiPi::Device::GPIO->new;
    
    my $pindata = {};
    
    for my $pinid( @_validpins ) {
        my $pinname = sprintf("GPIO %02d", $pinid);
        my $pinlookup = sprintf("GPIO_%02d", $pinid);
        $pindata->{$pinname} = {
            id        => $pinid,
            exported  => 0,
            direction => 0,
            edge      => 0,
            activelow => 0,
            value     => 0,
            rpi       => gpio_2_rpitext($pinlookup)
        };
        
        if( $gpio->pin_status($pinid) == HiPi::Device::GPIO::DEV_GPIO_PIN_STATUS_EXPORTED ) {
            my $pin = $gpio->get_pin( $pinid );
            $pindata->{$pinname}->{exported} = 1;
            $pindata->{$pinname}->{direction} = $pin->mode;
            $pindata->{$pinname}->{edge} = $pin->interrupt;
            $pindata->{$pinname}->{activelow} = $pin->active_low;
            $pindata->{$pinname}->{value} = $pin->value;
        }
    }
    $self->set_value('pindata', $pindata);
    
    my $udata = HiPi::Utils::parse_udev_rule();
    $self->set_value('udevgroup', $udata->{gpio}->{group});
    $self->set_value('udevactive', $udata->{gpio}->{active});
    
    return 1;
}

sub _set_dummy_data {
    my $self = shift;
    my $pindata = {};
    for my $pinid( @_validpins ) {
        my $pinname = sprintf("GPIO %02d", $pinid);
        my $pinlookup = sprintf("GPIO_%02d", $pinid);
        $pindata->{$pinname} = {
            id        =>  $pinid,
            exported  => 0,
            direction => 0,
            edge      => 0,
            activelow => 0,
            value     => 0,
            rpi       => gpio_2_rpitext($pinlookup)
        };
    }
    
    # change pin 27 init value
    $pindata->{'GPIO 04'} = {
        id        => 4,
        exported  => 1,
        direction => 1,
        edge      => 0,
        activelow => 0,
        value     => 1,
        rpi       => gpio_2_rpitext('GPIO_04')
    };
    
    $self->set_value('pindata', $pindata);
    
    my $udata = HiPi::Utils::parse_udev_rule();
    $self->set_value('udevgroup', $udata->{gpio}->{group});
    $self->set_value('udevactive', $udata->{gpio}->{active});
    
    return 1;
}

1;
