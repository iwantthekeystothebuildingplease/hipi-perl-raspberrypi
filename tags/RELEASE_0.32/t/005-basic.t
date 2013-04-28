#!perl

# SVN Id $Id$

use Test::More tests => 1;

use HiPi::Wiring;
use HiPi::RaspberryPi;

{
    my $fixedrev = (exists($ENV{HIPI_FORCE_BOARD_REVISION})) ? $ENV{HIPI_FORCE_BOARD_REVISION} : HiPi::Wiring::piBoardRev();
    is( HiPi::RaspberryPi::get_cpuinfo->{'GPIO Revision'}, $fixedrev, 'GPIO Revision');
}

1;
