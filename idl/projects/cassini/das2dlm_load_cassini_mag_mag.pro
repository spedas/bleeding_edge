;+
; PRO: das2dlm_load_cassini_mag_mag, ...
;
; Description:
;    Loads Magnetic Field Magnitude from Cassini using das2dlm library
;    dataset: Cassini/MAG/Magnitude
;
; Keywords:
;    trange: Sets the time tange
;    parameter (optional): string of optional das2 parameters 
;    
; Note:
;   Please reffer to the das2.org catalog for additional information or examples of das2 use:
;   https://das2.org/browse/uiowa/cassini/mag    
;    
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2021-01-25 20:29:41 -0800 (Mon, 25 Jan 2021) $
; $Revision: 29621 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_load_cassini_mag_mag.pro $
;-

pro das2dlm_load_cassini_mag_mag, trange=trange, parameter=parameter
  
  das2dlm_cassini_init
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
   
   if undefined(parameter) then parameter = ''
   if parameter ne '' then parameter = '&params=' + parameter.Replace(' ','+')
       
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Cassini/MAG/Magnitude'
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2 + parameter
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  ; Get dataset
  ds = das2c_datasets(query, 0)
  
  ; Get variables
  das2dlm_get_ds_var, ds, 'time', 'center', p=px, v=vx, m=mx, d=x
  das2dlm_get_ds_var, ds, 'B_mag', 'center', p=py, v=vy, m=my, d=y

  ; Exit on empty data
  if undefined(x) then begin
    dprint, dlevel = 0, 'Dataset has no data for the selected period.'
    return
  endif

  ; Convert time
  x = das2dlm_time_to_unixtime(x, vx.units)
      
  tvarname = 'cassini_mag_' + ds.name
  store_data, tvarname, data={x:x, y:y}
  options, /default, tvarname, 'colors', 0
  
  ; Metadata
  das2dlm_get_ds_meta, ds, meta=mds, title=das2name

  str_element, DAS2, 'url', requestUrl, /add
  str_element, DAS2, 'name', das2name, /add
  str_element, DAS2, 'propds', mds, /add ; add data set property

  das2dlm_add_metadata, DAS2, p=px, v=vx, m=mx, add='t'
  das2dlm_add_metadata, DAS2, p=py, v=vy, m=my, add='y'
    
  options, /default, tvarname, 'DAS2', DAS2 ; Store metadata (this should not affect graphics)
  options, /default, tvarname, 'title', DAS2.name
  
  ; Data Label
  ytitle = DAS2.namey + ', ' + DAS2.unitsy
  str_element, my[0], 'key', success=s
  if s eq 1 then str_element, my[0], 'value', ytitle    
  options, /default, tvarname, 'ytitle', ytitle ; Title from the properties
end