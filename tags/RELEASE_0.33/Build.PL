use 5.14.0;
use strict;

use lib 'inc';
require Module::Build::HiPi;

our $VERSION = '0.28';

my $build = Module::Build::HiPi->new(
	module_name         => 'HiPi',
	license             => 'GPL_3',
	dist_author         => q{Mark Dootson <mdootson@cpan.org>},
	dist_version_from   => 'lib/HiPi.pm',
	configure_requires  => {
        'perl'          => '5.14.0',
	    'Module::Build' => '0',
	},
    requires            => {
        'ExtUtils::ParseXS'  => '0',
        'ExtUtils::XSpp'     => '0',
        'Try::Tiny'          => '0',
        'Device::SerialPort' => '0',
        'File::Slurp'        => '0',
        'UNIVERSAL::require' => '0',
        'Class::Accessor'    => '0',
        'File::chdir'        => '0',
        'IO::String'         => '0',
        'IO::Stringy'        => '0',       
        'File::Copy::Recursive' => '0',
        'PAR::Dist'          => '0',
        'LWP::UserAgent'     => '0',
        'OpenGL'             => '0',
        'Text::Patch'        => '0',
        'Text::Diff'         => '0',
        'Module::Info'       => '0',
        'threads'            => '0',
        'threads::shared'    => '0',
        'Thread::Queue'      => '0',
        'IO::Multiplex'      => '0',
        'IO::Epoll'          => '0',
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
    
    if( $ENV{PERL5_CPAN_IS_RUNNING} || $ENV{PERL5_CPANPLUS_IS_RUNNING} || $ENV{PERL5_CPAN_IS_EXECUTING} ) {
        $build->notes( cpanskip  => 1 );
    } else {
        $build->notes( cpanskip  => 0 );
    }
}

$build->create_build_script();

sub _hipi_option_is_yes {
    return lc( $_[0] ) eq 'y' || lc( $_[0] ) eq 'yes' || $_[0] eq 1;
}

