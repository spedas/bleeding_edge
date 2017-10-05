
function spice_bodc2s,code
cspice_bodc2s,code,name
return,name
end


function spice_bods2c,name,found
cspice_bods2c,name,code,found
return,code
end


;+
; Function: SPICE_BOD2S
; Purpose:  returns true name (string) of a body given either the CODE or an alias string
; usage:
;   name = spice_bod2s(-202)
;   name = spice_bod2s('MAVEN_SC_BUS')   ; name set to 'MAVEN_SPACECRAFT'
;-
function spice_bod2s,nnn
if size(/type,nnn) eq 7 then name=spice_bodc2s(spice_bods2c(nnn)) else cspice_bodc2s,nnn,name
return,strupcase(name)
end


; Loads kernels only if they are not already loaded
pro spice_kernel_load,kernels,unload=unload,verbose=verbose,info=info,clear=clear
  if spice_test() eq 0 then return
  if keyword_set(clear) then begin
    cspice_kclear
    dprint,dlevel=2,'All kernels unloaded'
  endif
  if ~keyword_set(unload) then begin              ;  loading kernels
    loaded = spice_test('*')
    for i=0L,n_elements(kernels)-1 do begin
       w = where(kernels[i] eq loaded,nw)
       if nw eq 0 then begin
         if file_test(/regular , kernels[i]) eq 0 then continue
         dprint,verbose=verbose,dlevel=2,'Loading  '+kernels[i]
         cspice_furnsh,kernels[i]
       endif else dprint,verbose=verbose,dlevel=3,'Ignoring '+kernels[i] + ' (already loaded)'
    endfor
  endif else begin      ; Unloading kernels
    loaded = spice_test('*')
    k = strfilter(loaded,kernels,/str,count=c)
    c = c * keyword_set(k)
;    print,k
    for i=0,c-1 do begin
      dprint,dlevel=2,'Unloading '+k[i]
      cspice_unload,k[i]
    endfor
  endelse
  info = spice_kernel_info(verbose=1)   ; must be called to update cache of kernel info
end

