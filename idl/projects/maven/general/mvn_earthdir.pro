;+
;PROCEDURE:   mvn_earthdir
;PURPOSE:
;  Determines the direction of Earth as viewed from Mars in any coordinate
;  frame recognized by SPICE.  See mvn_frame_name for a list.  The default
;  is MAVEN_SPACECRAFT.  If you sit on the spacecraft and look in this
;  direction, you will see Earth.
;
;  You must have SPICE installed for this routine to work.  This routine will
;  check to make sure SPICE has been initialized and that the loaded kernels
;  cover the specified time range.
;
;USAGE:
;  mvn_earthdir, trange
;
;INPUTS:
;       trange:   Time range for calculating the sub-Earth point.  If not
;                 specified, this routine will attempt to get the time range
;                 from tplot_com.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default = 1.
;
;       FRAME:    String or string array for specifying one or more frames
;                 to transform the Earth direction into.  Any frame recognized
;                 by SPICE is allowed.  The default is 'MAVEN_SPACECRAFT'.
;                 Other possibilities are: 'MAVEN_APP', 'MAVEN_STATIC', etc.
;                 Type 'mvn_frame_name(/list)' to see a full list of frames.
;                 Minimum matching name fragments (e.g., 'sta', 'swe') are
;                 allowed -- see mvn_frame_name for details.
;
;       ABCORR:   Aberration correction.  Options are:
;
;                     'NONE'  : No correction (default)
;
;                   Receive (photons leave Mars at ET-LT and reach Earth at ET)
;                     'LT'    : One-way light time
;                     'LT+S'  : One-way light time + stellar aberration
;                     'CN'    : Same as 'LT' but with better accuracy
;                     'CN+S'  : Same as 'LT+S' but with better accuracy
;
;                   Transmit (photons leave Earth at ET and reach Mars at ET+LT)
;                     'XLT'   : One-way light time
;                     'XLT+S' : One-way light time + stellar aberration
;                     'XCN'   : Same as 'LT' but with better accuracy
;                     'XCN+S' : Same as 'LT+S' but with better accuracy
;
;                 The aberration correction is used for situations where photons
;                 leave one object and arrive at the other object at a later time.
;                 By far, the largest part of this correction is the rotation of
;                 Mars (0.75 to 5.5 degrees).  The motions of Earth and Mars in 
;                 their orbits result in a correction smaller than 0.003 deg.
;
;                 For MAVEN, the only time to use an aberration correction is for
;                 radio occultations.  For all other purposes, use 'NONE'.
;
;                 See documentation for CSPICE_SUBPNT for details:
;                 https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/IDL/icy/cspice_subpnt.html
;
;       POLAR:    If set, convert the direction to polar coordinates and store
;                 as additional tplot variables.
;                    Phi = atan(y,x)*!radeg  ; [  0, 360]
;                    The = asin(z)*!radeg    ; [-90, +90]
;
;       PH_180:   If set, the range for Phi is -180 to +180 degrees.
;
;       REVERSE:  Reverse the sense to be the anti-Earth direction.  If you sit on
;                 the spacecraft and look in this direction you will have turned 
;                 your back on Earth.  You're a Martian now.
;
;       PANS:     Named variable to hold the tplot variables created.  For the
;                 default frame, this would be 'Earth_MAVEN_SPACECRAFT'.
;
;       FORCE:    Ignore the SPICE check and forge ahead anyway.
;
;       SUCCESS:  Returns 1 on normal completion, 0 otherwise.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-04-11 20:59:57 -0700 (Tue, 11 Apr 2023) $
; $LastChangedRevision: 31732 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_earthdir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_earthdir, trange, dt=dt, pans=pans, abcorr=abcorr, frame=frame, polar=polar, $
                          reverse=reverse, ph_180=ph_180, force=force, success=success

  success = 0
  dopol = keyword_set(polar)
  noguff = keyword_set(force)
  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  ph_360 = ~keyword_set(ph_180)
  sign = keyword_set(reverse) ? -1. : 1.

  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'
  frame = mvn_frame_name(frame, success=i)
  gndx = where(i, count)
  if (count eq 0) then begin
    print,"No valid frames."
    return
  endif
  frame = frame[i[gndx]]

  if (size(abcorr, /type) ne 7) then abcorr = 'NONE' else abcorr = abcorr[0]
  clist = ['NONE','LT','LT+S','CN','CN+S','XLT','XLT+S','XCN','XCN+S']
  i = strmatch(clist, abcorr, /fold)
  if (max(i) eq 0) then begin
    print, "Aberration correction method not recognized: ",abcorr
    print, "Must be one of:"
    for i=0,8 do print,"  ",clist[i]
    return
  endif

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

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then begin
    print,"You must initialize SPICE first."
    return
  endif else begin
    mvn_spice_stat, summary=sinfo, check=[tmin,tmax], /silent
    ok = sinfo.spk_check and sinfo.ck_sc_check
    if (need_app_ck) then ok = ok and sinfo.ck_app_check
    if (not ok) then begin
      print,"Insufficient SPICE coverage for the requested time range."
      print,"  -> Reinitialize SPICE to include your time range."
      if (~noguff) then return
      print,"  -> Keyword FORCE is set, so trying anyway."
    endif
  endelse

; First store the Earth direction in the IAU_MARS frame

  npts = floor((tmax - tmin)/dt) + 1L
  time = tmin + dt*dindgen(npts)

  tstring = time_string(time,prec=3)
  cspice_str2et, tstring, et
  from_frame = 'IAU_MARS'
  earth = dblarr(npts,3)
  elon = dblarr(npts)
  elat = elon

  for i=0L,(npts-1L) do begin
    cspice_subpnt, 'INTERCEPT/ELLIPSOID', 'Mars', et[i], from_frame, abcorr, 'Earth', $
                   spoint, trgepc, srfvec
    earth[i,*] = spoint
  endfor
  earth /= sign*(sqrt(total(earth*earth,2)) # replicate(1D,3))  ; unit vector

  vroot = 'Earth'
  vname = vroot
  store_data,vname,data={x:time, y:earth, v:indgen(3)}
  options,vname,'ytitle','Earth!c(' + from_frame + ')'
  options,vname,'colors',[2,4,6]
  options,vname,'labels',['X','Y','Z']
  options,vname,'labflag',1
  options,vname,spice_frame=from_frame,spice_master_frame='MAVEN_SPACECRAFT'
  options,vname,'abcorr',abcorr

  if (dopol) then begin
    get_data, vname, data=earth
    xyz_to_polar, earth, theta=the, phi=phi, ph_0_360=ph_360

    the_name = vname + '_The'
    store_data,the_name,data=the
    options,the_name,'ytitle','Earth The!c(' + from_frame + ')'
    options,the_name,'ynozero',1
    options,the_name,'psym',3
    options,the_name,spice_frame=from_frame
    options,the_name,'abcorr',abcorr

    phi_name = vname + '_Phi'
    store_data,phi_name,data=phi
    ylim,phi_name,0,360,0
    options,phi_name,'ytitle','Earth Phi!c(' + from_frame + ')'
    options,phi_name,'yticks',4
    options,phi_name,'yminor',3
    options,phi_name,'ynozero',1
    options,phi_name,'psym',3
    options,phi_name,spice_frame=from_frame
    options,phi_name,'abcorr',abcorr
  endif

; Next calculate the Earth direction in frame(s) specified by keyword FRAME

  pans = [vname]

  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,vname,to_frame,trange=[tmin,tmax],check='MAVEN_SPACECRAFT'

    labels = ['X','Y','Z']
    pname = vroot + '_' + to_frame
    fname = strmid(to_frame, strpos(to_frame,'_')+1)
    case fname of
      'SPACECRAFT' : fname = 'PL'
      'IAU_MARS'   : fname = 'Mars'
      'APP'        : labels = ['I','J','K']
      else         : ; do nothing
    endcase
    options,pname,'ytitle','Earth!c'+fname
    options,pname,'colors',[2,4,6]
    options,pname,'labels',labels
    options,pname,'labflag',1
    options,pname,spice_frame=to_frame,spice_master_frame='MAVEN_SPACECRAFT'
    options,pname,'abcorr',abcorr
    pans = [pans, pname]

    if (dopol) then begin
      get_data, pname, data=sun
      xyz_to_polar, sun, theta=the, phi=phi, ph_0_360=ph_360

      the_name = 'Earth_' + fname + '_The'
      store_data,the_name,data=the
      options,the_name,'ytitle','Earth The!c'+fname
      options,the_name,'ynozero',1
      options,the_name,'psym',3
      options,the_name,spice_frame=to_frame
      options,the_name,'abcorr',abcorr

      phi_name = 'Earth_' + fname + '_Phi'
      store_data,phi_name,data=phi
      ylim,phi_name,0,360,0
      options,phi_name,'ytitle','Earth Phi!c'+fname
      options,phi_name,'yticks',4
      options,phi_name,'yminor',3
      options,phi_name,'ynozero',1
      options,phi_name,'psym',3
      options,phi_name,spice_frame=to_frame
      options,phi_name,'abcorr',abcorr

      pans = [pans, the_name, phi_name]
    endif

  endfor

  success = 1
  
  return

end
