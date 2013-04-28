#########################################################################################
# Package       HiPi::RaspberryPi
# Description:  Data from, inter alia, /proc/cpuinfo
# Created       Sat Nov 24 00:30:35 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::RaspberryPi;

#########################################################################################

use strict;
use warnings;
use threads;
use threads::shared;
use HiPi::Utils qw( is_raspberry );

our $VERSION = '0.20';

our %_revstash = (
    'beta'      => { release => 'Q1 2012', model => 'Raspberry Pi Model B Revision beta', revision => 1, memory => 256, manufacturer => 'Generic' },
    '0002'      => { release => 'Q1 2012', model => 'Raspberry Pi Model B Revision 1.0', revision => 1, memory => 256, manufacturer => 'Generic' },
    '0003'      => { release => 'Q3 2012', model => 'Raspberry Pi Model B Revision 1.0', revision => 1, memory => 256, manufacturer => 'Generic' },
    '0004'      => { release => 'Q3 2012', model => 'Raspberry Pi Model B Revision 2.0', revision => 2, memory => 256, manufacturer => 'Sony' },
    '0005'      => { release => 'Q4 2012', model => 'Raspberry Pi Model B Revision 2.0', revision => 2, memory => 256, manufacturer => 'Qisda' },
    '0006'      => { release => 'Q4 2012', model => 'Raspberry Pi Model B Revision 2.0', revision => 2, memory => 256, manufacturer => 'Egoman' },
    '0007'      => { release => 'Q1 2013', model => 'Raspberry Pi Model A', revision => 2, memory => 256, manufacturer => 'Egoman' },
    '0008'      => { release => 'Q1 2013', model => 'Raspberry Pi Model A', revision => 2, memory => 256, manufacturer => 'Sony' },
    '0009'      => { release => 'Q1 2013', model => 'Raspberry Pi Model A', revision => 2, memory => 256, manufacturer => 'Qisda' },
    '000d'      => { release => 'Q4 2012', model => 'Raspberry Pi Model B Revision 2.0', revision => 2, memory => 512, manufacturer => 'Egoman' },
    '000e'      => { release => 'Q4 2012', model => 'Raspberry Pi Model B Revision 2.0', revision => 2, memory => 512, manufacturer => 'Sony' },
    '000f'      => { release => 'Q4 2012', model => 'Raspberry Pi Model B Revision 2.0', revision => 2, memory => 512, manufacturer => 'Qisda' },
    'unknown'   => { release => 'Q1 2013', model => 'Virtual or Non-Raspberry Model A', revision => 2, memory => 256, manufacturer => 'Virtual' },
);

our %_boardinfo = %{ $_revstash{unknown} };

our %_cpuinfostash: shared;
    
{
    lock %_cpuinfostash;
    %_cpuinfostash = ( 'GPIO Revision' => 2 );
    
    if( is_raspberry ){
        # Only do this on real raspi
        local $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
        my $output = qx(/bin/cat /proc/cpuinfo);
        if( $output ) {
            for ( split(/\n/, $output) ) {
                if( $_ =~ /^([^\s]+)\s*:\s(.+)$/ ) {
                    $_cpuinfostash{$1} = $2;
                }
            }
        }
    }
    
    if(exists($_cpuinfostash{Revision})) {
        if($_cpuinfostash{Revision} =~ /(beta|2|3)$/i ) {
            $_cpuinfostash{'GPIO Revision'} = 1,
        }
        my $rev = lc $_cpuinfostash{Revision};
        my $infokey = exists($_revstash{$rev}) ? $rev : 'unknown';
        %_boardinfo = %{ $_revstash{$infokey} };
    }
}

sub get_cpuinfo {
    # return a ref to the hash of values from /proc/cpuinfo.
    # %_cpuinfo is shared (threads::shared) data
    my %cpuinfo;
    {
        lock %_cpuinfostash;
        %cpuinfo = %_cpuinfostash;
    }
    return \%cpuinfo;
}

sub get_piboard_info {
    my %rval = %_boardinfo;
    return \%rval;
}

sub get_piboard_rev {
    return $_boardinfo{revision};
}

sub get_validpins {
    if( get_piboard_rev == 1 ) {
        return ( 0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25 );
    } else {
        return ( 2, 3, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 22, 23, 24, 25, 27, 28, 29, 30, 31 );
    }
}

1;

__END__
