#########################################################################################
# Package       HiPi::Apps::Control::Menu::Help
# Description:  Help Menu
# Created       Fri Mar 30 14:15:46 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This program is free software; you can redistribute it 
#               and/or modify it under the same terms as Perl itself
#########################################################################################

package HiPi::Apps::Control::Menu::Help;

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
    my $id = $self->AddMenuItem($menu, t("&Help Contents"), t('Help Contents'), \&OnMenuContents,  \&OnMenuUIContents );
    
    $menu->AppendSeparator;
    $id = $self->AddMenuItem($menu, t("&About"), t('About'), \&OnMenuAbout,  \&OnMenuUIAbout, wxID_ABOUT );
 
    return $menu;
}

#-----------------------------------------
# COMMANDS
#-----------------------------------------

sub OnMenuContents {
    my ($parent, $event) = @_;
    wxTheApp->DisplayHelpContents;
}

sub OnMenuAbout {
    my ($parent, $event) = @_;
    wxTheApp->OnMenuAbout;
}

#-----------------------------------------
# UI UPDATES
#-----------------------------------------

sub OnMenuUIContents {
    my ($parent, $event) = @_;
    
}

sub OnMenuUIAbout {
    my ($parent, $event) = @_;
    
}





1;
