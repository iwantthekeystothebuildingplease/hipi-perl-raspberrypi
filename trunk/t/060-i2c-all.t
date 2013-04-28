#!perl

# SVN Id $Id$

use Test::More tests => 270;

use HiPi::BCM2835;
use HiPi::BCM2835::I2C qw( :all );
use HiPi::Device::I2C;
use HiPi::Interface::MCP23017 qw( :mcp23017 );
use HiPi::Interface::MPL3115A2;
use HiPi::Interface::HTADCI2C;

sub reset_mcp23017 {
    
    my $mcp = HiPi::Interface::MCP23017->new( backend => 'bcm2835' );
    
    HiPi::BCM2835->delay(100);
    
    # all pins as outputs set low
    # configuration IOCON.BANK=0
    my @bits = $mcp->read_register_bits('IOCON');
    $bits[MCP23017_BANK] = 0;
    $bits[MCP23017_SEQOP] = 0;
    $mcp->write_register_bits('IOCON', @bits);
    my @lowbits  = (0,0,0,0,0,0,0,0);
    $mcp->write_register_bits('IODIRA', @lowbits);
    $mcp->write_register_bits('IODIRB', @lowbits);
    $mcp->write_register_bits('GPIOA',  @lowbits);
    $mcp->write_register_bits('GPIOB',  @lowbits);
}

SKIP: {
      skip 'unknown peripheral setup', 270 unless $ENV{HIPI_MODULES_PERI_TEST};



for my $baudrate ( 3816, 5000, 8000, 9600, 16000, 32000, 64000, 100000, 400000, 1000000 ) {
    HiPi::BCM2835::I2C->set_baudrate( BB_I2C_PERI_1, $baudrate );
    HiPi::Device::I2C->set_baudrate(  $baudrate );
    
# test MCP23017 in all modes
for my $backend( qw(  bcm2835 i2c smbus) )
{
    
    
    reset_mcp23017();
    
    my $mcp = HiPi::Interface::MCP23017->new( backend => $backend );
    
    # check our registers
    my ( $byte ) = $mcp->read_register_bytes('GPIOA');
    is( $byte, 0, qq(Check GPIOA output on $backend baud $baudrate));
    ( $byte ) = $mcp->read_register_bytes('GPIOB');
    is( $byte, 0, qq(Check GPIOB output on $backend baud $baudrate));
    my @bits = $mcp->read_register_bits('IOCON');
    is( $bits[MCP23017_BANK], 0, qq(Check BANK == 0 on $backend baud $baudrate));
    
    #my @lowbits  = (0,0,0,0,0,0,0,0);
    my @setbits  = (1,1,0,1,0,1,0,1); # 0xAB
    my $setbyte  = 0xAB;
    
    $mcp->write_register_bits('GPIOA',  @setbits);
    $mcp->write_register_bytes('GPIOB', $setbyte);
    
    my ( $gpioa ) = $mcp->read_register_bytes('GPIOA');
    is( $gpioa, 0xAB, qq(Single read GPIOA on $backend baud $baudrate));
    my ( $gpiob ) = $mcp->read_register_bytes('GPIOB');
    is( $gpiob, 0xAB, qq(Single read GPIOB on $backend baud $baudrate));
    
    # standard sequential register bank
    my @vals = $mcp->read_register_bytes('IODIRA', 22);
    is( $vals[18], 0xAB, qq(Multi read BANK=0 GPIOA on $backend baud $baudrate));
    is( $vals[19], 0xAB, qq(Multi read BANK=0 GPIOB on $backend baud $baudrate));
    
    # change to bank 1 - segregated
    @bits = $mcp->read_register_bits('IOCON');
    $bits[MCP23017_BANK] = 1;
    $mcp->write_register_bits('IOCON', @bits);
    
    # segregated register bank
    @vals = $mcp->read_register_bytes('IODIRA', 22);
    is( $vals[9], 0xAB, qq(Multi read BANK=1 GPIOA on $backend baud $baudrate));
    is( $vals[20], 0xAB, qq(Multi read BANK=1 GPIOB on $backend baud $baudrate));
    
} # end backend

} # end baudrate

# return to base state
reset_mcp23017();

HiPi::BCM2835::I2C->set_baudrate( BB_I2C_PERI_1, 32000 );
HiPi::Device::I2C->set_baudrate(  32000 );

}; # end SKIP

1;
