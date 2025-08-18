;+
;NAME:
; fa_esa_current_sw_version
;PURPOSE:
; Records the current FAST ESA SW version number
;CALLING SEQUENCE:
; version = fa_esa_current_sw_version()
;HISTORY:
; 2015-07-23
; $LastChangedBy: jimm $
; $LastChangedDate: 2021-10-11 12:39:20 -0700 (Mon, 11 Oct 2021) $
; $LastChangedRevision: 30347 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_current_sw_version.pro $
;-
Function fa_esa_current_sw_version

; make the software version number common block - used for CDF file production
;	common fa_esa_software_version,ver & ver=0
;  common fa_esa_software_version,ver & ver=1
  common fa_esa_software_version,ver & ver=2 ;new version, 2021-07-20, version 1 has data variables with dependences on virtual variables
  
  Return, ver
End
