;+
;PROCEDURE:   mvn_sundir
;PURPOSE:
;  Determines the direction of the Sun at the position of the spacecraft in
;  one or more coordinate frames.  The results are stored in TPLOT variables.
;
;  You must have SPICE installed for this routine to work.  If SPICE is 
;  already initialized (e.g., mvn_swe_spice_init), this routine will use the 
;  current loadlist.  Otherwise, this routine will try to initialize SPICE
;  based on the current timespan.
;
;USAGE:
;  mvn_sundir, trange
;
;INPUTS:
;       trange:   Optional.  Time range for calculating the Sun direction.
;                 If not specified, then use current range set by timespan.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default = 1.
;
;       FRAME:    String or string array for specifying one or more frames
;                 to transform the Sun direction into.  Any frame recognized
;                 by SPICE is allowed.  The default is 'MAVEN_SPACECRAFT'.
;                 Other possibilities are: 'MAVEN_APP', 'MAVEN_STATIC', etc.
;                 Type 'mvn_frame_name(/list)' to see a full list of frames.
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Phi = atan(y,x)*!radeg  ; [  0, 360]
;                    The = asin(z)*!radeg    ; [-90, +90]
;
;       PANS:     Named variable to hold the tplot variables created.  For the
;                 default frame, this would be 'Sun_MAVEN_SPACECRAFT'.
;
;       SUCCESS:  Returns 1 on normal completion, 0 otherwise.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-09-24 15:48:26 -0700 (Tue, 24 Sep 2019) $
; $LastChangedRevision: 27792 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_sundir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_sundir, trange, dt=dt, pans=pans, frame=frame, polar=polar, success=success

  success = 0

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

; If SPICE is not initialized at all, then load kernels now.  Otherwise, use
; the kernels already loaded.

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then begin
    mvn_swe_spice_init, trange=[tmin,tmax]
    mk = spice_test('*', verbose=-1)
    indx = where(mk ne '', count)
    if (count eq 0) then begin
      print,"Insufficient SPICE coverage in requested time range."
      return
    endif
  endif

  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  dopol = keyword_set(polar)
  
  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'
  frame = mvn_frame_name(frame, success=i)
  gndx = where(i, count)
  if (count eq 0) then begin
    print,"No valid frames."
    return
  endif
  frame = frame[i[gndx]]

; First store the Sun direction in MAVEN_SSO coordinates

  npts = floor((tmax - tmin)/dt) + 1L
  x = tmin + dt*dindgen(npts)
  y = replicate(1.,npts) # [1.,0.,0.]
  store_data,'Sun',data={x:x, y:y, v:indgen(3)}
  options,'Sun','ytitle','Sun (MSO)'
  options,'Sun','labels',['X','Y','Z']
  options,'Sun','labflag',1
  options,'Sun',spice_frame='MAVEN_SSO',spice_master_frame='MAVEN_SPACECRAFT'

; Next calculate the Sun direction in frame(s) specified by keyword FRAME

  pans = ['']
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'Sun',to_frame,trange=[tmin,tmax],check='MAVEN_SPACECRAFT'

    labels = ['X','Y','Z']
    pname = 'Sun_' + to_frame
    fname = strmid(to_frame, strpos(to_frame,'_')+1)
    case fname of
      'SPACECRAFT' : fname = 'PL'
      'IAU_MARS'   : fname = 'Mars'
      'APP'        : labels = ['I','J','K']
      else         : ; do nothing
    endcase
    options,pname,'ytitle','Sun (' + fname + ')'
    options,pname,'colors',[2,4,6]
    options,pname,'labels',labels
    options,pname,'labflag',1
    options,pname,spice_frame=to_frame,spice_master_frame='MAVEN_SPACECRAFT'
    pans = [pans, pname]

    if (dopol) then begin
      get_data, pname, data=sun
      xyz_to_polar, sun, theta=the, phi=phi, /ph_0_360

      the_name = 'Sun_' + fname + '_The'
      store_data,the_name,data=the
      options,the_name,'ytitle','Sun The!c'+fname
      options,the_name,'ynozero',1
      options,the_name,'psym',3

      phi_name = 'Sun_' + fname + '_Phi'
      store_data,phi_name,data=phi
      ylim,phi_name,0,360,0
      options,phi_name,'ytitle','Sun Phi!c'+fname
      options,phi_name,'yticks',4
      options,phi_name,'yminor',3
      options,phi_name,'ynozero',1
      options,phi_name,'psym',3

      if (fname eq 'SWEA') then begin
        options,the_name,'constant',[-10, 0, 17, 37, 77, 87]  ; see mvn_swe_sundir
        options,phi_name,'constant',[0, 45, 90, 135, 180, 225, 270, 315]  ; ribs
      endif

      pans = [pans, the_name, phi_name]
    endif

  endfor
  
  pans = pans[1:*]
  store_data,'Sun',/delete

  success = 1
  
  return

end
