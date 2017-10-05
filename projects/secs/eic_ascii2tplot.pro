;+
;  eic_ascii2tplot, files, prefix=prefix,suffix=suffix,verbose=verbose,tplotnames=tplotnames
;
;Purpose:
;  This routine reads in the EIC ascii data files and creates two tplot variables eic_latlong and
;  eic_jxy containing the Equivalent Ionosopheric Currents and the Latitude and Longitude grid
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

pro eic_ascii2tplot,files,prefix=prefix,suffix=suffix,verbose=verbose,tplotnames=tplotnames

  dprint,dlevel=4,verbose=verbose,'$Id: eic_ascii2tplot.pro $'
  tplotnames=''
  vb = keyword_set(verbose) ? verbose : 0

  ; Load data from file(s)
  dprint,dlevel=4,verbose=verbose,'Starting ASCII file load'  
  data = eic_read_ascii_data(files) 
  if is_string(data) then begin
     dprint, 'Error reading data. No tplot variable created.'
     return
  endif
 
  dprint,dlevel=4,verbose=verbose,'Starting load into tplot'

  ;  Insert Lat Long into tplot format
  labels = ['Latitude','Longitude']
  dlimits = { files: files,     $
              spec: 0B,         $
              log: 0B,          $
              labels: labels,   $
              labflag: 1,       $
              coord_sys: 'geo', $
              units: 'deg' }
  tn = 'secs_eics_latlong'
  if keyword_set(prefix) then tn = prefix+tn
  if keyword_set(suffix) then tn = tn+suffix
  eic_latlong = {x:data[*,0], y:data[*,1:2] }
  store_data, tn, data = eic_latlong, dlimit = dlimit
  tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn

  ;  Insert Lat Long into tplot format
  dlimits.labels = ['Jx','Jy']
  dlimits.units = 'mA/m'
  tn = 'secs_eics_jxy'
  if keyword_set(prefix) then tn = prefix+tn
  if keyword_set(suffix) then tn = tn+suffix
  eic_jxy = {x:data[*,0], y:data[*,3:4] }
  store_data, tn, data = eic_jxy, dlimit = dlimit
  tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn

end



