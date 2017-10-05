;+
;NAME:
; mvn_sta_current_sw_version
;PURPOSE:
; Records the current MAVEN STATIC SW version number
;CALLING SEQUENCE:
; version = mvn_sta_current_sw_version()
;HISTORY:
; 2015-01-23
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-01-23 11:07:39 -0800 (Fri, 23 Jan 2015) $
; $LastChangedRevision: 16715 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_current_sw_version.pro $
;-
Function mvn_sta_current_sw_version

; make the software version number common block - used for CDF file production
;	common mvn_sta_software_version,ver & ver=0		; software version was "0" prior to 20141219
  common mvn_sta_software_version,ver & ver=1 ; changed 20150118 when all SIS required elements were included in common blocks, some element not filled in
  
  Return, ver
End
