;+
;PROCEDURE: 
;	swe_3d_strahl_dir
;PURPOSE:
;	Determines the direction in SWEA coordinates of the strahl.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	swe_3d_strahl_dir
;INPUTS: 
;KEYWORDS:
;       SMO:           Set smoothing in energy and angle.  Since there are only six
;                      theta bins, smoothing in that dimension is not recommended.
;
;                        smo = [n_energy, n_phi, n_theta]  ; default = [5,3,1]
;
;       ENERGY:        Energy at which to calculate the symmetry direction.  Should
;                      be > 100 eV.  Using the SMO keyword also helps.
;                      Default = 130.
;
;       POWER:         Weighting function is proportional to eflux^power.  Higher
;                      powers emphasize the peak of the distribution; lower powers
;                      give more weight to surrounding cells.  Default = 2.
;
;       PANS:          Named variable to hold TPLOT variable names created.
;
;       RESULT:        Named variable to hold the result.
;
;       ARCHIVE:       Use archive data instead of survey data.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-10-18 15:24:35 -0700 (Tue, 18 Oct 2016) $
; $LastChangedRevision: 22134 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_3d_strahl_dir.pro $
;
;-

pro swe_3d_strahl_dir, result=result, energy=energy, power=pow, smo=smo, pans=pans, $
                       archive=archive

  compile_opt idl2

  @mvn_swe_com
  
; Make sure data are loaded

  if keyword_set(archive) then aflg = 1 else aflg = 0

  if (aflg) then begin
    if ((size(swe_3d_arc,/type) ne 8) and (size(mvn_swe_3d_arc,/type) ne 8)) then begin
      print,"No 3D archive data loaded."
      return
    endif
  endif else begin
    if ((size(swe_3d,/type) ne 8) and (size(mvn_swe_3d,/type) ne 8)) then begin
      print,"No 3D survey data loaded."
      return
    endif
  endelse
    
  units = 'crate'
  
  if (aflg) then begin
    if (size(mvn_swe_3d_arc,/type) eq 8) then t = mvn_swe_3d_arc.time $
                                         else t = swe_3d_arc.time
  endif else begin
    if (size(mvn_swe_3d,/type) eq 8) then t = mvn_swe_3d.time $
                                     else t = swe_3d.time
  endelse

  npts = n_elements(t)
  sphi = fltarr(npts)
  sthe = sphi
  Baz = sphi
  Bel = sphi
  the_min = sphi
  the_max = sphi

  if (n_elements(smo) gt 0) then begin
    nsmo = [1,1,1]
    for i=0,(n_elements(smo)-1) do nsmo[i] = round(smo[i])
    dosmo = 1
  endif else begin
    nsmo = [5,3,1]
    dosmo = 1
  endelse

  if not keyword_set(energy) then energy = 130.

  if not keyword_set(pow) then pow = 3.
  
  indx = where(t gt t_mtx[2], count)
  if (count gt 0L) then i_deploy = indx[0] else i_deploy = npts

; Loop through data and get peak direction

  i = 0L
  ddd = mvn_swe_get3d(t[i],units=units,archive=aflg)
  e = ddd.energy[*,0]
  de = min(abs(e - energy), ebin)

  if (dosmo) then begin
    ddat = reform(ddd.data,64,16,6)
    dat = fltarr(64,32,6)
    dat[*,8:23,*] = ddat
    dat[*,0:7,*] = ddat[*,8:15,*]
    dat[*,24:31,*] = ddat[*,0:7,*]
    dats = smooth(dat,nsmo)
    ddd.data = reform(dats[*,8:23,*],64,96)
  endif

  f = reform(ddd.data[ebin,*],16,6)
  phi = (reform(ddd.phi[ebin,*],16,6))[*,0]
  the = (reform(ddd.theta[ebin,*],16,6))[0,*]

  if (i lt i_deploy) then begin
    f[*,0:1] = 0.
    the_max[i] = max(the)
    the_min[i] = min(the[2:*])
  endif else begin
    the_max[i] = max(the)
    the_min[i] = min(the)
  endelse
        
  fmax = max(f,k)
  k = k mod 16

  faz = total((f/fmax)^pow,2)
  faz = (faz - mean(faz)) > 0.
  k = (k + 9) mod 16
  az = shift(phi,-k)
  if (k gt 0) then az[16-k:*] = az[16-k:*] + 360.
  faz = shift(faz,-k)
  m = indgen(9) + 3
  sphi[i] = (total(az[m]*faz[m])/total(faz[m]) + 360.) mod 360.

  el = reform(the,6)
  f = shift(f,-k,0)
  fel = total((f[m,*]/fmax)^pow,1)
  fel = (fel - mean(fel)) > 0.
  sthe[i] = total(el*fel^pow)/total(fel^pow)
  
  ok = 0

  if (size(mvn_swe_pad,/type) eq 8) then begin
    dt = min(abs(mvn_swe_pad.time - ddd.time),j)
    Baz[i] = mvn_swe_pad[j].Baz*!radeg
    Bel[i] = mvn_swe_pad[j].Bel*!radeg
    ok = 1
  endif
  
  if ((not ok) and (size(a2,/type) eq 8)) then begin
    dt = min(abs(a2.time - ddd.time),j)
    mvn_swe_magdir, a2[j].time, a2[j].Baz, a2[j].Bel, aBaz, aBel
    Baz[i] = aBaz*!radeg
    Bel[i] = aBel*!radeg
  endif

  for i=1L,(npts-1L) do begin
    ddd = mvn_swe_get3d(t[i],units=units,archive=aflg)

    if (dosmo) then begin
      ddat = reform(ddd.data,64,16,6)
      dat = fltarr(64,32,6)
      dat[*,8:23,*] = ddat
      dat[*,0:7,*] = ddat[*,8:15,*]
      dat[*,24:31,*] = ddat[*,0:7,*]
      dats = smooth(dat,nsmo)
      ddd.data = reform(dats[*,8:23,*],64,96)
    endif

    f = reform(ddd.data[ebin,*],16,6)
    phi = (reform(ddd.phi[ebin,*],16,6))[*,0]
    the = (reform(ddd.theta[ebin,*],16,6))[0,*]

    if (i lt i_deploy) then begin
      f[*,0:1] = 0.
      the_max[i] = max(the)
      the_min[i] = min(the[2:*])
    endif else begin
      the_max[i] = max(the)
      the_min[i] = min(the)
    endelse
        
    fmax = max(f,k)
    k = k mod 16

    faz = total((f/fmax)^pow,2)
    faz = (faz - mean(faz)) > 0.
    k = (k + 9) mod 16
    az = shift(phi,-k)
    if (k gt 0) then az[16-k:*] = az[16-k:*] + 360.
    faz = shift(faz,-k)
    m = indgen(9) + 3
    sphi[i] = (total(az[m]*faz[m])/total(faz[m]) + 360.) mod 360.

    el = reform(the,6)
    f = shift(f,-k,0)
    fel = total((f[m,*]/fmax)^pow,1)
    fel = (fel - mean(fel)) > 0.
    sthe[i] = total(el*fel)/total(fel)

    ok = 0

    if (size(mvn_swe_pad,/type) eq 8) then begin
      dt = min(abs(mvn_swe_pad.time - ddd.time),j)
      Baz[i] = mvn_swe_pad[j].Baz*!radeg
      Bel[i] = mvn_swe_pad[j].Bel*!radeg
      ok = 1
    endif

    if ((not ok) and (size(a2,/type) eq 8)) then begin
      dt = min(abs(a2.time - ddd.time),j)
      mvn_swe_magdir, a2[j].time, a2[j].Baz, a2[j].Bel, aBaz, aBel
      Baz[i] = aBaz*!radeg
      Bel[i] = aBel*!radeg
    endif
  endfor

  result = {time:t, theta:sthe, phi:sphi, Baz:Baz, Bel:Bel}

; Create TPLOT variables

  store_data,'Baz',data={x:t, y:Baz}
  store_data,'Bel',data={x:t, y:Bel}
  store_data,'Saz',data={x:t, y:sphi}
  store_data,'Sel',data={x:t, y:sthe}
  options,'Baz','psym',3
  options,'Bel','psym',3
  options,'Saz','psym',4
  options,'Sel','psym',4
  options,'Saz','color',6
  options,'Sel','color',6
  options,'Saz','symsize',0.5
  options,'Sel','symsize',0.5

  store_data,'Saz2',data={x:t, y:(sphi + 180.) mod 360.}
  store_data,'Sel2',data={x:t, y:-sthe}
  options,'Saz2','psym',4
  options,'Sel2','psym',4
  options,'Saz2','color',2
  options,'Sel2','color',2
  options,'Saz2','symsize',0.5
  options,'Sel2','symsize',0.5

  store_data,'Sel_min',data={x:t, y:the_max}
  store_data,'Sel_max',data={x:t, y:the_min}
  options,'Sel_min','linestyle',2
  options,'Sel_max','linestyle',2
  options,'Sel_min','color',4
  options,'Sel_max','color',4

  get_data,'Bphi1',index=i
  if (i gt 0) then store_data,'SYM_Phi',data=['Bphi1','Saz','Saz2'] $
              else store_data,'SYM_Phi',data=['Baz','Saz','Saz2']

  get_data,'Bthe1',index=i
  if (i gt 0) then store_data,'SYM_The',data=['Bthe1','Sel','Sel2','Sel_min','Sel_max'] $
              else store_data,'SYM_The',data=['Bel','Sel','Sel2','Sel_min','Sel_max']

  ylim,'SYM_Phi',0,360,0
  options,'SYM_Phi','ytitle','SYM Phi'
  options,'SYM_Phi','yticks',4
  options,'SYM_Phi','yminor',3

  ylim,'SYM_The',-90,90,0
  options,'SYM_The','ytitle','SYM The'
  options,'SYM_The','yticks',2
  options,'SYM_The','yminor',3

  pans = ['SYM_Phi','SYM_The']

  return

end
