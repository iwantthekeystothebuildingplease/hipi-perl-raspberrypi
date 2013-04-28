#!/usr/bin/perl

#########################################################################################
# Description:  Direct access to I2C functions via /dev/mem
# Created       Mon Mar 18 22:38:41 2013
# svn id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

use 5.14.0;
use strict;
use warnings;
use HiPi::BCM2835::I2C qw( :all );
use Try::Tiny;
use Carp;

our $VERSION ='0.33';

my @args = @ARGV;

# have we got args
unless ( @args ) {
    do_usage(1);
}

my $mode = shift @args;

given ( $mode ) {
    when( /^r/i ) {
        do_read(@args);
    }
    when( /^w/i ) {
        do_write(@args);
    }
    when( /^h/i ) {
        do_usage(0);
    }
    when( /^b/i ) {
        do_baud(@args);
    }
    when( /^e/i ) {
        do_enable(@args);
    }
    default {
        do_usage(1);
    }
}

sub _handle_byte_arg {
    my $inarg = shift;
    my $outarg = ( $inarg  =~ /^0/ ) ? oct($inarg) : $inarg & 0xFF;
    return $outarg;
}

sub do_enable {
    my ( $inbus, $enable ) = @_;
    my $peripheral;
    if($inbus eq '0' || $inbus eq '1' ) {
        do_usage(1) if(!defined($enable));
    } else {
        do_usage(1);
    }
    $enable = ( $enable ) ? 1 : 0;
    try {
        require HiPi::BCM2835;
        HiPi::BCM2835::bcm2835_init();
        if( $inbus eq '0' ) {
            HiPi::BCM2835::hipi_set_I2C0( $enable );
        }
        if( $inbus eq '1' ) {
            HiPi::BCM2835::hipi_set_I2C1( $enable );
        }
    } catch {
        croak(qq(enable i2c bus $inbus failed : $_));
    };
    print qq(1\n);
}

sub do_baud {
    my ( $inbus, $newrate ) = @_;
    my $peripheral;
    if($inbus eq '0') {
        $peripheral = BB_I2C_PERI_0;
    } elsif($inbus eq '1') {
        $peripheral = BB_I2C_PERI_1;
    } else {
        do_usage(1);
    }
    
    if( $newrate ) {
        ### die if we're running suid by non-root user
        ##if( $< ) {
        ##    print qq(only root user may change baudrate\n);
        ##    exit(1);
        ##}
        
        # I can't get baudrate above 1000000 working with my
        # i2c devices
        if( ($newrate < 3816) || ($newrate > 1000000) ) {
            croak('baudrate must be in the range 3816 - 1000000');
        }
        
        my $changerate = $newrate & 0x1FFFFF;
        try {
            HiPi::BCM2835::I2C->set_baudrate($peripheral, $changerate);
        } catch {
            croak(qq(set baudrate failed : $_));
        };
    }
    
    my $baudrate = try {
        HiPi::BCM2835::I2C->get_baudrate($peripheral);
    } catch {
        croak(qq(get baudrate failed : $_));
    };
    
    print $baudrate . qq(\n);
}

sub do_read {
    my ($inbus, $inaddress, $inregister, $inbytes) = @_;
    unless(defined($inbus) && defined($inaddress) && defined($inregister)) {
        do_usage(1);
    }
    $inbytes ||= 1;
    
    my($peripheral, $address, $register, $numbytes);
    
    if($inbus eq '0') {
        $peripheral = BB_I2C_PERI_0;
    } elsif($inbus eq '1') {
        $peripheral = BB_I2C_PERI_1;
    } else {
        do_usage(1);
    }
    $address  = _handle_byte_arg($inaddress);
    $register = _handle_byte_arg($inregister);
    $numbytes = _handle_byte_arg($inbytes);
    
    my @bytesout;
    
    try {
        my $dev = HiPi::BCM2835::I2C->new(
            peripheral => $peripheral,
            address    => $address
        );
        @bytesout = $dev->i2c_read_register_rs($register, $numbytes);
    } catch {
        croak(qq(read failed : $_));
    };  
    print join(' ', @bytesout) . qq(\n);
}

sub do_write {
    my ($inbus, $inaddress, $inregister, @inbytes) = @_;
    
    my($peripheral, $address, $register, @writebytes);
    
    if($inbus eq '0') {
        $peripheral = BB_I2C_PERI_0;
    } elsif($inbus eq '1') {
        $peripheral = BB_I2C_PERI_1;
    } else {
        do_usage(1);
    }
    
    $address  = _handle_byte_arg($inaddress);
    $register = _handle_byte_arg($inregister);
        
    push @writebytes, $register;
    for my $byte ( @inbytes ) {
        $byte = _handle_byte_arg($byte);
        push @writebytes, $byte;
    }
    try {
        my $dev = HiPi::BCM2835::I2C->new(
            peripheral => $peripheral,
            address    => $address
        );
        $dev->i2c_write(@writebytes);
    } catch {
        croak(qq(write failed : $_));
    };
    my $bytes = scalar @writebytes;
    print $bytes . qq(\n);
}

sub do_usage {
    my $exit = shift;
    my $usage = q(
usage : hipi-i2c MODE I2C [ADDRESS] [REGISTER] [BAUDRATE] [ARG1 ARG2 ARG3]
    
    MODE     = w[rite] | r[read] | h[elp] | b[aud] | e[nable]
    I2C      = 0 | 1   The i2c perphipheral to use
    ADDRESS  = The device address on the i2c bus when mode r|w
    REGISTER = The register on the device you wish
               to write to / read from when mode r|w
    BAUDRATE = Baudrate for I2C ( only root may change baudrate);
    ARG1,2,n = additional arguments
    Examples:
      We have a device at address 0x3A on the I2C-1
      peripheral. (default for Model B Revision 2.0
      and Model A boards.)
      
      write one byte (0xFF) to register 0x02
        hipi-i2c w 1 0x3A 0x02 0xFF
        
      write just the register address (0x02) to the
      device
        hipi-i2c w 1 0x3A 0x02
        
      write 3 bytes (0xFF, 0xFE, 0x11) to register 0x02
        hipi-i2c w 1 0x3A 0x02 0xFF 0xFE 0x11
        
      read 1 byte starting at register 0x09
        hipi-i2c r 1 0x3A 0x09 1
        
      read 24 bytes starting at register 0x09
        hipi-i2c r 1 0x3A 0x09 24
      
      set baudrate to 400000 on I2C peripheral 1
        sudo hipi-i2c b 1 400000
        
      get current baudrate on I2C peripheral 1
        hipi-i2c b 1
      
      enable i2c bus 1
        hipi-i2c e 1 1
      
      enable i2c bus 0
        hipi-i2c e 0 1
    
      disable i2c bus 0
        hipi-i2c e 0 0
      
);
    say $usage;
    exit($exit);
}





1;
