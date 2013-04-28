#########################################################################################
# Package       HiPi::Interface::MCP23017
# Description:  Control MCP23017 Port Extender via I2C
# Created       Sun Dec 02 01:42:27 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::MCP23017;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi::Constant qw( :raspberry );
use Carp;

__PACKAGE__->create_accessors( qw( address devicename backend ) );

our $VERSION = '0.20';

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

#-------------------------------------------
# MCP23017
#------------------------------------------

use constant {
    MCP23017_A0     => 0x1000,
    MCP23017_A1     => 0x1001,
    MCP23017_A2     => 0x1002,
    MCP23017_A3     => 0x1003,
    MCP23017_A4     => 0x1004,
    MCP23017_A5     => 0x1005,
    MCP23017_A6     => 0x1006,
    MCP23017_A7     => 0x1007,
    MCP23017_B0     => 0x1010,
    MCP23017_B1     => 0x1011,
    MCP23017_B2     => 0x1012,
    MCP23017_B3     => 0x1013,
    MCP23017_B4     => 0x1014,
    MCP23017_B5     => 0x1015,
    MCP23017_B6     => 0x1016,
    MCP23017_B7     => 0x1017,
    
    MCP23017_BANK   => 7,
    MCP23017_MIRROR => 6,
    MCP23017_SEQOP  => 5,
    MCP23017_DISSLW => 4,
    MCP23017_HAEN   => 3,
    MCP23017_ODR    => 2,
    MCP23017_INTPOL => 1,
    
    MCP23017_INPUT  => 1,
    MCP23017_OUTPUT => 0,
    
    MCP23017_HIGH   => 1,
    MCP23017_LOW    => 0,

};

{
    my @const = qw(
        MCP23017_A0 MCP23017_A1 MCP23017_A2 MCP23017_A3 
        MCP23017_A4 MCP23017_A5 MCP23017_A6 MCP23017_A7 
        MCP23017_B0 MCP23017_B1 MCP23017_B2 MCP23017_B3 
        MCP23017_B4 MCP23017_B5 MCP23017_B6 MCP23017_B7
        MCP23017_BANK MCP23017_MIRROR MCP23017_SEQOP
        MCP23017_DISSLW MCP23017_HAEN MCP23017_ODR
        MCP23017_INTPOL MCP23017_INPUT MCP23017_OUTPUT
        MCP23017_LOW MCP23017_HIGH
    );
    push @EXPORT_OK, @const;
    $EXPORT_TAGS{mcp23017} = \@const;
}

our %regaddress;

sub set_register_addresses {
    my( $selforclass, $bank) = @_;
    if( $bank == 1 ) {
        $regaddress{IODIRA}   = 0x00;
        $regaddress{IPOLA}    = 0x01;
        $regaddress{GPINTENA} = 0x02;
        $regaddress{DEFVALA}  = 0x03;
        $regaddress{INTCONA}  = 0x04;
        $regaddress{IOCON}    = 0x05;
        $regaddress{GPPUA}    = 0x06;
        $regaddress{INTFA}    = 0x07;
        $regaddress{INTCAPA}  = 0x08;
        $regaddress{GPIOA}    = 0x09;
        $regaddress{OLATA}    = 0x0A;
        $regaddress{IODIRB}   = 0x10;
        $regaddress{IPOLB}    = 0x11;
        $regaddress{GPINTENB} = 0x12;
        $regaddress{DEFVALB}  = 0x13;
        $regaddress{INTCONB}  = 0x14;
        $regaddress{GPPUB}    = 0x16;
        $regaddress{INTFB}    = 0x17;
        $regaddress{INTCAPB}  = 0x18;
        $regaddress{GPIOB}    = 0x19;
        $regaddress{OLATB}    = 0x1A;
    } else {
        $regaddress{IODIRA}   = 0x00;
        $regaddress{IODIRB}   = 0x01;
        $regaddress{IPOLA}    = 0x02;
        $regaddress{IPOLB}    = 0x03;
        $regaddress{GPINTENA} = 0x04;
        $regaddress{GPINTENB} = 0x05;
        $regaddress{DEFVALA}  = 0x06;
        $regaddress{DEFVALB}  = 0x07;
        $regaddress{INTCONA}  = 0x08;
        $regaddress{INTCONB}  = 0x09;
        $regaddress{IOCON}    = 0x0A;
        $regaddress{GPPUA}    = 0x0C;
        $regaddress{GPPUB}    = 0x0D;
        $regaddress{INTFA}    = 0x0E;
        $regaddress{INTFB}    = 0x0F;
        $regaddress{INTCAPA}  = 0x10;
        $regaddress{INTCAPB}  = 0x11;
        $regaddress{GPIOA}    = 0x12;
        $regaddress{GPIOB}    = 0x13;
        $regaddress{OLATA}    = 0x14;
        $regaddress{OLATB}    = 0x15;
    }
}

__PACKAGE__->set_register_addresses(0);

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        devicename  => ( RPI_BOARD_REVISION == 1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address     => 0x20,
        device      => undef,
        backend     => 'smbus',
     _function_mode => 'hipi',
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        if ( $params{backend} eq 'bcm2835' ) {
            require HiPi::BCM2835::I2C;
            $params{device} = HiPi::BCM2835::I2C->new(
                address    => $params{address},
                peripheral => ( $params{devicename} eq '/dev/i2c-0' ) ? HiPi::BCM2835::I2C::BB_I2C_PERI_0() : HiPi::BCM2835::I2C::BB_I2C_PERI_1(),
            _function_mode => $params{_function_mode},
            );
        } else {
            require HiPi::Device::I2C;
            $params{device} = HiPi::Device::I2C->new(
                devicename  => $params{devicename},
                address     => $params{address},
                busmode     => $params{backend},
            );
        }
    }
    
    my $self = $class->SUPER::new(%params);
    
    # get current register address config so correct settings are loaded
    
    $self->read_register_bytes('IOCON');
    
    return $self;
}

sub read_register_bits {
    my($self, $register, $numbytes) = @_;
    my @bytes = $self->read_register_bytes($register, $numbytes);
    my @bits;
    while( defined(my $byte = shift @bytes )) {
        my $checkbits = 0b00000001;
        for( my $i = 0; $i < 8; $i++ ) {
            my $val = ( $byte & $checkbits ) ? 1 : 0;
            push( @bits, $val );
            $checkbits *= 2;
        }
    }
    return @bits;
}

sub read_register_bytes {
    my($self, $register, $numbytes) = @_;
    croak(qq(Register $register is not recognised)) unless( exists($regaddress{$register}) );
    my $raddr = $regaddress{$register};
    
    my @vals = $self->device->bus_read($raddr, $numbytes);
    # Check if address bank changed
    if( $register eq 'IOCON' ) {
        my $bank = ( $vals[0] & 0b10000000 ) ? 1 : 0;
        $self->set_register_addresses($bank);
    }
    return @vals;
}

sub write_register_bits {
    my($self, $register, @bits) = @_;
    my $bitcount  = @bits;
    my $bytecount = $bitcount / 8;
    if( $bitcount % 8 ) {
        croak(qq(The number of bits $bitcount cannot be ordered into bytes));
    }
    my @bytes;
    while( $bytecount ) {
        my $byte = 0;
        for(my $i = 0; $i < 8; $i++ ) {
            $byte += ( $bits[$i] << $i );   
        }
        push(@bytes, $byte);
        $bytecount --;
    }
    $self->write_register_bytes($register,@bytes);
}

sub write_register_bytes { 
    my($self, $register, @bytes) = @_;
    croak(qq(Register $register is not recognised)) unless( exists($regaddress{$register}) );
    my $raddr = $regaddress{$register};
    my $rval = $self->device->bus_write($raddr, @bytes);
    # Check if address bank changed
    if( $register eq 'IOCON' ) {
        my $bank = ( $bytes[0] & 0b10000000 ) ? 1 : 0;
        $self->set_register_addresses($bank);
    }
    return $rval;
}

1;

__END__
