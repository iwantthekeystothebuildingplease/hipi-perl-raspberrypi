#########################################################################################
# Package       HiPi::Pin
# Description:  GPIO / Extender Pin
# Created       Wed Feb 20 04:39:18 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Pin;

#########################################################################################
use 5.14.0;
use strict;
use warnings;
use HiPi::Class;
use base qw( HiPi::Class );
use HiPi::Constant qw( :raspberry );

our $VERSION = '0.32';

__PACKAGE__->create_ro_accessors( qw( pinid ) );

sub _open {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}


sub value {
    my($self, $newval) = @_;
    if(defined($newval)) {
        return $self->_do_setvalue($newval);
    } else {
        return $self->_do_getvalue();
    }
}

sub mode {
    my($self, $newval) = @_;
    if(defined($newval)) {
        return $self->_do_setmode($newval);
    } else {
        return $self->_do_getmode();
    }
}

sub interrupt {
    my($self, $newval) = @_;
    if(defined($newval)) {
        return $self->_do_setinterrupt($newval);
    } else {
        return $self->_do_getinterrupt();
    }
}

sub set_pud {
    my($self, $newval) = @_;
    my $rval;
    given( $newval ) {
        when( [ RPI_PUD_OFF, RPI_PUD_DOWN, RPI_PUD_UP ] ) {
            $rval = $self->_do_setpud( $newval );
        }
        default {
            croak(qq(Invalid PUD setting $newval));
        }
    }
    return $rval;
}

sub active_low {
    my($self, $newval) = @_;
    if(defined($newval)) {
        return $self->_do_activelow($newval);
    } else {
        return $self->_do_activelow();
    } 
}

1;

__END__
