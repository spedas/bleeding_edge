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
; $LastChangedDate: 2018-04-23 10:48:14 -0700 (Mon, 23 Apr 2018) $
; $LastChangedRevision: 25094 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_current_sw_version.pro $
;-
Function mvn_sta_current_sw_version

; make the software version number common block - used for CDF file production
;	common mvn_sta_software_version,ver & ver=0		; software version was "0" prior to 20141219
;       common mvn_sta_software_version,ver & ver=1 ; changed 20150118 when all SIS required elements were included in common blocks, some element not filled in
  common mvn_sta_software_version,ver & ver=2 ; changed 20180423 updated dead time corrections and new corrections for blocked bins, jmm, 2018-04-23
  
  Return, ver
End
