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
; $LastChangedDate: 2015-08-21 14:38:41 -0700 (Fri, 21 Aug 2015) $
; $LastChangedRevision: 18562 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_common.pro $
;
;CREATED BY:	David L. Mitchell
;-
common mav_orb_tplt, time, state, ss, wind, sheath, pileup, wake, sza, torb, period, $
                     lon, lat, hgt, mex, rcols, orbnum
