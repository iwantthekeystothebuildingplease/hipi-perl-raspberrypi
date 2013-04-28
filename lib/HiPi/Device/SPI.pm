#########################################################################################
# Package       HiPi::Device::SPI
# Description:  Wrapper for SPI communucation
# Created       Fri Nov 23 13:55:49 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Device::SPI;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Device );
use IO::File;
use Fcntl;
use XSLoader;
use Carp;
use HiPi::Constant qw( :raspberry );
use HiPi;
use HiPi::Utils qw( is_raspberry );
use Try::Tiny;

our $VERSION ='0.33';

__PACKAGE__->create_accessors( qw ( fh fno delay speed bitsperword ) );

XSLoader::load('HiPi::Device::SPI', $VERSION) if is_raspberry;

our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub _register_exported_constants {
    my( $tag, @constants ) = @_;
    $EXPORT_TAGS{$tag} = \@constants;
    push( @EXPORT_OK, @constants);
}

use constant {
    SPI_CPHA        => 0x01,
    SPI_CPOL        => 0x02,
    SPI_MODE_0      => 0x00,
    SPI_MODE_1      => 0x01,
    SPI_MODE_2      => 0x02,
    SPI_MODE_3      => 0x03,
    SPI_CS_HIGH     => 0x04,
    SPI_LSB_FIRST   => 0x08,
    SPI_3WIRE       => 0x10,
    SPI_LOOP        => 0x20,
    SPI_NO_CS       => 0x40,
    SPI_READY       => 0x80,
    SPI_SPEED_KHZ_500 => 500000,
    SPI_SPEED_MHZ_1   => 1000000,
    SPI_SPEED_MHZ_2   => 2000000,
    SPI_SPEED_MHZ_4   => 4000000,
    SPI_SPEED_MHZ_8   => 8000000,
    SPI_SPEED_MHZ_16  => 16000000,
    SPI_SPEED_MHZ_32  => 32000000,
};

_register_exported_constants qw(
    spi
    SPI_CPHA
    SPI_CPOL 
    SPI_MODE_0 
    SPI_MODE_1
    SPI_MODE_2
    SPI_MODE_3 
    SPI_CS_HIGH
    SPI_LSB_FIRST
    SPI_3WIRE
    SPI_LOOP
    SPI_NO_CS
    SPI_READY
    SPI_SPEED_KHZ_500
    SPI_SPEED_MHZ_1
    SPI_SPEED_MHZ_2
    SPI_SPEED_MHZ_4
    SPI_SPEED_MHZ_8
    SPI_SPEED_MHZ_16
    SPI_SPEED_MHZ_32
);

our @_moduleinfo = (
    { name => 'spi_bcm2708', params => {}, },
    { name => 'spidev',      params => { bufsiz => 4096 }, },
);

sub get_module_info {
    return @_moduleinfo;
}

{
    my $discard = __PACKAGE__->get_bufsiz();
}

sub get_bufsiz {
    my $bufsiz = HiPi::qx_sudo_shell('/bin/cat /sys/module/spidev/parameters/bufsiz 2>&1');
    if( $? ) {
        return $_moduleinfo[1]->{params}->{bufsiz};
    }
    chomp($bufsiz);
    $_moduleinfo[1]->{params}->{bufsiz} = $bufsiz;
    return $bufsiz;
}

sub set_bufsiz {
    my ($class, $newsiz) = @_;
    croak('Usage HiPi::Device::SPI->set_bufsiz( $newsiz )') if ( defined($newsiz) && ref($newsiz) );
    $_moduleinfo[1]->{params}->{bufsiz} = $newsiz;
    $class->load_modules(1);
}

sub get_device_list {
    # get the devicelist
    opendir my $dh, '/dev' or croak qq(Failed to open dev : $!);
    my @spidevs = grep { $_ =~ /^spidev\d+\.\d+$/ } readdir $dh;
    closedir($dh);
    
    for (my $i = 0; $i < @spidevs; $i++) {
        $spidevs[$i] = '/dev/' . $spidevs[$i];
    }
    return @spidevs;
}

sub new {
    my ($class, %userparams) = @_;
    
    my %params = (
        devicename   => '/dev/spidev0.0',
        speed        => SPI_SPEED_MHZ_1(),
        bitsperword  => 8,
        delay        => 0,
    );
    
    foreach my $key( sort keys( %params ) ) {
        $params{$key} = $userparams{$key} if exists($userparams{$key});
    }
    
    my $fh = IO::File->new(
        $params{devicename}, O_RDWR, 0
    ) or croak qq(open error on $params{devicename}: $!\n);
    
    
    $params{fh}  = $fh;
    $params{fno} = $fh->fileno(),
     
    my $self = $class->SUPER::new(%params);
    
    return $self;
}

sub transfer {
    my($self, $buffer) = @_;
   
    my $rval = HiPi::Device::SPI::_write_read_data(
            $self->fno, $buffer, $self->delay, $self->speed, $self->bitsperword
        );
    
    if( !defined( $rval ) ) {
        croak('SPI transfer failed');
    }
    
    return $rval;
}

sub set_bus_mode {
    my($self, $mode) = @_;
    HiPi::Device::SPI::_set_spi_mode($self->fno, $mode)
}

sub set_bus_maxspeed {
    my($self, $speed) = @_;
    HiPi::Device::SPI::_set_spi_max_speed($self->fno, $speed)
}

sub close {
    my $self = shift;
    if( $self->fh ) {
        $self->fh->flush;
        $self->fh->close;
        $self->fh( undef );
        $self->fno( undef );
        $self->devicename( undef );
    }
}

1;

__END__
