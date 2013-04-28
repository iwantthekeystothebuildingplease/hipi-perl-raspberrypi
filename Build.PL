use 5.14.0;
use strict;

use lib 'inc';
require Module::Build::HiPi;

our $VERSION = '0.27';

my $build = Module::Build::HiPi->new(
	module_name        => 'HiPi',
	license            => 'GPL_3',
	dist_author        => q{Mark Dootson <mdootson@cpan.org>},
	dist_version_from  => 'lib/HiPi.pm',
	configure_requires => {
            'perl'          => '5.14.0',
	    'Module::Build' => '0',
	},
	add_to_cleanup => [
        '*.o',
        'blib',
        '*.a',
        '*.so',
        '*.c',
        '*.xsc',
        '*.bs',
        '*.mksf',
	],
	meta_merge => {
        resources => {
            homepage   => 'http://raspberry.znix.com/',
        },
        no_index => {
            directory => [qw<inc mylib BCM2835 Wiring suidbin userbin>],
        },
	},
	dist_abstract   => 'Raspberry Pi GPIO Modules',
        
    get_options     => {
        'hipi-wx'         => { type => '!', default => 1, },
        'hipi-update'     => { type => '!', default => 1, },
    },

);


{ # Get Options
    my $dowx      = _hipi_option_is_yes($build->args('hipi-wx'));
    my $doupdate  = _hipi_option_is_yes($build->args('hipi-update'));
    
    $build->notes( doupdate     => $doupdate );
    $build->notes( dowx         => $dowx );
}

$build->create_build_script();

sub _hipi_option_is_yes {
    return lc( $_[0] ) eq 'y' || lc( $_[0] ) eq 'yes' || $_[0] eq 1;
}

