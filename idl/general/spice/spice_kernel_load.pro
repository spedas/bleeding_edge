; $LastChangedBy: hara $
; $LastChangedDate: 2022-06-24 14:34:59 -0700 (Fri, 24 Jun 2022) $
; $LastChangedRevision: 30882 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_kernel_load.pro $
; Loads kernels only if they are not already loaded
pro spice_kernel_load,kernels,unload=unload,verbose=verbose,info=info,clear=clear,maxiv=maxiv
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
        dprint,verbose=verbose,dlevel=2,'Loading '+file_info_string(kernels[i])
        cspice_furnsh,kernels[i]
      endif else dprint,verbose=verbose,dlevel=2,'Ignoring already loaded kernel '+file_info_string(kernels[i])
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
  info = spice_kernel_info(verbose=1,maxiv=maxiv)   ; must be called to update cache of kernel info
end

