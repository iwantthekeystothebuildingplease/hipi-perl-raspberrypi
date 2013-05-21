#########################################################################################
# Package       HiPi::Wx::LogGui
# Description:  Custom Log Window
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::LogGui;

#########################################################################################

use strict;
use warnings;
use Wx 0.99 qw( wxTheApp wxICON_HAND );
use UNIVERSAL::require;

require Exporter;
use base qw( Exporter );

our $VERSION = '0.27';

our @EXPORT;
our @EXPORT_OK = qw(
    hpLOGLEVEL_FatalError
    hpLOGLEVEL_Error
    hpLOGLEVEL_Warning
    hpLOGLEVEL_Message
    hpLOGLEVEL_Status
    hpLOGLEVEL_Info
    hpLOGLEVEL_Verbose
    hpLOGLEVEL_Debug
    hpLOGLEVEL_Trace
    hpLOGLEVEL_Progress
    hpLOGLEVEL_User
    hpLOGLEVEL_Max
    
    hpLOGSTATUS_NONE
    hpLOGSTATUS_MESSAGE
    hpLOGSTATUS_WARNING
    hpLOGSTATUS_ERROR
    
    hpLOGLEVEL_TO_TEXT
    
);

# follow Wx convention and add
# our own documented 'loglevel'
# tag

our %EXPORT_TAGS = (
    everything => \@EXPORT_OK,
    all        => \@EXPORT_OK,
    loglevel   => \@EXPORT_OK,
);

sub hpLOGLEVEL_FatalError () { 0 }
sub hpLOGLEVEL_Error      () { 1 }
sub hpLOGLEVEL_Warning    () { 2 }
sub hpLOGLEVEL_Message    () { 3 }
sub hpLOGLEVEL_Status     () { 4 }
sub hpLOGLEVEL_Info       () { 5 }
sub hpLOGLEVEL_Verbose    () { 5 }
sub hpLOGLEVEL_Debug      () { 6 }
sub hpLOGLEVEL_Trace      () { 7 }
sub hpLOGLEVEL_Progress   () { 8 }
sub hpLOGLEVEL_User       () { 100 }
sub hpLOGLEVEL_Max        () { 10000 }

sub hpLOGSTATUS_NONE      () { 0 }
sub hpLOGSTATUS_MESSAGE   () { 1 }
sub hpLOGSTATUS_WARNING   () { 2 }
sub hpLOGSTATUS_ERROR     () { 4 }

sub hpLOGLEVEL_TO_TEXT ($) {
    my $logtext = 'Log';
    if( $_[0] <= hpLOGLEVEL_Error ) {
        $logtext = Wx::GetTranslation('Error');
    } elsif( $_[0] == hpLOGLEVEL_Warning ) {
        $logtext = Wx::GetTranslation('Warning');
    } elsif( $_[0] == hpLOGLEVEL_Message ) {
        $logtext = Wx::GetTranslation('Message');
    } elsif( $_[0] == hpLOGLEVEL_Info ) {
        $logtext = Wx::GetTranslation('Verbose');
    } elsif( $_[0] == hpLOGLEVEL_Debug ) {
        $logtext = Wx::GetTranslation('Debug');
    } elsif( $_[0] == hpLOGLEVEL_Trace ) {
        $logtext = Wx::GetTranslation('Trace');
    } elsif( $_[0] == hpLOGLEVEL_Progress ) {
        $logtext = Wx::GetTranslation('Progress');
    } elsif( $_[0] >= hpLOGLEVEL_User ) {
        $logtext = Wx::GetTranslation('User ' . $_[0]);
    }
    return $logtext;
}

# Frame ID for use with Wx::LogStatus
our $_wxstatusframeid = undef;
# Buffer for Log lines
our $_wxlogbuffer =  [];
# Track cumulative log status of all our buffer lines
our $_wxlogstatus = hpLOGSTATUS_NONE;
# Track our state
our $_wxlogenabled = 0;
# Hang on to reference for log we replaced
# so that we can restore it
our $_wxrestorelog;
# The class we use to displat the log lines
our $_wxdisplayclass = 'HiPi::Wx::LogGui::LogWindowListCtrl';


# we need to override Wx::LogStatus so that we can know the status frame
# This implementation is based on internal wxLogGui implementation

sub _GuiLogStatus {
    my( $t );
    
    if( ref( $_[0] ) && $_[0]->isa( 'Wx::Frame' ) ) {
        my( $f ) = shift;
        $HiPi::Wx::LogGui::wxstatusframeid = $f->GetId;
        $t = sprintf( shift, @_ );
        $t =~ s/\%/\%\%/g; Wx::wxLogStatusFrame( $f, $t );
        $HiPi::Wx::LogGui::wxstatusframeid = undef;
    } else {
        $t = sprintf( shift, @_ ); $t =~ s/\%/\%\%/g; Wx::wxLogStatus( $t );
    }
}

{
    # replace standard LogStatus with our own
    no warnings;
    *Wx::LogStatus = \&HiPi::Wx::LogGui::_GuiLogStatus;
}

sub _is_main_thread {
    no warnings;
    return ( $threads::threads && ( threads->tid != 0 ) ) ? 0 : 1;
}

sub SetLogControlClass { $_wxdisplayclass = $_[0]; }

sub GetLogControlClass { $_wxdisplayclass; }

sub EnableLogGui {
    my $enable = shift;
    return if !_is_main_thread();
    
    $enable = 1 if(!defined($enable));
    return if $enable == $_wxlogenabled;
    
    Wx::Log::GetActiveTarget->Flush();
    _clear_logs();
    
    if( $enable ) {
        $_wxrestorelog = Wx::Log::SetActiveTarget( HiPi::Wx::LogGui::Logger->new() );
    } else {
        my $droplog = Wx::Log::SetActiveTarget( $_wxrestorelog );
        $droplog->Destroy if $droplog->can('Destroy');
    }
    $_wxlogenabled = $enable;
}

sub LogExitMainLoop {
    Wx::Log::SetActiveTarget( $_wxrestorelog );
}

sub DisableLogGui { EnableLogGui(0); }

sub _clear_logs {
    return if !_is_main_thread();
    $_wxlogbuffer =  [];
    $_wxlogstatus = hpLOGSTATUS_NONE;
}

sub _do_thread_log {
    my($logger, $loglevel, $message, $timestamp) = @_;
    if($loglevel <= hpLOGLEVEL_Warning) {
        print STDERR $message . qq(\n);
    } elsif( $loglevel ==  hpLOGLEVEL_Info ) {
        if( $logger->GetVerbose ) { print STDOUT $message . qq(\n); }
    } else {
        print STDOUT $message . qq(\n);
    }
}

sub _do_log {
    my($logger, $loglevel, $message, $timestamp) = @_;
    
    if( !_is_main_thread() ) {
        _do_thread_log( $logger, $loglevel, $message, $timestamp );
        return;
    }
    
    if( $loglevel ==  hpLOGLEVEL_FatalError ) {
        Wx::MessageBox($message, 'Fatal Error', wxICON_HAND);
        wxTheApp->ExitMainLoop;
        
    } elsif( $loglevel ==  hpLOGLEVEL_Error ) {
        
        push( @$_wxlogbuffer, [ $loglevel, $message, $timestamp ] );
        $_wxlogstatus = $_wxlogstatus | hpLOGSTATUS_ERROR;
        
    } elsif( $loglevel ==  hpLOGLEVEL_Warning ) {
        
        push( @$_wxlogbuffer, [ $loglevel, $message, $timestamp ] );
        $_wxlogstatus = $_wxlogstatus | hpLOGSTATUS_WARNING;
        
    } elsif( $loglevel ==  hpLOGLEVEL_Status ) {
        
        my $statusframe;
        $statusframe = Wx::Window::FindWindowById($_wxstatusframeid, undef) if defined($_wxstatusframeid);
        $statusframe = wxTheApp->GetTopWindow() if(!$statusframe );
        
        if($statusframe && $statusframe->isa('Wx::Frame') && $statusframe->GetStatusBar) {
            $statusframe->SetStatusText( $message );
        }
        
    } elsif(
           ( $loglevel ==  hpLOGLEVEL_Message )
        || ( ( $loglevel ==  hpLOGLEVEL_Info ) && Wx::Log::GetVerbose )
           ) {
        
        push( @$_wxlogbuffer, [ $loglevel, $message, $timestamp ] );
        $_wxlogstatus = $_wxlogstatus | hpLOGSTATUS_MESSAGE;
    
    }
}

sub _flush {
    my $logger = shift;
    my $logstatus = $_wxlogstatus;
    my @logbuffer = @$_wxlogbuffer;
    _clear_logs();
    
    return if !$logstatus;
    return if ! scalar @logbuffer;
    
    Wx::Log::Suspend();
    
    my $dialog = HiPi::Wx::LogGui::LogDialog->new( $logstatus, \@logbuffer);
    $dialog->ShowModal();
    $dialog->Close;
    $dialog->Destroy;
    
    Wx::Log::Resume();
}

sub __keep_packagers_happy {
    require HiPi::Wx::LogGui::LogWindowGrid;
    require HiPi::Wx::LogGui::LogWindowListCtrl;
}

#-------------------------------------------------------------------

package HiPi::Wx::LogGui::Logger;

#-------------------------------------------------------------------
use strict;
use warnings;
use Wx;
use base qw( Wx::PlLog );

our $VERSION = '0.01';

sub new { shift->SUPER::new( @_ ) }

sub DoLog { HiPi::Wx::LogGui::_do_log( @_ ); }

sub Flush { HiPi::Wx::LogGui::_flush( @_ ); }

#-------------------------------------------------------------------

package HiPi::Wx::LogGui::LogDialog;

#-------------------------------------------------------------------

use strict;
use warnings;
use Wx::DND;
use Wx qw( wxTheApp :id :misc :dialog :window :icon :sizer :colour wxTheClipboard :panel :filedialog wxSYS_DEFAULT_GUI_FONT);
use Wx::ArtProvider qw( :artid :clientid );
use Wx::Event qw( EVT_BUTTON );
HiPi::Wx::LogGui->import( qw( :all ) );

use base qw( Wx::Dialog );

our $VERSION = '0.02';

sub new {
    my ($class, $logstatus, $logbuffer) = @_;
    
    my $wxlogparent = wxTheApp->GetValidTopWindow;
    unless( $wxlogparent && $wxlogparent->IsShown ) {
        $wxlogparent = undef;
    }
    
    my $style = wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER ;
    
    my $self = $class->SUPER::new($wxlogparent, wxID_ANY, wxTheApp->GetAppName, wxDefaultPosition, wxDefaultSize, $style);
    
    #--------------------------
    # Data
    #--------------------------
    
    $self->{_wxplg_logbuffer} = $logbuffer;
    $self->{_wxplg_logstatus} = $logstatus;
    $self->{_wxplg_logcontrol} = undef;
    $self->{_wxplg_logcontrol_expanded} = 0;
    
    my $msgtext = Wx::GetTranslation( $logbuffer->[-1]->[1] );
    if(length($msgtext) > 750) {
        $msgtext = substr($msgtext,0,750) . ' .....';
    }
    
    my ($bitmap, $titlesuffix);
    if( ($logstatus & hpLOGSTATUS_ERROR()) == hpLOGSTATUS_ERROR() ) {
        $bitmap = Wx::ArtProvider::GetBitmap(wxART_ERROR, wxART_MESSAGE_BOX);
        $titlesuffix = Wx::GetTranslation('Error');
    } elsif( ($logstatus & hpLOGSTATUS_WARNING()) == hpLOGSTATUS_WARNING() ) {
        $bitmap = Wx::ArtProvider::GetBitmap(wxART_WARNING, wxART_MESSAGE_BOX);
        $titlesuffix = Wx::GetTranslation('Warning');
    } else {
        $bitmap = Wx::ArtProvider::GetBitmap(wxART_INFORMATION, wxART_MESSAGE_BOX);
        $titlesuffix = Wx::GetTranslation('Information');
    }
    
    $self->SetTitle( wxTheApp->GetAppName . ' ' . $titlesuffix );
    
    my $messagewidth;
    
    {
        my $minwidth = 200;
        my $maxwidth = 400;
        my $dc = Wx::ClientDC->new($self);
        my( $w, $h, $d, $e ) = $dc->GetTextExtent( $msgtext, Wx::SystemSettings::GetFont(wxSYS_DEFAULT_GUI_FONT ) );
        $messagewidth = ( $w < $minwidth ) ? $minwidth : ( $w > $maxwidth ) ? $maxwidth : $w + 6;
    }
    
    #---------------------
    # controls
    #---------------------
    
    my $msgpanel = Wx::Panel->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxBORDER_NONE );
    $msgpanel->SetBackgroundColour( wxWHITE );
    
    my $staticbitmap = Wx::StaticBitmap->new($msgpanel, -1, $bitmap);
    my $messagelabel = Wx::StaticText->new($msgpanel, -1, $msgtext, wxDefaultPosition, [$messagewidth, -1]);
    $messagelabel->Wrap( $messagewidth );
    
    $self->{buttonok}      = Wx::Button->new($self, wxID_OK, Wx::GetTranslation('OK'));
    $self->{buttondetails} = Wx::Button->new($self, -1, Wx::GetTranslation('Details') . ' >>');
    $self->{buttonsave}    = Wx::Button->new($self, -1, Wx::GetTranslation('Save'));
    $self->{buttoncopy}    = Wx::Button->new($self, -1, Wx::GetTranslation('Copy'));
    
    $self->{buttonsave}->Show(0);
    $self->{buttoncopy}->Show(0);
    
    #---------------------
    # Events
    #---------------------
    
    EVT_BUTTON($self, $self->{buttondetails}, sub { shift->OnButtonDetails( @_ ); });
    EVT_BUTTON($self, $self->{buttoncopy}, sub { shift->OnButtonCopy( @_ ); });
    EVT_BUTTON($self, $self->{buttonsave}, sub { shift->OnButtonSave( @_ ); });
    
    #---------------------
    # Layout
    #---------------------
    my $margin = 20;
    my $topsizer = Wx::BoxSizer->new(wxVERTICAL);
    my $mainsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $panelsizer = Wx::BoxSizer->new(wxVERTICAL);
    
    $mainsizer->Add($staticbitmap, 0, wxALIGN_CENTRE_VERTICAL);
    
    my $textsizer = Wx::BoxSizer->new(wxVERTICAL);
    $textsizer->Add($messagelabel, 0, wxEXPAND|wxALL, 0);
    
    $mainsizer->Add($textsizer, 1, wxALIGN_CENTRE_VERTICAL | wxLEFT | wxRIGHT, $margin);
    
    $panelsizer->Add($mainsizer, 0, wxEXPAND| wxALL, $margin);
    
    $msgpanel->SetSizer($panelsizer);
    
    $topsizer->Add($msgpanel, 0, wxEXPAND| wxALL, 0);
    
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $buttonsizer->AddStretchSpacer(1);
    $buttonsizer->Add($self->{buttonok},0,wxEXPAND|wxALL, 0);
    $buttonsizer->Add($self->{buttondetails},0,wxEXPAND|wxLEFT, 5);
    
    $topsizer->Add($buttonsizer, 0, wxEXPAND|wxALL, $margin / 2);
    
    $self->SetSizerAndFit($topsizer);
    
    #my $dialogsize = $mainsizer->Fit($self);
    {
        $self->SetSizeHints($self->GetSizeWH);
    }

    $self->{margin} = $margin;
    $self->{buttonok}->SetFocus;
    $self->CentreOnParent;
    
    return $self;
}

sub get_logbuffer { $_[0]->{_wxplg_logbuffer}; }
    
sub get_logstatus { $_[0]->{_wxplg_logstatus}; }

sub OnButtonDetails {
    my($self, $event) = @_;
    
    my $busy = Wx::BusyCursor->new();
    
    if( $self->{_wxplg_logcontrol_expanded} ) {
        
        my $buttonsizer = $self->{buttoncopy}->GetContainingSizer;
        
        $buttonsizer->Detach($self->{buttoncopy});
        $self->{buttoncopy}->Show(0);
        
        $buttonsizer->Detach($self->{buttonsave});
        $self->{buttonsave}->Show(0);
        
        $self->GetSizer->Remove($buttonsizer);
        
        $self->GetSizer->Detach($self->{_wxplg_logcontrol});
        $self->{_wxplg_logcontrol}->Show(0);
        
        $self->{_wxplg_logcontrol_expanded} = 0;
        $self->{buttondetails}->SetLabel(Wx::GetTranslation('Details') . ' >>');
    } else {
        if( !$self->{_wxplg_logcontrol} ) {
            $HiPi::Wx::LogGui::_wxdisplayclass->require;
            my $callcommand = $HiPi::Wx::LogGui::_wxdisplayclass . '::CreateLogControl';
            no strict;
            $self->{_wxplg_logcontrol} = &$callcommand($self, $self->get_logbuffer, $self->get_logstatus);
        }
        
        $self->GetSizer->Add($self->{_wxplg_logcontrol}, 1, wxLEFT|wxRIGHT|wxEXPAND, $self->{margin} / 2 );
        $self->{_wxplg_logcontrol}->Show(1);
        
        my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
        
        $buttonsizer->Add($self->{buttonsave}, 0, wxEXPAND|wxRIGHT, 3 );
        $self->{buttonsave}->Show(1);
        
        $buttonsizer->Add($self->{buttoncopy}, 0, wxEXPAND|wxLEFT,3 );
        $self->{buttoncopy}->Show(1);
        
        $self->GetSizer->Add($buttonsizer, 0, wxALL|wxALIGN_RIGHT, $self->{margin} / 2 );
        
        $self->{_wxplg_logcontrol_expanded} = 1;
        $self->{buttondetails}->SetLabel('<< ' . Wx::GetTranslation('Details'));
    }
    $self->SetSizerAndFit($self->GetSizer);
    $self->{_wxplg_logcontrol}->Refresh if $self->{_wxplg_logcontrol_expanded};
}

sub OnButtonCopy {
    my($self, $event) = @_;
    my $text = $self->get_formatted_text;
    wxTheClipboard->Open;
    wxTheClipboard->SetData( Wx::TextDataObject->new($text) );
    wxTheClipboard->Close;
}

sub OnButtonSave {
    my($self, $event) = @_;
    
    my $filepath = undef;
    my $dialog = Wx::FileDialog->new
    (
        $self,
        Wx::GetTranslation('Select a file'),
        '',
        'log.txt',
        ( join '|', 'Text files (*.txt)|*.txt', 'All files (*.*)|*.*' ),
        wxFD_OVERWRITE_PROMPT|wxFD_SAVE,
    );
    
    if( $dialog->ShowModal != wxID_CANCEL ) {
        $filepath = $dialog->GetPath();
    }
    return if !$filepath;
    
    my $text = $self->get_formatted_text;
    
    try {
        open my $fh, '>', $filepath;
        print $fh $text;
        close($fh);
    } catch {
        Wx::LogError( $_ );
    };

}

sub get_formatted_text {
    my $self = shift;
    my $text = '';
    for my $logline ( @{ $self->get_logbuffer } ) {
        $text .= _long_time_format($logline->[2]) . ' : ' . hpLOGLEVEL_TO_TEXT($logline->[0]) . ' : ' . Wx::GetTranslation( $logline->[1] ) . qq(\n);
    }
    return $text;
}

sub _long_time_format {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($_[0]);
    $year += 1900;
    $mon ++;
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
}


1;

