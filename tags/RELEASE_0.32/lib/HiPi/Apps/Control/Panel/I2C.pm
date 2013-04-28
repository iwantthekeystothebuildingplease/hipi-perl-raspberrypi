#########################################################################################
# Package       HiPi::Apps::Control::Panel::I2C
# Description:  Base for Device panels
# Created       Wed Feb 27 23:09:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Panel::I2C;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Apps::Control::Panel::Device );
use Wx qw( :sizer :id :misc :textctrl );
use HiPi::Apps::Control::Data::DeviceI2C;
use HiPi::Wx::ValidatedCheckBox;
use HiPi::Language;
use HiPi::Wx::ValidatedText;
use Try::Tiny;
use HiPi::Utils;
use HiPi::Apps::Control::GroupDialog;
use Wx::Event qw( EVT_BUTTON EVT_TEXT EVT_CHECKBOX);

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( list applybutton baudtext group ));

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new($parent);
    
    my $vdata = HiPi::Apps::Control::Data::DeviceI2C->new;
    $self->SetValidationData($vdata);
    
    #------------------------------------------------------
    # Controls
    #------------------------------------------------------
    my $modules  = HiPi::Wx::ValidatedCheckBox->new($self, t('I2C Kernel Modules Loaded'),  $vdata, 'loaded');
    my $checkdev = HiPi::Wx::ValidatedCheckBox->new($self, t('Allow Group Access To Devices'),  $vdata, 'udevactive');
    $checkdev->Enable(0); # currently standard i2c kernel drivers set i2c group and permissions 
    
    my $grp_label = Wx::StaticText->new($self, wxID_ANY, t('Group Name'));
    my $grp = HiPi::Wx::ValidatedText->new($self, '', $vdata, 'udevgroup', wxTE_READONLY|wxALIGN_RIGHT);
    $self->group($grp);
    my $grpbutton = Wx::Button->new($self, wxID_ANY, '...', wxDefaultPosition, [25,-1]);
    
    my $baud_label = Wx::StaticText->new($self, wxID_ANY, t('Baudrate'));
    my $baud = HiPi::Wx::ValidatedText->new($self, '', $vdata, 'baudrate');
    $self->baudtext($baud);
    my $baudapply = Wx::Button->new($self, wxID_ANY, 'Apply', wxDefaultPosition, [-1,-1]);
    $baudapply->SetValidator(HiPi::Apps::Control::Panel::I2C::ApplyValidator->new($vdata, 'passthrough'));
    $self->applybutton($baudapply);
    
    my $list = HiPi::Apps::Control::Panel::I2C::List->new($self, $vdata);
    
    #------------------------------------------------------
    # Events
    #------------------------------------------------------
    
    EVT_BUTTON($self, $baudapply, \&_on_evt_apply);
    EVT_TEXT($self, $baud, \&_on_evt_baudrate);
    EVT_CHECKBOX($self, $modules, \&_on_evt_loaded);
    EVT_CHECKBOX($self, $checkdev, \&_on_evt_usegroup);
    EVT_BUTTON($self, $grpbutton, \&_on_evt_manage_group);
    
    #------------------------------------------------------
    # Layout
    #------------------------------------------------------
    my $msizer   = Wx::BoxSizer->new(wxVERTICAL);
    my $modsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $topsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $bufsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $modsizer->Add($modules, 0, wxEXPAND|wxTOP|wxRIGHT|wxBOTTOM, 5);
    $topsizer->Add($checkdev, 1, wxEXPAND|wxTOP|wxRIGHT|wxBOTTOM, 5);
    $topsizer->Add($grp_label, 0, wxEXPAND|wxTOP, 8);
    $topsizer->Add($grp, 0, wxEXPAND|wxTOP|wxLEFT|wxBOTTOM, 5);
    $topsizer->Add($grpbutton, 0, wxEXPAND|wxLEFT|wxTOP|wxBOTTOM, 5);
    
    $bufsizer->Add($baud_label, 0, wxEXPAND|wxTOP, 8);
    $bufsizer->Add($baud, 0, wxEXPAND|wxTOP|wxLEFT|wxBOTTOM, 5);
    $bufsizer->Add($baudapply, 0, wxEXPAND|wxLEFT|wxTOP|wxBOTTOM, 5);
    
    $msizer->Add( $modsizer, 0, wxEXPAND|wxALL, 0);
    $msizer->Add( $topsizer, 0, wxEXPAND|wxALL, 0);
    $msizer->Add( $bufsizer, 0, wxEXPAND|wxALL, 0);
    $msizer->Add( $list, 1, wxEXPAND|wxALL, 0);
    $self->SetSizer( $msizer );
    
    return $self;
}

sub _on_evt_manage_group {
    my($self, $event) = @_;
    $event->Skip(1);
    my $group = $self->group->GetValue;
    my $dialog = HiPi::Apps::Control::GroupDialog->new($self, t('Manage Group - (%s)', $group), $group);
    $dialog->ShowModal();
    $dialog->Destroy;
}

sub _on_evt_apply {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    try {
        my $rh = HiPi::Utils::parse_modprobe_conf;
        $rh->{i2c_bcm2708}->{baudrate} = $self->baudtext->GetValue;
        $rh->{i2c_bcm2708}->{active} = 1;
        HiPi::Utils::set_modprobe_conf( $rh );
        Wx::LogMessage('New baudrate value applied');
    } catch {
        Wx::LogError($_);
        Wx::LogError('Failed to apply new baudrate value.');
    };
    $self->RefreshValidatedPanel;
}

sub _on_evt_baudrate {
    my($self, $event) = @_;
    $event->Skip(1);
    $self->applybutton->Enable(1);
}

sub _on_evt_usegroup {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    try {
        my $val = ( $event->IsChecked ) ? 1 : 0;
        my $rh = HiPi::Utils::parse_udev_rule;
        $rh->{i2c}->{active} = $val;
        HiPi::Utils::set_udev_rules( $rh );
        Wx::LogMessage('Applied new group access settings.');
    } catch {
        Wx::LogError($_);
        Wx::LogError('Failed to apply new group access settings.');
    };
    $self->RefreshValidatedPanel;
}

sub _on_evt_loaded {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    try {
        my $val = ( $event->IsChecked ) ? 1 : 0;
        if( $val ) {
            HiPi::Device::I2C->load_modules(1);
        } else {
            HiPi::Device::I2C->unload_modules();
        }
        my $msg = ( $val ) ? t('I2C Kernel Modules Loaded') : t('I2C Kernel Modules Unloaded');
        Wx::LogMessage($msg);
    } catch {
        Wx::LogError($_);
        Wx::LogError(t('Failed to apply kernel load/unload command.'));
    };
    $self->RefreshValidatedPanel;
}

#########################################################################################

package HiPi::Apps::Control::Panel::I2C::List;

#########################################################################################
use strict;
use warnings;
use Wx qw( :listctrl :id :misc);
use base qw( Wx::ListCtrl HiPi::Class );

__PACKAGE__->create_accessors( qw( devicelist ) );

sub new {
    my($class, $parent, $vdata) = @_;
    my $self = $class->SUPER::new($parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT);
    
    # cols name exported mode value reverse interrupt
    $self->InsertColumn(0, 'Device Name', wxLIST_FORMAT_LEFT, 250);
    
    $self->SetValidator( HiPi::Apps::Control::Panel::I2C::ListValidator->new($vdata, 'devicelist'));
    
    return $self;
}

#########################################################################################

package HiPi::Apps::Control::Panel::I2C::ListValidator;

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
    $self->GetWindow->devicelist;
}

sub SetWindowValue {
    my ($self, $data) = @_;
    my $list = $self->GetWindow;
    $list->devicelist($data);
    $list->Freeze;
    $list->DeleteAllItems;
    
    my $index = 0;
    
    for my $device ( @$data ) {
        my $id = $list->InsertImageStringItem( $index, $device, -1);
        $index ++;
    }
    
    $list->Thaw;
}

#########################################################################################

package HiPi::Apps::Control::Panel::I2C::ApplyValidator;

#########################################################################################
use strict;
use warnings;
use parent qw( HiPi::Wx::Validator::PassThrough);


sub OnValidatorSetValue {
    my($self, $data) = @_;
    $self->GetWindow->Enable(0);
}


1;