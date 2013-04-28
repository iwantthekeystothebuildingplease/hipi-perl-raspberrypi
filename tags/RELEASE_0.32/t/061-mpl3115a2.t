#!perl

# SVN Id $Id$

use Test::More tests => 288;

use HiPi::Interface::MPL3115A2 qw( :all );
use HiPi::BCM2835::I2C qw( :all );
use Try::Tiny;

my $devattached = try {
    my $test = HiPi::Interface::MPL3115A2->new();
    $test->sysmod;
    return 1;
} catch {
    return 0;
};


SKIP: {
      skip 'unknown peripheral setup', 288 unless $devattached && $ENV{HIPI_MODULES_PERI_TEST};

my $restorebaud = HiPi::BCM2835::I2C->get_baudrate( BB_I2C_PERI_1 );

for my $baudrate ( 3816, 9600, 32000, 100000, 400000, 1000000 ) {
    HiPi::BCM2835::I2C->set_baudrate( BB_I2C_PERI_1, $baudrate );
    for my $overs ( MPL_OVERSAMPLE_128, MPL_OVERSAMPLE_32, MPL_OVERSAMPLE_4, MPL_OVERSAMPLE_1) {
    
        my $loopid = qq(BR $baudrate OS ) . ($overs >>3);
        
        my $mpl = HiPi::Interface::MPL3115A2->new();
        
        # set base state as standby, oversample 128 & altitude
        my $setmask = MPL_CTRL_REG1_ALT;
        $mpl->device->i2c_write(MPL_REG_CTRL_REG1, $setmask);
        is($mpl->sysmod, 0, qq(check device in standby by sysmod $loopid));
        is($mpl->active, 0, qq(check device in standby by active $loopid));
        is($mpl->mode, MPL_FUNC_ALTITUDE, qq(check function is altitude 1 $loopid));
        $mpl->reboot;
        my ( $reg1 ) = $mpl->device->i2c_read_register_rs(MPL_REG_CTRL_REG1,1);
        is( $reg1, 0, qq(check CTRL_REG1 setting $loopid));
        is($mpl->oversample, 0, qq(oversample default $loopid));
        $mpl->oversample($overs);
        is($mpl->oversample, $overs, qq(oversample set $loopid));
        ( $reg1 ) = $mpl->device->i2c_read_register_rs(MPL_REG_CTRL_REG1,1);
        is($reg1 & MPL_OVERSAMPLE_MASK, $overs, qq(oversample from register $loopid));
        is($mpl->mode, MPL_FUNC_PRESSURE, qq(check function is pressure $loopid));
        $mpl->mode( MPL_FUNC_ALTITUDE );
        is($mpl->mode, MPL_FUNC_ALTITUDE, qq(check function is altitude 2 $loopid));
        my $pressure = $mpl->os_pressure();
        my $tempr = $mpl->os_temperature();
        my $alt = $mpl->os_altitude();
        ok( $pressure > 90000 && $pressure < 110000, qq(pressure value check $loopid));
        ok( $alt > -500 && $alt < 1000, qq(altitude value check $loopid));
        ok( $tempr > 0 && $tempr < 32, qq(temperature value check $loopid));
        
        $mpl->reboot;
    } # end oversample
    
} # end baudrate

# return to base state
HiPi::BCM2835::I2C->set_baudrate(BB_I2C_PERI_1, $restorebaud);
;

}; # end SKIP

1;
