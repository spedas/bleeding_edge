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
; $LastChangedDate: 2022-08-19 14:18:21 -0700 (Fri, 19 Aug 2022) $
; $LastChangedRevision: 31028 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_ls.pro $
;
;CREATED BY:	Robert J. Lillis 2017-10-09
;FILE:  mvn_ls
;VERSION:  1.0
;-

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

  year_boundary_times = times[ends]
  year = times[ends[1:*]] - times[ends[0:nend-2]]
  ave_year = mean(year)

  Mars_year_decimal = (time_double(times) - start_MY_34)/ave_year + 34.0
  ;Mars_year_integer = floor(Mars_year_decimal)
  Mars_season = {time:times, Mars_year:Mars_year_decimal, Ls:reform(Ls)}

  return, Mars_season
end 

function mvn_ls, time, tplot = tplot, calc = calc, last = last;, no_load_kernels
  
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
  
  if keyword_set(tplot) then store_data, 'ls', data = {x:Mars_season.time, y:Mars_season.Ls}, $
                                         dlimits={yrange: [0., 360.], ystyle: 1, yticks: 4, yminor: 3}
  
  if undefined(time) then return, Mars_season.ls $
  else return, interpol(Mars_season.Ls, Mars_season.time, time_double(time))
end 
