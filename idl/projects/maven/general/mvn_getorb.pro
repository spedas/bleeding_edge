;+
;FUNCTION:   mvn_getorb
;PURPOSE:
;  Wrapper for mvn_orbit_num that is quiet by default.
;  
;Typical CALLING SEQUENCE:
;  orbdata = mvn_getorb()
;
;KEYWORDS:
;  VERBOSE:        If set, then use default verbosity for mvn_orbit_num.
;                  This typically shows dozens of file download messages
;                  followed by a "floating illegal operand" error.
;
;                  If not set, then suppress all of the above.
;
;  REFRESH:        Refresh the orbit number database.
;
;Author: David Mitchell  - October, 2025
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-10-21 10:34:58 -0700 (Tue, 21 Oct 2025) $
; $LastChangedRevision: 33781 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_getorb.pro $
;-
function mvn_getorb, verbose=verbose, refresh=refresh

  common mvn_orbit_data, odat, tref

  quiet = ~keyword_set(verbose)
  refresh = keyword_set(refresh) or (size(odat,/type) ne 8)
  if (size(tref,/type) eq 5) then if (systime(/ut,/sec) gt (tref + 86400D)) then refresh = 1B

  if (refresh) then begin
    if (quiet) then dprint,' ', getdebug=bug, dlevel=4
    if (quiet) then dprint,' ', setdebug=0, dlevel=4
    odat = mvn_orbit_num()
    if (quiet) then dprint,' ', setdebug=bug, dlevel=4

    tref = systime(/ut,/sec)
  endif

  if (quiet) then i = check_math()

  return, odat

end
