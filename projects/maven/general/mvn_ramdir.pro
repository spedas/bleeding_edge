;+
;PROCEDURE:   mvn_ramdir
;PURPOSE:
;  Calculates the spacecraft orbital velocity relative to the body-fixed
;  rotating Mars frame (IAU_MARS).  If you sit on the spacecraft and look
;  in this direction, the flow will be in your face.
;
;  This vector can be rotated into any coordinate frame recognized by
;  SPICE.  See mvn_frame_name for a list.  The default is MAVEN_SPACECRAFT.
;
;  The co-rotation velocity in the IAU_MARS frame as a function of altitude
;  (h) and latitude (lat) is:
;
;      V_corot = (240 m/s)*[1 + h/3390]*cos(lat)
;
;  Models (LMD and MTGCM) predict that peak horizontal winds are 190-315 m/s 
;  near the exobase and 155-165 m/s near the homopause.  These are comparable 
;  to the co-rotation velocity.  The spacecraft velocity is ~4200 m/s in this 
;  altitude range, so winds could result in up to a ~4-deg angular offset of 
;  the actual flow from the nominal ram direction.
;
;  You must have SPICE installed for this routine to work.  This routine will
;  check to make sure SPICE has been initialized and that the loaded kernels
;  cover the specified time range.
;
;USAGE:
;  mvn_ramdir, trange
;
;INPUTS:
;       trange:   Optional.  Time range for calculating the RAM direction.
;                 If not specified, then use current range set by timespan.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default is to use the time resolution
;                 of maven_orbit_tplot (usually 10 sec).
;
;       FRAME:    String or string array for specifying one or more frames
;                 to transform the ram direction into.  Any frame recognized
;                 by SPICE is allowed.  The default is 'MAVEN_SPACECRAFT'.
;                 Other possibilities are: 'MAVEN_APP', 'MAVEN_STATIC', etc.
;                 Type 'mvn_frame_name(/list)' to see a full list of frames.
;                 Minimum matching name fragments (e.g., 'sta', 'swe') are
;                 allowed -- see mvn_frame_name for details.
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Mag = sqrt(x*x + y*y + z*z) ; units km/s
;                    Phi = atan(y,x)*!radeg      ; units deg [  0, 360]
;                    The = asin(z)*!radeg        ; units deg [-90, +90]
;
;       MSO:      Calculate ram vector in the MSO frame instead of the
;                 rotating IAU_MARS frame.  May be useful at high altitudes.
;
;       PANS:     Named variable to hold the tplot variables created.  For the
;                 default frame, this would be 'V_sc_MAVEN_SPACECRAFT'.
;
;       RESULT:   Named variable to hold the result structure.
;
;       FORCE:    Ignore the SPICE check and forge ahead anyway.
;
;       SUCCESS:  Returns 1 on normal operation, 0 otherwise.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-01-17 20:38:46 -0800 (Mon, 17 Jan 2022) $
; $LastChangedRevision: 30519 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_ramdir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_ramdir, trange, dt=dt, pans=pans, frame=frame, mso=mso, polar=polar, result=result, $
                force=force, success=success

  @maven_orbit_common

  success = 0
  result = 0
  dopol = keyword_set(polar)
  noguff = keyword_set(force)

  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'
  frame = mvn_frame_name(frame, success=flag)
  bndx = where(flag eq 0, count)
  if (count gt 0) then frame[bndx] = ''

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

; First store the spacecraft velocity in the IAU_MARS (or MSO) frame

  if keyword_set(mso) then begin
    vframe = 'MSO'
    if keyword_set(dt) then begin
      npts = ceil((tmax - tmin)/dt)
      Tsc = tmin + dt*dindgen(npts)
      Vsc = fltarr(npts,3)
      Vsc[*,0] = spline(state.time, state.mso_v[*,0], Tsc)
      Vsc[*,1] = spline(state.time, state.mso_v[*,1], Tsc)
      Vsc[*,2] = spline(state.time, state.mso_v[*,2], Tsc)
    endif else begin
      Tsc = state.time
      Vsc = state.mso_v
    endelse
    store_data,'V_sc',data={x:Tsc, y:Vsc, v:[0,1,2], vframe:vframe}
    options,'V_sc',spice_frame='MAVEN_SSO',spice_master_frame='MAVEN_SPACECRAFT'
  endif else begin
    vframe = 'GEO'
    if keyword_set(dt) then begin
      npts = ceil((tmax - tmin)/dt)
      Tsc = tmin + dt*dindgen(npts)
      Vsc = fltarr(npts,3)
      Vsc[*,0] = spline(state.time, state.geo_v[*,0], Tsc)
      Vsc[*,1] = spline(state.time, state.geo_v[*,1], Tsc)
      Vsc[*,2] = spline(state.time, state.geo_v[*,2], Tsc)
    endif else begin
      Tsc = state.time
      Vsc = state.geo_v
    endelse
    store_data,'V_sc',data={x:Tsc, y:Vsc, v:[0,1,2], vframe:vframe}
    options,'V_sc',spice_frame='IAU_MARS',spice_master_frame='MAVEN_SPACECRAFT'
  endelse

  result = {name : 'MAVEN RAM Velocity'}

; Next calculate the ram direction in frame(s) specified by keyword FRAME
  
  pans = ['']
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    fnum = strtrim(string(i,format='(i)'),2)
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'V_sc',to_frame,trange=[tmin,tmax]

    labels = ['X','Y','Z']
    fname = strmid(to_frame, strpos(to_frame,'_')+1)
    case strupcase(fname) of
      'MARS'       : fname = 'Mars'
      'SPACECRAFT' : fname = 'PL'
      'APP'        : labels = ['I','J','K']
      else         : ; do nothing
    endcase

    str_element, result, 'frame'+fnum, to_frame, /add

    vname = 'V_sc_' + to_frame
    get_data, vname, data=Vsc, index=k
    if (k gt 0) then begin
      str_element, Vsc, 'vframe', vframe, /add
      str_element, Vsc, 'units', 'km/s', /add
      store_data, vname, data=Vsc
      options,vname,'ytitle',vframe + ' RAM (' + fname + ')!ckm/s'
      options,vname,'colors',[2,4,6]
      options,vname,'labels',labels
      options,vname,'labflag',1
      options,vname,'constant',0
      pans = [pans, vname]
      str_element, result, 'vector'+fnum, Vsc, /add

      if (dopol) then begin
        xyz_to_polar, Vsc, mag=vmag, theta=the, phi=phi, /ph_0_360
        str_element, vmag, 'vframe', vframe, /add
        str_element, vmag, 'units', 'km/s', /add
        str_element, the, 'vframe', vframe, /add
        str_element, the, 'units', 'deg', /add
        str_element, phi, 'vframe', vframe, /add
        str_element, phi, 'units', 'deg', /add

        mag_name = 'V_sc_' + fname + '_Mag'
        store_data,mag_name,data=vmag
        options,mag_name,'ytitle',vframe + ' RAM Vel (' + fname + ')!ckm/s'
        options,mag_name,'ynozero',1
        options,mag_name,'psym',3

        the_name = 'V_sc_' + fname + '_The'
        store_data,the_name,data=the
        options,the_name,'ytitle',vframe + ' RAM The (' + fname + ')!cdeg'
        options,the_name,'ynozero',1
        options,the_name,'psym',3

        phi_name = 'V_sc_' + fname + '_Phi'
        store_data,phi_name,data=phi
        ylim,phi_name,0,360,0
        options,phi_name,'ytitle',vframe + ' RAM Phi (' + fname + ')!cdeg'
        options,phi_name,'yticks',4
        options,phi_name,'yminor',3
        options,phi_name,'ynozero',1
        options,phi_name,'psym',3

        pans = [pans, the_name, phi_name]
        str_element, result, 'mag'+fnum, vmag, /add
        str_element, result, 'the'+fnum, the, /add
        str_element, result, 'phi'+fnum, phi, /add
      endif
    endif else begin
      print,"Could not rotate to frame: ",to_frame
    endelse
  endfor

  if (n_elements(pans) lt 2) then begin
    print,"No valid ram directions."
    return
  endif

  pans = pans[1:*]
  store_data,'V_sc',/delete
  success = 1

  return

end
