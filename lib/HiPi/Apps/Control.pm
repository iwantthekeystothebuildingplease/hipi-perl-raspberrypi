#########################################################################################
# Package       HiPi::Apps::Control
# Description:  Control RPi Basics
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Wx::App );
use HiPi::Apps::Control::MainWindow;
use Wx qw( :id :bitmap );
use HiPi::BCM2835;
use HiPi;

our $VERSION = '0.26';

__PACKAGE__->create_accessors( qw( devmem ) );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{_hipi_resource_dir} = undef;
    return $self;
}

sub OnSetApplicationDetail {
    my $self = shift;
    $self->SetAppName('hipicontrolgui');
    $self->SetAppDisplayName('HiPi Raspberry Pi Control');
    $self->SetVendorName('markdootson');
    $self->SetVendorDisplayName('Mark Dootson');
    $self->SetClassName('hipictrlguiclass');
    
    $self->copyright('Copyright (c)2013 Mark Dootson');
    $self->description('GUI control for Raspberry Pi GPIO pads and devices');
    $self->version( $HiPi::VERSION );
    $self->supporturl( 'http://raspberrypi.citrusperl.com' );
    
    $self->singleinstance( 1 );
}

sub MainLoop {
    my ( $self ) = @_;
       
    #---------------------
    # Help File
    #---------------------
    
    # for now, we have 'en' help only
    {
        my $helpfile = $self->GetResourceFile('help/en/hipicontrol.hhp');
        
        if(-f $helpfile) {
            $self->GetHelpController->AddBook($helpfile, 0);
        }
    }
    
    #-------------------------------------------------------------
    # Load Standard Icon Bundle
    #-------------------------------------------------------------
    
    {
        my $iconbundle = Wx::IconBundle->new;
        $iconbundle->AddIcon($self->GetResourceFile('image/hipi256.png'), wxBITMAP_TYPE_PNG);
        $iconbundle->AddIcon($self->GetResourceFile('image/hipi128.png'), wxBITMAP_TYPE_PNG);
        $iconbundle->AddIcon($self->GetResourceFile('image/hipi64.png'), wxBITMAP_TYPE_PNG);
        $iconbundle->AddIcon($self->GetResourceFile('image/hipi48.png'), wxBITMAP_TYPE_PNG);
        $iconbundle->AddIcon($self->GetResourceFile('image/hipi32.png'), wxBITMAP_TYPE_PNG);
        $iconbundle->AddIcon($self->GetResourceFile('image/hipi24.png'), wxBITMAP_TYPE_PNG);
        $iconbundle->AddIcon($self->GetResourceFile('image/hipi16.png'), wxBITMAP_TYPE_PNG);
        $self->SetIconBundle( $iconbundle );
    }
    
    #-------------------------------------------------------------
    # Get BCM2835 object
    #-------------------------------------------------------------
    
    $self->devmem( HiPi::BCM2835->new );
    
    #-------------------------------------------------------------
    # Load MainWindow
    #-------------------------------------------------------------
    
    my $mwin = HiPi::Apps::Control::MainWindow->new(undef, wxID_ANY, $self->GetAppDisplayName);
    $self->SetTopWindow($mwin);
    $mwin->Show(1);
    $self->SUPER::MainLoop();
}

sub GetResourceFile {
    my ($self, $file) = @_;
    if( $self->{_hipi_resource_dir} ) {
        return $self->{_hipi_resource_dir} . '/' . $file;
    }
    my $testpath = '';
    for my $incpath ( @INC ) {
        $testpath = qq($incpath/auto/share/dist/HiPi);
        last if -d $testpath;
    }
    $self->{_hipi_resource_dir} = $testpath;
    return $self->{_hipi_resource_dir} . '/' . $file;
}


1;
