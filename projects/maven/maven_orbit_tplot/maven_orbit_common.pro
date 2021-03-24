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
; $LastChangedDate: 2021-03-22 19:19:14 -0700 (Mon, 22 Mar 2021) $
; $LastChangedRevision: 29806 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_common.pro $
;
;CREATED BY:	David L. Mitchell
;-
common mav_orb_tplt, time, state, ss, wind, sheath, pileup, wake, sza, torb, period, $
                     lon, lat, hgt, datum, mex, rcols, orbnum, orbstat, optkey
