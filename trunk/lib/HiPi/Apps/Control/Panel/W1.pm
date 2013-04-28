#########################################################################################
# Package       HiPi::Apps::Control::Panel::W1
# Description:  Base for Device panels
# Created       Wed Feb 27 23:09:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Panel::W1;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Apps::Control::Panel::Device );
use Wx qw( :sizer :id :misc :textctrl );
use HiPi::Apps::Control::Data::DeviceW1;
use HiPi::Language;
use Try::Tiny;
use HiPi::Utils;
use HiPi::Wx::ValidatedCheckBox;
use Wx::Event qw( EVT_CHECKBOX );

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( list ));

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new($parent);
    
    my $vdata = HiPi::Apps::Control::Data::DeviceW1->new;
    $self->SetValidationData($vdata);
    
    #------------------------------------------------------
    # Controls
    #------------------------------------------------------
    my $modules  = HiPi::Wx::ValidatedCheckBox->new($self, t('W1 Kernel Modules Loaded'),  $vdata, 'loaded');
    my $list = HiPi::Apps::Control::Panel::W1::List->new($self, $vdata);
    
    #------------------------------------------------------
    # Events
    #------------------------------------------------------
    EVT_CHECKBOX($self, $modules, \&_on_evt_loaded);
    
    #------------------------------------------------------
    # Layout
    #------------------------------------------------------
    my $msizer   = Wx::BoxSizer->new(wxVERTICAL);
    my $modsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    
    $modsizer->Add($modules, 0, wxEXPAND|wxTOP|wxRIGHT|wxBOTTOM, 5);
    
    $msizer->Add( $modsizer, 0, wxEXPAND|wxALL, 0);
    $msizer->Add( $list, 1, wxEXPAND|wxALL, 0);
    $self->SetSizer( $msizer );
    return $self;
}

sub _on_evt_loaded {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    try {
        my $val = ( $event->IsChecked ) ? 1 : 0;
        if( $val ) {
            HiPi::Device::OneWire->load_modules(1);
        } else {
            HiPi::Device::OneWire->unload_modules();
        }
        my $msg = ( $val ) ? t('W1 Kernel Modules Loaded') : t('W1 Kernel Modules Unloaded');
        Wx::LogMessage($msg);
    } catch {
        Wx::LogError($_);
        Wx::LogError(t('Failed to apply kernel load/unload command.'));
    };
    $self->RefreshValidatedPanel;
}


#########################################################################################

package HiPi::Apps::Control::Panel::W1::List;

#########################################################################################
use strict;
use warnings;
use Wx qw( :listctrl :id :misc);
use base qw( Wx::ListCtrl HiPi::Class );

__PACKAGE__->create_accessors( qw( slaves ) );

sub new {
    my($class, $parent, $vdata) = @_;
    my $self = $class->SUPER::new($parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT);
    
    # cols name exported mode value reverse interrupt
    $self->InsertColumn(0, 'Device Id', wxLIST_FORMAT_LEFT, 130);
    $self->InsertColumn(1, 'Name', wxLIST_FORMAT_LEFT, 80);
    $self->InsertColumn(2, 'Description', wxLIST_FORMAT_LEFT, 300);
    
    $self->SetValidator( HiPi::Apps::Control::Panel::W1::ListValidator->new($vdata, 'slaves'));
    
    return $self;
}

#########################################################################################

package HiPi::Apps::Control::Panel::W1::ListValidator;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Wx::Validator );
use HiPi::Constant qw( :raspberry );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub GetWindowValue {
    my $self = shift;
    $self->GetWindow->slaves;
}

sub SetWindowValue {
    my ($self, $data) = @_;
    my $list = $self->GetWindow;
    $list->slaves($data);
    $list->Freeze;
    $list->DeleteAllItems;
    
    my $index = 0;
    
    for my $device ( @$data ) {
        my $id = $list->InsertImageStringItem( $index, $device->{id}, -1);
        $list->SetItem($id, 1, $device->{name}, -1 );
        $list->SetItem($id, 2, $device->{description}, -1 );
        $index ++;
    }
    
    $list->Thaw;
}

1;
