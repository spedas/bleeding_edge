;+
; NAME:
;     THM_JBT_GET_BTRANGE (FUNCTION)
;
; PURPOSE:
;     This routine is to find the starting time and ending time of each
;     continuous section of a give tplot variable which essentially is specified
;     by a tplot name such as 'tha_efp'.
;     If the routine exit unsuccessfully, it will return -1. Otherwise, it will
;     return a 2D array as [2,number_of_total_bursts] which stores the
;     the starting time and the ending time of each continuous section.
;
; CALLING SEQUENCE:
;     btrange = thm_jbt_get_btrange(tvar, nbursts=nbursts, tind=tind)
;
; ARGUMENTS: 
;    tvar: (INPUT, REQUIRED). The name of a tplot variable.
;
; KEYWORDS:
;    nbursts: (OUTPUT, OPTIONAL) A named variable to return the number of
;           sections.
;    tind: (OUTPUT, OPTIONAL) A named variable to return a 2D array of the index
;           of starting and ending time points with structure
;           [[starting],[ending]]
; 
; EXAMPLES:
;     tvar = 'tha_efp'
;     btrange = thm_jbt_get_btrange(tvar, nb = nb, tind = tind)
;
;HISTORY:
;    2009-05-04, written by Jianbao Tao, in CU/LASP.
;    2010-04-08: Updated the help information. JBT, CU/LASP.
;
;-

function thm_jbt_get_btrange, tvar, nbursts=nbursts, tind=tind, tlen = tlen

;check if tvar valid
con1 = n_elements(tvar) eq 0
con2 = size(tvar, /type) ne 7
con = con1 + con2
if con gt 0 then begin
  print, 'THM_EFI_GET_BTRANGE: ' + $
         'A valid efp or efw tplot variable name must be provided. Returning...'
  return, -1
endif

get_data, tvar, data=data
if size(data,/type) ne 8 then begin
  print, 'THM_EFI_GET_BTRANGE: ' + $
         'The given tplot name does not contain valid data. Returning...'
  return, -1
endif

tarr = data.x
nt = n_elements(tarr)

dtarr = tarr[1:nt-1] - tarr[0:nt-2]
dt = median(dtarr)
gap = 1.5 * dt
bind = where(dtarr gt gap, nbursts)
nbursts = (nbursts+1)
IF nbursts GT 1 then BEGIN
  bstart = [0, bind+1]                  ; STARTING INDEX
  bend   = [bind, n_elements(dtarr)]       ; ENDING INDEX
ENDIF ELSE BEGIN
  bstart = [0]
  bend   = [n_elements(dtarr)]
ENDELSE

btrange = dblarr(2,nbursts)
btrange[0,*] = tarr[bstart]
btrange[1,*] = tarr[bend]

tind = [[bstart],[bend]]
tlen = tarr[tind[*,1]] - tarr[tind[*,0]]

return, btrange

end
