#########################################################################################
# Package       HiPi::Wx::Dialog
# Description:  Base Class For Wx Dialogs
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Dialog;

#########################################################################################

use strict;
use warnings;
use Wx qw( wxTheApp :id :window :misc :frame :dialog :bitmap);
use Wx::Event qw( EVT_CLOSE EVT_MENU EVT_UPDATE_UI );
use HiPi::Wx::TopLevelWindow;
use base qw( Wx::Dialog HiPi::Wx::TopLevelWindow );

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( savelayout nostatusbar ));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->SetTitle( wxTheApp->GetAppDisplayName ) if !$self->GetTitle();
    $self->SetExtraStyle( $self->GetExtraStyle | wxWS_EX_PROCESS_UI_UPDATES | wxWS_EX_VALIDATE_RECURSIVELY );
    EVT_CLOSE($self, sub { $_[0]->OnEventClose( $_[1] ); } );
    EVT_UPDATE_UI($self, $self, sub { $_[0]->OnEventUpdateDialogUI( $_[1] ); } );
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
        $self->Destroy;
    } else {
        if($canveto) {
            $event->Skip(0);
            $event->Veto(1);
        } else {
            $event->Skip(1);
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

sub OnEventUpdateDialogUI {
    my ($self, $event) = @_;
    $event->Skip(0);
}

1;
