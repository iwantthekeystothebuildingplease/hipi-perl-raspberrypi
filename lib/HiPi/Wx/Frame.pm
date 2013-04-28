#########################################################################################
# Package       HiPi::Wx::Frame
# Description:  Base Class For Wx Frames
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Frame;

#########################################################################################

use strict;
use warnings;
use Wx qw( wxTheApp :id :window :misc :frame :statusbar :bitmap);
use Wx::Event qw( EVT_CLOSE EVT_MENU EVT_UPDATE_UI );
use HiPi::Wx::TopLevelWindow;
use base qw( Wx::Frame HiPi::Wx::TopLevelWindow );

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( savelayout nostatusbar ));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->SetTitle( wxTheApp->GetAppDisplayName ) if !$self->GetTitle();
    $self->SetExtraStyle( $self->GetExtraStyle | wxWS_EX_PROCESS_UI_UPDATES | wxWS_EX_VALIDATE_RECURSIVELY );
    unless( $self->nostatusbar ) {
        $self->SetStatusBar( Wx::StatusBar->new($self, wxID_ANY, wxST_SIZEGRIP) );
        EVT_UPDATE_UI($self, $self->GetStatusBar, sub { $_[0]->OnEventUpdateStatusBarUI( $_[1] ); } );
    }
    EVT_CLOSE($self, sub { $_[0]->OnEventClose( $_[1] ); } );
    EVT_UPDATE_UI($self, $self, sub { $_[0]->OnEventUpdateFrameUI( $_[1] ); } );
    return $self;
}

sub Show {
    my ($self, $show) = @_;
    $show = 1 if !defined($show);
    $self->UpdateWindowUI(wxUPDATE_UI_RECURSE) if($show);
    $self->SUPER::Show($show);
}

#------------------------------------------------------------
# Close Events
#------------------------------------------------------------

sub OnEventClose {
    my ($self, $event) = @_;
    my $canveto = $event->CanVeto;
    if( $self->QueryEventClose )  {
        $event->Skip(1);
        $self->SaveFrameLayout() if($self->savelayout());
        $self->Destroy;
    } else {
        if($canveto) {
            $event->Skip(0);
            $event->Veto(1);
        } else {
            $event->Skip(1);
            $self->SaveFrameLayout() if($self->savelayout());
            $self->Destroy;
        }
    }
}

sub QueryEventClose {
    my ($self, $event) = @_;   
    return 1;
}

#------------------------------------------------------------
# Common UI Update Events
#------------------------------------------------------------

sub OnEventUpdateFrameUI {
    my ($self, $event) = @_;
    $event->Skip(0);
}

sub OnEventUpdateStatusBarUI {
    my ($self, $event) = @_;
    $event->Skip(0);
}

#------------------------------------------------------------
# Layout Save / Load Methods
#------------------------------------------------------------

sub SaveFrameLayout {
    my $self = shift;
    my $winrect = $self->GetRect();
    my ($width, $height) = $self->GetSizeWH ;
    my $idkey = '/' . $self->GetName();
    my $config = wxTheApp->GetConfig;
    $config->Write($idkey . '/position/left',$winrect->x);
    $config->Write($idkey . '/position/top',$winrect->y);
    $config->Write($idkey . '/position/width',$width);
    $config->Write($idkey . '/position/height',$height);
    $config->Write($idkey . '/position/saved','1');
}

sub LoadFrameLayout {
    my $self = shift;
    $self->savelayout(1);
    my $minsize = $self->GetMinSize;
    my $config = wxTheApp->GetConfig;
    my $idkey = '/' . $self->GetName();
    my $left = $config->Read($idkey . '/position/left','0');
    my $top = $config->Read($idkey . '/position/top','0');
    my $width = $config->Read($idkey . '/position/width','500');
    my $height = $config->Read($idkey . '/position/height','400');
    my $saved = $config->Read($idkey . '/position/saved',0);
    
    $width = $minsize->GetWidth if ( $width < $minsize->GetWidth );
    $height = $minsize->GetHeight if ( $height < $minsize->GetHeight );

    $self->SetSize($left, $top, $width, $height);
    $self->Centre if(!$saved);
}


1;
