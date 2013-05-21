#########################################################################################
# Package       HiPi::Apps::Control::Data::DeviceSPI
# Description:  Manage Device SPI
# Created       Fri Mar 01 15:53:01 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::DeviceSPI;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator::Data );
use Wx qw( wxTheApp );;
use HiPi::Utils qw( is_raspberry );
use HiPi::Constant qw( :raspberry );
use HiPi::Device::SPI;
use HiPi;
use Carp;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( pincount ) );

sub new {
    my ($class, $readonly) = @_;
    my $self = $class->SUPER::new('devicelist', 'udevgroup', 'udevactive', 'bufsiz', 'passthrough', 'loaded');
    $self->readonly(1) if $readonly;
    return $self;
}

sub read_data {
    my $self = shift;
    
    # Handle testing use on none Raspbian
    return $self->_set_dummy_data unless is_raspberry;
    
    my $bufsize = HiPi::Device::SPI->get_bufsiz();
    my @devices = HiPi::Device::SPI->get_device_list();
    
    $self->set_value('devicelist', \@devices);
    $self->set_value('bufsiz', $bufsize);

    my $udata = HiPi::Utils::parse_udev_rule();
    $self->set_value('udevgroup', $udata->{spi}->{group});
    $self->set_value('udevactive', $udata->{spi}->{active});
    $self->set_value('passthrough', 1);
    $self->set_value('loaded', HiPi::Device::SPI->modules_are_loaded());
    
    return 1;
}

sub _set_dummy_data {
    my $self = shift;
    $self->set_value('devicelist', [ qw( /dev/spidev0.0 /dev/spidev0.1 ) ]);
    $self->set_value('bufsiz', '4096');
    $self->set_value('udevgroup', 'spi');
    $self->set_value('udevactive', 1);
    $self->set_value('passthrough', 1);
    $self->set_value('loaded', 1);
    return 1;
}

1;
