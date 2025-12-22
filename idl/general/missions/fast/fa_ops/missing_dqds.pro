;	@(#)missing_dqds.pro	1.5	
;+
; NAME: missing_dqds
;
;
; PURPOSE: to check a SDT session for a set of required dqds
;
;
; CALLING SEQUENCE: missing = missing_dqds(required_dqds)
;
; 
; INPUTS: REQ_DQDS_CALL: a string or string array of dqds to look for in the
;         SDT session.
;
;
; KEYWORDS: The keyword ABSENT can be used to return the mising tag
;           names. If no dqds are missing, ABSENT contains the null
;           string on return. 
;           QUIET can be used to get MISSING_DQDS to not report
;           missing dqds to the user.
;
; OUTPUTS: The number of missing dqds is returned. A -1 is returned if
;           MISSING_DQDS was called incorrectly.
;
; MODIFICATION HISTORY: Written 19-August-1997 by Bill Peria, UCBerkeley
;                       Space Sciences Lab
;
;-


function missing_dqds, req_dqds_call, ABSENT = absent, QUIET = quiet

;
; check args...
;
req_dqds = strtrim(req_dqds_call,2)
;
; define absent, in case of early return...
;
absent = ''

dlist = get_dqds()

nreq = n_elements(req_dqds)
for i=0,nreq-1 do begin
    if (where(req_dqds(i) eq dlist))(0) lt 0 then begin
        if not defined(awol) then begin
            awol = req_dqds_call(i)
        endif else begin
            awol = [awol,req_dqds_call(i)]
        endelse
    endif
endfor

if defined(awol) then begin
    absent = awol
    if not keyword_set(quiet) then begin
        message,'The following DQDs were not found in the current SDT ' + $
          'session:',/continue
        print,absent
    endif
endif


return,n_elements(awol)
end

    







