;+
;  secs_stations2tplot, file, prefix=prefix,suffix=suffix,verbose=verbose,tplotnames=tplotnames
;
;Purpose:
;  This routine reads in the stations files that were used to create SECS data and creates 
;  a tplot variable secs_stations. This tplot var contains the station name (abbreviated) and 
;  the Latitude and Longitude of the station in geographic coordinates
;
;Keywords: 
; PREFIX = STRING      ; String that will be pre-pended to all tplot variable names. 
; SUFFIX = STRING      ; String appended to end of each tplot variable created.
; VERBOSE = INTEGER    ; Controls number of informational and error messages displayed
; TPLOTNAMES = STRING ARRAY ; Returns the names of tplot variables
; 
;Author: Cindy Russell, June 2017
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-09-23 14:56:22 -0700 (Tue, 23 Sep 2014) $
; $LastChangedRevision: 15845 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_cdf2tplot.pro $
;-

pro secs_stations2tplot,file,date,prefix=prefix,suffix=suffix,verbose=verbose,tplotnames=tplotnames

  dprint,dlevel=4,verbose=verbose,'$Id: secs_stations2tplot.pro $'
  tplotnames=''
  vb = keyword_set(verbose) ? verbose : 0

  ; Load data from file(s)
  dprint,dlevel=4,verbose=verbose,'Starting ASCII Station file load'  
  data = secs_read_stations(file[0]) 
  if is_string(data) then begin
     dprint, 'Error reading data. No tplot variable created.'
     return
  endif
 
  dprint,dlevel=4,verbose=verbose,'Starting load into tplot'

  ;  Insert Lat Long into tplot format
  labels = ['Latitude','Longitude']
  dlimits = { files: file,     $
              spec: 0B,         $
              log: 0B,          $
              labels: labels,   $
              labflag: 0,       $
              coord_sys: 'geo', $
              units: 'deg' }
  tn = 'secs_stations'
  if keyword_set(prefix) then tn = prefix+tn
  if keyword_set(suffix) then tn = tn+suffix
  secs_stations = {x:date, y:data.names, v:data.latlongs}
  store_data, tn, data = secs_stations, dlimit = dlimit
  tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn

end



