;+
;PROCEDURE: 
;	mvn_swe_kp
;PURPOSE:
;	Calculates SWEA key parameters.  The result is stored in tplot variables,
;   and as a save file.
;   This routine has been updated to use Version 5 of the CDF files.
;
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_kp
;INPUTS:
;   None:      Uses data currently loaded into the SWEA common block.
;
;KEYWORDS:
;   TRANGE:    Process data in this time range.
;
;   PANS:      Named variable to return tplot variables created.
;
;   MOM:       Calculate density using a moment.  This is the default and
;              only option for now.
;
;   DDD:       Calculate density from 3D distributions (allows bin
;              masking).  Default is to use SPEC data.  This option fits
;              a Maxwell-Boltzmann distribution to the core and performs
;              a moment calculation for the halo.  This provides corrections
;              for both spacecraft potential and scattered photoelectrons.
;              (Currently disabled.)
;
;   ABINS:     Anode bin mask - 16-element byte array (0 = off, 1 = on)
;              Default = replicate(1B, 16).
;
;   DBINS:     Deflector bin mask - 6-element byte array (0 = off, 1 = on)
;              Default = replicate(1B, 6).
;
;   OBINS:     Solid angle bin mask - 96-element byte array (0 = off, 1 = on)
;              Default = reform(ABINS # DBINS, 96).
;
;   MASK_SC:   Mask PA bins that are blocked by the spacecraft.  This is in
;              addition to any masking specified by ABINS, DBINS, and OBINS.
;              Default = 1 (yes).
;
;   L2ONLY:    Only process data using L2 MAG data.
;
;   QLEVEL:    Minimum quality level for calculations.  Filters out the vast
;              majority of spectra affected by the sporadic low energy
;              anomaly below 28 eV.  The validity levels are:
;
;                0B = Data are affected by the low-energy anomaly.  There
;                     are significant systematic errors below 28 eV.
;                1B = Unknown because: (1) the variability is too large to 
;                     confidently identify anomalous spectra, as in the 
;                     sheath, or (2) secondary electrons mask the anomaly,
;                     as in the sheath just downstream of the bow shock.
;                2B = Data are not affected by the low-energy anomaly.
;                     Caveat: There is increased noise around 23 eV, even 
;                     for "good" spectra.
;
;              Default for this procedure is 1B.
;
;   QINTERP:   Interpolate the potential for small gaps caused by the 
;              sporadic low-energy anomaly.  Set this keyword to the largest
;              gap (in seconds) to interpolate across.
;
;   SECONDARY: Estimate and remove secondary electrons.  This makes greatly
;              improved moments in the sheath.  Default is 1 (yes).
;              To disable, set this keyword to zero.
;
;   BIAS:      Bias to add to SWEPOS potential estimates.  Default = +0.5 V.
;
;   COMPOSITE: Try to use the composite spacecraft potential first.  If that
;              fails, then try the SWE+ method.  Default = 1 (yes).
;
;              Set this keyword to zero to ignore the composite potential and
;              force a SWE+ calculation.
;
;   OUTPUT_PATH: An output_path for testing, the save file will be put into 
;                OUTPUT_PATH/yyyy/mm/.  Directories are created as needed.
;                Default = root_data_dir() + 'maven/data/sci/swe/kp'.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-05-30 11:35:16 -0700 (Thu, 30 May 2024) $
; $LastChangedRevision: 32662 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_kp.pro $
;
;-

pro mvn_swe_kp, pans=pans, ddd=ddd, abins=abins, dbins=dbins, obins=obins, $
                mask_sc=mask_sc, mom=mom, l2only=l2only, output_path=output_path, $
                trange=trange, qlevel=qlevel, qinterp=qinterp, bias=bias, $
                composite=composite, secondary=secondary

  compile_opt idl2

  @mvn_swe_com

  delta_t = 1.95D/2D  ; start time to center time for PAD and 3D
  pans = ['']

; Process inputs

  if (size(ddd,/type) eq 0) then ddd = 0
  if (size(mom,/type) eq 0) then mom = 1
  qlevel = (n_elements(qlevel) gt 0) ? byte(qlevel[0]) < 2B : 1B
  dosec = (n_elements(secondary) gt 0) ? keyword_set(dosec) : 1
  bias = (n_elements(bias) gt 0) ? float(bias[0]) : 0.5
  docomp = (n_elements(composite) gt 0) ? keyword_set(composite) : 1

; Make sure all needed data are available

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,"No SPEC data loaded!"
    print,"No KP data generated!"
    return
  endif

  if (size(a2,/type) ne 8) then begin
    print,"No PAD data loaded!"
    print,"No KP data generated!"
    return
  endif

  dopad = 1
  if keyword_set(l2only) then begin
    str_element, swe_mag1, 'level', level, success=dopad
    if (dopad) then if (max(level) lt 2B) then dopad = 0
    if (not dopad) then begin
      print,"No MAG L2 data loaded!"
      print,"No KP PAD data generated!"
    endif
  endif

; Set the time range for processing

  if (n_elements(trange) lt 2) then begin
    t0 = min(mvn_swe_engy.time) < min(a2.time + delta_t)
    t1 = max(mvn_swe_engy.time) > max(a2.time + delta_t)
  endif else t0 = min(time_double(trange), max=t1)

  inorbit = t0 gt time_double('2014-09-22')

; Set FOV masking

  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then begin
    obins = replicate(1B, 96, 2)
    obins[*,0] = reform(abins # dbins, 96)
    obins[*,1] = obins[*,0]
  endif else obins = byte(obins # [1B,1B])
  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then obins = swe_sc_mask * obins

; Set output path and file root

  if keyword_set(output_path) then kp_path = output_path $
                              else kp_path = root_data_dir() + 'maven/data/sci/swe/kp'

  finfo = file_info(kp_path)
  if (not finfo.exists) then begin
    print,"KP root directory does not exist: ",kp_path
    return
  endif

  froot = 'mvn_swe_kp_'

; Load spacecraft ephemeris (used for filtering data)

  if (inorbit) then maven_orbit_tplot, /loadonly, /shadow

; Calculate the energy shape parameter

  if (inorbit) then begin
    mvn_swe_shape_par, trange=[t0,t1], pans=more_pans
    pans = [pans, more_pans]
  endif

; Calculate the spacecraft potential (LPW/SWE and SWE+ only)
; Don't calculate the density for negative potentials.  These
; occur mainly in the EUV shadow and the ionosphere -- in both
; cases SWEA is not measuring the bulk of the distribution.
;
; Use QLEVEL and QINTERP to filter out anomalous spectra from
; the SWEPOS estimation and interpolate missing values from nearby
; reliable measurements.

  if (inorbit) then begin
    gotpot = 0
    if (docomp) then mvn_scpot, comp=1, nocalc=1, success=gotpot
    if (not gotpot) then mvn_scpot, comp=0, lpw=0, pospot=1, negpot=0, stapot=0, shapot=0, $
                                    qlevel=qlevel, qinterp=qinterp
  endif else begin
    mvn_swe_sc_pot, erange=[5.5,20], potential=phi, qlevel=0
    phi.potential += bias
    swe_sc_pot = phi
    mvn_swe_engy.sc_pot = swe_sc_pot.potential
  endelse

  indx = where(swe_sc_pot.potential lt 0., count)
  if (count gt 0L) then begin
    swe_sc_pot[indx].potential = !values.f_nan
    mvn_swe_engy[indx].sc_pot = !values.f_nan
  endif

; Calculate the density and temperature
    
  mvn_swe_n1d, trange=[t0,t1], mom=mom, pans=more_pans, qlevel=qlevel, secondary=secondary

  pans = [pans, more_pans]

; Filter out poor solutions

  for i=0,(n_elements(more_pans)-1) do begin
    get_data, more_pans[i], data=dat, index=j
    str_element, dat, 'y', success=ok
    if (ok) then str_element, dat, 'dy', success=ok
    if (ok) then begin
      indx = where(finite(dat.y) and ~finite(dat.dy), count)
      if (count gt 0L) then begin
        dat.y[indx] = !values.f_nan
        store_data,more_pans[i],data=dat
      endif
    endif else begin
      print, "Problem with tplot variable: ", more_pans[i]
      help, dat, /str
    endelse
  endfor
  dat = 0

; Determine the parallel and anti-parallel energy fluxes
;   Exclude bins that straddle 90 degrees pitch angle
;   Apply FOV bin masking

  atime = a2.time + delta_t
  indx = where((atime ge t0) and (atime le t1), npts)

  if (npts gt 0L) then begin
    atime = atime[indx]

    t = dblarr(npts)
    eflux_pos_lo = fltarr(npts)
    eflux_pos_md = eflux_pos_lo
    eflux_pos_hi = eflux_pos_lo
    eflux_neg_lo = eflux_pos_lo
    eflux_neg_md = eflux_pos_lo
    eflux_neg_hi = eflux_pos_lo

    cnts_pos_lo = eflux_pos_lo
    cnts_pos_md = eflux_pos_lo
    cnts_pos_hi = eflux_pos_lo
    cnts_neg_lo = eflux_pos_lo
    cnts_neg_md = eflux_pos_lo
    cnts_neg_hi = eflux_pos_lo

    var_pos_lo = eflux_pos_lo
    var_pos_md = eflux_pos_lo
    var_pos_hi = eflux_pos_lo
    var_neg_lo = eflux_pos_lo
    var_neg_md = eflux_pos_lo
    var_neg_hi = eflux_pos_lo

    pad = mvn_swe_getpad(atime[0])
    energy = pad.energy[*,0]

    endx_lo = where((energy ge   5.) and (energy lt  100.), nlo)
    endx_md = where((energy ge 100.) and (energy lt  500.), nmd)
    endx_hi = where((energy ge 500.) and (energy lt 1000.), nhi)

    midpa = !pi/2.
    NaNs = replicate(!values.f_nan,64)
  
    if (dopad) then begin
      for i=0L,(npts-1L) do begin
        pad = mvn_swe_getpad(atime[i], units='counts')

        if (pad.time gt t_mtx[2]) then boom = 1 else boom = 0
        indx = where(obins[pad.k3d,boom] eq 0B, count)
        if (count gt 0L) then pad.data[*,indx] = !values.f_nan

        cnts = pad.data
        sig2 = pad.var      ; variance with digitization noise
        qual = pad.quality  ; quality flag
     
        mvn_swe_convert_units, pad, 'eflux'

        t[i] = pad.time

        ipos = where(pad.pa_max[63,*] lt midpa, npos)
        if (npos gt 0L) then begin
          eflux_pos = average(pad.data[*,ipos],2,/nan)
          cnts_pos = total(reform(cnts[*,ipos],64,npos),2,/nan)
          var_pos = total(reform(sig2[*,ipos],64,npos),2,/nan)
        endif else begin
          eflux_pos = NaNs
          cnts_pos = NaNs
          var_pos = NaNs
        endelse

        ineg = where(pad.pa_min[63,*] gt midpa, nneg)
        if (nneg gt 0L) then begin
          eflux_neg = average(pad.data[*,ineg],2,/nan)
          cnts_neg = total(reform(cnts[*,ineg],64,nneg),2,/nan)
          var_neg = total(reform(sig2[*,ineg],64,nneg),2,/nan)
        endif else begin
          eflux_neg = NaNs
          cnts_neg = NaNs
          var_neg = NaNs
        endelse

        if (qual ge qlevel) then begin
          eflux_pos_lo[i] = average(eflux_pos[endx_lo],/nan)
          cnts_pos_lo[i] = total(cnts_pos[endx_lo],/nan)
          var_pos_lo[i] = total(var_pos[endx_lo],/nan)

          eflux_neg_lo[i] = average(eflux_neg[endx_lo],/nan)
          cnts_neg_lo[i] = total(cnts_neg[endx_lo],/nan)
          var_neg_lo[i] = total(var_neg[endx_lo],/nan)
        endif else begin
          eflux_pos_lo[i] = !values.f_nan
          cnts_pos_lo[i] = !values.f_nan
          var_pos_lo[i] = !values.f_nan

          eflux_neg_lo[i] = !values.f_nan
          cnts_neg_lo[i] = !values.f_nan
          var_neg_lo[i] = !values.f_nan
        endelse

        eflux_pos_md[i] = average(eflux_pos[endx_md],/nan)
        cnts_pos_md[i] = total(cnts_pos[endx_md],/nan)
        var_pos_md[i] = total(var_pos[endx_md],/nan)

        eflux_neg_md[i] = average(eflux_neg[endx_md],/nan)
        eflux_neg_hi[i] = average(eflux_neg[endx_hi],/nan)
        cnts_neg_md[i] = total(cnts_neg[endx_md],/nan)

        eflux_pos_hi[i] = average(eflux_pos[endx_hi],/nan)
        cnts_pos_hi[i] = total(cnts_pos[endx_hi],/nan)
        var_pos_hi[i] = total(var_pos[endx_hi],/nan)

        cnts_neg_hi[i] = total(cnts_neg[endx_hi],/nan)
        var_neg_md[i] = total(var_neg[endx_md],/nan)
        var_neg_hi[i] = total(var_neg[endx_hi],/nan)
      endfor

      sdev_pos_lo = eflux_pos_lo * (sqrt(var_pos_lo)/cnts_pos_lo)
      sdev_pos_md = eflux_pos_md * (sqrt(var_pos_md)/cnts_pos_md)
      sdev_pos_hi = eflux_pos_hi * (sqrt(var_pos_hi)/cnts_pos_hi)
      sdev_neg_lo = eflux_neg_lo * (sqrt(var_neg_lo)/cnts_neg_lo)
      sdev_neg_md = eflux_neg_md * (sqrt(var_neg_md)/cnts_neg_md)
      sdev_neg_hi = eflux_neg_hi * (sqrt(var_neg_hi)/cnts_neg_hi)

; Filter out poor solutions

      indx = where(finite(eflux_pos_lo) and ~finite(sdev_pos_lo), count)
      if (count gt 0L) then eflux_pos_lo[indx] = !values.f_nan
      indx = where(finite(eflux_pos_md) and ~finite(sdev_pos_md), count)
      if (count gt 0L) then eflux_pos_md[indx] = !values.f_nan
      indx = where(finite(eflux_pos_hi) and ~finite(sdev_pos_hi), count)
      if (count gt 0L) then eflux_pos_hi[indx] = !values.f_nan

      indx = where(finite(eflux_neg_lo) and ~finite(sdev_neg_lo), count)
      if (count gt 0L) then eflux_neg_lo[indx] = !values.f_nan
      indx = where(finite(eflux_neg_md) and ~finite(sdev_neg_md), count)
      if (count gt 0L) then eflux_neg_md[indx] = !values.f_nan
      indx = where(finite(eflux_neg_hi) and ~finite(sdev_neg_hi), count)
      if (count gt 0L) then eflux_neg_hi[indx] = !values.f_nan
    endif else begin
      t = atime
      eflux_pos_lo[*] = !values.f_nan
      eflux_pos_md[*] = !values.f_nan
      eflux_pos_hi[*] = !values.f_nan
      eflux_neg_lo[*] = !values.f_nan
      eflux_neg_md[*] = !values.f_nan
      eflux_neg_hi[*] = !values.f_nan
      sdev_pos_lo = eflux_pos_lo
      sdev_pos_md = eflux_pos_md
      sdev_pos_hi = eflux_pos_hi
      sdev_neg_lo = eflux_neg_lo
      sdev_neg_md = eflux_neg_md
      sdev_neg_hi = eflux_neg_hi
    endelse

; Create TPLOT variables for save/restore file

    store_data,'mvn_swe_efpos_5_100',data={x:t, y:eflux_pos_lo, dy:sdev_pos_lo}
    store_data,'mvn_swe_efpos_100_500',data={x:t, y:eflux_pos_md, dy:sdev_pos_md}
    store_data,'mvn_swe_efpos_500_1000',data={x:t, y:eflux_pos_hi, dy:sdev_pos_hi}

    store_data,'mvn_swe_efneg_5_100',data={x:t, y:eflux_neg_lo, dy:sdev_neg_lo}
    store_data,'mvn_swe_efneg_100_500',data={x:t, y:eflux_neg_md, dy:sdev_neg_md}
    store_data,'mvn_swe_efneg_500_1000',data={x:t, y:eflux_neg_hi, dy:sdev_neg_hi}
  
    pans = [pans, 'mvn_swe_efpos_5_100', 'mvn_swe_efpos_100_500', 'mvn_swe_efpos_500_1000', $
                  'mvn_swe_efneg_5_100', 'mvn_swe_efneg_100_500', 'mvn_swe_efneg_500_1000'   ]

; Create TPLOT variables for display only

    eflux_lo = fltarr(npts,2)
    eflux_lo[*,0] = eflux_pos_lo
    eflux_lo[*,1] = eflux_neg_lo
    vname = 'mvn_swe_ef_5_100'
    store_data,vname,data={x:t, y:eflux_lo, v:[0,1]}
    ylim,vname,0,0,1
    options,vname,'labels',['pos','neg']
    options,vname,'labflag',1

    eflux_md = fltarr(npts,2)
    eflux_md[*,0] = eflux_pos_md
    eflux_md[*,1] = eflux_neg_md
    vname = 'mvn_swe_ef_100_500'
    store_data,vname,data={x:t, y:eflux_md, v:[0,1]}
    ylim,vname,0,0,1  
    options,vname,'labels',['pos','neg']
    options,vname,'labflag',1
  
    eflux_hi = fltarr(npts,2)
    eflux_hi[*,0] = eflux_pos_hi
    eflux_hi[*,1] = eflux_neg_hi
    vname = 'mvn_swe_ef_500_1000'
    store_data,vname,data={x:t, y:eflux_hi, v:[0,1]}
    ylim,vname,0,0,1  
    options,vname,'labels',['pos','neg']
    options,vname,'labflag',1
  endif

; Store the results in tplot save/restore file(s)

  date = time_string((t0 + 3600D),/date_only)
  yyyy = strmid(date,0,4)
  mm = strmid(date,5,2)
  dd = strmid(date,8,2)

  path = kp_path + '/' + yyyy
  finfo = file_info(path)
  if (~finfo.exists) then file_mkdir2, path, mode = '0775'o

  path = path + '/' + mm
  finfo = file_info(path)
  if (~finfo.exists) then file_mkdir2, path, mode = '0775'o

  tname = path + '/' + froot + yyyy + mm + dd
  fname = tname + '.tplot'
  finfo = file_info(fname)

; If the file already exists, then try to overwrite it;
; otherwise, create the file, change the group to maven,
; and make it group writable.

  indx = where(pans ne '', count)
  if (count eq 0) then begin
    print, "No tplot panels to save."
    return
  endif
  pans = pans[indx]

  if (finfo.exists) then begin
    if (~file_test(fname,/write)) then begin
      print,"Error: no write permission for: ",fname
      return
    endif
    tplot_save, pans, file=tname
  endif else begin
    tplot_save, pans, file=tname
    if (file_test(fname,/user)) then begin
      file_chmod, fname, '0664'o
      file_chgrp, fname, 'maven'
    endif
  endelse

  return

end
