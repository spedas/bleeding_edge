;+
;PROCEDURE:   mvn_appdir
;PURPOSE:
;  Determines the direction of the APP I-axis in the spacecraft frame.
;  There are two gimbals: inner and outer.  The outer gimbal performs
;  rotations about the APP J-axis (orthogonal to I).  The inner gimbal
;  performs rotations about the spacecraft Y-axis.
;
;  This vector can be rotated into any coordinate frame recognized by
;  SPICE.  See mvn_frame_name for a list.  The default is MAVEN_SPACECRAFT.
;
;  You must have SPICE installed for this routine to work.  This routine will
;  check to make sure SPICE has been initialized and that the loaded kernels
;  cover the specified time range.
;
;USAGE:
;  mvn_appdir, time
;
;INPUTS:
;       time:     If time has two elements, interpret it as a time range and
;                 create an array of evenly spaced times with resolution DT.
;
;                 If time has more than two elements, then the APP direction
;                 is calculated for each time in the array.
;
;                 Otherwise, attempt to get the time range from tplot and
;                 create an array of evenly spaced times with resolution DT.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default = 10 sec.
;
;       FRAME:    String or string array for specifying one or more frames
;                 to transform the Sun direction into.  Any frame recognized
;                 by SPICE is allowed.  The default is 'MAVEN_SPACECRAFT'.
;                 Type 'mvn_frame_name(/list)' to see a full list of frames.
;                 Minimum matching name fragments (e.g., 'sta', 'swe') are
;                 allowed -- see mvn_frame_name for details.
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Phi = atan(y,x)*!radeg  ; [  0, 360]
;                    The = asin(z)*!radeg    ; [-90, +90]
;
;       PH_180:   If set, the range for Phi is -180 to +180 degrees.
;
;       REVERSE:  Reverse the sense to be the -I direction.
;
;       PANS:     Named variable to hold the tplot variables created.  For the
;                 default frame, this would be 'APP_MAVEN_SPACECRAFT'.
;
;       FORCE:    Ignore the SPICE check and forge ahead anyway.
;
;       SUCCESS:  Returns 1 on normal completion, 0 otherwise.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-01-15 12:18:34 -0800 (Mon, 15 Jan 2024) $
; $LastChangedRevision: 32371 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_appdir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_appdir, trange, dt=dt, pans=pans, frame=frame, polar=polar, ph_180=ph_180, $
                reverse=reverse, force=force, success=success

  success = 0
  dopol = keyword_set(polar)
  noguff = keyword_set(force)
  ph_360 = ~keyword_set(ph_180)
  sign = keyword_set(reverse) ? -1. : 1.

  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'
  frame = mvn_frame_name(frame, success=i)
  gndx = where(i, count)
  if (count eq 0) then begin
    print,"No valid frames."
    return
  endif
  frame = frame[gndx]

; The spacecraft and APP CKs are always needed.

  need_app_ck = 1

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

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then begin
    print,"You must initialize SPICE first."
    return
  endif else begin
    mvn_spice_stat, summary=sinfo, check=minmax(ut), /silent
    ok = sinfo.spk_check and sinfo.ck_sc_check
    if (need_app_ck) then ok = ok and sinfo.ck_app_check
    if (not ok) then begin
      print,"Insufficient SPICE coverage for the requested time range."
      print,"  -> Reinitialize SPICE to include your time range."
      if (~noguff) then return
      print,"  -> Keyword FORCE is set, so trying anyway."
    endif
  endelse

; First store the APP I direction in APP coordinates

  x = ut
  y = replicate(1.,n_elements(ut)) # [sign,0.,0.]
  store_data,'APP',data={x:x, y:y, v:indgen(3)}
  options,'APP','ytitle','Sun (MSO)'
  options,'APP','labels',['I','J','K']
  options,'APP','labflag',1
  options,'APP',spice_frame='MAVEN_APP',spice_master_frame='MAVEN_SPACECRAFT'

; Next calculate the Sun direction in frame(s) specified by keyword FRAME

  pans = ['']
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'APP',to_frame,trange=minmax(ut),check='MAVEN_SPACECRAFT'

    labels = ['X','Y','Z']
    pname = 'APP_' + to_frame
    fname = strmid(to_frame, strpos(to_frame,'_')+1)
    case fname of
      'SPACECRAFT' : fname = 'PL'
      'IAU_MARS'   : fname = 'Mars'
      'APP'        : labels = ['I','J','K']
      else         : ; do nothing
    endcase
    options,pname,'ytitle','APP (' + fname + ')'
    options,pname,'colors',[2,4,6]
    options,pname,'labels',labels
    options,pname,'labflag',1
    options,pname,spice_frame=to_frame,spice_master_frame='MAVEN_SPACECRAFT'
    pans = [pans, pname]

    if (dopol) then begin
      get_data, pname, data=sun
      xyz_to_polar, sun, theta=the, phi=phi, ph_0_360=ph_360

      the_name = 'APP_' + fname + '_The'
      store_data,the_name,data=the
      options,the_name,'ytitle','APP The!c'+fname
      options,the_name,'ynozero',1
      options,the_name,'psym',3
      options,the_name,spice_frame=to_frame

      phi_name = 'APP_' + fname + '_Phi'
      store_data,phi_name,data=phi
      ylim,phi_name,0,360,0
      options,phi_name,'ytitle','APP Phi!c'+fname
      options,phi_name,'yticks',4
      options,phi_name,'yminor',3
      options,phi_name,'ynozero',1
      options,phi_name,'psym',3
      options,phi_name,spice_frame=to_frame

      pans = [pans, the_name, phi_name]
    endif

  endfor
  
  pans = pans[1:*]
  store_data,'APP',/delete

  success = 1
  
  return

end
