#########################################################################################
# Package       HiPi::Device::I2C
# Description:  Wrapper for I2C communucation
# Created       Fri Nov 23 13:55:49 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Device::I2C;

#########################################################################################

use strict;
use warnings;
use HiPi;
use parent qw( HiPi::Device );
use IO::File;
use Fcntl;
use XSLoader;
use Carp;
use Time::HiRes qw( usleep );
use HiPi::Constant qw( :raspberry );
use HiPi::Utils qw( is_raspberry );
use Try::Tiny;

our $VERSION ='0.33';

__PACKAGE__->create_accessors( qw ( fh fno address i2cbuffer busmode ) );

XSLoader::load('HiPi::Device::I2C', $VERSION) if is_raspberry;

our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub _register_exported_constants {
    my( $tag, @constants ) = @_;
    $EXPORT_TAGS{$tag} = \@constants;
    push( @EXPORT_OK, @constants);
}

use constant {
    I2C_RETRIES     => 0x0701,
    I2C_TIMEOUT     => 0x0702,
    I2C_SLAVE       => 0x0703,
    I2C_TENBIT      => 0x0704,
    I2C_FUNCS       => 0x0705,
    I2C_SLAVE_FORCE => 0x0706,
    I2C_RDWR        => 0x0707,
    I2C_PEC         => 0x0708,
    I2C_SMBUS       => 0x0720,
    
    I2C_DEFAULT_BAUD => 100000,
    
    I2C_M_TEN          => 0x0010,
    I2C_M_RD		   => 0x0001,
    I2C_M_NOSTART	   => 0x4000,
    I2C_M_REV_DIR_ADDR => 0x2000,
    I2C_M_IGNORE_NAK   => 0x1000,
    I2C_M_NO_RD_ACK	   => 0x0800,
    I2C_M_RECV_LEN	   => 0x0400,

};

_register_exported_constants qw(
    ioctl
    I2C_RETRIES
    I2C_TIMEOUT
    I2C_SLAVE
    I2C_SLAVE_FORCE
    I2C_TENBIT
    I2C_FUNCS
    I2C_RDWR
    I2C_PEC
    I2C_SMBUS
    I2C_DEFAULT_BAUD
    
    I2C_M_TEN 
    I2C_M_RD
    I2C_M_NOSTART
    I2C_M_REV_DIR_ADDR
    I2C_M_IGNORE_NAK 
    I2C_M_NO_RD_ACK	
    I2C_M_RECV_LEN
    
);


our @_moduleinfo = (
    { name => 'i2c_bcm2708', params => { baudrate => 100000 }, },
    { name => 'i2c_dev',     params => {}, },
);


sub get_module_info {
    return @_moduleinfo;
}

{
    my $discard = __PACKAGE__->get_baudrate();
}

sub get_baudrate {
    my $class = shift;
    my $baudrate = HiPi::qx_sudo_shell('/bin/cat /sys/module/i2c_bcm2708/parameters/baudrate 2>&1');
    if($?) {
        return $_moduleinfo[0]->{params}->{baudrate};
    }
    chomp($baudrate);
    $_moduleinfo[0]->{params}->{baudrate} = $baudrate;
    return $baudrate;
}

sub set_baudrate {
    my ($class, $newrate) = @_;
    croak('Usage HiPi::Device::I2C->set_baudrate( $baudrate )') if ( defined($newrate) && ref($newrate) );
    $newrate ||= 3816;
    $newrate = 3816 if $newrate < 3816;
    $_moduleinfo[0]->{params}->{baudrate} = $newrate;
    $class->load_modules(1);
}

sub get_device_list {
    # get the devicelist
    opendir my $dh, '/dev' or croak qq(Failed to open dev : $!);
    my @i2cdevs = grep { $_ =~ /^i2c-\d+$/ } readdir $dh;
    closedir($dh);
    
    for (my $i = 0; $i < @i2cdevs; $i++) {
        $i2cdevs[$i] = '/dev/' . $i2cdevs[$i];
    }
    return @i2cdevs;
}

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        devicename   => ( RPI_BOARD_REVISION == 1 ) ? '/dev/i2c-0' : '/dev/i2c-1',
        address      => 0,
        fh           => undef,
        fno          => undef,
        i2cbuffer    => [],
        busmode      => 'smbus',
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }

    my $fh = IO::File->new( $params{devicename}, O_RDWR, 0 ) or croak qq(open error on $params{devicename}: $!\n);
    
    $params{fh}  = $fh;
    $params{fno} = $fh->fileno(),
    
    my $self = $class->SUPER::new(%params);
    
    # select address if id provided
    $self->_do_select_address( $self->address ) if $self->address;

    return $self;
}

sub close {
    my $self = shift;
    if( $self->fh ) {
        $self->fh->flush;
        $self->fh->close;
        $self->fh( undef );
        $self->fno( undef );
        $self->address( undef );
    }
}

sub select_address {
    my ($self, $address) = @_;
    if( $address != $self->address ) {
        $self->_do_select_address($address);
    }
    return $self->address;
}

sub _do_select_address {
    my ($self, $address) = @_;
    if( $self->ioctl( I2C_SLAVE, $address + 0 ) ) {
        $self->address( $address );
    } else {
        croak(qq(Failed to activate address $address : $!));
    }
}

sub ioctl {
    my ($self, $ioctlconst, $data) = @_;
    $self->fh->ioctl( $ioctlconst, $data );
}

#-------------------------------------------
# Methods that honour busmode (smbus or i2c)
#-------------------------------------------

sub bus_write {
    my ( $self, @bytes ) = @_;
    if( $self->busmode eq 'smbus' ) {
        return $self->smbus_write( @bytes );
    } else {
        return $self->i2c_write( @bytes );
    }
}

sub bus_write_error {
    my ( $self, @bytes ) = @_;
    if( $self->busmode eq 'smbus' ) {
        return $self->smbus_write_error( @bytes );
    } else {
        return $self->i2c_write_error( @bytes );
    }
}

sub bus_read {
    my ($self, $cmdval, $numbytes) = @_;
    if( $self->busmode eq 'smbus' ) {
        return $self->smbus_read( $cmdval, $numbytes );
    } else {
        return $self->i2c_read_register($cmdval, $numbytes );
    }
}

sub bus_read_bits {
    my($self, $regaddr, $numbytes) = @_;
    $numbytes ||= 1;
    my @bytes = $self->bus_read($regaddr, $numbytes);
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

sub bus_write_bits {
    my($self, $register, @bits) = @_;
    my $bitcount  = @bits;
    my $bytecount = $bitcount / 8;
    if( $bitcount % 8 ) { croak(qq(The number of bits $bitcount cannot be ordered into bytes)); }
    my @bytes;
    while( $bytecount ) {
        my $byte = 0;
        for(my $i = 0; $i < 8; $i++ ) {
            $byte += ( $bits[$i] << $i );   
        }
        push(@bytes, $byte);
        $bytecount --;
    }
    $self->bus_write($register, @bytes);
}

#-------------------------------------------
# I2C interface
#-------------------------------------------
    
sub i2c_write {
    my( $self, @bytes ) = @_;
    my $buffer = pack('C*', @bytes, '0');
    my $len = @bytes;
    my $result = _i2c_write($self->fno, $self->address, $buffer, $len );
    croak qq(i2c_write failed with return value $result) if $result;
}

sub i2c_write_error {
    my( $self, @bytes ) = @_;
    my $buffer = pack('C*', @bytes, '0');
    my $len = @bytes;
    _i2c_write($self->fno, $self->address, $buffer, $len );
}

sub i2c_read {
    my($self, $numbytes) = @_;
    $numbytes ||= 1;
    my $buffer = '0' x ( $numbytes + 1 );
    my $result = _i2c_read($self->fno, $self->address, $buffer, $numbytes );
    croak qq(i2c_read failed with return value $result) if $result;
    my $template = ( $numbytes > 1 ) ? 'C' . $numbytes : 'C';
    my @vals = unpack($template, $buffer );
    return @vals;
}

sub i2c_read_register {
    my($self, $register, $numbytes) = @_;
    $numbytes ||= 1;
    my $rbuffer = '0' x ( $numbytes + 1 );
    my $wbuffer = pack('C', $register);
    my $result = _i2c_read_register($self->fno, $self->address, $wbuffer, $rbuffer, $numbytes );
    croak qq(i2c_read_register failed with return value $result) if $result;
    my $template = ( $numbytes > 1 ) ? 'C' . $numbytes : 'C';
    my @vals = unpack($template, $rbuffer );
    return @vals;
}

#-------------------------------------------
# SMBus interface
#-------------------------------------------

sub smbus_write {
    my ($self, @bytes) = @_;
    if( @bytes == 1) {
        $self->smbus_write_byte($bytes[0]);
    } elsif( @bytes == 2) {
        $self->smbus_write_byte_data( @bytes );
    } else {
        my $command = shift @bytes;
        $self->smbus_write_i2c_block_data($command, \@bytes );
    }
}

sub smbus_write_error {
    my ($self, @bytes) = @_;
    # we allow errors - so catch auto generated error
    try {
        if( @bytes == 1) {
            $self->smbus_write_byte($bytes[0]);
        } elsif( @bytes == 2) {
            $self->smbus_write_byte_data( @bytes );
        } else {
            my $command = shift @bytes;
            $self->smbus_write_i2c_block_data($command, \@bytes );
        }
    };
}

sub smbus_read {
    my ($self, $cmdval, $numbytes) = @_;
    if(!defined($cmdval)) {
        return $self->smbus_read_byte;
    } elsif(!$numbytes || $numbytes <= 1 ) {
        return $self->smbus_read_byte_data( $cmdval );
    } else {
        return $self->smbus_read_i2c_block_data($cmdval, $numbytes );
    }
}

sub smbus_write_quick {
    my($self, $command ) = @_;
    my $result = i2c_smbus_write_quick($self->fno, $command);
    croak qq(smbus_write_quick failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_byte {
    my( $self ) = @_;
    my $result = i2c_smbus_read_byte( $self->fno );
    croak qq(smbus_read_byte failed with return value $result) if $result < 0;
    return ( $result );
}

sub smbus_write_byte {
    my($self, $command) = @_;
    my $result = i2c_smbus_write_byte($self->fno, $command);
    croak qq(smbus_write_byte failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_byte_data {
    my($self, $command) = @_;
    my $result = i2c_smbus_read_byte_data($self->fno, $command);
    croak qq(smbus_read_byte_data failed with return value $result) if $result < 0;
    return ( $result );
}

sub smbus_write_byte_data {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_byte_data($self->fno,  $command, $data);
    croak qq(smbus_write_byte_data failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_word_data {
    my($self, $command) = @_;
    my $result = i2c_smbus_read_word_data($self->fno, $command);
    croak qq(smbus_read_word_data failed with return value $result) if $result < 0;
    return ( $result );
}

sub smbus_write_word_data {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_word_data($self->fno, $command, $data);
    croak qq(smbus_write_word_data failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_word_swapped {
    my($self, $command) = @_;
    my $result = i2c_smbus_read_word_swapped($self->fno, $command);
    croak qq(smbus_read_word_swapped failed with return value $result) if $result < 0;
    return ( $result );
}

sub smbus_write_word_swapped {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_word_swapped($self->fno, $command, $data);
    croak qq(smbus_write_word_swapped failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_process_call {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_process_call($self->fno, $command, $data);
    croak qq(smbus_process_call failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_read_block_data {
    my($self, $command) = @_;
    my @result = i2c_smbus_read_block_data($self->fno, $command);
    croak qq(smbus_read_block_data failed ) unless @result;
    return @result;
}

sub smbus_read_i2c_block_data {
    my($self, $command, $data) = @_;
    my @result = i2c_smbus_read_i2c_block_data($self->fno, $command, $data);
    croak qq(smbus_read_i2c_block_data failed ) unless @result;
    return @result;
}

sub smbus_write_block_data {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_block_data($self->fno, $command, $data);
    croak qq(smbus_write_block_data failed with return value $result) if $result < 0;
    return $result;
}

sub smbus_write_i2c_block_data {
    my($self, $command, $data) = @_;
    my $result = i2c_smbus_write_i2c_block_data($self->fno, $command, $data);
    croak qq(smbus_write_i2c_block_data failed with return value $result) if $result < 0;
    return $result;
}

1;

__END__
