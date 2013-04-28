#!perl

# SVN Id $Id$

use Test::More tests => 23;

BEGIN {
    use_ok( 'HiPi::Utils' );
    use_ok( 'HiPi::Language' );
    use_ok( 'HiPi' );
    use_ok( 'HiPi::BCM2835' );
    use_ok( 'HiPi::BCM2835::Pin' );
    use_ok( 'HiPi::Class' );
    use_ok( 'HiPi::Constant' );
    use_ok( 'HiPi::RaspberryPi' );
    use_ok( 'HiPi::Wiring' );
    use_ok( 'HiPi::Device::GPIO' );
    use_ok( 'HiPi::Device::GPIO::Pin' );
    use_ok( 'HiPi::Device::I2C' );
    use_ok( 'HiPi::Device::OneWire' );
    use_ok( 'HiPi::Device::SerialPort' );
    use_ok( 'HiPi::Device::SPI' );
    use_ok( 'HiPi::Interface::DS18X20' );
    use_ok( 'HiPi::Interface::HTADCI2C' );
    use_ok( 'HiPi::Interface::HTBackpackV2' );
    use_ok( 'HiPi::Interface::MCP23017' );
    use_ok( 'HiPi::Interface::MCP3004' );
    use_ok( 'HiPi::Interface::MCP3008' );
    use_ok( 'HiPi::Interface::MCP49XX' );
    use_ok( 'HiPi::Interface::SerLCD' );
}

1;
