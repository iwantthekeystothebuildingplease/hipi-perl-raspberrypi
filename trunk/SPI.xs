///////////////////////////////////////////////////////////////////////////////////////
// File          spi/SPI.xs
// Description:  XS module for HiPi::Device::SPI
// Created       Fri Nov 23 12:13:43 2012
// SVN Id        $Id:$
// Copyright:    Copyright (c) 2012 Mark Dootson
// Licence:      This work is free software; you can redistribute it and/or modify it 
//               under the terms of the GNU General Public License as published by the 
//               Free Software Foundation; either version 3 of the License, or any later 
//               version.
///////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mylib/include/ppport.h"
#include <sys/ioctl.h>
#include <linux/spi/spidev.h>

MODULE = HiPi::Device::SPI  PACKAGE = HiPi::Device::SPI

void
_write_read_data(file, inbuf, delay = 0, speed = 1000000, bitspw = 8 )
    int file
    SV* inbuf
    __u16 delay
    __u32 speed
    __u8 bitspw
  PPCODE:
    struct spi_ioc_transfer msg;
    SV* outbuf = newSVsv(inbuf);
    // for Raspberry Pi pointers are always 32 bit
    msg.tx_buf        = (__u32)SvPVX(inbuf);
    msg.rx_buf        = (__u32)SvPVX(outbuf);
    msg.len           = (__u32)SvCUR(inbuf);
    msg.speed_hz      = speed;
    msg.delay_usecs   = delay;
    msg.bits_per_word = bitspw;
    
##//  msg.cs_change:1
##//  msg.pad
    
    int ioval = ioctl (file, SPI_IOC_MESSAGE(1), &msg);
    if( ioval >= 0)
    {
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(outbuf));
    }
    else
    {
        EXTEND(SP, 1);
        PUSHs(&PL_sv_undef);
    }
  
    


int
_set_spi_max_speed(file, speed)
    int file
    __u32 speed
  CODE:
    int rval;
    rval = ioctl(file, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
    if(rval >= 0)
        rval = ioctl(file, SPI_IOC_RD_MAX_SPEED_HZ, &speed);

    if( rval < 0 )
        rval = -1;
    
    RETVAL = rval;
  OUTPUT: RETVAL


int
_set_spi_mode(file, mode)
    int file
    __u8 mode
  CODE:
    int rval;
    rval = ioctl(file, SPI_IOC_WR_MODE, &mode);
    if(rval >= 0)
        rval = ioctl(file, SPI_IOC_RD_MODE, &mode);

    if( rval < 0 )
        rval = -1;
    
    RETVAL = rval;
  OUTPUT: RETVAL


int
_set_spi_bits_per_word(file, bitspw)
    int file
    __u8 bitspw
  CODE:
    int rval;
    rval = ioctl(file, SPI_IOC_WR_BITS_PER_WORD, &bitspw);
    if(rval >= 0)
        rval = ioctl(file, SPI_IOC_RD_BITS_PER_WORD, &bitspw);

    if( rval < 0 )
        rval = -1;
    
    RETVAL = rval;
  OUTPUT: RETVAL

