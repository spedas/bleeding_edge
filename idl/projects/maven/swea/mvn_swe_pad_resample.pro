;+
;PROCEDURE: 
;	MVN_SWE_PAD_RESAMPLE
;
;PURPOSE:
;	Resamples the pitch angle distribution from SWEA PAD or 3D data,
;   averaging the signals from bins that overlap in pitch angle space.
;   Typically (and by default), pitch angle is oversampled by a factor
;   of 16 to accurately treat partial overlap.
;
;   PAD or 3D data are obtained from SWEA common block.  If you set the
;   time interval, then the snapshot of the pitch angle distribution at
;   the specified time is plotted.
;
;   The result is stored in a tplot variable and can also be returned
;   via keyword.
;
;CALLING SEQUENCE: 
;	mvn_swe_pad_resample, nbins=128., erange=[100., 150.]
;
;INPUTS: 
;   trange:    Optional: Time range for resampling.  Default is to resample
;              all data (PAD or 3D, survey or burst, depending on keywords).
;              This routine might take more than 10 minutes to process PAD 
;              survey data for one day, depending on your machine specs.
;
;KEYWORDS:
;   SILENT:    Minimize to show the processing information in the terminal.
;
;   MASK:      Mask angular bins that are blocked by the spacecraft.
;              Automatically determines whether or not the SWEA boom is
;              deployed.  Default = 1 (yes).
;
;   NO_MASK:   If set, do not mask angular bins blocked by the spacecraft.
;              Equivalent to MASK = 0.
;
;   STOW:      (Obsolete). Mask the angular bins whose field of view
;              is blocked before the boom deploy. --> This is now done
;              automatically.
;
;   DDD:       Use 3D data to resample pitch angle distribution.
;
;   PAD:       Use PAD data to resample pitch angle distribution.
;              It is the default setting.
;
;   NBINS:     Specify resampling binning numbers. Default = 128.
;
;   ABINS:     Specify which anode bins to 
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,16)
;
;   DBINS:     Specify which deflection bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,6)
;
;   MBINS:     Specify which solid angle bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = ABINS # DBINS
;
;   ARCHIVE:   Use archive (burst) data, instead of survey data.
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   WINDOW:    Set the window number to show the snapshot.  If there is
;              more than one snapshot window, then the window number 
;              increments by one for each additional window.  It is the 
;              user's responsibility to make sure these window(s) are 
;              not already in use.
;
;              Default is to use the FREE keyword in WINDOW.
;
;   RESULT:    Return the resampled pitch angle distribution data.
;
;   UNITS:     Set the units. Default = 'EFLUX'.
;
;   ERANGE:    Energy range over which to plot the pitch angle distribution.
;              For tplot case, default = 280 eV, based on the L0 tplot setting.
;
;   NORMAL:    If set, then normalize the pitch angle distribution to have an
;              average value of unity at each energy.
;
;   SNAP:      Plot a snapshot.  Default = 0 (no).
;
;   TPLOT:     Make a tplot variable.  Default = 1 (yes).
;
;   MAP3D:     Take into account the pitch angle width even for 3D
;              data. This keyword only works 3D data. The mapping
;              method is based on 'mvn_swe_padmap'.
;
;   SWIA:      Resample PAD in the plasma rest frame, where electron
;              angular distributions are typically gyrotropic. Plasma bulk
;              velocity is taken from SWIA Course data.  This keyword only
;              works after loading (restoring) SWIA data.  
;
;   HIRES:     Calculate a separate pitch angle map for each energy step 
;              within a sweep using 32-Hz MAG data.
;              See mvn_swe_padmap_32hz for caveats and details.
;
;   SC_POT:    Correct for the spacecraft potential.
;              (Not completely activated yet)
;  
;   SYMDIR:    Instead of the observed magnetic field vector, use the
;              symmetry direction of the (strahl) electron distribution.
;              The symmetry direction is calculated via 'swe_3d_strahl_dir'.
;
;   INTERPOLATE: When you try to resample the pitch angle distribtion
;                in the plasma rest frame, it calculates non-zero
;                value to have the data evaluated (interpolated) at
;                the original energy steps. This keyword is associated
;                with 'convert_vframe'.
;
;   CUT:       Plot the pitch-angle-sorted 1d spectra for each energy step.
;              It is an optional plot.
;
;   SPEC:      Plot the pitch-angle-selected 1d energy spectra. 
;              In the default settings, 5 pitch angle bands are selected.
;                 - quasi-parallel (0-30 deg),
;                 - quasi-perpendicular (75-105 deg),
;                 - quasi-antiparallel (150-180 deg),
;                 - 2 obliquenesses (30-75, 105-150 deg).
;              It is also an optional plot.
;
;   PSTYLE:    It means "plot style". This keyword allows
;              specification which plots you want to show.
;              Each option is described as follows:
;              - 1: Plots the snapshot(, equivalent to the "snap" keyword.)
;              - 2: Generates the tplot variable(, equivalent to the "tplot" keyword.)
;              - 4: Plots the pitch-angle-sorted 1d spectra(, equivalent to the "cut" keyword.)
;              - 8: Plots the pitch-angle-selected 1d energy spectra(, equivalent to the "spec" keyword.)
;              Note that this keyword is set bitwise, so multiple
;              effects can be achieved by adding values together. For
;              example, to plot the snapshot (value 1) and to generate
;              the tplot variable (value 2), set the PSTYLE keyword to
;              1+2, or 3. This basic idea is same as that
;              [x][y][z]style keyword included in default PLOT options.
;
;CREATED BY:      Takuya Hara on 2014-09-24.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-23 16:19:42 -0700 (Mon, 23 Jun 2025) $
; $LastChangedRevision: 33412 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_pad_resample.pro $
;
;-

; ----------------------------------------------------------------
;  Calculate pitch angle mapping for 3D distributions
; ----------------------------------------------------------------

FUNCTION mvn_swe_pad_resample_map3d, var, prf=prf
  @mvn_swe_com
  ddd = var
  str_element, ddd, 'magf', success=ok
  
  IF (ok) THEN BEGIN
     magf = ddd.magf
     magf /= SQRT(TOTAL(magf*magf))
     
     group = ddd.group
     Baz = ATAN(magf[1], magf[0])
     IF Baz LT 0. THEN Baz += 2.*!DPI
     Bel = ASIN(magf[2])
     
     k = indgen(96)
     i = k mod 16
     j = k / 16
     
     ddtor = !dpi/180D
     ddtors = REPLICATE(ddtor, 64)
     n = 17                     ; patch size - odd integer

     IF NOT keyword_set(prf) THEN BEGIN
        daz = DOUBLE((INDGEN(n*n) MOD n) - (n-1)/2)/DOUBLE(n-1) # DOUBLE(swe_daz[i])
        Saz = REFORM(REPLICATE(1D,n*n) # DOUBLE(swe_az[i]) + daz, n*n*96) # ddtors
     ENDIF ELSE BEGIN
        Saz = DBLARR(n*n*96, 64)
        daz = DOUBLE((INDGEN(n*n) MOD n) - (n-1)/2)/DOUBLE(n-1) # DOUBLE(swe_daz[i])
        ;; daz = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_daz[i])
        FOR m=0, 63 DO $
           Saz[*, m] = reform(replicate(1D,n*n) # double(REFORM(ddd.phi[m, *])) + daz, n*n*96)
        Saz *= ddtor
     ENDELSE 

     Sel = dblarr(n*n*96, 64)
     FOR m=0,63 DO BEGIN
        del = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_del[j,m,group])
        IF NOT keyword_set(prf) THEN $
           Sel[*,m] = reform(replicate(1D,n*n) # double(swe_el[j,m,group]) + del, n*n*96) $
        ELSE Sel[*,m] = reform(replicate(1D,n*n) # double(REFORM(ddd.theta[m, *])) + del, n*n*96)
     ENDFOR 
     Sel = Sel*ddtor

     Saz = REFORM(Saz, n*n, 96, 64) ; nxn az-el patch, 96 pitch angle bins, 64 energies     
     Sel = REFORM(Sel, n*n, 96, 64)
     pam = ACOS(COS(Saz - Baz)*COS(Sel)*COS(Bel) + SIN(Sel)*SIN(Bel))
     
     pa = TOTAL(pam, 1)/FLOAT(n*n) ; mean pitch angle
     pa_min = MIN(pam, dim=1)      ; minimum pitch angle
     pa_max = MAX(pam, dim=1)      ; maximum pitch angle
     dpa = pa_max - pa_min         ; pitch angle range
     
; Package the result
     
     pam = { pa     : FLOAT(pa)     , $ ; mean pitch angles (radians)
             dpa    : FLOAT(dpa)    , $ ; pitch angle widths (radians)
             pa_min : FLOAT(pa_min) , $ ; minimum pitch angle (radians)
             pa_max : FLOAT(pa_max) , $ ; maximum pitch angle (radians)
             iaz    : i             , $ ; anode bin (0-15)
             jel    : j             , $ ; deflector bin (0-5)
             k3d    : k             , $ ; 3D angle bin (0-95)
             Baz    : FLOAT(Baz)    , $ ; Baz in SWEA coord. (radians)
             Bel    : FLOAT(Bel)      } ; Bel in SWEA coord. (radians)
     
     str_element, ddd, 'pa', TRANSPOSE(FLOAT(pa)), /add
     str_element, ddd, 'dpa', TRANSPOSE(FLOAT(dpa)), /add
     str_element, ddd, 'pa_min', TRANSPOSE(FLOAT(pa_min)), /add
     str_element, ddd, 'pa_max', TRANSPOSE(FLOAT(pa_max)), /add
     str_element, ddd, 'iaz', i, /add
     str_element, ddd, 'jel', j, /add
     str_element, ddd, 'k3d', k, /add
     str_element, ddd, 'Baz', FLOAT(Baz), /add
     str_element, ddd, 'Bel', FLOAT(Bel), /add
  ENDIF ELSE pam = 0
  RETURN, ddd
END

; ----------------------------------------------------------------
; Resample PAD in the plasma rest frame.
; ----------------------------------------------------------------

FUNCTION mvn_swe_pad_resample_prf, var, type, archive=archive, silent=silent, energy=energy, $
                                   map3d=map3d, dformat=dformat, nbins=nbins, nene=nene, edx=edx
  nan = !values.f_nan
  swe = var
  dtype = type
  ;; energy = average(swe.energy, 2)
  result = dformat

  ;; swe = mvn_swe_3d_shift(swe, silent=silent, archive=archive, /swia)
  ;; IF (dtype EQ 1) AND (keyword_set(map3d)) THEN BEGIN
  ;;    swe = mvn_swe_pad_resample_map3d(swe, /prf)
  ;;    dtype = 0
  ;; ENDIF 
  IF (dtype EQ 1) AND (keyword_set(map3d)) THEN dtype = 0
  result.time = swe.time
  ;; xax = (0.5*(180./nbins) + FINDGEN(nbins) * (180./nbins))*!DTOR

  dx = (180./nbins) * !DTOR
  dy = MEAN(ALOG10(energy[0:swe.nenergy-2]) - ALOG10(energy[1:swe.nenergy-1]))

  xrange = [0., 180.] * !DTOR
  yrange = minmax(ALOG10(energy)) + (dy/2.)*[-1., 1.]
  IF NOT keyword_set(dtype) THEN BEGIN
     tot = DBLARR(nbins, swe.nenergy)
     tot[*] = 0.
     index = tot
     
     idx = WHERE(FINITE(swe.data), cnt)
     IF cnt GT 0 THEN BEGIN
        ; ! Causion ! 
        ; Energy order is from low to high through 'histbins2d'.
        hist = histbins2d(REFORM(swe.pa), REFORM(ALOG10(swe.energy)), xax, yax,    $
                          xrange=xrange, yrange=yrange, xbinsize=dx, ybinsize=dy, reverse=ri )
        undefine, cnt
        FOR i=0L, nbins*swe.nenergy-1L DO BEGIN
           it = ARRAY_INDICES(hist, i)
           IF ri[i] NE ri[i+1L] THEN BEGIN
              j = ARRAY_INDICES(swe.data, ri[ri[i]:ri[i+1L]-1L])
              
              npts = N_ELEMENTS(j[0, *])
              FOR k=0L, npts-1L DO BEGIN
                 idx = WHERE(FINITE(swe.data[j[0, k], j[1, k]]), cnt)
                 IF cnt GT 0 THEN BEGIN
                    undefine, cnt
                    l = WHERE(xax GE swe.pa_min[j[0, k], j[1, k]] AND $
                              xax LE swe.pa_max[j[0, k], j[1, k]], cnt)
                    IF cnt GT 0 THEN BEGIN
                       tot[l, it[1]] = tot[l, it[1]] + swe.data[j[0, k], j[1, k]]
                       index[l, it[1]] = index[l, it[1]] + 1.
                    ENDIF 
                    undefine, l
                 ENDIF 
                 undefine, idx, cnt
              ENDFOR 
              undefine, j, k, npts
           ENDIF 
           undefine, it
        ENDFOR
        undefine, i
     ENDIF ELSE tot[*] = nan
  ENDIF ELSE BEGIN
  ENDELSE 
  undefine, idx, cnt

  ; Energy order is from high to low.
  tot = TRANSPOSE(REVERSE(tot, 2))
  index = TRANSPOSE(REVERSE(index, 2))
  tot = tot[edx, *]
  index = index[edx, *]

  result.avg = tot / index
  result.nbins = index

  idx = WHERE(index LE 0., cnt)
  result.index = LONG(index / index)
  IF cnt GT 0 THEN result.index[idx] = 0
  
  result.xax = xax * !RADEG
  undefine, tot, index  
  RETURN, result
END

; ----------------------------------------------------------------
; Transform to the plasma rest frame.
; ----------------------------------------------------------------

FUNCTION mvn_swe_pad_resample_swia, var, archive=archive, silent=silent, $
                                    sc_pot=sc_pot, interpolate=interpolate
  COMPILE_OPT idl2
  @mvn_swe_com

  edat = var
  time = edat.time
  unit = edat[0].units_name
  idat = mvn_swia_get_3dc(time, archive=archive)
  ivel = v_3d(idat)             ; SWIA coordiate system

  IF time LT t_mtx[2] THEN fswe = 'MAVEN_SWEA_STOW' $
  ELSE fswe = 'MAVEN_SWEA'
  
  ;; Converting to the SWEA coordinate system. ;;
  vel = spice_vector_rotate(ivel, time, 'MAVEN_SWIA', fswe, $
                            check_objects='MAVEN_SPACECRAFT', verbose=1)
  ;IF NOT keyword_set(silent) THEN dprint, 'Shifted bulk velocity [km/s]: ', vel
  IF N_ELEMENTS(WHERE(~FINITE(vel))) EQ 3 THEN BEGIN
     dprint, 'Cannot convert the SWEA frame due to the lack of SPICE/Kernels.'
     vel = [0., 0., 0.]
     data = edat
  ENDIF ELSE $
     data = convert_vframe(edat, vel, sc_pot=sc_pot, interpolat=interpolate)

  mvn_swe_convert_units, data, unit
  RETURN, data
END
FUNCTION mvn_swe_pad_resample_cscale, data, mincol=mincol, maxcol=maxcol, mindat=mindat, maxdat=maxdat
  IF n_elements(mincol) EQ 0 THEN mincol = 0
  IF n_elements(maxcol) EQ 0 THEN maxcol = 255
  IF n_elements(mindat) EQ 0 THEN mindat = MIN(data, /nan)
  IF n_elements(maxdat) EQ 0 THEN maxdat = MAX(data, /nan)

  colrange = maxcol - mincol
  datrange = maxdat - mindat

  lodata = WHERE(data LT mindat, locount)
  hidata = WHERE(data GT maxdat, hicount)

  dat = data                    ; Copy data

  IF locount NE 0 THEN dat[lodata] = mindat
  IF hicount NE 0 THEN dat[hidata] = maxdat

  RETURN, (dat - mindat) * colrange/FLOAT(datrange) + mincol
END

; ----------------------------------------------------------------
; Main routine
; ----------------------------------------------------------------

PRO mvn_swe_pad_resample, var, mask=mask, stow=stow, ddd=ddd, pad=pad,  $
                          nbins=nbins, abins=abins, dbins=dbins, archive=archive, $
                          pans=pans, window=wi, result=result, no_mask=no_mask, $
                          units=units, erange=erange, normal=normal, _extra=extra, $
                          snap=plot, tplot=tplot, map3d=map3d, swia=swia, $
                          mbins=mbins, sc_pot=sc_pot, symdir=symdir, interpolate=interpolate, $
                          cut=cut, spec=spec, pstyle=pstyle, silent=sil, verbose=vb, $
                          hires=hires, fbdata=fbdata, tabnum=tabnum, burst=burst, $
                          success=success
  COMPILE_OPT idl2
  @mvn_swe_com
  nan = !values.f_nan 

  success = 0
  fifb = string("15b) ;"
  IF keyword_set(sil) THEN silent = sil ELSE silent = 0
  IF keyword_set(vb) THEN verbose = vb ELSE verbose = 0
  verbose -= silent
  delta_t = 1.95D/2D  ; start time to center time for PAD and 3D
  if (not keyword_set(tabnum)) then tabnum = 5B
  if keyword_set(burst) then archive = 1

;  IF SIZE(mvn_swe_engy, /type) NE 8 THEN BEGIN
;     print, ptrace()
;     print, '  No SWEA data loaded.'
;     RETURN
;  ENDIF 
  IF SIZE(swe_mag1, /type) NE 8 THEN BEGIN
     mvn_swe_addmag
     if (size(swe_mag1,/type) ne 8) then begin
       print, ptrace()
       print, '  No MAG data loaded.  Use mvn_swe_addmag first.'
       RETURN
     endif
  ENDIF

  if (tabnum gt 6) then begin
    get_data,'mvn_B_full',index=i
    if (i eq 0) then begin
      print, ptrace()
      print, '  No 32-Hz MAG data loaded.'
      return
    endif
  endif
  
; Determine which data to process (pad or 3d, survey or burst)

  IF keyword_set(ddd) OR keyword_set(map3d) THEN dtype = 1
  IF keyword_set(pad) THEN dtype = 0
  IF SIZE(dtype, /type) EQ 0 THEN dtype = 0

  IF NOT keyword_set(dtype) THEN BEGIN
     if keyword_set(archive) then begin
       if (size(a3,/type) eq 8) then dat_time = a3.time + delta_t  ; center time
       if (size(mvn_swe_pad_arc,/type) eq 8) then dat_time = mvn_swe_pad_arc.time
       if (size(dat_time,/type) eq 0) then begin
         print,'  No PAD archive data.'
         archive = 0
       endif
     endif
     if not keyword_set(archive) then begin
       if (size(a2,/type) eq 8) then dat_time = a2.time + delta_t  ; center time
       if (size(mvn_swe_pad,/type) eq 8) then dat_time = mvn_swe_pad.time
       if (size(dat_time,/type) eq 0) then begin
         print,'  No PAD survey data.  Nothing to resample.'
         return
       endif
     endif
  ENDIF ELSE BEGIN
     if keyword_set(archive) then begin
       if (size(swe_3d_arc,/type) eq 8) then dat_time = swe_3d_arc.time + delta_t  ; center time
       if (size(mvn_swe_3d_arc,/type) eq 8) then dat_time = mvn_swe_3d_arc.time
       if (size(dat_time,/type) eq 0) then begin
         print,'  No 3D archive data.'
         archive = 0
       endif
     endif
     if not keyword_set(archive) then begin
       if (size(swe_3d,/type) eq 8) then dat_time = swe_3d.time + delta_t  ; center time
       if (size(mvn_swe_3d,/type) eq 8) then dat_time = mvn_swe_3d.time
       if (size(dat_time,/type) eq 0) then begin
         print,'  No 3D survey data.  Nothing to resample.'
         return
       endif
     endif

     IF keyword_set(symdir) THEN BEGIN
        swe_3d_strahl_dir, result=strahl, archive=archive
        
        idx = nn2(dat_time, strahl.time)
        magf = [ [COS(strahl.theta[idx]*!DTOR) * COS(strahl.phi[idx]*!DTOR)], $
                 [COS(strahl.theta[idx]*!DTOR) * SIN(strahl.phi[idx]*!DTOR)], $
                 [SIN(strahl.theta[idx]*!DTOR)] ]
        str_element, strahl, 'magf', magf, /add
        undefine, magf
     ENDIF 
  ENDELSE

; Hires PAD data (select data by table number)

  dwell = 0
  if ((tabnum ge 7) and (tabnum le 9)) then begin
    dtype = 0  ; only PAD data for now
    if keyword_set(archive) then begin
      idx = where(a3.lut eq tabnum, ndat)
      if (ndat eq 0) then begin
        print, ptrace()
        print, "  No hires PAD archive data with requested sweep table: ",tabnum
        archive = 0
      endif
    endif
    if not keyword_set(archive) then begin
      idx = where(a2.lut eq tabnum, ndat)
      if (ndat eq 0) then begin
        print, ptrace()
        print, "  No hires PAD survey data with requested sweep table: ",tabnum
        return
      endif
    endif
    dwell = 1
    case tabnum of
        7  : erange = 199.
        8  : erange = 49.
        9  : erange = 125.
      else : begin
               print, ptrace()
               print, "  This should be impossible!  TABNUM: ",tabnum
               return
             end
    endcase
  endif

; Process time or time range, if specified

  if (not dwell) then begin
    IF SIZE(var, /type) NE 0 THEN BEGIN
       trange = var
       IF SIZE(trange, /type) EQ 7 THEN trange = time_double(trange)
       IF SIZE(plot, /type) EQ 0 THEN plot = 1
       CASE N_ELEMENTS(trange) OF
          1: BEGIN
             ndat = 1
             idx = nn2(dat_time, trange)
          END 
          2: BEGIN
             idx = WHERE(dat_time GE MIN(trange) AND dat_time LE MAX(trange), ndat)
             IF ndat EQ 0 THEN BEGIN
                PRINT, ptrace()
                PRINT, '  No data during the specified time you set.'
                RETURN
             ENDIF 
          END 
          ELSE: BEGIN
             PRINT, ptrace()
             PRINT, '  You must input 1 or 2 element(s) of the time interval.'
             RETURN
          END 
       ENDCASE 
    ENDIF ELSE BEGIN
       trange = minmax(dat_time)
       ndat = N_ELEMENTS(dat_time)
       idx = LINDGEN(ndat)
    ENDELSE
  endif

; Process keywords and set options

  if (size(tplot,/type) eq 0) then tplot = 1
  IF keyword_set(swia) THEN mvn_swe_spice_init, trange=trange
  IF NOT keyword_set(units) THEN units = 'eflux'
  IF NOT keyword_set(nbins) THEN nbins = 128.
  IF NOT keyword_set(wi) THEN wnum = -1 ELSE wnum = wi
  IF NOT keyword_set(erange) AND keyword_set(tplot) THEN erange = 280.
  IF (SIZE(mask, /type) EQ 0) AND (SIZE(no_mask, /type) EQ 0) THEN mask = 1
  IF keyword_set(no_mask) THEN mask = 0
  IF keyword_set(hires) THEN hflg = 1 ELSE hflg = 0
  IF SIZE(pstyle, /type) EQ 0 THEN BEGIN
     pstyle = 0
     IF keyword_set(plot) THEN IF plot GT 0 THEN pstyle += 1
     IF keyword_set(tplot) THEN IF tplot GT 0 THEN pstyle += 2
     IF keyword_set(cut) THEN IF cut GT 0 THEN pstyle += 4
     IF keyword_set(spec) THEN IF spec GT 0 THEN pstyle += 8
  ENDIF
  pflg = BYTARR(4)
  FOR i=0, 3 DO pflg[i] = (pstyle AND 2L^i)/2L^i

; Field of view masking

  if (n_elements(abins) ne 16) then abins = replicate(1., 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1., 6)
  if (n_elements(mbins) ne 96) then mbins = reform(abins # dbins, 96)
  mobins = mbins # [1.,1.]  ; same mask for both boom states

  if (size(mask,/type) eq 0) then mask = 1
  if keyword_set(mask) then mobins *= float(swe_sc_mask)

  i = where(mobins eq 0., cnt)
  if (cnt gt 0) then mobins[i] = nan

; SWEA boom state: 0 = stowed, 1 = deployed

  boom = replicate(1, ndat)
  i = where((dat_time[idx] lt t_mtx[2]), cnt)
  if (cnt gt 0) then boom[i] = 0
  undefine, i, cnt

  IF STRLOWCASE(!version.os_family) EQ 'windows' THEN chsz = 1. ELSE chsz = 1.3
  plim = {noiso: 1, zlog: 1, charsize: chsz, xticks: 6, xminor: 3, xrange: [0., 180.], ylog: 1}
  start = SYSTIME(/sec)
  cet = 0.d0
  IF keyword_set(silent) THEN prt = 0 ELSE prt = 1

; Select energy bins for processing
;   Sweep table 5 is used almost all the time, and the energy bins
;   of tables 5 and 6 are within 20% of each other.  So, select 
;   energy bins using table 5 only.

  if (dwell) then begin
    nene = 1
    edx = 0
    nchan = 64
  endif else begin

    mvn_swe_sweep, tab=5, result=sdat
    energy = sdat.e
    nchan = 1

    case n_elements(erange) of
         0 : begin
               nene = n_elements(energy)
               edx = indgen(nene)
             end
         1 : begin
               nene = 1
               edx = nn2(energy, erange)
             end 
      else : begin
               emin = min(erange, max=emax)
               edx = where((energy ge emin) and (energy le emax), nene)
               if (nene eq 0) then begin
                  print, ptrace()
                  print, '  No energy bins within range: ',[emin,emax]
                  return
               endif
             end 
    endcase

  endelse

  dformat = {time  : 0.d0                , $
             xax   : FLTARR(nbins)       , $
             index : FLTARR(nene, nbins) , $
             avg   : FLTARR(nene, nbins) , $
             std   : FLTARR(nene, nbins) , $
             nbins : FLTARR(nene, nbins)    }
        
  result = replicate(dformat, ndat*nchan)

; Loop through data in time sequence

  FOR i=0L,(ndat-1L) DO BEGIN

     IF i EQ 0L THEN BEGIN
        t0 = SYSTIME(/sec)
        dt = SYSTIME(/sec) - t0
        undefine, t0
     ENDIF 

     IF keyword_set(dtype) THEN BEGIN
        ddd = mvn_swe_get3d(dat_time[idx[i]], units=units, archive=archive)
        if (size(ddd,/type) ne 8) then begin
          pa = dformat
          if (nchan gt 1) then pa = replicate(pa, nchan)
          GOTO, skip_spec
        endif
        if (not ok) then begin
          pa = dformat
          if (nchan gt 1) then pa = replicate(pa, nchan)
          GOTO, skip_spec
        endif
        dtime = ddd.time
        dname = ddd.data_name
        energy = average(ddd.energy, 2)
        tabok = ddd.lut eq tabnum
        if keyword_set(sc_pot) then begin
          pot = swe_sc_pot[nn2(swe_sc_pot.time, ddd.time)].potential
          if (finite(pot)) then begin
            mvn_swe_convert_units, ddd, 'df'
            ddd.energy -= pot
            mvn_swe_convert_units, ddd, units
          endif
        endif

        IF keyword_set(swia) THEN $
           ddd = mvn_swe_pad_resample_swia(ddd, archive=archive, interpolate=interpolate, $
                                           silent=silent, sc_pot=sc_pot)
        
        IF keyword_set(symdir) THEN $
           ddd.magf = strahl.magf[nn2(strahl.time, ddd.time), *]
     
        magf = ddd.magf
        magf /= SQRT(TOTAL(magf * magf))
        
        ;; ddd.data *= REBIN(TRANSPOSE(obins), ddd.nenergy, ddd.nbins)
        ddd.data *= REBIN(TRANSPOSE(mobins[*, boom[i]]), ddd.nenergy, ddd.nbins)
        IF keyword_set(map3d) THEN ddd = mvn_swe_pad_resample_map3d(ddd, prf=interpolate)
     ENDIF ELSE BEGIN
        pad = mvn_swe_getpad(dat_time[idx[i]], units=units, archive=archive)
        if (size(pad,/type) ne 8) then begin
          pa = dformat
          if (nchan gt 1) then pa = replicate(pa, nchan)
          GOTO, skip_spec
        endif
        dtime = pad.time
        dname = pad.data_name
        energy = average(pad.energy, 2)
        tabok = pad.lut eq tabnum
        IF (hflg) THEN pad = mvn_swe_padmap_32hz(pad, fbdata=fbdata, verbose=verbose)
        if (dwell) then pad = swe_pad32hz_unpack(pad)
        if (size(pad,/type) ne 8) then begin
          pa = dformat
          if (nchan gt 1) then pa = replicate(pa, nchan)
          GOTO, skip_spec
        endif
        if keyword_set(sc_pot) then begin
          pot = swe_sc_pot[nn2(swe_sc_pot.time, pad.time)].potential
          if (finite(pot)) then begin
            mvn_swe_convert_units, pad, 'df'
            pad.energy -= pot
            mvn_swe_convert_units, pad, units
          endif
        endif

        for j=0,(nchan-1) do begin
         ; print, 'Block check'
          ;; pad.data *= REBIN(TRANSPOSE(obins[pad.k3d]), pad.nenergy, pad.nbins)
          pad[j].data *= REBIN(TRANSPOSE(mobins[pad[j].k3d, boom[i]]), pad[j].nenergy, pad[j].nbins)
          block = WHERE(~FINITE(mobins[pad[j].k3d, boom[i]]), nblock)
          IF ((nblock GT 0) and prt) THEN BEGIN
             tblk = 'Removed blocked bin(s): ['
             FOR iblk=0, nblock-1 DO BEGIN
                tblk += STRING(block[iblk], '(I0)')
                IF iblk NE nblock-1 THEN tblk += ', '
             ENDFOR 
             tblk += ']'
;            dprint, tblk, dlevel=2, verbose=3-silent
;            undefine, iblk, tblk
          ENDIF ELSE tblk = 'Removed blocked bin(s): none             '
          ; stop
          undefine, block, nblock
        endfor
     ENDELSE 

     pa = dformat
     if (nchan gt 1) then pa = replicate(pa, nchan)
     IF keyword_set(map3d) THEN BEGIN
        pad = ddd
        GOTO, pad_resample
     ENDIF

     IF (not tabok) THEN BEGIN
        pa.time  = dtime
        pa.xax   = !values.f_nan
        pa.index = !values.f_nan
        pa.avg   = !values.f_nan
        pa.std   = !values.f_nan
        pa.nbins = !values.f_nan
        GOTO, skip_spec
     ENDIF

     IF keyword_set(dtype) THEN BEGIN
        angle = FLTARR(nene, ddd.nbins)
        FOR j=0, nene-1 DO FOR k=0, ddd.nbins-1 DO BEGIN
           vec = [COS(ddd.theta[edx[j], k]*!DTOR) * COS(ddd.phi[edx[j], k]*!DTOR), $
                  COS(ddd.theta[edx[j], k]*!DTOR) * SIN(ddd.phi[edx[j], k]*!DTOR), $
                  SIN(ddd.theta[edx[j], k]*!DTOR) ]
           angle[j, k] = ACOS(magf ## TRANSPOSE(vec)) * !RADEG
           undefine, vec
        ENDFOR 
        undefine, j, k
        
        pa.time = ddd.time
        ; Resampling 
        FOR j=0, nene-1 DO BEGIN
           k = WHERE(FINITE(ddd.data[edx[j], *]))
           bin1d, REFORM(angle[j, k]), REFORM(ddd.data[edx[j], k]), 0., 180., (180./nbins), kinbin, xax, avg, std
           pa.avg[j, *] = avg
           pa.std[j, *] = std
           pa.nbins[j, *] = kinbin
           undefine, kinbin, avg, std, k
        ENDFOR 
        undefine, j

        data = pa.avg
        data[*] = 0.d
     
        pa.index = 0.
        FOR j=0, nene-1 DO BEGIN
           jdx = WHERE(pa.nbins[j, *] GT 0, cnt)
           IF cnt GT 0 THEN BEGIN
              data[j, MIN(jdx):MAX(jdx)] = INTERPOL(REFORM(pa.avg[j, jdx]), xax[jdx], xax[MIN(jdx):MAX(jdx)],/nan)
              pa.index[j, MIN(jdx):MAX(jdx)] = 1.
           ENDIF 
           undefine, jdx, cnt
           jdx = WHERE(data[j, *] LT 0., cnt)
           IF cnt GT 0 THEN data[j, jdx] = 0.
           undefine, jdx, cnt
        ENDFOR 
        undefine, j
        pa.avg = data
        pa.xax = xax
     ENDIF ELSE BEGIN
        pad_resample:
        ;; IF keyword_set(swia) THEN $
        IF NOT keyword_set(interpolate) AND keyword_set(swia) THEN $
           pa = mvn_swe_pad_resample_prf(pad, dtype, silent=silent, archive=archive, map3d=map3d, $
                                         nbins=nbins, nene=nene, edx=edx, dformat=dformat, energy=energy) $
        ELSE BEGIN
         ; print, 'pad branch'
         ; stop
          pa.time = pad.time
          ; Make a new equally spaced array for the pitch angle for the data
          ; to be discretized into:
          xax = (0.5*(180./nbins) + FINDGEN(nbins) * (180./nbins)) * !DTOR
          for m=0,(nchan-1) do begin
            ; Resampling
            ; Iterate over (requested) energies:
            FOR j=0, nene-1 DO BEGIN
               tot = DBLARR(nbins)
               variance = tot
               index = tot
               ; Iterate over # old pitch angle bins
               FOR k=0, pad[m].nbins-1 DO BEGIN
                  ; For each en/PA, get the non-NaN fluxes:
                  l = WHERE(~FINITE(pad[m].data[edx[j], k]), cnt)
                  IF cnt EQ 0 THEN BEGIN
                     ; indices between min pa and max pa to fill in the resampled struc:
                     l = WHERE((xax GE pad[m].pa_min[edx[j],k]) AND (xax LE pad[m].pa_max[edx[j],k]), cnt)
                     ; print, l
                     ; stop

                     IF cnt GT 0 THEN BEGIN
                        ; if there are any:
                        tot[l] += pad[m].data[edx[j], k]
                        variance[l] += pad[m].var[edx[j], k]
                        index[l] += 1.
                     ENDIF 
                  ENDIF 
                  undefine, l, cnt
               ENDFOR 
               undefine, k

;              stop

               pa[m].avg[j,*] = tot/index               ; average signal of overlapping PA bins
               pa[m].nbins[j,*] = index                 ; normalization factor (# overlapping PA bins)
               pa[m].index[j,*] = float(index gt 0.)    ; bins that have signal (1=yes, 0=no)
               pa[m].std[j,*] = SQRT(variance) / index  ; standard deviation (error propagation)
               undefine, k, cnt
               undefine, tot, index, variance
            ENDFOR  
            pa.xax = xax * !RADEG
            undefine, tot, index
          endfor
        ENDELSE 
     ENDELSE  
     skip_spec:
     if (nchan gt 1) then result[(i*nchan):(i*nchan + 63)] = pa else result[i] = pa
     undefine, pa, data, xax
     undefine, ddd, pad, magf

     IF ndat GT 1 THEN BEGIN
        IF keyword_set(silent) THEN BEGIN
           IF i GT 0L THEN IF SYSTIME(/sec)-start GT cet THEN BEGIN
              prt = 1
              cet += dcet
           ENDIF 
        ENDIF
        IF i EQ ndat-1L THEN prt = 1
        IF i EQ 0L THEN BEGIN
           dcet = ((SYSTIME(/sec)-start-dt)*DOUBLE(ndat-1L))/5.
           cet = +dcet
;          print, ptrace()
;          print, '  Resampling Start (Expected time needed to complete: ' + $
;                 STRING(5.*dcet, '(f0.1)') + ' sec).'
        ENDIF ELSE BEGIN
           IF prt EQ 1 THEN $
              print, format='(a, a, a, i3, a, f6.1, a, $)', $
                     '      ', fifb, '  Resampling ' + $
                     dname + ' data is ', round(FLOAT(i)/FLOAT(ndat-1L)*100.), ' % complete (', $
                     SYSTIME(/sec)-start, ' sec).' ; , tblk
        ENDELSE 
        IF keyword_set(silent) THEN prt = 0
     ENDIF  
  ENDFOR
  
  success = 1  ; found data and resampled
  undefine, i
  IF ndat GT 1 THEN PRINT, ' '

  CASE units OF
     'counts': oztit = 'Counts / Samples'
     'crate' : oztit = 'CRATE'
     'eflux' : oztit = 'EFLUX'
     'flux'  : oztit = 'FLUX'
     'df'    : oztit = 'Distribution Function'
     ELSE    : oztit = 'Unknown Units' 
  ENDCASE 
  IF keyword_set(normal) THEN $
     ztit = 'Normalized ' + oztit ELSE ztit = oztit

  IF (pflg[0]) OR (pflg[2]) OR (pflg[3]) THEN BEGIN
     tit = dname + '!C' + time_string(MIN(result.time))
     IF ndat GT 1 THEN BEGIN
        tit += ' - ' + time_string(MAX(result.time))
        zdata = TRANSPOSE(TOTAL(result.avg, 3, /nan) / TOTAL(result.index, 3, /nan)) 
        xax = average(result.xax, 2)
        
        index = TRANSPOSE(TOTAL(result.index, 3, /nan))
        i = WHERE(index GE 1, cnt)
        IF cnt GT 0 THEN index[i] = 1
        undefine, i, cnt
     ENDIF ELSE BEGIN
        zdata = TRANSPOSE(result.avg / result.index)
        xax = result.xax
        
        index = TRANSPOSE(result.index)
     ENDELSE 

     nfct = average(zdata, 1, /nan)
     IF keyword_set(normal) THEN BEGIN
        ;; zdata /= REBIN(TRANSPOSE(average(zdata, 1, /nan)), nbins, nene)
        zdata /= REBIN(TRANSPOSE([nfct]), nbins, nene)

        i = WHERE(index EQ 0, cnt)
        IF cnt GT 0 THEN zdata[i] = nan
        undefine, i, cnt

        ;; str_element, plim, 'zrange', [0.1, 10.], /add        
        str_element, plim, 'zrange', [0.5, 1.5], /add
        str_element, plim, 'zlog', 0, /add_replace
     ENDIF
  ENDIF 

  IF (pflg[0]) THEN BEGIN       ; Plot snapshots
     win, wnum, xsize=640, ysize=512, /secondary, dx=10, dy=10
     plotxyz, xax, energy[edx], zdata, _extra=plim, $
              xtit='Pitch Angle [deg]', ytit='Energy [eV]', ztit=ztit, $
              yrange=minmax(energy), title=tit, xmargin=[0.15, 0.17], ymargin=[0.10, 0.09]
     wnum0 = wnum
     wnum += 1
  ENDIF 

  ;; IF keyword_set(tplot) THEN BEGIN
  IF (pflg[1]) THEN BEGIN       ; Generate a tplot variable
     emins = strtrim(string(round(min(energy[edx]))),2)
     emaxs = strtrim(string(round(max(energy[edx]))),2)
     tname = 'pad_' + emins + '_' + emaxs + '_resample'

     ytit = 'SWE PAD!C('
     IF nene EQ 1 THEN ytit += emins + ' eV)' $
                  ELSE ytit += emins + ' - ' + emaxs + ' eV)' 

     data = TRANSPOSE(average(result.avg, 1, /nan))
     nfactor = average(data, 2, /nan)
     IF keyword_set(normal) THEN BEGIN
        data /= REBIN(nfactor, ndat*nchan, nbins)
        index = TRANSPOSE(average(result.index, 1))
        index[WHERE(index EQ 0.)] = nan
        index[WHERE(FINITE(index))] = 1.
        data *= index
        zrange = [0.5, 1.5]
        zlog = 0
     ENDIF ELSE BEGIN
        zlog = 1
        davg = MEAN(ALOG10(data[WHERE(data GT 0.)]))
        dstd = STDDEV(ALOG10(data[WHERE(data GT 0.)]))
        zrange = [10.^(davg - dstd*2.), 10.^(davg + dstd*2.)]
     ENDELSE 

     IF (size(pans,/type) ne 7) THEN pans = tname
     store_data, pans, $
                 data={x: result.time, y: data, v: TRANSPOSE(result.xax)}, $
                 dlim={nfactor: nfactor, spec: 1, yrange: [0., 180.], ystyle: 1, $
                       yticks: 6, yminor: 3, ytitle: ytit, ysubtitle: '[deg]', $
                       ztitle: ztit, zlog: zlog, zrange: zrange, erange:minmax(energy[edx])}
     copy_data,tname,'mvn_swe_pad_resample'
  ENDIF 
  ;; plim = {noiso: 1, zlog: 1, charsize: chsz, xticks: 6, xminor: 3, xrange: [0., 180.], ylog: 1}  

  IF (pflg[2]) OR (pflg[3]) THEN BEGIN 
     pos = [0.15, 0.10, 0.83, 0.91]
     pbar = pos
     pbar[0] = pos[2] + (pos[2]-pos[0])*.05  
     pbar[2] = pos[2] + (pos[2]-pos[0])*.1
     
     IF NOT keyword_set(normal) THEN $
        spec = mvn_swe_getspec(trange, /sum, archive=archive, units=units, yrange=yrange) $
     ELSE yrange = [0.1, 10.]
     undefine, spec
  ENDIF 

  IF (pflg[2]) THEN BEGIN       ; Plot pitch-angle-sorted 1-d spectra.
     ;; lc = colorscale(ALOG10(energy), mincol=7, maxcol=254, mindat=MIN(ALOG10(energy)), maxdat=MAX(ALOG10(energy)))
     lc = mvn_swe_pad_resample_cscale(ALOG10(energy), mincol=7, maxcol=254, $
                                      mindat=MIN(ALOG10(energy)), maxdat=MAX(ALOG10(energy)))
     ok = size(wnum0,/type) eq 2
     if (ok) then win, wnum, xsize=640, ysize=512, relative=wnum0, dx=10, /top $
             else win, wnum, xsize=640, ysize=512, /secondary, dx=10, dy=10
     PLOT_IO, /nodata, [0., 180.], yrange, charsize=chsz, xticks=6, xminor=3, $
              xrange=[0., 180.], /xstyle, yrange=yrange, /ystyle, xtitle='Pitch Angle [deg]', $
              ytitle=ztit, title=tit, pos=pos
     FOR i=0, N_ELEMENTS(edx)-1 DO $
        OPLOT, xax, zdata[*, i], psym=10, color=lc[edx[i]]
     
     draw_color_scale, range=minmax(energy), /log, charsize=chsz, pos=pbar, $
                       brange=[7, 254], ytitle='Energy [eV]'
     wnum2 = wnum
     wnum += 1
  ENDIF 

  IF (pflg[3]) THEN BEGIN       ; Plot pitch-angle-selected 1-d energy spectra.
     ;; lc = colorscale(xax, mincol=7, maxcol=254, mindat=0., maxdat=180.)
     angle = [15., 52.5, 90., 127.5, 165.]
     lc = mvn_swe_pad_resample_cscale(angle, mincol=7, maxcol=254, mindat=0., maxdat=180.)

     ok = size(wnum0,/type) eq 2
     if (ok) then win, wnum, xsize=640, ysize=512, relative=wnum0, dy=-10, /left
     if (not ok) then begin
       ok = size(wnum2,/type) eq 2
       if (ok) then win, wnum, xsize=640, ysize=512, relative=wnum2, dx=10, /top $
               else win, wnum, xsize=640, ysize=512, /secondary, dx=10, dy=10
     endif
     wnum3 = wnum

     spec = mvn_swe_getspec(trange, /sum, archive=archive, units=units, yrange=yrange) 
     PLOT_OO, /nodata, minmax(energy), yrange, charsize=chsz, $
              xrange=minmax(energy), /xstyle, yrange=yrange, /ystyle, xtitle='Energy [eV]', $
              ytitle=oztit, title=tit, pos=pos

     IF keyword_set(normal) THEN zdata2 = zdata * REBIN(TRANSPOSE([nfct]), nbins, nene) ELSE zdata2 = zdata
     
     ;; FOR i=0, nbins-1 DO $
     ;;    OPLOT, energy, zdata2[i, *], psym=10, color=lc[i]
     FOR i=0, N_ELEMENTS(lc)-1 DO BEGIN
        IF (i MOD 2) EQ 0 THEN j = WHERE(xax GE angle[i] - 15. AND xax LE angle[i] + 15.) $
        ELSE j = WHERE(xax GE angle[i] - 22.5 AND xax LE angle[i] + 22.5) 

        zavg = average(zdata2[j, *], 1, stdev=zdev, /nan)
        ;; oploterror, energy, zavg, zdev, color=lc[i], errcolor=lc[i], psym=10
        OPLOT, energy, zavg, color=lc[i], psym=10
        FOR k=0, N_ELEMENTS(energy)-1 DO $ ; Draws error bars.
           plots, [energy[k], energy[k]], [zavg[k]-zdev[k], zavg[k]+zdev[k]], color=lc[i]

        undefine, zavg, zdev, j, k
     ENDFOR 
     draw_color_scale, range=[0., 180.], charsize=chsz, pos=pbar, $
                       brange=[7, 254], ytitle='Pitch Angle [deg]', yticks=6, xminor=3
     undefine, spec
  ENDIF 

  RETURN
END
