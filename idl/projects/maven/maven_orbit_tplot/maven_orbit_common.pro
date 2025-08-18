;+
;COMMON BLOCK:   maven_orbit_common
;PURPOSE:
;  Common block definition for maven_orbit_tplot and associated routines.
;
;USAGE:
;  To be used inside routines that want access to the common block.  Put this
;  line near the top:
;
;    @maven_orbit_common
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-07-07 10:47:04 -0700 (Fri, 07 Jul 2023) $
; $LastChangedRevision: 31941 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_common.pro $
;
;CREATED BY:	David L. Mitchell
;-
common mav_orb_tplt, time, state, ss, wind, sheath, pileup, wake, sza, torb, period, $
                     lon, lat, hgt, datum, lst, slon, slat, rcols, orbnum, orbstat, optkey
