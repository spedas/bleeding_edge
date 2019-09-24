;+
;PROCEDURE:   mvn_ramdir
;PURPOSE:
;  Calculates the spacecraft orbital velocity relative to the body-fixed
;  rotating Mars frame (IAU_MARS).  If you sit on the spacecraft and look
;  in this direction, the flow will be in your face.
;
;  This vector can be rotated into any coordinate frame recognized by
;  SPICE.  The default is MAVEN_SPACECRAFT.
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
;  You must have SPICE installed for this routine to work.  If SPICE is 
;  already initialized (e.g., mvn_swe_spice_init), this routine will use the 
;  current loadlist.  Otherwise, this routine will try to initialize SPICE
;  based on the current timespan.
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
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Phi = atan(y,x)*!radeg  ; [  0, 360]
;                    The = asin(z)*!radeg    ; [-90, +90]
;
;       MSO:      Calculate ram vector in the MSO frame instead of the
;                 rotating IAU_MARS frame.  May be useful at high altitudes.
;
;       PANS:     Named variable to hold the tplot variables created.  For the
;                 default frame, this would be 'V_sc_MAVEN_SPACECRAFT'.
;
;       SUCCESS:  Returns 1 on normal operation, 0 otherwise.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-09-23 11:13:58 -0700 (Mon, 23 Sep 2019) $
; $LastChangedRevision: 27790 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_ramdir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_ramdir, trange, dt=dt, pans=pans, frame=frame, mso=mso, polar=polar, success=ok

  @maven_orbit_common

  ok = 0

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

  if (size(state,/type) eq 0) then begin
    maven_orbit_tplot, /loadonly
    if (size(state,/type) eq 0) then begin
      print,"Cannot get spacecraft state vector."
      return
    endif
  endif

  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'
  frame = mvn_frame_name(frame, success=flag)
  bndx = where(flag eq 0, count)
  if (count gt 0) then frame[bndx] = ''

  dopol = keyword_set(polar)

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then begin
    mvn_swe_spice_init, trange=[tmin,tmax]
    mk = spice_test('*', verbose=-1)
    indx = where(mk eq '', count)
    if (count eq 0) then begin
      print,"Cannot initialize SPICE."
      return
    endif
  endif

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

; Next calculate the ram direction in frame(s) specified by keyword FRAME
  
  pans = ['']
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
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

      if (dopol) then begin
        xyz_to_polar, Vsc, theta=the, phi=phi, /ph_0_360
        str_element, the, 'vframe', vframe, /add
        str_element, the, 'units', 'km/s', /add
        str_element, phi, 'vframe', vframe, /add
        str_element, phi, 'units', 'km/s', /add

        the_name = 'V_sc_' + fname + '_The'
        store_data,the_name,data=the
        options,the_name,'ytitle',vframe + ' RAM The!c'+fname
        options,the_name,'ynozero',1
        options,the_name,'psym',3

        phi_name = 'V_sc_' + fname + '_Phi'
        store_data,phi_name,data=phi
        ylim,phi_name,0,360,0
        options,phi_name,'ytitle',vframe + ' RAM Phi!c'+fname
        options,phi_name,'yticks',4
        options,phi_name,'yminor',3
        options,phi_name,'ynozero',1
        options,phi_name,'psym',3

        pans = [pans, the_name, phi_name]
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
  ok = 1

  return

end
