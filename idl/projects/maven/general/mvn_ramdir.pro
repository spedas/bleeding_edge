;+
;PROCEDURE:   mvn_ramdir
;PURPOSE:
;  Calculates the spacecraft orbital velocity relative to the body-fixed
;  rotating Mars frame (IAU_MARS).  If you sit on the spacecraft and look
;  in this direction, the flow will be in your face.  The default is to 
;  calculate this direction in the MAVEN_SPACECRAFT frame.
;
;  Careful!  Some people consider the opposite of the spacecraft velocity
;  to be the RAM direction.  Watch for sign errors.
;
;  This vector can be rotated into the APP frame or any of the instrument
;  frames.  See mvn_frame_name for a list.  This is a pure rotation, so
;  don't try to rotate into the MSO frame, since the result would still be 
;  in a frame that rotates with the planet.  Instead, use the MSO keyword.
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
;  cover the specified time range.  With reconstructed kernels, this routine
;  has an accuracy of ~0.1 deg.
;
;USAGE:
;  mvn_ramdir, time
;
;INPUTS:
;       time:     If time has two elements, interpret it as a time range and
;                 create an array of evenly spaced times with resolution DT.
;
;                 If time has more than two elements, then the ram direction
;                 is calculated for each time in the array.
;
;                 Otherwise, attempt to get the time range from tplot and
;                 create an array of evenly spaced times with resolution DT.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default is 10 sec.
;
;       FRAME:    String or string array for specifying one or more frames
;                 to rotate the ram direction into.  Any frame recognized
;                 by SPICE is allowed.  The default is 'MAVEN_SPACECRAFT'.
;                 Other possibilities are: 'MAVEN_APP', 'MAVEN_STATIC', etc.
;                 Type 'mvn_frame_name(/list)' to see a full list of frames.
;                 Minimum matching name fragments (e.g., 'sta', 'swe') are
;                 allowed -- see mvn_frame_name for details.  This is a pure
;                 rotation!
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Mag = sqrt(x*x + y*y + z*z) ; units km/s
;                    Phi = atan(y,x)*!radeg      ; units deg [  0, 360]
;                    The = asin(z/Mag)*!radeg    ; units deg [-90, +90]
;
;       PH_180:   If set, the range for Phi is -180 to +180 degrees.
;
;       REVERSE:  Reverse the sense of RAM to be the velocity of the incoming
;                 ions with respect to the spacecraft.  If you sit on the 
;                 spacecraft and look in this direction the flow will be into
;                 the back of your head.
;
;       MSO:      Calculate ram vector in the MSO frame instead of the
;                 rotating IAU_MARS frame.  May be useful at high altitudes.
;
;       ERROR:    Calculate the magnitude of the RAM pointing error (deg)
;                 and store as a separate tplot variable.  This only works for
;                 the APP and NGIMS frames.  The STATIC frame is reversed.
;
;                 Using ephemeris predicts refreshed on a regular basis, the
;                 spacecraft can usually point the APP into the RAM direction
;                 with an accuracy of ~0.5 deg.  Occasionally, the error can
;                 be up to ~2 deg.  The reconstructed RAM direction has an 
;                 accuracy of ~0.1 deg.
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
; $LastChangedDate: 2024-07-25 14:47:18 -0700 (Thu, 25 Jul 2024) $
; $LastChangedRevision: 32761 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_ramdir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_ramdir, trange, dt=dt, pans=pans, frame=frame, mso=mso, polar=polar, result=result, $
                ph_180=ph_180, error=error, force=force, success=success, reverse=reverse

  success = 0
  result = 0
  doerr = keyword_set(error)
  dopol = keyword_set(polar) or doerr
  noguff = keyword_set(force)
  ph_360 = ~keyword_set(ph_180)
  sign = keyword_set(reverse) ? -1. : 1.

  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'
  frame = mvn_frame_name(frame, success=i)
  gndx = where(i, count)
  if (count eq 0L) then begin
    print,"No valid frames."
    return
  endif else frame = frame[gndx]

; The spacecraft CK is always needed.  Check to see if the APP CK is also needed.

  need_app_ck = max(strmatch(frame,'*STATIC*',/fold)) or $
                max(strmatch(frame,'*NGIMS*',/fold)) or $
                max(strmatch(frame,'*IUVS*',/fold)) or $
                max(strmatch(frame,'*APP*',/fold))

; Create the UT array

  npts = n_elements(trange)
  if (npts lt 2) then begin
    tplot_options, get=topt
    trange = topt.trange_full
    if (max(trange) lt time_double('2013-11-18')) then begin
      print,"Invalid time range or time array."
      return
    endif
    npts = 2L
  endif
  if (npts lt 3) then begin
    tmin = min(time_double(trange), max=tmax)
    dt = keyword_set(dt) ? double(dt[0]) : 10D
    npts = ceil((tmax - tmin)/dt) + 1L
    ut = tmin + dt*dindgen(npts)
  endif else ut = time_double(trange)

; Check the time range against the ephemeris coverage -- bail if there's a problem

  bail = 0
  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then begin
    print,"You must initialize SPICE first."
    bail = 1
  endif else begin
    mvn_spice_stat, summary=sinfo, check=minmax(ut), /silent
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

; Calculate the state vector

  if keyword_set(mso) then begin
    vframe = 'MAVEN_SSO'
    vlabel = 'MSO'
  endif else begin
    vframe = 'IAU_MARS'
    vlabel = 'GEO'
  endelse
  timestr = time_string(ut,prec=5)
  cspice_str2et, timestr, et
  cspice_spkezr, 'MAVEN', et, vframe, 'NONE', 'MARS', svec, ltime

; Store the spacecraft velocity in the IAU_MARS (or MSO) frame

  store_data,'V_sc',data={x:ut, y:sign*transpose(svec[3:5,*]), v:[0,1,2], vframe:vframe}
  options,'V_sc',spice_frame=vframe,spice_master_frame='MAVEN_SPACECRAFT'

  result = {name : 'MAVEN RAM Velocity', vframe : vframe}

; Calculate the ram direction in frame(s) specified by keyword FRAME
  
  pans = ['']
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    fnum = strtrim(string(i,format='(i)'),2)
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'V_sc',to_frame,trange=minmax(ut),check='MAVEN_SPACECRAFT'

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
      options,vname,'ytitle',vlabel + ' RAM (' + fname + ')!ckm/s'
      options,vname,'colors',[2,4,6]
      options,vname,'labels',labels
      options,vname,'labflag',1
      options,vname,'constant',0
      pans = [pans, vname]
      str_element, result, 'vector'+fnum, Vsc, /add

      if (dopol) then begin
        xyz_to_polar, Vsc, mag=vmag, theta=the, phi=phi, ph_0_360=ph_360
        str_element, vmag, 'vframe', vframe, /add
        str_element, vmag, 'units', 'km/s', /add
        str_element, the, 'vframe', vframe, /add
        str_element, the, 'units', 'deg', /add
        str_element, phi, 'vframe', vframe, /add
        str_element, phi, 'units', 'deg', /add

        mag_name = 'V_sc_' + fname + '_Mag'
        store_data,mag_name,data=vmag
        options,mag_name,'ytitle',vlabel + ' RAM Vel (' + fname + ')!ckm/s'
        options,mag_name,'ynozero',1
        options,mag_name,'psym',3
        options,mag_name,'colors',6

        the_name = 'V_sc_' + fname + '_The'
        store_data,the_name,data=the
        options,the_name,'ytitle',vlabel + ' RAM The (' + fname + ')!cdeg'
        options,the_name,'ynozero',1
        options,the_name,'psym',3
        options,the_name,'colors',6

        phi_name = 'V_sc_' + fname + '_Phi'
        store_data,phi_name,data=phi
        if (ph_360) then ylim,phi_name,0,360,0 else ylim,phi_name,-180,180,0
        options,phi_name,'ytitle',vlabel + ' RAM Phi (' + fname + ')!cdeg'
        options,phi_name,'yticks',4
        options,phi_name,'yminor',3
        options,phi_name,'ynozero',1
        options,phi_name,'psym',3
        options,phi_name,'colors',6

        pans = [pans, the_name, phi_name]
        str_element, result, 'mag'+fnum, vmag, /add
        str_element, result, 'the'+fnum, the, /add
        str_element, result, 'phi'+fnum, phi, /add

        if (doerr) then begin
          dang = acos(cos(phi.y*!dtor)*cos(the.y*!dtor))*!radeg
          store_data,'RAM_Error',data={x:phi.x, y:dang}
          ylim,'RAM_Error',0,3,0
          options,'RAM_Error','ytitle','RAM Error!cdeg'
          options,'RAM_Error','psym',3
          options,'RAM_Error','line_colors',5
          options,'RAM_Error','colors',6
          options,'RAM_Error','constant',[0.5,2]
          options,'RAM_Error','const_color',[4,5]
          options,'RAM_Error','const_line',[2,2]
        endif
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
