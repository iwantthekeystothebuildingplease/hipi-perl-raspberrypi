#########################################################################################
# Package       HiPi::Apps::Control::Panel::RInfo
# Description:  General Info Panel
# Created       Wed Feb 27 23:09:33 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::Panel::RInfo;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Apps::Control::Panel::Device );
use Wx qw( :sizer :id :misc :textctrl );
use HiPi::Apps::Control::Data::RInfo;
use HiPi::Language;
use Try::Tiny;
use HiPi::Utils;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( list ));

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new($parent);
    
    my $vdata = HiPi::Apps::Control::Data::RInfo->new;
    $self->SetValidationData($vdata);
    
    #------------------------------------------------------
    # Controls
    #------------------------------------------------------
    
    my $list = HiPi::Apps::Control::Panel::RInfo::List->new($self, $vdata);
    
    #------------------------------------------------------
    # Events
    #------------------------------------------------------
    
    #------------------------------------------------------
    # Layout
    #------------------------------------------------------
    my $msizer   = Wx::BoxSizer->new(wxVERTICAL);
    $msizer->Add( $list, 1, wxEXPAND|wxALL, 0);
    $self->SetSizer( $msizer );
    return $self;
}

#########################################################################################

package HiPi::Apps::Control::Panel::RInfo::List;

#########################################################################################
use strict;
use warnings;
use Wx qw( :listctrl :id :misc);
use base qw( Wx::ListCtrl HiPi::Class );

__PACKAGE__->create_accessors( qw( info ) );

sub new {
    my($class, $parent, $vdata) = @_;
    my $self = $class->SUPER::new($parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxLC_REPORT);
    
    # cols name exported mode value reverse interrupt
    $self->InsertColumn(0, '', wxLIST_FORMAT_LEFT, 100);
    $self->InsertColumn(1, '', wxLIST_FORMAT_LEFT, 300);
    
    $self->SetValidator( HiPi::Apps::Control::Panel::RInfo::ListValidator->new($vdata, 'info'));
    
    return $self;
}

#########################################################################################

package HiPi::Apps::Control::Panel::RInfo::ListValidator;

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
    $self->GetWindow->info;
}

sub SetWindowValue {
    my ($self, $data) = @_;
    my $list = $self->GetWindow;
    $list->info($data);
    $list->Freeze;
    $list->DeleteAllItems;
    
    my $index = 0;
    
    for my $key ( qw( Model Memory Manufacturer Release ) )
    {
        my $id = $list->InsertImageStringItem( $index, $key, -1);
        my $dkey = lc($key);
        $list->SetItem($id, 1, $data->{$dkey}, -1 );
        $index ++;
    }
    {
        my $id = $list->InsertImageStringItem( $index, 'GPIO Revision', -1);
        $list->SetItem($id, 1, $data->{revision}, -1 );
        $index ++;
    }
    #{
    #    $list->InsertImageStringItem( $index, '', -1);
    #    $index++;
    #    my $id = $list->InsertImageStringItem( $index, '/proc/cpuinfo', -1);
    #    #$list->SetItem($id, 1, '/proc/cpuinfo', -1 );
    #    $index ++;
    #}
    for my $key ( sort keys( %{ $data->{cpuinfo} } )) {
        next if $key eq 'GPIO Revision';
        my $id = $list->InsertImageStringItem( $index, $key, -1);
        $list->SetItem($id, 1, $data->{cpuinfo}->{$key}, -1 );
        $index ++
    }
    
    
    
    $list->Thaw;
}

1;
