#########################################################################################
# Package       HiPi::Interface::MCP49XX
# Description:  Control MCP49XX Digital to Analog Series
# Created       Sun Dec 02 01:42:27 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::MCP49XX;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use Carp;
use HiPi::Device::SPI qw( :spi );

our $VERSION = '0.20';

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub MCP_DUAL_CHANNEL  { 0x001 }
sub MCP_CAN_BUFFER    { 0x002 }
sub MCP_RESOLUTION_8  { 0x010 }
sub MCP_RESOLUTION_10 { 0x020 }
sub MCP_RESOLUTION_12 { 0x030 }

use constant {
    MCP4801 =>  0x100|MCP_RESOLUTION_8(),
    MCP4811 =>  0x200|MCP_RESOLUTION_10(),
    MCP4821 =>  0x300|MCP_RESOLUTION_12(),
    MCP4802 =>  0x400|MCP_DUAL_CHANNEL()|MCP_RESOLUTION_8(),
    MCP4812 =>  0x500|MCP_DUAL_CHANNEL()|MCP_RESOLUTION_10(),
    MCP4822 =>  0x600|MCP_DUAL_CHANNEL()|MCP_RESOLUTION_12(),
    MCP4901 =>  0x700|MCP_RESOLUTION_8()|MCP_CAN_BUFFER(),
    MCP4911 =>  0x800|MCP_RESOLUTION_10()|MCP_CAN_BUFFER(),
    MCP4921 =>  0x900|MCP_RESOLUTION_12()|MCP_CAN_BUFFER(),
    MCP4902 =>  0xA00|MCP_DUAL_CHANNEL()|MCP_RESOLUTION_8()|MCP_CAN_BUFFER(),
    MCP4912 =>  0xB00|MCP_DUAL_CHANNEL()|MCP_RESOLUTION_10()|MCP_CAN_BUFFER(),
    MCP4922 =>  0xC00|MCP_DUAL_CHANNEL()|MCP_RESOLUTION_12()|MCP_CAN_BUFFER(),
    MCP_CHANNEL_A => 0x00,
    MCP_CHANNEL_B => 0x8000,
    MCP_BUFFER    => 0x4000,
    MCP_GAIN      => 0x00,
    MCP_NO_GAIN   => 0x2000,
    MCP_LIVE      => 0x1000,
    MCP_SHUTDOWN  => 0x00,
};

{
    my @const = qw(
        MCP4801 MCP4811 MCP4821 MCP4802 MCP4812 MCP4822
        MCP4901 MCP4911 MCP4921 MCP4902 MCP4912 MCP4922
    );
    push( @EXPORT_OK, @const );
    $EXPORT_TAGS{mcp} = \@const;
}

__PACKAGE__->create_accessors( qw( bitsperword minvar type devicename
                                   dualchannel canbuffer buffer gain
                                   writemask shiftvalue shiftbits ) );

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_1,
        bitsperword  => 8,
        delay        => 0,
        device       => undef,
        type         => MCP4902(),
        buffer       => 0,
        gain         => 0,
        shiftvalue   => 0,
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
        
    {
        my $ct = $params{type};
        
        if( $ct & MCP_RESOLUTION_12() ) {
            $params{minvar} = 0;
            $params{shiftbits} = 0;
            $params{writemask} = 0b1111111111111111;
        } elsif( $ct & MCP_RESOLUTION_10() ) {
            $params{minvar} = 4;
            $params{shiftbits} = 2;
            $params{writemask} = 0b1111111111111100;
        } else {
            $params{minvar} = 16;
            $params{shiftbits} = 4;
            $params{writemask} = 0b1111111111110000;
        }
        
        if( $ct & MCP_CAN_BUFFER() ) {
            $params{canbuffer} = 1;
        } else {
            $params{canbuffer} = 0;
        }
        
         if( $ct & MCP_DUAL_CHANNEL() ) {
            $params{dualchannel} = 1;
        } else {
            $params{dualchannel} = 0;
        }
        
    }
    
    unless( defined($params{device}) ) {
        my $dev = HiPi::Device::SPI->new(
            speed        => $params{speed},
            bitsperword  => $params{bitsperword},
            delay        => $params{delay},
            devicename   => $params{devicename},
        );
        
        $params{device} = $dev;
    }
    
    my $self = $class->SUPER::new(%params);
    return $self;
}


sub write {
    my($self, $value, $channelb) = @_;
    $channelb ||= 0;
    $channelb = 0 if !$self->dualchannel;
        
    my $output = ( $channelb ) ? MCP_CHANNEL_B() : MCP_CHANNEL_A();
    $output += MCP_BUFFER() if($self->canbuffer && $self->buffer);
    $output += ( $self->gain ) ? MCP_GAIN() : MCP_NO_GAIN();
    $output += MCP_LIVE();
    
    # allow user to specify values 1-255 for 8 bit device etc
    
    if( $self->shiftvalue ) {
        $value <<= $self->shiftbits;
    }
    
    # mask the $value. If user specifies shiftvalue == true
    # and gives a value over 255 for an 8 bit device
    # confusing things will happen. We only want
    # 12 bits. If user gets it wrong then at least
    # all that happens is they get wrong voltage -
    # instead of potentially writing to wrong channel
    # or shutting the channel down if we shift a high value
    
    $value &= 0b111111111111;
    
    $value = $self->minvar if( $value > 0 && $value < $self->minvar );
    $value = 0 if $value < 0;
    # $value = 4095 if $value > 4095; - taken care of by value mask above
    
    $output += $value;
    $output &= $self->writemask;
    $self->device->transfer( $self->_fmt_val( $output ) );
}

sub _fmt_val {
    my($self, $val) = @_;
    pack('n', $val);
}

sub shutdown {
    my($self, $channelb) = @_;
    $channelb ||= 0;
    $channelb = 0 if !$self->dualchannel;
    my $output = ( $channelb ) ? MCP_CHANNEL_B() : MCP_CHANNEL_A();
    $output += MCP_SHUTDOWN();
    $self->device->transfer( $self->_fmt_val( $output ) );
}

1;

__END__
