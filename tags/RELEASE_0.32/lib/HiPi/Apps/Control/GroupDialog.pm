#########################################################################################
# Package       HiPi::Apps::Control::GroupDialog
# Description:  Manage Group
# Created       Wed Mar 06 02:50:55 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Apps::Control::GroupDialog;

#########################################################################################

use strict;
use warnings;
use 5.14.0;
use parent qw( HiPi::Wx::Dialog );
use Wx qw( :id :misc :sizer :panel :window :dialog :listbox );
use HiPi::Language;
use HiPi::Utils qw( is_raspberry );
use Wx::Event qw( EVT_LISTBOX EVT_LISTBOX_DCLICK EVT_BUTTON EVT_COMMAND );
use Try::Tiny;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw(memberlist userlist group gid btnadd btnremove));

our $HIPI_EVT_ID_REFRESH_GROUP = Wx::NewEventType();

sub new {
    my ($class, $parent, $label, $group) = @_;
    my $self = $class->SUPER::new($parent, wxID_ANY, $label);
    
    $self->group($group);
    
    #----------------------------------------
    # Controls
    #----------------------------------------
    
    my $mheader = Wx::StaticText->new($self, wxID_ANY, t('Group Members'), wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE);
    my $mlist = Wx::ListBox->new($self, wxID_ANY, wxDefaultPosition, [150, 180], [], wxLB_SINGLE|wxLB_SORT|wxLB_ALWAYS_SB);
    $self->memberlist($mlist);
    my $btnremove = Wx::Button->new($self, wxID_ANY, '>>', wxDefaultPosition, [-1, 25]);
    $self->btnremove($btnremove);
    $btnremove->Enable(0);
    
    my $uheader = Wx::StaticText->new($self, wxID_ANY, t('Users'), wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE);
    my $ulist = Wx::ListBox->new($self, wxID_ANY, wxDefaultPosition, [150, 180], [], wxLB_SINGLE|wxLB_SORT|wxLB_ALWAYS_SB);
    $self->userlist($ulist);
    my $btnadd = Wx::Button->new($self, wxID_ANY, '<<', wxDefaultPosition, [-1, 25]);
    $self->btnadd($btnadd);
    $btnadd->Enable(0);
    
    my $btnclose = Wx::Button->new($self, wxID_OK, t('Close'));
    
    #----------------------------------------
    # Events
    #----------------------------------------
    
    EVT_LISTBOX($self, $mlist, \&_evt_member_selected );
    EVT_LISTBOX($self, $ulist, \&_evt_user_selected );
    EVT_LISTBOX_DCLICK($self, $mlist, \&_evt_member_dclick );
    EVT_LISTBOX_DCLICK($self, $ulist, \&_evt_user_dclick );
    EVT_BUTTON($self, $btnremove, \&_evt_btn_remove );
    EVT_BUTTON($self, $btnadd, \&_evt_btn_add );
    EVT_COMMAND($self, $self, $HIPI_EVT_ID_REFRESH_GROUP, \&_evt_refresh_required);
    
    #----------------------------------------
    # Layout
    #----------------------------------------
    
    my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
    my $listsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $mlistsizer = Wx::BoxSizer->new(wxVERTICAL);
    my $ulistsizer = Wx::BoxSizer->new(wxVERTICAL);
    
    $mlistsizer->Add($mheader, 0, wxEXPAND|wxALL, 0);
    $mlistsizer->Add($mlist, 1, wxEXPAND|wxALL, 0);
    $mlistsizer->Add($btnremove, 0, wxEXPAND|wxALL, 0);
    
    $ulistsizer->Add($uheader, 0, wxEXPAND|wxALL, 0);
    $ulistsizer->Add($ulist, 1, wxEXPAND|wxALL, 0);
    $ulistsizer->Add($btnadd, 0, wxEXPAND|wxALL, 0);
    
    $listsizer->Add($mlistsizer,1, wxEXPAND|wxALL, 0);
    $listsizer->AddSpacer(10);
    $listsizer->Add($ulistsizer, 1, wxEXPAND|wxALL, 0);
    
    $mainsizer->Add($listsizer, 1, wxEXPAND|wxTOP|wxLEFT|wxRIGHT, 10);
    $mainsizer->Add($btnclose, 0, wxALIGN_RIGHT|wxALL, 10);
    $self->SetSizerAndFit($mainsizer);
    
    # Handle dummy usage
    
    $self->{dummymembers} = { rolf => 1, john => 1 };
    $self->{dummyusers} = [qw(rolf john arthur mark pi tom alice eviljane)];
    
    $self->refresh_lists;
    $self->Centre;
    return $self;
}

sub _get_listdata {
    my $self = shift;
    my(@members, @users);
    
    unless( is_raspberry ) {
        @members = (sort keys(%{ $self->{dummymembers} }));
        for my $name ( @{ $self->{dummyusers} } ) {
            next if $name ~~ @members;
            push(@users, $name);
        }
        return \@members, \@users;
    }
    
    # get members
    {
        my ($name,$passwd,$gid,$members) = getgrnam($self->group);
        if( $name ) {
            $self->gid($gid);
            @members = split(/\s+/, $members);
        }
    }
    
    #get users
    {
        setpwent();
        while( my($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwent()) {
            next if $name ~~ @members;
            push(@users, $name);
        }
        endpwent();
    }
    
    return \@members, \@users;
}

sub refresh_lists {
    my $self = shift;
    my( $members, $users ) = $self->_get_listdata;
    my $mlist = $self->memberlist;
    my $ulist = $self->userlist;
    $mlist->Clear;
    $mlist->InsertItems($members, 0);
    $ulist->Clear;
    $ulist->InsertItems($users, 0);
    $self->btnadd->Enable(0);
    $self->btnremove->Enable(0);
}

sub _evt_member_selected {
    my($self, $event) = @_;
    my $index = $event->GetSelection;
    if( defined($index) && $index != -1) {
        $self->btnremove->Enable(1);
    } else {
        $self->btnremove->Enable(0);
    }
    $event->Skip(1);
}

sub _evt_refresh_required {
    my($self, $event) = @_;
    $self->refresh_lists;
}

sub _evt_user_selected {
    my($self, $event) = @_;
    my $index = $event->GetSelection;
    if( defined($index) && $index != -1) {
        $self->btnadd->Enable(1);
    } else {
        $self->btnadd->Enable(0);
    }
    $event->Skip(1);
}

sub _evt_member_dclick {
    my($self, $event) = @_;
    $event->Skip(1);
    $self->_remove_selected_user;
}

sub _evt_user_dclick {
    my($self, $event) = @_;
    $event->Skip(1);
    $self->_add_selected_user;
}

sub _evt_btn_remove {
    my($self, $event) = @_;
    $event->Skip(1);
    $self->_remove_selected_user;
}

sub _evt_btn_add {
    my($self, $event) = @_;
    $event->Skip(1);
    $self->_add_selected_user;
}

sub _remove_selected_user {
    my $self = shift;
    my $selected = $self->memberlist->GetStringSelection;
    if(!$selected) {
        $self->btnremove->Enable(0);
        return;
    }
    
    try {
        if( is_raspberry ) {
            HiPi::Utils::group_remove_user($self->group, $selected);
        } else {
            delete($self->{dummymembers}->{$selected});
        }
    } catch {
        Wx::LogError($_);
        Wx::LogError(t('Failed to update user list for group %s.', $self->group));
    };
    
    my $event = Wx::CommandEvent->new($HIPI_EVT_ID_REFRESH_GROUP , $self->GetId);
    $self->GetEventHandler->AddPendingEvent($event);
}

sub _add_selected_user {
    my $self = shift;
    my $selected = $self->userlist->GetStringSelection;
    
    if(!$selected) {
        $self->btnadd->Enable(0);
        return;
    }
    
    try {
        if( is_raspberry ) {
            HiPi::Utils::group_add_user($self->group, $selected);
        } else {
            $self->{dummymembers}->{$selected} = 1;
        }
    } catch {
        Wx::LogError($_);
        Wx::LogError(t('Failed to update user lists for group %s.', $self->group));
    };
    
    my $event = Wx::CommandEvent->new($HIPI_EVT_ID_REFRESH_GROUP , $self->GetId);
    $self->GetEventHandler->AddPendingEvent($event);
}


1;
