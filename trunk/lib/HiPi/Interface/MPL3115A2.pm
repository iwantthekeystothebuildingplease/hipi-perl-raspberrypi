#########################################################################################
# Package       HiPi::Interface::MPL3115A2
# Description:  Interface to MPL3115A2 precision Altimeter
# Created       Wed Mar 13 08:56:53 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::MPL3115A2;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi::Constant qw( :raspberry );
use HiPi::BCM2835::I2C qw( :i2c );

our $VERSION = '0.26';

__PACKAGE__->create_accessors( qw( address peripheral osdelay ) );

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant {
    MPL_REG_STATUS              => 0x00,
    MPL_REG_OUT_P_MSB           => 0x01,
    MPL_REG_OUT_P_CSB           => 0x02,
    MPL_REG_OUT_P_LSB           => 0x03,
    MPL_REG_OUT_T_MSB           => 0x04,
    MPL_REG_OUT_T_LSB           => 0x05,
    MPL_REG_DR_STATUS           => 0x06,
    MPL_REG_OUT_P_DELTA_MSB     => 0x07,
    MPL_REG_OUT_P_DELTA_CSB     => 0x08,
    MPL_REG_OUT_P_DELTA_LSB     => 0x09,
    MPL_REG_OUT_T_DELTA_MSB     => 0x0A,
    MPL_REG_OUT_T_DELTA_LSB     => 0x0B,
    MPL_REG_WHO_AM_I            => 0x0C,
    MPL_REG_F_STATUS            => 0x0D,
    MPL_REG_F_DATA              => 0x0E,
    MPL_REG_F_SETUP             => 0x0F,
    MPL_REG_TIME_DLY            => 0x10,
    MPL_REG_SYSMOD              => 0x11,
    MPL_REG_INT_SOURCE          => 0x12,
    MPL_REG_PT_DATA_CFG         => 0x13,
    MPL_REG_BAR_IN_MSB          => 0x14,
    MPL_REG_MAR_IN_LSB          => 0x15,
    MPL_REG_P_TGT_MSB           => 0x16,
    MPL_REG_P_TGT_LSB           => 0x17,
    MPL_REG_T_TGT               => 0x18,
    MPL_REG_P_WND_MSB           => 0x19,
    MPL_REG_P_WND_LSB           => 0x1A,
    MPL_REG_T_WND               => 0x1B,
    MPL_REG_P_MIN_MSB           => 0x1C,
    MPL_REG_P_MIN_CSB           => 0x1D,
    MPL_REG_P_MIN_LSB           => 0x1E,
    MPL_REG_T_MIN_MSB           => 0x1F,
    MPL_REG_T_MIN_LSB           => 0x20,
    MPL_REG_P_MAX_MSB           => 0x21,
    MPL_REG_P_MAX_CSB           => 0x22,
    MPL_REG_P_MAX_LSB           => 0x23,
    MPL_REG_T_MAX_MSB           => 0x24,
    MPL_REG_T_MAX_LSB           => 0x25,
    MPL_REG_CTRL_REG1           => 0x26,
    MPL_REG_CTRL_REG2           => 0x27,
    MPL_REG_CTRL_REG3           => 0x28,
    MPL_REG_CTRL_REG4           => 0x29,
    MPL_REG_CTRL_REG5           => 0x2A,
    MPL_REG_OFF_P               => 0x2B,
    MPL_REG_OFF_T               => 0x2C,
    MPL_REG_OFF_H               => 0x2D,
    
    MPL_CTRL_REG1_SBYB          => 0x01,
    MPL_CTRL_REG1_OST           => 0x02,
    MPL_CTRL_REG1_RST           => 0x04,
    MPL_CTRL_REG1_OS0           => 0x08,
    MPL_CTRL_REG1_OS1           => 0x10,
    MPL_CTRL_REG1_OS2           => 0x20,
    MPL_CTRL_REG1_RAW           => 0x40,
    MPL_CTRL_REG1_ALT           => 0x80,
    
    MPL_CTRL_REG1_MASK          => 0xFF,
    
    MPL_CTRL_REG2_ST0           => 0x01,
    MPL_CTRL_REG2_ST1           => 0x02,
    MPL_CTRL_REG2_ST2           => 0x04,
    MPL_CTRL_REG2_ST3           => 0x08,
    MPL_CTRL_REG2_ALARM_SEL     => 0x10,
    MPL_CTRL_REG2_LOAD_OUTPUT   => 0x20,
    
    MPL_CTRL_REG2_MASK          => 0x3F,
    
    MPL_CTRL_REG3_PP_0D2        => 0x01,
    MPL_CTRL_REG3_IPOL2         => 0x02,
    MPL_CTRL_REG3_PP_OD1        => 0x10,
    MPL_CTRL_REG3_IPOL1         => 0x20,
  
    MPL_CTRL_REG3_MASK          => 0x33,
    
    MPL_CTRL_REG4_INT_EN_DRDY   => 0x80,
    MPL_CTRL_REG4_INT_EN_FIFO   => 0x40,
    MPL_CTRL_REG4_INT_EN_PW     => 0x20,
    MPL_CTRL_REG4_INT_EN_TW     => 0x10,
    MPL_CTRL_REG4_INT_EN_PTH    => 0x08,
    MPL_CTRL_REG4_INT_EN_TTH    => 0x04,
    MPL_CTRL_REG4_INT_EN_PCHG   => 0x02,
    MPL_CTRL_REG4_INT_EN_TCHG   => 0x01,
    
    MPL_CTRL_REG4_MASK          => 0xFF,
    
    MPL_INTREGS_DRDY  => 0x80,
    MPL_INTREGS_FIFO  => 0x40,
    MPL_INTREGS_PW    => 0x20,
    MPL_INTREGS_TW    => 0x10,
    MPL_INTREGS_PTH   => 0x08,
    MPL_INTREGS_TTH   => 0x04,
    MPL_INTREGS_PCHG  => 0x02,
    MPL_INTREGS_TCHG  => 0x01,
    
    MPL_INTREGS_MASK          => 0xFF,
    
    MPL_DR_STATUS_PTOW          => 0x80,
    MPL_DR_STATUS_POW           => 0x40,
    MPL_DR_STATUS_TOW           => 0x20,
    MPL_DR_STATUS_PTDR          => 0x08,
    MPL_DR_STATUS_PDR           => 0x04,
    MPL_DR_STATUS_TDR           => 0x02,
    
    MPL_DR_STATUS_MASK          => 0xEE,
    
    MPL_F_STATUS_F_OVF          => 0x80,
    MPL_F_STATUS_F_WMRK_FLAG    => 0x40,
    MPL_F_STATUS_F_CNT5         => 0x20,
    MPL_F_STATUS_F_CNT4         => 0x10,
    MPL_F_STATUS_F_CNT3         => 0x08,
    MPL_F_STATUS_F_CNT2         => 0x04,
    MPL_F_STATUS_F_CNT1         => 0x02,
    MPL_F_STATUS_F_CNT0         => 0x01,
    
    MPL_F_STATUS_MASK           => 0xFF,
    
    MPL_PT_DATA_CFG_DREM        => 0x04,
    MPL_PT_DATA_CFG_PDEFE       => 0x02,
    MPL_PT_DATA_CFG_TDEFE       => 0x01,
    
    MPL_PT_DATA_CFG_MASK        => 0x07,
    
    MPL_BIT_SBYB          => 0,
    MPL_BIT_OST           => 1,
    MPL_BIT_RST           => 2,
    MPL_BIT_OS0           => 3,
    MPL_BIT_OS1           => 4,
    MPL_BIT_OS2           => 5,
    MPL_BIT_RAW           => 6,
    MPL_BIT_ALT           => 7,
    
    MPL_BIT_ST0           => 0,
    MPL_BIT_ST1           => 1,
    MPL_BIT_ST2           => 2,
    MPL_BIT_ST3           => 3,
    MPL_BIT_ALARM_SEL     => 4,
    MPL_BIT_LOAD_OUTPUT   => 5,
    
    MPL_BIT_PP_0D2        => 0,
    MPL_BIT_IPOL2         => 1,
    MPL_BIT_PP_OD1        => 4,
    MPL_BIT_IPOL1         => 5,
    
    # interrupt bits for CTRL_REG5,
    # INT_SOURCE
    
    MPL_BIT_DRDY          => 7,
    MPL_BIT_FIFO          => 6,
    MPL_BIT_PW            => 5,
    MPL_BIT_TW            => 4,
    MPL_BIT_PTH           => 3,
    MPL_BIT_TTH           => 2,
    MPL_BIT_PCHG          => 1,
    MPL_BIT_TCHG          => 0,
    
    MPL_BIT_PTOW          => 7,
    MPL_BIT_POW           => 6,
    MPL_BIT_TOW           => 5,
    MPL_BIT_PTDR          => 3,
    MPL_BIT_PDR           => 2,
    MPL_BIT_TDR           => 1,
    
    MPL_BIT_F_OVF        => 7,
    MPL_BIT_F_WMRK_FLAG  => 6,
    MPL_BIT_F_CNT5       => 5,
    MPL_BIT_F_CNT4       => 4,
    MPL_BIT_F_CNT3       => 3,
    MPL_BIT_F_CNT2       => 2,
    MPL_BIT_F_CNT1       => 1,
    MPL_BIT_F_CNT0       => 0,
    
    MPL_BIT_DREM         => 2,
    MPL_BIT_PDEFE        => 1,
    MPL_BIT_TDEFE        => 0,
    
    
    MPL_OSREAD_DELAY     => 1060, # left for compatibility with code that uses it.
                                  
    MPL_FUNC_ALTITUDE    => 1,
    MPL_FUNC_PRESSURE    => 2,
    MPL3115A2_ID         => 0xC4,
    
    
    MPL_CONTROL_MASK     => 0b00111000, #128 oversampling
    MPL_BYTE_MASK        => 0xFF,
    MPL_WORD_MASK        => 0xFFFF,
    
    MPL_OVERSAMPLE_1     => 0b00000000,
    MPL_OVERSAMPLE_2     => 0b00001000,
    MPL_OVERSAMPLE_4     => 0b00010000,
    MPL_OVERSAMPLE_8     => 0b00011000,
    MPL_OVERSAMPLE_16    => 0b00100000,
    MPL_OVERSAMPLE_32    => 0b00101000,
    MPL_OVERSAMPLE_64    => 0b00110000,
    MPL_OVERSAMPLE_128   => 0b00111000,
    
    MPL_OVERSAMPLE_MASK  => 0b00111000,
    
};

{
    my @const = qw(
        MPL_REG_STATUS 
        MPL_REG_OUT_P_MSB  
        MPL_REG_OUT_P_CSB 
        MPL_REG_OUT_P_LSB 
        MPL_REG_OUT_T_MSB 
        MPL_REG_OUT_T_LSB 
        MPL_REG_DR_STATUS  
        MPL_REG_OUT_P_DELTA_MSB 
        MPL_REG_OUT_P_DELTA_CSB 
        MPL_REG_OUT_P_DELTA_LSB 
        MPL_REG_OUT_T_DELTA_MSB 
        MPL_REG_OUT_T_DELTA_LSB 
        MPL_REG_WHO_AM_I        
        MPL_REG_F_STATUS             
        MPL_REG_F_DATA               
        MPL_REG_F_SETUP              
        MPL_REG_TIME_DLY             
        MPL_REG_SYSMOD               
        MPL_REG_INT_SOURCE           
        MPL_REG_PT_DATA_CFG          
        MPL_REG_BAR_IN_MSB           
        MPL_REG_MAR_IN_LSB           
        MPL_REG_P_TGT_MSB            
        MPL_REG_P_TGT_LSB            
        MPL_REG_T_TGT                
        MPL_REG_P_WND_MSB            
        MPL_REG_P_WND_LSB            
        MPL_REG_T_WND                
        MPL_REG_P_MIN_MSB            
        MPL_REG_P_MIN_CSB            
        MPL_REG_P_MIN_LSB            
        MPL_REG_T_MIN_MSB            
        MPL_REG_T_MIN_LSB            
        MPL_REG_P_MAX_MSB            
        MPL_REG_P_MAX_CSB            
        MPL_REG_P_MAX_LSB            
        MPL_REG_T_MAX_MSB            
        MPL_REG_T_MAX_LSB            
        MPL_REG_CTRL_REG1            
        MPL_REG_CTRL_REG2            
        MPL_REG_CTRL_REG3            
        MPL_REG_CTRL_REG4            
        MPL_REG_CTRL_REG5            
        MPL_REG_OFF_P                
        MPL_REG_OFF_T                
        MPL_REG_OFF_H                
        
        MPL_CTRL_REG1_SBYB           
        MPL_CTRL_REG1_OST            
        MPL_CTRL_REG1_RST            
        MPL_CTRL_REG1_OS0            
        MPL_CTRL_REG1_OS1            
        MPL_CTRL_REG1_OS2            
        MPL_CTRL_REG1_RAW            
        MPL_CTRL_REG1_ALT            
        
        MPL_CTRL_REG1_MASK           
        
        MPL_CTRL_REG2_ST0            
        MPL_CTRL_REG2_ST1            
        MPL_CTRL_REG2_ST2            
        MPL_CTRL_REG2_ST3            
        MPL_CTRL_REG2_ALARM_SEL      
        MPL_CTRL_REG2_LOAD_OUTPUT    
        
        MPL_CTRL_REG2_MASK           
        
        MPL_CTRL_REG3_PP_0D2         
        MPL_CTRL_REG3_IPOL2          
        MPL_CTRL_REG3_PP_OD1         
        MPL_CTRL_REG3_IPOL1          
      
        MPL_CTRL_REG3_MASK           
        
        MPL_CTRL_REG4_INT_EN_DRDY    
        MPL_CTRL_REG4_INT_EN_FIFO    
        MPL_CTRL_REG4_INT_EN_PW      
        MPL_CTRL_REG4_INT_EN_TW      
        MPL_CTRL_REG4_INT_EN_PTH     
        MPL_CTRL_REG4_INT_EN_TTH     
        MPL_CTRL_REG4_INT_EN_PCHG    
        MPL_CTRL_REG4_INT_EN_TCHG    
        
        MPL_CTRL_REG4_MASK           
        
        MPL_INTREGS_DRDY   
        MPL_INTREGS_FIFO   
        MPL_INTREGS_PW     
        MPL_INTREGS_TW     
        MPL_INTREGS_PTH    
        MPL_INTREGS_TTH    
        MPL_INTREGS_PCHG   
        MPL_INTREGS_TCHG   
        
        MPL_INTREGS_MASK           
        
        MPL_DR_STATUS_PTOW           
        MPL_DR_STATUS_POW            
        MPL_DR_STATUS_TOW            
        MPL_DR_STATUS_PTDR           
        MPL_DR_STATUS_PDR            
        MPL_DR_STATUS_TDR            
        
        MPL_DR_STATUS_MASK           
        
        MPL_F_STATUS_F_OVF           
        MPL_F_STATUS_F_WMRK_FLAG     
        MPL_F_STATUS_F_CNT5          
        MPL_F_STATUS_F_CNT4          
        MPL_F_STATUS_F_CNT3          
        MPL_F_STATUS_F_CNT2          
        MPL_F_STATUS_F_CNT1          
        MPL_F_STATUS_F_CNT0          
        
        MPL_F_STATUS_MASK            
        
        MPL_PT_DATA_CFG_DREM         
        MPL_PT_DATA_CFG_PDEFE        
        MPL_PT_DATA_CFG_TDEFE        
        
        MPL_PT_DATA_CFG_MASK
        
        MPL_OSREAD_DELAY
        MPL_FUNC_ALTITUDE
        MPL_FUNC_PRESSURE
        MPL3115A2_ID
    
        MPL_CONTROL_MASK
        MPL_BYTE_MASK
        MPL_WORD_MASK
        
        MPL_OVERSAMPLE_1 
        MPL_OVERSAMPLE_2
        MPL_OVERSAMPLE_4 
        MPL_OVERSAMPLE_8 
        MPL_OVERSAMPLE_16 
        MPL_OVERSAMPLE_32
        MPL_OVERSAMPLE_64 
        MPL_OVERSAMPLE_128
        
        MPL_OVERSAMPLE_MASK
    );
    push @EXPORT_OK, @const;

}

sub new {
    my ($class, %userparams) = @_;
    my %params = (
        peripheral  => ( RPI_BOARD_REVISION == 1 ) ? BB_I2C_PERI_0 : BB_I2C_PERI_1,
        address     => 0x60,
        device      => undef,
        osdelay     => MPL_OSREAD_DELAY,
        
        _function_mode => 'hipi',
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        require HiPi::BCM2835::I2C;
        $params{device} = HiPi::BCM2835::I2C->new(
            peripheral  => $params{peripheral},
            address     => $params{address},
            _function_mode  => $params{_function_mode},
        );
    }
    
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub unpack_altitude {
    my( $self, $msb, $csb, $lsb ) =@_;
    my $alt = $msb << 8;
    $alt += $csb;
    if( $msb > 127 ) {
        $alt = 0xFFFF &~$alt;
        $alt ++;
        $alt *= -1;
    }
    $alt += 0.5    if( $lsb & 0b10000000 );
    $alt += 0.25   if( $lsb & 0b01000000 );
    $alt += 0.125  if( $lsb & 0b00100000 );
    $alt += 0.0625 if( $lsb & 0b00010000 );
    return $alt;
}

sub pack_altitude {
    my($self, $alt) = @_;
    my $mint = int( $alt );
    my $lsb =  0b1111 & int(0.5 + ( 15.0 * (abs($alt) - abs($mint))));
    $lsb <<= 4;
    
    if( $alt < 0 ) {
        $mint *= -1;
        $mint --;
        $mint = 0xFFFF &~$mint;
    }
    
    my $msb = $mint >> 8;
    my $csb = $mint & 0xFF;
    return($msb, $csb, $lsb);
}

sub unpack_temperature {
    my( $self, $msb, $lsb ) =@_;
    if( $msb > 127 ) {
        $msb = 0xFFFF &~$msb;
        $msb ++;
        $msb *= -1;
    }
    $msb += 0.5    if( $lsb & 0b10000000 );
    $msb += 0.25   if( $lsb & 0b01000000 );
    $msb += 0.125  if( $lsb & 0b00100000 );
    $msb += 0.0625 if( $lsb & 0b00010000 );
    return $msb;
}

sub pack_temperature {
    my($self, $temp) = @_;
    my $mint = int( $temp );
    my $lsb =  0b1111 & int(0.495 + ( 15.0 * (abs($temp) - abs($mint))));
    $lsb <<= 4;
    if( $temp < 0 ) {
        $mint *= -1;
        $mint --;
        $mint = 0xFF &~$mint;
    }
    my $msb = $mint & 0xFF;
    return($msb, $lsb);
}

sub unpack_pressure {
    my( $self, $msb, $csb, $lsb ) =@_;
    my $alt = $msb << 10;
    $alt += $csb << 2;
    $alt += 0b11 & ( $lsb >> 6 );
    $alt += 0.5  if( $lsb & 0b00100000 );
    $alt += 0.25 if( $lsb & 0b00010000 );
    return $alt;
}

sub pack_pressure {
    my($self, $alt) = @_;
    my $mint = int( $alt );
    my $lsb =  0b1111 & int(0.495 + ( 3.0 * (abs($alt) - abs($mint))));
    $lsb <<= 4;
    my $msb = $mint & 0x3FC00;
    $msb >>= 10;
    my $csb = $mint & 0x3FC;
    $csb >>= 2;
    my $extra = $mint & 0x03;
    $lsb += ($extra << 6);
    return($msb, $csb, $lsb);
}

sub sysmod {
    my $self = shift;
    ( $self->device->i2c_read_register_rs(MPL_REG_SYSMOD, 1))[0];
}

sub who_am_i {
    my $self = shift;
    ( $self->device->i2c_read_register_rs(MPL_REG_WHO_AM_I, 1))[0];
}

sub active {
    my ($self, $set) = @_;
    my ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
    my $rval = $curreg & MPL_CTRL_REG1_SBYB;
    if (defined($set)) {
        my $setmask = ( $set ) ? MPL_CTRL_REG1_SBYB | $curreg : $curreg &~MPL_CTRL_REG1_SBYB;
        $self->device->i2c_write(MPL_REG_CTRL_REG1, $setmask);
        $rval = $setmask & MPL_CTRL_REG1_SBYB;
    }
    return $rval;
}

sub reboot {
    my $self = shift;
    $self->device->i2c_write_error(MPL_REG_CTRL_REG1, MPL_CTRL_REG1_RST);
    $self->device->delay(100);
}


sub oversample {
    my($self, $newval) = @_;
    my ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
    my $currentval = $curreg & MPL_OVERSAMPLE_MASK;
    if(defined($newval)) {
        $newval &= MPL_OVERSAMPLE_MASK;
        unless( $currentval == $newval ) {
            if( $curreg & MPL_CTRL_REG1_SBYB ) {
                croak('cannot set oversample rate while system is active');
            }
            $self->device->i2c_write(MPL_REG_CTRL_REG1, $curreg | $newval );
            ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
            $currentval = $curreg & MPL_OVERSAMPLE_MASK;
        }
    }
    return $currentval;
}

sub delay_from_oversample {
    my ($self, $oversample) = @_;
    # calculate delay needed for oversample to complete.
    # spec sheet says 60ms at oversample 1 and 1000ms at oversample 128
    # so if we range at 100ms to 1100ms and the oversample register bits
    # contain a value of 0 through 7 representing 1 to 128
    # delay = 100 + 2^$oversample * 1000/128
    $oversample >>= 3;
    return int(100.5 + 2**$oversample * 1000/128);
}

sub raw {
    my($self, $newval) = @_;
    my ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
    my $currentval = $curreg & MPL_CTRL_REG1_RAW;
    if(defined($newval)) {
        $newval &= MPL_CTRL_REG1_RAW;
        unless( $currentval == $newval ) {
            if( $curreg & MPL_CTRL_REG1_SBYB ) {
                croak('cannot set raw mode while system is active');
            }
            $self->device->i2c_write(MPL_REG_CTRL_REG1, $curreg | $newval );
            ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
            $currentval = $curreg & MPL_CTRL_REG1_RAW;
        }
    }
    return $currentval;
}

sub mode {
    my($self, $newmode) = @_;
    my ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
    my $currentmode = ( $curreg & MPL_CTRL_REG1_ALT ) ? MPL_FUNC_ALTITUDE : MPL_FUNC_PRESSURE;
    if(defined($newmode)) {
        unless( $currentmode == $newmode ) {
            if( $curreg & MPL_CTRL_REG1_SBYB ) {
                croak('cannot set altitude / pressure mode while system is active');
            }
            my $setmask = ($newmode == MPL_FUNC_ALTITUDE) ? $curreg | MPL_CTRL_REG1_ALT : $curreg &~MPL_CTRL_REG1_ALT;
            $self->device->i2c_write(MPL_REG_CTRL_REG1, $setmask );
            ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
            $currentmode = ( $curreg & MPL_CTRL_REG1_ALT ) ? MPL_FUNC_ALTITUDE : MPL_FUNC_PRESSURE;
        }
    }
    return $currentmode;
}

sub os_temperature {
    my $self = shift;
    my ( $pvalue, $tvalue ) = $self->os_any_data; 
    return  $tvalue;    
}

sub os_pressure {
    my $self = shift;
    my($pdata, $tdata) = $self->os_both_data( MPL_FUNC_PRESSURE );
    return $pdata;
}

sub os_altitude {
    my $self = shift;
    my($pdata, $tdata) = $self->os_both_data( MPL_FUNC_ALTITUDE );
    return $pdata;
}

sub os_any_data {
    my $self = shift;
    my ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
    
    my $currentmode = ( $curreg & MPL_CTRL_REG1_ALT ) ? MPL_FUNC_ALTITUDE : MPL_FUNC_PRESSURE;
    my $oversample  = ( $curreg & MPL_OVERSAMPLE_MASK );
    
    # whatever the original state of CTRL_REG1, we want to restore it with
    # one shot bit cleared
    my $restorereg = $curreg &~MPL_CTRL_REG1_OST;
    
    my $delayms = $self->delay_from_oversample($oversample);
        
    # clear any one shot bit
    $self->device->i2c_write(MPL_REG_CTRL_REG1, $curreg &~MPL_CTRL_REG1_OST );
    # set one shot bit
    $self->device->i2c_write(MPL_REG_CTRL_REG1, $curreg | MPL_CTRL_REG1_OST );
    
    # wait before read
    $self->device->delay($delayms);
        
    # read data       
    my( $pmsb, $pcsb, $plsb, $tmsb, $tlsb)
        = $self->device->i2c_read_register_rs(MPL_REG_OUT_P_MSB, 5);
    
    # convert pressure / altitude data
    my $pdata;
    if( $currentmode == MPL_FUNC_ALTITUDE ) {
        $pdata = $self->unpack_altitude( $pmsb, $pcsb, $plsb );
    } else {
        $pdata = $self->unpack_pressure( $pmsb, $pcsb, $plsb );
    }
    
    # convert temperature data
    my $tdata = $self->unpack_temperature( $tmsb, $tlsb );
    
    # restore REG1 clearing any one shot bit
    $self->device->i2c_write(MPL_REG_CTRL_REG1, $restorereg );
    
    # return both
    return ( $pdata, $tdata );    
}

sub os_both_data {
    my($self, $function) = @_;
    $function //= MPL_FUNC_PRESSURE; # default it not defined
    
    my ( $curreg ) = $self->device->i2c_read_register_rs(MPL_REG_CTRL_REG1, 1);
    
    my $currentmode   = ( $curreg & MPL_CTRL_REG1_ALT ) ? MPL_FUNC_ALTITUDE : MPL_FUNC_PRESSURE;
    my $currentactive = $curreg & 0x01;
    
    # we can't change datamodes if system is currently active
    if($currentactive && ( $currentmode !=  $function )) {
        croak('cannot switch between pressure and altitude modes when system is active');
    }
    
    my $ctrlmask = ( $function == MPL_FUNC_ALTITUDE )
        ? $curreg | MPL_CTRL_REG1_ALT
        : $curreg &~MPL_CTRL_REG1_ALT;
    
    $self->device->i2c_write(MPL_REG_CTRL_REG1, $ctrlmask );
    $self->os_any_data;
}

sub os_all_data {
    my($self ) = @_;
    
    my( $altitude, $discard ) = $self->os_both_data( MPL_FUNC_ALTITUDE );
    my( $pressure, $tempert ) = $self->os_both_data( MPL_FUNC_PRESSURE );
    
    return ( $altitude, $pressure, $tempert );    
}


1;
