#########################################################################################
# Package       HiPi::Utils
# Description:  HiPi Utilities
# Created       Sun Feb 24 05:16:17 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Utils;

#########################################################################################

use strict;
use warnings;
use Carp;
require Exporter;
use base qw( Exporter );
use XSLoader;

our $VERSION ='0.33';

our $defaultuser = 'pi';

our @EXPORT_OK = qw(
    get_groups
    create_system_group
    create_user_group
    group_add_user
    group_remove_user
    cat_file
    echo_file
    home_directory
    is_windows
    is_unix
    is_raspberry
    is_mac
);
                    
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

#---------------------------------------------------
# Allow this code to run on none raspberry platforms
#---------------------------------------------------

our ($_israspberry, $_isunix, $_iswindows, $_ismac, $_homedir) = (0,0,0,0, '');

{
    # Platform
    if( $^O =~ /^mswin/i ) {
        $_iswindows = 1;
    } elsif( $^O =~ /^darwin/i ) {
        $_ismac = 1;
    } else {
        $_isunix = 1;
        # clean our path for safety
        local $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
        my $checkcmd = qx(/bin/cat /proc/cpuinfo);
        $_israspberry = ( $checkcmd =~ /BCM2708/ ) ? 1 : 0;
    }
    
    # Home Dir
    if( $_iswindows) {
        require Win32;
        $_homedir = Win32::GetFolderPath( 0x001C, 1);
        $_homedir = Win32::GetShortPathName( $_homedir );
        $_homedir =~ s/\\/\//g;
    } else {
        $_homedir = (getpwuid($<))[7];
    }
    
    unless( -d $_homedir && -w $_homedir ) {
        croak qq(Unable to access home directory $_homedir);
    }
    
}

XSLoader::load('HiPi::Utils', $VERSION) if is_raspberry();

sub is_raspberry { $_israspberry; }
sub is_windows { $_iswindows; }
sub is_mac { $_ismac; }
sub is_unix { $_isunix; }
sub home_directory { $_homedir; }

sub get_groups {
    my $rhash = {};
    return $rhash unless is_raspberry;
    setgrent();
    while( my ($name,$passwd,$gid,$members) = getgrent() ){
        $rhash->{$name} = {
            gid     => $gid,
            members => [  split(/\s/, $members)  ],
        }
    }
    endgrent();
    return $rhash;
}

sub create_system_group {
    my($gname, $gid) = @_;
    require HiPi;
    if( $gid ) {
        HiPi::system_sudo(qq(groupadd -f -r -g $gid $gname)) and croak qq(Failed to create group $gname with gid $gid : $!);
    } else {
        HiPi::system_sudo(qq(groupadd -f -r $gname)) and croak qq(Failed to create group $gname : $!);
    }
}

sub create_user_group {
    my($gname, $gid) = @_;
    require HiPi;
    if( $gid ) {
        HiPi::system_sudo(qq(groupadd -f -g $gid $gname)) and croak qq(Failed to create group $gname with gid $gid : $!);
    } else {
        HiPi::system_sudo(qq(groupadd -f $gname)) and croak qq(Failed to create group $gname : $!);
    }
}

sub group_add_user {
    my($gname, $uname) = @_;
    require HiPi;
    HiPi::system_sudo(qq(gpasswd -a $uname $gname)) and croak qq(Failed to add user $uname to group $gname : $!);
}

sub group_remove_user {
    my($gname, $uname) = @_;
    require HiPi;
    HiPi::system_sudo(qq(gpasswd -d $uname $gname)) and croak qq(Failed to remove user $uname from group $gname : $!);
}

sub cat_file {
    my $filepath = shift;
    require HiPi;
    return '' unless is_raspberry;
    my $rval = HiPi::qx_sudo(qq(/bin/cat $filepath));
    if($?) {
        croak qq(reading file $filepath failed : $!);
    }
    return $rval;
}

sub echo_file {
    my ($msg, $filepath, $append) = @_;
    require HiPi;
    return 0 unless is_raspberry;
    my $redir = ( $append ) ? '>>' : '>';
    my $canwrite = 0;
    # croak now if filepath is a directory
    croak qq($filepath is a directory) if -d $filepath;
    
    # first check if file exists;
    if( -f $filepath ) {
        $canwrite = ( -w $filepath ) ? 1 : 0;
    } else {
        my $dir = $filepath;
        $dir =~ s/\/[^\/]+$//;
        unless( -d $dir ) {
            croak qq(Cannot write to $filepath. Directory does not exist);
        }
        $canwrite = ( -w $dir ) ? 1 : 0;
    }
    
    my $command = qq(/bin/echo \"$msg\" $append $filepath);
    {
        local $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
        if( $canwrite ) {
            system($command) and croak qq(Failed to echo to $filepath : $!);
        } else {
            HiPi::system_sudo_shell( $command ) and croak qq(Failed to echo to $filepath : $!);
        }
    }
    
}

sub parse_udev_rule {
    require HiPi;
    my $udevfile = '/etc/udev/rules.d/99-hipi-perl.rules';
    
    unless( is_raspberry ) {
        # return a default set
        return { gpio => { active => 1, group => 'gpio' }, spi => { active => 1, group => 'spi' }, };
    }
    
    my $rval = { gpio => { active => 0, group => 'gpio' }, spi => { active => 0, group => 'spi' }, };
    return $rval if !-f $udevfile;
    open my $fh, '<', $udevfile or croak qq(Failed to open $udevfile : $!);
    while(<$fh>) {
        chomp;
        my $line = $_;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        if($line =~ /KERNEL=="(spidev\*|gpio\*)"/) {
            if($1 eq 'spidev*') {
                $rval->{spi}->{active} = 1;
                if($line =~ /GROUP=="([^"]+)"/) {
                    $rval->{spi}->{group} = $1;
                } else {
                    $rval->{spi}->{group} = 'spi';
                }
            } elsif($1 eq 'gpio*') {
                $rval->{gpio}->{active} = 1;
                if($line =~ /PROGRAM="\/usr\/local\/bin\/hipi-expin\s+([^\s]+)/) {
                    $rval->{gpio}->{group} = $1;
                } else {
                    $rval->{gpio}->{group} = 'gpio';
                }
            }
        }
    }
    close($fh);
    return $rval;
}

sub set_udev_rules {
    my $rh = shift;
    require HiPi;
    my $udevfile = '/etc/udev/rules.d/99-hipi-perl.rules';
    
    return unless( is_raspberry );
    
    open my $fh, '>', $udevfile or croak qq(Failed to open $udevfile : $!);
    print $fh qq(# File autogenerated by hipi-control\n\n);
    
    if( $rh->{gpio}->{active} ) {
        my $lineout = 'KERNEL=="gpio*", SUBSYSTEM=="gpio", ACTION=="add", PROGRAM="/usr/local/bin/hipi-expin REPLGROUPNAME /sys%p"';
        my $group = $rh->{gpio}->{group};
        $lineout =~ s/REPLGROUPNAME/$group/g;
        print $fh $lineout . qq(\n\n);
        # force group presence
        create_system_group($group);
    }
    
    {
        # FIX Up permissions on export / unexport and any existing exports
        
        my $group = ( $rh->{gpio}->{active} ) ? $rh->{gpio}->{group} : 'root';
        # reset existing perms
        # for export /unexport
        HiPi::system_sudo(qq(/usr/local/bin/hipi-expin $group /sys/devices/virtual/gpio/gpiochip0));
        # for existing pins
        opendir my $dh, '/sys/devices/virtual/gpio' or croak qq(Failed to open /sys/devices/virtual/gpio : $!);
        my @pindirs = grep { $_ =~ /gpio\d+/ && -d qq(/sys/devices/virtual/gpio/$_) } readdir $dh;
        closedir($dh);
        
        for my $pinn( @pindirs ) {
            my $rootpath = qq(/sys/devices/virtual/gpio/$pinn);
            HiPi::system_sudo(qq(/usr/local/bin/hipi-expin $group $rootpath));
        }
    }
    
    if( $rh->{spi}->{active} ) {
        my $lineout = 'KERNEL=="spidev*", SUBSYSTEM=="spidev", GROUP="REPLGROUPNAME", MODE="0660"';
        my $group = $rh->{spi}->{group};
        $lineout =~ s/REPLGROUPNAME/$group/g;
        print $fh $lineout . qq(\n\n);
        # force group presence
        create_system_group($group);
    }
    
    {
        my $group = ( $rh->{spi}->{active} ) ? $rh->{spi}->{group} : 'root';
        
        # reset existing perms
        opendir my $dh, '/dev' or croak qq(Failed to open dev : $!);
        my @spidevs = grep { $_ =~ /^spidev\d+\.\d+$/ } readdir $dh;
        closedir($dh);
        
        my ($gname,$gpasswd,$gid,$gmembers) = getgrnam($group);
        
        for my $dvc ( @spidevs ) {
            my $devfile = qq(/dev/$dvc);
            chmod(0660, $devfile);
            chown(-1, $gid, $devfile);
        }
    }
    
    close($fh);
    
    # reload rules
    HiPi::system_sudo(qq(udevadm control --reload-rules));
}

sub parse_modprobe_conf {
    require HiPi;
    my $modfile = '/etc/modprobe.d/hipi.conf';
    
    #options i2c_bcm2708 baudrate=100000
    #options spidev bufsiz=4096
    
    
    unless( is_raspberry ) {
        # return a default set
        return { spidev => { active => 1, bufsiz => 4096 }, i2c_bcm2708 => { active => 1, baudrate => 100000 }, };
    }
    
    my $rval = { spidev => { active => 0, bufsiz => 4096 }, i2c_bcm2708 => { active => 0, baudrate => 100000 }, };
    return $rval if !-f $modfile;
    open my $fh, '<', $modfile or croak qq(Failed to open $modfile : $!);
    while(<$fh>) {
        chomp;
        my $line = $_;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        
        if($line =~ /^options\s([^\s]+)\s([^=]+)=([^\s]+)$/) {
            my $module = $1;
            my $param  = $2;
            my $value  = $3;
            $rval->{$module}->{active} = 1;
            $rval->{$module}->{$param} = $value;
        }
        
    }
    close($fh);
    return $rval;
}

sub set_modprobe_conf {
    my $rh = shift;
    require HiPi;
    my $modfile = '/etc/modprobe.d/hipi.conf';
    
    return unless( is_raspberry );
    
    open my $fh, '>', $modfile or croak qq(Failed to open $modfile : $!);
    print $fh qq(# File autogenerated by hipi-control\n\n);
    
    if( $rh->{i2c_bcm2708}->{active} ) {
        my $lineout = qq(options i2c_bcm2708 baudrate=$rh->{i2c_bcm2708}->{baudrate});
        print $fh $lineout . qq(\n\n);
    }
    
    if( $rh->{spidev}->{active} ) {
        my $lineout = qq(options spidev bufsiz=$rh->{spidev}->{bufsiz});
        print $fh $lineout . qq(\n\n);
    }
    
    close($fh);
    
    require HiPi::Device::I2C;
    HiPi::Device::I2C->set_baudrate($rh->{i2c_bcm2708}->{baudrate});
    
    require HiPi::Device::SPI;
    HiPi::Device::SPI->set_bufsiz($rh->{spidev}->{bufsiz});

}

sub drop_permissions_name {
    my($username, $groupname) = @_;
    
    return 0 unless is_raspberry;
    
    $username ||= getlogin();
    $username ||= $defaultuser;
    
    my($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwnam($username);
    my $targetuid = $uid;
    my $targetgid = ( $groupname ) ? (getgrnam($groupname))[2] : $gid;
    if( $targetuid > 0 && $targetgid > 0 ) {
        drop_permissions_id($targetuid, $targetgid);
    } else {
        croak qq(Could not drop permissions to uid $targetuid, gid $targetgid);
    }
    unless( $> == $targetuid && $< == $targetuid && $) == $targetgid && $( == $targetgid) {
        croak qq(Could not set Perl permissions to uid $targetuid, gid $targetgid);
    }
}

1;

__END__
