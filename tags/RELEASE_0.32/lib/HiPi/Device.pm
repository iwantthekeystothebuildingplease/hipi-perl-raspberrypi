#########################################################################################
# Package       HiPi::Device
# Description:  Base class for system devices
# Created       Sat Dec 01 18:34:18 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it
#               under the terms of the GNU General Public License as published by the
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Device;

#########################################################################################

use 5.14.0;
use strict;
use warnings;
use parent qw( HiPi::Class );
use HiPi;
use HiPi::Constant qw( :raspberry );
use Carp;

__PACKAGE__->create_accessors( qw( devicename ) );

our $VERSION = '0.20';

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);
    return $self;
}


sub module_is_loaded {
    my ($class, $module) = @_;
    my $result = HiPi::qx_sudo_shell(qq(modprobe -n --first-time  $module  2>&1));
    return ( $result && $result =~ /ERROR/i ) ? 1 : 0;
}

sub modules_are_loaded {
    my $class = shift;
    my @modules  = $class->get_module_info();
    for my $mod ( @modules ) {
        return 0 if !$class->module_is_loaded( $mod->{name} );
    }
    return 1;
}

sub unload_modules {
    my $class = shift;
    my @modules = $class->get_module_info();
    return unless ( @modules );
    for (my $i = @modules - 1; $i >=0; $i--) {
        my $module = $modules[$i];
        my $check = $module->{name};
        if( $class->module_is_loaded( $module->{name} ) ) {
            HiPi::system_sudo( qq(modprobe -r $module->{name} ) ) and croak qq(failed to unload module $module->{name} : $!);
        }
    }
}

sub load_modules {
    my ( $class, $forceunload ) = @_;
    my @modules  = $class->get_module_info();
    return unless ( @modules );
    
    $class->unload_modules( @modules ) if $forceunload;
    
    for my $module( @modules ) {
        my $paramstr = '';
        while(my($key, $value) = each %{ $module->{params} }) {
            $paramstr .= qq($key=$value );
        }
        HiPi::system_sudo( qq(modprobe $module->{name} $paramstr) ) and croak qq(failed to load module $module->{name} : $!);
    }
}

sub write { 1; }

sub close { 1; }

sub DESTROY { $_[0]->close; }

1;
