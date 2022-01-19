;+
;PROCEDURE:   mvn_sundir
;PURPOSE:
;  Determines the direction of the Sun at the position of the spacecraft in
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
;                 Minimum matching name fragments (e.g., 'sta', 'swe') are
;                 allowed -- see mvn_frame_name for details.
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Phi = atan(y,x)*!radeg  ; [  0, 360]
;                    The = asin(z)*!radeg    ; [-90, +90]
;
;       PANS:     Named variable to hold the tplot variables created.  For the
;                 default frame, this would be 'Sun_MAVEN_SPACECRAFT'.
;
;       FORCE:    Ignore the SPICE check and forge ahead anyway.
;
;       SUCCESS:  Returns 1 on normal completion, 0 otherwise.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-01-17 20:38:46 -0800 (Mon, 17 Jan 2022) $
; $LastChangedRevision: 30519 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_sundir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_sundir, trange, dt=dt, pans=pans, frame=frame, polar=polar, force=force, success=success

  success = 0
  dopol = keyword_set(polar)
  noguff = keyword_set(force)
  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  
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
      options,the_name,spice_frame=to_frame

      phi_name = 'Sun_' + fname + '_Phi'
      store_data,phi_name,data=phi
      ylim,phi_name,0,360,0
      options,phi_name,'ytitle','Sun Phi!c'+fname
      options,phi_name,'yticks',4
      options,phi_name,'yminor',3
      options,phi_name,'ynozero',1
      options,phi_name,'psym',3
      options,phi_name,spice_frame=to_frame

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
