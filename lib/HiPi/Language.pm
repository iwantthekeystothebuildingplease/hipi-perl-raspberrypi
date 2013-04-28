#########################################################################################
# Package       HiPi::Language
# Description:  Translations For Wx && none Wx
# Created       Thu Dec 08 09:57:28 2011
# svn id        $Id$
# Copyright:    Copyright (c) 2011 Mark Dootson
# Licence:      This program is free software; you can redistribute it 
#               and/or modify it under the same terms as Perl itself
#########################################################################################

package HiPi::Language;

#########################################################################################

# Provides multiple language support for Wx based apps whilst allowing code that uses
# the 't' translation function to run outside Wx;
# Kept separate from general 'Locale' functions which are Wx specific
# in this implementation

use strict;
use warnings;
require Exporter;
use base qw( Exporter );
use Carp;

our $VERSION = '0.22';

sub CONST_WXLANG { defined(&Wx::wxVERSION) };

our @EXPORT = qw( t t_p t_e );

# standard translation

sub t {
    my ( @args ) = @_;
    croak('No arguments to translation') if !@args;
    if( (scalar @args) == 1 ) {
        return ( CONST_WXLANG ) ? Wx::GetTranslation( $args[0] ) : HiPi::Language::GetTranslation( $args[0] );
    } else {
        my $format = shift(@args);
        $format = ( CONST_WXLANG ) ? Wx::GetTranslation( $format ) : CP::Language::GetTranslation( $format );
        return sprintf($format, @args);
    }
}

# plural translation

sub t_p {
    my( @args ) = @_;
    croak('No arguments to translation') if !@args;
    if( (scalar @args) == 3 ) {
        return ( CONST_WXLANG )
            ?  Wx::GetTranslation( @args )
            :  ( $args[2] == 1 ) ? CP::Language::GetTranslation( $args[0] ) : HiPi::Language::GetTranslation( $args[1] );
    } else {
        my $singular = shift(@args);
        my $plural = shift( @args );
        my $number = shift( @args );
        my $format = ( $number == 1 ) ? $singular : $plural;
        $format = ( CONST_WXLANG ) ? Wx::GetTranslation( $format ) : HiPi::Language::GetTranslation( $format );
        return sprintf($format, @args);
    }
}

# extended translation

sub t_e {
    my ($format, %args) = @_;
    my $retval = HiPi::Language::t($format);
    my $re = join('|', map { quotemeta($_) } keys(%args));
    $retval =~ s/\{($re)\}/defined($args{$1}) ? $args{$1} : "{$1}"/ge;
    $retval;
}

# implement a Wx independent gettext method ?
sub GetTranslation { return $_[0]; }


1;
