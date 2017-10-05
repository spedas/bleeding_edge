;+
;PROCEDURE: 
;	mvn_swe_padmap_3d
;
;PURPOSE:
;	Map pitch angle for PAD or 3D distributions.  In either case, you must first
;   call mvn_swe_addmag to load MAG L1 or L2 data, rotate to SWEA coordinates, and
;   sample at the SWEA data times.
;
;CALLING SEQUENCE: 
;	mvn_swe_padmap_3d, data
;
;INPUTS: 
;       data:     An array of PAD or 3D structures.  For PAD structures, the
;                 appropriate tags are updated.  For 3D structures, the results 
;                 are added as new tags.
;
;KEYWORDS:
;
;CREATED BY:      D.L. Mitchell on 2014-09-24.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-08-04 17:15:05 -0700 (Tue, 04 Aug 2015) $
; $LastChangedRevision: 18398 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padmap_3d.pro $
;
;-
pro mvn_swe_padmap_3d, data

  @mvn_swe_com

  str_element, data, 'magf', magf, success=ok
  if (not ok) then begin
    print,"No magnetic field in structure!"
    return
  endif
  
  amp = sqrt(total(magf*magf,1))

  if (min(amp,/nan) lt 0.001) then begin
    print,"Oops!  Call mvn_swe_addmag first."
    return
  endif

  nrec = n_elements(data)
  n_a = data[0].nbins
  n_e = data[0].nenergy

  twopi = 2D*!dpi
  ddtor = !dpi/180D
  ddtors = replicate(ddtor, n_e)
  n = 17  ; patch size - odd integer

; Create structure tags to hold the pitch angle information.
; If data is a PAD structure, then these tags already exist
; and are simply overwritten with new information.  If data 
; is a 3D structure, then structure tags are added then 
; populated.  This method works for a single structure or an
; array of structures.  (str_element.pro cannot do this.)

  str_element, data, 'pa', success=pflg

  if (not pflg) then begin
    newstr = data[0]
    str_element, newstr, 'pa'    , fltarr(n_e, n_a), /add
    str_element, newstr, 'dpa'   , fltarr(n_e, n_a), /add
    str_element, newstr, 'pa_min', fltarr(n_e, n_a), /add
    str_element, newstr, 'pa_max', fltarr(n_e, n_a), /add
    str_element, newstr, 'iaz'   , intarr(n_a)     , /add
    str_element, newstr, 'jel'   , intarr(n_a)     , /add
    str_element, newstr, 'k3d'   , intarr(n_a)     , /add
    str_element, newstr, 'Baz'   , 0.              , /add
    str_element, newstr, 'Bel'   , 0.              , /add
    if (nrec gt 1L) then newstr = replicate(newstr, nrec)
    struct_assign, data, newstr
    data = temporary(newstr)
  endif

; Calculate the pitch angle information.

  for m=0L,(nrec-1L) do begin
    magu = magf[*,m]/amp[m]  ; unit vector in direction of B
     
    group = data[m].group
    Baz = atan(magu[1], magu[0])
    if (Baz lt 0.) then Baz += twopi
    Bel = asin(magu[2])

    if (pflg) then begin
      i = data[m].iaz
      j = data[m].jel
      k = data[m].k3d
    endif else begin
      k = indgen(n_a)
      i = k mod 16
      j = k / 16
    endelse

    daz = double((indgen(n*n) mod n) - (n-1)/2)/double(n-1) # double(swe_daz[i])
    Saz = reform(replicate(1D,n*n) # double(swe_az[i]) + daz, n*n*n_a) # ddtors

    Sel = dblarr(n*n*n_a, 64)
    for l=0,63 do begin
      del = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_del[j,l,group])
      Sel[*,l] = reform(replicate(1D,n*n) # double(swe_el[j,l,group]) + del, n*n*n_a)
    endfor
    Sel = Sel*ddtor

    Saz = reform(Saz, n*n, n_a, 64) ; nxn az-el patch, n_a pitch angle bins, 64 energies     
    Sel = reform(Sel, n*n, n_a, 64)
    pam = acos(cos(Saz - Baz)*cos(Sel)*cos(Bel) + sin(Sel)*sin(Bel))
     
    pa = average(pam, 1)      ; mean pitch angle
    pa_min = min(pam, dim=1)  ; minimum pitch angle
    pa_max = max(pam, dim=1)  ; maximum pitch angle
    dpa = pa_max - pa_min     ; pitch angle range
     
; Stuff result into structure
     
    data[m].pa     = transpose(float(pa))      ; mean pitch angles (radians)
    data[m].dpa    = transpose(float(dpa))     ; pitch angle widths (radians)
    data[m].pa_min = transpose(float(pa_min))  ; minimum pitch angle (radians)
    data[m].pa_max = transpose(float(pa_max))  ; maximum pitch angle (radians)

    if (not pflg) then begin
      data[m].iaz    = i                       ; anode bin (0-15)
      data[m].jel    = j                       ; deflector bin (0-5)
      data[m].k3d    = k                       ; 3D angle bin (0-95)
      data[m].Baz    = float(Baz)              ; Baz in SWEA coord. (radians)
      data[m].Bel    = float(Bel)              ; Bel in SWEA coord. (radians)
    endif

  endfor
  
  return

end
