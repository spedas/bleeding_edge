; Density moment

function specmom, eflux, erange=erange
  mass = 5.6856297d-06             ; electron rest mass [eV/(km/s)^2]
  c3 = 4D*!dpi*1d-5*sqrt(mass/2D)  ; assume isotropic electron distribution
  tiny = 1.e-31

  ounits = eflux.units_name
  mvn_swe_convert_units, eflux, 'eflux'
  E1 = eflux.energy
  dE = eflux.denergy
  F1 = eflux.data - eflux.bkg
  S1 = sqrt(eflux.var)
  pot = eflux.sc_pot

  indx = where(eflux.valid eq 0B, count)
  if (count gt 0L) then F1[indx] = tiny

  if (n_elements(erange) gt 1) then begin
    Emin = min(erange, max=Emax)
    j = where((E1 ge Emin) and (E1 le Emax), n_e)
  endif else begin
    j = where(E1 gt pot, n_e)
    j = j[0:(n_e-2)]  ; one channel cushion from s/c potential
    n_e--
  endelse

  prat = (pot/E1[j]) < 1.
  Enorm = c3*dE[j]*sqrt(1. - prat)*(E1[j]^(-1.5))
  N_j = Enorm*F1[j]
  S_j = Enorm*S1[j]

  N_tot = total(N_j)
  N_sig = sqrt(total(S_j^2.))

  Enorm = (2./3.)*c3*dE[j]*((1. - prat)^1.5)*(E1[j]^(-0.5))
  P_j = Enorm*F1[j]
  S_j = Enorm*S1[j]

  pres = total(P_j)
  psig = sqrt(total(S_j^2.))

  temp = pres/N_tot  ; temperature corresponding to kinetic energy density
  tsig = temp*sqrt((N_sig/N_tot)^2. + (psig/pres)^2.)

  mvn_swe_convert_units, eflux, ounits

  return, {N:N_tot, Nsig:N_sig, T:temp, Tsig:tsig, indx:j}
end

; Sheath "flat-top" distribution function

function fm_spec_generalized, V, parameters = par

    if not keyword_set(par) then begin
        par = {V0 : 5000.d,   $ ;km/s
            p : 5.5d,    $ ;
            r : 4.5d,    $
            C0 : 1.d-10, $
            func : 'fm_spec_generalized' };max df
    endif
    if n_params() eq 0 then return,par

    df = par.C0*(1+(V/par.V0)^(2.*par.r))^(-par.p/par.r)
    return,df
end

;+
;PROCEDURE:   swe_engy_snap
;PURPOSE:
;  Plots omnidirectional energy spectrum snapshots in a separate window for times 
;  selected with the cursor in a tplot window.  Hold down the left mouse button 
;  and slide for a movie effect.
;
;USAGE:
;  swe_engy_snap
;
;INPUTS:
;
;KEYWORDS:
;       UNITS:         Plot the data in these units.  See mvn_swe_convert_units.
;                      Default = 'eflux'.
;
;       TIMES:         Make a plot for these times.  (Placeholder only.)
;
;       TPLOT:         Get energy spectra from tplot variable instead of SWEA
;                      common block.
;
;       FIXY:          Use a fixed y-axis range.  Default = 1 (yes).
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       MONITOR:       Put snapshot windows in this monitor.  Monitors are numbered
;                      from 0 to N-1, where N is the number of monitors recognized
;                      by the operating system.  See win.pro for details.
;
;       ARCHIVE:       If set, show shapshots of archive data (A5).
;
;       BURST:         Synonym for ARCHIVE.
;
;       SPEC:          Named variable to hold the energy spectrum at the last time
;                      selected.
;
;       RESULT:        Named variable to hold the data used in the various plots.
;
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       TSMO:          Smoothing interval, in seconds.  Default is no smoothing.
;
;       ERROR_BARS:    If set, plot energy spectra with error bars.  Does not work 
;                      when the TPLOT option (see above) is set, because statistical
;                      uncertainties are not stored in the tplot variable.
;
;       POT:           Overplot an estimate of the spacecraft potential.  Must run
;                      mvn_scpot first.
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
;       DEMAX:         Maximum width of spacecraft potential signature.
;
;       PEPEAKS:       Overplot the nominal energies of the photoelectron energy peaks
;                      at 23 and 27 eV.
;
;       CUII:          Overplot ionization potential of Cu (hemispheres and top cap are
;                      coated with Cu2S).  This is the threshold for electron impact
;                      ionization and secondary electron contamination inside the 
;                      instrument.
;
;       PEREF:         Overplot photoelectron reference spectra
;
;       BCK:           Plot background level (Potassium-40 decay and penetrating
;                      particles only).
;
;       MAGDIR:        Print magnetic field geometry (azim, elev, clock) on the plot.
;
;       PDIAG:         Plot potential estimator in a separate window.
;
;       PXLIM:         X limits (Volts) for diagnostic plot.
;
;       PYLIM:         Y limits (Volts) for diagnostic plot.
;
;       MB:            Perform a Maxwell-Boltzmann fit to determine density and 
;                      temperature.  Uses a moment calculation to determine the
;                      halo density, which is defined as the high energy residual
;                      after subtracting the best-fit Maxwell-Boltzmann.
;
;       KAP:           Instead of the halo moment calculation, fit the halo with
;                      a kappa function to estimate halo density.
;
;       MOM:           Instead of fitting the core with a Maxwell-Boltzmann, use
;                      a moment calculation for all energies above the spacecraft
;                      potential.
;
;       ERANGE:        Energy range for computing the moment.  Only effective when
;                      keyword MOM is set.
;
;       FLEV:          Calculate the signal level at this energy, using interpolation
;                      as needed.
;
;       SCAT:          Plot the scattered photoelectron population, which is defined
;                      as the low-energy residual after subtracting the best-fit
;                      Maxwell-Boltzmann.
;
;       SEC:           Calculate secondary electron spectrum using one of two methods:
;                        SEC = 1 --> Andreone
;                        SEC = 2 --> Evans
;
;       SCONFIG:       Structure of parameters for the secondary electron models.
;
;                        {e0:e0, s0:s0, e1:e1, s1:s1, scl:scl}
;
;       NORAW:         If SEC is set, do not plot the uncorrected or secondary spectra;
;                      just plot the corrected spectrum.
;
;       DDD:           Create an energy spectrum from the nearest 3D spectrum and
;                      plot for comparison.
;
;       ABINS:         Anode bin mask (16 elements: 0=off, 1=on).  Default = all on.
;
;       DBINS:         Deflector bin mask (6 elements: 0=off, 1=on).  Default = all on.
;
;       OBINS:         3D solid angle bin mask (96 elements: 0=off, 1=on).
;                      Default = reform(ABINS # DBINS).
;
;       MASK_SC:       Mask solid angle bins that view the spacecraft.  Default = yes.
;                      This masking is in addition to OBINS.
;
;       NOERASE:       Overplot all spectra after the first.
;
;       VOFFSET:       Vertical offset when overplotting spectra.
;
;       RAINBOW:       With NOERASE, overplot spectra using up to 6 different colors.
;
;       RCOLORS:       Instead of the default rainbow colors, use these instead.
;                      Any number of colors is allowed.  The routine cycles through 
;                      the colors as needed, if there are many spectra to plot.
;
;       POPEN:         Set this to the name of a postscript file for output.
;
;       WSCALE:        Window size scale factor.
;
;       CSCALE:        Character size scale factor.
;
;       XRANGE:        Override the default horizontal axis range with this.
;
;       YRANGE:        Override the default vertical axis range with this.
;
;       TRANGE:        Plot snapshot for this time range.  Can be in any
;                      format accepted by time_double.  (This disables the
;                      interactive time range selection.)
;
;       TWOT:          Compare energy of peak energy flux and temperature of 
;                      Maxwell-Boltzmann fit. (Nominally, E_peak = 2*T)
;
;       SHOWDEAD:      Show the scaled deadtime correction.  Does not work with
;                      summed spectra (keywords SUM and TSMO) because spectra
;                      are summed in units of corrected count rate (CRATE) so
;                      that the deadtime corrections for the individual spectra
;                      are lost.
;
;       DEAD:          Same as SHOWDEAD.
;
;       BACKGROUND:    Show the background on the plot.
;
;       COLOR_TABLE:   Use this color table for all plots.
;
;       REVERSE_COLOR_TABLE:  Reverse the color table (except for fixed colors).
;
;       LINE_COLORS:   Use this for the line colors.
;
;       QLEVEL:        Minimum quality level for summing and plotting.  Filters out
;                      the vast majority of spectra affected by the sporadic low energy
;                      anomaly below 28 eV.  The validity levels are:
;
;                        0B = Data are affected by the low-energy anomaly.  There
;                             are significant systematic errors below 28 eV.
;                        1B = Unknown because: (1) the variability is too large to 
;                             confidently identify anomalous spectra, as in the 
;                             sheath, or (2) secondary electrons mask the anomaly,
;                             as in the sheath just downstream of the bow shock.
;                        2B = Data are not affected by the low-energy anomaly.
;                             Caveat: There is increased noise around 23 eV, even 
;                             for "good" spectra.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-23 09:23:37 -0700 (Mon, 23 Jun 2025) $
; $LastChangedRevision: 33402 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_engy_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_engy_snap, units=units, keepwins=keepwins, archive=archive, spec=spec, ddd=ddd, $
                   abins=abins, dbins=dbins, obins=obins2, sum=sum, pot=pot, pdiag=pdiag, $
                   pxlim=pxlim, mb=mb, kap=kap, mom=mom, scat=scat, erange=erange, $
                   noerase=noerase, scp=scp, fixy=fixy, pepeaks=pepeaks, $
                   burst=burst, rainbow=rainbow, mask_sc=mask_sc, sec=sec, $
                   bkg=bkg, tplot=tplot, magdir=magdir, bck=bck, shiftpot=shiftpot, $
                   xrange=xrange,yrange=frange,sconfig=sconfig, popen=popen, times=times, $
                   flev=flev, pylim=pylim, k_e=k_e, peref=peref, error_bars=error_bars, $
                   trange=tspan, tsmo=tsmo, wscale=wscale, cscale=cscale, voffset=voffset, $
                   endx=endx, twot=twot, rcolors=rcolors, cuii=cuii, fmfit=fmfit, nolab=nolab, $
                   showdead=showdead, dead=dead, monitor=monitor, der=der, color_table=color_table, $
                   reverse_color_table=reverse_color_table, line_colors=line_colors, noraw=noraw, $
                   qlevel=qlevel, result=result, background=background,$
                   mkpng=mkpng,figname=figname

  @mvn_swe_com
  @mvn_scpot_com
  @putwin_common

  mass = 5.6856297d-06             ; electron rest mass [eV/(km/s)^2]
  c1 = (mass/(2D*!dpi))^1.5
  c2 = (2d5/(mass*mass))
  c3 = 4D*!dpi*1d-5*sqrt(mass/2D)  ; assume isotropic electron distribution
  tiny = 1.e-31
  maxarg = 80.

  phi = findgen(49)*(2.*!pi/49.)
  usersym,cos(phi),sin(phi),/fill

  badspec = swe_engy_struct

  if (size(windex,/type) eq 0) then win, config=0  ; win acts like window

; Load any keyword defaults

  swe_snap_options, get=key, /silent
  ktag = tag_names(key)
  tlist = ['UNITS','KEEPWINS','ARCHIVE','DDD','ABINS','DBINS','OBINS2', $
           'SUM','POT','PDIAG','PXLIM','MB','KAP','MOM','SCAT','ERANGE', $
           'NOERASE','SCP','FIXY','PEPEAKS','BURST','RAINBOW','MASK_SC','SEC', $
           'BKG','TPLOT','MAGDIR','BCK','SHIFTPOT','XRANGE','YRANGE','SCONFIG', $
           'POPEN','TIMES','FLEV','PYLIM','K_E','PEREF','ERROR_BARS','TRANGE', $
           'TSMO','WSCALE','CSCALE','VOFFSET','ENDX','TWOT','RCOLORS','CUII', $
           'FMFIT','NOLAB','SHOWDEAD','DEAD','MONITOR','COLOR_TABLE','REVERSE_COLOR_TABLE', $
           'LINE_COLORS','NORAW','QLEVEL','RESULT','BACKGROUND']
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

  if (size(Espan,/type) eq 0) then mvn_scpot_defaults
  if keyword_set(dead) then showdead = 1

  aflg = 0  ; there are never any SPEC archive data (apid a5)
  if not keyword_set(units) then units = 'eflux'
  if keyword_set(sum) then begin
    npts = 2
    showdead = 0  ; incompatible with summed spectra
  endif else npts = 1
  if keyword_set(tsmo) then begin
    npts = 1
    dosmo = 1
    dtsmo = double(tsmo)/2D
    showdead = 0  ; incompatible with summed spectra
  endif else dosmo = 0
  if (size(error_bars,/type) eq 0) then ebar = 1 else ebar = keyword_set(error_bars)
  dflg = keyword_set(ddd)
  oflg = ~keyword_set(noerase)
  dolab = ~keyword_set(nolab)
  if (size(scp,/type) eq 0) then scp = !values.f_nan else scp = float(scp[0])
  if (size(fixy,/type) eq 0) then fflg = 1 else fflg = keyword_set(fixy)
  rflg = keyword_set(rainbow)
  dosec = keyword_set(sec)
  dobkg = keyword_set(bkg)
  doraw = ~keyword_set(noraw) or ~dosec
  qlevel = (n_elements(qlevel) gt 0) ? byte(qlevel[0]) < 2B : 0B

  spflg = keyword_set(shiftpot)
  if (n_elements(xrange) ne 2) then xrange = [1.,1.e4]
  if not keyword_set(wscale) then wscale = 1.
  if not keyword_set(cscale) then cscale = wscale
  if not keyword_set(voffset) then voffset = 1.
  if not keyword_set(rcolors) then begin
    ncol = 6
    rcol = indgen(ncol) + 1
  endif else begin
    ncol = n_elements(rcolors)
    rcol = fix(rcolors)
  endelse
  if (size(popen,/type) eq 7) then begin
    psflg = 1
    psname = popen[0]
    csize1 = 1.2*cscale
    csize2 = 1.0*cscale
  endif else begin
    psflg = 0
    csize1 = 1.2*cscale
    csize2 = 1.4*cscale
  endelse

  tflg = 0
  if (keyword_set(tplot) or (n_elements(mvn_swe_engy) lt 2L)) then begin
    get_data,'swe_a4',data=dat,limits=lim,index=i
    if (i gt 0) then begin
      str_element,lim,'ztitle',units_name,success=ok
      if (ok) then units_name = strlowcase(units_name) else units_name = 'unknown'
      tspec = {time:dat.x, data:dat.y, var:(dat.dy)^2., energy:dat.v, units_name:units_name}
      tflg = 1
    endif else print,'No SPEC data found in tplot.'
  endif

  get_data,'alt',data=alt
  if (size(alt,/type) eq 8) then begin
    doalt = 1
    get_data,'sza',data=sza
    get_data,'lon',data=lon
    get_data,'lat',data=lat
  endif else doalt = 0

  if (~dolab) then doalt = 0

  domag = 0
  if keyword_set(magdir) then begin
    get_data,'mvn_B_1sec_iau_mars',data=mag
    if (size(mag,/type) eq 8) then domag = 1 else domag = 0
  endif

  if ((size(obins,/type) eq 0) or keyword_set(abins) or keyword_set(dbins) or $
      keyword_set(obins2) or keyword_set(mask_sc)) then begin
    if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
    if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
    if (n_elements(obins2) ne 96) then begin
      obins = replicate(1B, 96, 2)
      obins[*,0] = reform(abins # dbins, 96)
      obins[*,1] = obins[*,0]
    endif else obins = reform(byte(obins2)) # [1B,1B]
    if (size(mask_sc,/type) eq 0) then mask_sc = 1
   if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  endif
  
  if (size(pot,/type) eq 0) then dopot = 1 else dopot = keyword_set(pot)
  if keyword_set(pepeaks) then dopep = 1 else dopep = 0
  if keyword_set(cuii) then docu = 1 else docu = 0
  if (size(peref,/type) eq 8) then doper = 1 else doper = 0
  if keyword_set(scat) then scat = 1 else scat = 0

  if keyword_set(mb) then begin
    mb = 1
    dopot = 1
  endif else mb = 0
  if keyword_set(kap) then kap = 1 else kap = 0

  if keyword_set(mom) then begin
    mom = 1
    dopot = 1
    mb = 0
    kap = 0
  endif else mom = 0

  if keyword_set(pdiag) then begin
    get_data,'df',data=df
    get_data,'d2f',data=d2f,index=i
    if (i gt 0) then pflg = 1 else pflg = 0
  endif else pflg = 0

  if (not tflg) then begin
    if (size(mvn_swe_engy,/type) ne 8) then mvn_swe_makespec
  
    if (aflg) then begin
      if (size(mvn_swe_engy_arc,/type) ne 8) then begin
        print,"No SPEC archive data."
        return
      endif
    endif else begin
      if (size(mvn_swe_engy,/type) ne 8) then begin
        print,"No SPEC survey data."
        return
      endif
    endelse
  endif
  
  if (fflg) then begin
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
  endif

  if (size(swe_hsk,/type) eq 8) then begin
    if (n_elements(swe_hsk) gt 2L) then hflg = 1 else hflg = 0
  endif else hflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  aflg = 0  ; there are never any SPEC arvhive data (apid a5)

  case n_elements(tspan) of
       0 : tsflg = 0
       1 : begin
             tspan = time_double(tspan)
             tsflg = 1
             if keyword_set(keepwins) then kflg = 0 else kflg=1
           end
    else : begin
             tspan = minmax(time_double(tspan))
             tsflg = 1
             if keyword_set(keepwins) then kflg = 0 else kflg=1
           end
  endcase

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

  cols = get_colors()
  if (cols.color_table ge 1000) then cols = get_qualcolors()
  cbot = (cols.bottom_c ge 0) ? cols.bottom_c : 7
  ctop = (cols.top_c ge 0) ? cols.top_c : 254
  str_element, cols, 'magenta', mcol, success=ok
  if (not ok) then str_element, cols, 'purple', mcol, success=ok
  if (not ok) then mcol = !p.color
  str_element, cols, 'cyan', bcol, success=ok
  if (not ok) then str_element, cols, 'blue', bcol, success=ok
  if (not ok) then bcol = !p.color

; Put up snapshot window(s)

  Twin = !d.window

  undefine, mnum
  if (size(monitor,/type) gt 0) then begin
    if (~windex) then win, /config
    mnum = fix(monitor[0])
  endif else begin
    if (size(secondarymon,/type) gt 0) then mnum = secondarymon
  endelse

  win, /free, monitor=mnum, xsize=400, ysize=600, dx=10, dy=10, scale=wscale
  Ewin = !d.window

  if (hflg) then begin
    win, /free, rel=!d.window, xsize=200, ysize=600, dx=10
    Hwin = !d.window
  endif
  
  if (pflg) then begin
    win, /free, rel=!d.window, xsize=450, ysize=600, dx=10
    Pwin = !d.window
    win, /free, xsize=450, ysize=300, rel=Pwin, dy=-10
    Fwin = !d.window
  endif

  if keyword_set(der) then begin
    doder = 1
    win, /free, rel=!d.window, clone=Ewin, dx=10
    Dwin = !d.window
  endif else doder = 0

; Get the spectrum closest to the selected time
  
  ok = 1

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  if (~tsflg) then begin
    trange = 0
    ctime,trange,npoints=npts,/silent
    if (npts gt 1) then cursor,cx,cy,/norm,/up  ; Make sure mouse button released
  endif else trange = tspan

  if (size(trange,/type) eq 2) then begin       ; Abort before first time select.
    wdelete,Ewin
    if (hflg) then wdelete,Hwin
    if (pflg) then begin
      wdelete,Pwin
      wdelete,Fwin
    endif
    wset,Twin
    if ((ctab ne pct) or (crev ne prev)) then initct, pct, reverse=prev
    if (max(abs(lines - plines)) gt 0) then line_colors, plines
    return
  endif

  if (dosmo) then begin
    tmin = min(trange, max=tmax)
    trange = [(tmin - dtsmo), (tmax + dtsmo)]
  endif

  if (tflg) then begin
    if (finite(scp)) then pot = scp else pot = 0.

    if ((npts eq 1) and (~dosmo)) then begin
      dt = min(abs(trange[0] - tspec.time), i)
      spec = {time:tspec.time[i], data:reform(tspec.data[i,*]), var:reform(tspec.var[i,*]), $
              energy:tspec.energy, units_name:tspec.units_name, sc_pot:pot}
    endif else begin
      tmin = min(trange, max=tmax)
      i = where((tspec.time ge tmin) and (tspec.time le tmax), nspec)
      if (nspec gt 0L) then begin
        dat = tspec.data[i,*]
        var = tspec.var[i,*]
        nrm = dat
        nrm[*] = 1.
        bndx = where(~finite(dat), count)
        if (count gt 0L) then begin
          nrm[bndx] = 0.
          var[bndx] = !values.f_nan
        endif
        nrm = total(nrm, 1)/float(nspec)

        avg = total(dat[i,*], 1, /nan)/nrm
        var = total(var[i,*], 1, /nan)/nrm

        spec = {time:mean(tspec.time[i]), data:avg, var:var, energy:tspec.energy, $
                units_name:tspec.units_name, sc_pot:pot}
      endif
    endelse
  endif else begin
    spec = mvn_swe_getspec(trange, /sum, archive=aflg, units=units, yrange=yrange, qlevel=qlevel)
    if (size(spec,/type) ne 8) then begin
      spec = badspec
      spec.time = mean(trange)
      spec.end_time = max(trange)
      spec.quality = 255B
    endif
    if (finite(scp)) then pot = scp $
                     else if (finite(spec.sc_pot)) then pot = spec.sc_pot else pot = 0.
    spec.sc_pot = pot
    dt = min(abs(spec.time - mvn_swe_engy.time),endx)
  endelse
  if (fflg) then yrange = drange
  if keyword_set(frange) then yrange = frange

; Correct for spacecraft potential.  For instrumental units (COUNTS, RATE, or
; CRATE) only shift in energy.  For flux units (FLUX, EFLUX), shift in energy 
; and correct the signal level to ensure conservation of phase space density.

  if (spflg) then begin
    if (stregex(units,'flux',/boo,/fold)) then begin
      mvn_swe_convert_units, spec, 'df'
      spec.energy -= pot
      mvn_swe_convert_units, spec, units
    endif else spec.energy -= pot
  endif

  rate = spec
  mvn_swe_convert_units, rate, 'rate'
  rate = rate.data
  
  case strupcase(units) of
    'COUNTS' : ytitle = 'Raw Counts'
    'RATE'   : ytitle = 'Raw Count Rate'
    'CRATE'  : ytitle = 'Count Rate'
    'EFLUX'  : ytitle = 'Energy Flux (eV/cm2-s-ster-eV)'
    'E2FLUX' : ytitle = 'Energy Flux (eV/cm2-s-ster)'
    'FLUX'   : ytitle = 'Flux (1/cm2-s-ster-eV)'
    'DF'     : ytitle = 'Dist. Function (1/cm3-(km/s)3)'
    else     : ytitle = 'Unknown Units'
  endcase

  if (hflg) then dt = min(abs(swe_hsk.time - spec.time), jref)  ; closest HSK
  
  nplot = 0
  xs = 0.68
  dys = 0.03
  yoff = 1.
  
  while (ok) do begin
    result = {units:units}

    x = spec.energy
    y = spec.data * yoff
    if (ebar) then dy = sqrt(spec.var) * yoff
    phi = spec.sc_pot
    ys = 0.90
    if (~oflg) then yoff *= voffset

    if (psflg) then popen, psname + string(nplot,format='("_",i2.2)') $
               else wset, Ewin

; Put up an Energy Spectrum with (optionally) model fit, background, scattering, etc.

    psym = 10

    delta_t = spec.end_time - spec.time
    if (delta_t gt 1D) then begin
      tstart = time_string(spec.time - delta_t)
      tend   = strmid(time_string(spec.end_time),11)
      title = tstart + ' - ' + tend
    endif else title = time_string(spec.time)

    str_element, result, 'trange', [spec.time-delta_t, spec.end_time], /add

    if ((nplot eq 0) or oflg) then plot_oo,x,y,yrange=yrange,/ysty,xrange=xrange,/xsty, $
            xtitle='Energy (eV)', ytitle=ytitle,charsize=csize2,psym=psym,title=title, $
            xmargin=[10,3] $
                              else oplot,x,y,psym=psym

    if (ebar) then errplot,x,(y-dy)>tiny,y+dy,width=0

    str_element, result, 'measured', {x:x, y:y, dy:dy}, /add

    if (rflg) then begin
      col = rcol[nplot mod ncol]
      oplot,x,y,psym=psym,color=col
      if (ebar) then errplot,x,(y-dy)>tiny,y+dy,width=0,color=col
    endif

    if keyword_set(showdead) then begin
      scale = max(yrange)/10.
      if (swe_paralyze) then mindtc = 1./exp(1.) else mindtc = swe_min_dtc
      oplot,x,scale/swe_deadtime(rate),psym=psym,color=5
      oplot,xrange,[scale,scale],line=2,color=5
      oplot,xrange,[scale,scale]/mindtc,line=2,color=5
    endif

    if (keyword_set(fmfit) and strupcase(units) eq 'DF') then begin
       ine = where(x gt 25 and x lt 500 and y gt 0, cte)
       inen1 = where(x gt 25 and x lt 50)
       datf = y[ine]
       V=sqrt(2.*x[ine]*1.6e-19/9.1e-31)*1.e-3 ;km/s          
       c0=mean(datf[inen1])
       par = fm_spec_generalized()  
       par.c0 = double(c0)
       if cte gt 0 then $
       fit,V,datf,chi2=ierr,fit=yfit,func='fm_spec_generalized',$
           names='V0 p C0 r',/logfit, par=par,/silent
       if n_elements(yfit) gt 1 then oplot,x[ine],yfit,psym=psym,color=cols.red
    endif

    if (dflg) then begin
      if (npts gt 1) then ddd = mvn_swe_get3d(trange,/all,/sum) $
                     else ddd = mvn_swe_get3d(spec.time)
      mvn_swe_convert_units, ddd, units
      dt = min(abs(swe_hsk.time - ddd.time), kref)

      if (ddd.time gt t_mtx[2]) then boom = 1 else boom = 0
      indx = where(obins[*,boom] eq 1B, onorm)
      omask = replicate(1.,64) # obins[*,boom]
      onorm = float(onorm)

      spec3d = total(ddd.data*omask,2,/nan)/onorm
      oplot,ddd.energy[*,0],spec3d,psym=psym,color=cols.green
    endif

    if keyword_set(background) then begin
      x = spec.energy
      y = spec.bkg
      oplot, x, y, color=4, psym=0
      dosec = 0  ; disable secondary code, which overwrites the background
    endif

; Secondary electrons produced by primary electron impact inside the instrument.

    if (dosec) then begin

; Method 1: Adapted from Andreone

      if (sec eq 1) then begin
        mvn_swe_secondary, spec, config=sconfig, scale=fscale
        x = spec.energy
        y = spec.data
        dy = sqrt(spec.var)
        yb = spec.bkg
        ya = spec.data - spec.bkg
        indx = where(~spec.valid, count)
        if (count gt 0L) then ya[indx] = !values.f_nan

        if (doraw) then oplot, x, yb, color=cols.blue, psym=10
        oplot, x, ya, color=cols.green, psym=10
        if (ebar) then errplot,x,(ya-dy)>tiny,ya+dy,width=0

        str_element, result, 'secondary', {x:x, y:yb}, /add
        str_element, result, 'corrected', {x:x, y:ya, dy:dy}, /add

      endif

; Method 2: McFadden, adapted from Dave Evans

      if (sec eq 2) then begin
        mvn_swe_convert_units, spec, 'crate'

        e = spec.energy
        n_e = n_elements(e)
        Rs = dblarr(n_e)

        alpha = 1.35
        Tmax = 2.283
        Emax = 325.
        k = 2.2
        str_element, sconfig, 'scl', value, success=ok
        if (ok) then sscale = double(value) else sscale = 5D

        Vbias = 0.                        ; primaries not passing through exit grid
        Erat = (e + Vbias)/Emax           ; effect of V0 cancels when using swe_swp
        arg = Tmax*(Erat^alpha) < maxarg  ; avoid underflow

        delta = (Erat^(1. - alpha))*(1. - exp(-arg))/(1. - exp(-Tmax))
        eff = sscale*(1. - exp(-k*delta))/(1. - exp(-k))

        for k=1,n_e-1 do Rs[k:*] += eff[k]*spec.data[k]/e[k:*]^2.0
        spec.bkg = Rs

        spec.valid = 1B
        mvn_swe_convert_units, spec, 'eflux'
        y = spec.data
        ya = y - spec.bkg
        dy = sqrt(spec.var)

        indx = where(e le spec.sc_pot, count)
        if (count gt 0L) then spec.valid[indx] = 0B       ; s/c photoelectrons

        kscp = max(where(e gt spec.sc_pot))
        ymax = max(e[0:kscp]*ya[0:kscp], kmax)
        ymin = min(e[kmax:kscp]*ya[kmax:kscp], kmin)
        kmin += kmax
        if ((ya[kmin] + 2.*dy[kmin]) lt max(ya[(kmin-1):kscp])) then begin
          spec.valid[(kmin+1 < kscp):*] = 0B         ; under-correction
        endif

        indx = where((e lt 100.) and (y/ya gt 10.), count)
        if (count gt 0L) then spec.valid[indx] = 0B  ; over-correction

        mvn_swe_convert_units, spec, units
        x = spec.energy
        y = spec.data
        dy = sqrt(spec.var)
        yb = spec.bkg
        ya = spec.data - spec.bkg
        indx = where(~spec.valid, count)
        if (count gt 0L) then ya[indx] = !values.f_nan

        oplot, x, yb, color=cols.blue, psym=10
        oplot, x, ya, color=cols.green, psym=10
        if (ebar) then errplot,x,(ya-dy)>tiny,ya+dy,width=0

        str_element, result, 'secondary', {x:x, y:yb}, /add
        str_element, result, 'corrected', {x:x, y:ya, dy:dy}, /add

      endif
    endif

; Background counts resulting from the wings of the energy response function.
; Empirical: based on fits to solar wind core.  Experimental.

    if (dobkg) then begin
      odat = spec
      mvn_swe_convert_units, odat, 'crate'

      energy = odat.energy
      nenergy = odat.nenergy

      if (finite(scp)) then pot = scp $
                       else if (finite(phi)) then pot = phi else pot = 0.
      kndx = where(energy le pot, kcnt)

      if (kcnt gt 0L) then begin
        bkg_spec = dblarr(nenergy)
        kmax = nenergy - 1

        scale = 1.5d-1

        for k=1,(nenergy-2) do begin
          denergy = energy - energy[k]
          bkg_spec[0:k-1] += scale*odat.data[k]/denergy[0:k-1]^2.0
          bkg_spec[k+1:kmax] += scale*odat.data[k]/denergy[k+1:kmax]^2.0
        endfor
        bkg_spec[kndx] = !values.f_nan

        odat.data = bkg_spec
        bkg_dat = odat
        mvn_swe_convert_units, bkg_dat, units
        dif_dat = spec
        dif_dat.data = (spec.data - bkg_dat.data) > 1.
        oplot,bkg_dat.energy,bkg_dat.data,color=cols.yellow,line=2
        oplot,dif_dat.energy,dif_dat.data,color=cols.yellow,psym=10
      endif
    endif
    
    if keyword_set(bck) then begin
      bck = spec
      eff0 = 1./mvn_swe_crosscal('2014-11-15',/silent)
      eff = 1./mvn_swe_crosscal(bck.time,/silent)
      brate = (0.6*(average(eff,/nan)/eff0))[0]
      bck.data[*] = brate  ; background crate per anode at periapsis
      bck.units_name = 'crate'
      mvn_swe_convert_units, bck, units
      oplot, bck.energy, bck.data, line=2, color=cols.green        ; periapsis
      brate = ((2./3.)*(0.97/0.63) + (1./3.))                      ; GCR's + Potassium-40
      oplot, bck.energy, bck.data*brate, line=2, color=cols.green  ; apoapsis
      
      bck.data[*] = (1./swe_min_dtc - 1.)/swe_dead                 ; saturation CRATE
      bck.units_name = 'crate'
      mvn_swe_convert_units, bck, units
      oplot, bck.energy, bck.data, line=2, color=cols.green
    endif

    if (dopot) then begin
      if (spflg) then oplot,[-pot,-pot],yrange,line=2,color=cols.green $
                 else oplot,[pot,pot],yrange,line=2,color=cols.red
      str_element, result, 'scpot', pot, /add
    endif
    
    if (dopep) then begin
      oplot,[23.,23.],yrange,line=2,color=mcol
      oplot,[27.,27.],yrange,line=2,color=mcol
      oplot,[60.,60.],yrange,line=2,color=mcol
      oplot,[250.,250.],yrange,line=2,color=mcol
      oplot,[360.,360.],yrange,line=2,color=mcol
    endif

    if (docu) then oplot,[7.73,7.73],yrange,line=2,color=mcol
    
    if (doper) then begin
      oplot, peref.x, peref.y
      oplot, peref.x, peref.y2
    endif

    if (spec.quality eq 255B) then begin
      xyouts,xs,ys,"NO VALID DATA",charsize=csize1,/norm
      ys -= dys
    endif
    
    if (doalt) then begin
      dt = min(abs(alt.x - spec.time), aref)
      xyouts,xs,ys,string(round(alt.y[aref]), format='("ALT = ",i5)'),charsize=csize1,/norm
      ys -= dys
      if (~mb and ~mom) then begin
        xyouts,xs,ys,string(round(sza.y[aref]), format='("SZA = ",i5)'),charsize=csize1,/norm
        ys -= dys
      endif
    endif

    if (0) then begin  ; this info available with mvn_swe_calib,/list
      msg = "!4s!1H = " + string(swe_dead, format='(e8.2)')
      xyouts, xs, ys, msg, charsize=csize1, color=5,/norm
      ys -= dys
      msg = ["non-paralyzable","paralyzable"]
      xyouts, xs, ys, msg[swe_paralyze], charsize=csize1, color=5,/norm
      ys -= dys
    endif
    
    if (domag) then begin
      dt = min(abs(mag.x - spec.time), mref)
      str_element, mag, 'azim', success=ok
      if (ok) then begin
        xyouts,xs,ys,string(round(mag.azim[mref]), format='("Baz = ",i5)'),charsize=csize1,/norm
        ys -= dys
      endif
      str_element, mag, 'elev', success=ok
      if (ok) then begin
        xyouts,xs,ys,string(round(mag.elev[mref]), format='("Bel = ",i5)'),charsize=csize1,/norm
        ys -= dys
      endif
      str_element, mag, 'clock', success=ok
      if (ok) then begin
        xyouts,xs,ys,string(round(mag.clock[mref]), format='("Bclk = ",i5)'),charsize=csize1,/norm
        ys -= dys
      endif
    endif
    
    if (mb and (spec.quality ne 255B)) then begin
      mvn_swe_convert_units, spec, 'eflux'
      E1 = spec.energy
      dE = spec.denergy
      F1 = spec.data - spec.bkg
      sdev = sqrt(spec.var)
      indx = where((spec.valid eq 0B) or (~finite(F1)), count)
      if (count gt 0) then F1[indx] = tiny
      dcol = cols.green

      p = swe_maxbol()
      p.pot = spec.sc_pot

      indx = where(E1 gt p.pot, count)
      indx = indx[0:(count-2)]

      Fpeak = max(F1[indx],k,/nan)
      Epeak = E1[indx[k]]
      p.t = Epeak/2.
      p.n = Fpeak/(4.*c1*c2*sqrt(p.t)*exp((p.pot/p.t) - 2.))
      Elo = min(E1[indx])
      imb = where((E1 gt Elo) and (F1 gt Fpeak/3.))

      fit,E1[imb],F1[imb],dy=sdev[imb],func='swe_maxbol',par=p,names='N T',/silent
      
      N_core = p.n

      if (kap) then begin
        Fh = F1 - swe_maxbol(E1,par=p)
        ikap = where(E1 gt Epeak*3.)
        Fhmax = max(Fh[ikap],k,/nan)
        Ehmax = E1[ikap[k]]
        Th = Ehmax/2.

        p.k_n = Fhmax/(4.*c1*c2*sqrt(Th)*exp((p.pot/Th) - 2.))
        p.k_vh = sqrt(Ehmax/mass)
        
        ikap = where((E1 gt Epeak*0.8) and (E1 lt Epeak*25.))

        fit,E1[ikap],F1[ikap],func='swe_maxbol',par=p,names='N T K_N',/silent
        fit,E1[ikap],F1[ikap],func='swe_maxbol',par=p,names='N T K_N K_VH',/silent
;        fit,E1[indx],F1[indx],func='swe_maxbol',par=p,names='N T K_N K_VH K_K',/silent

        N_tot = p.n + p.k_n
        pk = p
        pk.n = 0.

        kappa = spec
        kappa.data = !values.f_nan
        kappa.data[ikap] = swe_maxbol(E1[ikap],par=pk)
        mvn_swe_convert_units, kappa, units
        oplot,E1,kappa.data,psym=10,color=bcol
      endif else begin
        j = where(E1 gt Epeak*2., n_e)
        E_halo = E1[j]
        F_halo = (F1[j] - swe_maxbol(E_halo, par=p)) > 0.
        prat = (p.pot/E_halo) < 1.

        N_halo = c3*total(dE[j]*sqrt(1. - prat)*(E_halo^(-1.5))*F_halo)
        N_tot = N_core + N_halo

        halo = spec
        halo.data = !values.f_nan
        halo.data[j] = F_halo
        mvn_swe_convert_units, halo, units
        oplot,E1,halo.data,color=mcol,psym=10

        str_element, result, 'halo', {x:E1, y:halo.data, dy:dy}, /add
      endelse

      if (spflg) then jndx = indgen(64) else jndx = where(E1 gt p.pot)
      thermal = spec
      thermal.data = !values.f_nan
      thermal.data[jndx] = swe_maxbol(E1[jndx],par=p)
      mvn_swe_convert_units, thermal, units
      oplot,E1,thermal.data,thick=2,color=cols.green,line=1
      oplot,E1[imb],thermal.data[imb],color=cols.green,thick=2
      if keyword_set(twot) then oplot,2.*[p.T,p.T],yrange,line=2,color=cols.yellow

      str_element, result, 'core', {x:E1, y:thermal.data}

      xyouts,xs,ys,string(N_tot,format='("N = ",f6.2)'),color=dcol,charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(p.T,format='("T = ",f5.2)'),color=dcol,charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(p.pot,format='("V = ",f5.2)'),color=cols.red,charsize=csize1,/norm
      ys -= dys
      if (kap) then begin
        xyouts,xs,ys,string(p.k_n,format='("Nh = ",f5.2)'),color=bcol,charsize=csize1,/norm
        ys -= dys
        xyouts,xs,ys,string(p.k_vh,format='("Vh = ",f6.0)'),color=bcol,charsize=csize1,/norm
        ys -= dys
        xyouts,xs,ys,string(p.k_k,format='("k = ",f5.2)'),color=bcol,charsize=csize1,/norm        
        ys -= dys
      endif else begin
        xyouts,xs,ys,string(N_halo,format='("Nh = ",f5.2)'),color=mcol,charsize=csize1,/norm
        ys -= dys
      endelse

      smom = specmom(spec, erange=erange)
      ys -= dys
      xyouts,xs,ys,"Moments:",charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(smom.N,format='("N = ",f5.2)'),charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(smom.T,format='("T = ",f5.2)'),charsize=csize1,/norm
      ys -= dys

      if (scat) then begin
        kndx = where((E1 gt phi) and (E1 lt Epeak), count)
        if (count gt 0L) then begin
          x_scat = E1[kndx]
          y_scat = F1[kndx] - swe_maxbol(E1[kndx], par=p)
          kndx = where(E1 le phi, count)
          if (count gt 0L) then begin
            x_scat = [x_scat, E1[kndx]]
            y_scat = [y_scat, F1[kndx]]
          endif
          oplot,x_scat,y_scat,color=bcol,psym=10
        endif
      endif
    endif

    if (mom and (spec.quality ne 255B)) then begin
      dcol = 1

      smom = specmom(spec, erange=erange)

      x = spec.energy[smom.indx]
      y = spec.data[smom.indx] - spec.bkg[smom.indx]
      indx = where(spec.valid[smom.indx] eq 0B, count)
      if (count gt 0L) then y[indx] = !values.f_nan

      oplot,x,y,color=dcol,psym=10
;     print,"Density = ",smom.N," +/- ",smom.Nsig,format='(a,f6.2,a,f6.2)'
;     print,"Temperature = ",smom.T," +/- ",smom.Tsig,format='(a,f6.2,a,f6.2)'

      xyouts,xs,ys,string(smom.N,format='("N = ",f6.2)'),color=dcol,charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(smom.T,format='("T = ",f6.2)'),color=dcol,charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(pot,format='("V = ",f6.2)'),color=cols.red,charsize=csize1,/norm
      ys -= dys
    endif
    
    if (~mb and ~mom and dolab) then begin
      xyouts,xs,ys,string(pot,format='("V = ",f6.2)'),color=cols.red,charsize=csize1,/norm
      ys -= dys
    endif

    if (dosec and (spec.quality ne 255B)) then begin
      if (sec eq 1) then begin
        mvn_swe_secondary, param=p
        ys -= dys
        xyouts,xs,ys,string(p.e0, format='("E0 = ",f5.2)'),charsize=csize1,color=cols.blue,/norm
        ys -= dys
        xyouts,xs,ys,string(p.s1, format='("S1 = ",f5.2)'),charsize=csize1,color=cols.blue,/norm
        ys -= dys
        xyouts,xs,ys,string(fscale, format='("SCL = ",f5.2)'),charsize=csize1,color=cols.blue,/norm
        ys -= dys
      endif else begin
        ys -= dys
        xyouts,xs,ys,string(sscale, format='("SCL = ",f5.2)'),charsize=csize1,color=cols.blue,/norm
        ys -= dys
      endelse
    endif

    if keyword_set(flev) then begin
      logE0 = alog10((float(flev) > min(spec.energy)) < max(spec.energy))
      logE = alog10(spec.energy)
      logF = alog10(spec.data)

      E0 = 10.^logE0
      F0 = 10.^interpol(logF, logE, logE0)
      oplot,[E0],[F0],psym=4,color=cols.red,symsize=1.5,thick=2
      
      xyouts,xs,ys,string(F0,format='("F = ",e8.2)'),color=cols.red,charsize=csize1,/norm
      ys -= dys

      Emsg = strtrim(string(E0,format='(f7.1)'),2)
      print,"Flux (",Emsg," eV) = ",F0,format='(a,a,a,e8.2)'
    endif

    if (dflg) then begin
      xyouts,xs,ys,'3D',charsize=csize1,/norm,color=cols.green
      ys -= dys
    endif
    
    if keyword_set(k_e) then begin
      xyouts,xs,ys,string(swe_Ke[0],format='("Ke = ",f4.2)'),charsize=csize1,/norm
      ys -= dys
    endif

    if (doder) then begin
      indx = where(spec.energy lt 1000.)
      e = spec.energy[indx]
      f = alog10(spec.data[indx] > 1.)
      df = deriv(f)
      dfs = smooth(df,3)

      wset, Dwin
      plot_oi,e,dfs,xrange=[1,1000],yrange=[-1,1],/xsty,xtitle='Energy (eV)',$
              ytitle='df',charsize=csize1,psym=4
      oplot,e,dfs,color=cols.green
      oplot,[1.,1000.],[0.,0.],line=2

      if (0) then begin
        g = dfs*shift(dfs,1)
        g[0] = 0.
        indx = where(g lt 0., count)
        for k=0,(count-1) do oplot,[e[indx[k]],e[indx[k]]],[1e1,1e10],line=2,color=cols.green
      endif
    endif

    if (psflg) then pclose

    if (pflg) then begin
      wset, Pwin

      xs = 0.65
      ys = 0.90
      dys = 0.03
      csize0 = csize1*0.8

      if not keyword_set(pxlim) then xlim = [3,20] else xlim = minmax(pxlim)
      if not keyword_set(pylim) then ylim = [-0.2, 0.4] else ylim = minmax(pylim)

      dt = min(abs(d2f.x - trange[0]), kref)
      px = reform(d2f.v[kref,*])
      py = reform(df.y[kref,*])
      py2 = reform(d2f.y[kref,*])    
      n_e = n_elements(py)

      zcross = py2 * shift(py2,1)
      zcross[0] = 1.
      indx = where((zcross lt 0.) and (py gt thresh[0]), ncross)

      if (ncross eq 0) then begin
        fom = 0.
        Ep = 0.
        dE = 2.*dEmax
      endif else begin
        fom = fltarr(ncross)
        Ep = fom
        dE = replicate(2.*dEmax, ncross)
      endelse

      title = string(spec.sc_pot,format='("Potential = ",f5.1," V")')
      plot,px,py,xtitle='Potential (V)',ytitle='',$
                  xrange=xlim,/xsty,yrange=ylim,/ysty,charsize=csize2
      xyouts,0.12,0.44,'dF/dE',/norm,orient=90,align=0.5,charsize=csize2,color=5
      xyouts,0.12,0.53,'or',/norm,orient=90,align=0.5,charsize=csize2
      xyouts,0.12,0.63,'d!u2!nF/dE!u2!n',/norm,orient=90,align=0.5,charsize=csize2,color=4
;     oplot,[spec.sc_pot,spec.sc_pot],ylim,line=2,color=6
      oplot,px,py,color=5
      oplot,px,py2,color=4
      oplot,xlim,[0,0],line=2
      oplot,xlim,[thresh,thresh],line=2,color=1
      oplot,replicate(min(Espan),2),ylim,line=1
      oplot,replicate(max(Espan),2),ylim,line=1

      for i=0,(ncross-1) do begin
;        k = max(indx)       ; lowest energy feature above threshold
;        pymax = max(py,k0)  ; largest slope feature above threshold
;        k = k0

        k = indx[i]
        pymax = py[k]    ; peak
        pymin = pymax/2. ; half max

        while ((py[k] gt pymin) and (k lt n_e-1)) do k++
        kmax = k
        k = indx[i]
        while ((py[k] gt pymin) and (k gt 0)) do k--
        kmin = k
        k = indx[i]

        dE[i] = px[kmin] - px[kmax]  ; feature width
        oplot,[px[kmin],px[kmax]],[pymin,pymin],color=2
        if (kmin eq 0) then dE[i] = 2.*dEmax

        fom[i] = (pymax^1.5)*(px[k]/dE[i])
        Ep[i] = px[k]
        oplot,[px[k],px[k]],ylim,color=2
      endfor

      jndx = where((fom gt 0.) and (dE lt dEmax), count)
      if (count gt 0L) then begin
        fom = fom[jndx]
        Ep = Ep[jndx]
        indx = indx[jndx]

        k = where(Ep lt 10., nk)  ; Look for multiple features below 10 eV.
        if (nk gt 1) then begin   ; If more than one, drop lowest energy feature.
          k = count - 2           ; This accounts for shape to the s/c photoelectron spectrum.
          fom = fom[0:k]
          Ep = Ep[0:k]
          indx = indx[0:k]
        endif
        fmax = max(fom,i)
        k = indx[i]
        phi = px[k]*(1. + (bias*0.1236))
        oplot,[phi,phi],ylim,color=6,line=2
        xyouts,xs,ys,string(phi,format='("V = ",f6.2)'),color=6,charsize=csize0,/norm
        ys -= dys
        xyouts,xs,ys,string(dE[jndx[i]],format='("dE = ",f5.2)'),charsize=csize0,/norm
        ys -= dys
      endif else begin
        xyouts,xs,ys,"V = NaN",color=6,charsize=csize0,/norm
        ys -= dys
        xyouts,xs,ys,"dE = NaN",charsize=csize0,/norm
        ys -= dys
      endelse

      xyouts,xs,ys,string(dEmax,format='("dEmax = ",f4.2)'),charsize=csize0,/norm
      ys -= dys

      xyouts,xs,ys,string(bias,format='("bias = ",f5.2)'),charsize=csize0,/norm
      ys -= dys

      xyouts,xs,ys,string(thresh,format='("thresh = ",f4.2)'),charsize=csize0,color=1,/norm
      ys -= dys

      wset, Fwin
      if (count gt 0) then begin
        nfom = fom/max(fom,j)
        plot_io,[px[indx]],[nfom],psym=8,xtitle="Potential (V)",ytitle="Figure of Merit",$
                xrange=xlim,/xsty,yrange=[0.02,2.0],/ysty,charsize=csize2,symsize=1.5
        oplot,[px[indx]],[nfom],psym=8,symsize=1.5,color=3
        oplot,[px[indx[j]]],[nfom[j]],psym=8,symsize=1.5,color=6
      endif else begin
        plot_io,[-1.,-1.],[tiny,tiny],psym=8,xtitle="Potential (V)",ytitle="Figure of Merit",$
                xrange=xlim,/xsty,yrange=[0.02,2.0],/ysty,charsize=csize2,symsize=1.5
      endelse

    endif

; Print out housekeeping in another window

    if (hflg) then begin
      wset, Hwin
      
      csize = 1.4
      x1 = 0.05
      x2 = 0.75
      x3 = x2 - 0.12
      y1 = 0.95 - 0.034*findgen(28)
  
      fmt1 = '(f7.2," V")'
      fmt2 = '(f7.2," C")'
      fmt3 = '(i2)'
      fmt4 = '(Z2.2)'
      
      j = jref

      k = swe_hsk[j].ssctl
      if (k lt 4) then begin
        chksum = swe_hsk[j].chksum[k]
        tabnum = mvn_swe_tabnum(chksum)
      endif else begin
        chksum = 'FF'x
        tabnum = -1
      endelse

      erase
      xyouts,x1,y1[0],/normal,"SWEA Housekeeping",charsize=csize
      xyouts,x1,y1[1],/normal,time_string(swe_hsk[j].time),charsize=csize
      xyouts,x1,y1[3],/normal,"P28V",charsize=csize
      xyouts,x2,y1[3],/normal,string(swe_hsk[j].P28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[4],/normal,"MCP28V",charsize=csize
      xyouts,x2,y1[4],/normal,string(swe_hsk[j].MCP28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[5],/normal,"NR28V",charsize=csize
      xyouts,x2,y1[5],/normal,string(swe_hsk[j].NR28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[6],/normal,"MCPHV",charsize=csize
      xyouts,x2,y1[6],/normal,string(sigfig(swe_hsk[j].MCPHV,3),format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[7],/normal,"NRV",charsize=csize
      xyouts,x2,y1[7],/normal,string(swe_hsk[j].NRV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[9],/normal,"P12V",charsize=csize
      xyouts,x2,y1[9],/normal,string(swe_hsk[j].P12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[10],/normal,"N12V",charsize=csize
      xyouts,x2,y1[10],/normal,string(swe_hsk[j].N12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[11],/normal,"P5AV",charsize=csize
      xyouts,x2,y1[11],/normal,string(swe_hsk[j].P5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[12],/normal,"N5AV",charsize=csize
      xyouts,x2,y1[12],/normal,string(swe_hsk[j].N5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[13],/normal,"P5DV",charsize=csize
      xyouts,x2,y1[13],/normal,string(swe_hsk[j].P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[14],/normal,"P3P3DV",charsize=csize
      xyouts,x2,y1[14],/normal,string(swe_hsk[j].P3P3DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[15],/normal,"P2P5DV",charsize=csize
      xyouts,x2,y1[15],/normal,string(swe_hsk[j].P2P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[17],/normal,"ANALV",charsize=csize
      xyouts,x2,y1[17],/normal,string(swe_hsk[j].ANALV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[18],/normal,"DEF1V",charsize=csize
      xyouts,x2,y1[18],/normal,string(swe_hsk[j].DEF1V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[19],/normal,"DEF2V",charsize=csize
      xyouts,x2,y1[19],/normal,string(swe_hsk[j].DEF2V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[20],/normal,"V0V",charsize=csize
      xyouts,x2,y1[20],/normal,string(swe_hsk[j].V0V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[22],/normal,"ANALT",charsize=csize
      xyouts,x2,y1[22],/normal,string(swe_hsk[j].ANALT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[23],/normal,"LVPST",charsize=csize
      xyouts,x2,y1[23],/normal,string(swe_hsk[j].LVPST,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[24],/normal,"DIGT",charsize=csize
      xyouts,x2,y1[24],/normal,string(swe_hsk[j].DIGT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[26],/normal,"SWEEP TABLE",charsize=csize
      xyouts,x2,y1[26],/normal,string(tabnum,format=fmt3),charsize=csize,align=1.0
      xyouts,x1,y1[27],/normal,"CHECKSUM",charsize=csize
      xyouts,x2,y1[27],/normal,string(chksum,format=fmt4),charsize=csize,align=1.0
    endif

; Get the next button press

    nplot++

    if (~tsflg) then begin
      wset,Twin
      trange = 0
      ctime,trange,npoints=npts,/silent
      if (npts gt 1) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released

      if (size(trange,/type) eq 5) then begin
  
        if (dosmo) then begin
          tmin = min(trange, max=tmax)
          trange = [(tmin - dtsmo), (tmax + dtsmo)]
        endif

        if (tflg) then begin
          if (finite(scp)) then pot = scp else pot = 0.

          if ((npts eq 1) and (~dosmo)) then begin
            dt = min(abs(trange[0] - tspec.time), i)
            spec = {time:tspec.time[i], data:reform(tspec.data[i,*]), $
                    energy:tspec.energy, units_name:tspec.units_name, $
                    sc_pot:pot, var:reform(tspec.var[i,*])}
          endif else begin
            tmin = min(trange, max=tmax)
            i = where((tspec.time ge tmin) and (tspec.time le tmax), nspec)
            if (nspec gt 0L) then begin
              dat = tspec.data[i,*]
              var = tspec.var[i,*]
              nrm = dat
              nrm[*] = 1.
              bndx = where(~finite(dat), count)
              if (count gt 0L) then begin
                nrm[bndx] = 0.
                var[bndx] = !values.f_nan
              endif
              nrm = total(nrm, 1)/float(nspec)

              avg = total(dat[i,*], 1, /nan)/nrm
              var = total(var[i,*], 1, /nan)/nrm

              spec = {time:mean(tspec.time[i]), data:avg, var:var, energy:tspec.energy, $
                      units_name:tspec.units_name, sc_pot:pot}
            endif
          endelse
        endif else begin
          spec = mvn_swe_getspec(trange, /sum, archive=aflg, units=units, yrange=yrange, qlevel=qlevel)
          if (size(spec,/type) ne 8) then begin
            spec = badspec
            spec.time = mean(trange)
            spec.end_time = max(trange)
            spec.quality = 255B
          endif
          if (finite(scp)) then pot = scp $
                           else if (finite(spec.sc_pot)) then pot = spec.sc_pot else pot = 0.
          spec.sc_pot = pot
          dt = min(abs(spec.time - mvn_swe_engy.time),i)
          endx = [endx,i]
        endelse

        if (spflg) then begin
          if (stregex(units,'flux',/boo,/fold)) then begin
            mvn_swe_convert_units, spec, 'df'
            spec.energy -= pot
            mvn_swe_convert_units, spec, units
          endif else spec.energy -= pot
        endif

        rate = spec
        mvn_swe_convert_units, rate, 'rate'
        rate = rate.data

        if (fflg) then yrange = drange
        if keyword_set(frange) then yrange = frange
        if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)
      endif else ok = 0
    endif else ok = 0

  endwhile

  if keyword_set(mkpng) then begin
      if ~keyword_set(figname) then figname='~/'
      makepng,figname+'_espec',wi=Ewin      
  endif

  if (kflg) then begin
    wdelete, Ewin
    if (hflg) then wdelete, Hwin
    if (pflg) then begin
      wdelete, Pwin
      wdelete, Fwin
    endif
    if (doder) then wdelete, Dwin
  endif

  wset, Twin
  if ((ctab ne pct) or (crev ne prev)) then initct, pct, reverse=prev
  if (max(abs(lines - plines)) gt 0) then line_colors, plines

end
