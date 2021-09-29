;PROCEDURE: mvn_ls
;PURPOSE:
;  Calculates the Mars season (i.e. solar longitude)
;
;USAGE:
;  mvn_ls, time
;
;INPUTS:
;       time: time in string ('YYYY-MM-DD', 'YYYY-MM-DD/hh:mm:ss' etc) or double format.
;OUTPUT:                
;       Mars solar longitude
;
;KEYWORDS:
;       TPLOT: makes a tplot variable of Ls

;CREATED BY:	Robert J. Lillis 2017-10-09
;FILE:  mvn_ls
;VERSION:  1.0


function mvn_ls, time, tplot = tplot;, no_load_kernels
  
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
    
  if keyword_set(tplot) then store_data, 'ls', $
                                         data = {x:Mars_season.time, y:Mars_season.Ls}

  return, interpol(Mars_season.Ls,Mars_season.time, time_double(time))
end 

