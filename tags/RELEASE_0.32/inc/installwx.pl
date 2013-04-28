#########################################################################################
# Description:  Installer for Wx
# Created       Sat Feb 23 17:21:10 2013
# svn id        $Id$
# Copyright:    Copyright (c) 2013 Mark Dootson
# Licence:      This work is free software; you can redistribute it and/or modify it 
#               under the terms of the GNU General Public License as published by the 
#               Free Software Foundation; either version 3 of the License, or any later 
#               version.
#########################################################################################

use strict;
use warnings;
use Config;
use PAR::Dist;

our $archname  = $Config{archname};
our $instarchpath = $Config{sitearchexp};

our $rooturl = 'http://raspberrypi.znix.com/hipifiles';

#---------------------------------------
# Install Alien::wxWidgets
#---------------------------------------

log_info( qq(Installing Alien::wxWidgets\n) );

{
    install_par(qq($rooturl/Alien-wxWidgets-0.62-$archname-5.14.2.par));
    
    # We have to set up symlinks - PAR::Dist can't handle these
    
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_xrc-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_xrc-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_xrc-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_xrc-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_webview-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_webview-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_webview-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_webview-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_stc-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_stc-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_stc-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_stc-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_richtext-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_richtext-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_richtext-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_richtext-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_ribbon-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_ribbon-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_ribbon-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_ribbon-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_qa-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_qa-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_qa-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_qa-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_propgrid-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_propgrid-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_propgrid-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_propgrid-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_media-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_media-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_media-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_media-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_html-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_html-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_html-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_html-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_gl-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_gl-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_gl-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_gl-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_core-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_core-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_core-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_core-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_aui-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_aui-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_aui-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_aui-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_adv-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_adv-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_adv-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_gtk2u_adv-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu_xml-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu_xml-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu_xml-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu_xml-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu_net-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu_net-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu_net-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu_net-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu-2.9.so.4.0.0', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu-2.9.so.4');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu-2.9.so.4', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/libwx_baseu-2.9.so');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/bin/wxrc-2.9', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/bin/wxrc');
    symlink($instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/lib/wx/config/gtk2-unicode-2.9', $instarchpath . '/Alien/wxWidgets/gtk_2_9_4_uni/bin/wx-config');
}

#---------------------------------------
# Install Wx
#---------------------------------------

log_info( qq(Installing Wx\n) );

{
    install_par(qq($rooturl/Wx-0.9917-$archname-5.14.2.par));
}

#---------------------------------------
# Install Wx::Demo
#---------------------------------------

log_info( qq(Installing Wx::Demo\n) );

{
    install_par(qq($rooturl/Wx-Demo-0.19-$archname-5.14.2.par));
}

#---------------------------------------
# Install Wx::GLCanvas
#---------------------------------------

log_info( qq(Installing Wx::GLCanvas\n) );

{
    install_par(qq($rooturl/Wx-GLCanvas-0.09-$archname-5.14.2.par));
}

#---------------------------------------
# Install Wx::PdfDocument
#---------------------------------------

log_info( qq(Installing Wx::PdfDocument\n) ); 
{
    install_par(qq($rooturl/Wx-PdfDocument-0.13-$archname-5.14.2.par));
    
    # We have to set up symlinks - PAR::Dist can't handle these
    
    symlink($instarchpath . '/auto/Wx/PdfDocument/libwxcode_gtk2u_pdfdoc-2.9.so.0.0.0', $instarchpath . '/auto/Wx/PdfDocument/libwxcode_gtk2u_pdfdoc-2.9.so.0');
    symlink($instarchpath . '/auto/Wx/PdfDocument/libwxcode_gtk2u_pdfdoc-2.9.so.0', $instarchpath . '/auto/Wx/PdfDocument/libwxcode_gtk2u_pdfdoc-2.9.so');
    
}

#---------------------------------------
# Install Wx::Scintilla
#---------------------------------------

log_info( qq(Installing Wx::Scintilla\n) ); 

{
    install_par(qq($rooturl/Wx-Scintilla-0.40_02-$archname-5.14.2.par));
    
}

#---------------------------------------
# Install Wx::Perl::ProcessStream
#---------------------------------------

log_info( qq(Installing Wx::Perl::ProcessStream\n) ); 

{
    install_par(qq($rooturl/Wx-Perl-ProcessStream-0.32-$archname-5.14.2.par));
    
}


log_info(qq(wxPerl dependency Installation Complete\n));

sub log_info { print @_; }

1;
