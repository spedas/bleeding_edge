;+
;PROCEDURE:   mvn_sta_cio_plot
;PURPOSE:
;
;USAGE:
;  mvn_sta_cio_plot, ptr, KEYWORD=value, ...
;
;INPUTS:
;       ptr:        A pointer to the cold ion data structure, which
;                   is obtained with 'mvn_sta_cio_load'.
;
;KEYWORDS:
;       OPTIONS:    Structure of options for selecting variables and binning
;                   parameters.  Recognized options (tags) are:
;
;           PVAR:       Parameter to plot.  Can be one of:
;
;                         'den_i'  -> ion density
;                         'den_e'  -> electron density
;                         'temp'   -> ion temperature
;                         'vbulk'  -> ion bulk velocity
;                         'vratio' -> ratio of ion bulk velocity to escape velocity
;                         'voratio' -> ratio of O2+ to O+ bulk velocity
;                         'fbulk'  -> ion bulk flux (den_i * vbulk)
;                         'vel_x'  -> ion velocity X component
;                         'vel_y'  -> ion velocity Y component
;                         'vel_z'  -> ion velocity Z component
;                         'energy' -> ion bulk kinetic energy
;                         'VB_phi' -> angle between V and B
;
;           XVAR:       Parameter for the X variable.  Can be one of:
;
;                         'time'  -> time               (UT/SCET)
;                         'mso_x' -> MSO X              (Rm)
;                         'mso_y' -> MSO Y              (Rm)
;                         'mso_z' -> MSO Z              (Rm)
;                         'mso_r' -> MSO R              (Rm)
;                         'sza'   -> solar zenith angle (degrees)
;                         'alt'   -> altitude           (km)
;                         'slon'  -> subsolar longitude (degrees)
;                         'slat'  -> subsolar latitude  (degrees)
;
;           YVAR:       Parameter for the Y variable (see XVAR).  You must
;                       specify at least one of XVAR and YVAR.  If only one
;                       of these keywords is set, the binned PARAM is plotted
;                       versus XVAR or YVAR.  If both are set, then a color
;                       spectrogram of PVAR versus XVAR and YVAR is plotted.
;                       YVAR cannot be 'time'.
;
;           XBINS:      Number of bins for the X variable.  A reasonable
;                       default based on XVAR is provided.
;
;           YBINS:      Number of bins for the Y variable.  A reasonable
;                       default based on YVAR is provided.
;
;           XSPAN:      Range for binning the X variable.  A reasonable
;                       default based on XVAR is provided.  This is not
;                       the same as the X plot limits, which you specify
;                       in the LIMITS keyword.
;
;           YSPAN:      Range for binning the Y variable.  A reasonable
;                       default based on YVAR is provided.  This is not
;                       the same as the Y plot limits, which you specify
;                       in the LIMITS keyword.
;
;           STYPE:      Statistics to plot: 'mean' or 'median'.
;
;           MTYPE:      Which moment to plot:
;                         'sdev' : sdev/mean  (default)
;                         'skew' : skewness
;                         'kurt' : kurtosis
;                         'adev' : adev/mean
;
;           MINSAM:     Minimum number of samples per cell.  Cells that
;                       contain fewer samples than this are not included
;                       in the results.
;
;           VVEC:       Overplots projections of the bulk velocity vectors in
;                       the XVAR-YVAR plane.  Set this keyword to the scale
;                       factor (Rm/km/s).  Only works when PVAR is set and 
;                       XVAR and YVAR are any two of MSO_X, MSO_Y, and MSO_Z.
;                       Using this keyword with MSO_R (cylindrical coordinates)
;                       is misleading!
;
;           VSKIP:      Bin spacing between vectors in x and y directions.
;                       Default = [1,1], i.e., every bin gets a vector.
;
;           VBAR:       Three element array specifying the length (km/s), and
;                       position (XVAR, YVAR) for a velocity scale bar.
;
;       DATA:       A named variable to hold the average, median and
;                   standard deviation of PARAM versus XVAR and/or YVAR.
;                   The sampling (number of points per cell) is also
;                   provided.  Finally, a copy of the filter definition
;                   is included.
;
;       DST:        Save the distributions for each bin in DATA.  Then use
;                   mvn_sta_cio_snap to view them.
;
;       DOPLOT:     Plot PVAR vs. XVAR and/or YVAR.
;                   Set this keyword to the IDL window number where you
;                   want the plot to appear (1 to 31).  The window size
;                   is set to keep Mars round.
;
;       DOSAMP:     Plot the sampling function vs. XVAR and/or YVAR.
;                   Set this keyword to the IDL window number where you
;                   want the plot to appear (1 to 31).  The window size
;                   is set to keep Mars round.
;
;       DOMOM:      Plot a moment of the distribution vs. XVAR and/or YVAR.
;                   Set this keyword to the IDL window number where you
;                   want the plot to appear (1 to 31).  The window size
;                   is set to keep Mars round.
;
;       DOALL:      Put the parameter, sampling, and rms/mean plots on a
;                   single page.  Also includes a panel of text with
;                   filter settings.  Set this keyword to the IDL window
;                   number where you want the plot to appear (1 to 31).
;
;       FILTER:     Set this flag to a structure defining a filter.  See
;                   mvn_sta_cio_filter for more information.  If not set,
;                   then no filter is applied, even if it is present in 
;                   the CIO data structure.
;
;       LIMITS:     Structure of plotting options.  You can specify any
;                   option(s) accepted by PLOT.  Reasonable defaults are
;                   provided for all unspecified options.  To interpolate
;                   the binned distribution function (not recommended), set
;                   the tag 'no_interp' to zero.
;
;       ZLIMITS:    Sampling plot Z limits, with 2 to 4 elements:
;
;                           [zmin, zmax, zlog, zticks]
;
;                   By default, the sampling plot has the same X and Y 
;                   limits and plotting options as the parameter plot
;                   (as controlled by LIMITS).  Reasonable defaults are
;                   provided for the Z axis, but you can override them
;                   with this keyword.
;
;       RLIMITS:    RMS/Mean plot Z limits, with 2 to 4 elements:
;
;                           [rmin, rmax, rlog, rticks]
;
;                   By default, the rms/mean plot has the same X and Y 
;                   limits and plotting options as the parameter plot
;                   (as controlled by LIMITS).  Reasonable defaults are
;                   provided for the Z axis, but you can override them
;                   with this keyword.
;
;       WSCALE:     Scale factor for sizing windows.  Default = 1 for a
;                   an external monitor.  Use a smaller value for a laptop
;                   monitor.
;
;       EVEC:       Plot the convection electric field direction.
;                   Default = 1 (yes) if BCLK is among the data filters.
;
;       PNG:        Set this keyword to the full filename (including path)
;                   for outputting a png plot.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-04-07 15:27:02 -0700 (Mon, 07 Apr 2025) $
; $LastChangedRevision: 33238 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_plot.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_sta_cio_plot.pro
;-
pro mvn_sta_cio_plot, ptr, data=data, dst=dst, options=options, filter=filter, $
                      doplot=doplot, dosamp=dosamp, domom=domom, doall=doall, $
                      limits=ulimits, zlimits=zlimits, rlimits=rlimits, png=png, $
                      wscale=wscale, evec=evec

; Make sure inputs are reasonable

  if (size(ptr,/type) ne 10) then begin  
    print,'You must provide a pointer to the data.'
    return
  endif

  if (size(*ptr,/type) ne 8) then begin
    print,'Data pointer does not refer to a structure.'
    return
  endif

  tags = strupcase(tag_names(*ptr))

  dofilter = 0
  if (size(filter,/type) eq 8) then mvn_sta_cio_filter, ptr, filter, success=dofilter

  data = 0B

  if not keyword_set(wscale) then wscale = 1.

  xsize = 730.                   ; x dimension in pixels
  case (!d.name) of
    'X'   : begin
              aspect1 = 1.175  ; aspect ratio for 1x1 plot (x/y)
              aspect2 = 1.175  ; aspect ratio for 2x2 plot (x/y)
            end
    'WIN' : begin
              aspect1 = 1.175  ; aspect ratio for 1x1 plot (x/y)
              aspect2 = 1.175  ; aspect ratio for 2x2 plot (x/y)
            end
     else : begin
              aspect1 = 1.175  ; aspect ratio for 1x1 plot (x/y)
              aspect2 = 1.175  ; aspect ratio for 2x2 plot (x/y)
            end
  endcase

  dst = keyword_set(dst)

; Gather options

  if (size(options,/type) eq 8) then begin
    str_element, options, 'pvar', value, success=ok
    if (ok) then param = value else param = 0

    str_element, options, 'xvar', value, success=ok
    if (ok) then xvar = value else xvar = 0

    str_element, options, 'xspan', value, success=ok
    if (ok) then xspan = value else xspan = 0

    str_element, options, 'xbins', value, success=ok
    if (ok) then xbins = value else xbins = 0

    str_element, options, 'yvar', value, success=ok
    if (ok) then yvar = value else yvar = 0

    str_element, options, 'yspan', value, success=ok
    if (ok) then yspan = value else yspan = 0

    str_element, options, 'ybins', value, success=ok
    if (ok) then ybins = value else ybins = 0

    str_element, options, 'stype', value, success=ok
    if (ok) then stype = value else stype = 'mean'

    str_element, options, 'mtype', value, success=ok
    if (ok) then mtype = value else mtype = 'sdev'

    str_element, options, 'minsam', value, success=ok
    if (ok) then minsam = value else minsam = 0

    str_element, options, 'vvec', value, success=ok
    if (ok) then vvec = value else vvec = 0

    str_element, options, 'vskip', value, success=ok
    if (ok) then vskip = value

    str_element, options, 'vbar', value, success=ok
    if (ok) then vbar = value

    str_element, options, 'evec', value, success=ok
    if (ok) then evec = value
  endif

  if (size(evec,/type) eq 0) then evec = 1 else evec = keyword_set(evec)
  if (strupcase(yvar) ne 'MSO_Z') then evec = 0

  if ((not keyword_set(xvar)) and (not keyword_set(yvar))) then begin
    print,"You must specify X and/or Y variable names."
    return
  endif

  if keyword_set(param) then begin
    pvar = strupcase(param)
    indx = where(tags eq pvar, count)
    if (count eq 0L) then begin
      print,'Parameter "',pvar,'" not found in data structure!'
      return
    endif
    ptag = indx[0]
  endif else begin
    print,"You must specify a parameter to plot."
    return
  endelse

  if keyword_set(xvar) then begin
    xvar = strupcase(xvar)
    indx = where(tags eq xvar, count)
    if (count eq 0L) then begin
      print,'Variable "',xvar,'" not found in data structure!'
      return
    endif
    xtag = indx[0]
  endif else xvar = 'PARAM'

  if keyword_set(yvar) then begin
    yvar = strupcase(yvar)
    indx = where(tags eq yvar, count)
    if (count eq 0L) then begin
      print,'Variable "',yvar,'" not found in data structure!'
      return
    endif
    ytag = indx[0]
  endif else yvar = 'PARAM'

  if keyword_set(xspan) then begin
    if (n_elements(xspan) ne 2) then begin
      print,"XSPAN must have two elements.  Using default instead."
      xspan = 0
    endif else xspan = float(xspan)
  endif

  if keyword_set(yspan) then begin
    if (n_elements(yspan) ne 2) then begin
      print,"YSPAN must have two elements.  Using default instead."
      yspan = 0
    endif else yspan = float(yspan)
  endif

; Set plotting defaults for PARAM

  case (*ptr).mass of
     1 : species = 'H+'
    16 : species = 'O+'
    32 : species = 'O2+'
  endcase

  case strupcase(stype) of
    'MEAN'   : medflg = 0
    'MEDIAN' : medflg = 1
    else     : begin
                 print,"STYPE must be 'mean' or 'median'."
                 return
               end
  endcase

  if (medflg) then mode = 'Median ' else mode = 'Mean '

  case (pvar) of
    'DEN_I'  : begin
                 zlab = species + ' Density (1/cc)'
                 zmin = 0.1
                 zmax = 100.
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 1
               end
    'DEN_E'  : begin
                 zlab = 'e- Density (1/cc)'
                 zmin = 0.1
                 zmax = 100.
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 1
               end
    'TEMP'   : begin
                 zlab = species + ' Temp (eV)'
                 zmin = 1.
                 zmax = 200.
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 1
               end
    'VBULK'  : begin
                 zlab = species + ' Velocity (km/s)'
                 zmin = 2.
                 zmax = 100.
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 1
               end
    'VEL_R'  : begin
                 zlab = species + ' V_r (km/s)'
                 zmin = -100.
                 zmax = 100.
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 0
               end
    'VEL_PHI': begin
                 zlab = species + ' V_phi (deg)'
                 zmin = 0.
                 zmax = 360.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 0
                 zlog = 0
               end
    'VEL_THE': begin
                 zlab = species + ' V_the (deg)'
                 zmin = 90.
                 zmax = 180.
                 zrange = [zmin,zmax]
                 zt = 3
                 zm = 0
                 zlog = 0
               end
    'VRATIO' : begin
                 zlab = species + ' V/V_esc'
                 zmin = 0
                 zmax = 10
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 0
               end
    'FBULK'  : begin
                 zlab = species + ' Flux (cm-2 s-1)'
                 zmin = 1.e5
                 zmax = 1.e8
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 1
               end
    'FRADIAL': begin
                 zlab = species + ' Radial Flux (cm-2 s-1)'
                 zmin = -1.e8  ; radial in
                 zmax =  1.e8  ; radial out
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 0
               end
    'LOGFRAD': begin
                 zlab = species + ' Log Radial Flux (cm-2 s-1)'
                 zmin = -8  ; radial in
                 zmax =  8  ; radial out
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 0
               end
    'VEL_X'  : begin
                 zlab = species + ' V_x (km/s)'
                 zmin = -20.
                 zmax = 20.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 5
                 zlog = 0
               end
    'VEL_Y'  : begin
                 zlab = species + ' V_y (km/s)'
                 zmin = -20.
                 zmax = 20.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 5
                 zlog = 0
               end
    'VEL_Z'  : begin
                 zlab = species + ' V_z (km/s)'
                 zmin = -20.
                 zmax = 20.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 5
                 zlog = 0
               end
    'VEL_XE' : begin
                 zlab = species + ' V_x (km/s)'
                 zmin = -20.
                 zmax = 20.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 5
                 zlog = 0
               end
    'VEL_YE' : begin
                 zlab = species + ' V_y (km/s)'
                 zmin = -20.
                 zmax = 20.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 5
                 zlog = 0
               end
    'VEL_ZE' : begin
                 zlab = species + ' V_z (km/s)'
                 zmin = -20.
                 zmax = 20.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 5
                 zlog = 0
               end
    'ENERGY' : begin
                 zlab = species + ' Energy (eV)'
                 zmin = 1.
                 zmax = 1000.
                 zrange = [zmin,zmax]
                 zt = 0
                 zm = 0
                 zlog = 1
               end
    'VB_PHI' : begin
                 zlab = species + ' VB_phi (deg)'
                 zmin = 0.
                 zmax = 90.
                 zrange = [zmin,zmax]
                 zt = 3
                 zm = 0
                 zlog = 0
               end
    'VORATIO' : begin
                 zlab = 'V!dO!n / V!dO2!n'
                 zmin = 0.
                 zmax = 4.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 0
                 zlog = 0
               end
    'EORATIO' : begin
                 zlab = 'E!dO!n / E!dO2!n'
                 zmin = 0.
                 zmax = 4.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 0
                 zlog = 0
               end
    'NORATIO' : begin
                 zlab = 'N!dO!n / N!dO2!n'
                 zmin = 0.
                 zmax = 4.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 0
                 zlog = 0
               end
    'FORATIO' : begin
                 zlab = 'F!dO!n / F!dO2!n'
                 zmin = 0.
                 zmax = 4.
                 zrange = [zmin,zmax]
                 zt = 4
                 zm = 0
                 zlog = 0
               end
    else     : begin
                 print,"Unrecognized parameter: ",pvar
                 return
               end
  endcase

  tpflg = 0
  vxvar = ''
  vyvar = ''

  case (xvar) of
    'MSO_X' : begin
                if not keyword_set(xspan) then begin
                  xmin = -3.
                  xmax =  0.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'MSO X (R!dM!n)'
                xrange = [xmin,xmax]
                xt = 3
                xm = 2
                xlog = 0
                vxvar = 'VEL_X'
              end
    'MSO_Y' : begin
                if not keyword_set(xspan) then begin
                  xmin = -3.
                  xmax =  3.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'MSO Y (R!dM!n)'
                xrange = [xmin,xmax]
                xt = 6
                xm = 2
                xlog = 0
                vxvar = 'VEL_Y'
              end
    'MSO_Z' : begin
                if not keyword_set(xspan) then begin
                  xmin = -3.
                  xmax =  3.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'MSO Z (R!dM!n)'
                xrange = [xmin,xmax]
                xt = 6
                xm = 2
                xlog = 0
                vxvar = 'VEL_Z'
              end
    'MSO_S' : begin
                if not keyword_set(xspan) then begin
                  xmin = 0.
                  xmax = 3.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'MSO S (R!dM!n)'
                xrange = [xmin,xmax]
                xt = 3
                xm = 2
                xlog = 0
                vxvar = 'VEL_S'
              end
    'MSE_X' : begin
                if not keyword_set(xspan) then begin
                  xmin = -3.
                  xmax =  0.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'MSE X (R!dM!n)'
                xrange = [xmin,xmax]
                xt = 3
                xm = 2
                xlog = 0
                vxvar = 'VEL_XE'
              end
    'MSE_Y' : begin
                if not keyword_set(xspan) then begin
                  xmin = -3.
                  xmax =  3.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'MSE Y (R!dM!n)'
                xrange = [xmin,xmax]
                xt = 6
                xm = 2
                xlog = 0
                vxvar = 'VEL_YE'
              end
    'MSE_Z' : begin
                if not keyword_set(xspan) then begin
                  xmin = -3.
                  xmax =  3.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'MSE Z (R!dM!n)'
                xrange = [xmin,xmax]
                xt = 6
                xm = 2
                xlog = 0
                vxvar = 'VEL_ZE'
              end
    'SZA'   : begin
                if not keyword_set(xspan) then begin
                  xmin = 0.
                  xmax = 180.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 18
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'SZA (deg)'
                xrange = [xmin,xmax]
                xt = 6
                xm = 3
                xlog = 0
              end
    'ALT'   : begin
                if not keyword_set(xspan) then begin
                  xmin = 1000.
                  xmax = 7000.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'Altitude (km)'
                xrange = [xmin,xmax]
                xt = 6
                xm = 2
                xlog = 0
              end
    'SLON'  : begin
                if not keyword_set(xspan) then begin
                  xmin = 0.
                  xmax = 360.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'Solar Longitude (deg)'
                xrange = [xmin,xmax]
                xt = 4
                xm = 3
                xlog = 0
              end
    'SLAT'  : begin
                if not keyword_set(xspan) then begin
                  xmin = -30.
                  xmax =  30.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 24
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'Solar Latitude (deg)'
                xrange = [xmin,xmax]
                xt = 6
                xm = 2
                xlog = 0
              end
    'MDIST' : begin
                if not keyword_set(xspan) then begin
                  xmin = 1.3
                  xmax = 1.7
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 20
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'Mars-Sun Distance (AU)'
                xrange = [xmin,xmax]
                xt = 4
                xm = 2
                xlog = 0
              end
    'PSW'   : begin
                if not keyword_set(xspan) then begin
                  xmin = 0.
                  xmax = 2.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 20
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'Dynamic Pressure (nPa)'
                xrange = [xmin,xmax]
                xt = 5
                xm = 2
                xlog = 0
              end
    'BCLK'  : begin
                if not keyword_set(xspan) then begin
                  xmin = 0.
                  xmax = 360.
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 18
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'IMF Clock Angle (deg)'
                xrange = [xmin,xmax]
                xt = 4
                xm = 3
                xlog = 0
              end
    'TIME'  : begin
                tpflg = 1
                if not keyword_set(xspan) then begin
                  xmin = min((*ptr).time, max=xmax)
                endif else xmin = min(xspan, max=xmax)
                if not keyword_set(xbins) then xbins = 30
                dx = float(xmax - xmin)/float(xbins)
                xlab = 'Time'
                xrange = [xmin,xmax]
                xt = 0
                xm = 0
                xlog = 0
              end
    'PARAM' : begin
                xmin = zmin
                xmax = zmax
                xrange = zrange
                xlab = zlab
                xt = zt
                xm = zm
                xlog = zlog
              end
    else    : begin
                print,"Unrecognized X variable: ",xvar
                return
              end
  endcase

  case (yvar) of
    'MSO_X' : begin
                if not keyword_set(yspan) then begin
                  ymin = -3.
                  ymax =  0.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'MSO X (R!dM!n)'
                yrange = [ymin,ymax]
                yt = 3
                ym = 2
                ylog = 0
                vyvar = 'VEL_X'
              end
    'MSO_Y' : begin
                if not keyword_set(yspan) then begin
                  ymin = -3.
                  ymax =  3.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'MSO Y (R!dM!n)'
                yrange = [ymin,ymax]
                yt = 6
                ym = 2
                ylog = 0
                vyvar = 'VEL_Y'
              end
    'MSO_Z' : begin
                if not keyword_set(yspan) then begin
                  ymin = -3.
                  ymax =  3.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'MSO Z (R!dM!n)'
                yrange = [ymin,ymax]
                yt = 6
                ym = 2
                ylog = 0
                vyvar = 'VEL_Z'
              end
    'MSO_S' : begin
                if not keyword_set(yspan) then begin
                  ymin = 0.
                  ymax = 3.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'MSO S (R!dM!n)'
                yrange = [ymin,ymax]
                yt = 3
                ym = 2
                ylog = 0
                vyvar = 'VEL_S'
              end
    'MSE_X' : begin
                if not keyword_set(yspan) then begin
                  ymin = -3.
                  ymax =  0.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'MSE X (R!dM!n)'
                yrange = [ymin,ymax]
                yt = 3
                ym = 2
                ylog = 0
                vyvar = 'VEL_XE'
              end
    'MSE_Y' : begin
                if not keyword_set(yspan) then begin
                  ymin = -3.
                  ymax =  3.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'MSE Y (R!dM!n)'
                yrange = [ymin,ymax]
                yt = 6
                ym = 2
                ylog = 0
                vyvar = 'VEL_YE'
              end
    'MSE_Z' : begin
                if not keyword_set(yspan) then begin
                  ymin = -3.
                  ymax =  3.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'MSE Z (R!dM!n)'
                yrange = [ymin,ymax]
                yt = 6
                ym = 2
                ylog = 0
                vyvar = 'VEL_ZE'
              end
    'SZA'   : begin
                if not keyword_set(yspan) then begin
                  ymin = 0.
                  ymax = 180.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 18
                dy = float(ymax - ymin)/float(ybins)
                ylab = 'SZA (deg)'
                yrange = [ymin,ymax]
                yt = 6
                ym = 3
                ylog = 0
              end
    'ALT'   : begin
                if not keyword_set(yspan) then begin
                  ymin = 1000.
                  ymax = 7000.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'Altitude'
                yrange = [ymin,ymax]
                yt = 6
                ym = 2
                ylog = 0
              end
    'SLON'  : begin
                if not keyword_set(yspan) then begin
                  ymin = 0.
                  ymax = 360.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'Solar Longitude'
                yrange = [ymin,ymax]
                yt = 4
                ym = 3
                ylog = 0
              end
    'SLAT'  : begin
                if not keyword_set(yspan) then begin
                  ymin = -30
                  ymax =  30.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 24
                dy = (ymax - ymin)/ybins
                ylab = 'Solar Latitude'
                yrange = [ymin,ymax]
                yt = 6
                ym = 2
                ylog = 0
              end
    'MDIST' : begin
                if not keyword_set(yspan) then begin
                  ymin = 1.3
                  ymax = 1.7
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 20
                dy = float(ymax - ymin)/float(ybins)
                ylab = 'Mars-Sun Distance (AU)'
                yrange = [ymin,ymax]
                yt = 4
                ym = 2
                ylog = 0
              end
    'PSW'   : begin
                if not keyword_set(yspan) then begin
                  ymin = 0.
                  ymax = 2.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 20
                dy = float(ymax - ymin)/float(ybins)
                ylab = 'Dynamic Pressure (nPa)'
                yrange = [ymin,ymax]
                yt = 5
                ym = 2
                ylog = 0
              end
    'BCLK'  : begin
                if not keyword_set(yspan) then begin
                  ymin = 0.
                  ymax = 360.
                endif else ymin = min(yspan, max=ymax)
                if not keyword_set(ybins) then ybins = 18
                dy = float(ymax - ymin)/float(ybins)
                ylab = 'IMF Clock Angle (deg)'
                yrange = [ymin,ymax]
                yt = 4
                ym = 3
                ylog = 0
              end
    'TIME'  : begin
                print,"Time must be the X variable."
                return
              end
    'PARAM' : begin
                ymin = zmin
                ymax = zmax
                ylab = zlab
                yrange = zrange
                yt = zt
                ym = zm
                ylog = zlog
              end
    else    : begin
                print,"Unrecognized Y variable: ",yvar
                return
              end
  endcase

; Set plot dimensions - make sure Mars is round

  if (strcmp(xvar, 'MS', 2, /fold) and strcmp(yvar, 'MS', 2, /fold)) then begin
    yscl = abs(ymax - ymin)/abs(xmax - xmin)
  endif else yscl = 1.

; Velocity vector overlay

  if (keyword_set(vvec) and (vxvar ne '') and (vyvar ne '')) then dovec = 1 else dovec = 0

  if (dovec) then begin
    indx = where(tags eq vxvar, count)
    if (count eq 0L) then begin
      print,'Variable "',yxvar,'" not found in data structure!'
      dovec = 0
    endif else vxtag = indx[0]
    indx = where(tags eq vyvar, count)
    if (count eq 0L) then begin
      print,'Variable "',yyvar,'" not found in data structure!'
      dovec = 0
    endif else vytag = indx[0]

    case n_elements(vskip) of
       0   : vskip = [1,1]
       1   : vskip = [round(vskip) > 1,1]
      else : vskip = round(vskip[0:1]) > 1
    endcase

    case n_elements(vbar) of
       0   : vbar = [10., (xmin + dx/2.), (ymax - dy/2.)]
       1   : vbar = [vbar[0], (xmin + dx/2.), (ymax - dy/2.)]
       2   : vbar = [vbar[0:1], (ymax - dy/2.)]
      else : vbar = vbar[0:2]
    endcase
    vbar = float(vbar)

  endif

; Make a Mars circle and curves for the shock and MPB (from Trotignon)

  phi = findgen(181)*(2.*!pi/180.)
  mars_x = cos(phi)
  mars_y = sin(phi)

  x0  = 0.600
  psi = 1.026
  L   = 2.081
  phi = (-150. + findgen(301))*!dtor
  rho = L/(1. + psi*cos(phi))
  shock_x = x0 + rho*cos(phi)
  shock_y = rho*sin(phi)

  x0_p1  = 0.640
  psi_p1 = 0.770
  L_p1   = 1.080
  x0_p2  = 1.600
  psi_p2 = 1.009
  L_p2   = 0.528
  phi = (-160. + findgen(160))*!dtor
  rho = L_p1/(1. + psi_p1*cos(phi))
  x1 = x0_p1 + rho*cos(phi)
  y1 = rho*sin(phi)
  rho = L_p2/(1. + psi_p2*cos(phi))
  x2 = x0_p2 + rho*cos(phi)
  y2 = rho*sin(phi)
  indx = where(x1 ge 0)
  jndx = where(x2 lt 0)
  pileup_x = [x2[jndx], x1[indx]]
  pileup_y = [y2[jndx], y1[indx]]
  phi = findgen(161)*!dtor
  rho = L_p1/(1. + psi_p1*cos(phi))
  x1 = x0_p1 + rho*cos(phi)
  y1 = rho*sin(phi)
  rho = L_p2/(1. + psi_p2*cos(phi))
  x2 = x0_p2 + rho*cos(phi)
  y2 = rho*sin(phi)
  indx = where(x1 ge 0)
  jndx = where(x2 lt 0)
  pileup_x = [pileup_x, x1[indx], x2[jndx]]
  pileup_y = [pileup_y, y1[indx], y2[jndx]]

  if (((xvar eq 'MSO_Y') or (xvar eq 'MSO_Z') or (xvar eq 'MSO_R') or   $
       (xvar eq 'MSE_Y') or (xvar eq 'MSE_Z') or (xvar eq 'MSE_R')) and $
      ((yvar eq 'MSO_Y') or (yvar eq 'MSO_Z') or (yvar eq 'MSO_R') or   $
       (yvar eq 'MSE_Y') or (yvar eq 'MSE_Z') or (yvar eq 'MSE_R'))) then begin

    L0 = sqrt((L + psi*x0)^2. - x0*x0)
    shock_x = L0*mars_x
    shock_y = L0*mars_y

    L0 = sqrt((L_p1 + psi_p1*x0_p1)^2. - x0_p1*x0_p1)
    pileup_x = L0*mars_x
    pileup_y = L0*mars_y
  endif

  i = where(strcmp(xvar, 'MS', 2, /fold), ni)
  j = where(strcmp(yvar, 'MS', 2, /fold), nj)
  bflg = (ni gt 0) and (nj gt 0)

; Default plotting options

  if (yvar eq 'PARAM') then psym = 10 else psym = 0

  limits = {no_interp:1, xrange:xrange, yrange:yrange, zrange:zrange, xstyle:1, $
            ystyle:1, xtitle:xlab, ytitle:ylab, ztitle:zlab, xlog:xlog, $
            ylog:ylog, zlog:zlog, xticks:xt, yticks:yt, zticks:zt, xminor:xm, yminor:ym, $
            zminor:zm, xmargin:[10,12], charsize:1.2, psym:psym}

  if (bflg) then str_element, limits, 'isotropic', 1, /add

; User defined plotting options (override defaults and/or add new options)

  if (size(ulimits,/type) eq 8) then begin
    tags = tag_names(ulimits)
    ntags = n_elements(tags)

    for i=0,(ntags-1) do begin
      str_element, ulimits, tags[i], value
      str_element, limits, tags[i], value, /add
    endfor

    str_element, limits, 'xsize', value, success=ok
    if (ok) then begin
      xsize = value
      str_element, limits, 'xsize', /del
    endif
    str_element, limits, 'ysize', value, success=ok
    if (ok) then begin
      ysize = value
      str_element, limits, 'ysize', /del
    endif
    str_element, limits, 'note', value, success=ok
    if (ok) then begin
      note = value
      str_element, limits, 'note', /del
    endif else note = ''

    if keyword_set(doall) then begin
      str_element, limits, 'title', value, success=ok
      if (ok) then begin
        title = value
        str_element, limits, 'title', /del
      endif else title = ''
    endif
  endif

; Filter the data:
;   fndx --> indices that pass through all filters

  if not keyword_set(minsam) then minsam = 0L

  if (dofilter) then fndx = (*(*ptr).filter).f_indx $
                else fndx = lindgen(n_elements((*ptr).time))

; Filter out invalid/missing data

  indx = where(finite((*ptr).(ptag)[fndx]), count)
  if (count eq 0L) then begin
    print,"No valid data: ",pvar
    return
  endif
  fndx = fndx[indx]

  if (xvar ne 'PARAM') then begin
    indx = where(finite((*ptr).(xtag)[fndx]), count)
    if (count eq 0L) then begin
      print,"No valid data: ",xvar
      return
    endif
    fndx = fndx[indx]
  endif

  if (yvar ne 'PARAM') then begin
    indx = where(finite((*ptr).(ytag)[fndx]), count)
    if (count eq 0L) then begin
      print,"No valid data: ",yvar
      return
    endif
    fndx = fndx[indx]
  endif

; Bin the data

  pmode = 2  ; plotting mode

  if (yvar eq 'PARAM') then begin
    bindata, (*ptr).(xtag)[fndx], (*ptr).(ptag)[fndx], xbins=xbins, xrange=[xmin,xmax], dst=dst, $
             result=data
    str_element, data, 'xvar', xvar, /add
    str_element, data, 'yvar', pvar, /add
    pmode = 0
  endif

  if (xvar eq 'PARAM') then begin
    bindata, (*ptr).(ytag)[fndx], (*ptr).(ptag)[fndx], xbins=ybins, xrange=[ymin,ymax], dst=dst, $
             result=data
    str_element, data, 'xvar', yvar, /add
    str_element, data, 'yvar', pvar, /add
    pmode = 1
  endif

  if (pmode eq 2) then begin
    bindata2d, (*ptr).(xtag)[fndx], (*ptr).(ytag)[fndx], (*ptr).(ptag)[fndx], xbins=xbins, $
               ybins=ybins, xrange=[xmin,xmax], yrange=[ymin,ymax], dst=dst, result=data
    str_element, data, 'xvar', xvar, /add
    str_element, data, 'yvar', yvar, /add
    str_element, data, 'zvar', pvar, /add

    if (dovec) then begin
      bindata2d, (*ptr).(xtag)[fndx], (*ptr).(ytag)[fndx], (*ptr).(vxtag)[fndx], xbins=xbins, $
                 ybins=ybins, xrange=[xmin,xmax], yrange=[ymin,ymax], result=vxdat
      bindata2d, (*ptr).(xtag)[fndx], (*ptr).(ytag)[fndx], (*ptr).(vytag)[fndx], xbins=xbins, $
                 ybins=ybins, xrange=[xmin,xmax], yrange=[ymin,ymax], result=vydat
    endif
  endif

  str_element, data, 'mass', (*ptr).mass, /add
  str_element, data, 'filter', *(*ptr).filter, /add
  str_element, data, 'limits', limits, /add

  indx = where(data.npts ge minsam, ngud, complement=jndx, ncomplement=nbad)
  if (ngud gt 0L) then begin
    min_samp = min(data.npts[indx])
    med_samp = median(data.npts[indx])
    max_samp = max(data.npts[indx])
  endif else begin
    min_samp = min(data.npts)
    med_samp = median(data.npts)
    max_samp = max(data.npts)
  endelse

  print," "
  print,"         Points per Cell"
  print,"       Min   Median    Max"
  print,"      ---------------------"
  print, min_samp, med_samp, max_samp, format='(5x,i5,2x,i6,2x,i6,/)'

  if (pmode eq 2) then ncell = n_elements(data.z) else ncell = n_elements(data.y)

  if (minsam gt 0L) then msg = " fewer than " else msg = " "
  msg = strtrim(string(ncell - ngud),2) + " of " + string(ncell) + $
        " cells contain" + msg + string(minsam) + " points."
  print,strcompress(msg),format='(a,/)'

  if (ngud eq 0L) then return                            ; nothing to plot

; Mask data with low sampling

  if (pmode eq 2) then begin
    str_element, data, 'valid', replicate(1, n_elements(data.x), n_elements(data.y)), /add
    if (nbad gt 0L) then begin
      data.valid[jndx] = 0
      data.z[jndx] = !values.f_nan
      data.med[jndx] = !values.f_nan
    endif
  endif else begin
    str_element, data, 'valid', replicate(1, n_elements(data.y)), /add
    if (nbad gt 0L) then begin
      data.valid[jndx] = 0
      data.y[jndx] = !values.f_nan
      data.med[jndx] = !values.f_nan
    endif
  endelse

; Put up probability, sampling, and/or rms plots

  if keyword_set(doall) then begin
    if (not execute('wset, doall',2,1)) then begin
      scale = 2.*wscale
      xsize1 = xsize*scale
      ysize1 = xsize1/aspect2
      win, doall, xsize=xsize1, ysize=ysize1, /secondary, /ycenter, dx=10
    endif
    !p.multi = [0,2,2,0,0]
    doall = 1
    doplot = 1
    dosamp = 1
    domom = 1
  endif else begin
    doall = 0
    !p.multi = 0
  endelse

  if keyword_set(doplot) then begin

    if (~doall) then begin
      if (not execute('wset, doplot',2,1)) then begin
        scale = wscale
        xsize1 = xsize*scale
        ysize1 = xsize1/aspect1
        win, doplot, xsize=xsize1, ysize=ysize1, /secondary, /ycenter, dx=10
      endif
    endif

    case pmode of
      0 : begin
            if (medflg) then y = data.med else y = data.y
            limits.ytitle = mode + limits.ytitle
            if (tpflg) then begin
              store_data, pvar, data={x:data.x, y:y}
              ylim, pvar, limits.zrange, limits.zlog
              options, pvar, 'x_no_interp', limits.no_interp
              options, pvar, 'y_no_interp', limits.no_interp
              options, pvar, 'ytitle', limits.ztitle
              options, pvar, 'yticks', limits.zticks
              options, pvar, 'yminor', limits.zminor
              options, pvar, 'psym', limits.psym
              options, pvar, 'spec', 0
              tplot_options, 'charsize', limits.charsize
              timespan,[xmin,xmax]

              tplot, pvar
            endif else plot, data.x, y, _extra=limits
          end

      1 : begin
            if (medflg) then y = data.med else y = data.y
            limits.ytitle = mode + limits.ytitle
            plot, data.x, y, _extra=limits
          end

      2 : begin
            if (medflg) then z = data.med else z = data.z
            limits.ztitle = mode + limits.ztitle
            if (tpflg) then begin
              store_data, pvar, data={x:data.x, y:z, v:data.y}
              ylim, pvar, limits.yrange, limits.ylog
              options, pvar, 'x_no_interp', limits.no_interp
              options, pvar, 'y_no_interp', limits.no_interp
              options, pvar, 'ytitle', limits.ytitle
              options, pvar, 'yticks', limits.yticks
              options, pvar, 'yminor', limits.yminor
              options, pvar, 'psym', limits.psym
              options, pvar, 'spec', 1

              zlim, pvar, limits.zrange, limits.zlog
              options, pvar, 'ztitle', limits.ztitle
              options, pvar, 'zticks', limits.zticks

              tplot_options, 'charsize', limits.charsize
              timespan,xrange
              tplot, pvar
            endif else begin
              specplot,data.x,data.y,z,limits=limits
              if (bflg) then begin
                oplot, mars_x, mars_y, thick=2
                oplot, shock_x, shock_y, linestyle=2, thick=2
                oplot, pileup_x, pileup_y, linestyle=2, thick=2
              endif
              if (dovec) then begin
                for i=0,(xbins-1),vskip[0] do begin
                  x0 = vxdat.x[i]
                  for j=0,(ybins-1),vskip[1] do begin
                    y0 = vxdat.y[j]
                    x1 = x0 + vxdat.z[i,j]*vvec
                    y1 = y0 + vydat.z[i,j]*vvec
                    if (finite(data.z[i,j])) then arrow, x0, y0, x1, y1, /data, hsize=5
                  endfor
                endfor
                x0 = vbar[1]
                y0 = vbar[2]
                x1 = x0 + vbar[0]*vvec
                y1 = y0
                oplot, [x0,x1], [y0,y1], thick=2
                vbmag = strtrim(string(round(vbar[0])),2) + ' km/s'
                xyouts, (x0 + x1)/2., (y0 - dy), vbmag, align=0.5, charsize=limits.charsize*0.8
              endif

              str_element, *(*ptr).filter, 'bclk', bclk, success=ok
              if (ok and evec) then begin
                xspan = (xrange[1] - xrange[0])
                yspan = (yrange[1] - yrange[0])
                vlen = -yspan/10.                                             ; -U x B points south
                if ((bclk[0] gt 270.) and (bclk[1] lt 90.)) then vlen *= -1.  ; -U x B points north
                x0 = xrange[0] + xspan*0.85
                y0 = yrange[0] + yspan*0.2 - vlen/2.
                x1 = x0
                y1 = y0 + vlen
                arrow, x0, y0, x1, y1, /data, hsize=10, /solid, thick=2
                csize = limits.charsize*wscale*1.2
                xyouts, (x0 + dx/2.), (y0 + y1)/2., "E!dSW!n", charsize=csize
              endif
            endelse
          end
    endcase

  endif

  if keyword_set(dosamp) then begin

    if (~doall) then begin
      if (not execute('wset, dosamp',2,1)) then begin
        scale = wscale
        xsize1 = xsize*scale
        ysize1 = xsize1/aspect2
        win, dosamp, /secondary, xsize=xsize1, ysize=ysize1, /ycenter, dx=10
      endif
    endif

    z = data.npts
    if (nbad gt 0L) then z[jndx] = 0  ; mask values below minimum sampling

    if (pmode eq 2) then begin
      z_max = round(alog10(max(z,/nan)))
      z_min = round(alog10(min(z,/nan) > 1))
    endif else begin
      z_max = ceil(alog10(max(z,/nan)))
      z_min = floor(alog10(min(z,/nan) > 1))
    endelse
    zrange = 10.^[z_min, z_max]
    zticks = (z_max - z_min)

    if (zticks lt 2) then begin
      zticks = 0
      zlog = 0
    endif else zlog = 1

    nzlim = n_elements(zlimits)
    if (nzlim ge 2) then begin
      zrange = float(zlimits[0:1])
      if (nzlim ge 3) then zlog = round(zlimits[2])
      if (nzlim ge 4) then zticks = round(zlimits[3])
    endif

    ztitle = 'Points per Bin'

    case pmode of
      0 : begin
            if (tpflg) then begin
              store_data,'SAMP',data={x:data.x, y:z}
              ylim, 'SAMP', zrange[0], zrange[1], zlog
              options, 'SAMP', 'ytitle', ztitle
              options, 'SAMP', 'yticks', zticks
              options, 'SAMP', 'yminor', 0
              options, 'SAMP', 'psym', limits.psym
              options, 'SAMP', 'spec', 0

              timespan,[xmin,xmax]
              tplot, 'SAMP'
            endif else begin
              str_element, limits, 'yrange', zrange, /add
              str_element, limits, 'ytitle', ztitle, /add
              str_element, limits, 'yticks', zticks, /add
              str_element, limits, 'yminor', 0, /add
              str_element, limits, 'ylog', zlog, /add

              plot, data.x, z, _extra=limits
            endelse
          end

      1 : begin
            str_element, limits, 'xrange', zrange, /add
            str_element, limits, 'xtitle', ztitle, /add
            str_element, limits, 'xticks', zticks, /add
            str_element, limits, 'xminor', 0, /add
            str_element, limits, 'xlog', zlog, /add

            plot, z, data.y, _extra=limits
          end

      2 : begin
            str_element, limits, 'zrange', zrange, /add
            str_element, limits, 'ztitle', ztitle, /add
            str_element, limits, 'zticks', zticks, /add
            str_element, limits, 'zminor', 0, /add
            str_element, limits, 'zlog', zlog, /add

            if (tpflg) then begin
              store_data,'SAMP',data={x:data.x, y:z, v:data.y}
              ylim, 'SAMP', limits.yrange[0], limits.yrange[1], limits.ylog
              options, 'SAMP', 'x_no_interp', limits.no_interp
              options, 'SAMP', 'y_no_interp', limits.no_interp
              options, 'SAMP', 'ytitle', limits.ytitle
              options, 'SAMP', 'yticks', limits.yticks
              options, 'SAMP', 'yminor', limits.yminor
              options, 'SAMP', 'psym', limits.psym
              options, 'SAMP', 'spec', 1

              zlim, 'SAMP', zrange[0], zrange[1], zlog
              options, 'SAMP', 'ztitle', ztitle
              options, 'SAMP', 'zticks', zticks
              options, 'SAMP', 'zminor', 0

              tplot_options, 'charsize', limits.charsize
              timespan,[xmin,xmax]
              tplot, 'SAMP'
            endif else begin
              specplot,data.x,data.y,z,limits=limits
              if (bflg) then begin
                oplot, mars_x, mars_y, thick=2
                oplot, shock_x, shock_y, linestyle=2, thick=2
                oplot, pileup_x, pileup_y, linestyle=2, thick=2
              endif
            endelse
          end
    endcase

  endif

  if keyword_set(domom) then begin

    if (~doall) then begin
      if (not execute('wset, domom',2,1)) then begin
        scale = wscale
        xsize1 = xsize*scale
        ysize1 = xsize1/aspect2
        win, domom, /secondary, xsize=xsize1, ysize=ysize1, /ycenter, dx=10
      endif
    endif

    if (pmode eq 2) then begin
      case mtype of
        'skew' : begin
                   z = data.skew
                   ztitle = 'Skewness ' + zlab
                 end
        'kurt' : begin
                   z = data.kurt
                   ztitle = 'Kurtosis ' + zlab
                 end
        'adev' : begin
                   if (data.zvar ne 'VB_PHI') then begin
                     z = data.adev/abs(data.z)
                     ztitle = 'Adev/Mean ' + zlab
                   endif else begin
                     z = data.adev
                     ztitle = 'Adev ' + zlab
                   endelse
                 end
         else  : begin
                   if (data.zvar ne 'VB_PHI') then begin
                     z = data.sdev/abs(data.z)
                     ztitle = 'Sdev/Mean ' + zlab
                   endif else begin
                     z = data.sdev
                     ztitle = 'Sdev ' + zlab
                   endelse
                 end
      endcase
    endif else begin
      case mtype of
        'skew' : begin
                   z = data.skew
                   ztitle = 'Skewness ' + zlab
                 end
        'kurt' : begin
                   z = data.kurt
                   ztitle = 'Kurtosis ' + zlab
                 end
        'adev' : begin
                   if (data.yvar ne 'VB_PHI') then begin
                     z = data.adev/abs(data.y)
                     ztitle = 'Adev/Mean ' + zlab
                   endif else begin
                     z = data.adev
                     ztitle = 'Adev ' + zlab
                   endelse
                 end
         else  : begin
                   if (data.yvar ne 'VB_PHI') then begin
                     z = data.sdev/abs(data.y)
                     ztitle = 'Sdev/Mean ' + zlab
                   endif else begin
                     z = data.sdev
                     ztitle = 'Sdev ' + zlab
                   endelse
                 end
      endcase
    endelse
    if (nbad gt 0L) then z[jndx] = !values.f_nan  ; mask values below minimum sampling

    zrange = minmax(z)
    zticks = 0
    zlog = 0

    nrlim = n_elements(rlimits)
    if (nrlim ge 2) then begin
      zrange = float(rlimits[0:1])
      if (nrlim ge 3) then zlog = round(rlimits[2])
      if (nrlim ge 4) then zticks = round(rlimits[3])
    endif

    case pmode of
      0 : begin
            if (tpflg) then begin
              store_data,'RMS',data={x:data.x, y:z}
              ylim, 'RMS', zrange[0], zrange[1], zlog
              options, 'RMS', 'ytitle', ztitle
              options, 'RMS', 'yticks', zticks
              options, 'RMS', 'yminor', 0
              options, 'RMS', 'psym', limits.psym
              options, 'RMS', 'spec', 0

              timespan,[xmin,xmax]
              tplot, 'RMS'
            endif else begin
              str_element, limits, 'yrange', zrange, /add
              str_element, limits, 'ytitle', ztitle, /add
              str_element, limits, 'yticks', zticks, /add
              str_element, limits, 'yminor', 0, /add
              str_element, limits, 'ylog', zlog, /add

              plot, data.x, z, _extra=limits
            endelse
          end

      1 : begin
            str_element, limits, 'xrange', zrange, /add
            str_element, limits, 'xtitle', ztitle, /add
            str_element, limits, 'xticks', zticks, /add
            str_element, limits, 'xminor', 0, /add
            str_element, limits, 'xlog', zlog, /add

            plot, z, data.y, _extra=limits
          end

      2 : begin
            str_element, limits, 'zrange', zrange, /add
            str_element, limits, 'ztitle', ztitle, /add
            str_element, limits, 'zticks', zticks, /add
            str_element, limits, 'zminor', 0, /add
            str_element, limits, 'zlog', zlog, /add

            if (tpflg) then begin
              store_data,'RMS',data={x:data.x, y:z, v:data.y}
              ylim, 'RMS', limits.yrange[0], limits.yrange[1], limits.ylog
              options, 'RMS', 'x_no_interp', limits.no_interp
              options, 'RMS', 'y_no_interp', limits.no_interp
              options, 'RMS', 'ytitle', limits.ytitle
              options, 'RMS', 'yticks', limits.yticks
              options, 'RMS', 'yminor', limits.yminor
              options, 'RMS', 'psym', limits.psym
              options, 'RMS', 'spec', 1

              zlim, 'RMS', zrange[0], zrange[1], zlog
              options, 'RMS', 'ztitle', ztitle
              options, 'RMS', 'zticks', zticks
              options, 'RMS', 'zminor', 0

              tplot_options, 'charsize', limits.charsize
              timespan,[xmin,xmax]
              tplot, 'RMS'
            endif else begin
              specplot,data.x,data.y,z,limits=limits
              if (bflg) then begin
                oplot, mars_x, mars_y, thick=2
                oplot, shock_x, shock_y, linestyle=2, thick=2
                oplot, pileup_x, pileup_y, linestyle=2, thick=2
              endif
            endelse
          end
    endcase

  endif

  if (doall) then begin
    plot, [-1.], [-1.], xrange=[0,1], yrange=[0,1], xstyle=5, ystyle=5
    x = [0.1, 0.35, 0.5]
    dx = 0.05
    y = 0.95
    dy = 0.05

    if (strlen(title) gt 0) then begin
      xyouts, x[0], y, title, charsize=limits.charsize*1.2
      y -= (2.*dy)
    endif

    if (strlen(note) gt 0) then begin
      xyouts, x[0], y, note, charsize=limits.charsize
      y -= (2.*dy)
    endif

    if (dofilter) then begin
      tag = strlowcase(tag_names(*(*ptr).filter))
      indx = where(tag ne 'f_indx', ntag)
      tag = tag[indx]

      jndx = where(tag eq 'topo', nj)
      xyouts, x[0], y, 'TOPOLOGY', charsize=limits.charsize
      x += dx
      y -= dy
      if (nj gt 0) then begin
        tstring = ['unknown','closed','open to day','open to night','draped','impossible']
        value = (*(*ptr).filter).(jndx[0])
        for i=value[0],value[1] do begin
          xyouts, x[0], y, tstring[i < 5], charsize=limits.charsize
          y -= dy
        endfor
      endif else begin
        xyouts, x[0], y, 'all', charsize=limits.charsize
        y -= dy
      endelse
      x -= dx
      y -= dy

      xyouts, x[0], y, 'FILTER', charsize=limits.charsize
      x += dx
      y -= dy

      for i=0,(ntag-1) do begin
        case tag[i] of
          'time' : begin
                     xyouts, x[0], y, tag[i], charsize=limits.charsize
                     value = (*(*ptr).filter).(indx[i])
                     xyouts, x[1], y, time_string(value[0]), charsize=limits.charsize, align=1
                     xyouts, x[2], y, time_string(value[1]), charsize=limits.charsize, align=1
                     y -= dy
                   end
          'topo' : ; do nothing here (see above)
           else  : begin
                     xyouts, x[0], y, tag[i], charsize=limits.charsize
                     value = (*(*ptr).filter).(indx[i])
                     if (size(value,/type) gt 3) then vstring = string(value, format='(f9.2)') $
                                                 else vstring = string(value, format='(i)')
                     vstring = strtrim(vstring,2)
                     xyouts, x[1], y, vstring[0], charsize=limits.charsize, align=1
                     xyouts, x[2], y, vstring[1], charsize=limits.charsize, align=1
                     y -= dy
                   end
        endcase
      endfor
      x -= dx
    endif
    y -= dy

    xyouts, x[0], y, ('MINSAM = ' + strtrim(string(minsam),2)), charsize=limits.charsize
    y -= dy
    case pmode of
      0 : begin
            cx = float(xmax - xmin)/float(xbins)
            cellsize = string(cx,format='(f4.2)')
          end
      1 : begin
            cy = float(ymax - ymin)/float(ybins)
            cellsize = string(cy,format='(f4.2)')
          end
      2 : begin
            cx = float(xmax - xmin)/float(xbins)
            cy = float(ymax - ymin)/float(ybins)
            cellsize = string(cx,cy,format='(f4.2,", ",f4.2)')
          end
    endcase
    xyouts, x[0], y, ('CELLSIZE = ' + strtrim(string(cellsize),2)), charsize=limits.charsize
    y -= (2.*dy)

    xyouts, x[0], y, systime(), charsize=limits.charsize
    y -= dy
  endif else begin    
    if (strlen(note) gt 0) then begin
      xyouts, 0.8, 0.9, note, charsize=limits.charsize, /norm, align=1
    endif
  endelse

  if (size(png,/type) eq 7) then begin
    device, get_decomposed=old_decomposed
    device, decomposed=0
    cols = get_colors()
    initct, cols.color_table, reverse=cols.color_reverse
    write_png, png, tvrd(/true)
    print,'Plot written to: ',file_basename(png)
    print,''
    device, decomposed=old_decomposed
  endif

  !p.multi = 0

  return

end
