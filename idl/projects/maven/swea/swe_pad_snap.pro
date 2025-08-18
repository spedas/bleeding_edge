;+
;PROCEDURE:   swe_pad_snap
;PURPOSE:
;  Plots PAD snapshots in a separate window for times selected with the cursor in
;  a tplot window.  Hold down the left mouse button and slide for a movie effect.
;  A PAD snapshot is an pitch angle X energy spectrogram at the selected time.
;  Optionally, keyword ENERGY can be used to plot a PAD in histogram mode for a 
;  single energy.
;
;USAGE:
;  swe_pad_snap
;
;INPUTS:
;
;KEYWORDS:
;       ENERGY:        Energy (eV) to use for the histogram plot.
;
;       UNITS:         Plot PAD data in these units.
;
;       LASTPAD:       Named variable to hold a PAD structure at the last time
;                      selected.
;
;       RESULT:        Named variable to hold the data used in the various plots.
;
;       DDD:           If set, compare with the nearest 3D spectrum.
;
;       CENTER:        Specify the center azimuth for 3D plots.  Only works when DDD
;                      is set.
;
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       TSMO:          Smoothing interval, in seconds.  Default is no smoothing.
;
;       SMO:           Number of energy bins to smooth over.
;
;       NORM:          At each energy step, normalize the distribution to the mean.
;
;       POT:           Overplot an estimate of the spacecraft potential.  Must run
;                      mvn_scpot first.  Default = 1 (yes).
;
;       SCP:           Temporarily override any other estimates of the spacecraft
;                      potential and force it to be this value.
;
;       SHIFTPOT:      Correct for the spacecraft potential.  If the data are in
;                      instrument units (COUNTS, RATE, CRATE), then the energy
;                      scale is shifted by the amount of the potential, but the 
;                      signal level remains unchanged.  If the data are in physical
;                      units (FLUX, EFLUX, DF), then the signal level is also
;                      adjusted to ensure conservation of phase space density.
;
;       SEC:           Remove secondary electrons.
;
;       SCONFIG:       Structure of parameters for the secondary electron models.
;
;                        {e0:e0, s0:s0, e1:e1, s1:s1, scl:scl}
;
;       LABEL:         Label the anode and deflection bin numbers (label=1) or the
;                      solid angle bin numbers (label=2).
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       KILLWINS:      If set, then close the snapshot window(s) on exit no matter what.
;                      Takes precedence over KEEPWINS.
;
;       MONITOR:       Put snapshot windows in this monitor.  Monitors are numbered
;                      from 0 to N-1, where N is the number of monitors recognized
;                      by the operating system.  See win.pro for details.
;
;       ARCHIVE:       If set, show snapshots of archive data.
;
;       BURST:         Synonym for ARCHIVE.
;
;       DIR:           If set, show some useful information with
;                      respect to the observed vector magnetic field
;                      in the MSO and LGEO(local geographic coordinate). 
;
;       ABINS:         Anode bin mask -> 16 elements (0 = off, 1 = on)
;                      Default = replicate(1,16)
;
;       DBINS:         Deflector bin mask -> 6 elements (0 = off, 1 = on)
;                      Default = replicate(1,6)
;
;       OBINS:         3D solid angle bin mask -> 96 elements (0 = off, 1 = on)
;                      Default = reform(ABINS # DBINS)
;
;       MASK_SC:       Mask the spacecraft blockage.  This is in addition to any
;                      masking defined by the ABINS, DBINS, and OBINS.
;                      Default = 1 (yes).  Set this to 0 to disable and use the
;                      above 3 keywords only.
;
;       SPEC:          Plot energy spectra for parallel, anti-parallel, and
;                      90-degree pitch angle populations.  The value of this 
;                      keyword is the pitch angle width (deg) that is used
;                      to separate the populations:
;
;                        parallel      : 0 to SPEC degrees
;                        middle        : SPEC to (180 - SPEC) degrees
;                        anti-parallel : (180 - SPEC) to 180 degrees
;
;                      Pitch angle bins must be entirely contained within
;                      one of these ranges to be included.
;
;                      Any value of SPEC < 30 deg is taken to be 30 deg.
;
;        NOMID:        When using keyword SPEC, do not plot the energy spectrum
;                      for the middle range of pitch angles.  Plot only the 
;                      spectra for parallel and anti-parallel populations.
;
;        PLOTLIMS:     Plot dashed lines at the limits of the pitch angle
;                      coverage.
;
;        PEP:          Plot vertical dashed lines at the nominal photoelectron
;                      energy peaks at 23 and 27 eV (due to ionization of CO2
;                      and O by 304-Angstrom He-II line).
;
;        RESAMPLE:     Two independent pitch angle distributions are measured 
;                      for each PAD data structure.  This keyword averages them
;                      together and plots the result.
;
;        UNCERTAINTY:  If set, show the relative uncertainty of the resampled PAD.
;
;        ERROR_BARS:   Plot energy spectra with error bars.  Default = 1 (yes).
;
;        MINCOUNTS:    Minumum number of counts for plotting.  Default = 10.
;
;        MAXRERR:      Maximum relative error in resampled PADs.  Default = 10
;                      (i.e., disabled).  Set this to some lower value (~1) to
;                      filter out data with large relative errors.
;
;        HIRES:        Use 32-Hz MAG data to map pitch angle with high time 
;                      resolution within a 2-second SWEA measurement cycle.  A
;                      separate pitch angle map is determined for each of the
;                      64 energy steps.  You must first load 32-Hz MAG data for 
;                      this keyword to be effective.  Please read warnings in 
;                      mvn_swe_padmap_32Hz.pro.
;
;        FBDATA:       Tplot variable name that contains the 32-Hz MAG data.
;                      Default = 'mvn_B_full'.
;
;        ADIABATIC:    Calculate and display the adiabatic condition:
;
;                        (1/B)*(dB/dx)*Rg << 1
;
;                      which is the fractional change in the magnetic field over
;                      one gyroradius.  Only works when HIRES is set.
;
;        POPEN:        Set this to the name of a postscript file for output.
;        
;        INDSPEC:      To plot out the energy spectrum for each PA bins
;        
;        TWOPOT:       Set to a two-element array to allow shifting different
;                      potentials on parallel and anti-parallel directions.
;                        -> Assumes data are in EFLUX units.
;                        -> Assumes SHIFTPOT is not set.
;
;        VDIS:         Plot the velocity distribution function based on the PAD
;                      data.  This will be symmetric because each PAD is a 2D
;                      cut through the 3D distribution.
;
;        XRANGE:       Override Espec energy range with this.
;
;        YRANGE:       Override Espec flux range with this.
;
;        ZRANGE:       Override default color scale range with this.
;
;        TRANGE:       Plot snapshot for this time range.  Can be in any
;                      format accepted by time_double.  (This disables the
;                      interactive time range selection.)
;
;        PYRANGE:      Override normalized PAD y plot range with this.
;
;        WSCALE:       Scale all window sizes by this factor.  Default = 1.
;
;        CSCALE:       Scale all characters by this factor.  Default = 1.
;
;        PADMAP:       Show the pitch angle map for the current spectrum.
;                      Boundaries for the 3D solid angle bins are shown, and
;                      if TSMO=0 and SUM=0, then boundaries for the PAD cut 
;                      are also shown.  Bins blocked by the spacecraft are 
;                      marked with a yellow 'X'.
;
;        COLOR_TABLE:  Use this color table for all plots.
;
;        REVERSE_COLOR_TABLE:  Reverse the color table (except for fixed colors).
;
;        LINE_COLORS:  Use this for the line colors.
;
;        NOTE:         Insert a text label.  Keep it short.
;
;        QLEVEL:       Minimum quality level to plot (0-2, default=0):
;                         2B = good
;                         1B = uncertain
;                         0B = affected by low-energy anomaly
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-04-05 14:36:55 -0700 (Sat, 05 Apr 2025) $
; $LastChangedRevision: 33233 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_pad_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_pad_snap, keepwins=keepwins, killwins=killwins, archive=archive, energy=energy, $
                  units=units, lastpad=pad, ddd=ddd, zrange=zrange, sum=sum, $
                  label=label, smo=smo, dir=dir, mask_sc=mask_sc, $
                  abins=abins, dbins=dbins, obins=obins, burst=burst, $
                  pot=pot, scp=scp, spec=spec, plotlims=plotlims, norm=norm, $
                  center=center, pep=pep, resample=resample, hires=hires, $
                  fbdata=fbdata, monitor=monitor, adiabatic=adiabatic, $
                  nomid=nomid, uncertainty=uncertainty, nospec90=nospec90, $
                  shiftpot=shiftpot,popen=popen, indspec=indspec, twopot=twopot, $
                  xrange=xrange, error_bars=error_bars, yrange=yrange, trange=trange2, $
                  note=note, mincounts=mincounts, maxrerr=maxrerr, tsmo=tsmo, $
                  sundir=sundir, wscale=wscale, cscale=cscale, fscale=fscale, $
                  result=result, vdis=vdis, padmap=padmap, sec=sec, sconfig=sconfig, $
                  color_table=color_table, reverse_color_table=reverse_color_table, $
                  line_colors=line_colors, pyrange=pyrange, qlevel=qlevel, _extra=_extra,$
                  mkpng=mkpng,figname=figname

  @mvn_swe_com
  @putwin_common

  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  cols = get_colors()
  cbot = cols.bottom_c
  ctop = cols.top_c

  tiny = 1.e-31
  badpad = swe_pad_struct
  badpad.quality = 255B

  if (size(windex,/type) eq 0) then win, config=0  ; win acts like window

; Load any keyword defaults

  swe_snap_options, get=key, /silent
  ktag = tag_names(key)
  tlist = ['KEEPWINS','KILLWINS','ARCHIVE','ENERGY','UNITS','DDD','ZRANGE', $
           'SUM','LABEL','SMO','DIR','MASK_SC','ABINS','DBINS','OBINS','BURST', $
           'POT','SCP','SPEC','PLOTLIMS','NORM','CENTER','PEP','RESAMPLE', $
           'HIRES','FBDATA','MONITOR','ADIABATIC','NOMID','UNCERTAINTY', $
           'NOSPEC90','SHIFTPOT','POPEN','INDSPEC','TWOPOT','XRANGE',$
           'ERROR_BARS','YRANGE','TRANGE2','NOTE','MINCOUNTS','MAXRERR', $
           'TSMO','SUNDIR','WSCALE','CSCALE','FSCALE','RESULT','VDIS', $
           'PADMAP','COLOR_TABLE','REVERSE_COLOR_TABLE','LINE_COLORS', $
           'PYRANGE','QLEVEL','SCONFIG']
  for j=0,(n_elements(ktag)-1) do begin
    i = strmatch(tlist, ktag[j]+'*', /fold)
    case (total(i)) of
        0  : ; keyword not recognized -> do nothing
        1  : begin
               kname = (tlist[where(i eq 1)])[0]
               ok = execute('kset = size(' + kname + ',/type) gt 0',0,1)
               if (not kset) then ok = execute(kname + ' = key.(j)',0,1)
             end
      else : print, "Keyword ambiguous: ", ktag[j]
    endcase
  endfor

; Process keywords

  if (size(note,/type) ne 7) then note = ''
  aflg = keyword_set(archive)
  if keyword_set(burst) then aflg = 1
  if (size(units,/type) ne 7) then units = 'eflux'
  sflg = keyword_set(energy)
  killwins = keyword_set(killwins)
  kflg = ~keyword_set(keepwins) or killwins
  if not keyword_set(zrange) then zrange = 0
  dflg = keyword_set(ddd)
  rflg = keyword_set(resample)
  if not keyword_set(wscale) then wscale = 1.
  if not keyword_set(cscale) then cscale = wscale
  if not keyword_set(fscale) then fscale = 1.
  if (n_elements(xrange) ge 2) then begin
    xrange = minmax(xrange)
    xflg = 1
  endif else xflg = 0
  pyrange = keyword_set(pyrange) ? minmax(pyrange) : [0.1, 10.]
  padmap = keyword_set(padmap)
  qlevel = (n_elements(qlevel) gt 0L) ? byte(qlevel[0]) : 0B

  case n_elements(trange2) of
       0 : tflg = 0
       1 : begin
             trange2 = time_double(trange2)
             tflg = 1
             if (~killwins) then kflg = 0
           end
    else : begin
             trange2 = minmax(time_double(trange2))
             tflg = 1
             if (~killwins) then kflg = 0
           end
  endcase

  if keyword_set(hires) then hflg = 1 else hflg = 0
  if (size(fbdata, /type) eq 0) then fbdata = 'mvn_B_full'
  if keyword_set(adiabatic) then begin
    mflg = 1
    get_data, 'dBdRg', index=idbdr
    if (idbdr eq 0) then mvn_swe_eparam
  endif else mflg = 0
  if keyword_set(uncertainty) then begin
     uflg = 1
     rflg = 1
  endif else uflg = 0
  if (size(error_bars,/type) eq 0) then ebar = 1 else ebar = keyword_set(error_bars)
  if (size(mincounts,/type) eq 0) then mincounts = 10.
  if (size(maxrerr,/type) eq 0) then maxrerr = 100.  ; disable by default
  if (size(center,/type) eq 0) then center = 0
  if keyword_set(pep) then pflg = 1 else pflg = 0
  if keyword_set(sum) then begin
    npts = 2
    doall = 1
  endif else begin
    npts = 1
    doall = 0
  endelse
  if keyword_set(tsmo) then begin
    npts = 1
    doall = 1
    dosmo = 1
    dtsmo = double(tsmo)/2D
  endif else dosmo = 0
  if not keyword_set(smo) then smo = 1
  if keyword_set(norm) then nflg = 1 else nflg = 0
  if (size(pot,/type) eq 0) then dopot = 1 else dopot = keyword_set(pot)
  if (size(scp,/type) eq 0) then scp = !values.f_nan else scp = float(scp[0])
  if keyword_set(twopot) then shiftpot = 0
  if keyword_set(shiftpot) then begin
    if (size(swe_sc_pot,/type) ne 8) then begin
      print,"No spacecraft potential.  Cannot shift spectra."
      shiftpot = 0
    endif
  endif
  if keyword_set(shiftpot) then begin
    spflg = 1
    if (~xflg) then xrange = [1.,5000.]
  endif else begin
    spflg = 0
    if (~xflg) then xrange = [3.,5000.]
  endelse
  if keyword_set(label) then begin
    dolab = 1
    abin = string(indgen(16),format='(i2.2)')
    dbin = string(indgen(6),format='(i1)')
    obin = string(indgen(96),format='(i2.2)')
  endif else dolab = 0
  if keyword_set(plotlims) then plot_pa_lims = 1 else plot_pa_lims = 0
  if keyword_set(nomid) then domid = 0 else domid = 1

  if keyword_set(sundir) then begin
    t = [0D]
    the = [0.]
    phi = [0.]
    get_data,'Sun_MAVEN_SWEA_STOW',data=sun,index=i
    if (i gt 0) then begin
      t = [temporary(t), sun.x]
      xyz_to_polar, sun, theta=th, phi=ph, /ph_0_360
      the = [temporary(the), th.y]
      phi = [temporary(phi), ph.y]
    endif
    get_data,'Sun_MAVEN_SWEA',data=sun,index=i
    if (i gt 0) then begin
      t = [temporary(t), sun.x]
      xyz_to_polar, sun, theta=th, phi=ph, /ph_0_360
      the = [temporary(the), th.y]
      phi = [temporary(phi), ph.y]
    endif
    if (n_elements(t) gt 1) then begin
      sun = {time:t[1L:*], the:the[1L:*], phi:phi[1L:*]}
    endif else sundir = 0
  endif

  ctab = -1 & pct = -1 & crev = -1 & prev = -1 & lines = -1 & plines = -1
  if (n_elements(color_table) gt 0) then begin
    ctab = fix(color_table[0])
    crev = keyword_set(reverse_color_table)
    initct, ctab, previous_ct=pct, reverse=crev, previous_rev=prev
  endif
  if (n_elements(line_colors) gt 0) then begin
    lines = line_colors
    line_colors, lines, previous_lines=plines
  endif

; Field of view masking

  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then obins = reform(abins # dbins, 96)
  fovmask = byte(obins # [1B,1B])  ; same mask for both boom states

  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then fovmask *= swe_sc_mask

; Pitch angle resolved energy spectra

  if (size(spec,/type) ne 0) then begin
    dospec = 1
    swidth = (float(abs(spec)) > 30.)*!dtor
  endif else begin
    dospec = 0
    swidth = 30.*!dtor
  endelse
  
  if keyword_set(indspec) then doind=1 else doind=0
  if keyword_set(vdis) then begin
    dov = 1
    rflg = 1
  endif else dov = 0

  if (size(popen,/type) eq 7) then begin
      psflg = 1
      psname = popen[0]
      csize1 = 1.2
      csize2 = 1.0
  endif else begin
      psflg = 0
      csize1 = 1.2
      csize2 = 1.4
  endelse

  case n_elements(center) of
    0 : begin
          lon0 = 180.
          lat0 = 0.
        end
    1 : begin
          lon0 = center[0]
          lat0 = 0.
        end
    else : begin
             lon0 = center[0]
             lat0 = center[1]
           end
  endcase

  case strupcase(units) of
    'COUNTS' : drange = [1e0, 1e5]
    'RATE'   : drange = [1e1, 1e6]
    'CRATE'  : drange = [1e1, 1e6]
    'FLUX'   : drange = [1e1, 3e8]
    'EFLUX'  : drange = [1e4, 3e9]
    'E2FLUX' : drange = [1e6, 1e11]
    'DF'     : drange = [1e-18, 1e-8]
    else     : drange = [0,0]
  endcase
  
  if (n_elements(yrange) ge 2) then drange = minmax(yrange)
  
  case strupcase(units) of
    'COUNTS' : ytitle = 'Raw Counts'
    'RATE'   : ytitle = 'Raw Count Rate'
    'CRATE'  : ytitle = 'Count Rate'
    'EFLUX'  : ytitle = 'Energy Flux (eV/cm2-s-ster-eV)'
    'E2FLUX' : ytitle = 'Energy Flux (eV/cm2-s-ster)'
    'FLUX'   : ytitle = 'Flux (1/cm2-s-ster-eV)'
    'DF'     : ytitle = 'DF (cm!u-3!n (km/s)!u-3!n)'
    else     : ytitle = 'Unknown Units'
  endcase

  get_data,'alt',data=alt
  if (size(alt,/type) eq 8) then begin
    doalt = 1
    get_data,'sza',data=sza
    get_data,'lon',data=lon
    get_data,'lat',data=lat
    get_data,'sza',data=sza
  endif else doalt = 0

; Put up snapshot window(s)

  tplot_options, get_opt=topt
  str_element, topt, 'window', value=Twin, success=ok
  if (not ok) then Twin = !d.window
  wset, Twin

  undefine, mnum
  if (size(monitor,/type) gt 0) then begin
    if (~windex) then win, /config
    mnum = fix(monitor[0])
  endif else begin
    if (size(secondarymon,/type) gt 0) then mnum = secondarymon
  endelse

  if (rflg or hflg or uflg) then begin
    rflg = 1
    ysize = fix(300.*float(rflg+hflg+uflg))
    win, /free, monitor=mnum, xsize=800, ysize=ysize, dx=10, dy=10, scale=wscale  ; PAD (resampled)
    Pwin = !d.window
  endif

  if (~rflg) then begin
    win, /free, monitor=mnum, xsize=800, ysize=600, dx=10, dy=10, scale=wscale  ; PAD (as measured)
    Pwin = !d.window
  endif

  wdy = 0.
  if keyword_set(dir) then if (dir gt 1) then wdy = fix(0.125*450.)

  if (sflg) then begin
    win, /free, xsize=600, ysize=(450+wdy), rel=Pwin, dy=-10, scale=wscale ; PAD E-cut
    Nwin = !d.window
  endif

  if (dospec) then begin
    win, /free, xsize=400, ysize=600, rel=Pwin, dx=10, scale=wscale  ; PAD spec
    Ewin = !d.window
  endif

  if (dflg) then begin
    win, /free, monitor=mnum, xsize=500, ysize=700, dx=10, dy=-10, scale=wscale  ; 3D view
    Cwin = !d.window
  endif

  if (doind) then begin
    win, /free, monitor=mnum, xsize=800, ysize=600, dx=-10, dy=10, scale=wscale  ; Espec for each pad bin
    Iwin = !d.window
  endif

  if (dov) then begin
    win, /free, monitor=mnum, xsize=1200, ysize=300, dx=-10, dy=-10, scale=wscale  ; velocity dist.
    Vwin = !d.window
  endif

  if (padmap) then begin
    win, /free, monitor=mnum, xsize=600, ysize=450, dx=-10, dy=-10, scale=wscale  ; PA map
    Mwin = !d.window
  endif

; Set plot options

  limits = {no_interp:1, xlog:1, xrange:xrange, xstyle:1, xtitle:'Energy (eV)', $
            yrange:[0,180], ystyle:1, yticks:6, yminor:3, ytitle:'Pitch Angle (deg)', $
            zlog:1, ztitle:strupcase(units), xmargin:[15,15], charsize:1.4*cscale}

  if keyword_set(zrange) then begin
    str_element, limits, 'zrange', zrange, /add
    fixz = 1
  endif else fixz = 0

; Calculate PAD timing

  ptime2 = [0D]
  plut2 = [5B]
  ptime3 = [0D]
  plut3 = [5B]

  if (size(mvn_swe_pad,/type) eq 8) then begin
    ptime2 = mvn_swe_pad.time
    plut2 = replicate(5B, n_elements(ptime2))
  endif else begin
    if (size(a2,/type) eq 8) then begin
      ptime2 = a2.time + 1.95D/2D  ; center times
      plut2 = a2.lut
    endif
  endelse

  if (size(swe_fpad,/type) eq 8) then begin
    if (n_elements(ptime2) gt 1L) then begin
      ptime2 = [ptime2, swe_fpad.time]
      plut2 = [plut2, swe_fpad.lut]
      indx = sort(ptime2)
      ptime2 = ptime2[indx]
      plut2 = plut2[indx]
    endif else begin
      ptime2 = swe_fpad.time
      plut2 = swe_fpad.lut
    endelse
  endif

  if (size(mvn_swe_pad_arc,/type) eq 8) then begin
    ptime3 = mvn_swe_pad_arc.time
    plut3 = replicate(5B, n_elements(ptime3))
  endif else begin
    if (size(a3,/type) eq 8)  then begin
      ptime3 = a3.time + 1.95D/2D  ; center times
      plut3 = a3.lut
    endif
  endelse

  if (size(swe_fpad_arc,/type) eq 8) then begin
    if (n_elements(ptime3) gt 1L) then begin
      ptime3 = [ptime3, swe_fpad_arc.time]
      plut3 = [plut3, swe_fpad_arc.lut]
      indx = sort(ptime3)
      ptime3 = ptime3[indx]
      plut3 = plut3[indx]
    endif else begin
      ptime3 = swe_fpad_arc.time
      plut3 = swe_fpad_arc.lut
    endelse
  endif

; Select the first time, then get the PAD spectrum closest that time

  print,'Use button 1 to select time; button 3 to quit.'
     
  wset,Twin
  if (~tflg) then begin
    ctime,trange,npoints=npts,/silent
    if (npts gt 1) then cursor,cx,cy,/norm,/up  ; Make sure mouse button released
  endif else trange = trange2
  pdflg = 1

  if (size(trange,/type) eq 2) then begin          ; Abort before first time select.
    if (~rflg) then wdelete,Pwin                   ; Don't keep empty windows.
    if (sflg) then wdelete,Nwin
    if (dospec) then wdelete,Ewin
    if (rflg or hflg or uflg) then wdelete,Pwin
    if (padmap) then wdelete,Mwin
    wset,Twin
    if ((ctab ne pct) or (crev ne prev)) then initct, pct, reverse=prev
    if (max(abs(lines - plines)) gt 0) then line_colors, plines
    return
  endif

  if keyword_set(dir) then begin
    get_data,'mvn_B_1sec',index=i
    if (i eq 0) then mvn_mag_load

    get_data,'mvn_B_1sec_iau_mars',data=mag_pc,index=i
    if (i eq 0) then begin
      mvn_mag_geom
      get_data,'mvn_B_1sec_iau_mars',data=mag_pc,index=i
      if (i eq 0) then print,"Can't get MAG data!"
    endif

    get_data,'mvn_B_1sec_maven_mso',data=mag_ss,index=j
    if ((i eq 0) or (j eq 0)) then dir = 0
  endif

  ok = 1
  
  nplot = 0
  
  while (ok) do begin
    result = {units:units}

    if (dosmo) then begin
      tmin = min(trange, max=tmax)
      trange = [(tmin - dtsmo), (tmax + dtsmo)]
    endif

    if (psflg) then popen, psname + string(nplot,format='("_",i2.2)'),/landscape

; Put up a PAD spectrogram
 
    if (pdflg) then begin
       if (n_elements(trange) gt 1) then begin
         tmin = min(trange, max=tmax)
         if (aflg) then begin
           indx = where((ptime3 ge tmin) and (ptime3 le tmax), count)
           if (max(plut3[indx]) gt 6B) then dwell = 1 else dwell = 0
         endif else begin
           indx = where((ptime2 ge tmin) and (ptime2 le tmax), count)
           if (max(plut2[indx]) gt 6B) then dwell = 1 else dwell = 0
         endelse
       endif else begin
         if (aflg) then begin
           indx = nn2(ptime3, trange)
           if (plut3[indx] gt 6B) then dwell = 1 else dwell = 0
         endif else begin
           indx = nn2(ptime2, trange)
           if (plut2[indx] gt 6B) then dwell = 1 else dwell = 0
         endelse
       endelse

       if (dwell) then begin
         if (n_elements(trange) gt 1L) then begin
           tmin = min(trange, max=tmax)
           if (aflg) then begin
             indx = where((swe_fpad_arc.time ge tmin) and (swe_fpad_arc.time le tmax), cnt)
             pad = mvn_swe_padsum(swe_fpad_arc[indx])
           endif else begin
             indx = where((swe_fpad.time ge tmin) and (swe_fpad.time le tmax), cnt)
             pad = mvn_swe_padsum(swe_fpad[indx])
           endelse
         endif else begin
           if (aflg) then begin
             indx = nn2(swe_fpad_arc.time, trange)
             pad = swe_fpad_arc[indx]
           endif else begin
             indx = nn2(swe_fpad.time, trange)
             pad = swe_fpad[indx]
           endelse
         endelse
         hflg = 0
         n_e = 1
         tprec = 3
       endif else begin
         dt = max(trange) - min(trange)
         if (dt lt 4D) then trange = mean(trange)
         pad = mvn_swe_getpad(trange,archive=aflg,all=doall,/sum,units=units,qlevel=qlevel)
         if (size(pad,/type) ne 8) then begin
           pad = badpad
           pad.time = mean(trange)
           pad.end_time = max(trange)
           hflg = 0
         endif
         if (hflg) then pad = mvn_swe_padmap_32hz(pad, fbdata=fbdata, /verbose, maglev=maglev)
         n_e = 64
         tprec = 0
       endelse
    endif

    if (size(pad,/type) eq 8) then begin

      delta_t = pad.end_time - pad.time
      str_element, pad, 'trange', [(pad.time - delta_t), pad.end_time], /add

      pmask = replicate(1.,n_e,16)
      counts = pad
      mvn_swe_convert_units, counts, 'counts'
      indx = where(counts.data lt mincounts, count)
      if (count gt 0L) then pmask[indx] = !values.f_nan

      if keyword_set(dir) then begin
        dt = min(abs(mag_ss.x - pad.time),i)
        B_mso = reform(mag_ss.y[i,*])

        dt = min(abs(mag_pc.x - pad.time),i)
        B_geo = reform(mag_pc.y[i,*])
        B_azim  = mag_pc.azim[i]
        B_elev  = mag_pc.elev[i]
      endif

      if (size(swe_sc_pot, /type) eq 8) then begin
          pot = swe_sc_pot[nn(swe_sc_pot.time, pad.time)].potential
          if (~finite(pot)) then pot = 0.
      endif else pot = 0.
      if (finite(scp)) then pot = scp  ; override with user-supplied value
      pad.sc_pot = pot

      str_element, result, 'scpot', pot, /add

; Correct for spacecraft potential.  For instrumental units (COUNTS, RATE, or
; CRATE) only shift in energy.  For flux units (FLUX, EFLUX), shift in energy 
; and correct the signal level to ensure conservation of phase space density.

      if (spflg) then begin
        if (stregex(units,'flux',/boo,/fold)) then begin
          mvn_swe_convert_units, pad, 'df'
          pad.energy -= pot
          mvn_swe_convert_units, pad, units
        endif else pad.energy -= pot
      endif

      case strupcase(pad.units_name) of
        'COUNTS' : zlo = 1
        'RATE'   : zlo = 1
        'CRATE'  : zlo = 1
        'FLUX'   : zlo = 1
        'EFLUX'  : zlo = 1e3
        'DF'     : zlo = 1e-18
        else     : zlo = 1
      endcase

      delta_t = pad.end_time - pad.time
      if (delta_t gt 1D) then begin
        tstart = time_string(pad.time - delta_t, prec=tprec)
        tend   = time_string(pad.end_time, prec=tprec)
        tstring = tstart + ' - ' + strmid(tend,11)
      endif else tstring = time_string(pad.time, prec=tprec)
      title = strtrim(string(tstring) + '   ' + note)
      str_element,limits,'title',title,/add
      
      if (pad.time gt t_mtx[2]) then boom = 1 else boom = 0
      indx = where(fovmask[pad.k3d,boom] eq 0B, count)
      if (count gt 0L) then pad.data[*,indx] = !values.f_nan

; Remove secondaries

      if ~keyword_set(sec) then begin
        pad.bkg = 0.
        pad.valid = 1B
      endif else mvn_swe_secondary, pad, config=sconfig

      x = pad.energy[*,0]
      y = pad.pa*!radeg
      ylo = pad.pa_min*!radeg
      yhi = pad.pa_max*!radeg
      z = (pad.data - pad.bkg)
      indx = where(~pad.valid, count)
      if (count gt 0L) then z[indx] = !values.f_nan
      z = smooth(z*pmask,[smo,1],/nan)/fscale
      v = pad.var

      if (sflg) then begin
        case n_elements(energy) of
            0  : ; this is impossible
            1  : begin
                   de = min(abs(energy - x),i)
                   penergy = x[i]
                 end
          else : begin
                   erange = minmax(energy)
                   i = where((x ge erange[0]) and (x le erange[1]), count)
                   penergy = x[i]
                 end
        endcase
      endif
      
      if (nflg) then begin
        zmean = average(z,2,/nan) # replicate(1.,16)
        z /= (zmean > 1.)
      endif

; Add extra elements to force specplot to show the full pitch angle range

      y1 = fltarr(n_e,10)
      ylo1 = y1
      yhi1 = y1
      z1 = y1
      y2 = y1
      ylo2 = y1
      yhi2 = y1
      z2 = y1

      for i=0,(n_e-1) do begin
        indx = sort(reform(y[i,0:7]))
        y1[i,1:8] = y[i,indx]
        z1[i,1:8] = z[i,indx]
        ylo1[i,1:8] = ylo[i,indx]
        yhi1[i,1:8] = yhi[i,indx]
        jndx = sort(reform(y[i,8:15])) + 8
        y2[i,1:8] = y[i,jndx]
        z2[i,1:8] = z[i,jndx]
        ylo2[i,1:8] = ylo[i,jndx]
        yhi2[i,1:8] = yhi[i,jndx]
      endfor
      y1[*,0] = ylo1[*,1]
      y1[*,9] = yhi1[*,8]
      z1[*,0] = z1[*,1]
      z1[*,9] = z1[*,8]

      y2[*,0] = ylo2[*,1]
      y2[*,9] = yhi2[*,8]
      z2[*,0] = z2[*,1]
      z2[*,9] = z2[*,8]

      str_element,limits,'zrange',success=gotz
      if (not gotz) then begin
;        zmin = min(z, /nan) > zlo
;        zmax = max(z, /nan) > (10.*zmin)
        zmin = drange[0]
        zmax = drange[1]
        if (nflg) then begin
          zmin = 0.3
          zmax = 3.0
          str_element,limits,'zlog',1,/add
          str_element,limits,'ztitle','NORM',/add
          str_element,limits,'zticks',2,/add
          str_element,limits,'ztickname',['0.3','1.0','3.0'],/add
        endif
        str_element,limits,'zrange',[zmin,zmax],/add
      endif

      if (~rflg and ~psflg) then begin
        wset, Pwin
        !p.multi = [0,1,2]
        specplot,x,y1,z1,limits=limits
        str_element, result, 'pad_1', {x:x, y:y1, z:z1}, /add
        if (dopot) then begin
          if (spflg) then oplot,[-pot,-pot],[0,180],line=2,color=6 $
                     else oplot,[pot,pot],[0,180],line=2
        endif
        if (plot_pa_lims) then begin
          oplot,[3,5000],[ylo1[(n_e-1),1],ylo1[(n_e-1),1]],line=2
          oplot,[3,5000],[yhi1[(n_e-1),8],yhi1[(n_e-1),8]],line=2
        endif
        if (sflg) then for k=0,(n_elements(penergy)-1) do oplot,[penergy[k],penergy[k]],[0,180],line=2
        if (pad.quality eq 255B) then xyouts,0.5,0.5,"NO VALID DATA",/norm,align=0.5,charsize=csize2*1.5

        limits.title = ''
        specplot,x,y2,z2,limits=limits
        str_element, result, 'pad_2', {x:x, y:y2, z:z2}, /add
        if (dopot) then begin
          if (spflg) then oplot,[-pot,-pot],[0,180],line=2,color=6 $
                     else oplot,[pot,pot],[0,180],line=2
        endif
        if (plot_pa_lims) then begin
          oplot,[3,5000],[ylo2[(n_e-1),1],ylo2[(n_e-1),1]],line=2
          oplot,[3,5000],[yhi2[(n_e-1),8],yhi2[(n_e-1),8]],line=2
        endif
        if (sflg) then for k=0,(n_elements(penergy)-1) do oplot,[penergy[k],penergy[k]],[0,180],line=2
        !p.multi = 0
      endif

      if (rflg or hflg or uflg) then begin
         if (~psflg) then wset, Pwin
         if (rflg + hflg + uflg) gt 1 then !p.multi = [0, 1, rflg+hflg+uflg]
         if (rflg) then begin
            rlim = limits
            if (rflg + hflg + uflg) eq 3 then begin
               ymargin = !y.margin
               str_element, rlim, 'charsize', rlim.charsize * 1.5 * cscale, /add_replace
               str_element, rlim, 'xmargin', rlim.xmargin / (1.5*cscale), /add_replace
               !y.margin /= 1.5
            endif 
            rtime = minmax(trange)
            if rtime[0] eq rtime[1] then rtime = rtime[0]
            mvn_swe_pad_resample, rtime, snap=0, tplot=0, result=rpad, silent=3, hires=hflg, $
                                  fbdata=fbdata, sc_pot=spflg, archive=aflg, mbins=fovmask[*,boom]

            if (size(rpad,/type) ne 8) then begin
              rpad = {time  : 0.d0                           , $
                      xax   : findgen(128)*(180./127.)       , $
                      index : replicate(!values.f_nan,1,128) , $
                      avg   : replicate(!values.f_nan,1,128) , $
                      std   : replicate(!values.f_nan,1,128) , $
                      nbins : replicate(!values.f_nan,1,128)    }

              arpad = rpad.avg
              urpad = rpad.std
              rerr = arpad
              respad = arpad
            endif else begin
              arpad = rpad.avg
              if size(arpad, /n_dimension) eq 3 then arpad = average(arpad, 3,/nan)

              urpad = rpad.std
              if size(urpad, /n_dimension) eq 3 then urpad = average(urpad, 3,/nan)
              rerr = urpad/arpad
         
              bad = where(rerr gt maxrerr, count)
              if (count gt 0L) then arpad[bad] = !values.f_nan
              respad=arpad

              if (nflg) then arpad /= rebin(average(arpad, 2, /nan), n_elements(arpad[*, 0]), n_elements(arpad[0, *]), /sample)
            endelse

            str_element, rlim, 'title', rtitle, success=aok
            if (not aok) then begin
              str_element, rlim, 'title', strtrim(time_string(mean(rpad.time)) + ' (Resampled)' + $
                                                  '   ' + note), /add_replace
            endif else str_element, rlim, 'title', rtitle + ' (Resampled)', /add_replace
            specplot, average(pad.energy, 2), rpad[0].xax, arpad, lim=rlim
            str_element, result, 'pad_resample', {x:average(pad.energy, 2), y:rpad[0].xax, z:arpad}, /add

            if (dopot) then begin
              if (spflg) then oplot,[-pot,-pot],[0,180],line=2,color=6 $
                         else oplot,[pot,pot],[0,180],line=2
            endif

            if (plot_pa_lims) then begin
              oplot,[3,5000],[ylo2[63,1],ylo2[63,1]],line=2
              oplot,[3,5000],[yhi2[63,8],yhi2[63,8]],line=2
            endif
            if (sflg) then for k=0,(n_elements(penergy)-1) do oplot,[penergy[k],penergy[k]],[0,180],line=2
            str_element, pad, 'quality', pq, success=gotq
            if (gotq) then if (pq eq 255B) then xyouts,0.5,0.5,"NO VALID DATA",/norm,align=0.5,charsize=csize2*1.5

            if (uflg) then begin
               str_element, rlim, 'ztitle', 'Relative Uncertainty', /add_replace
               str_element, rlim, 'zrange', [1.d-2, 1.], /add_replace
               str_element, rlim, 'title', 'Resampled PAD Relative Uncertainty', /add_replace
               specplot, average(pad.energy, 2), rpad[0].xax, rerr, lim=rlim
               str_element, result, 'pad_resample_rerr', {x:average(pad.energy, 2), y:rpad[0].xax, z:rerr}, /add
               if (dopot) then begin
                 if (spflg) then oplot,[-pot,-pot],[0,180],line=2,color=6 $
                            else oplot,[pot,pot],[0,180],line=2
               endif
            endif

             if (dov) then begin
                if (~psflg) then wset, vwin
                ven = average(pad.energy, 2,/nan)
                ine = where(ven gt 0)
                ven = ven[ine]
                ;ven = pad.energy[*,0]
                eexam = [pot,30.,50.,100.] ; eV
                emass = 9.1e-31
                vtot = (sqrt(ven*1.6e-19*2./emass) * 1.e-3) ; km/s
                vexam = (sqrt(eexam*1.6e-19*2./emass) * 1.e-3) ; km/s
                vpa = rpad[0].xax
                vc = 2.99792458D5                  ; velocity of light [km/s]
                vmass = (5.10998910D5)/(vc*vc)     ; electron rest mass [eV/(km/s)^2]
                m_conv = 2D5/(vmass*vmass)         ; mass conversion factor (flux to distribution function)
                scale = (1.d/(ven^2 * m_conv)) # replicate(1.,128)
                vphase = alog10(respad[ine,*] * scale) ; log phase space density [1/cm3-(km/s)3]
                ;print,minmax(respad),minmax(vphase)
                ;vphase = transpose(alog10(pad.data * scale))
                indx=where(finite(vphase) eq 0,cts)
                vphase[indx] = !values.d_nan
                mima = minmax(vphase)
                mima[1] = -10
                mima[0]=mima[1]-5;6
                !p.multi=[0,3,1,0,0]
                vpara=vtot#cos(vpa*!dtor)
                vper=vtot#sin(vpa*!dtor)
                nlv = 15.

                str_element, result, 'vdf', {vphase:vphase,vpara:vpara,vper:vper}, /add
                
                cs3 = csize2*2.
                xmar = [10,3] + 3
                ymar = [4,2] + 3

;               DF vs. Vpara and Vperp

                contour,vphase,vpara,vper,$;,/IRREGULAR
                    xtit='V!d||!n (km/s)',ytit='V!d!9x!1H!n (km/s)',cell_fill=1,$
                    levels=(mima[1]-mima[0])/(nlv-1)*findgen(nlv)+mima[0],$
                    c_colors=findgen(nlv)*(ctop-cbot)/(nlv-1)+cbot,xrange=[-1e4,1e4],$
                    yrange=[0,1e4],nlevels=nlv,isotropic=1,charsize=cs3,$
                    xmargin=xmar,ymargin=ymar,title=tstring ;,c_spacing=0.5

                vcon=(sqrt([10.,50.,100.,250.]*1.6e-19*2./emass) * 1.e-3)
                cost = cos(findgen(181)*!dtor)
                sint = sin(findgen(181)*!dtor)
                for i=0,3 do oplot,vcon[i]*cost,vcon[i]*sint,linestyle=1
                draw_color_scale,range=[mima[0],mima[1]],brange=[cbot,ctop],charsize=cs3

;               DF vs. Pitch Angle

                ien=15+indgen(10)*3
                nen=n_elements(ien)
                yran = minmax(vphase[ien,*])
                xmsg = 182.
                ymsg = yran[0] + findgen(nen)*((yran[1] - yran[0])/float(nen))
                cran = [32., float(ctop)]
                lcol = round(cran[0] + findgen(nen)*((cran[1] - cran[0])/float(nen)))
                plot,vpa,vphase[ien[0],*],xtit='Pitch Angle (deg)',ytit='DF',xrange=[0,180],xstyle=1,$
                    yrange=yran,charsize=cs3,xmargin=xmar,ymargin=ymar,xticks=6,xminor=3
                ie=0
                while (ie le nen-1) and (ie le n_elements(ven)-1) do begin
                    oplot,vpa,vphase[ien[ie],*],color=lcol[ie]
                    xyouts,xmsg,ymsg[ie],string(sigfig(ven[ien[ie]],2),'(I4)')+' eV',/data,charsize=csize2,$
                           color=lcol[ie]
                    ie++
                endwhile
                oplot,[90.,90.],!y.crange,line=1

;               DF vs. Vpara and Vperp separately

                vnbin=10
                plot,vpara[*,0],vphase[*,64],xtit='V (km/s)',ytit='DF',$
                     ylog=0,xrange=[-1.e4,1.e4],/nodata,yrange=[mima[0],mima[1]+1],charsize=cs3,$
                     xmargin=xmar,ymargin=ymar,title='V!d||!n (solid)      V!d!9x!1H!n (dashed)'
                oplot,average(vpara[*,0:vnbin-1],2),average(vphase[*,0:vnbin-1],2,/nan)
                oplot,average(vper[*,63-vnbin/2-1:63],2),average(vphase[*,63-vnbin/2-1:63],2,/nan),$
                      linestyle=2,color=6
                oplot,average(vpara[*,127-vnbin+1:127],2,/nan),average(vphase[*,127-vnbin+1:127],2,/nan)
                oplot,-average(vper[*,64:64+vnbin/2-1],2,/nan),average(vphase[*,64:64+vnbin/2-1],2,/nan),$
                      linestyle=2,color=6

                if (0) then begin
                  phi=0;75.
                  Enp=ven;*1.6e-19
                  nmb=8
                  kTmb=25.; * 1.38e-23/8.613e-5 ;J
                  vmb=sqrt((ven+80.)*1.6e-19*2/emass)*1.e-3 ;km/s
                  fmb = 1.e-10*0.5*exp(-(Enp-phi)/kTmb)
                  pmb = alog10(fmb)

                  oplot,vmb,pmb,linestyle=2,color=6
                  oplot,-vmb,pmb,linestyle=2,color=6
                  print,minmax(vtot),minmax(pmb)
                endif

                nexam = n_elements(vexam)
                xmsg = vexam + 1.e2
                ymsg = !y.crange[0] + 0.9*(!y.crange[1] - !y.crange[0])
                msg = strtrim(string(round(eexam)),2)
                msg[0] = strtrim(string(pot,format='(f6.1)'),2)
                msg[nexam-1] += ' eV'
                
                for i=0,(nexam-1) do begin
                   oplot,[vexam[i],vexam[i]],!y.crange,linestyle=1,color=5
                   oplot,[-vexam[i],-vexam[i]],!y.crange,linestyle=1,color=5
                   xyouts,xmsg[i],ymsg,msg[i],/data,charsize=csize2*0.8,color=5
                endfor
                !p.multi=0
            endif
 
         endif 
         if (hflg) then begin
            if tag_exist(pad, 'ftime') then begin
               ftime = pad.ftime - time_double(time_string(pad.ftime[0], tformat='YYYY-MM-DD/hh:mm'))
               if (mflg) then begin
                  get_data, 'dBdRg', data=dbdr, index=idbdr
                  if (idbdr ne 0) then begin
                     idx = where(dbdr.x ge pad.time and dbdr.x le pad.end_time, nidx)
                     if nidx gt 0 then begin
                        edbdr = dbdr.v
                        dbdr = average(dbdr.y[idx, *], 1)
                        fdbdr = strarr(3)
                        jdx = where(floor(alog10(dbdr)) ge 0, njdx, complement=kdx, ncomplement=nkdx)
                        if njdx gt 0 then fdbdr[jdx] = '(f0.1)'
                        if nkdx gt 0 then fdbdr[kdx] = '(f0.' + string(abs(floor(alog10(dbdr[kdx]))) + 1, '(i0)') + ')'
                        htit = 'dB/dRg = ' + string(dbdr[0], fdbdr[0]) + ' (' + string(edbdr[0], '(i0)') + ' eV), ' + $
                               string(dbdr[1], fdbdr[1]) + ' (' + string(edbdr[1], '(i0)') + ' eV), ' + $
                               string(dbdr[2], fdbdr[2]) + ' (' + string(edbdr[2], '(i0)') + ' eV)'
                        undefine, jdx, njdx, kdx, nkdx
                        undefine, edbdr, fdbdr
                     endif else htit = ''
                     undefine, idx, nidx
                  endif else htit = ''
                  undefine, dbdr, idbdr
               endif else htit = ''
               box, {xrange: minmax(ftime), xstyle: 1, yrange: [0., 360.], yticks: 4, yminor: 3, ystyle: 9, $
                     xtitle: 'Time (UT) Seconds after ' + time_string(pad.ftime[0], tformat='YYYY-MM-DD/hh:mm'), ytitle: 'Baz (deg)', $
                     charsize: (0.7 * (rflg + uflg + hflg))*cscale > 1.4, xmargin: [15, 15] / ((rflg + uflg + hflg)/2. > 1.)}
               ;oplot, minmax(ftime), [180., 180.], lines=1
               oplot, minmax(ftime), replicate(pad.baz*!radeg, 2), lines=1
               oplot, minmax(ftime), replicate(2.*pad.bel*!radeg + 180., 2), color=6, lines=1
               oplot, ftime, pad.fbaz*!radeg, psym=1
               oplot, ftime, 2. * pad.fbel*!radeg + 180., psym=1, color=6
               axis, /yaxis, yrange=[-90., 90.], color=6, ytitle='Bel (deg)', yticks=4, yminor=3, /ystyle, charsize=((0.7 * (rflg + uflg + hflg))*cscale > 1.4)
               ;axis, /xaxis, charsize=1.4, xrange=reverse(minmax(pad.energy)), xtitle='Energy [eV]', /xstyle, /xlog
               xyouts, mean(!x.window), mean([!y.window[1], !y.region[1]]), htit, align=.5, charsize=1.4*cscale, /normal
            endif 
         endif 
         if (rflg + hflg + uflg) ge 2 then !p.multi = 0
         if size(ymargin, /type) ne 0 then begin
            !y.margin = ymargin
            undefine, ymargin
         endif 
      endif

      if (sflg) then begin
        x = pad.energy[*,0]
        y = pad.pa*!radeg
        z = (pad.data - pad.bkg)/fscale
        indx = where(~pad.valid, count)
        if (count gt 0L) then z[indx] = !values.f_nan
        dz = sqrt(pad.var)/fscale
        pcol = !p.color

        if (~psflg) then wset, Nwin
        de = min(abs(energy - x),i)
        penergy = x[i]
        ylo = reform(pad.pa_min[i,*])*!radeg
        yhi = reform(pad.pa_max[i,*])*!radeg
        zmean = mean(z[i,*],/nan)
        zi = z[i,*]/zmean
        dzi = dz[i,*]/zmean

        pad_cut = {x      : reform(y[i,*])    , $
                   dx     : abs(yhi - ylo)/2. , $
                   y      : reform(zi)        , $
                   dy     : reform(dzi)       , $
                   time   : tstring           , $
                   energy : penergy           , $
                   units  : 'normalized'         }

        str_element, result, 'pad_cut', pad_cut, /add

        col = [replicate(2,8), replicate(6,8)]
;       col = replicate(!p.color,16)

        plot_io,[-1.],[0.1],psym=3,xtitle='Pitch Angle (deg)',ytitle='Normalized', $
                yrange=pyrange,ystyle=1,xrange=[0,180],xstyle=1,xticks=6,xminor=3, $
                title=strtrim(string(tstring, penergy, note, format='(a,5x,f6.1," eV   ",a)')), $
                charsize=1.4*cscale, pos=[0.140005, 0.124449 - (wdy/4000.), 0.958005, 0.937783 - (wdy/525.)]

        for j=0,15 do oplot,[ylo[j],yhi[j]],[zi[j],zi[j]],color=col[j]
        for j=0,7 do begin   ; anodes 0-7
          oplot,[y[i,j]],[zi[j]],color=col[0]
          if (ebar) then errplot,y[i,j],(zi[j]-dzi[j])>tiny,zi[j]+dzi[j],color=col[0],width=0
          oplot,[y[i,j]],[zi[j]],psym=4
        endfor
        for j=8,15 do begin  ; anodes 8-15
          oplot,[y[i,j]],[zi[j]],color=col[8]
          if (ebar) then errplot,y[i,j],(zi[j]-dzi[j])>tiny,zi[j]+dzi[j],color=col[8],width=0
          oplot,[y[i,j]],[zi[j]],psym=4
        endfor

        if (dolab) then begin
          if (label gt 1) then begin
            olab = obin[pad.k3d]
            for j=0,7  do xyouts,(ylo[j]+yhi[j])/2.,8.,olab[j],color=col[0],align=0.5
            for j=8,15 do xyouts,(ylo[j]+yhi[j])/2.,0.13,olab[j],color=col[8],align=0.5
          endif else begin
            alab = abin[pad.iaz]
            dlab = dbin[pad.jel]
            for j=0,7  do xyouts,(ylo[j]+yhi[j])/2.,8.,alab[j],color=col[0],align=0.5
            for j=0,7  do xyouts,(ylo[j]+yhi[j])/2.,7.,dlab[j],color=col[0],align=0.5

            for j=8,15 do xyouts,(ylo[j]+yhi[j])/2.,0.15,alab[j],color=col[8],align=0.5
            for j=8,15 do xyouts,(ylo[j]+yhi[j])/2.,0.13,dlab[j],color=col[8],align=0.5
          endelse
        endif

        IF keyword_set(dir) THEN BEGIN
          ; print,B_mso[0],B_elev
        
          oplot,[90.,90.],pyrange,line=2
          my = 10.^(0.9375*(alog10(pyrange[1]) - alog10(pyrange[0])) + alog10(pyrange[0]))
          dirname = replicate('',4)
           
          IF (B_mso[0] GT 0.) THEN dirname[0] = 'SUN' ELSE dirname[0] = 'TAIL'
          IF (B_elev GT 0.)   THEN dirname[1] = 'UP'  ELSE dirname[1] = 'DOWN'
          IF (B_mso[0] LT 0.) THEN dirname[2] = 'SUN' ELSE dirname[2] = 'TAIL'
          IF (B_elev LT 0.)   THEN dirname[3] = 'UP'  ELSE dirname[3] = 'DOWN'

          bperp = [B_mso[1], B_mso[2], -B_geo[0], -B_geo[1]]
          FOR j=0, 3 DO $
            IF bperp[j] GT 0. THEN append_array, dircol, 6 ELSE append_array, dircol, 2
          FOR j=0, 3 DO $
            XYOUTS, 17.5+45.*j, my, dirname[j], color=!p.color, charsize=1.3*cscale, /data

          if (dir gt 1) then begin
            PLOT, [-1., 1.], [-1., 1.], /nodata, pos=[0.285892, 0.874722, 0.39075, 1.], $
                   /noerase, yticks=1, xticks=1, xminor=1, yminor=1, xstyle=5, ystyle=5
            OPLOT, 0.9*COS(FINDGEN(361)*!DTOR), 0.9*SIN(FINDGEN(361)*!DTOR)
            angle = ATAN(B_mso[2], B_mso[1])
            IF B_mso[0] GT 0. THEN dircol = 6 ELSE dircol = 2
            ARROW, 0., 0., 0.7*COS(angle), 0.7*SIN(angle), /data, color=dircol
            XYOUTS, 0., -1.3, 'MSO', /data, alignment=0.5
            XYOUTS, 0., 0.5, 'Z', /data, alignment=0.5
            XYOUTS, 0.6, 0., 'Y', /data, alignment=0.5

            PLOT, [-1., 1.], [-1., 1.], /nodata, pos=[0.708061, 0.874722, 0.812919, 1.], $
                   /noerase, yticks=1, xticks=1, xminor=1, yminor=1, xstyle=5, ystyle=5
            OPLOT, 0.9*COS(FINDGEN(361)*!DTOR), 0.9*SIN(FINDGEN(361)*!DTOR)
            angle = ATAN(-B_geo[1], -B_geo[0])
            IF -B_geo[2] GT 0. THEN dircol = 6 ELSE dircol = 2
            ARROW, 0., 0., 0.7*COS(angle), 0.7*SIN(angle), /data, color=dircol
            XYOUTS, 0., -1.3, 'GEO', /data, alignment=0.5
            XYOUTS, 0., 0.5, 'N', /data, alignment=0.5
            XYOUTS, 0.6, 0., 'E', /data, alignment=0.5
          endif
        ENDIF

        if (dflg and ~dwell) then begin
          ddd = mvn_swe_get3d(trange,archive=aflg,all=doall,/sum,units=units)
          if (size(ddd,/type) eq 8) then begin
            initct, 34, previous_ct=pct2, previous_rev=prv2
            indx = where(fovmask[*,boom] eq 0B, count)
            if (count gt 0L) then ddd.data[*,indx] = !values.f_nan

            de = min(abs(ddd.energy[*,0] - energy),ebin)
            z3d = reform(ddd.data[ebin,pad.k3d])  ; 3D mapped into PAD
            z3d = z3d/mean(z3d,/nan)

            col = [replicate(5,8), replicate(4,8)]

            for j=0,15 do oplot,[ylo[j],yhi[j]],[z3d[j],z3d[j]],color=col[j],line=2

            if (~psflg) then wset, Cwin
            d_dat = replicate(!values.f_nan,96)
            d_dat[pad.k3d] = reform(z[i,*])       ; PAD mapped into 3D
            ddd.data[ebin+1,*] = d_dat            ; overwrite adjacent energy bin
            ddd.energy[ebin+1,*] = ddd.energy[ebin,*]
            ddd.magf[0] = cos(pad.Baz)*cos(pad.Bel)
            ddd.magf[1] = sin(pad.Baz)*cos(pad.Bel)
            ddd.magf[2] = sin(pad.Bel)
            plot3d_new,ddd,lat0,lon0,ebins=[ebin,ebin+1]

            lab=strcompress(indgen(ddd.nbins),/rem)
            xyouts,reform(ddd.phi[63,*]),reform(ddd.theta[63,*]),lab,align=0.5
            mvn_spc_fov_blockage, clr=200, /swea, /invert_phi, /invert_theta
            if keyword_set(sundir) then begin
              dt = min(abs(sun.time - mean(ddd.time)),j)
              Saz = sun.phi[j]
              Sel = sun.the[j]
              if (abs(Sel) gt 61.) then col=!p.color else col=!p.color
              oplot,[Saz],[Sel],psym=8,color=5,thick=2,symsize=2.0
;             Saz = (Saz + 180.) mod 360.
;             Sel = -Sel
;             oplot,[Saz],[Sel],psym=7,color=col,thick=2,symsize=1.2
            endif
            initct, pct2, reverse=prv2
          endif
        endif
      endif
            
      if (dospec and ~dwell) then begin
        if (~psflg) then wset, Ewin
        x = pad.energy[*,0]

        pndx = where(reform(pad.pa[63,*]) le swidth, nbins)
        case nbins of
             0 : begin
                   Fp = replicate(!values.f_nan,64)
                   Fp_err = Fp
                 end
             1 : begin
                   Fp = (pad.data[*,pndx] - pad.bkg[*,pndx])/fscale
                   indx = where(~pad.valid[*,pndx], count)
                   if (count gt 0L) then Fp[indx] = !values.f_nan
                   Fp_err = sqrt(pad.var[*,pndx])/fscale
                 end
          else : begin
                   Fp = (pad.data[*,pndx] - pad.bkg[*,pndx])/fscale
                   indx = where(~pad.valid[*,pndx], count)
                   if (count gt 0L) then Fp[indx] = !values.f_nan

                   ngud = total(finite(Fp),2)
                   Fp = average(Fp,2,/nan)/fscale
                   Fp_err = sqrt(total(pad.var[*,pndx],2,/nan))/(ngud > 1.)/fscale
                 end
        endcase

        mndx = where(reform(pad.pa[63,*]) ge (!pi - swidth), nbins)
        case nbins of
             0 : begin
                   Fm = replicate(!values.f_nan,64)
                   Fm_err = Fm
                 end
             1 : begin
                   Fm = (pad.data[*,mndx] - pad.bkg[*,mndx])/fscale
                   indx = where(~pad.valid[*,pndx], count)
                   if (count gt 0L) then Fm[indx] = !values.f_nan
                   Fm_err = sqrt(pad.var[*,mndx])/fscale
                 end
          else : begin
                   Fm = (pad.data[*,mndx] - pad.bkg[*,mndx])/fscale
                   indx = where(~pad.valid[*,mndx], count)
                   if (count gt 0L) then Fm[indx] = !values.f_nan

                   ngud = total(finite(Fm),2)
                   Fm = average(Fm,2,/nan)/fscale
                   Fm_err = sqrt(total(pad.var[*,mndx],2,/nan))/(ngud > 1.)/fscale
                 end
        endcase

        zndx = where((reform(pad.pa[63,*]) lt (!pi - swidth)) and $
                     (reform(pad.pa[63,*]) gt swidth), nbins)
        case nbins of
             0 : begin
                   Fz = replicate(!values.f_nan,64)
                   Fz_err = Fz
                 end
             1 : begin
                   Fz = (pad.data[*,zndx] - pad.bkg[*,zndx])/fscale
                   indx = where(~pad.valid[*,zndx], count)
                   if (count gt 0L) then Fz[indx] = !values.f_nan
                   Fz_err = sqrt(pad.var[*,zndx])/fscale
                 end
          else : begin
                   Fz = (pad.data[*,zndx] - pad.bkg[*,zndx])/fscale
                   indx = where(~pad.valid[*,zndx], count)
                   if (count gt 0L) then Fz[indx] = !values.f_nan

                   ngud = total(finite(Fz),2)
                   Fz = average(Fz,2,/nan)/fscale
                   Fz_err = sqrt(total(pad.var[*,zndx],2,/nan))/(ngud > 1.)/fscale
                 end
        endcase
        
        if keyword_set(twopot) then begin
            php = Fp/x^2              ; assume EFLUX units
            php_err = Fp_err/x^2
            x1 = x - twopot[0]
            inE = where(x1 ge 0, cts)
            Fp = php[inE]*x1[inE]^2
            Fp_err = php_err[inE]*x1[inE]^2
            
            php = Fm/x^2              ; assume EFLUX units
            php_err = Fm_err/x^2
            x2 = x - twopot[1]
            inE = where(x2 ge 0, cts)
            Fm = php[inE]*x2[inE]^2
            Fm_err = php_err[inE]*x2[inE]^2
        endif else begin
            x1 = x
            x2 = x
        endelse
        
        plot_oo, [0.1,0.1], drange, xrange=xrange, yrange=drange, /xsty, /ysty, $
          xtitle='Energy (eV)', ytitle=ytitle, title=time_string(pad.time), $
          charsize=1.4*cscale, xmargin=[10,3] ; , _extra=_extra

        oplot, x1, Fp, psym=10, color=6 ; , _extra=_extra
        oplot, x2, Fm, psym=10, color=2 ; , _extra=_extra
        if (domid) then oplot, x, Fz, psym=10, color=4 ; , _extra=_extra

        if (ebar) then begin
          errplot, x1*0.999, (Fp-Fp_err)>tiny, Fp+Fp_err, color=6, width=0
          errplot, x2*1.001, (Fm-Fm_err)>tiny, Fm+Fm_err, color=2, width=0
          if (domid) then errplot, x, (Fz-Fz_err)>tiny, Fz+Fz_err, color=4, width=0
        endif

        dwidth = swidth*!radeg
        str_element, result, 'spec_plus', {x:x1, y:Fp, dy:Fp_err, pa_range:[0.,dwidth]}, /add
        str_element, result, 'spec_minus', {x:x2, y:Fm, dy:Fm_err, pa_range:[180.-dwidth,180.]}, /add
        str_element, result, 'spec_mid', {x:x, y:Fz, dy:Fz_err, pa_range:[dwidth, 180.-dwidth]}, /add

        if (dopot) then begin
          if (spflg) then oplot,[-pot,-pot],drange,line=2,color=6 $
                     else oplot,[pot,pot],drange,line=2
        endif
        if (pflg) then begin
          str_element, cols, 'magenta', mcol, success=ok
          if (not ok) then str_element, cols, 'purple', mcol, success=ok
          if (not ok) then mcol = !p.color
          oplot,[23.,23.],drange,line=2,color=mcol
          oplot,[27.,27.],drange,line=2,color=mcol
          oplot,[60.,60.],drange,line=2,color=mcol
        endif

        xs = 0.68
        ys = 0.90
        dys = 0.03
        pa_min = round(swidth*!radeg)
        pa_max = 180 - pa_min
        xyouts,xs,ys,string(pa_min, format='("  0 - ",i2)'),charsize=1.2*cscale,/norm,color=6
        ys -= dys
        if (domid) then begin
          xyouts,xs,ys,string(pa_min, pa_max, format='(i3," - ",i3)'),charsize=1.2*cscale,/norm,color=4
          ys -= dys
        endif
        xyouts,xs,ys,string(pa_max, format='(i3," - 180")'),charsize=1.2*cscale,/norm,color=2
        ys -= dys

        if (doalt) then begin
          dt = min(abs(alt.x - pad.time), aref)
          xyouts,xs,ys,string(round(alt.y[aref]), format='("ALT = ",i5)'),charsize=1.2*cscale,/norm
          ys -= dys
          xyouts,xs,ys,string(round(sza.y[aref]), format='("SZA = ",i5)'),charsize=1.2*cscale,/norm
          ys -= dys
        endif
        
        if (dopot) then begin
          xyouts,xs,ys,string(pot, format='("SCP = ",f5.1)'),charsize=1.2*cscale,/norm
          ys -= dys
        endif
        
        if keyword_set(dir) then begin
          if (B_azim lt 0.) then B_azim = (B_azim + 360.) mod 360.
          xyouts,xs,ys,string(round(B_azim), format='("B_az = ",i4)'),charsize=1.2*cscale,/norm
          ys -= dys
          xyouts,xs,ys,string(round(B_elev), format='("B_el = ",i4)'),charsize=1.2*cscale,/norm          
          ys -= dys
        endif
        
        if (strlen(note) gt 0) then begin
          xyouts,xs,ys,note,charsize=1.2*cscale,/norm
          ys -= dys
        endif

      endif
    endif
    
    if (doind and ~dwell) then begin
        if (~psflg) then wset, Iwin
        x = pad.energy[*,0]
        npa = 16;n_elements(pad.energy[0,*])
        pas = reform(pad.pa[63,*])
        inm = where(pas eq min(pas))
        inm = inm[0]        
        !p.multi=[0,4,2,0,0]
        
        ;first half of the PAD
      
        for ip=0,npa/2-1 do begin
           xs = xrange[1]/100.
           ys = drange[1]/5.
           dys = 10^(0.05*(alog10(drange[1])-alog10(drange[0])))
            plot_oo, [0.1,0.1], drange, xrange=xrange, yrange=drange, /ysty, $
            xtitle='Energy (eV)', ytitle=ytitle, title=time_string(pad.time), $
            charsize=1.4*cscale, xmargin=[10,3]

            ipa = (ip + inm); < (ipa - npa)
            if ipa ge npa then ipa=ipa-npa
            mip = pad.pa_min[63,ipa]*!radeg
            maap = pad.pa_max[63,ipa]*!radeg
            ;if (pad.pa[63,ipa]*!radeg ge 90) then lst = 2 else lst = 0
            ;clr = 244./(npa/2-1)*ip + 10
            y = pad.data[*,ipa]
            dy = sqrt(pad.var[*,ipa])
            oplot,x,y,psym=10,color=4
            errplot, x, (y-dy)>tiny, y+dy, color=4, width=0
            xyouts,xs,ys,string(mip, maap, format='(i3," - ",i3)'),$
                   charsize=1.2*cscale,color=4
            ys /=dys

            ;second half
            ipa=ip+npa/2+inm
            ipa=npa-ip;-1
            if ipa ge npa then ipa = (npa-ip) mod (npa-1);ipa=ipa-npa
            mip=pad.pa_min[63,ipa]*!radeg
            maap=pad.pa_max[63,ipa]*!radeg
            ;if pad.pa[63,ipa]*!radeg ge 90 then lst=2 else lst=0
            ;clr=254.-244./(npa/2-1)*ip
            y = pad.data[*,ipa]
            dy = sqrt(pad.var[*,ipa])
            oplot,x,y,psym=10,color=6
            errplot, x, (y-dy)>tiny, y+dy, color=6, width=0
            xyouts,xs,ys,string(mip, maap, format='(i3," - ",i3)'),$
                   charsize=1.2*cscale,color=6
            ys /= dys
        
            if (dopot) then begin
               if (finite(scp)) then pot = scp $
               else if (finite(pad.sc_pot)) then pot = pad.sc_pot else pot = 0.
               oplot,[pot,pot],drange,line=2
            endif
            if (pflg) then begin
               str_element, cols, 'magenta', mcol, success=ok
               if (not ok) then str_element, cols, 'purple', mcol, success=ok
               if (not ok) then mcol = !p.color
               oplot,[23.,23.],drange,line=2,color=mcol
               oplot,[27.,27.],drange,line=2,color=mcol
               oplot,[60.,60.],drange,line=2,color=mcol
            endif

            if (doalt) then begin
               dt = min(abs(alt.x - pad.time), aref)
               xyouts,xs,ys,string(round(alt.y[aref]), format='("ALT = ",i5)'),$
                      charsize=1.2*cscale
               ys /= dys
               xyouts,xs,ys,string(round(sza.y[aref]), format='("SZA = ",i5)'),charsize=1.2*cscale
               ys /= dys
            endif
            
            if keyword_set(dir) then begin
               if (B_azim lt 0.) then B_azim = (B_azim + 360.) mod 360.
               xyouts,xs,ys,string(round(B_azim), format='("B_az = ",i4)'),charsize=1.2*cscale
               ys /= dys
               xyouts,xs,ys,string(round(B_elev), format='("B_el = ",i4)'),charsize=1.2*cscale
               ys /= dys
            endif
        
            if (strlen(note) gt 0) then begin
               xyouts,xs,ys,note,charsize=1.2*cscale
               ys /= dys
            endif
            

         endfor

        !p.multi=0
    endif

    if (padmap) then begin
      wset, Mwin

      Naz = 256
      daz = 2.*!pi/float(Naz)
      az = daz*findgen(Naz + 1)

      Nel = 128
      elmin = (swe_el[0,63,pad.group] - 0.5*swe_del[0,63,pad.group])*!dtor
      elmax = (swe_el[5,63,pad.group] + 0.5*swe_del[5,63,pad.group])*!dtor
      del = (elmax - elmin)/float(Nel)
      el = elmin + del*findgen(Nel + 1)

      azm = az # replicate(1.,Nel+1)
      elm = replicate(1.,Naz+1) # el
      pam = acos(cos(azm - pad.Baz)*cos(elm)*cos(pad.Bel) + sin(elm)*sin(pad.Bel))

      contour,pam*!radeg,az*!radeg,el*!radeg,levels=10*indgen(19),c_labels=replicate(1,19),$
              xrange=[0,360],xstyle=9,xticks=4,xminor=3,yrange=[-90,90],ystyle=9,$
              yticks=6,yminor=3,xmargin=[10,10],ymargin=[6,6],$
              xtitle='SWEA Azimuth',ytitle='SWEA Elevation',charsize=csize2,$
              c_charsize=csize1

      axis,/yaxis,yrange=[1,181],charsize=csize2,ystyle=1,ytitle='Elevation Bin',$
               yticks=6,yminor=0,yticklen=-0.00001,ytickv=(swe_el[*,63,0] + 91.),$
               ytickname=string(indgen(6),format='(" ",i1," ")'),color=4

      axis,/xaxis,xrange=[1,361],charsize=csize2,xstyle=1,xtitle='Azimuth Bin',$
               xticks=16,xminor=0,xticklen=-0.00001,xtickv=(swe_az + 1.),$
               xtickname=string(indgen(16),format='(i2)'),color=4

      az = 22.5*findgen(17)
      for i=1,15 do oplot,[az[i],az[i]],[elmin,elmax]*!radeg,color=4,linestyle=1
      el = [swe_el[*,63,pad.group] - (swe_del[*,63,pad.group]/2.), elmax*!radeg]
      for i=0,6 do oplot,[0,360],[el[i],el[i]],color=4,linestyle=1

      if (dosmo or (npts gt 1)) then $  ; TSMO or SUM mode is active
          xyouts,0.05,0.03,'* Data are averaged, so PA map is approximate.',/norm,charsize=1.2

      for k=0,7 do begin
        i = pad.iaz[k]
        j = pad.jel[k]
        azbox = [az[i], az[i+1], az[i+1], az[i]   ,az[i]]
        elbox = [el[j], el[j]  , el[j+1], el[j+1] ,el[j]]
        oplot,azbox,elbox,color=col[0],linestyle=2
      endfor

      for k=8,15 do begin
        i = pad.iaz[k]
        j = pad.jel[k]
        azbox = [az[i], az[i+1], az[i+1], az[i]   ,az[i]]
        elbox = [el[j], el[j]  , el[j+1], el[j+1] ,el[j]]
        oplot,azbox,elbox,color=col[8],linestyle=2
      endfor

      kb = where(swe_sc_mask[*,boom] eq 0, count)
      ib = kb mod 16
      jb = kb / 16
      for k=0,(count-1) do begin
        i = ib[k]
        j = jb[k]
        oplot,[mean(az[i:i+1])],[mean(el[j:j+1])],psym=7,symsize=3,thick=2,color=5
      endfor

      az = pad.Baz*!radeg
      el = pad.Bel*!radeg
      oplot,[az],[el],psym=1,symsize=2
      if (az gt 180.) then az -= 180. else az += 180.
      el = -el
      oplot,[az],[el],psym=4,symsize=2
    endif

    if (psflg) then pclose
    nplot++
    
; Get the next button press

    if (pdflg and ~tflg) then begin
       wset,Twin
       ctime,trange,npoints=npts,/silent
       if (npts gt 1) then cursor,cx,cy,/norm,/up ; make sure mouse button is released
       if (size(trange,/type) eq 5) then ok = 1 else ok = 0
    endif else ok = 0
    
  endwhile

  if keyword_set(mkpng) then begin
    if ~keyword_set(figname) then figname='~/'
    if (dospec) then makepng,figname+'_espec',wi=Ewin
    if (rflg or hflg or uflg) then makepng, figname+'_epad',wi=Pwin
    if (doind) then makepng, figname+'_indvspec', wi=Iwin
    if (dov) then makepng, figname+'_phasespace', wi=vwin
  endif

  if (kflg) then begin
    if (~rflg) then wdelete, Pwin
    if (sflg) then wdelete, Nwin
    if (dflg) then wdelete, Cwin
    if (dospec) then wdelete, Ewin
    if (rflg or hflg or uflg) then wdelete, Pwin
    if (doind) then wdelete, Iwin
    if (dov) then wdelete, vwin
    if (padmap) then wdelete, Mwin
  endif

  wset, Twin
  if ((ctab ne pct) or (crev ne prev)) then initct, pct, reverse=prev
  if (max(abs(lines - plines)) gt 0) then line_colors, plines

end
