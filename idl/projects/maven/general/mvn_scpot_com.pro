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
;                       (Since dE/E is a constant, this is measured in units
;                        of dE.)
;     bias            : potential bias for swe+ method
;     minflux         : minimum 40-eV energy flux for swe+ method
;     badval          : fill value for potential when no method works
;     ee              : 4x oversampled energy array
;     dfs             : 4x oversampled d(logF)/d(logE)
;     d2fs            : 4x oversampled d2(logF)/d(logE)2
;     min_lpw_pot     : minimum valid LPW potential
;     maxdt           : maximum time gap to interpolate over
;     min_sta_pot     : minimum valid STA potential for altitudes below sta_peri_alt
;     max_sta_alt     : maximum altitude for limiting range of STA potentials
;     min_swe_alt     : minimum altitude for limiting range of SWE+ potentials
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-07-25 14:47:01 -0700 (Thu, 25 Jul 2024) $
; $LastChangedRevision: 32760 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot_com.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_scpot_com.pro
;-

common mvn_scpot_com, mvn_sc_pot, mvn_pot_struct, Espan, thresh, dEmax, bias, $
                      minflux, obins, badval, ee, dfs, d2fs, min_lpw_pot, maxdt, $
                      min_sta_pot, max_sta_alt, min_swe_alt
