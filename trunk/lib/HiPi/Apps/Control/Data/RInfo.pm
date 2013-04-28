#########################################################################################
# Package       HiPi::Apps::Control::Data::RInfo
# Description:  General Info
# Created       Fri Mar 01 15:53:01 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Data::RInfo;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator::Data );
use HiPi::RaspberryPi;

our $VERSION = '0.22';

sub new {
    my ($class, $readonly) = @_;
    my $self = $class->SUPER::new('info', 'passthrough');
    $self->readonly(1) if $readonly;
    return $self;
}

sub read_data {
    my $self = shift;
    
    my $info = HiPi::RaspberryPi::get_piboard_info;
    $info->{cpuinfo} = HiPi::RaspberryPi::get_cpuinfo;
    $self->set_value('info', $info);
    $self->set_value('passthrough', 1);
    
    return 1;
}

1;
