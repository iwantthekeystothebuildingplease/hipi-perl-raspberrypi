#########################################################################################
# Package       HiPi::Apps::Control::Menu::File
# Description:  File Menu
# Created       Fri Mar 30 14:15:46 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This program is free software; you can redistribute it 
#               and/or modify it under the same terms as Perl itself
#########################################################################################

package HiPi::Apps::Control::Menu::File;

#########################################################################################

use strict;
use warnings;
use Wx qw( wxTheApp :id :bitmap );
use parent qw( HiPi::Wx::Menu );
use HiPi::Language;

our $VERSION = '0.22';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub CreateMenu {
    my $self = shift;
    my $parent = $self->GetParent;
    my $menu = Wx::Menu->new('');
    
    $self->AddMenuItem($menu, t("&Preferences"), t('Preferences'), \&OnMenuPreferences,  \&OnMenuUIPreferences, wxID_PREFERENCES );
    $menu->AppendSeparator;
    $self->AddMenuItem($menu, t('E&xit'), t('Exit'), \&OnMenuExit,  \&OnMenuUIExit, wxID_EXIT );
    
    return $menu;
}

#-----------------------------------------
# COMMANDS
#-----------------------------------------


sub OnMenuPreferences {
    my ($parent, $event) = @_;
    wxTheApp->OnMenuPreferences;
}

sub OnMenuUIPreferences {
    my ($parent, $event) = @_;
}

sub OnMenuExit {
    my ($parent, $event) = @_;
    wxTheApp->OnMenuExit;
}

sub OnMenuUIExit {
    my ($parent, $event) = @_;
    
}


1;
