;PROCEDURE: mvn_mars_year
;PURPOSE:
;  Calculates the Mars year
;
;USAGE:
;  mvn_year, time
;
;INPUTS:
;       time: time in string ('YYYY-MM-DD', 'YYYY-MM-DD/hh:mm:ss' etc) or double format.
;OUTPUT:                
;       Mars year (decimal)
;
;KEYWORDS:
;       TPLOT: makes a tplot variable of Ls

;CREATED BY:	Robert J. Lillis 2017-10-09
;FILE:  mvn_mars_year
;VERSION:  1.0

function mvn_mars_year, time;, no_load_kernels
  
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
    
  return, interpol(Mars_season.Mars_year,Mars_season.time, time_double(time))
end 

