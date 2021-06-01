; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-30 19:48:04 -0700 (Sun, 30 May 2021) $
; $LastChangedRevision: 30012 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_kernel_load.pro $
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
  info = spice_kernel_info(verbose=1)   ; must be called to update cache of kernel info
end

