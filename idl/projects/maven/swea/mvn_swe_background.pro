; Fitting function for SWEA penetrating particle and radioactive decay background.
;
; background = (penetrating particle)*(1 - Mars shielding) + radioactive decay
;
;   h   = spacecraft altitude (km)
;   a   = penetrating particle background for zero Mars shielding
;   k40 = background from radioactive decay of potassium 40
;
; Assumption: The GCR flux and the penetrating SEP flux (when present)
;   would be isotropic if Mars were not present.  This may sometimes be a
;   bad assumption for SEPs.
;
; Note: The GCR energy spectrum peaks at ~300 MeV.  The part that varies with 
;   the solar cycle is below ~1 GeV.  SEPs are softer (lower energy), typically
;   peaking aroung 1 MeV and falling with a power law at higher energies.

function swe_background, h,  parameters=p,  p_names=p_names, pder_values=pder_values

  if not keyword_set(p) then p = {func:'swe_background', a:1D, k40:0D}

  if n_params() eq 0 then return, p

  Rm = 3389.5D                        ; +/- 0.2, volumetric radius of Mars (km)
  sina = Rm/(Rm + h)                  ; sine of half-angle subtended by Mars
  y = (1D - sqrt(1D - sina*sina))/2D  ; fraction of sky blocked by Mars
  f = p.a*(1D - y) + p.k40            ; background vs. altitude

  if keyword_set(p_names) then begin
     np = n_elements(p_names)
     nd = n_elements(f)
     pder_values = dblarr(nd,np)
     for i=0,np-1 do begin
        case strupcase(p_names(i)) of
            'A'   : pder_values[*,i] = 1D - y
            'K40' : pder_values[*,i] = 1D
        endcase
     endfor
  endif

  return, f

end

;+
;PROCEDURE:   mvn_swe_background
;PURPOSE:
;  At energies above ~1 keV, the SWEA count rate comes from three
;  sources:  >1-keV electrons, penetrating high-energy particles, and
;  radioactive decay of potassium 40 in the MCP glass.  Often, the
;  background from penetrating particles and radioactive decay dominates
;  the signal, so it is essential to remove this background to obtain
;  reliable measurements of the >1-keV electron component.
;
;  Protons with energies above ~20 MeV and electrons with energies above
;  ~2 MeV can penetrate the instrument housing and internal walls to pass
;  through the MCP, where they can trigger electron cascades and generate
;  counts.  Lower energy electrons can partially penetrate and generate
;  bremsstrahlung x-rays by interacting with the instrument's aluminum
;  walls.  The x-rays can then penetrate to the MCP and trigger counts.
;  Galactic Cosmic Rays (GCRs) peak near 1 GeV and easily pass through the
;  instrument (and the entire spacecraft), resulting in a background count 
;  rate of several counts per second summed over all anodes.  GCR's are 
;  isotropic, but Mars effectively shields part of the sky.  Since MAVEN's
;  orbit is elliptical, the GCR background varies along the orbit according
;  to the changing angular size of the planet.  SEP events are episodic, 
;  but can increase the penetrating particle background by orders of 
;  magnitude for days.
;
;  Since penetrating particles bypass SWEA's optics, they result in a
;  constant count rate across SWEA's energy range.  The GCR background is
;  ~1 count/sec/anode, varying by a factor of three over the solar cycle.
;  Penetrating background can be identified by a constant count rate in
;  SWEA's highest energy channels.  However, there are times when < 4.6 keV
;  electrons are present at the same time as penetrating particles.  This
;  is particularly true during SEP events.  When this happens, this routine
;  will overestimate the background, so it may be necessary to fit the 
;  measured signal with a model that includes contributions from >1-keV
;  electrons, penetrating particles, and radioactive decay.
;
;  Potassium 40 has a half-life of ~1 billion years, so it generates a 
;  constant background.  This part of the background does not vary along 
;  the orbit, so it can in principle be separated from the GCR background.
;  One good measurement of the potassium 40 background can be used for
;  the entire mission.
;
;  This routine estimates the penetrating particle background when the
;  highest four energy channels (3.3 to 4.6 keV) exhibit a constant count
;  rate.  If there is any slope in this energy range, then you should not
;  use this routine, but instead do a 3-parameter fit to the measurements.
;
;  This routine requires SPICE.
;
;USAGE:
;  mvn_swe_background
;
;INPUTS:
;  None.       SPEC data are obtained from the SWEA common block.
;
;KEYWORDS:
;  K40:        If set, then fit for the radioactive decay background in
;              addition to the penetrating particle background.
;              Default = 0 (no).
;
;  NBINS:      Number of altitude bins for the >3.3-keV count rate data.
;              Default = 30.
;
;  MAXALT:     Set this keyword to the maximum altitude to include in the
;              fit.  Use this to base the fit solely on periapsis passes.
;              Reduce NBINS to maintain a reasonable number of points per
;              bin.  You may also need to load 3+ days of data to obtain
;              good statistics.  This keyword can be useful during SEP
;              events.  
;
;  INCLUDE:    If set, interactively include one or more time ranges for
;              the fit.  This can be used to select times when the >3.3-keV
;              count rate is constant.  Disabled when EXCLUDE is set.
;
;  EXCLUDE:    If set, interactively exclude one or more time ranges from
;              the fit.  This can be used to exclude times when the >3.3-keV
;              count rate is not constant.  Takes precedence over INCLUDE.
;
;  MASK:       Returns the mask used to select which data to use in the fit.
;              (0 = exclude, 1 = include).  You can also set this keyword to
;              a previous mask to make additional edits.
;
;  ORBIT:      Mask data orbit by orbit.  Useful in combination with INCLUDE
;              and EXCLUDE during a SEP event, when the GCR background can 
;              only be measured at periapsis on closed or deeply draped field
;              lines.  (Open field lines must be masked.)
;
;  RESULT:     Returns the fitted/assumed results:
;                time    = center time of loaded data
;                trange  = time range of loaded data
;                alt     = altitude bins
;                data    = average >3.3-keV count rate in each bin
;                sdev    = statistical uncertainty
;                npts    = number of points in each bin
;                model   = count rate vs. altitude for best fit
;                units   = data, sdev, model units ('CRATE')
;                a       = penetrating background count rate corresponding
;                          to zero shielding from Mars (alt -> infinity)
;                a_sigma = uncertainty in a
;                k40     = count rate from radioactive decay of potassium 40
;                          in the MCP glass
;                k40_sigma = uncertainty in k40 (if applicable)
;
;  RESIDUAL:   Show the residual (measured background - model) in the tplot
;              window.  Default = 0 (no).
;
;  SHOWFIT:    If set, show the fit results in a separate window.  The top
;              panel shows the binned count rate vs. altitude along with the
;              best fit.  The next two panels show the number of samples per
;              bin and the Poisson correction.  Default = 0 (no).
;
;  RESET:      Force a new altitude calculation.
;
;SEE ALSO:
;   mvn_swe_secondary:  Calculates the secondary electron background.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-08-12 09:49:16 -0700 (Mon, 12 Aug 2024) $
; $LastChangedRevision: 32788 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_background.pro $
;
;CREATED BY:    David L. Mitchell  07-05-24
;FILE: mvn_swe_background.pro
;-
pro mvn_swe_background, k40=k40, residual=residual, result=result, nbins=nbins, $
                        maxalt=maxalt, exclude=exclude, include=include, mask=mask, $
                        orbit=orbit, showfit=showfit, reset=reset

  @mvn_swe_com
  common swe_bkg_com, tspan, h, fwin, fdim

; Make sure data and ephemeris exist

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print, "You must load SWEA SPEC data first.", format='(/,a,/)'
    return
  endif

  mvn_spice_stat, check=mvn_swe_engy.time, summary=sinfo, /silent
  if (sinfo.spk_check eq 0) then begin
    print,"Insufficient SPICE SPK coverage for SWEA SPEC data.",format='(/,a)'
    print,"   SPEC: ",time_string(minmax(spec.time)),format='(a,a19," - ",a19)'
    print,"    SPK: ",time_string(sinfo.spk_trange),format='(a,a19," - ",a19)'
    print,"Reinitialize SPICE and try again.",format='(a,/)'
    return
  endif

; Process keywords

  k40 = keyword_set(k40)
  res = keyword_set(residual)
  nbins = (n_elements(nbins) gt 0) ? fix(nbins[0]) : 30
  maxalt = (n_elements(maxalt) gt 0) ? double(maxalt[0]) : 10000D
  exclude = keyword_set(exclude)
  include = keyword_set(include) and ~exclude
  orbit = keyword_set(orbit)
  nmask = n_elements(mask)
  showfit = keyword_set(showfit)
  reset = keyword_set(reset)

; Prepare SPEC data for analysis

  spec = mvn_swe_engy                                ; get SPEC data from the common block
  nspec = n_elements(spec)
  tmax = max(spec.time)
  spec.bkg = 0.                                      ; clear the background array
  mvn_swe_secondary, spec                            ; calculate secondary contamination
  old_units = spec[0].units_name                     ; remember the original units
  mvn_swe_convert_units, spec, 'crate'               ; convert units to corrected count rate
  bkg = average(spec.data[0:3,*], 1, /nan)           ; estimate penetrating particle background
  bkgs = smooth_in_time(bkg, spec.time, 64)          ; smooth in time by 64 sec (32 spectra)
  store_data, 'swe_bkg', data={x:spec.time, y:bkgs}  ; make a tplot variable of smoothed data
  options, 'swe_bkg', 'ytitle', 'CRATE (>3.3 keV)'
  options, 'swe_bkg', 'datagap', 16D
  if (nmask ne nspec) then store_data, 'swe_bkg_mask', data={x:minmax(spec.time), y:replicate(!values.f_nan,2)}
  options, 'swe_bkg_mask', 'datagap', 16D

; Choose a graphics window.  Make one if necessary.

  device, window_state=ws
  tplot_options, get=topt
  str_element, topt, 'window', i, success=ok
  if (ok) then begin
    if (ws[i]) then wset, i else win, i, /center
  endif else if (~max(ws)) then win, 0, /center
  twin = !d.window

; Determine which panels to plot.  Make sure swe_bkg is on the list.

  wset, twin
  str_element, topt, 'varnames', varnames, success=ok
  if (not ok) then begin
    mvn_swe_sumplot, /load
    tplot, ['alt2','swe_bkg','swe_a4']
  endif else begin
    i = where(strmatch(topt.varnames, 'swe_bkg*'), count)
    if (count gt 0) then tplot, trange=topt.trange_full else tplot, 'swe_bkg', add=-1, trange=topt.trange_full
  endelse

; Get altitude if necessary

  if (n_elements(tspan) eq 2) then begin
    getalt = (max(abs(minmax(spec.time) - tspan)) ne 0D) or $
             (n_elements(spec.time) ne n_elements(h)) or reset
  endif else getalt = 1B

  if (getalt) then begin
    pos = spice_body_pos('Mars', 'MAVEN', ut=spec.time, frame='IAU_MARS', check='MAVEN')
    mvn_altitude, cart=pos, datum='ell', result=dat
    h = dat.alt
    tspan = minmax(spec.time)
    undefine, pos, dat
  endif

; Select data for the fit

  if (orbit) then skip, /first, /apo
  tplot_options, get=topt
  keepgoing = 1

  while (keepgoing) do begin

    if (exclude) then begin
      if (nmask ne nspec) then begin
        mask = replicate(1B, nspec)
        nmask = nspec
      endif
      ok = 1
      print, "Select time range(s) to exclude from the fit (right click to exit) ... "
      while (ok) do begin
        undefine, tt
        ctime, tt, npoints=2, /silent
        cursor,cx,cy,/norm,/up  ; make sure mouse button is released
        if (n_elements(tt) gt 1) then begin
          indx = where(spec.time ge min(tt) and spec.time le max(tt), count)
          if (count gt 0L) then begin
            mask[indx] = 0B
            timebar, min(tt), line=2, color=4
            timebar, max(tt), line=2, color=6
          endif
        endif else ok = 0
      endwhile
    endif

    if (include) then begin
      if (nmask ne nspec) then begin
        mask = replicate(0B, nspec)
        nmask = nspec
      endif
      ok = 1
      print, "Select time range(s) to include for the fit (right click to exit) ... "
      while (ok) do begin
        undefine, tt
        ctime, tt, npoints=2, /silent
        cursor,cx,cy,/norm,/up  ; make sure mouse button is released
        if (n_elements(tt) gt 1) then begin
          indx = where(spec.time ge min(tt) and spec.time le max(tt), count)
          if (count gt 0L) then begin
            mask[indx] = 1B
            timebar, min(tt), line=2, color=4
            timebar, max(tt), line=2, color=6
          endif
        endif else ok = 0
      endwhile
    endif

    if (orbit) then begin
      skip
      tplot_options, get=topt
      if (topt.trange[0] gt tmax) then keepgoing = 0
    endif else keepgoing = 0
  endwhile

  if (orbit) then tlimit,/full

; Altitude mask

  if (nmask ne nspec) then begin
    mask = replicate(1B, nspec)
    nmask = nspec
  endif
  indx = where(h gt maxalt, count)
  if (count gt 0L) then mask[indx] = 0B

; Bin and fit the measurements

  indx = where(mask eq 1B, count)
  if (count eq 0) then begin
    print, "All data masked.  No data to fit."
    return
  endif

  bindata, h[indx], bkg[indx], xbins=nbins, result=dat

  p = swe_background()
  if (k40) then names = 'a k40' else names = 'a'
  fit, dat.x, dat.y, dy=dat.sdev, param=p, names=names, function='swe_background', $
                         p_values=pval, p_sigma=psig
  yfit = swe_background(dat.x, param=p)

; Plot the fit results

  if (showfit) then begin
    makewin = 1
    if (n_elements(fwin) gt 0) then if (ws[fwin]) then begin
      wset, fwin
      makewin = !d.x_size ne fdim
    endif

    if (makewin) then begin
      win, /free, /sec, dx=10, xsize=800, ysize=1000, /yfull
      fwin = !d.window
      fdim = !d.x_size
    endif else wset, fwin

    !x.omargin = [2,4]
    !p.multi = [0,1,3]  ; starting panel, number of columns, number of rows
      csize = 3.0
      lsize = 1.6
      xrange = [0., ceil(max(dat.x)/1000.)*1000.]
      yrange = [floor(10.*min(dat.y) - 1.), ceil(10.*max(dat.y) + 1.)]/10.
      plot, dat.x, dat.y, psym=10, xtitle='', ytitle='Count Rate (>3.3 keV)', yrange=yrange, /ysty, $
            title='Penetrating Background', charsize=csize, xrange=xrange, /xsty
      oplot, dat.x, yfit, color=4, thick=2

      dys = 0.08*(yrange[1] - yrange[0])*(1440./float(!d.y_size))
      xs = mean(xrange)
      ys = median(yfit) - 1.5*dys
      msg = 'Rate(alt -> !4y!1H) = ' + string(pval[0],format='(f4.2)') + ' +/- ' + string(psig[0],format='(f5.2)')
      xyouts, xs, ys, strcompress(msg) , /data, charsize=lsize, color=4
      ys -= dys

      msg = 'K40 = ' + string(p.k40,format='(f5.2)')
      if (n_elements(psig) gt 1) then msg += ' +/- ' + string(psig[1],format='(f5.2)') else msg += ' (assumed)'
      xyouts, xs, ys, strcompress(msg) , /data, charsize=lsize, color=4
      ys -= dys

      plot_io, dat.x, float(dat.npts), psym=10, xtitle='', ytitle='Number', $
            title='Number of Samples', charsize=csize, xrange=xrange, /xsty

      plot_io, dat.x, 0.5/(dat.y * dat.npts), psym=10, xtitle='Altitude (km)', $
            ytitle='Correction', title='Poisson Correction', charsize=csize, xrange=xrange, /xsty
    !p.multi = 0
    !x.omargin = [0,0]
  endif

; Create the result structure

  trange = minmax(spec.time)
  k40_sigma = (n_elements(psig) gt 1) ? psig[1] : !values.d_nan

  result = {time:mean(trange), trange:trange, alt:dat.x, data:dat.y, sdev:dat.sdev, npts:dat.npts, $
            model:yfit, units:'CRATE', a:p.a, a_sigma:psig[0], k40:p.k40, k40_sigma:k40_sigma}

; Create/update tplot variables

  bkg_model = swe_background(h, param=p)
  vname = 'swe_bkg_model'
  store_data, vname, data={x:spec.time, y:bkg_model}
  options, vname, 'line_colors', 5
  options, vname, 'colors', [6]
  options, vname, 'thick', 2

  vname = 'swe_bkg_mask'
  mndx = where(mask eq 0B, count)
  if (count gt 0L) then mdat = {x:spec[mndx].time, y:bkgs[mndx]} $
                   else mdat = {x:minmax(spec.time), y:replicate(!values.f_nan,2)}
  store_data, vname, data=mdat
  options, vname, 'datagap', 16D

  vname = 'swe_bkg_comp'
  store_data, vname, data=['swe_bkg','swe_bkg_mask','swe_bkg_model']
  ylim, vname, 0, 5, 0
  options, vname, 'ytitle', 'CRATE (>3.3 keV)'
  options, vname, 'line_colors', 5
  options, vname, 'colors', [4,2,6]
  options, vname, 'labels', ['data','mask','model']
  options, vname, 'labflag', 1
  if (k40 gt 0.) then begin
    options, vname, 'constant', k40
    options, vname, 'const_line', 2
    options, vname, 'const_color', 5
    options, vname, 'const_thick', 2
  endif else begin
    options, vname, 'constant', -1.
  endelse

  tplot_options, get=topt
  varnames = topt.varnames
  imax = n_elements(varnames) - 1
  i = where(varnames eq 'swe_bkg', count)
  if (count gt 0) then varnames[i] = vname
  i = where(varnames eq vname, count)
  if (count eq 0) then begin
    firstvars = [varnames[0:i], vname]
    if (i lt imax) then varnames = [firstvars, varnames[(i+1):imax]]
  endif

  vname = 'swe_bkg_residual'
  store_data,vname,data={x:spec.time, y:(bkgs - bkg_model)}
  options,vname, 'ytitle', 'Residual'
  options,vname, 'constant', 0
  options,vname, 'line_colors', 5
  options,vname, 'const_color', 6
  options,vname, 'const_line', 0
  options,vname, 'const_thick', 2

  if (res) then begin
    j = where(varnames eq vname, count)
    if (count eq 0) then begin
      imax = n_elements(varnames) - 1
      firstvars = [varnames[0:i], vname]
      if (i lt imax) then varnames = [firstvars, varnames[(i+1):imax]]
    endif
  endif

  wset, twin
  tplot, varnames                                ; display the measured background and model

; Save the result

  spec.bkg += replicate(1.,64) # bkg_model       ; sum secondary and penetrating bkgs
  mvn_swe_convert_units, spec, old_units         ; convert back to original units
  mvn_swe_engy = temporary(spec)                 ; store the result in the common block

end
