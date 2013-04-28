#########################################################################################
# Package       HiPi::Apps::Control::Panel::Device
# Description:  Base for Device panels
# Created       Wed Feb 27 23:09:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Panel::Device;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Apps::Control::Panel::Base );
use Wx;

our $VERSION = '0.22';

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new($parent);
    return $self;
}

1;
