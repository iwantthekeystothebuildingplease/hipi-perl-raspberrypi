#########################################################################################
# Package       HiPi::Apps::Control::Data::DeviceW1
# Description:  One Wire data
# Created       Fri Mar 01 15:53:01 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::DeviceW1;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator::Data );
use Wx qw( wxTheApp );;
use HiPi::Utils qw( is_raspberry );
use HiPi::Device::OneWire;
use Carp;

our $VERSION = '0.22';

sub new {
    my ($class, $readonly) = @_;
    my $self = $class->SUPER::new('slaves', 'passthrough', 'loaded');
    $self->readonly(1) if $readonly;
    return $self;
}

sub read_data {
    my $self = shift;
    
    # Handle testing use on none Raspbian
    return $self->_set_dummy_data unless is_raspberry;        
    
    my @slaves = HiPi::Device::OneWire->list_slaves;
    $self->set_value('slaves', \@slaves);
    $self->set_value('passthrough', 1);
    $self->set_value('loaded', HiPi::Device::OneWire->modules_are_loaded());
    
    return 1;
}

sub _set_dummy_data {
    my $self = shift;
    
    # ugly kludge - hey ho
    my %idmap = %HiPi::Device::OneWire::idmap;

    my @slaves;
    
    my @idlist = qw(
        28-000000000001
        05-000000000002
        10-000000000004
        14-000000000008
        22-000000000010
        2C-000000000020
        41-000000000040
    );
    
    for my $id ( @idlist ) {
        my ( $family, $discard ) = split(/-/, $id);
        $family = '0' . $family if length($family) == 1;
        my ($name, $desc) = ('','');
        if(exists($idmap{$family})) {
            $name = $idmap{$family}->[0];
            $desc = $idmap{$family}->[1];
        }
        push(@slaves, { id => $id, family => $family, name => $name, description => $desc} );
    }
    
    $self->set_value('slaves', \@slaves);
    $self->set_value('passthrough', 1);
    $self->set_value('loaded', 1);
    return 1;
}

1;
