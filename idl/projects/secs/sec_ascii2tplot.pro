;+
;  sec_ascii2tplot, files, prefix=prefix,suffix=suffix,verbose=verbose,tplotnames=tplotnames
;
;Purpose:
;  This routine reads in the SEC ascii data files and creates a tplot variable sec_amp that
;  contains the amplitude
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

pro sec_ascii2tplot,files,prefix=prefix,suffix=suffix,verbose=verbose,tplotnames=tplotnames

  dprint,dlevel=4,verbose=verbose,'$Id: sec_ascii2tplot.pro $'
  tplotnames=''
  vb = keyword_set(verbose) ? verbose : 0

  ; Load data from file(s)
  dprint,dlevel=4,verbose=verbose,'Starting ASCII file load'  

  data = sec_read_ascii_data(files) 
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
  tn = 'secs_seca_latlong'
  if keyword_set(prefix) then tn = prefix+tn
  if keyword_set(suffix) then tn = tn+suffix
  sec_latlong = {x:data[*,0], y:data[*,1:2] }
  store_data, tn, data = sec_latlong, dlimit = dlimits
  tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn

  ;  Insert Lat Long into tplot format
  ; The original code reassigned the labels array like this:
  ; dlimits.labels = ['J']
  ; dlimits.units = 'A'
  ;
  ; IDL doesn't allow changing the length of an array in an already-defined structure!  This ends up giving you
  ; ['J', 'Longitude'] as the labels attribute, where the intented value is just ['J'].  JWL 2026-10-14
  

  ; Redefine the structure instead of altering its elements
  labels = ['J']
  dlimits = { files: files,     $
    spec: 0B,         $
    log: 0B,          $
    labels: labels,   $
    labflag: 1,       $
    coord_sys: 'geo', $
    units: 'A' }
  
  tn = 'secs_seca_amp'
  if keyword_set(prefix) then tn = prefix+tn
  if keyword_set(suffix) then tn = tn+suffix
  sec_amp = {x:data[*,0], y:data[*,3] }
  store_data, tn, data = sec_amp, dlimit = dlimits
  tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn

end



