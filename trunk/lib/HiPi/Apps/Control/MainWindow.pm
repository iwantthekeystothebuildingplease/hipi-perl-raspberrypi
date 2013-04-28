#########################################################################################
# Package       HiPi::Apps::Control::MainWindow
# Description:  Main Window for HiPi Apps Control
# Created       Mon Feb 25 13:29:44 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::MainWindow;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Wx::Frame );
use HiPi::Language;
use Wx qw( wxTheApp :panel :sizer :id :misc :window );
use HiPi::Apps::Control::SelectPanel;
use HiPi::Apps::Control::MainPanel;
use Try::Tiny;
use Wx::Event qw( EVT_COMBOBOX EVT_BUTTON);

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw(datapanel) );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $busy = Wx::BusyCursor->new;
    #-----------------------------------------------------------
    # Menu & Commands
    #-----------------------------------------------------------
    
    my @accelerators;
    require HiPi::Apps::Control::Menu::File;
    require HiPi::Apps::Control::Menu::Help;
    my $fmenubar = Wx::MenuBar->new();
    
    {
        my $mhandler = HiPi::Apps::Control::Menu::File->new(undef);
        my $mmenu = $mhandler->CreateMenu;
        $fmenubar->Append($mmenu, t('&File'));
        push( @accelerators, $mhandler->GetAccelerators );
    }
    {
        my $mhandler = HiPi::Apps::Control::Menu::Help->new(undef);
        my $mmenu = $mhandler->CreateMenu;
        $fmenubar->Append($mmenu, t('&Help'));
        push( @accelerators, $mhandler->GetAccelerators );
    }
    
    $self->SetMenuBar($fmenubar);
    $self->SetAcceleratorTable( Wx::AcceleratorTable->new( @accelerators ) );
    
    #-----------------------------------------------------------
    # Controls
    #-----------------------------------------------------------
    
    my $framepanel = Wx::Panel->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL|wxBORDER_NONE );
    my $selector_label = Wx::StaticText->new($framepanel, wxID_ANY, t('Select Service'));
    my $selector  = HiPi::Apps::Control::SelectPanel->new($framepanel);
    my $btnrefresh = Wx::Button->new($framepanel, wxID_ANY, t('Refresh'), wxDefaultPosition, wxDefaultSize, 0);
    my $mainpanel = HiPi::Apps::Control::MainPanel->new($framepanel);
    
    $self->datapanel($mainpanel);
    
    #-----------------------------------------------------------
    # Events
    #-----------------------------------------------------------
    
    EVT_COMBOBOX($self, $selector, \&_on_event_selector);
    EVT_BUTTON($self, $btnrefresh, \&_on_event_refreshpanel);
    
    #-----------------------------------------------------------
    # Layout
    #-----------------------------------------------------------
    
    my $framesizer = Wx::BoxSizer->new(wxVERTICAL);
    my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
    my $selectsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    
    $selectsizer->Add($selector_label, 0, wxEXPAND|wxTOP, 3);
    $selectsizer->Add($selector, 1, wxEXPAND|wxLEFT, 5);
    $selectsizer->Add($btnrefresh, 0, wxEXPAND|wxLEFT, 3);
    $mainsizer->Add($selectsizer, 0, wxEXPAND|wxALL, 10);
    $mainsizer->Add($mainpanel, 1, wxEXPAND|wxALL, 10);
    
    $framepanel->SetSizer($mainsizer);
    $framesizer->Add($framepanel, 1, wxALL|wxEXPAND, 0);
    $self->SetSizer($framesizer);

    #-----------------------------------------------------------
    # Init
    #-----------------------------------------------------------
    $self->SetIcon( wxTheApp->GetIconBundle->GetIcon(16) );
    $self->LoadFrameLayout;
    $selector->SetValue(0);
    $mainpanel->set_panel_class($selector->get_panel_class(0));
    $self->SetSizeHints(450,350);
    return $self;
}

sub _on_event_selector {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    try {
        my $selector = $event->GetEventObject;
        my $selection = $event->GetSelection;
        my $panelclass = $selector->get_panel_class($selection);
        $self->datapanel->set_panel_class( $panelclass );
    } catch {
        Wx::LogError($_);
        Wx::LogError(t('Failed to select service.'));
    };
}

sub _on_event_refreshpanel {
    my($self, $event) = @_;
    $event->Skip(1);
    my $busy = Wx::BusyCursor->new;
    try {
        $self->datapanel->reload_service;
    } catch {
        Wx::LogError($_);
        Wx::LogError(t('Failed to refresh service.'));
    };
}

1;
