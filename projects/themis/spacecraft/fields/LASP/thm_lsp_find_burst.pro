;+
;PRO: THM_LSP_FIND_BURST
;
;           NOT FOR GENERAL USE. 
;
;PURPOSE:
;    Isolate an indivitual burst for analysis. 
;
;INPUT:
;    Data          -NEEDED. A data structure
;    tfind         -OPTIONAL. Time of interest.
;
;KEYWORD:
;
;HISTORY:
;   2009-05-30: REE. Broke out to run with wave burst.
;-

pro thm_lsp_find_burst, data, tfind, tstart=tstart,  tend=tend, $
                        istart=istart, iend=iend, nbursts=nbursts, mdt=mdt

tstart = -1
tend   = -1 
istart = -1 
iend   = -1

; CHECK INPUT
IF (size(/type,data) NE 8) then BEGIN
  print, 'THM_LSP_FIND_BURST: Data not valid. Exiting...'
  return
ENDIF

; FIND CONTINOUS DATA STRETCHES
t        = data.x
dt       = t(1:*)-t(*)
mdt      = median(dt)
ind      = where(dt GT 2.0*mdt, nbursts)
nbursts  = (nbursts+1)                   ; NUMBER OF INDIVIDUAL BURSTS
IF nbursts GT 1 then BEGIN
  istart = [0L, ind+1]                   ; STARTING INDEX
  iend   = [ind, n_elements(t)-1L]       ; ENDING INDEX
ENDIF ELSE BEGIN
  istart = [0L]
  iend   = [n_elements(t)-1L]
ENDELSE

tstart = t(istart)
tend   = t(iend)

; ISOLATE DESIRED BURST
IF keyword_set(tfind) then BEGIN
  ind = where( (tfind GE tstart) AND (tfind LE tend), nind )
  IF nind GT 0 then BEGIN
    istart = istart(ind)
    iend   = iend(ind)
    tstart = t(istart)
    tend   = t(iend)
  ENDIF ELSE BEGIN
    print, 'THM_LSP_FIND_BURST: No burst available at selected time...'
    tstart = -1
    tend   = -1 
    istart = -1 
    iend   = -1
  ENDELSE
ENDIF
return
end


