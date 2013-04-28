#########################################################################################
# Package       HiPi::Wx::Menu
# Description:  Menu Base Helper
# Created       Fri Mar 30 03:09:33 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This program is free software; you can redistribute it 
#               and/or modify it under the same terms as Perl itself
#########################################################################################

package HiPi::Wx::Menu;

#########################################################################################

use strict;
use warnings;
use Wx qw( :id wxTheApp wxACCEL_ALT wxACCEL_CTRL wxACCEL_NORMAL wxACCEL_SHIFT);
use Wx::Event qw( EVT_UPDATE_UI EVT_MENU );
use parent qw( HiPi::Class );
use Carp;

our $VERSION = '0.22';

our @accessors = qw( parentid accelerators );

__PACKAGE__->create_accessors( @accessors );

sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new(
        parentid     => ( defined($parent) ) ? $parent->GetId : undef,
        accelerators => [],
    );
    return $self;
}

sub CreateMenu {
    my $self = shift;
    croak qq(Override in derived class);
}

sub GetParent {
    my $self = shift;
    my $parentid = $self->parentid;
    return ( defined( $parentid ) ) ? Wx::Window::FindWindowById( $parentid , undef) : undef;
}

#------------------------------------------------------------
# MenuItems
#------------------------------------------------------------

sub AddMenuItem {
    my ( $self, $menu, $itemlabel, $helptext, $eventsub, $updateuisub, $id ) = @_;
    $id = wxID_ANY if !defined($id);
    my $item = Wx::MenuItem->new($menu, $id, $itemlabel, $helptext, 0);
    $menu->Append($item);
    my $parent = $self->GetParent || wxTheApp;
    EVT_MENU($parent, $item, $eventsub);
    EVT_UPDATE_UI($parent, $item, $updateuisub);
    return $item->GetId;
}

sub AppendSubMenu {
    my ( $self, $menu, $submenu, $submenulabel, $helptext, $updateuisub ) = @_;
    my $item = $menu->AppendSubMenu($submenu, $submenulabel, $helptext);
    my $parent = $self->GetParent || wxTheApp;
    EVT_UPDATE_UI($parent, $item, $updateuisub);
}

sub GetAccelerators {
    my $self = shift;
    return ( @{ $self->accelerators } );
}

sub CreateAccelerator {
    my($self, $flags, $keycode, $commandid) = @_;
    my $accel = Wx::AcceleratorEntry->new($flags, $keycode, $commandid);
    push( @{ $self->accelerators }, $accel );
}

1;
