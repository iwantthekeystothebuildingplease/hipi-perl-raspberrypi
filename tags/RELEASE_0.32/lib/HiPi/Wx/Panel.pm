#########################################################################################
# Package       HiPi::Wx::Panel
# Description:  Panel with validation super powers
# Created       Tue Feb 26 04:50:05 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Panel;

#########################################################################################
use strict;
use warnings;
use HiPi::Class;
use Wx qw( :id :misc :panel :window );
use base qw( Wx::Panel HiPi::Class);

our $VERSION = '0.22';

__PACKAGE__->create_both_accessors( qw( ValidationData ) );

sub new {
    my $class = shift;
    # $_[0] must be parent
    $_[1] = wxID_ANY if not exists $_[1];
    $_[2] = wxDefaultPosition if not exists $_[2];
    $_[3] = wxDefaultSize if not exists $_[3];
    $_[4] = wxTAB_TRAVERSAL|wxBORDER_NONE if not exists $_[4];
    my $self = $class->SUPER::new( @_ );
    $self->SetExtraStyle( $self->GetExtraStyle | &Wx::wxWS_EX_PROCESS_UI_UPDATES | &Wx::wxWS_EX_VALIDATE_RECURSIVELY );
    return $self;
}

sub InitValidatedPanel {
    my $self = shift;
    if(my $vdata = $self->GetValidationData) {
        $vdata->load_data;
    }
    $self->TransferDataToWindow;
}

sub WriteValidatedPanel {
    my $self = shift;
    my $rval = 0;
    if($self->Validate && $self->TransferDataFromWindow ) {
        if( my $vdata = $self->GetValidationData ) {
            $rval = $vdata->flush_if_dirty;
        } else {
            $rval = 1; # default if we have no vdata
        }
    }
    return $rval;
}

sub RefreshValidatedPanel {
    my ($self) = @_;
    $self->WriteValidatedPanel;
    $self->InitValidatedPanel;
}

1;
