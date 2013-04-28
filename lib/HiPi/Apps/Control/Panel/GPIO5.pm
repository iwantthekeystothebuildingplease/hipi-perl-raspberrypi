#########################################################################################
# Package       HiPi::Apps::Control::Panel::GPIO5
# Description:  Base for GPIO Pad panels
# Created       Wed Feb 27 23:09:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Panel::GPIO5;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Apps::Control::Panel::Pad );
use Wx;
use HiPi::Apps::Control::Data::GPIOPAD5;

our $VERSION = '0.22';

sub new {
    my ($class, $parent) = @_;
    my $vdata = HiPi::Apps::Control::Data::GPIOPAD5->new;
    my $self = $class->SUPER::new($parent, $vdata, $vdata->padname);
    return $self;
}

1;
