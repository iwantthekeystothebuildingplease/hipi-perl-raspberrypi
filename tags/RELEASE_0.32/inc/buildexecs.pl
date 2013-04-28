#########################################################################################
# Description:  Build Exec Scripts
# Created       Sat Feb 23 17:21:10 2013
# svn id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

use strict;
use warnings;
use HiPi::Utils::Exec;

for my $file ( qw( suidbin/hipi-i2c suidbin/hipi-pud ) ) {
    my @paths = split(/\//, $file);
    my $execname  = pop @paths;
    my $directory = join('/', @paths);
    
    my $builder = HiPi::Utils::Exec->new(
        workingdir => $directory,
        sourceperl => qq($file.pl),
        outputexec => $execname,
    );
    
    $builder->build;
}

1;
