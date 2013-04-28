#########################################################################################
# Package       HiPi::Wx::Common
# Description:  Base Class For Wx Apps
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Common;
use strict;
use warnings;
use HiPi::Language;

our $VERSION = '0.22';

use Wx qw( wxOK wxICON_ERROR wxOK wxICON_INFORMATION wxYES_NO wxICON_QUESTION wxYES
           wxICON_EXCLAMATION wxICON_WARNING wxICON_HAND
           wxDD_DEFAULT_STYLE wxDD_DIR_MUST_EXIST wxFD_OPEN wxFD_FILE_MUST_EXIST wxID_CANCEL
           wxFD_MULTIPLE wxFD_OVERWRITE_PROMPT wxFD_SAVE wxTheApp wxCENTRE);

require Exporter;
use base qw( Exporter );

sub _get_parent_for_dialog {
    my $self = shift;
    my $parent;
    if( $self->isa('Wx::App') ) {
        $parent = undef;
    } elsif( $self->isa('Wx::Dialog') || $self->isa('Wx::Frame') ) {
        $parent = $self;
    } else {
        $parent = Wx::GetTopLevelParent( $self ) or undef;
    }
    return $parent;
}

sub WaitForError {
    my ($self, $msg, $title) = @_;
    $title ||= wxTheApp->GetAppDisplayName();
    Wx::MessageBox($msg, $title, wxOK|wxICON_ERROR, $self->_get_parent_for_dialog);
}

sub WaitForExclamation {
    my ($self, $msg, $title) = @_;
    $title ||= wxTheApp->GetAppDisplayName();
    Wx::MessageBox($msg, $title, wxOK|wxICON_EXCLAMATION, $self->_get_parent_for_dialog);
}

sub MessageBox { shift->WaitForMessage( @_ ); }

sub WaitForMessage {
    my ($self, $msg, $title) = @_;
    $title ||= wxTheApp->GetAppDisplayName();
    Wx::MessageBox($msg, $title, wxOK|wxICON_INFORMATION, $self->_get_parent_for_dialog);
}

sub WaitForWarning {
    my ($self, $msg, $title) = @_;
    $title ||= wxTheApp->GetAppDisplayName();
    Wx::MessageBox($msg, $title, wxOK|wxICON_WARNING, $self->_get_parent_for_dialog);
}

sub WaitForQuestion {
    my ($self, $msg, $title) = @_;
    $title ||= wxTheApp->GetAppDisplayName();
    my $rval;
    if(Wx::MessageBox($msg, $title, wxYES_NO|wxICON_QUESTION, $self->_get_parent_for_dialog ) == wxYES) {
        return 1;
    } else {
        return 0;
    }
    return $rval;
}

sub WaitForString {
    my($self, $message, $default, $caption) = @_;
    my $returnstring = undef;
    $default = (defined($default)) ? $default : '';
    $caption = (defined($caption)) ? $caption : wxTheApp->GetAppDisplayName();
    my $parent = $self->_get_parent_for_dialog;
    
    my $dialog = Wx::TextEntryDialog->new
        ( $parent,
          $message,
          $caption,
          $default,
        );

    if( $dialog->ShowModal != wxID_CANCEL ) {
        $returnstring = $dialog->GetValue;
    }
    
    $dialog->Destroy;
    return $returnstring;
}

sub WaitForPassword {
    my($self, $message, $default, $caption) = @_;
    my $returnstring = undef;
    $default = (defined($default)) ? $default : '';
    $caption = (defined($caption)) ? $caption : wxTheApp->GetAppDisplayName();
    my $parent = $self->_get_parent_for_dialog;
    
    my $dialog = Wx::PasswordEntryDialog->new
        ( $parent,
          $message,
          $caption,
          $default,
        );

    if( $dialog->ShowModal != wxID_CANCEL ) {
        $returnstring = $dialog->GetValue;
    }
    
    $dialog->Destroy;
    return $returnstring;
}

sub DirectoryDialog {
    my $self = shift;
    my %parms = @_;

    $parms{prompt} ||= t('Select a Directory or Folder');
    $parms{context} ||= 'default';
    $parms{mustexist} ||= 0;
    
    my $defaultpath = $parms{defaultpath} || '';

    my $style = $parms{mustexist} ? (wxDD_DEFAULT_STYLE|wxDD_DIR_MUST_EXIST) : wxDD_DEFAULT_STYLE;

    my $contextpath = wxTheApp->GetConfig->Read('/dialogcontextpath/' . $parms{context});
    $contextpath = ($contextpath && (-d $contextpath) ) ? $contextpath : '';
    
    my $usepath = $defaultpath || $contextpath;
    
    my $dialog = Wx::DirDialog->new( $self->_get_parent_for_dialog , $parms{prompt}, $contextpath, $style );
    $dialog->Centre;
    my $result = $dialog->ShowModal();
    my $path = $dialog->GetPath();
    $dialog->Destroy;
    return undef if($result == wxID_CANCEL);
    wxTheApp->GetConfig->Write('/dialogcontextpath/' . $parms{context}, $path);
    return $path;
}

sub OpenFileDialog { shift->OpenSingleFileDialog(@_); }

sub OpenSingleFileDialog {
    my $self = shift;
    my %parms = @_;

    $parms{prompt} ||= t('Select a File to Open');
    $parms{context} ||= 'default';
    $parms{filename} ||= '';
    $parms{mustexist} ||= 0;
    $parms{filters} ||= [ {text => 'All Files', mask => '*'} ];
    $parms{defaultpath} ||= '';

    my $style = $parms{mustexist} ? (wxFD_OPEN|wxFD_FILE_MUST_EXIST) : wxFD_OPEN;
    $self->_common_single_file_dialog(%parms, style => $style);
}

sub SaveFileDialog {
    my $self = shift;
    my %parms = @_;

    $parms{prompt} ||= t('Save File');
    $parms{context} ||= 'default';
    $parms{filename} ||= '';
    $parms{mustexist} ||= 0;
    $parms{filters} ||= [ {text => 'All Files', mask => '*.*'} ];
    $parms{defaultpath} ||= '';

    if(!defined($parms{overwriteprompt})) { $parms{overwriteprompt} = 1; }

    my $style = $parms{overwriteprompt} ? (wxFD_OVERWRITE_PROMPT|wxFD_SAVE) : wxFD_SAVE;

    $self->_common_single_file_dialog(%parms, style => $style);
}

sub _common_single_file_dialog {
    my $self = shift;
    my %parms = @_;

    my $contextpath = wxTheApp->GetConfig->Read('/dialogcontextpath/' . $parms{context}, '');
    $contextpath = ($contextpath && (-d $contextpath) ) ? $contextpath : '';
    $parms{defaultpath} ||= $contextpath;

    my @filemasks = ();
    for my $filter (@{ $parms{filters} }) {
        push(@filemasks, qq($filter->{text} ($filter->{mask})|$filter->{mask}) );
    }
    my $filemask = join('|', @filemasks);

    my $dialog = Wx::FileDialog->new
        (
            $self->_get_parent_for_dialog,
            $parms{prompt},
            $parms{defaultpath},
            $parms{filename},
            $filemask,
            $parms{style}
        );
        
    my $filepath = '';
    my $newcontextdir = '';

    if( $dialog->ShowModal == wxID_CANCEL ) {
        $filepath = '';
    } else {
        $filepath = $dialog->GetPath;
        $newcontextdir = $filepath;
        $newcontextdir =~ s/\/[^\/]+$//;
    }
    
    $dialog->Destroy;
    return undef if(!$filepath);

    # save the context
    wxTheApp->GetConfig->Write('/dialogcontextpath/' . $parms{context}, $newcontextdir) if -e $newcontextdir;

    return $filepath;    
}

sub OpenMultipleFileDialog {
    my $self = shift;
    my %parms = @_;

    $parms{prompt} ||= t('Select a File or Files');
    $parms{context} ||= 'default';
    $parms{filters} ||= [ {text => 'All Files', mask => '*.*'} ];
    $parms{defaultpath} ||= '';

    my $style = wxFD_OPEN|wxFD_FILE_MUST_EXIST|wxFD_MULTIPLE ;

    my $contextpath = wxTheApp->GetConfig->Read('/dialogcontextpath/' . $parms{context}, '');
    $contextpath = ($contextpath && (-d $contextpath) ) ? $contextpath : '';
    $parms{defaultpath} ||= $contextpath;

    my @filemasks = ();
    for my $filter (@{ $parms{filters} }) {
        push(@filemasks, qq($filter->{text} ($filter->{mask})|$filter->{mask}) );
    }
    my $filemask = join('|', @filemasks);

    my $dialog = Wx::FileDialog->new
        (
            $self->_get_parent_for_dialog,
            $parms{prompt},
            $parms{defaultpath},
            '',
            $filemask,
            $style
        );
    $dialog->Centre;
    
    my @filepaths = ();
    my $newcontextdir = '';

    if( $dialog->ShowModal != wxID_CANCEL ) {
        @filepaths = $dialog->GetPaths();
    }
    
    $dialog->Destroy;
    
    if( @filepaths ) {
        $newcontextdir = $filepaths[0];
        $newcontextdir =~ s/\/[^\/]+$//;
        wxTheApp->GetConfig->Write('/dialogcontextpath/' . $parms{context}, $newcontextdir);
    }
    return (@filepaths);
}

1;
