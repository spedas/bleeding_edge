;+
;PROCEDURE:   mvn_nadir
;PURPOSE:
;  Determines the direction of nadir at the position of the spacecraft in
;  one or more coordinate frames.  The results are stored in TPLOT variables.
;
;  This vector can be rotated into any coordinate frame recognized by
;  SPICE.  See mvn_frame_name for a list.  The default is MAVEN_SPACECRAFT.
;
;  You must have SPICE installed for this routine to work.  This routine will
;  check to make sure SPICE has been initialized and that the loaded kernels
;  cover the specified time range.
;
;USAGE:
;  mvn_nadir, trange
;
;INPUTS:
;       trange:   Optional.  Time range for calculating the nadir direction.
;                 If not specified, then use current range set by timespan.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default is to use the time resolution
;                 of maven_orbit_tplot (usually 10 sec).
;
;       FRAME:    String or string array for specifying one or more frames
;                 to transform the nadir direction into.  Any frame recognized
;                 by SPICE is allowed.  The default is 'MAVEN_SPACECRAFT'.
;                 Other possibilities are: 'MAVEN_APP', 'MAVEN_STATIC', etc.
;                 Type 'mvn_frame_name(/list)' to see a full list of frames.
;                 Minimum matching name fragments (e.g., 'sta', 'swe') are
;                 allowed -- see mvn_frame_name for details.
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Phi = atan(y,x)*!radeg  ; [  0, 360]
;                    The = asin(z)*!radeg    ; [-90, +90]
;
;       PANS:     Named variable to hold the tplot variables created.  For the
;                 default frame, this would be 'Nadir_MAVEN_SPACECRAFT'.
;
;       FORCE:    Ignore the SPICE check and forge ahead anyway.
;
;       SUCCESS:  Returns 1 on normal completion, 0 otherwise
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-01-17 20:38:46 -0800 (Mon, 17 Jan 2022) $
; $LastChangedRevision: 30519 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_nadir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_nadir, trange, dt=dt, pans=pans, frame=frame, polar=polar, force=force, success=success

  @maven_orbit_common

  success = 0
  dopol = keyword_set(polar)
  noguff = keyword_set(force)

  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'
  frame = mvn_frame_name(frame, success=i)
  gndx = where(i, count)
  if (count eq 0) then begin
    print,"No valid frames."
    return
  endif
  frame = frame[i[gndx]]

; The spacecraft CK is always needed.  Check to see if the APP CK is also needed.

  need_app_ck = max(strmatch(frame,'*STATIC*',/fold)) or $
                max(strmatch(frame,'*NGIMS*',/fold)) or $
                max(strmatch(frame,'*IUVS*',/fold)) or $
                max(strmatch(frame,'*APP*',/fold))

; Get the time range

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

; Check the time range against the ephemeris coverage -- bail if there's a problem

  bail = 0
  if (size(state,/type) eq 0) then begin
    print,"You must run maven_orbit_tplot first."
    bail = 1
  endif else begin
    smin = min(state.time, max=smax)
    if ((tmin lt smin) or (tmax gt smax)) then begin
      print,"Insufficient state vector coverage for the requested time range."
      print,"  -> Rerun maven_orbit_tplot to include your time range."
      bail = 1
    endif
  endelse

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then begin
    print,"You must initialize SPICE first."
    bail = 1
  endif else begin
    mvn_spice_stat, summary=sinfo, check=[tmin,tmax], /silent
    ok = sinfo.spk_check and sinfo.ck_sc_check
    if (need_app_ck) then ok = ok and sinfo.ck_app_check
    if (not ok) then begin
      print,"Insufficient SPICE coverage for the requested time range."
      print,"  -> Reinitialize SPICE to include your time range."
      bail = 1
    endif
  endelse

  if (noguff) then begin
    if (bail) then print,"  -> Keyword FORCE is set, so trying anyway."
    bail = 0
  endif

  if (bail) then return

; First store the nadir direction in the IAU_MARS frame

  if keyword_set(dt) then begin
    npts = ceil((tmax - tmin)/dt)
    x = tmin + dt*dindgen(npts)
    y = fltarr(npts,3)
    y[*,0] = spline(state.time, -(state.geo_x[*,0]), x)
    y[*,1] = spline(state.time, -(state.geo_x[*,1]), x)
    y[*,2] = spline(state.time, -(state.geo_x[*,2]), x)
  endif else begin
    x = state.time
    y = -(state.geo_x)
  endelse

  ymag = sqrt(total(y*y,2)) # replicate(1.,3)
  store_data,'Nadir',data={x:x, y:y/ymag, v:indgen(3)}
  options,'Nadir','ytitle','Nadir (Mars)'
  options,'Nadir','labels',['X','Y','Z']
  options,'Nadir','labflag',1
  options,'Nadir',spice_frame='IAU_MARS',spice_master_frame='MAVEN_SPACECRAFT'

; Next calculate the nadir direction in frame(s) specified by keyword FRAME

  pans = ['']
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'Nadir',to_frame,trange=[tmin,tmax],check='MAVEN_SPACECRAFT'

    labels = ['X','Y','Z']
    pname = 'Nadir_' + to_frame
    fname = strmid(to_frame, strpos(to_frame,'_')+1)
    case fname of
      'SPACECRAFT' : fname = 'PL'
      'IAU_MARS'   : fname = 'Mars'
      'APP'        : labels = ['I','J','K']
      else         : ; do nothing
    endcase
    options,pname,'ytitle','Nadir (' + fname + ')'
    options,pname,'colors',[2,4,6]
    options,pname,'labels',labels
    options,pname,'labflag',1
    options,pname,spice_frame=to_frame,spice_master_frame='MAVEN_SPACECRAFT'
    pans = [pans, pname]

    if (dopol) then begin
      get_data, pname, data=nadir
      xyz_to_polar, nadir, theta=the, phi=phi, /ph_0_360

      the_name = 'Nadir_' + fname + '_The'
      store_data,the_name,data=the
      options,the_name,'ytitle','Nadir The!c'+fname
      options,the_name,'ynozero',1
      options,the_name,'psym',3
      options,the_name,spice_frame=to_frame

      phi_name = 'Nadir_' + fname + '_Phi'
      store_data,phi_name,data=phi
      ylim,phi_name,0,360,0
      options,phi_name,'ytitle','Nadir Phi!c'+fname
      options,phi_name,'yticks',4
      options,phi_name,'yminor',3
      options,phi_name,'ynozero',1
      options,phi_name,'psym',3
      options,phi_name,spice_frame=to_frame

      pans = [pans, the_name, phi_name]
    endif
  endfor

  pans = pans[1:*]
  store_data,'Nadir',/delete

  success = 1
  
  return

end
