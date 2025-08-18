;+
;FUNCTION: mvn_ls
;PURPOSE:
;  Calculates the Mars season (solar longitude and Mars year).
;
;    Ls =   0  --> Northern spring equinox  (beginning of Mars year)
;    Ls =  90  --> Northern summer solstice
;    Ls = 180  --> Northern fall equinox
;    Ls = 270  --> Northern winter solstice
;
;    Ls =  71  --> Aphelion
;    Ls = 251  --> Perihelion
;
;    Ls = 180-320  --> Dust storm season
;
;  Ls (pronounced "L sub S") is the angular position of Mars in its orbit about the
;  Sun, starting at the northern spring equinox and ranging from 0 to 360 degrees.
;  This is different from longitude in the rotating IAU_SUN frame, which is used to 
;  specify the positions of features (flares, sunspots) on the Sun as well as the 
;  face of the Sun seen by an observer.
;
;  For the definition of Mars year, see Piqueux et al., Icarus 251 (2015) 332–338.
;
;    Mars year  0 began 1953-05-24/11:54:39
;    Mars year 34 began 2017-05-05/11:28:03
;
;USAGE:
;  result = mvn_ls(time)
;
;INPUTS:
;       time:      An array of times in any format accepted by time_double.  If no
;                  time is provided, then all values in the common block are returned.
;                  If keyword DT is set, then the minimum and maximum values of time
;                  are used to create an array of evenly spaced values sampled every
;                  DT seconds.
;
;OUTPUT:
;                  By default, returns an array of Ls (L_sub_s) values with the same
;                  number of elements as time.  If keyword ALL is set, then returns a
;                  structure with three tags:
;
;                    time      : the times at which the Mars season is calculated
;                    Ls        : the longitude of Mars in its orbit about the Sun,
;                                with Ls=0 at Mars' northern spring equinox
;                    Mars_year : the Mars year (Ls = 0 to 360) -- Mars year 0 began
;                                at 1953-05-24/11:54:39.  Year 1 was chosen to 
;                                correspond to a global dust storm in 1956.
;
;KEYWORDS:
;       DT :       Optional.  Time resolution in seconds for calculating the result.
;                  If set, then the minimum and maximum values of time are used to 
;                  create an array of values sampled every DT seconds.  Linear 
;                  interpolation between calculated values spaced by 1 day provides 
;                  an accuracy of ~0.0001 deg, so there's typically no need for DT 
;                  to be any smaller.  If not set, then the result is calculated for
;                  all values in the time array.
;
;       ALL:       By default, this function returns an array of Ls (L_sub_s) values
;                  with the same number of elements as time.  Set this keyword to 
;                  instead get a structure with three tags: time, Ls, and Mars_year.
;
;       TPLOT:     Make a tplot variable.
;
;       BAR:       If TPLOT is set, then setting this keyword creates a detached horizontal
;                  time axis with labels for Mars year and Ls.  This axis can be placed
;                  below any panel or at the top.  Only seems to work for Mars years 24-36
;                  (1998-2023).
;
;       CALC:      Instead of interpolating on an array of pre-calculated values, use
;                  spice to calculate values based on time and DT.  This mode always
;                  returns a structure of arrays, as if ALL were set.  Use this if you
;                  need a precision better than ~0.0001 deg.
;
;       SILENT:    Suppress diagnostic output (mostly from spice).
;
;       RESET:     Re-calculate mars_season and refresh the common block.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-07-11 17:52:59 -0700 (Fri, 11 Jul 2025) $
; $LastChangedRevision: 33456 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_ls.pro $
;
;CREATED BY:	Robert J. Lillis 2017-10-09
;FILE:  mvn_ls
;VERSION:  1.0
;-

; This subroutine was written by T.Hara on 2023-04-14.
PRO mvn_ls_bar, data=data, limits=lim, _extra=extra
  IF ~tag_exist(data, 'v', /quiet) THEN BEGIN
     dprint, 'No Mars Year data is available.'
     mplot, data=data, limits=lim
     RETURN
  ENDIF
  
  mars_year = FLOOR(data.v)

  data.y += mars_year * 360.
  
  xpos = lim.position[0]
  dy = lim.position[3] - lim.position[1]
  xrange = INTERPOL(data.y, data.x, lim.xrange)

  str_element, lim, 'xaxis', value=xaxis
  IF undefined(xaxis) THEN BEGIN
     IF xrange[1]-xrange[0] LT 30. THEN xaxis = {xtickinterval: 5., xminor: 5} $
     ELSE IF xrange[1]-xrange[0] LT 90. THEN xaxis = {xtickinterval: 10., xminor: 5} $
     ELSE IF xrange[1]-xrange[0] LT 360. THEN xaxis = {xtickinterval: 30., xminor: 3} $
     ELSE xaxis = {xtickinterval: 90., xminor: 3}
  ENDIF
  
  IF is_struct(xaxis) THEN BEGIN
     extract_tags, aopt, xaxis, /axis
     extract_tags, aopt, xaxis, tags=['xtickinterval']
     IF tag_exist(aopt, 'xaxis', /quiet) THEN BEGIN
        atype = aopt.xaxis
        str_element, aopt, 'xaxis', /delete
        IF ~is_struct(aopt) THEN undefine, aopt
     ENDIF 
  ENDIF
  IF undefined(atype) THEN atype = 1

  ypos = lim.position[1] + 0.5*dy
  AXIS, xpos, ypos, /normal, xrange=xrange, xaxis=atype, xstyle=5, charsize=lim.charsize, _extra=aopt, xtick_get=xmajor
  IF lim.ytitle EQ 'ls' THEN ytit = 'Ls [deg]' ELSE ytit = lim.ytitle
  
  tlim = lim
  extract_tags, tlim, lim, except='ytitle'
  extract_tags, tlim, {yrange: [-1., 1.], ystyle: 5, xstyle: 5, yminor: 1, yticks: 1}
  mplot, data={x: lim.xrange, y: [-0.5, -0.5]}, lim=tlim

  xticks = INTERPOL(data.x, data.y, xmajor)
  IF is_struct(aopt) THEN BEGIN
     IF tag_exist(aopt, 'xminor', /quiet) THEN BEGIN
        dx = ABS(xmajor[1] - xmajor[0])
        xminor = dgen(range=minmax(xmajor) + [-dx, dx], resolution=dx/aopt.xminor)
        w = WHERE(xminor GT xrange[0] AND xminor LT xrange[1], nw)
        IF nw GT 0 THEN xminor = xminor[w] ELSE undefine, xminor
     ENDIF
  ENDIF
  IF MAX(xmajor - FLOOR(xmajor)) GT 0 THEN xtickformat = '(F0.1)' ELSE xtickformat = '(I0)'
  xtickname = (xmajor MOD 360.)
  
  FOR i=0, N_ELEMENTS(xmajor)-1 DO BEGIN
     XYOUTS, xticks[i], 0.1, /data, charsize=lim.charsize, align=0.5, xtickname[i].tostring(xtickformat)
     OPLOT, [ xticks[i], xticks[i] ], [-0.8, -0.2]
  ENDFOR

  IF ~undefined(xminor) THEN BEGIN
     xticks = INTERPOL(data.x, data.y, xminor)
     FOR i=0, N_ELEMENTS(xminor)-1 DO BEGIN
        w = WHERE(xmajor EQ xminor[i], nw)
        IF nw EQ 0 THEN OPLOT, [ xticks[i], xticks[i] ], [-0.65, -0.35]
     ENDFOR
  ENDIF

  w = WHERE(data.x GE lim.xrange[0] AND data.x LE lim.xrange[1], nw)
  IF nw GT 0 THEN BEGIN
     MY = spd_uniq(mars_year[w])
     FOR i=0, N_ELEMENTS(MY)-1 DO BEGIN
        xd = INTERPOL(data.x, data.v, DOUBLE([MY[i], MY[i]+1]))
        p1 = CONVERT_COORD([xd[0], 0.7], /data, /to_normal) 
        p2 = CONVERT_COORD([xd[1], 0.7], /data, /to_normal)

        p1[0] = p1[0] > lim.position[0]
        p2[0] = p2[0] < lim.position[2]
        IF (p2[0] - p1[0]) GT 0.05 THEN XYOUTS, 0.5*(p2[0]+p1[0]), p1[1], /normal, charsize=lim.charsize, 'MY' + roundst(MY[i]), align=0.5
     ENDFOR 
  ENDIF
  
  XYOUTS, xpos, 0.25 * dy + lim.position[1], /normal, charsize=lim.charsize, ytit + '  ', /align
  
  RETURN
END

; This subroutine was initially written by Rob, and was modified by T.Hara on 2022-08-18.
; Modified by D. Mitchell on 2025-02-09 so that it can be used by orrery.pro.  The default
; time resolution of 10 minutes was overkill.  Linear interpolation on calculated values 
; with a time resolution of 1 day provides an accuracy of ~0.0001 deg, which should be 
; plenty.  With this change, it is possible to extend the coverage to match the Mars kernel
; (mars097.bsp), which goes from 1900 to 2100.  If higher accuracy is needed, then mvn_ls 
; can be called with CALC=1 and custom values of time and/or DT.  Changed the logic so that 
; a uniform time array is generated when either DT is provided or time is not provided.  
; Otherwise, the result is calculated for all elements of time.

function mvn_ls_calc, time, dt=dt, silent=silent

  if (~spice_test(v=0)) then begin
    print,"  You must have spice installed to calculate Mars seasons."
    return, !values.f_nan
  endif

  shh = keyword_set(silent)
  if (shh) then begin
    dprint,' ', getdebug=bug, dlevel=4
    dprint,' ', setdebug=0, dlevel=4
  endif

  mvn_spice_stat, summary=sinfo, info=info, /silent  ; only load kernels if necessary
  if (~sinfo.planets_exist or ~sinfo.frames_exist) then maven_kernels = mvn_spice_kernels(['STD', 'FRM'], /load)

  oneday = 86400D
  if undefined(time) then begin
    start_time = time_double('1600-01-01')
    end_time = time_double('2600-01-01')
    if undefined(dt) then dt = oneday
    times = dgen(range=[start_time, end_time], resolution=dt[0])
  endif else begin
    if ~undefined(dt) then begin
      start_time = min(time_double(time), max=end_time)
      times = dgen(range=[start_time, end_time], resolution=dt[0])
    endif else times = time_double(time)
  endelse 

  et = time_ephemeris(times)
  ntimes = n_elements(et)

  ; Mars Year 34 started on 2017-05-05
  start_MY_34 = time_double('2017-05-05/11:28:03')  ; previous value was 2017-05-05/17:47:31
  oneyear = 686.980D * oneday  ; Mars siderial year (precise value not important)

  ls = dblarr(ntimes)
  for i=0L, ntimes-1L do ls[i] = cspice_dpr() * cspice_lspcn('MARS', et[i], 'NONE')

  if (ntimes gt 1L) then begin
    dls = ls - shift(ls,1)
    dls[0] = dls[1]
  endif else dls = [1D]

  imy = where(dls lt 0, count)
  if (count gt 0) then begin
    year_boundary_times = times[imy]
    MYi = round((year_boundary_times - start_MY_34)/oneyear) + 34L
    imax = n_elements(MYi) - 1L

    MY = dblarr(ntimes)
    if (imy[0] gt 0L) then MY[0L:imy[0]-1L] = MYi[0] - 1L
    for i=0L,imax-1L do MY[imy[i]:imy[i+1L]-1L] = MYi[i]
    if (imy[imax] lt (ntimes-1L)) then MY[imy[imax]:*] = MYi[imax]
    Mars_year_decimal = MY + ls/360D
  endif else begin
    MYi = replicate(floor((times[0] - start_MY_34)/oneyear) + 34L, ntimes)
    Mars_year_decimal = double(MYi) + ls/360D
  endelse

  Mars_season = {time:times, Mars_year:Mars_year_decimal, Ls:Ls}

  if (shh) then dprint,' ', setdebug=bug, dlevel=4

  return, Mars_season
end 

function mvn_ls, time, dt=dt, tplot=tplot, calc=calc, all=all, bar=bar, silent=silent, reset=reset
  
  common mvn_ls_eph, mars_season

  if keyword_set(calc) then return, mvn_ls_calc(time, dt=dt, silent=silent)
  shh = keyword_set(silent) ? 0 : 2

  if ((size(mars_season,/type) ne 8) or keyword_set(reset)) then begin
    rootdir = 'maven/anc/spice/sav/'
    pathname = rootdir + 'Mars_seasons_1600_2600*.sav'
    file = mvn_pfp_file_retrieve(pathname, /last_version, /valid, verbose=shh)
    if (file[0] eq '') then begin
      print,"  File not found: ", pathname
      print,"  Attempting to calculate."
      mars_season = mvn_ls_calc(silent=silent)
      if (size(mars_season,/type) ne 8) then return, !values.f_nan
    endif else restore, file[0]
  endif

  if keyword_set(tplot) then begin
     data = {x:mars_season.time, y:mars_season.Ls}
     if keyword_set(bar) then str_element, data, 'v', mars_season.mars_year, /add
     
     store_data, 'ls', data = data, $
                 dlimits={yrange:[0.,360.], ystyle:1, yticks:4, yminor:3}
     if keyword_set(bar) then options, 'ls', tplot_routine='mvn_ls_bar', panel_size=0.3
  endif 

  if (size(time,/type) ne 0) then begin
    if (size(dt,/type) ne 0) then begin
      start_time = min(time_double(time), max=end_time)
      t = dgen(range=[start_time, end_time], resolution=dt[0])
    endif else t = time_double(time)

    indx = where((t ge min(mars_season.time)) and (t le max(mars_season.time)), ngud, ncomplement=nbad)
    if (ngud eq 0L) then begin
      print,"  No ephemeris coverage for input times."
      return, !values.f_nan
    endif
    if (nbad gt 0L) then print,"  Some input times extend outside ephemeris coverage."

    Ls = replicate(!values.d_nan, n_elements(t))
    My = Ls
    Ls_x = interpol(cos(mars_season.Ls * !dtor), mars_season.time, t[indx])
    Ls_y = interpol(sin(mars_season.Ls * !dtor), mars_season.time, t[indx])
    Ls[indx] = atan(Ls_y, Ls_x) * !radeg
    jndx = where(Ls[indx] lt 0D, count)
    if (count gt 0L) then Ls[indx[jndx]] += 360D
    My[indx] = interpol(mars_season.mars_year, mars_season.time, t[indx])
  endif else begin
    t = mars_season.time
    Ls = mars_season.Ls
    My = mars_season.mars_year
  endelse

  if keyword_set(all) then return, {time:t, Ls:Ls, mars_year:My} else return, Ls  

end 
