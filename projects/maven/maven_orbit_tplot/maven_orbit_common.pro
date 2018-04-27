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
; $LastChangedDate: 2018-04-26 11:01:36 -0700 (Thu, 26 Apr 2018) $
; $LastChangedRevision: 25122 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_common.pro $
;
;CREATED BY:	David L. Mitchell
;-
common mav_orb_tplt, time, state, ss, wind, sheath, pileup, wake, sza, torb, period, $
                     lon, lat, hgt, mex, rcols, orbnum, orbstat
