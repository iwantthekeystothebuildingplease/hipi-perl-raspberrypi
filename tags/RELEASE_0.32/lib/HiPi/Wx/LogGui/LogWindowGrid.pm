#########################################################################################
# Package       HiPi::Wx::LogGui::LogWindowGrid
# Description:  Grid Log Target
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::LogGui::LogWindowGrid;

#########################################################################################

use strict;
use warnings;
use Wx qw( :listctrl :misc :window :id :imagelist :grid wxWANTS_CHARS wxSYS_DEFAULT_GUI_FONT);
use Wx::ArtProvider qw( :artid :clientid );
use Wx::Grid;
use Wx::Event qw( EVT_SIZE EVT_GRID_RANGE_SELECT EVT_GRID_SELECT_CELL );
use HiPi::Wx::LogGui qw( :all );

our $VERSION = '0.27';

our $bitmapartsize = [16,16];
our $textmargin    = 10;

sub CreateLogControl {
    my($parent, $logbuffer, $logstatus) = @_;
    
    my $ctrlmargin = 
    
    # give a position to constructor that is outside the visible area of the dialog
    # to prevent drawing / composing flicker
    
    my $grid = Wx::Grid->new($parent, wxID_ANY, [1000,1000],[-1, 150 ], wxBORDER_SIMPLE );
    
    $grid->CreateGrid(scalar(@$logbuffer), 3);
    
    $grid->SetColLabelSize(0);
    $grid->SetRowLabelSize(0);
    $grid->EnableGridLines(0);
    $grid->SetFont( Wx::SystemSettings::GetFont(wxSYS_DEFAULT_GUI_FONT ) );
    
    {
        my $dc = Wx::ClientDC->new($grid);
        my( $w, $h, $d, $e ) = $dc->GetTextExtent('Progress 100', Wx::SystemSettings::GetFont(wxSYS_DEFAULT_GUI_FONT ) ); 
        $grid->{col0width} = $w + $bitmapartsize->[0] + $textmargin;
        ( $w, $h, $d, $e ) = $dc->GetTextExtent('00:00:00', Wx::SystemSettings::GetFont(wxSYS_DEFAULT_GUI_FONT ) );
        $grid->{col2width} = $w + $textmargin;
    }
    
    my $itemindex = 0;
    
    my $loglevelrenderer = HiPi::Wx::LogGui::LogWindowGrid::LogLevelRenderer->new;
    my $wraprenderer     = Wx::GridCellAutoWrapStringRenderer->new;
    my $timerenderer     = HiPi::Wx::LogGui::LogWindowGrid::TimeStampRenderer->new;
     
    for my $logline ( @$logbuffer ) {        
        $grid->SetCellRenderer($itemindex, 0, $loglevelrenderer );
        $grid->SetCellValue($itemindex, 0, $logline->[0]);
        $grid->SetReadOnly($itemindex, 0);
        
        my $logmessage = $logline->[1];
        
        # we need a limit to message length or wrapping may take
        # a very long time on some platforms
        
        if(length($logmessage) > 5000) {
            $logmessage = substr($logmessage, 0, 5000) . ' ...';
        }
        
        $grid->SetCellRenderer($itemindex, 1, $wraprenderer);
        $grid->SetCellValue($itemindex, 1, $logmessage);
        $grid->SetReadOnly($itemindex, 1);
        
        $grid->SetCellRenderer($itemindex, 2,  $timerenderer);
        $grid->SetCellValue($itemindex, 2, $logline->[2]);
        $grid->SetReadOnly($itemindex, 2);
        
        $grid->AutoSizeRow($itemindex, 0);
        $itemindex ++;
    }

    $grid->EnableCellEditControl(0);
    
    # prevent selection
    EVT_GRID_SELECT_CELL ( $grid, sub { $_[1]->Veto; } );
    EVT_GRID_RANGE_SELECT( $grid, sub { $_[1]->Veto; } );
    
    EVT_SIZE($grid, sub {
        my( $gobj, $event) = @_;
        my($width, $height) = $gobj->GetClientSizeWH;
        
        my $avaliable = $width - ( $gobj->{col0width} + $gobj->{col2width} );
        
        $gobj->SetColSize(0, $gobj->{col0width});
        $gobj->SetColSize(1, $avaliable);
        $gobj->SetColSize(2, $gobj->{col2width});
        
        for (my $i = 0; $i < $gobj->GetNumberRows; $i++) {
            $gobj->AutoSizeRow($i, 0);
        }
        
        $gobj->ForceRefresh;
    });
    
    return $grid;
}

#-------------------------------------------------------------

package HiPi::Wx::LogGui::LogWindowGrid::TimeStampRenderer;

#-------------------------------------------------------------

use strict;
use warnings;
use Wx qw(wxBLACK_PEN wxWHITE_BRUSH wxSYS_DEFAULT_GUI_FONT wxWHITE_PEN);
use Wx::Grid;
use base qw( Wx::PlGridCellRenderer );

sub new { shift->SUPER::new( @_ ); }

sub Draw {
    my( $self, $grid, $attr, $dc, $rect, $row, $col, $sel ) = ( shift, @_ );
    
    # draw standard background etc.
    $self->SUPER::Draw( $grid, $attr, $dc, $rect, $row, $col, $sel );
    
    $dc->SetPen( wxBLACK_PEN );
    $dc->SetBrush( wxWHITE_BRUSH );
    $dc->SetFont(Wx::SystemSettings::GetFont(wxSYS_DEFAULT_GUI_FONT ));
    
    $rect->Deflate( 2,2 );

    my $text = $self->_time_format($grid->GetCellValue( $row, $col ));

    $dc->DrawLabel( $text, $rect );
}

sub Clone { $_[0]->new(); }


sub _time_format {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($_[1]);
    return sprintf("%02d:%02d:%02d", $hour, $min, $sec);
}

#-------------------------------------------------------------

package HiPi::Wx::LogGui::LogWindowGrid::LogLevelRenderer;

#-------------------------------------------------------------

use strict;
use warnings;
use Wx qw(wxBLACK_PEN wxWHITE_BRUSH wxSYS_DEFAULT_GUI_FONT wxWHITE_PEN);
use Wx::Grid;
use Wx::ArtProvider qw( :artid :clientid );
use HiPi::Wx::LogGui qw( :all );

use base qw( Wx::PlGridCellRenderer );

sub new { shift->SUPER::new( @_ ); }

sub Draw {
    my( $self, $grid, $attr, $dc, $rect, $row, $col, $sel ) = ( shift, @_ );
    
    # draw standard background etc.
    $self->SUPER::Draw( $grid, $attr, $dc, $rect, $row, $col, $sel );
    
    $dc->SetPen( wxBLACK_PEN );
    $dc->SetBrush( wxWHITE_BRUSH );
    $dc->SetFont(Wx::SystemSettings::GetFont(wxSYS_DEFAULT_GUI_FONT ));

    $rect->Deflate( 2,2 );
    
    my $loglevel = $grid->GetCellValue( $row, $col );
    
    my $itype;
    if( $loglevel <= hpLOGLEVEL_Error ) {
        $itype = wxART_ERROR;
    } elsif(  $loglevel == hpLOGLEVEL_Warning ) {
        $itype = wxART_WARNING;
    } elsif(  $loglevel == hpLOGLEVEL_Message ) {
        $itype = wxART_INFORMATION;
    } else {
        $itype = wxART_QUESTION;
    }
    
    my $logtext = hpLOGLEVEL_TO_TEXT( $loglevel );
    
    my $bitmap = Wx::ArtProvider::GetBitmap($itype, wxART_MESSAGE_BOX, $HiPi::Wx::LogGui::LogWindowGrid::bitmapartsize );
    
    $dc->DrawLabel( $logtext , $bitmap, $rect );
}

sub Clone { $_[0]->new(); }

1;
