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
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-08-08 12:10:41 -0700 (Mon, 08 Aug 2022) $
; $LastChangedRevision: 31002 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_ls.pro $
;
;CREATED BY:	Robert J. Lillis 2017-10-09
;FILE:  mvn_ls
;VERSION:  1.0
;-

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

