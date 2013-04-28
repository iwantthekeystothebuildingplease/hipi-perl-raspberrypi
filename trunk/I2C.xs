///////////////////////////////////////////////////////////////////////////////////////
// File          i2c/I2C.xs
// Description:  XS module for MyPi::Device::I2C
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
#include "mylib/include/local-i2c-dev.h"
#include <linux/swab.h>

MODULE = HiPi::Device::I2C  PACKAGE = HiPi::Device::I2C

__s32
i2c_smbus_write_quick(file, value)
    int  file
    __u8 value
  CODE:
    RETVAL = i2c_smbus_write_quick(file, value);
    
  OUTPUT: RETVAL


__s32
i2c_smbus_read_byte( file )
    int file
  CODE:
    RETVAL = i2c_smbus_read_byte( file );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_write_byte(file, value)
    int  file
    __u8 value
  CODE:
    RETVAL = i2c_smbus_write_byte( file, value );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_read_byte_data(file, command )
    int  file
    __u8 command
  CODE:
    RETVAL = i2c_smbus_read_byte_data(file, command );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_write_byte_data( file, command, value)
    int  file
    __u8 command
    __u8 value
  CODE:
    RETVAL = i2c_smbus_write_byte_data(file, command, value );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_read_word_data(file, command)
    int  file
    __u8 command
  CODE:
    RETVAL = i2c_smbus_read_word_data(file, command );
    
  OUTPUT: RETVAL    


__s32
i2c_smbus_write_word_data( file, command, value)
    int   file
    __u8  command
    __u16 value
  CODE:
    RETVAL = i2c_smbus_write_word_data(file, command, value );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_read_word_swapped(file, command)
    int  file
    __u8 command
  CODE:
    __s32 rval = i2c_smbus_read_word_data(file, command );
    RETVAL = (rval < 0) ? rval : __swab16(rval);
    
  OUTPUT: RETVAL    


__s32
i2c_smbus_write_word_swapped( file, command, value)
    int   file
    __u8  command
    __u16 value
  CODE:
    RETVAL = i2c_smbus_write_word_data(file, command, __swab16(value) );
    
  OUTPUT: RETVAL


__s32
i2c_smbus_process_call( file, command, value )
    int   file
    __u8  command
    __u16 value
  CODE:
    RETVAL = i2c_smbus_process_call(file, command, value );
    
  OUTPUT: RETVAL
  

void
i2c_smbus_read_block_data( file, command )
    int  file
    __u8 command
  PPCODE:
    int i;
    __u8 buf[32];
    int result = i2c_smbus_read_block_data(file, command, buf);
    if (result < 0) {
        EXTEND( SP, 1 );
        PUSHs(  &PL_sv_undef );
    } else {
        EXTEND( SP, (IV)result );
        for( i = 0; i < result; ++i )
        {
            SV* var = sv_newmortal();
            sv_setuv( var, (UV)buf[i] );
            PUSHs( var );
        }
    }
    

void
i2c_smbus_read_i2c_block_data( file, command, len )
    int  file
    __u8 command
    __u8 len
  PPCODE:
    int i;
    __u8 *buffer;
    buffer = malloc(len * sizeof(__u8));
    int result = i2c_smbus_read_i2c_block_data(file, command, len, buffer);
    if (result < 0) {
        EXTEND( SP, 1 );
        PUSHs(  &PL_sv_undef );
    } else {
        EXTEND( SP, (IV)result );
        for( i = 0; i < result; ++i )
        {
            SV* var = sv_newmortal();
            sv_setuv( var, (UV)buffer[i] );
            PUSHs( var );
        }
    }
    free( buffer );
    


__s32
i2c_smbus_write_block_data( file,  command, dataarray )
    int  file
    __u8 command
    SV*  dataarray
  CODE:
    STRLEN len;
    AV*  av;
    __u8 *buffer;
    int  i;
    
    if( !SvROK( dataarray ) || ( SvTYPE( (SV*) ( av = (AV*) SvRV( dataarray ) ) ) != SVt_PVAV ) )
    {
        croak( "the data array is not an array reference" );
        return;
    }
    
    len = av_len( av ) + 1;
    
    buffer = malloc(len * sizeof(__u8));
    
    for( i = 0; i < (int)len; ++i )
        buffer[i] = (__u8)SvUV(*av_fetch( av, i, 0 ));
    
    RETVAL = i2c_smbus_write_block_data(file, command, len, buffer);
    
    free( buffer);
    
  OUTPUT: RETVAL


__s32
i2c_smbus_write_i2c_block_data( file,  command, dataarray )
    int  file
    __u8 command
    SV*  dataarray
  CODE:
    STRLEN len;
    AV*    av;
    __u8   *buffer;
    int    i;
    
    if( !SvROK( dataarray ) || ( SvTYPE( (SV*) ( av = (AV*) SvRV( dataarray ) ) ) != SVt_PVAV ) )
    {
        croak( "the data array is not an array reference" );
        return;
    }
    
    len = av_len( av ) + 1;
    
    buffer = malloc(len * sizeof(__u8));
    
    for( i = 0; i < (int)len; ++i )
        buffer[i] = (__u8)SvUV(*av_fetch( av, i, 0 ));
    
    RETVAL = i2c_smbus_write_i2c_block_data(file, command, len, buffer);
    
    free( buffer );
    
  OUTPUT: RETVAL
  
int
_i2c_write( int file, __u16 address, unsigned char *wbuf,  __u16 wlen )
  CODE:
    int ret;
    struct i2c_rdwr_ioctl_data i2c_data;
    struct i2c_msg msg[1];
    i2c_data.msgs = msg;
    i2c_data.nmsgs = 1;             // use one message structure

    i2c_data.msgs[0].addr = address;
    i2c_data.msgs[0].flags = 0;     // don't need flags
    i2c_data.msgs[0].len = wlen;
    i2c_data.msgs[0].buf = (__u8 *)wbuf;

    ret = ioctl(file, I2C_RDWR, &i2c_data);
    
    if (ret < 0) {
        RETVAL = ret;
    } else {
        RETVAL = 0;
    }
  OUTPUT: RETVAL
    

int
_i2c_read( int file, __u16 address, unsigned char *rbuf, __u16 rlen)
  CODE:
    int ret;
    struct i2c_rdwr_ioctl_data  i2c_data;
    struct i2c_msg  msg[1];
   
    i2c_data.msgs = msg;
    i2c_data.nmsgs = 1;   
    i2c_data.msgs[0].addr = address;
    i2c_data.msgs[0].flags = I2C_M_RD; 
    i2c_data.msgs[0].len = rlen;
    i2c_data.msgs[0].buf = (__u8 *)rbuf;
    
    ret = ioctl(file, I2C_RDWR, &i2c_data);
    
    if (ret < 0) {
        RETVAL = ret;
    } else {
        RETVAL = 0;
    }

    OUTPUT: RETVAL
    
int
_i2c_read_register( int file, __u16 address, unsigned char *wbuf, unsigned char *rbuf, __u16 rlen)
  CODE:
    int ret;
    struct i2c_rdwr_ioctl_data  i2c_data;
    struct i2c_msg  msg[2];
   
    i2c_data.msgs = msg;
    i2c_data.nmsgs = 2;
    
    i2c_data.msgs[0].addr = address;
    i2c_data.msgs[0].flags = 0; 
    i2c_data.msgs[0].len = 1;
    i2c_data.msgs[0].buf = (__u8 *)wbuf;
    
    i2c_data.msgs[1].addr = address;
    i2c_data.msgs[1].flags = I2C_M_RD; 
    i2c_data.msgs[1].len = rlen;
    i2c_data.msgs[1].buf = (__u8 *)rbuf;
    
    ret = ioctl(file, I2C_RDWR, &i2c_data);
    
    if (ret < 0) {
        RETVAL = ret;
    } else {
        RETVAL = 0;
    }

    OUTPUT: RETVAL
