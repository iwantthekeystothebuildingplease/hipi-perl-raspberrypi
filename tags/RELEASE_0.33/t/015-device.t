#!perl

# SVN Id $Id$

use Test::More tests => 5;

BEGIN {
    use_ok( 'HiPi::Device::GPIO' );
    use_ok( 'HiPi::Device::I2C' );
    use_ok( 'HiPi::Device::OneWire' );
    use_ok( 'HiPi::Device::SerialPort' );
    use_ok( 'HiPi::Device::SPI' );
}

1;
