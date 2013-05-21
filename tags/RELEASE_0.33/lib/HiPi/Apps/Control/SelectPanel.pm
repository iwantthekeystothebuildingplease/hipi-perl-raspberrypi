#########################################################################################
# Package       HiPi::Apps::Control::SelectPanel
# Description:  Select Manage Panel
# Created       Mon Feb 25 13:29:44 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::SelectPanel;

#########################################################################################
use 5.14.0;
use strict;
use warnings;
use Wx qw( :comboctrl :window :bitmap wxTheApp :id :misc);
use base qw( Wx::BitmapComboBox );
use HiPi::Language;
use Carp;

our $VERSION = '0.22';

use constant {
    SELECT_RASP_INFO    => 0,
    SELECT_GPIO_PAD1    => 1,
    SELECT_GPIO_PAD5    => 2,
    SELECT_GPIO_DEVICE  => 3,
    SELECT_I2C_DEVICE   => 4,
    SELECT_SPI_DEVICE   => 5,
    SELECT_W1_DEVICE    => 6,
};

our @_panelclasses = qw(
    HiPi::Apps::Control::Panel::RInfo
    HiPi::Apps::Control::Panel::GPIO1
    HiPi::Apps::Control::Panel::GPIO5
    HiPi::Apps::Control::Panel::GPIODEV
    HiPi::Apps::Control::Panel::I2C
    HiPi::Apps::Control::Panel::SPI
    HiPi::Apps::Control::Panel::W1
);

sub new {
    my ($class, $parent, $selected) = @_;
    
    my $textoptions = [
        t('Raspberry Pi Board Info') ,
        t('GPIO Pad 1') ,
        t('GPIO Pad 5') ,
        t('GPIO Device') ,
        t('I2C Device') ,
        t('SPI Device') ,
        t('1 Wire Kernel Device Driver') ,
    ];
    
    $selected //= SELECT_GPIO_PAD1();
    my $self = $class->SUPER::new($parent, wxID_ANY, '', wxDefaultPosition, wxDefaultSize, $textoptions, wxCB_READONLY|wxBORDER_THEME);
    $self->SetItemBitmap(0, Wx::Bitmap->new( wxTheApp->GetResourceFile( 'image/rasp16.png' ),wxBITMAP_TYPE_PNG ));
    $self->SetItemBitmap(1, Wx::Bitmap->new( wxTheApp->GetResourceFile( 'image/gpio1.png' ),wxBITMAP_TYPE_PNG ));
    $self->SetItemBitmap(2, Wx::Bitmap->new( wxTheApp->GetResourceFile( 'image/gpio5.png' ),wxBITMAP_TYPE_PNG ));
    $self->SetItemBitmap(3, Wx::Bitmap->new( wxTheApp->GetResourceFile( 'image/gpiodev.png' ),wxBITMAP_TYPE_PNG ));
    $self->SetItemBitmap(4, Wx::Bitmap->new( wxTheApp->GetResourceFile( 'image/i2cdev.png' ),wxBITMAP_TYPE_PNG ));
    $self->SetItemBitmap(5, Wx::Bitmap->new( wxTheApp->GetResourceFile( 'image/spidev.png' ),wxBITMAP_TYPE_PNG ));
    $self->SetItemBitmap(6, Wx::Bitmap->new( wxTheApp->GetResourceFile( 'image/w1.png' ),wxBITMAP_TYPE_PNG ));
    return $self;
}

sub GetValue {
    my $self = shift;
    my $item = $self->GetSelection();
    return $item;
}

sub SetValue {
    my ($self, $value) = @_;
    $self->SetSelection($value);
}

sub get_panel_class {
    my($self, $selection) = @_;
    return $_panelclasses[$selection];
}

1;
