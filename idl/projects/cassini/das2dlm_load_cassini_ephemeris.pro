;+
; PRO: das2dlm_load_cassini_ephemeris, ...
;
; Description:
;    Loads Cassini Spacecraft location data using das2dlm library
;    dataset: Cassini/Ephemeris/<dataset>
;    Available datasets:
;     'Dione': Dione centered Cassini orbit parameters
;     'Dione_CoRotation': Dione centered Cassini location - Cartesian Co-Rotational
;     'Earth': Cassini Geocentric orbit parameters
;     'Enceladus': Enceladus centered Cassini orbit parameters
;     'Enceladus_CoRotation': Enceladus centered Cassini location - Cartesian Co-Rotational
;     'Hyperion': Hyperion centered Cassini orbit parameters
;     'Iapetus': Iapetus centered Cassini orbit parameters
;     'Jupiter': Cassini Jupiter centered orbit parameters
;     'Mimas': Mimas centered Cassini orbit parameters
;     'Phoebe': Phoebe centered Cassini orbit parameters
;     'Rhea': Rhea centered Cassini orbit parameters
;     'Rhea_CoRotation': Rhea centered Cassini location - Cartesian Co-Rotational
;     'Saturn': Cassini Saturn centered orbit parameters
;     'Saturn_Equatorial': Saturn centered Cassini location - Cartesian Equatorial
;     'Saturn_KSM': Saturn centered Cassini location - Cartesian KSM
;     'Saturn_SLS2': Saturn centered Cassini orbit parameters with SLS2 longitude calculation
;     'Saturn_SLS3': Saturn centered Cassini orbit parameters with SLS3 longitude calculation
;     'Sun': Heliocentric Cassini orbit parameters
;     'Tethys': Tethys centered Cassini orbit parameters
;     'Tethys_CoRotation': Tethys centered Cassini location - Cartesian Co-Rotational
;     'Titan': Titan centered Cassini orbit parameters
;     'Titan_CoRotation': Titan centered Cassini location - Cartesian Co-Rotational
;     'Venus': Venus centered Cassini orbit parameters
;
; Note:
;   Please reffer to the das2.org catalog for additional information or examples of das2 use:
;   https://das2.org/browse/uiowa/cassini/ephemeris
;
; Keywords:
;    trange: Sets the time tange
;    source (optional): String that defines ephemeris dataset (default: 'Saturn') 
;    interval (optional): string of the interval in seconds between data points, e.g. '60' (default)
;    parameter (optional): string of optional das2 parameters    
;    
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2021-01-25 20:29:41 -0800 (Mon, 25 Jan 2021) $
; $Revision: 29621 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_ephemeris.pro $
;-

pro das2dlm_load_cassini_ephemeris, trange=trange, source=source, interval=interval,  parameter=parameter
  
  das2dlm_cassini_init
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
   
  if undefined(source) $
    then source = 'Saturn'
    
  if undefined(interval) $
    then interval = '60'       
    
  if undefined(parameter) then parameter = ''
  if parameter ne '' then parameter = '&params=' + parameter.Replace(' ','+')

  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  ; todo: validate dataset
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/Ephemeris/' + source
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)
  qinterval = 'interval=' + interval

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2 + '&' + qinterval + parameter
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query)
 
  ; Get time
  das2dlm_get_ds_var, ds, 'time', 'center', p=pt, v=vt, m=mt, d=dt   
  
  ; Exit on empty data
  if undefined(dt) then begin
    dprint, dlevel = 0, 'Dataset has no data for the selected period.'
    return
  endif
  
 ; Convert time
  dt = das2dlm_time_to_unixtime(dt, vt.units)
  
  ; We have to obtain the rest of the variables in the loop since we don't know them
  pdims = das2c_pdims(ds) ; get all pdims
  nd = size(pdims, /n_elem)
  ; Get all variables
  names = []
  for i=0,nd-1 do begin
    name = pdims[i].pdim
    if strcmp(name, 'time',/fold) ne 1 then names = [names, name]           
  endfor
  
  ; Create all tplot variables in the loop
  for i=0,nd-2 do begin ; nd-2 because we exclude time
    name = names[i]
    
    ; get variable
    das2dlm_get_ds_var, ds, name, 'center', p=py, v=vy, m=my, d=dy
    
    ; Metadata
    das2dlm_get_ds_meta, ds, meta=mds, title=das2name
    
    str_element, DAS2, 'url', requestUrl, /add
    str_element, DAS2, 'name', das2name, /add ; ds.name does not contain usefull information in this case
    str_element, DAS2, 'propds', mds, /add ; ds.name does not contain usefull information in this case

    das2dlm_add_metadata, DAS2, p=pt, v=vt, m=mt, add='t'
    das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add=''
    
    tvarname = 'cassini_ephemeris_' + source + '_' + name
    store_data, tvarname, data={x:dt, y:dy}
    options, /default, tvarname, 'colors', 0
    options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
    options, /default, tvarname, 'title', name ; custom title
    
    ytitle = DAS2.name + ', ' + DAS2.units
    options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
  endfor

  ; Cleaning up
  res = das2c_free(query)
      
  ; TODO: add check on null
end