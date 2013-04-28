#########################################################################################
# Package       HiPi::Wx::App
# Description:  Base Class For Wx Apps
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::App;

#########################################################################################

use strict;
use warnings;
use Carp;
use HiPi::Utils;

our $VERSION = '0.22';

use Wx qw( wxOK wxCENTRE wxCONFIG_USE_LOCAL_FILE wxID_OK
            wxUPDATE_UI_PROCESS_SPECIFIED :locale wxYES_NO
            wxYES :icon wxID_ANY wxTheApp wxLANGUAGE_USER_DEFINED
            :html wxWINDOW_VARIANT_SMALL wxUPDATE_UI_RECURSE
            :splashscreen wxWS_EX_TRANSIENT
            );

use Wx::Event qw( EVT_QUERY_END_SESSION EVT_END_SESSION
                  EVT_CLOSE EVT_HELP EVT_COMMAND );

use base qw( Wx::App HiPi::Wx::Common HiPi::Class );
use Wx::Help;
use Wx::Html;
use Wx::FS;
use Wx::Locale;
use HiPi::Wx::LogGui;
use HiPi::Language;
use Try::Tiny;

__PACKAGE__->create_accessors( qw( copyright description version supporturl singleinstance ) );

our $_uiupdatepending = 0;
our $HIPI_EVT_ID_DELAYED_STARTUP  = Wx::NewEventType;
our $HIPI_EVT_ID_PROCESS_UIUPDATE = Wx::NewEventType;

sub EVT_HIPI_PROCESS_UIUPDATE ($$$) { $_[0]->Connect( $_[1], wxID_ANY, $HiPi::Wx::App::HIPI_EVT_ID_PROCESS_UIUPDATE, $_[2] ) }

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new();
    return $self->init_hipi_object( %params );
}

#--------------------------------------------------------
# Garbage - if we need to destroy an object inside an
# event handler and our platform / wxWidgets version
# does not like this, just CP::add_to_garbage($obj)
#--------------------------------------------------------


sub OnSingleInstanceRunning {
    my $self = shift;
    my $msg = t('You already have an instance of "%s" running.', $self->GetAppDisplayName);
    $msg .= "\n" . t('You may only run one instance of "%s" at a time.', $self->GetAppDisplayName);
    Wx::MessageBox( $msg, $self->GetAppDisplayName );
    return 0;
}

sub OnDelayedStartupEvent {
    my ( $self, $event ) = @_;
    # Override if you want to do something when the splash
    # screen closes or, if no splash, when app enters
    # MainLoop
}

sub OnSetApplicationDetail {
    # override to set Appname, Vendorname etc
}

sub OnLoadHelpFiles {
    # override to set helpfiles
}

sub OnInit {
    my $self = shift;
    #---------------------------------------------
    # LogTarget
    #---------------------------------------------
    HiPi::Wx::LogGui::SetLogControlClass('HiPi::Wx::LogGui::LogWindowGrid');
    HiPi::Wx::LogGui::EnableLogGui(1);
    
    #---------------------------------------------
    # Initialise Handlers
    #---------------------------------------------
    # handle all images
    Wx::InitAllImageHandlers();
    # we need a zip handler for our help controller
    Wx::FileSystem::AddHandler( Wx::ZipFSHandler->new() );    
    # Handle UI Updates manually
    Wx::UpdateUIEvent::SetMode( wxUPDATE_UI_PROCESS_SPECIFIED );
    Wx::UpdateUIEvent::SetUpdateInterval( -1 ); # manual updates
    
    #---------------------------------------------
    # Set Standard Wx Application Details
    #---------------------------------------------
    
    $self->OnSetApplicationDetail;
    unless( $self->GetClassName ){
        my $classname = join('-', (
                $self->GetVendorName,
                $self->GetAppName,
                ));
        
        $self->SetClassName( $classname );
    }
    
    
    #---------------------------------------------
    # Instance Check
    #---------------------------------------------
    
    if( $self->singleinstance ) {
        # Single Instance Check
        $self->{_hipi_wx_singleinstancecheck} = Wx::SingleInstanceChecker->new();
        $self->{_hipi_wx_singleinstancecheck}->Create( $self->GetClassName ); 
        if ($self->{_hipi_wx_singleinstancecheck}->IsAnotherRunning()) {
            return 0 if !$self->OnSingleInstanceRunning;
        }
    }
    
    #---------------------------------------------
    # Do Splash
    #---------------------------------------------
    
    # $self->OnSplash;# DO NOT PLACE THIS ANY EARLIER
    
    #---------------------------------------------
    # Help Setup
    #---------------------------------------------

    my $helpcontroller = Wx::HtmlHelpController->new( wxHF_DEFAULT_STYLE );
    $helpcontroller->UseConfig( $self->GetConfig() );
    $self->SetHelpController( $helpcontroller );
    $self->OnLoadHelpFiles();
    
    #---------------------------------------------
    # Install Event Handlers
    #---------------------------------------------

    EVT_QUERY_END_SESSION( $self, sub { shift->OnQueryEndSession( @_ ); } );
    EVT_END_SESSION( $self, sub { shift->OnEndSession( @_ ); } );
    EVT_HELP($self, wxID_ANY, sub { $_[0]->OnEventContextHelp( $_[1] ); });
    EVT_HIPI_PROCESS_UIUPDATE( $self, wxID_ANY, sub { $_[0]->_on_event_process_ui_update( $_[1] ); });
    
    $self->SetExitOnFrameDelete(1);
    return 1;
}

#--------------------------------------
# UI Update Handling
#--------------------------------------

sub SendUIUpdate {
    my $self = shift;
    # stop recursive cascading if we contrive to cause it
    # elsewhere in the app
    $_uiupdatepending = 1;
    my $event = Wx::CommandEvent->new( $HIPI_EVT_ID_PROCESS_UIUPDATE, wxID_ANY);
    $self->AddPendingEvent($event);
}

sub _on_event_process_ui_update {
    my( $self, $event) = @_; @_ = ();
    $_uiupdatepending = 0;
    $self->OnBeforeUIUpdate;
    if(my $topwin = $self->GetTopWindow) {
        $topwin->UpdateWindowUI( wxUPDATE_UI_RECURSE );
    }
}

sub OnBeforeUIUpdate { 1 }

sub OnExit {
    my $self = shift;
    $self->GetHelpController->Quit;
    $self->GetConfig->Flush();
}

sub MainLoop {
    my $self = shift;
    if($self->{_hipi_do_startupevent_in_new}) {
        my $newevent = Wx::CommandEvent->new( $HIPI_EVT_ID_DELAYED_STARTUP, -1);
        $newevent->SetInt(0); # splash was not shown
        $self->AddPendingEvent( $newevent );
    }
    $self->SUPER::MainLoop( @_ );
}

#---------------------------------------------------------------
# Custom Properties
#---------------------------------------------------------------
sub SetHelpController { $_[0]->{_hipi_app_help_controller} = $_[1]; }
sub GetHelpController { $_[0]->{_hipi_app_help_controller}; }
sub GetCurrentLocale { $_[0]->{_hipi_app_currentlocale}; }
sub GetIconBundle { $_[0]->{_hipi_app_iconbundle}; }
sub SetIconBundle { $_[0]->{_hipi_app_iconbundle} = $_[1]; }

#---------------------------------------------------------------
# Custom Methods
#---------------------------------------------------------------

sub ShutDown {
    my $self = shift;
    if( my $mwin = $self->GetTopWindow ) {
        $mwin->Close;
    } else {
        $self->ExitMainLoop;
    }
}

sub DisplayHelpTopic {
    my $self = shift;
    $self->GetHelpController->Display( @_ );
}

sub DisplayHelpTopicId {
    my $self = shift;
    $self->GetHelpController->DisplayId( @_ );
}

sub DisplayHelpContents {
    my $self = shift;
    $self->GetHelpController->DisplayContents;
}

sub OnMenuAbout {
    my $self = shift;
    my $info = Wx::AboutDialogInfo->new;
    
    $info->SetName( $self->GetAppDisplayName );
    $info->SetCopyright( $self->copyright ) if $self->copyright;
    $info->SetDescription( $self->description ) if $self->description;
    $info->SetVersion( $self->version ) if $self->version;
    $info->SetWebSite( $self->supporturl ) if $self->supporturl;
    
    if( my $iconbundle = $self->GetIconBundle ) {
        $info->SetIcon( $iconbundle->GetIcon(128) );
    }
    
    Wx::AboutBox( $info );
}

sub OnMenuExit {
    my $self = shift;
    $self->ShutDown;
}
sub OnMenuPreferences {
    my $self = shift;
    Wx::LogMessage(t('This application has not implemented a standard preferences handler.'))
}

sub GetConfig {
    my $self = shift;
    if(!defined($self->{_hipi_app_config}) ) {
        my $localfilename = $self->GetConfigFilePath;
        $self->{_hipi_app_config} = Wx::FileConfig->new( $self->GetAppName() , $self->GetVendorName() ,$localfilename, '', wxCONFIG_USE_LOCAL_FILE );
    }
    return $self->{_hipi_app_config};
}

sub GetAppDataDir {
    my $self = shift;
    my @appdatapaths = ( '.hipiapps', $self->GetVendorName, $self->GetAppName  );
    my $basepath = HiPi::Utils::home_directory();
    my $checkpath = join('/', ( $basepath, @appdatapaths ) );
    return $checkpath if -e $checkpath;
    my $mode = (stat($basepath))[2];
    for my $newdir ( @appdatapaths ) {
        $basepath .= '/' . $newdir;
        unless( -d $basepath ) {
            mkdir( $basepath, $mode );
        }
    }
    return $basepath;
}

sub CreateDataFile {
    my($self, $filename) = @_;
    my $basepath = $self->GetAppDataDir;
    my $filepath  = qq($basepath/$filename);
    return $filepath if -e $filepath;
    open my $fh, '>', $filepath or croak t('failed creating %s : %s', $filepath, $!);
    close($fh);
    return $filepath;
}

sub GetConfigFilePath {
    my $self = shift;
    return $self->CreateDataFile( 'wxapp.config' );
}

sub GetValidTopWindow {
    my $self = shift;
    my $topwindow = wxTheApp->GetTopWindow;
    
    # Check we have a genuine top window
    unless(
        $topwindow &&
        $topwindow->can('AllowHiPiWxLogGuiParent') &&
        $topwindow->AllowHiPiWxLogGuiParent
          )
    {
        $topwindow = undef;
    }
    return $topwindow;
}


#---------------------------------------------
# Event Handlers
#---------------------------------------------

sub OnQueryEndSession {
    my ($self, $event) = @_;
    $event->Skip(1);
}

sub OnEndSession {
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->ShutDown;
}

sub OnEventContextHelp {
    my ($self, $event) = @_;
    $event->Skip(1);
    my $class = ref($self);
    $self->DisplayHelpContents();
}

#--------------------------------------

no warnings;
no strict;

package
   Wx::HtmlHelpFrame;  @ISA = qw( Wx::Frame );

1;

