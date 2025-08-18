;+
; NAME:
;   rbsp_btrange (procedure)
;
; PURPOSE:
;     This routine is to find the starting time and ending time of each
;     continuous segment (burst, usually) of a give tplot variable which
;     essentially is specified by a tplot name such as 'rbspa_efw_eb2'.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_btrange, tvar, btrange = btrange, nbursts = nbursts, tind = tind, $
;                   tlen = tlen, structure = structure
;
; ARGUMENTS:
;   tvar: (INPUT, REQUIRED). The name of a tplot variable. If keyword STRUCTURE
;         is set, tvar should be a tplot data structure from get_data.
;
; KEYWORDS:
;    btrange: (OUTPUT, OPTIONAL) A named variable to return a 2D array as
;             [number_of_total_bursts, 2] which stores the the starting time and
;             the ending time of each continuous burst.
;    nbursts: (OUTPUT, OPTIONAL) A named variable to return the number of
;           bursts.
;    tind: (OUTPUT, OPTIONAL) A named variable to return a 2D array of the index
;           of starting and ending time points with structure
;           [[starting],[ending]]
;    tlen: (OUTPUT, OPTIONAL) A named variable to return the time lengths of
;          all bursts.
;    /structure: If set, tvar should be a tplot data structure.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-08-23: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
;-

pro rbsp_btrange, tvar, btrange = btrange, nbursts = nbursts, tind = tind, $
                  tlen = tlen, structure = structure

compile_opt idl2

;check if tvar valid
if ~keyword_set(structure) then begin
  con1 = n_elements(tvar) eq 0
  con2 = size(tvar, /type) ne 7
  con = con1 + con2
  if con gt 0 then begin
    dprint, 'Invalid tplot name. Returning...'
    return
  endif

  get_data, tvar, data=data
  if size(data,/type) ne 8 then begin
    dprint, 'The given tplot name does not contain valid data. Returning...'
    return
  endif
endif else data = tvar

tarr = data.x
nt = n_elements(tarr)

dtarr = tarr[1:nt-1] - tarr[0:nt-2]
dt = median(dtarr)
gap = 1.5 * dt
bind = where(dtarr gt gap, nbursts)
nbursts++
if nbursts gt 1 then begin
  bstart = [0, bind+1]                  ; starting index
  bend   = [bind, n_elements(dtarr)]       ; ending index
endif else begin
  bstart = [0]
  bend   = [n_elements(dtarr)]
endelse

; btrange = dblarr(2,nbursts)
; btrange[0,*] = tarr[bstart]
; btrange[1,*] = tarr[bend]

btrange = dblarr(nbursts, 2)
btrange[*, 0] = tarr[bstart]
btrange[*, 1] = tarr[bend]

tind = [[bstart],[bend]]
tlen = tarr[tind[*,1]] - tarr[tind[*,0]]

end
