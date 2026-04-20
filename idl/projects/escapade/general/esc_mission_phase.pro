;+
;
;FUNCTION:        ESC_MISSION_PHASE
;
;PURPOSE:         Returns the ESCAPADE mission phase names (or indices).
;
;INPUTS:          Time (array) to be determined.
;
;KEYWORDS:
;
;     INDEX:      If set, returns the mission phase indices.
;                 0 = prelaunch, 1 = commissioning, 2 = science.
;
;CREATED BY:      Takuya Hara on 2026-04-17.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-04-17 15:53:30 -0700 (Fri, 17 Apr 2026) $
; $LastChangedRevision: 34379 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/general/esc_mission_phase.pro $
;
;-
FUNCTION esc_mission_phase, itime, verbose=verbose, index=index
  IF undefined(itime) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No input time array found.'
     IF KEYWORD_SET(index) THEN RETURN, -1L ELSE RETURN, 'undefined'
  ENDIF ELSE times = itime

  IF is_string(times) THEN times = time_double(times) 

  pname = ['prelaunch', 'commissioning', 'science']
  pindx = [0, 1, 2]
  ptime = ['2025-11-13/20:55:01', '2026-02-26', '2100'] ; UTC
  ptime = time_double(ptime)

  ; Slightly shifting so that '2026-02-26' can be regarded as "science".
  idx = CEIL(INTERPOL(pindx, ptime, times) + 1.e-10)
  IF KEYWORD_SET(index) THEN phase = idx ELSE phase = pname[idx]

  RETURN, phase
END   
