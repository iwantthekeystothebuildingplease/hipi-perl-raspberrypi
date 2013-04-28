#########################################################################################
# Package       HiPi::Interface::SerLCD
# Description:  SerLCD RX Enabled LCD Controller
# Created       Sat Nov 24 20:48:42 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::SerLCD;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::HD44780 );
use feature qw( switch );
use Carp;

our $VERSION = '0.20';

use constant {
    SLCD_START_COMMAND    => chr(0xFE),
    SLCD_SPECIAL_COMMAND  => chr(0x7C),
};

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        # standard device
        devicename      => '/dev/ttyAMA0',
        
        # serial port
        baudrate        => 9600,
        parity          => 'none',
        stopbits        => 1,
        databits        => 8,
        
        # LCD
        width            =>  undef,
        lines            =>  undef,
        backlightcontrol =>  0,
        device           =>  undef,
        positionmap      =>  undef,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        my %portparams;
        for (qw( devicename baudrate parity stopbits databits ) ) {
            $portparams{$_} = $params{$_};
        }
        require HiPi::Device::SerialPort;
        $params{device} = HiPi::Device::SerialPort->new(%portparams);
    }
    
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub send_text {
    my($self, $text) = @_;
    $self->device->write( $text );
}

sub send_command {
    my($self, $command) = @_;
    $self->device->write( SLCD_START_COMMAND . chr($command) );
}

sub send_special_command {
    my($self, $command) = @_;
    $self->device->write( SLCD_SPECIAL_COMMAND . chr($command) );
}

sub backlight {
    my($self, $brightness) = @_;
    $brightness = 0 if $brightness < 0;
    $brightness = 100 if $brightness > 100;
    
    # input $brightness = 0 to 100
    #
    # SerLCD uses a 30 range value 128 - 157
    # to control brightness level
    
    return unless ($self->backlightcontrol);

    my $level;
    if( $brightness == 0 ) {
        $level = 128;
    } elsif( $brightness == 1 ) {
        $level = 129;
    } elsif( $brightness == 100 ) {
        $level = 157;
    } else {
        $level = int( 128.5 + ( ( $brightness / 100 ) * 30 ) );
        $level = 129 if $level < 129;
    }
    
    $level = 157 if $level > 157;
    
    $self->send_special_command( $level );
}

sub update_baudrate {
    my $self = shift;
    my $baud = $self->device->baudrate;
    my $bflag;
    given( $baud ) {
        when( [ 2400 ] ) {
            $bflag = 11;
        }
        when( [ 4800 ] ) {
            $bflag = 12;
        }
        when( [ 9600 ] ) {
            $bflag = 13;
        }
        when( [ 14400 ] ) {
            $bflag = 14;
        }
        when( [ 19200 ] ) {
            $bflag = 15;
        }
        when( [ 38400 ] ) {
            $bflag = 16;
        }
        default {
            croak(qq(The baudrate of the serial device is not supported by the LCD controller));
        }
    }
    
    $self->send_special_command( $bflag );
}

sub update_geometry {
    my $self = shift;
    
    if($self->width == 20) {
        $self->send_special_command( 3 );
    }
    if($self->width == 16) {
        $self->send_special_command( 4 );
    }
    if($self->lines == 4) {
        $self->send_special_command( 5 );
    }
    if($self->lines == 2) {
        $self->send_special_command( 6 );
    }
    if($self->lines == 1) {
        $self->send_special_command( 7 );
    }
}

sub enable_backlight {
    my($self, $flag) = @_;
    $flag = 1 if !defined($flag);
    if( $flag ) {
        $self->send_special_command( 1 );
    } else {
        $self->send_special_command( 2 );
    }
}

sub toggle_splashscreen {
    $_[0]->send_special_command( 9 );
}

sub init_lcd {
    $_[0]->send_special_command( 8 );
}

sub set_splashscreen {
    $_[0]->send_special_command( 10 );
}

1;

__END__
