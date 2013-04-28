#########################################################################################
# Package       HiPi::Apps::Control::MainPanel
# Description:  Main Panel For Frame
# Created       Wed Feb 27 16:11:19 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::MainPanel;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Wx::Panel );
use Wx qw( wxTheApp :id :misc :window :panel :sizer );

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( datapanel ) );

require HiPi::Apps::Control::Panel::RInfo;
require HiPi::Apps::Control::Panel::GPIO1;
require HiPi::Apps::Control::Panel::GPIO5;
require HiPi::Apps::Control::Panel::GPIODEV;
require HiPi::Apps::Control::Panel::I2C;
require HiPi::Apps::Control::Panel::SPI;
require HiPi::Apps::Control::Panel::W1;

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new($parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL|wxBORDER_NONE);
    
    $self->SetSizer( Wx::BoxSizer->new(wxVERTICAL) );
    return $self;
}

sub set_panel_class {
    my($self, $panelclass) = @_;
    
    $self->Freeze;
    
    my $sizer = $self->GetSizer;
    
    my $newpanel = $panelclass->new($self);
    
    if( my $oldpanel = $self->datapanel ) {
        if(!$oldpanel->WriteValidatedPanel ) {
            $newpanel->Destroy;
            $self->Thaw;
            return 0;
        }
        
        $self->datapanel(undef);
        $sizer->Replace($oldpanel, $newpanel);
        $oldpanel->Destroy;
    } else {
        $sizer->Add($newpanel, 1, wxALL|wxEXPAND, 0);
    }
    
    $self->datapanel($newpanel);
    $sizer->Layout;
    $self->Thaw;
    return $newpanel->InitValidatedPanel();
}

sub reload_service {
    my $self = shift;
    $self->datapanel->RefreshValidatedPanel;
}

1;
