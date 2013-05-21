#########################################################################################
# Package       HiPi::Wx::TopLevelWindow
# Description:  Base Class For TopWindows
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::TopLevelWindow;

#########################################################################################

use strict;
use warnings;
use HiPi::Class;
use HiPi::Wx::Common;
use base qw( HiPi::Class HiPi::Wx::Common );

our $VERSION = '0.27';

sub AllowWxLogGuiParent { 1 }

1;
