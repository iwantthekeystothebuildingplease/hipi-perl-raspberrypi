#########################################################################################
# Package       HiPi
# Description:  High level Perl modules for Raspberry Pi
# Created       Fri Nov 23 11:33:11 2012
# SVN Id        $Id$
# Copyright:    Copyright (c) 2012 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

package HiPi;

#########################################################################################

use strict;
use warnings;
use Carp;
use HiPi::Utils qw( is_raspberry );

our $VERSION ='0.33';

our $sudoprog = 'sudo';

our %_cansudostash = (
    lasteuid => -1,
    cansudo  => undef,
    usesudo  => 0,
);

our $_safepath = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

sub use_sudo {
    if(@_) {
        $_cansudostash{usesudo} = $_[0];
    }
    return $_cansudostash{usesudo};
}

sub can_sudo {
    return 0 unless $_cansudostash{usesudo};
    return 0 unless is_raspberry;
    # return stashed result if we have it
    if( $_cansudostash{lasteuid} == $< ) {
        return $_cansudostash{cansudo};
    }
    
    $_cansudostash{lasteuid} = $<;
    
    if( $_cansudostash{lasteuid} == 0 ) {
        $_cansudostash{cansudo} = 0;
    } else {
        local $ENV{PATH} = $_safepath;
        $_cansudostash{cansudo} = ( system('sudo -V >/dev/null 2>&1') ) ? 0 : 1;
    }
    
    return $_cansudostash{cansudo};
}

sub system_sudo {
    my $command = shift;
    return 0 unless is_raspberry;
    local $ENV{PATH} = $_safepath;
    if( $< && can_sudo() ) {
        $command = qq($sudoprog $command);
    }
    system($command);
}

sub qx_sudo {
    my $command = shift;
    return '' unless is_raspberry;
    local $ENV{PATH} = $_safepath;
    if( $< && can_sudo() ) {
        $command = qq($sudoprog $command);
    }
    qx($command);
}

sub system_sudo_shell {
    my $command = shift;
    return 0 unless is_raspberry;
    local $ENV{PATH} = $_safepath;
    if( $< && can_sudo() ) {
        $command = qq($sudoprog sh -c '$command');
    }
    system($command);
}

sub qx_sudo_shell {
    my $command = shift;
    return '' unless is_raspberry;
    local $ENV{PATH} = $_safepath;
    if( $< && can_sudo ) {
        $command = qq($sudoprog sh -c '$command');
    }
    qx($command);
}

sub drop_permissions_name {
    my($username, $groupname) = @_;
    HiPi::Utils::drop_permissions_name( $username, $groupname );
}

1;

__END__

=head1 NAME

HiPi

=head1 DESCRIPTION

Documentation for this distribution is available at

L<http://raspberry.znix.com/hipidocs/>

The distribution home site is

L<http://raspberry.znix.com/>
    
=head1 LICENSE

This work is free software; you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the 
Free Software Foundation; either version 3 of the License, or any later 
version.

=head1 AUTHOR

Mark Dootson, C<< <mdootson at cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2012-2013 Mark Dootson, all rights reserved.

=cut

