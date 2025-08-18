;+
;PROCEDURE:   mvn_swe_addmag
;PURPOSE:
;  Loads MAG data from L2 or L1 save/restore files, rotates the MAG vectors to
;  the SWEA frame, and stores the result in the SWEA common block for quick
;  access by mvn_swe_getpad and mvn_swe_get3d.
;
;  Note: If L2ONLY is set and L2 MAG PL data are unavailable, then this routine
;  will attempt to load L2 MAG PC data and rotate to the PL frame using SPICE.
;  This introduces a small error in the MAG vector direction that propagates 
;  from uncertainties in the spacecraft ck kernel.  The error is typically 
;  ~0.01 deg, except during spacecraft rotations when it can reach ~0.1 deg.
;  These errors are negligible compared with the SWEA angular resolution of 
;  ~20 degrees, so pitch angle mapping remains accurate.
;
;USAGE:
;  mvn_swe_addmag
;
;INPUTS:
;
;KEYWORDS:
;
;    FULL:          The default priority order for loading is (highest to lowest):
;                     L2_1SEC, L2_FULL, L1_1SEC, L1_FULL.
;
;                   If set, then the priority order is: L2_FULL, L1_FULL.
;
;    USEPADMAG:     If all else fails, then use the PAD angles as calculated 
;                   onboard.  In the best case, this close to MAG L1, except the
;                   angular resolution is reduced (256 azimuths, 40 elevations).
;                   In the worst case, it can be off by 10's of degrees.  Use with
;                   caution!  Default = 0 (never use PAD angles).  If PAD angles
;                   are used, the MAG level is set to zero.
;
;    L2ONLY:        Insist on loading L2 data.  (Useful for generating PDS data.)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-03 12:01:10 -0700 (Tue, 03 Jun 2025) $
; $LastChangedRevision: 33364 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addmag.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addmag, full=full, usepadmag=usepadmag, l2only=l2only

  @mvn_swe_com
  
  swe_mag1 = 0
  maglev = 'L0'
  usepadmag = keyword_set(usepadmag)
  l2only = keyword_set(l2only)
  if (l2only) then usepadmag = 0

; Get the highest level MAG data available

  i = find_handle('mvn_B_1sec', verbose=-1)
  if (i gt 0) then store_data, 'mvn_B_1sec', /delete
  mvn_mag_load, 'L2_1SEC', mag_frame='pl', l2only=l2only, verbose=-1
  get_data, 'mvn_B_1sec', data=mag1, alim=lim, index=i

  if (i eq 0) then begin
    print,"No L2 MAG PL data found!"
    if (l2only) then begin  ; try to load l2 pc data as a last resort
      i = find_handle('mvn_B_1sec_MAVEN_SPACECRAFT', verbose=-1)
      if (i gt 0) then store_data, 'mvn_B_1sec_MAVEN_SPACECRAFT', /delete
      mvn_mag_load, 'L2_1SEC', mag_frame='pc', spice_frame='spacecraft', l2only=l2only, verbose=-1
      get_data, 'mvn_B_1sec_MAVEN_SPACECRAFT', data=mag1, alim=lim, index=i
      if (i eq 0) then print,"No L2 MAG PC data found!" $
                  else print,"Using L2 MAG PC data instead."
    endif
  endif

  if (i eq 0) then begin
    if (usepadmag) then begin
      print,"*****************************************"
      print,"WARNING: USING PAD MAG ANGLES"
      print,"For rough estimates only - not for publication"
      print,"*****************************************"

      y = fltarr(n_elements(a2),3)
      mvn_swe_magdir, a2.time, a2.Baz, a2.Bel, Baz, Bel
      y[*,0] = cos(Baz)*cos(Bel)
      y[*,1] = sin(Baz)*cos(Bel)
      y[*,2] = sin(Bel)
      mag1 = {x:(a2.time + 1.5D), y:y}
      lim = {level:'L0'}
    endif else return
  endif

  str_element, lim, 'level', maglev, success=ok
  case strupcase(maglev) of
    'L0' : maglev = 0
    'L1' : maglev = 1
    'L2' : maglev = 2
    else : maglev = 0
  endcase

; Rotate to the SWEA frame using same code as flight software (no SPICE)
  
  if (maglev gt 0) then begin
    print, string(maglev,format='("Using MAG L",i1," data.")')

    indx = where(mag1.x lt t_mtx[2], nstow, complement=jndx, ncomplement=ndeploy)

    if (nstow gt 0L) then begin
      print,"Using stowed boom rotation matrix for MAG1"
      mag1.y[indx,*] = rotate_mag_to_swe(mag1.y[indx,*], magu=1, /stow, /payload)
    endif
    if (ndeploy gt 0L) then begin
      print,"Using deployed boom rotation matrix for MAG1"
      mag1.y[jndx,*] = rotate_mag_to_swe(mag1.y[jndx,*], magu=1, /payload)
    endif
  endif

; Store the result in the SWEA common block

  if (size(swe_mag_struct,/type) ne 8) then mvn_swe_struct

  swe_mag1 = replicate(swe_mag_struct, n_elements(mag1.x))
  swe_mag1.time = mag1.x
  swe_mag1.magf = transpose(mag1.y)

  swe_mag1.Bamp = sqrt(total(mag1.y * mag1.y, 2))
  swe_mag1.Bphi = atan(mag1.y[*,1], mag1.y[*,0])
  indx = where(swe_mag1.Bphi lt 0., count)
  if (count gt 0L) then swe_mag1[indx].Bphi += (2.*!pi)
  swe_mag1.Bthe = asin(mag1.y[*,2]/swe_mag1.Bamp)

  swe_mag1.level = maglev
  swe_mag1.valid = 1B

; Store results and comparisons in TPLOT variables

  store_data,'Bphi1',data={x:swe_mag1.time, y:swe_mag1.Bphi*!radeg}
  store_data,'Bthe1',data={x:swe_mag1.time, y:swe_mag1.Bthe*!radeg}
  store_data,'Bamp1',data={x:swe_mag1.time, y:swe_mag1.Bamp}

  ylim,'Bphi1',0,360,0
  options,'Bphi1','yticks',4
  options,'Bphi1','yminor',3
  options,'Bphi1','psym',3
  options,'Bphi1','ytitle','Bphi (deg)'

  ylim,'Bthe1',-90,90,0
  options,'Bthe1','yticks',2
  options,'Bthe1','yminor',3
  options,'Bthe1','psym',3
  options,'Bthe1','ytitle','Bthe (deg)'

  ylim,'Bamp1',0.1,500,1
  options,'Bamp1','ytitle','|B| (nT)'

; Compare MAG1 angles with SWEA PAD angles

  get_data,'swe_mag_svy',data=foo
  
  if (size(foo,/type) eq 8) then begin
    store_data,'Sphi',data={x:foo.x, y:foo.y[*,0]}
    store_data,'Sthe',data={x:foo.x, y:foo.y[*,1]-90.}
    store_data,'PAD_Phi',data=['Bphi1','Sphi']
    store_data,'PAD_The',data=['Bthe1','Sthe']
    ylim,'PAD_Phi',0,360,0
    options,'PAD_Phi','ytitle','PAD Phi'
    options,'PAD_Phi','yticks',4
    options,'PAD_Phi','yminor',3
    ylim,'PAD_The',-90,90,0
    options,'PAD_The','ytitle','PAD The'
    options,'PAD_The','yticks',2
    options,'PAD_The','yminor',3
    options,'Sphi','color',2
    options,'Sthe','color',2
    options,'Sphi','psym',3
    options,'Sthe','psym',3
  endif

  return

end
