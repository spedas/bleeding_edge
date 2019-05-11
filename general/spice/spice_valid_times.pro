;+
;Function: 
;
;Purpose: ;
; Author: Davin Larson  
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
function spice_valid_times,et,objects=objects,force_objects=force_objects,tolerance=tol
if spice_test() eq 0 then message,'SPICE not installed'
if ~keyword_set(tol) then tol=120.
kinfo = spice_kernel_info(use_cache=1)
ok = et ne 0  ; get array of 1b     
for j=0,n_elements(objects)-1 do begin
  cspice_bods2c,objects[j],code,found ;body code
  if ~found then cspice_namfrm,objects[j],code ;frame code
  if code ne 0 then found=1
  nw = 0
  if found and keyword_set(kinfo) then  w = where(kinfo.obj_code eq code ,nw)
  if nw ne 0 then begin
    nvalid = replicate(0,n_elements(et))
    for i=0,nw-1 do begin
        s = kinfo[w[i]]
        etr = time_ephemeris(s.trange)
        nvalid +=  ( (et ge (etr[0]+tol)) and (et le (etr[1]-tol)) )
    endfor
    ok = ok and (nvalid ne 0)
  endif else  begin
    if keyword_set(force_objects) then begin
      dprint,objects[j],' Not found. Forced zero valid times'
      return,0*ok
    endif else  dprint,objects[j],' Not found. (Ignoring)'
  endelse
endfor
return,ok
end


