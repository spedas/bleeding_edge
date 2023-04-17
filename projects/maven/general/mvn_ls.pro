;+
;FUNCTION: mvn_ls
;PURPOSE:
;  Calculates the Mars season (i.e. solar longitude)
;
;USAGE:
;  ls = mvn_ls(time)
;
;INPUT:
;       time: time in any format accepted by time_double.
;
;OUTPUT:                
;       Mars solar longitude
;
;KEYWORDS:
;       TPLOT: make a tplot variable of Ls
;
; $LastChangedBy: hara $
; $LastChangedDate: 2023-04-16 15:08:05 -0700 (Sun, 16 Apr 2023) $
; $LastChangedRevision: 31754 $
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
  IF undefined(xaxis) THEN xaxis = {xtickinterval: 90., xminor: 3}

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

;This subroutine was initially written by Rob, and was modified by T.Hara on 2022-08-18.
function mvn_ls_calc, time
  if undefined(time) then begin
     start_time = time_double('1997-01-01')
     end_time = time_double('2040-01-01')
  endif else begin
     if n_elements(time) eq 2 then start_time = min(time, max=end_time)
     if n_elements(time) gt 2 then times = time
  endelse 
  if undefined(dt) then dt = 600.0
  if undefined(times) then times = dgen(range=[start_time, end_time], resolution=dt)

  et = time_ephemeris(times)
  maven_kernels = mvn_spice_kernels(['STD', 'FRM'], /load)

  ; Mars Year 34 started at 2017-05-05/18
  start_MY_34 = time_double('2017-05-05/17:47:31')

  ls = dblarr(n_elements(et))
  for i=0ll, n_elements(et)-1 do ls[i] = cspice_dpr() * cspice_lspcn('MARS', et[i], 'NONE')
  dls = deriv(ls)

  ends = where(abs(dls) gt 20.0)
  ends = ends[2*indgen(23)]     ; because evey year boundary is two points
  nend = n_elements(ends)

  year_boundary_times = times[ends+1]
  index_MY34 = nn(year_boundary_times, start_MY_34)
  MYs = 34 - index_MY34 + indgen(n_elements(year_boundary_times))

  mars_years = dblarr(n_elements(et))
  mars_years[*] = max(MYs)
  for i=nend-1, 0, -1 do mars_years[0ll:ends[i]] = MYs[i] - 1

  Mars_year_decimal = mars_years + reform(Ls)/360.d0
  
  ;year_boundary_times = times[ends]
  ;year = times[ends[1:*]] - times[ends[0:nend-2]]
  ;ave_year = mean(year)

  ;Mars_year_decimal = (time_double(times) - start_MY_34)/ave_year + 34.0
  ;Mars_year_integer = floor(Mars_year_decimal)
  Mars_season = {time:times, Mars_year:Mars_year_decimal, Ls:reform(Ls)}

  return, Mars_season
end 

function mvn_ls, time, tplot = tplot, calc = calc, last = last, all = all, bar=bar;, no_load_kernels
  
  common ephemeris, mars_season

  if size(mars_season, /type) ne 8 then begin
     if keyword_set(calc) then mars_season = mvn_ls_calc(time) $
     else begin
        rootdir = 'maven/anc/spice/sav/'
        pathname = rootdir + 'Mars_seasons_1997_2040*.sav'
        file = mvn_pfp_file_retrieve(pathname, last_version=last)
        if (findfile(file[0]) eq '') then begin
           print,"File not found: ",pathname
           return, !values.f_nan
        endif
        restore, file[0]
     endelse
  endif 
  
  if keyword_set(tplot) then begin
     data = {x: Mars_season.time, y: Mars_season.Ls}
     if keyword_set(bar) then str_element, data, 'v', Mars_season.mars_year, /add
     
     store_data, 'ls', data = data, $
                 dlimits={yrange: [0., 360.], ystyle: 1, yticks: 4, yminor: 3}
     if keyword_set(bar) then options, 'ls', tplot_routine='mvn_ls_bar', panel_size=0.3
  endif 

  
  if keyword_set(all) then return, Mars_season
  
  if undefined(time) then return, Mars_season.ls $
  else return, interpol(Mars_season.Ls, Mars_season.time, time_double(time))
end 
