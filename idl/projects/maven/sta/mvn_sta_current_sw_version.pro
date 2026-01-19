;+
;NAME:
; mvn_sta_current_sw_version
;PURPOSE:
; Records the current MAVEN STATIC SW version number
;CALLING SEQUENCE:
; version = mvn_sta_current_sw_version()
;HISTORY:
; 2015-01-23
; Added init, reset, for control of version during background reprocessing
; $LastChangedBy: muser $
; $LastChangedDate: 2026-01-12 13:38:15 -0800 (Mon, 12 Jan 2026) $
; $LastChangedRevision: 33998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_current_sw_version.pro $
;-
Function mvn_sta_current_sw_version, value = value, init = init, reset = reset

; make the software version number common block - used for CDF file production
;	common mvn_sta_software_version,ver & ver=0		; software version was "0" prior to 20141219
;       common mvn_sta_software_version,ver & ver=1 ; changed 20150118 when all SIS required elements were included in common blocks, some element not filled in
;       common mvn_sta_software_version,ver & ver=2                       ; changed 20180423 updated dead time corrections and new corrections for blocked bins, jmm, 2018-04-23
;  common mvn_sta_software_version,ver & ver=3 ; files have data from
;  0.0 seconds on the day boundary to the end of the day, for better
;  dead time corrections, jmm, 2025-09-09
  common mvn_sta_software_version,ver
  If(keyword_set(init) Or keyword_set(reset) Or (n_elements(ver) Eq 0)) Then Begin
     If(keyword_set(value)) Then ver = value Else ver = 2
  Endif 
     
  Return, ver
End
