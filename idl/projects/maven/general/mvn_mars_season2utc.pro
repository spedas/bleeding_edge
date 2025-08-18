;PROCEDURE: mvn_mars_season2utc
;PURPOSE:
;  Calculates the Universal time from the Mars year and Mars Ls
;
;USAGE:
;  answer = mvn_mars_season2utc(Mars_year, Ls)
;
;INPUTS:
;       Mars year (year 1 started at northern spring equinox: April 11, 1955)
;
;       Ls: Mars Solar Longitude (O is northern spring equinox, 90 is
;           north summer solstice, 180 north autumnal equinox, 270 is
;           northern winter solstice)
;OUTPUT:                
;       Universal time
;

;CREATED BY:	Robert J. Lillis 2017-10-09
;FILE:  mvn_mars_season2utc
;VERSION:  1.0


function mvn_mars_season2utc, Mars_year, Ls 
  
  common ephemeris, mars_season

  if size(mars_season,/type) ne 8 then begin
     rootdir = 'maven/anc/spice/sav/'
     pathname = rootdir + 'Mars_seasons_1997_2040.sav'
     file = mvn_pfp_file_retrieve(pathname)
     if (findfile(file[0]) eq '') then begin
        print,"File not found: ",pathname
        return, !values.f_nan
     endif
     restore, file[0]
  endif
  
;find the start of the Mars year in question
  np = n_elements(ls)
  times = fltarr(np)
  for k = 0, np-1 do begin
     index_start_mars_year = value_locate(Mars_season.Mars_year,floor(Mars_year[k]))
     index_end_mars_year = value_locate(Mars_season.Mars_year,floor(Mars_year[k])+1)
     times[k] = interpol(Mars_season.time[index_start_mars_year+1:index_end_mars_year],$
                         Mars_season.Ls[index_start_mars_year+1:index_end_mars_year], Ls[k])
  endfor
  return, times
end 

