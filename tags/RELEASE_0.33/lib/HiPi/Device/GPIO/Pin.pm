#########################################################################################
# Package       HiPi::Device::GPIO::Pin
# Description:  Pin
# Created       Wed Feb 20 04:37:38 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Device::GPIO::Pin;

#########################################################################################
use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Pin );
use Carp;
use Fcntl;
use HiPi::Constant qw( :raspberry );
use HiPi;

our $VERSION ='0.33';

__PACKAGE__->create_accessors( qw( pinroot valfh ) );

sub _open {
    my ($class, %params) = @_;
    defined($params{pinid}) or croak q(pinid not defined in parameters);
    
    my $pinroot = qq(/sys/class/gpio/gpio$params{pinid});
    croak qq(pin $params{pinid} is not exported) if !-d $pinroot;
    
    my $valfile = qq($pinroot/value);

    $params{valfh} = _open_file( $valfile );
    $params{pinroot} = $pinroot;
    
    my $self = $class->SUPER::_open(%params);
    return $self;
}

sub _open_file {
    my $filepath = shift;
    my $fh;
    sysopen($fh, $filepath, O_RDWR|O_NONBLOCK) or croak qq(failed to open $filepath : $!);
    return $fh;
}

sub _read_fh_bytes {
    my($fh, $bytes) = @_;
    my $value;
    sysseek($fh,0,0);
    defined( sysread($fh, $value, $bytes) ) or croak(qq(Failed to read from filehandle : $!));
    chomp $value;
    return $value;
}

sub _write_fh {
    my($fh, $val) = @_;
    defined( syswrite($fh, $val) ) or croak(qq(Failed to write to filehandle : $!));
}

sub _do_getvalue {
    _read_fh_bytes( $_[0]->valfh, 1);
}

sub _do_setvalue {
    my( $self, $newval) = @_;
    _write_fh($self->valfh, $newval );
    return $newval;
}

sub _do_getmode {
    my $self = shift;
    my $fh = _open_file( $self->pinroot . '/direction' );
    my $result = _read_fh_bytes( $fh, 16);
    close($fh);
    return ( $result eq 'out' ) ? RPI_PINMODE_OUTP : RPI_PINMODE_INPT;
}

sub _do_setmode {
    my ($self, $newmode) = @_;
    my $fh = _open_file( $self->pinroot . '/direction' );
    if( ($newmode == RPI_PINMODE_OUTP) || ($newmode eq 'out') )  {
        _write_fh($fh, 'out');
        close($fh);
        return RPI_PINMODE_OUTP;
    } else {
        _write_fh($fh, 'in');
        close($fh);
        return RPI_PINMODE_INPT;
    }
}

sub _do_getinterrupt {
    my $self = shift;
    my $fh = _open_file( $self->pinroot . '/edge' );
    my $result = _read_fh_bytes( $fh, 16);
    close($fh);
    
    if($result eq 'rising') {
        return RPI_INT_RISE;
    } elsif($result eq 'falling') {
        return RPI_INT_FALL;
    } elsif($result eq 'both') {
        return RPI_INT_BOTH;
    } else {
        return RPI_INT_NONE;
    }
}

sub _do_setinterrupt {
    my ($self, $newedge) = @_;
   
    my $stredge = 'none';
    
    $newedge = RPI_INT_FALL if $newedge eq 'falling';
    $newedge = RPI_INT_RISE if $newedge eq 'rising';
    $newedge = RPI_INT_BOTH if $newedge eq 'both';
    
    given( $newedge ) {
        when( [ RPI_INT_AFALL, RPI_INT_FALL, RPI_INT_LOW, 'falling'  ] ) {
            $stredge = 'falling';
        }
        when( [ RPI_INT_ARISE, RPI_INT_RISE, RPI_INT_HIGH, 'rising'  ] ) {
            $stredge = 'rising';
        }
        when( [ RPI_INT_BOTH, 'both'  ] ) {
            $stredge = 'both';
        }
        default {
            $stredge = 'none';
        }
    }
    
    my $fh = _open_file( $self->pinroot . '/edge' );
    _write_fh( $fh, $stredge);
    close($fh);
    return $newedge;
}

sub _do_setpud {
    my($self, $pudval) = @_;
    my $pudchars = 'error';
    given( $pudval ) {
        when([ RPI_PUD_OFF ]) {
            $pudchars = 'clear';
        }
        when([ RPI_PUD_UP ]) {
            $pudchars = 'up';
        }
        when([ RPI_PUD_DOWN ]) {
            $pudchars = 'down';
        }
        default {
            croak(qq(Incorrect PUD setting $pudval));
        }
    }
    my $pinid = $self->pinid;
    HiPi::system_sudo(qq(hipi-pud $pinid $pudchars)) and croak qq(failed to set pud restistor for $pinid : $!);
    return 1;
}


sub _do_activelow {
    my($self, $newval) = @_;
    
    my $fh = _open_file( $self->pinroot . '/active_low' );
    my $result;
    if(defined($newval)) {
        _write_fh( $fh, $newval);
        $result = $newval;
    } else {
        $result = _read_fh_bytes( $fh, 1);
    }
    close($fh);
    return $result;
} 

sub DESTROY {
    my $self = shift;
    close($self->valfh);
}

1;
