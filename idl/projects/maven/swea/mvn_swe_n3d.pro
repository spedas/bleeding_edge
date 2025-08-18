;+
;PROCEDURE: 
;	mvn_swe_n3d
;PURPOSE:
;	Determines density from a 3D distribution.  Adapted from McFadden's n_3d.pro.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_n3d
;INPUTS: 
;KEYWORDS:
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-06-23 12:34:13 -0700 (Fri, 23 Jun 2023) $
; $LastChangedRevision: 31909 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_n3d.pro $
;
;-

pro mvn_swe_n3d, ebins=ebins, abins=abins, dbins=dbins, obins=obins, mask_sc=mask_sc, $
                 pans=pans, archive=archive, sec=sec

  compile_opt idl2

  @mvn_swe_com

  tiny = 1.d-31

; Make sure data are loaded

  if ((size(swe_3d,/type) ne 8) and (size(mvn_swe_3d,/type) ne 8)) then begin
    print,"Load SWEA data first."
    return
  endif
  
  if (size(swe_sc_pot,/type) ne 8) then begin
    print,"No spacecraft potential.  Use mvn_scpot."
    return
  endif

; Solid angle bin masking

  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then begin
    obins = replicate(1B, 96, 2)
    obins[*,0] = reform(abins # dbins, 96)
    obins[*,1] = obins[*,0]
  endif else obins = byte(obins # [1B,1B])
  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then obins = swe_sc_mask * obins

; Process data

  if keyword_set(archive) then aflg = 1 else aflg = 0

  if (aflg) then begin
    if (size(mvn_swe_3d_arc,/type) eq 8) then t = mvn_swe_3d_arc.time $
                                         else t = swe_3d_arc.time 
  endif else begin
    if (size(mvn_swe_3d,/type) eq 8) then t = mvn_swe_3d.time $
                                     else t = swe_3d.time 
  endelse
  
  npts = n_elements(t)
  density = fltarr(npts)
  
  for i=0L,(npts-1L) do begin
    ddd = mvn_swe_get3d(t[i],archive=aflg,units='eflux')
    if (dosec) then begin
      mvn_swe_secondary, ddd
      bkg = ddd.bkg
      indx = where(~ddd.valid, count)
      if (count gt 0L) then begin
        eflux[indx] = tiny
        var[indx] = tiny
        bkg[indx] = 0.
      endif
    endif else bkg[*] = 0.

    if (ddd.time gt t_mtx[2]) then boom = 1 else boom = 0
    density[i] = swe_n_3d(ddd,ebins=ebins,obins=obins[*,boom])
  endfor
  
; Create TPLOT variables

  store_data,'swe_3d_n',data={x:t, y:density}
  options,'swe_3d_n','ytitle','Ne (1/cc)'
  pans = ['swe_3d_n']
  
  return

end
