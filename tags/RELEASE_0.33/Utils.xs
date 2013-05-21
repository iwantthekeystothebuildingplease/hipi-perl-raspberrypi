/////////////////////////////////////////////////////////////////////////////////////////
// File          HiPi::Utils
// Description:  C Utilities for HiPi::Utils
// Created       Fri Feb 22 16:47:08 2013
// SVN Id        $Id:$
// Copyright:    Copyright (c) 2013 Mark Dootson
// Licence:      This work is free software; you can redistribute it and/or modify it 
//               under the terms of the GNU General Public License as published by the 
//               Free Software Foundation; either version 2 of the License, or any later 
//               version.
/////////////////////////////////////////////////////////////////////////////////////////

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mylib/include/ppport.h"
#include <unistd.h>
#include <sys/types.h>
#include <sys/syscall.h>

MODULE = HiPi::Utils     PACKAGE = HiPi::Utils

void
drop_permissions_id(touid, togid = -1)
    int touid
    int togid
  PREINIT:
    int ruid, euid, suid, rgid, egid, sgid;
  CODE:
    if( togid != -1) {
        if (setresgid(togid,togid,togid) < 0)
	    croak("Failed in call to drop gid privileges.");
	
	if (getresgid(&rgid, &egid, &sgid) < 0)
	    croak("gid privilege check failed.");
	
	if (rgid != togid || egid != togid || sgid != togid)
            croak("Failed to drop gid privileges.");
	
	PL_gid  = togid;
	PL_egid = togid;
    }
    
    if (setresuid(touid,touid,touid) < 0) 
	croak("Failed in call to drop uid privileges");
		
    if (getresuid(&ruid, &euid, &suid) < 0)
	croak("uid privilege check failed");
		
    if (ruid != touid || euid != touid || suid != touid)
	croak("Failed to drop uid privileges.");

    PL_uid  = touid;
    PL_euid = touid;
