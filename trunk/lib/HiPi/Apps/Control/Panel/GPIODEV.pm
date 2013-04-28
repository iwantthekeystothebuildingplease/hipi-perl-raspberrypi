#########################################################################################
# Package       HiPi::Apps::Control::Panel::GPIODEV
# Description:  Base for Device panels
# Created       Wed Feb 27 23:09:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Panel::GPIODEV;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Apps::Control::Panel::Device );
use Wx qw( :sizer :id :misc :textctrl wxTheApp);
use HiPi::Apps::Control::Data::DeviceGPIO;
use HiPi::Wx::ValidatedCheckBox;
use HiPi::Language;
use HiPi::Wx::ValidatedText;
use HiPi::Apps::Control::GroupDialog;
use HiPi::Utils;
use Wx::Event( qw( EVT_BUTTON EVT_CHECKBOX EVT_LIST_ITEM_SELECTED EVT_LIST_ITEM_DESELECTED) );
use Try::Tiny;
use HiPi::Device::GPIO;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( list group btnexport btnmode btnlevel btnlogic btnedge device));

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new($parent);
    
    my $vdata = HiPi::Apps::Control::Data::DeviceGPIO->new;
    $self->SetValidationData($vdata);
    
    $self->device(HiPi::Device::GPIO->new);
    
    #------------------------------------------------------
    # Controls
    #------------------------------------------------------
    my $checkdev = HiPi::Wx::ValidatedCheckBox->new($self, t('Allow Group Access To Devices'),  $vdata, 'udevactive');
    my $grp_label = Wx::StaticText->new($self, wxID_ANY, t('Group Name'));
    my $grp = HiPi::Wx::ValidatedText->new($self, '', $vdata, 'udevgroup', wxTE_READONLY|wxALIGN_RIGHT);
    $self->group($grp);
    my $grpbutton = Wx::Button->new($self, wxID_ANY, '...', wxDefaultPosition, [25,-1]);
    my $list = HiPi::Apps::Control::Panel::GPIODEV::List->new($self, $vdata);
    $self->list($list);
    
    my $buttonlabel = Wx::StaticText->new($self, wxID_ANY, t('Toggle Pin Settings'));
    
    my $btnexport = Wx::Button->new($self, wxID_ANY, 'Export', wxDefaultPosition, [60, -1]);
    $self->btnexport($btnexport);
    my $btnmode = Wx::Button->new($self, wxID_ANY, 'Mode', wxDefaultPosition, [60, -1]);
    $self->btnmode($btnmode);
    my $btnlevel = Wx::Button->new($self, wxID_ANY, 'Level', wxDefaultPosition, [60, -1]);
    $self->btnlevel($btnlevel);
    my $btnlogic = Wx::Button->new($self, wxID_ANY, 'Invert', wxDefaultPosition, [60, -1]);
    $self->btnlogic($btnlogic);
    my $btnedge = Wx::Button->new($self, wxID_ANY, 'Edge', wxDefaultPosition, [60, -1]);
    $self->btnedge($btnedge);
    
    
    #------------------------------------------------------
    # Events
    #------------------------------------------------------
    EVT_BUTTON($self, $grpbutton, \&_on_evt_manage_group);
    EVT_CHECKBOX($self, $checkdev, \&_on_evt_usegroup);
    EVT_LIST_ITEM_SELECTED($self, $list, \&_on_evt_list_selected);
    EVT_LIST_ITEM_DESELECTED($self, $list, \&_on_evt_list_deselected);
    EVT_BUTTON($self, $btnexport, \&_on_evt_button_export);
    EVT_BUTTON($self, $btnmode, \&_on_evt_button_mode);
    EVT_BUTTON($self, $btnlevel, \&_on_evt_button_level);
    EVT_BUTTON($self, $btnlogic, \&_on_evt_button_logic);
    EVT_BUTTON($self, $btnedge, \&_on_evt_button_edge);
    
    #------------------------------------------------------
    # Layout
    #------------------------------------------------------
    my $msizer   = Wx::BoxSizer->new(wxVERTICAL);
    my $topsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $topsizer->Add($checkdev, 1, wxEXPAND|wxTOP|wxRIGHT|wxBOTTOM, 5);
    $topsizer->Add($grp_label, 0, wxEXPAND|wxTOP, 8);
    $topsizer->Add($grp, 0, wxEXPAND|wxTOP|wxLEFT|wxBOTTOM, 5);
    $topsizer->Add($grpbutton, 0, wxEXPAND|wxLEFT|wxTOP|wxBOTTOM, 5);
    $msizer->Add( $topsizer, 0, wxEXPAND|wxALL, 0);
    $msizer->Add( $list, 1, wxEXPAND|wxALL, 0);
    
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $buttonsizer->Add($buttonlabel,1,wxEXPAND|wxTOP, 10);
    for ( $btnexport, $btnmode, $btnlevel, $btnlogic, $btnedge ) {
        $_->Enable(0);
        $buttonsizer->Add($_, 0, wxLEFT|wxBOTTOM|wxTOP|wxEXPAND, 6);
    }
    $msizer->Add($buttonsizer, 0, wxEXPAND|wxALL, 0);
    $self->SetSizer( $msizer );
    
    return $self;
}

sub _disable_buttons {
    my $self = shift;
    $self->btnexport->Enable(0);
    $self->btnmode->Enable(0);
    $self->btnlevel->Enable(0);
    $self->btnlogic->Enable(0);
    $self->btnedge->Enable(0);
}

sub _on_evt_list_selected {
    my($self, $event) = @_;
    $event->Skip(1);
    my $index = $event->GetIndex;
    $self->_disable_buttons;
    
    if(!defined($index) || $index == -1) {
        return;
    }
    
    my $pinname = $event->GetText;
    my $pin = $event->GetEventObject->pindata->{$pinname};
    unless( $pin ) {
        Wx::Logerror(qq(Unable to find data for $pinname));
        return;
    }
    
    $self->btnexport->Enable(1);    
    return unless $pin->{exported};
    $self->btnmode->Enable(1);
    
    if( $pin->{direction} ) {
        $self->btnlevel->Enable(1);
    } else {
        $self->btnlogic->Enable(1);
        $self->btnedge->Enable(1);
    }
}

sub _get_selected_pin {
    my $self = shift;
    my $item = $self->list->GetFirstSelected;
    return undef if !defined($item) || $item == -1;
    
    my $pinname = $self->list->GetItemText($item);
    my $pin = $self->list->pindata->{$pinname};
    unless( $pin ) {
        Wx::Logerror(qq(Unable to find data for $pinname));
        return undef;
    }
    return $pin;
}

sub _on_evt_list_deselected {
    my($self, $event) = @_;
    $event->Skip(1);
    $self->_disable_buttons;
}

sub _on_evt_button_export {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    my $pin = $self->_get_selected_pin;
    return unless $pin;
    try {
        if($pin->{exported}) {
            $self->device->unexport_pin($pin->{id});
        } else {
            $self->device->export_pin($pin->{id});
        }
    } catch {
        Wx::LogError('Failed to change export status of pin %s : %s', $pin->{id}, $_ );
    };
    $self->_disable_buttons;
    $self->RefreshValidatedPanel;
}

sub _on_evt_button_mode {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    my $pindata = $self->_get_selected_pin;
    return unless $pindata;
    
    my $newmode = ($pindata->{direction}) ? 0 : 1;
    {
        my $pin = $self->device->get_pin( $pindata->{id} );
        $pin->mode($newmode);
    }
    $self->_disable_buttons;
    $self->RefreshValidatedPanel;
}

sub _on_evt_button_level {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    my $pindata = $self->_get_selected_pin;
    return unless $pindata;
    
    my $newval = ($pindata->{value}) ? 0 : 1;
    {
        my $pin = $self->device->get_pin( $pindata->{id} );
        $pin->value($newval);
    }
    $self->_disable_buttons;
    $self->RefreshValidatedPanel;
}

sub _on_evt_button_logic {
    my($self, $event) = @_;
    $event->Skip(1);
    my $pindata = $self->_get_selected_pin;
    return unless $pindata;
    my $newval = ($pindata->{activelow}) ? 0 : 1;
    {
        my $pin = $self->device->get_pin( $pindata->{id} );
        $pin->active_low($newval);
    }
    $self->_disable_buttons;
    $self->RefreshValidatedPanel;
}

sub _on_evt_button_edge {
    my($self, $event) = @_;
    $event->Skip(1);
    my $pindata = $self->_get_selected_pin;
    return unless $pindata;
    
    try {
        my $edge = Wx::GetSingleChoice( t('Select the type of edge detection to apply to pin %s.', $pindata->{id}), wxTheApp->GetAppDisplayName,
                [qw(none rising falling both)], $self );
        
        my $pin = $self->device->get_pin( $pindata->{id} );
        
        if($edge) {
            $pin->interrupt($edge);
        } else {
            $pin->interrupt('none');
        }
    } catch {
        Wx::LogError($_);
        Wx::LogError(t('Failed to set interrupts for GPIO %s', $pindata->{id}));
    };
    
    $self->_disable_buttons;
    $self->RefreshValidatedPanel;
}

sub _on_evt_manage_group {
    my($self, $event) = @_;
    $event->Skip(1);
    my $group = $self->group->GetValue;
    my $dialog = HiPi::Apps::Control::GroupDialog->new($self, t('Manage Group - (%s)', $group), $group);
    $dialog->ShowModal();
    $dialog->Destroy;
}

sub _on_evt_usegroup {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    try {
        my $val = ( $event->IsChecked ) ? 1 : 0;
        my $rh = HiPi::Utils::parse_udev_rule;
        $rh->{gpio}->{active} = $val;
        HiPi::Utils::set_udev_rules( $rh );
        Wx::LogMessage('Applied new group access settings.');
    } catch {
        Wx::LogError($_);
        Wx::LogError('Failed to apply new group access settings.');
    };
    
    $self->RefreshValidatedPanel;
}

#########################################################################################

package HiPi::Apps::Control::Panel::GPIODEV::List;

#########################################################################################
use strict;
use warnings;
use Wx qw( :listctrl :id :misc);
use base qw( Wx::ListView HiPi::Class );

__PACKAGE__->create_accessors( qw( pindata ) );

sub new {
    my($class, $parent, $vdata) = @_;
    my $self = $class->SUPER::new($parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_SINGLE_SEL );
    
    # cols name exported mode value reverse interrupt
    $self->InsertColumn(0, 'Pin', wxLIST_FORMAT_LEFT, 75);
    $self->InsertColumn(1, 'RPi', wxLIST_FORMAT_LEFT, 100);
    $self->InsertColumn(2, 'Export', wxLIST_FORMAT_LEFT, 50);
    $self->InsertColumn(3, 'Mode', wxLIST_FORMAT_LEFT, 50);
    $self->InsertColumn(4, 'Level', wxLIST_FORMAT_LEFT, 50);
    $self->InsertColumn(5, 'Invert', wxLIST_FORMAT_LEFT, 50);
    $self->InsertColumn(6, 'Edge', wxLIST_FORMAT_LEFT, 100);
    
    $self->SetValidator( HiPi::Apps::Control::Panel::GPIODEV::ListValidator->new($vdata, 'pindata'));
    
    return $self;
}

#########################################################################################

package HiPi::Apps::Control::Panel::GPIODEV::ListValidator;

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
    $self->GetWindow->pindata;
}

sub SetWindowValue {
    my ($self, $data) = @_;
    my $list = $self->GetWindow;
    $list->pindata($data);
    $list->Freeze;
    $list->DeleteAllItems;
    
    my $index = 0;
    
    for my $pinname ( sort keys(%$data) ) {
        my $pin = $data->{$pinname};
        my $id = $list->InsertImageStringItem( $index, $pinname, -1);
        $list->SetItemData($id, $pin->{id});
        $list->SetItem($id,1, $pin->{rpi}, -1);
        
        if( $pin->{exported} ) {
            
            my $edge = 'None';
            if( $pin->{edge} == RPI_INT_BOTH ) {
                $edge = 'Both';
            } elsif( $pin->{edge} == RPI_INT_FALL ) {
                $edge = 'Falling';
            } elsif( $pin->{edge} == RPI_INT_RISE ) {
                $edge = 'Rising';
            } else {
                $edge = 'None';
            }
            $list->SetItem($id,2, 'Yes', -1);
            $list->SetItem($id,3, ($pin->{direction}) ? 'Output' : 'Input', -1);
            $list->SetItem($id,4, ($pin->{value}) ? 'High' : 'Low', -1);
            $list->SetItem($id,5, ($pin->{activelow}) ? 'Yes' : 'No', -1);
            $list->SetItem($id,6, $edge, -1);
        } else {
            $list->SetItem($id,2, 'No', -1);
            $list->SetItem($id,3, '-', -1);
            $list->SetItem($id,4, '-', -1);
            $list->SetItem($id,5, '-', -1);
            $list->SetItem($id,6, '-', -1);
        }
        
        $index ++;
    }
    $list->Thaw;
    
}

1;
