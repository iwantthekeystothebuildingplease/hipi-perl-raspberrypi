#########################################################################################
# Package       HiPi::Wx::LogGui::LogWindowListCtrl
# Description:  ListCtrl Log Target
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::LogGui::LogWindowListCtrl;

#########################################################################################

use strict;
use warnings;
use Wx qw( :listctrl :misc :window :id :imagelist);
use HiPi::Wx::LogGui qw( :all );
use Wx::ArtProvider qw( :artid :clientid );
use Wx::Event qw( EVT_LIST_ITEM_SELECTED );

our $VERSION = '0.27';

sub CreateLogControl {
    my($parent, $logbuffer, $logstatus) = @_;
    
    my $listctrl = Wx::ListCtrl->new($parent, wxID_ANY,
                                wxDefaultPosition, [-1, 150],
                                wxSUNKEN_BORDER |
                                wxLC_REPORT |
                                wxLC_NO_HEADER |
                                wxLC_SINGLE_SEL);
    
    $listctrl->InsertColumn(0,'Log Level');
    $listctrl->InsertColumn(1,'Message');
    $listctrl->InsertColumn(2,'Time');
    
    my $iconsize = 16;
    
    my $imagelist = Wx::ImageList->new($iconsize, $iconsize);

    my @icontypes = (
        wxART_ERROR,
        wxART_WARNING,
        wxART_INFORMATION
    );
    
    my $iconsloaded = 1;

    for my $itype ( @icontypes ) {
        my $bitmap = Wx::ArtProvider::GetBitmap($itype, wxART_MESSAGE_BOX, Wx::Size->new($iconsize,$iconsize) );
        
        if(!$bitmap->Ok) {
            $iconsloaded = 0;
            last;
        }

        $imagelist->Add($bitmap);
    }

    $listctrl->AssignImageList($imagelist, wxIMAGE_LIST_SMALL);
    
    my $timeformat = "%c";
        
    my $itemindex = 0;
    for my $logline ( @$logbuffer ) {
        
        my $imgidx;
        
        if ( $iconsloaded ) {
            if( $logline->[0] <= hpLOGLEVEL_Error ) {
                $imgidx = 0;
            } elsif(  $logline->[0] == hpLOGLEVEL_Warning ) {
                $imgidx = 1;
            } else {
                default:
                $imgidx = 2;
            }
        }  else  {
            $imgidx = -1;
        }
        
        my $logtext = hpLOGLEVEL_TO_TEXT($logline->[0]);
        
        $listctrl->InsertImageStringItem( $itemindex, $logtext, $imgidx );
        $listctrl->SetItem($itemindex, 1, Wx::GetTranslation($logline->[1]) );
        $listctrl->SetItem($itemindex, 2, _time_format( $logline->[2] ) );
    }
    
    $listctrl->SetColumnWidth(0, wxLIST_AUTOSIZE);
    $listctrl->SetColumnWidth(1, wxLIST_AUTOSIZE);
    $listctrl->SetColumnWidth(2, wxLIST_AUTOSIZE);
    
    EVT_LIST_ITEM_SELECTED( $listctrl, $listctrl,
        sub {
            my($listself, $event) = @_;
            $listself->SetItemState( $event->GetIndex(), 0, wxLIST_STATE_SELECTED);   
        }
    );
    
    return $listctrl;
}

sub _time_format {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($_[0]);
    return sprintf("%02d:%02d:%02d", $hour, $min, $sec);
}


1;
