;+
;PROCEDURE:   mvn_swe_sundir
;PURPOSE:
;  Calculates the direction of the Sun in SWEA coordinates.
;  Optionally, calculates the direction of the Sun in additional 
;  frames specified by keyword.  The results are stored in TPLOT 
;  variables.
;
;  Spacecraft frame:
;    X --> APP boom axis
;    Y --> +Y solar array axis
;    Z --> HGA axis
;
;  SWEA frame:
;    X --> boundary between Anodes 15 and 0
;    Y --> boundary between Anodes 3 and 4
;    Z --> instrument symmetry axis
;          (points "down" from top cap to pedestal)
;
;  When boom is deployed, Z_sc = Z_swea
;
;  If [X,Y,Z] is a unit vector, then
;    phi   = atan(Y,X)
;    theta = asin(Z)
;
;  Some important angles:
;
;    theta (deg)   : significance
;  ---------------------------------------------------------------
;    90 to 87      : entire sensor in shadow of pedestal
;    < 87          : toroidal grids illuminated
;    < 77          : upper deflector illuminated
;    < 37          : top cap (periphery) illuminated
;    17 to   0     : scalloped part of top cap illuminated
;     0 to -10     : photons enter gap between hemispheres
;  ---------------------------------------------------------------
;
;  Negative values of theta are very unlikely in practice, since it
;  means that the solar panels are facing away from the Sun.  The
;  grids and upper deflector often become illuminated during comm
;  passes and fly-Y.  The maximum angular separation between Earth
;  and the Sun as seen from Mars is 47.5 deg.
;
;  Toroidal grid support ribs are located every 45 degrees.  Each
;  rib is 7-deg wide at theta = 0, with centers at:
;
;    phi = 0, 45, 90, 135, 180, 225, 270, 315 degrees
;
;USAGE:
;  mvn_swe_sundir, trange
;
;INPUTS:
;       trange:   Time range for calculating the Sun direction.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default = 1, which is plenty
;                 fast to resolve spacecraft rotations.
;
;       PANS:     Named variable to hold the tplot variables created.
;
;       FRAME:    Also calculate the Sun direction in one or more 
;                 frames specified by this keyword.  Default = 'MAVEN_SWEA'
;
;       LIST:     List the key angles (as described above) and exit.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-03-01 14:50:37 -0800 (Wed, 01 Mar 2017) $
; $LastChangedRevision: 22886 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sundir.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_swe_sundir, trange, dt=dt, pans=pans, frame=frame, list=list

  if keyword_set(list) then begin
    print,' '
    print,'    theta (deg)   : significance'
    print,'  ---------------------------------------------------------------'
    print,'    90 to 87      : entire sensor in shadow of pedestal'
    print,'    < 87          : toroidal grids illuminated'
    print,'    < 77          : upper deflector illuminated'
    print,'    < 37          : top cap (periphery) illuminated'
    print,'    17 to   0     : scalloped part of top cap illuminated'
    print,'     0 to -10     : photons enter gap between hemispheres'
    print,'  ---------------------------------------------------------------'
    print,' '
    return
  endif

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init, trange=[tmin,tmax]

  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  
  if (size(frame,/type) ne 7) then frame = 'MAVEN_SWEA'

; First calculate the Sun direction in the spacecraft frame

  npts = floor((tmax - tmin)/dt) + 1L
  x = tmin + dt*dindgen(npts)
  y = replicate(1.,npts) # [1.,0.,0.]  ; MAVEN_SSO direction of Sun
  store_data,'Sun',data={x:x, y:y, v:indgen(3)}
  options,'Sun','labels',['X','Y','Z']
  options,'Sun','labflag',1
  options,'Sun',spice_frame='MAVEN_SSO',spice_master_frame='MAVEN_SPACECRAFT'
  spice_vector_rotate_tplot,'Sun','MAVEN_SPACECRAFT',trange=[tmin,tmax],check='MAVEN_SPACECRAFT'
  
  pans = ['Sun_MAVEN_SPACECRAFT']

; Next calculate the Sun direction in frame(s) specified by keyword FRAME
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'Sun',to_frame,trange=[tmin,tmax],check='MAVEN_SPACECRAFT'
    pans = [pans, ('Sun_' + to_frame)]

    if (to_frame eq 'MAVEN_SWEA') then begin
      get_data,('Sun_' + to_frame),data=sun
      xyz_to_polar, sun, theta=the, phi=phi, /ph_0_360
      store_data,'Sun_The',data=the
      store_data,'Sun_Phi',data=phi
      options,'Sun_The','ynozero',1
      options,'Sun_Phi','ynozero',1
      options,'Sun_The','psym',3
      options,'Sun_Phi','psym',3
      options,'Sun_Phi','constant',[0, 45, 90, 135, 180, 225, 270, 315]  ; ribs
      options,'Sun_The','constant',[-10, 0, 17, 37, 77, 87]  ; see header info
  
      pans = [pans, 'Sun_The','Sun_Phi']
    endif

  endfor

  return

end
