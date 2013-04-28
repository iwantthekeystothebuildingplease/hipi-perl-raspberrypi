#########################################################################################
# Package       HiPi::Interface::HD44780
# Description:  Control a LCD based on HD44780
# Created       Sat Nov 24 20:24:23 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Interface::HD44780;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use Carp;

our $VERSION = '0.20';

__PACKAGE__->create_accessors( qw(
    width lines backlightcontrol positionmap devicename
    ) );

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use constant {
    SRX_CURSOR_OFF       => 0x0C,
    SRX_CURSOR_BLINK     => 0x0F,
    SRX_CURSOR_UNDERLINE => 0x0E,
};

{
    my @const = qw( SRX_CURSOR_OFF SRX_CURSOR_BLINK SRX_CURSOR_UNDERLINE );
    push( @EXPORT_OK, @const );
    $EXPORT_TAGS{cursor} = \@const;
}

# HD44780 commands

use constant {
    HD44780_CLEAR_DISPLAY           => 0x01,
    HD44780_HOME_UNSHIFT            => 0x02,
    HD44780_CURSOR_MODE_LEFT        => 0x04,
    HD44780_CURSOR_MODE_LEFT_SHIFT  => 0x05,
    HD44780_CURSOR_MODE_RIGHT       => 0x06,
    HD44780_CURSOR_MODE_RIGHT_SHIFT => 0x07,
    HD44780_DISPLAY_OFF             => 0x08,
    
    HD44780_DISPLAY_ON              => 0x0C,
    HD44780_CURSOR_OFF              => 0x0C,
    HD44780_CURSOR_UNDERLINE        => 0x0E,
    HD44780_CURSOR_BLINK            => 0x0F,
    
    HD44780_SHIFT_CURSOR_LEFT       => 0x10,
    HD44780_SHIFT_CURSOR_RIGHT      => 0x14,
    HD44780_SHIFT_DISPLAY_LEFT      => 0x18,
    HD44780_SHIFT_DISPLAY_RIGHT     => 0x1C,
    
    HD44780_CURSOR_POSITION         => 0x80,
    
};

{
    my @const = qw(
        HD44780_CLEAR_DISPLAY 
        HD44780_HOME_UNSHIFT
        HD44780_CURSOR_MODE_LEFT
        HD44780_CURSOR_MODE_LEFT_SHIFT
        HD44780_CURSOR_MODE_RIGHT
        HD44780_CURSOR_MODE_RIGHT_SHIFT
        HD44780_DISPLAY_OFF
        
        HD44780_DISPLAY_ON
        HD44780_CURSOR_OFF
        HD44780_CURSOR_UNDERLINE
        HD44780_CURSOR_BLINK
        
        HD44780_SHIFT_CURSOR_LEFT
        HD44780_SHIFT_CURSOR_RIGHT
        HD44780_SHIFT_DISPLAY_LEFT
        HD44780_SHIFT_DISPLAY_RIGHT
        
        HD44780_CURSOR_POSITION
    );
    push( @EXPORT_OK, @const );
    $EXPORT_TAGS{hd44780} = \@const;
}

sub new {
    my ($class, %userparams ) = @_;
    
    my %params = (
        width            =>  undef,
        lines            =>  undef,
        backlightcontrol =>  0,
        device           =>  undef,
        positionmap      =>  undef,
    );
    
    # get user params
    foreach my $key( keys (%userparams) ) {
        $params{$key} = $userparams{$key};
    }
    
    croak('A derived class must provide a device') unless(defined($params{device}));
    
    unless( $params{positionmap} ) {   
        # setup default position map
        unless( $params{width} =~ /^(16|20)$/ && $params{lines} =~ /^(2|4)$/) {
            croak('HiPi::Interface::HD44780 only supports default LCD types 16x2, 16x4, 20x2, 20x4' );
        }
        my (@pmap, @line1, @line2, @line3, @line4, @buffers);
        
        if( $params{width} == 16 ) {
            @line1 = (0..15);
            @line2 = (64..79);
            @line3 = (16..31);
            @line4 = (80..95);
        } elsif( $params{width} == 20 ) {
            @line1 = (0..19);
            @line2 = (64..83);
            @line3 = (20..39);
            @line4 = (84..103);
        }
        
        if( $params{lines} == 2 ) {
            @pmap = ( @line1, @line2 );
        } elsif( $params{lines} == 4 ) {
            @pmap = ( @line1, @line2, @line3, @line4 );
        }
        
        $params{positionmap} = \@pmap;
    }
    
    my $self = $class->SUPER::new(%params);
    
    $self->update_geometry; # will set cols / lines to controller
    
    return $self;
}

sub enable {
    my($self, $enable) = @_;
    $enable = 1 unless defined($enable);
    my $command = ( $enable ) ? HD44780_DISPLAY_ON : HD44780_DISPLAY_OFF;
    $self->send_command( $command ) ;
}

sub set_cursor_position {
    my($self, $col, $row) = @_;
    my $pos = $col + ( $row * $self->width ); 
    $self->send_command( HD44780_CURSOR_POSITION + $self->positionmap->[$pos] );
}

sub move_cursor_left  {
    $_[0]->send_command( HD44780_SHIFT_CURSOR_LEFT );
}

sub move_cursor_right  {
    $_[0]->send_command( HD44780_SHIFT_CURSOR_RIGHT );
}

sub home  { $_[0]->send_command( HD44780_HOME_UNSHIFT ); }

sub clear { $_[0]->send_command( HD44780_CLEAR_DISPLAY ); }

sub set_cursor_mode { $_[0]->send_command( $_[1] ); }

sub backlight { croak('backlight must be overriden in derived class'); }

sub send_text { croak('send_text must be overriden in derived class'); }

sub send_command { croak('send_command must be overriden in derived class'); }

sub update_baudrate { croak('update_baudrate must be overriden in derived class'); }

sub update_geometry { croak('update_geometry must be overriden in derived class'); }

1;

__END__
