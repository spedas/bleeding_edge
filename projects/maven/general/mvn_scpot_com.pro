;+
;COMMON BLOCK:   mvn_scpot_com
;PURPOSE:
;  Stores the spacecraft potential information.  Place this near the top
;  of any routine that needs access to the common block.
;
;     mvn_sc_pot      : spacecraft potential structure
;     mvn_pot_struct  : potential structure template
;
;     Espan           : energy search range for swe+ method
;     thresh          : minimum value of d(logF)/d(logE) for swe+ method
;     dEmax           : maximum width of d(logF)/d(logE) for swe+ method
;     minflux         : minimum 40-eV energy flux for swe+ method
;     badval          : fill value for potential when no method works
;     ee              : 4x oversampled energy array
;     dfs             : 4x oversampled d(logF)/d(logE)
;     d2fs            : 4x oversampled d2(logF)/d(logE)2
;     min_lpw_pot     : minimum valid LPW potential
;     maxdt           : maximum time gap to interpolate over
;     min_sta_pot     : minimum valid STA potential for altitudes below sta_peri_alt
;     max_sta_alt     : maximum altitude for limiting range of STA potentials
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-11-30 21:10:58 -0800 (Thu, 30 Nov 2017) $
; $LastChangedRevision: 24365 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot_com.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_scpot_com.pro
;-

common mvn_scpot_com, mvn_sc_pot, mvn_pot_struct, Espan, thresh, dEmax, minflux, $
                      obins, badval, ee, dfs, d2fs, min_lpw_pot, maxdt, $
                      min_sta_pot, max_sta_alt
