package Module::Build::HiPi;

use 5.14.0;
use strict;
use warnings;
use Module::Build;
use Config;
use File::Copy;
use Cwd;
use File::Path;
our @ISA = qw( Module::Build );

our $VERSION ='0.33';

sub process_xs_files {
	my $self = shift;

	# Override Module::Build with a null implementation
	# We will be doing our own custom XS file handling
}

sub hipi_run_command {
	my ($self, $cmds) = @_;
	my $cmd = join( ' ', @$cmds );
    if ( !$self->verbose and $cmd =~ /(cc|gcc|g\+\+|cl).+-o\s+(\S+)/ ) {
		my $object_name = File::Basename::basename($2);
		$self->log_info("    CC -o $object_name\n");
    } elsif ( !$self->verbose and $cmd =~ /(configure|make)/i ) {
		$self->log_info("    SH $1\n")
    } else {
		$self->log_info("$cmd\n");
	}
	my $rc = system($cmd);
	die "Failed with exit code $rc\n$cmd\n"  if $rc != 0;
	die "Ctrl-C interrupted command\n$cmd\n" if $rc & 127;
}

sub ACTION_clean {
    my $self = shift;
    $self->SUPER::ACTION_clean;
    File::Path::remove_tree('BCM2835/buildlib') if -d 'BCM2835/buildlib';
    unlink('mylib/lib/libwiringPiStatic.a');
    unlink('mylib/lib/libbcm2835Static.a');
    chdir('Wiring/src/wiringPi');
    system('make clean');
    chdir('../../../');
    chdir('suidbin');
    system('make -f makefile.gcc realclean');
    chdir('../../../');
    chdir
}

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build;
    $self->hipi_do_update;
    $self->hipi_do_depends;
    $self->hipi_do_wx;
	$self->hipi_build_wiring_library;
    $self->hipi_build_bcm2835_library;
    $self->hipi_build_xs;
    $self->hipi_build_data;
    $self->hipi_build_execs;
    $self->log_info(qq(Build Complete\n));
}

# Build test action invokes build first
sub ACTION_test {
	my $self = shift;
	$self->depends_on('build');
	$self->SUPER::ACTION_test;
}

# Build install action invokes build first
sub ACTION_install {
	my $self = shift;
	$self->depends_on('build');
    $self->hipi_install_groups;
	$self->SUPER::ACTION_install;
    $self->hipi_install_scriptfiles;
}

our $_hipi_sudo_prog;

sub hipi_check_perms {
    return $_hipi_sudo_prog if defined($_hipi_sudo_prog);
    if( $< != 0 ) {
        my $cansudo = ( system('sudo -V >/dev/null 2>&1') ) ? 0 : 1;
        if( $cansudo ) {
            $_hipi_sudo_prog = 'sudo ';
        } else {
            die 'HiPi requires access to root permissions to install dependencies. Run the Perl Build steps as a user with sudo permissions.';
        }
    } else {
        $_hipi_sudo_prog = '';
    }
    return $_hipi_sudo_prog;
}

sub hipi_do_update {
    my $self = shift;
    return unless $self->notes('doupdate');
    
    my $statefile = 'update.mksf';
    return if $self->up_to_date( 'Build', $statefile );
    
    my $supg = hipi_check_perms();
    $self->log_info(qq(Performing apt-get update\n));
    system(qq(${supg}apt-get -y update)) and die qq(failed calling apt-get update: $!);
    system(qq(touch $statefile));
}

sub hipi_do_depends {
    my $self = shift;
    
    my $statefile = 'depends.mksf';
    return if $self->up_to_date( 'Build', $statefile );
    
    my $supg = hipi_check_perms();
    $self->log_info(qq(Installing Dependencies\n));
    my @debs = qw(
        libextutils-parsexs-perl
        libextutils-xspp-perl
        libtry-tiny-perl
        libdevice-serialport-perl
        libfile-slurp-perl
        libuniversal-require-perl
        libclass-accessor-perl
        libfile-chdir-perl
        libio-string-perl
        libio-stringy-perl       
        libfile-copy-recursive-perl
        libpar-dist-perl
        libwww-perl
        libopengl-perl
        libtext-patch-perl
        libtext-diff-perl
        libmodule-info-perl
        libthreads-perl
        libthreads-shared-perl
        libthread-queue-perl
        libio-multiplex-perl
        i2c-tools
        git
        zlib1g-dev
        libperl-dev
        libio-epoll-perl
    );
    
#   libdbd-pg-perl
#	libdbd-mysql-perl
#	libdbd-sqlite3-perl
    
    my $cmd = qq(${supg}apt-get -y install ) . join(' ', @debs);
    system($cmd) and die qq(failed installing dependencies: $!);
    system(qq(touch $statefile));
}

sub hipi_do_wx {
    my $self = shift;
    return unless $self->notes('dowx');
    
    my $statefile = 'wxperl.mksf';
    return if $self->up_to_date( 'Build', $statefile );
    
    my $supg = hipi_check_perms();
        
    my $wxrequired = 1;
    
    eval {
        require Wx::Mini;
        my $wxversion = $Wx::VERSION;
        require Alien::wxWidgets;
        Alien::wxWidgets->import;
        my $widgversion = Alien::wxWidgets->version;
        # require version 0.9917 and 2.009004
        if( $wxversion > 0.9916 && $widgversion > 2.009003 ) {
            $wxrequired = 0;
        }
    };
    
    if( $wxrequired ) {
        $self->log_info(qq(Installing PAR Dists for wxPerl\n));
        system(qq(${supg}$^X inc/installwx.pl)) and die 'failed to install wxPerl';
        system(qq(touch $statefile));
    }
}


sub hipi_build_wiring_library {
    my $self = shift;
    
    $self->log_info(qq(Building wiringPi library\n));
    mkdir( 'mylib/lib', 0777 ) if !-d 'mylib/lib';
    my $tgtlib = 'mylib/lib/libwiringPiStatic.a';
    return if $self->up_to_date( 'Build', $tgtlib );
    
    chdir('Wiring/src/wiringPi');
    
    my $gcc = $Config{cc};
    $gcc = 'gcc' if $gcc eq 'cc';
    my $gxx = $gcc;
    $gxx =~ s/^gcc/g\+\+/;
    my $gld = $Config{ld};
    
    my @cmd = (
		qq(make static CC=$gcc CXX=$gxx LD=$gld),
	);

	$self->hipi_run_command( \@cmd );
    chdir('../../../');
    
    # copy the lib
    my $srclib = 'Wiring/src/wiringPi/libwiringPi.a';
    File::Copy::copy( $srclib, $tgtlib );
}

sub hipi_build_bcm2835_library {
    my $self = shift;
    
    $self->log_info(qq(Building bcm2835 library\n));
    mkdir( 'mylib/lib', 0777 ) if !-d 'mylib/lib';
    my $tgtlib = 'mylib/lib/libbcm2835Static.a';
    
    return if $self->up_to_date( [ 'Build', 'BCM2835/src/src/bcm2835.c', 'BCM2835/src/src/bcm2835.h' ], [ $tgtlib ] );
     
    my $gcc = $Config{cc};
    $gcc = 'gcc' if $gcc eq 'cc';
    my $gxx = $gcc;
    $gxx =~ s/^gcc/g\+\+/;
    my $gld = $Config{ld};
    
    chdir('BCM2835');
    my $buildlibdir = Cwd::abs_path( getcwd() );
    die 'Failed to determine working directory' unless $buildlibdir && $buildlibdir =~ /\/BCM2835/;
    
    $buildlibdir .= '/buildlib';
    mkdir( $buildlibdir, 0777 );
        
    chdir('buildlib');
    my $quiet = ( $self->verbose ) ? '' : '--quiet ';
    my @cmd = (
		qq(sh ../src/configure $quiet--prefix=$buildlibdir CC=$gcc CXX=$gxx LD=$gld),
	);

	$self->hipi_run_command( \@cmd );
    @cmd = (
		qq(make $quiet),
	);
    $self->hipi_run_command( \@cmd );
    
    chdir('../../');
    
    # copy the lib
    my $srclib = 'BCM2835/buildlib/src/libbcm2835.a';
    File::Copy::copy( $srclib, $tgtlib );
}

sub hipi_build_xs {
    my $self = shift;
    
    $self->log_info(qq(Building XS Files\n));
    
    my @modules = (
        { name => 'Utils', version => $VERSION, autopath => 'HiPi/Utils', libs => '' },
        { name => 'Exec', version => $VERSION, autopath => 'HiPi/Utils/Exec', libs => '-lz' },
        { name => 'I2C',  version => $VERSION, autopath => 'HiPi/Device/I2C', libs => '' },
        { name => 'SPI',  version => $VERSION, autopath => 'HiPi/Device/SPI', libs => '' },
        { name => 'BCM2835', version => $VERSION, autopath => 'HiPi/BCM2835', libs => '-Lmylib/lib -lbcm2835Static' },
        { name => 'Wiring',  version => $VERSION, autopath => 'HiPi/Wiring',  libs => '-Lmylib/lib -lwiringPiStatic -lpthread' },
    );
    
    #----------------------------------------------
    # determine typemap
    #----------------------------------------------
    
    my $perltypemap;
	
	for my $incpath (@INC) {
		my $perlcheckfile = qq($incpath/ExtUtils/typemap);
		if ( !$perltypemap && -f $perlcheckfile ) {
			$perltypemap = $perlcheckfile;
			$perltypemap =~ s/\\/\//g;
		}
		last if $perltypemap;
	}

	die 'Unable to determine Perl typemap' if !defined($perltypemap);
    
    for my $mod ( @modules ) {
        my $xsfile   = qq($mod->{name}.xs);
        my $cfile    = qq($mod->{name}.c);
        my $ofile    = qq($mod->{name}.o);
        my $autopath = 'blib/arch/auto/' . $mod->{autopath};
        my $bsfile   = qq($autopath/$mod->{name}.bs);
        my $dllfile  = qq($autopath/$mod->{name}.) . $Config{dlext};
        
        File::Path::make_path( $autopath, { mode => 0755 } );
        
        # make bootscript file
        if ( open my $fh, '>', $bsfile ) {
            close $fh;
        }
        
        # Build Object File
        
        unless ( $self->up_to_date( $xsfile, $cfile ) ) {
            
            for ( qw( o def c xsc obj ) ) {
                my $fname = qq($mod->{name}.$_);
                unlink( $fname ) if -f $fname;
            }
            require ExtUtils::ParseXS;
            ExtUtils::ParseXS::process_file(
                filename    => $xsfile,
                output      => $cfile,
                prototypes  => 0,
                linenumbers => 0,
                typemap     => [
                    $perltypemap,
                    'typemap',
                ],
            );
            
            my @cmd = (
                $Config{cc},
                '-c -o',
                $ofile,
                $Config{ccflags},
                $Config{optimize},
                '-DVERSION=\"' . $mod->{version} . '\" -DXS_VERSION=\"' . $mod->{version} . '\"',
                $Config{cccdlflags},
                '-Imylib/include',
                '-I' . $Config{archlibexp} . '/CORE',
                $cfile,
            );
            $self->hipi_run_command( \@cmd );  
        }
        
        # Link Object
        unless( $self->up_to_date( $cfile, $dllfile ) ) {
            
            my $libdirs = $Config{libpth};
            $libdirs =~ s/\s+/ -L/g;
            
            unlink( $dllfile );
            my @cmd = (
                $Config{ld},
                qq(-L$libdirs),
                $Config{lddlflags},
                $ofile,
                '-o ' . $dllfile,
                $mod->{libs}
            );
            $self->hipi_run_command( \@cmd );
        }
    }
}

sub hipi_build_execs {
    my $self = shift;
    return if $self->up_to_date(
        [ 'Build', 'suidbin/hipi-i2c.pl', 'suidbin/hipi-pud.pl' ],
        [ 'suidbin/hipi-i2c', 'suidbin/hipi-pud' ]
    );
    $self->log_info(qq(Building Executables\n));
    
    my @cmd = (
        $^X,
        '-Ilib -Iblib/arch -Iblib/lib',
        'inc/buildexecs.pl',
    );
    
    $self->hipi_run_command( \@cmd );
}

sub hipi_build_data {
    my $self = shift;
    require File::Copy::Recursive;
    File::Copy::Recursive::dircopy('mylib/auto/share','blib/lib/auto/share'); 
}

sub hipi_install_scriptfiles {
    my $self = shift;
    
    my $supg = hipi_check_perms();
    
    my $suidgroups = {
        'hipi-i2c' => 'i2c',
        'hipi-pud' => 'gpio',
    };
    
    # install setuid executables
    for my $fname ( qw( hipi-i2c hipi-pud ) ) {
        my $gname = $suidgroups->{$fname};
        $self->log_info(qq(Installing $fname\n));
        my $src = qq(suidbin/$fname);
        my $tgt = qq(/usr/local/bin/$fname);
        my $command = qq(sudo cp \"$src\" \"$tgt\");
        
        system($command) and die qq(Failed to install $fname script : $!);
        $command = qq(sudo chown root:$gname \"$tgt\");
        system($command) and die qq(Failed to set root ownership for $fname script : $!);
        $command = qq(sudo chmod 4754 \"$tgt\");
        system($command) and die qq(Failed to set suid mode for $fname script : $!);
    }
    
    # install plain executables
    for my $fname ( qw( hipi-control-gui hipi-expin hipi-install hipi-upgrade hipi-gpio) ) {
        $self->log_info(qq(Installing $fname\n));
        my $src = qq(userbin/$fname);
        my $tgt = qq(/usr/local/bin/$fname);
        my $command = qq(sudo cp \"$src\" \"$tgt\");
        system($command) and die qq(Failed to install $fname script : $!);
        $command = qq(sudo chown root:root \"$tgt\");
        system($command) and die qq(Failed to set root ownership for $fname script : $!);
        $command = qq(sudo chmod 0755 \"$tgt\");
        system($command) and die qq(Failed to set permissions for $fname script : $!);
    }
}

sub hipi_install_groups {
    my $self = shift;
    for my $group ( qw( i2c spi gpio ) ) {
        system(qq(sudo groupadd -f -r $group));
    }
}


1;
