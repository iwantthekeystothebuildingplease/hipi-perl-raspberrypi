#########################################################################################
# Package       HiPi::Device::OneWire
# Description:  One Wire Device
# Created       Sun Feb 10 02:31:12 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Device::OneWire;

#########################################################################################

use strict;
use warnings;
use Carp;
use HiPi;
use parent qw( HiPi::Device );

our $VERSION = '0.21';

our %idmap = (
    '01' => [ '2401/11', 'silicon serial number'], 
    '02' => [ '1425', 'multikey 1153bit secure'], 
    '04' => [ '2404', 'econoram time chip'], 
    '05' => [ '2405', 'Addressable Switch'], 
    '06' => [ '', '4k memory ibutton'], 
    '08' => [ '', '1k memory ibutton'], 
    '09' => [ '2502', '1k add-only memory'], 
    '0A' => [ '', '16k memory ibutton'], 
    '0B' => [ '2505', '16k add-only memory'], 
    '0C' => [ '', '64k memory ibutton'], 
    '0F' => [ '2506', '64k add-only� memory'], 
    '10' => [ '18S20', 'high precision digital thermometer'], 
    '12' => [ '2406/2407', 'dual addressable switch plus 1k memory'], 
    '14' => [ '2430A', '256 eeprom'], 
    '1A' => [ '', '4k Monetary'], 
    '1B' => [ '2436', 'battery id/monitor chip'], 
    '1C' => [ '28E04-100', '4k EEPROM with PIO'], 
    '1D' => [ '2423', '4k ram with counter'], 
    '1F' => [ '2409', 'microlan coupler'], 
    '20' => [ '2450', 'quad a/d converter'], 
    '21' => [ '', 'Thermachron'], 
    '22' => [ '1822', 'Econo Digital Thermometer'], 
    '23' => [ '2433', '4k eeprom'], 
    '24' => [ '2415', 'time chip'], 
    '26' => [ '2438', 'smart battery monitor'], 
    '27' => [ '2417', 'time chip with interrupt'], 
    '28' => [ '18B20', 'programmable resolution digital thermometer'], 
    '29' => [ '2408', '8-channel addressable switch'], 
    '2C' => [ '2890', 'digital potentiometer'], 
    '2D' => [ '2431', '1k eeprom'], 
    '2E' => [ '2770', 'battery monitor and charge controller'], 
    '30' => [ '2760/61/62', 'high-precision li+ battery monitor'], 
    '31' => [ '2720', 'efficient addressable single-cell rechargable lithium protection ic'], 
    '33' => [ '2432', '1k protected eeprom with SHA-1'], 
    '36' => [ '2740', 'high precision coulomb counter'], 
    '37' => [ '', 'Password protected 32k eeprom'], 
    '3A' => [ '2413', 'dual channel addressable switch'], 
    '41' => [ '2422', 'Temperature Logger 8k mem'], 
    '51' => [ '2751', 'multichemistry battery fuel gauge'], 
    '81' => [ '', 'Serial ID Button'], 
    '84' => [ '2404S', 'dual port plus time'], 
    '89' => [ '2502-E48/UNW', '48 bit node address chip'], 
    '8B' => [ '2505-UNW', '16k add-only'], 
    '8F' => [ '2506-UNW', '64k add-only uniqueware'], 
    'FF' => [ 'LCD', 'LCD (Swart)'], 
);

our @_moduleinfo = (
    { name => 'wire',     params => {}, },
    { name => 'w1_gpio',  params => {}, },
    { name => 'w1_therm', params => {}, },
);

sub get_module_info {
    return @_moduleinfo;
}

sub list_slaves {
    my( $class ) = @_;
    my @rlist = ();
    my $slist = HiPi::qx_sudo_shell('/bin/cat /sys/bus/w1/devices/w1_bus_master1/w1_master_slaves 2>&1');
    if( $? ) {
        return @rlist;
    }
    my @slaves = split(/\n/, $slist);
    for my $id ( @slaves ) {
        my ( $family, $discard ) = split(/-/, $id);
        $family = '0' . $family if length($family) == 1;
        my ($name, $desc) = ('','');
        if(exists($idmap{$family})) {
            $name = $idmap{$family}->[0];
            $desc = $idmap{$family}->[1];
        }
        push(@rlist, { id => $id, family => $family, name => $name, description => $desc} );
    }
    return @rlist;
}

sub read_data {
    my( $class, $id ) = @_;
    # return data & or errors
    my $data = HiPi::qx_sudo_shell(qq(/bin/cat /sys/bus/w1/devices/$id/w1_slave 2>&1));
    chomp($data);
    return $data;
}

sub id_exists {
    my( $class, $id) = @_;
    my $slist = HiPi::qx_sudo_shell('/bin/cat /sys/bus/w1/devices/w1_bus_master1/w1_master_slaves 2>&1');
    return ( $slist =~ /\Q$id\E/ && -e qq(/sys/bus/w1/devices/$id/w1_slave) ) ? 1 : 0;
}

1;
