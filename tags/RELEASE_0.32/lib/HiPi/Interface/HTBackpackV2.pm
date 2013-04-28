#########################################################################################
# Package       HiPi::Interface::HTBackpackV2
# Description:  HobbyTronics BackpackV2 LCD Controller
# Created       Sat Nov 24 20:46:14 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::HTBackpackV2;

#########################################################################################


use strict;
use warnings;
use parent qw( HiPi::Interface::HD44780 );
use feature qw( switch );
use Carp;
use HiPi::Constant qw( :raspberry );

our $VERSION = '0.20';

__PACKAGE__->create_accessors( qw( devicetype address devicename backend ) );

our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant {
    HTV2_END_SERIALRX_COMMAND    => chr(0xFF),
    
    HTV2_BAUD_2400    => 0,
    HTV2_BAUD_4800    => 1,
    HTV2_BAUD_9600    => 2,
    HTV2_BAUD_14400   => 3,
    HTV2_BAUD_19200   => 4,
    HTV2_BAUD_28800   => 5,
    HTV2_BAUD_57600   => 6,
    HTV2_BAUD_115200  => 7,
    
    HTV2_CMD_PRINT          => 1,
    HTV2_CMD_SET_CURSOR_POS => 2,
    HTV2_CMD_CLEAR_LINE     => 3,
    HTV2_CMD_CLEAR_DISPLAY  => 4,
    HTV2_CMD_LCD_TYPE       => 5,
    HTV2_CMD_HD44780_CMD    => 6,
    HTV2_CMD_BACKLIGHT      => 7,
    HTV2_CMD_WRITE_CHAR     => 10,
    HTV2_CMD_I2C_ADDRESS    => 32,
    HTV2_CMD_BAUD_RATE      => 33,
    HTV2_CMD_CUSTOM_CHAR    => 64,
};

{
    my @const = qw(
        HTV2_CMD_PRINT 
        HTV2_CMD_SET_CURSOR_POS
        HTV2_CMD_CLEAR_LINE
        HTV2_CMD_CLEAR_DISPLAY
        HTV2_CMD_LCD_TYPE
        HTV2_CMD_HD44780_CMD 
        HTV2_CMD_BACKLIGHT 
        HTV2_CMD_WRITE_CHAR
        HTV2_CMD_I2C_ADDRESS
        HTV2_CMD_BAUD_RATE
        HTV2_CMD_CUSTOM_CHAR
    );
    
    push( @EXPORT_OK, @const );
    $EXPORT_TAGS{htv2cmd} = \@const;
}

{
    my @const = qw(
        HTV2_BAUD_2400
        HTV2_BAUD_4800 
        HTV2_BAUD_9600 
        HTV2_BAUD_14400
        HTV2_BAUD_19200
        HTV2_BAUD_28800
        HTV2_BAUD_57600
        HTV2_BAUD_115200
    );
    push( @EXPORT_OK, @const );
    $EXPORT_TAGS{htv2baud} = \@const;
}

sub new {
    my( $class, %userparams)  = @_;
    
	# handle deprecated devicetype param
	if ( defined($userparams{devicetype}) && !defined($userparams{backend}) ) {
		$userparams{backend} = $userparams{devicetype};
	}
	
    my %params = (
        # LCD
        width            =>  undef,
        lines            =>  undef,
        backlightcontrol =>  0,
        device           =>  undef,
        positionmap      =>  undef,
        
        # RX or i2c
        backend          => 'serialrx', # alt [serialrx|i2c|smbus|bcm2835]
		address          => undef,
		devicename       => undef,
	
        # SerialRX params
        baudrate   		  => 9600,
        parity            => 'none',
        stopbits          => 1,
        databits          => 8,
		serial_devicename => '/dev/ttyAMA0',
        
        # i2c params
        i2c_address       => 0x3A,
	    i2c_devicename    => ( RPI_BOARD_REVISION == 1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
	
	# handle deprecated devicetype
	$userparams{devicetype} = $userparams{backend};
	
    unless( defined($params{device}) ) {
        if( lc($params{backend}) eq 'serialrx' ) {
			$params{devicename} = $params{serial_devicename} unless $params{devicename};
            # set a default port
            my %devparams;
            for (qw( devicename baudrate parity stopbits databits ) ) {
                $devparams{$_} = $params{$_};
            }
            require HiPi::Device::SerialPort;
            
            $params{device} = HiPi::Device::SerialPort->new(%devparams);
            
        } elsif( $params{backend} =~ /^(i2c|smbus)$/i ) {
            
            $params{devicename} = $params{i2c_devicename} unless $params{devicename};
	        $params{address}    = $params{i2c_address} unless defined($params{address});
	    
            require HiPi::Device::I2C;
	    
            $params{device} = HiPi::Device::I2C->new(
                devicename   => $params{devicename},
                address      => $params{address},
				busmode      => $params{backend},
            );
		
		} elsif( lc($params{backend}) eq 'bcm2835' ) {
            
            $params{devicename} = $params{i2c_devicename} unless $params{devicename};
	        $params{address}    = $params{i2c_address} unless defined($params{address});
	    
            require HiPi::BCM2835::I2C;
	    
            $params{device} = HiPi::BCM2835::I2C->new(
                peripheral   => ( $params{devicename} eq '/dev/i2c-0' ) ? HiPi::BCM2835::I2C::BB_I2C_PERI_0() : HiPi::BCM2835::I2C::BB_I2C_PERI_1(),
                address      => $params{address},
            );
        }
    }
    
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub send_text {
    my($self, $text) = @_;
    $self->send_htv2_command( HTV2_CMD_PRINT, $text );
}

sub send_command {
    my($self, $command) = @_;
    $self->send_htv2_command( HTV2_CMD_HD44780_CMD, $command );
}

sub send_htv2_command {
    my($self, $command, @params ) = @_;
    if( $self->backend eq 'serialrx') {
        my $buffer  = chr($command);
        if( $command == HTV2_CMD_PRINT ) {
            # one param - a text string
            $buffer .= $params[0];
        } else {
            # all other cases - params are ASCII char codes
            for my $p ( @params ) {
                $buffer .= chr($p);
            }
        }
        return $self->device->write( $buffer . HTV2_END_SERIALRX_COMMAND );
    } else {
        my @i2cvals  = ( $command );
        if( $command == HTV2_CMD_PRINT ) {
            # one param - a text string
            my @strvals = split(//, $params[0]);
            for my $p ( @strvals ) {
                push @i2cvals, ord($p);
            }
        } else {
            # all other cases - params are ASCII char codes
            push(@i2cvals, @params) if @params;
        }
        return $self->device->bus_write( @i2cvals );
    }
}

sub backlight {
    my($self, $brightness) = @_;
    $brightness = 0 if $brightness < 0;
    $brightness = 100 if $brightness > 100;
    
    # $brightness = 0 to 100
    # we translate to 0 - 250
    
    return unless $self->backlightcontrol;
    my $bset;
    if($brightness < 0) {
        $bset = 0;
    } elsif( $brightness >= 250 ) {
        $bset = 250;
    } else {
        $bset = int( 2.5 * $brightness);
    }
    
    $self->send_htv2_command( HTV2_CMD_BACKLIGHT, $bset );
}

sub update_baudrate {
    my $self = shift;
    return unless $self->backend eq 'serialrx';
    my $baud = $self->device->baudrate;
    my $bflag;
    given( $baud ) {
        when( [ 2400 ] ) {
            $bflag = HTV2_BAUD_2400;
        }
        when( [ 4800 ] ) {
            $bflag = HTV2_BAUD_4800;
        }
        when( [ 9600 ] ) {
            $bflag = HTV2_BAUD_9600;
        }
        when( [ 14400 ] ) {
            $bflag = HTV2_BAUD_14400;
        }
        when( [ 19200 ] ) {
            $bflag = HTV2_BAUD_19200;
        }
        when( [ 28800 ] ) {
            $bflag = HTV2_BAUD_28800;
        }
        when( [ 57600 ] ) {
            $bflag = HTV2_BAUD_57600;
        }
        when( [ 115200 ] ) {
            $bflag = HTV2_BAUD_115200;
        }
        default {
            croak(qq(The baudrate of the serial device is not supported by the LCD controller));
        }
    }
    
    $self->send_htv2_command( HTV2_CMD_BAUD_RATE, $bflag );
    carp('The HTBackpackV2 device must be powered off and on after changing baudrate.');
}

sub update_geometry {
    my $self = shift;
    $self->send_htv2_command( HTV2_CMD_LCD_TYPE, $self->lines, $self->width );
}

sub change_i2c_address {
    my( $self, $newaddress) = @_;
    if( $self->backend eq 'serialrx') {
        carp('The HTBackpackV2 device is in Serial RX mode. You cannot change the i2c address.');
        return;
    }
    if($newaddress < 1 || $newaddress > 127) {
        croak('The i2c address must be in the range 1 - 127 ( 0x01 - 0x7F )');
    }
    $self->send_htv2_command( HTV2_CMD_I2C_ADDRESS, $newaddress );
    carp('The HTBackpackV2 device must be powered off and on after changing i2c address.');
}

1;

__END__
