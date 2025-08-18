;+
; NAME:
;     thm_lsp_clean_timestamp (PROCEDURE)
;
; PURPOSE:
;     Clean a given tplot variable so that its time stamp is exactly monotonic.
;     The basic idea for doing that is just to toss one or more data points that
;     overlap others in time.
;
; CALLING SEQUENCE:
;     thm_lsp_clean_timestamp, tvar, newname = newname
;
; ARGUMENTS:
;     tvar: (input, required) A string of a tplot variable name. 
;
; KEYWORDS:
;     newname: (input, optional) A string as the name of the cleaned tplot data.
;
; HISTORY:
;     2010-01-27: Created by Jianbao Tao, CU/LASP.
;
;+

pro thm_lsp_clean_timestamp, tvar, newname=newname

; check tvar
if n_elements(tvar) eq 0 then begin
   print, 'THM_LSP_CLEAN_TIMESTAMP: ' + $
      'A string of a tplot variable name must be given. Exiting...'
   return
endif
tmp =size(tvar, /type)
if tmp ne 7 then begin
   print, 'THM_LSP_CLEAN_TIMESTAMP: ' + $
      'The input type must be string. Exiting...'
   return
endif
tmp = size(tvar, /dim)
if tmp gt 0 then begin
   print, 'THM_LSP_CLEAN_TIMESTAMP: ' + $
      'The input must be a scalar. Exiting...'
   return
endif
tmp = tnames(tvar)
if strlen(tmp) eq 0 then begin
   print, 'THM_LSP_CLEAN_TIMESTAMP: ' + $
      'The tplot variable ' + tname + ' does not exist on memory. Exiting...'
   return
endif

if n_elements(newname) eq 0 then newname = tvar
tmp =size(newname, /type)
if tmp ne 7 then begin
   print, 'THM_LSP_CLEAN_TIMESTAMP: ' + $
      'The newname must be string. Exiting...'
   return
endif

get_data, tvar, data=data, dlim=dlim

; get info of the structure data
ydim = size(data.y, /dim)
str_element, data, 'v', success = success
if success then vdim = size(data.v,/dim)

tarr = data.x - data.x[0]

; get the indices of the points to be tossed.
nt = n_elements(data.x)
badpts = 0L
last = tarr[0]
for i = 1L, nt-1 do begin
   if tarr[i] le last then begin
      badpts = badpts + 1
      if badpts eq 1 then ind = i
      if badpts gt 1 then ind = [ind, i]
   endif else begin
      last = tarr[i]
   endelse
endfor

if badpts eq 0 then begin
   print, 'THM_LSP_CLEAN_TIMESTAMP: ' +  $
      'The time stamp of the input tplot variable is already monotonic. No'+$
      ' cleaning needed. Returning...'
   return
endif

print, 'THM_LSP_CLEAN_TIMESTAMP: ' +  $
   String(badpts, format='(I0)') + ' bad points have been tossed.'

tarr = data.x
tarr[ind] = !values.d_nan
new_ind = where(finite(tarr))
newt = tarr[new_ind]
newy = data.y[new_ind, *]
if success then begin
   newv = data.v[new_ind, *]
   store_data, newname, data={x:newt, y:newy, v:newv}, dlim=dlim
endif else begin
   store_data, newname, data={x:newt, y:newy}, dlim=dlim
endelse

end

