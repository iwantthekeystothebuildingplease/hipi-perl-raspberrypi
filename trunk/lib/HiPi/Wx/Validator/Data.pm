#########################################################################################
# Package       HiPi::Wx::Validator::Data
# Description:  Base Classes For Validators
# Created       Mon Feb 25 13:27:30 2013
# SVN Id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi::Wx::Validator::Data;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use HiPi::Language;
use Carp;

our $VERSION = '0.22';

__PACKAGE__->create_accessors( qw( datakey readonly validvalues validdirty validtypes) );

sub new {
    my ( $class, @validtypes ) = @_;
    # $class, @listofvalidnames
    # $class, $namedefhash, $datakey
    my $validtypelist;
    my %validnamedefaults;
    my $datakey = undef;
    if( ref($validtypes[0]) eq 'HASH' ) {
        %validnamedefaults = %{$validtypes[0]};
        @$validtypelist = (sort keys(%validnamedefaults));
        $datakey = (exists($validtypes[1])) ? $validtypes[1] : undef;
    } else {
        %validnamedefaults = map { $_ => '' } @validtypes;
        $validtypelist = \@validtypes;
    }
        
    my $self = $class->SUPER::new(
        datakey        => $datakey,
        validvalues    => {},
        validtypes     => $validtypelist,
        validdirty     => 0,
    );
    
    while( my($type, $default)  = each %validnamedefaults ) {
        $self->create_value_type($type, $default);
    }
    
    return $self;
}

sub get_value_types { @{ $_[0]->validtypes }; }

sub create_value_type {
    my ($self, $name, $default) = @_;
    $default = '' if !defined($default);
    my $newvalue = $default;
    $self->validvalues->{$name} = \$newvalue;
}

sub exists_value_type {
    exists($_[0]->validvalues->{$_[1]});
}

sub remove_value_type {
    $_[0]->_hipi_valid_checkname($_[1]);
    delete $_[0]->validvalues->{$_[1]};
}

sub set_dirty { $_[0]->validdirty($_[1]); }

sub is_dirty  { $_[0]->validdirty; }

sub _hipi_valid_checkname {
    croak(t('Value Type %s does not exist', $_[1])) if !$_[0]->exists_value_type($_[1]);
}

sub get_value {
    my($self, $name) = @_;
    $self->_hipi_valid_checkname($name);
    return ${$self->validvalues->{$name}};
}

sub set_value {
    my($self, $name, $newvalue) = @_;
    $self->_hipi_valid_checkname($name);
    ${$self->validvalues->{$name}} = $newvalue;
}

sub get_value_ref {
    my($self, $name) = @_;
    $self->_hipi_valid_checkname($name);
    $self->validvalues->{$name};
}

sub load_data  {
    $_[0]->set_dirty(0); $_[0]->read_data; }

sub flush_data {
    $_[0]->set_dirty(0); ( $_[0]->readonly ) ? 1 : $_[0]->write_data;
}

sub read_data  { 1 }
sub write_data { 1 }

sub flush_if_dirty {
    my $self = shift;
    return ( $self->is_dirty ) ? $self->flush_data : 1;
}

1;
