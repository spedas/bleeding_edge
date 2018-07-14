;+
;
;PROCEDURE:       MVN_STA_V4D
;
;PURPOSE:         Calculates ion bulk velocity correcting for spacecraft
;                 potential and spacecraft motion.  Also transforms result
;                 to different frames.
;
;INPUTS:
;
;    trange:      Time or time range for loading data.
;
;KEYWORDS: 
;   
;       FRAME:    Transform the results to this frame.  See mvn_frame_name
;                 for a list of frames.  Default = 'MAVEN_MSO'.
;
;        MASS:    Selects ion mass/charge range.
;
;        MMIN:    Defines the minimum ion mass/charge to use.
;
;        MMAX:    Defines the maximum ion mass/charge to use.
;
;       M_INT:    Assumed ion mass/charge. Default = 1.
;
;        APID:    Specifies the STATIC APID to use.
;
;       DOPOT:    If set, correct for the spacecraft potential.  The default is
;                 to use the potential stored in the L2 CDF's or calculated by 
;                 mvn_sta_scpot_load.  If this estimate is not available, no
;                 correction is made.
;
;      SC_POT:    Override the default spacecraft potential with this.
;
;         VSC:    Correct for the spacecraft velocity.
;
;      ERANGE:    Specifies the energy range to use.
;
;      TEMPLATE:  Just return the result structure template.
;
;NOTE:            This routine is based on 'mvn_sta_slice2d_snap' created by
;                 Yuki Harada and modified by Takuya Hara.
;
;CREATED BY:      D. L. Mitchell.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-07-13 13:19:46 -0700 (Fri, 13 Jul 2018) $
; $LastChangedRevision: 25469 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_functions/mvn_sta_v4d.pro $
;
;-
PRO mvn_sta_v4d, trange, frame=frame, _extra=_extra, mass=mass, m_int=mq, $
                 mmin=mmin, mmax=mmax, apid=apid, sum=sum, dopot=dopot, $
                 sc_pot=sc_pot, vsc=vsc, erange=erange, result=result, $
                 template=template, verbose=verbose

  NaN = !values.f_nan
  NaN3 = replicate(NaN,3)
  dNaN = !values.d_nan
  dNaN3 = replicate(dNaN,3)

  result = {time     : dNaN          , $   ; time
            v_sc     : dNaN3         , $   ; spacecraft velocity (km/s)
            v_tot    : dNaN          , $   ; spacecraft speed (km/s)
            vel      : dNaN3         , $   ; ion bulk velocity (km/s)
            vbulk    : dNaN          , $   ; ion bulk speed (km/s)
            magf     : NaN3          , $   ; magnetic field (nT)
            energy   : dNaN          , $   ; ion kinetic energy (eV)
            VB_phi   : dNaN          , $   ; angle between V and B (deg)
            sc_pot   : NaN           , $   ; spacecraft potential (V)
            mass     : NaN           , $   ; assumed ion mass (amu)
            mrange   : [NaN,NaN]     , $   ; mass range for integration (amu)
            erange   : [Nan,NaN]     , $   ; energy range for integration (eV)
            frame    : ''            , $   ; reference frame (for all vectors)
            apid     : ''            , $   ; STATIC APID used for calculation
            valid    : 0                }

  if keyword_set(template) then return

; Process inputs

  if (size(trange,/type) eq 0) then begin
    dprint, 'You must supply a time or time range.', dlevel=2, verbose=verbose
    return
  endif
  trange = time_double(trange)
  sum = n_elements(trange) gt 1

  if (size(frame,/type) ne 7) then frame = 'MAVEN_MSO'
  frame = (mvn_frame_name(frame))[0]

  dopot = keyword_set(dopot)
  dovel = keyword_set(vsc)
  forcepot = size(sc_pot,/type) ne 0

  if keyword_set(mass) then mmin = min(mass, max=mmax)
  if ~keyword_set(mmin) then mmin = 0.
  if ~keyword_set(mmax) then mmax = 100.

  if keyword_set(erange) then emin = min(erange, max=emax)
  if ~keyword_set(emin) then emin = 0.
  if ~keyword_set(emax) then emax = 30000.

; Get data

  if (sum) then d = mvn_sta_get(apid, tt=trange) $
           else d = call_function('mvn_sta_get_' + apid, trange)

; Calculate bulk velocity, corrected for spacecraft potential and motion

  if (d.valid) then begin

    tmid = (d.time + d.end_time)/2D

    if mvn_spice_valid_times(tmid) eq 0 then begin
       dprint, dlevel=2, verbose=verbose, 'SPICE/kernels ara invalid.'
       return
    endif 

    idx = where((d.mass_arr lt mmin) or (d.mass_arr gt mmax), nidx)
    if (nidx gt 0) then d.cnts[idx] = 0.
    undefine, nidx, idx
    if keyword_set(mq) then d.mass *= float(mq)

    idx = where((d.energy lt emin) or (d.energy gt emax), nidx)
    if (nidx gt 0) then d.cnts[idx] = 0.
    undefine, nidx, idx           

    if (frame ne 'MAVEN_STATIC') then begin
      sstat = execute("mvn_pfp_cotrans, d, from='MAVEN_STATIC', to=frame, /overwrite")
      if (sstat eq 0) then return
      bnew = spice_vector_rotate(d.magf, tmid, 'MAVEN_STATIC', frame)
      str_element, d, 'magf', bnew, /add_replace
    endif

    d = sum4m(d)
    str_element, d, 'nbins', (d.nbins), /add_replace
    str_element, d, 'nenergy', (d.nenergy), /add_replace
    str_element, d, 'bins', rebin(transpose(d.bins), d.nenergy, d.nbins), /add_replace
    str_element, d, 'bins_sc', rebin(transpose(d.bins_sc), d.nenergy, d.nbins), /add_replace

    if (dopot or dovel) then begin
      if (dovel) then begin
        sstat = execute("v_sc = spice_body_vel('MAVEN', 'MARS', utc=tmid, frame=frame)")
        if (sstat eq 0) then begin
          mvn_spice_load, /download
          v_sc = spice_body_vel('MAVEN', 'MARS', utc=tmid, frame=frame)
        endif
        if (size(v_sc, /type) ne 0) then $
          v_sc = spice_vector_rotate(v_sc, tmid, frame, 'MAVEN_STATIC')
        undefine, sstat
      endif else v_sc = [0.,0.,0.]

      d.sc_pot = mvn_get_scpot((d.time + d.end_time)/2D)
      if (~finite(d.sc_pot)) then d.sc_pot = 0.
      if (forcepot) then d.sc_pot = sc_pot
      if (~dopot) then d.sc_pot = 0.
    endif

; Calculate the velocity moment.  The call to v_4d includes the spacecraft
; potential correction (if d.sc_pot is non-zero).  The spacecraft velocity is
; superimposed onto the ion bulk flow in the STATIC frame (e.g., if the ions
; appear stationary to STATIC, then they must be traveling with the s/c).

    vel = v_4d(d) + v_sc
    VB_phi = separation_angle(vel, d.magf)*!radeg

; Package the result

    vbulk = sqrt(total(vel*vel))
    ebulk = (vbulk^2.)*0.005*mq
    v_tot = sqrt(total(v_sc*v_sc))

    result.v_sc   = double(v_sc)
    result.v_tot  = double(v_tot)
    result.vel    = double(vel)
    result.vbulk  = double(vbulk)
    result.magf   = float(d.magf)
    result.energy = double(ebulk)
    result.VB_phi = double(VB_phi)
    result.sc_pot = float(d.sc_pot)
    result.mass   = float(mq)
    result.mrange = float([mmin,mmax])
    result.erange = float([emin,emax])
    result.frame  = string(frame)
    result.apid   = string(apid)
    result.valid  = 1

  endif

  return

end
